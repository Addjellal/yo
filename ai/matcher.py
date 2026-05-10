import json
import re
from collections import Counter
from scrapers.base import JobOffer
from config import config
from utils import console

BATCH_SIZE = 10

# Mots vides FR/EN les plus courants — exclus du pré-filtre keyword
_STOPWORDS = {
    # Français
    "le","la","les","un","une","des","de","du","et","ou","à","au","aux","en","dans",
    "sur","pour","par","avec","sans","sous","vers","chez","plus","moins","ce","cet",
    "cette","ces","mon","ma","mes","ton","ta","tes","son","sa","ses","notre","votre",
    "leur","leurs","est","sont","être","avoir","fait","faire","plus","tout","tous",
    "toute","toutes","aussi","comme","mais","donc","car","si","ne","pas","ni","que",
    "qui","quoi","dont","où","y","an","ans","année","années","jour","jours","mois",
    "h","heures","minimum","poste","emploi","offre","offres","entreprise","candidat",
    "candidate","profil","mission","missions","équipe","activité","activités",
    # Anglais
    "the","a","an","and","or","of","to","in","on","at","by","for","with","from",
    "is","are","was","were","be","been","being","have","has","had","do","does","did",
    "this","that","these","those","it","its","you","your","we","our","they","their",
    "as","but","not","if","then","than","so","no","yes","up","down","out","over",
    "under","more","most","less","other","some","any","all","each","every","both",
    "such","same","new","also","very","can","will","just","like","into","about",
}
_TOKEN_RE = re.compile(r"[a-zA-ZÀ-ÿ][a-zA-ZÀ-ÿ0-9+#./-]{2,}")
PRE_FILTER_THRESHOLD = 3  # min keywords overlap to keep an offer

SYSTEM_PROMPT = (
    "Tu es un expert RH qui analyse la correspondance entre un CV et des offres d'emploi. "
    "Tu réponds toujours avec un JSON valide, sans texte supplémentaire.\n\n"
    "CV du candidat :\n{cv}"
)


def _tokenize(text: str) -> list[str]:
    return [
        t.lower() for t in _TOKEN_RE.findall(text or "")
        if t.lower() not in _STOPWORDS
    ]


class JobMatcher:
    def __init__(self, cv_text: str):
        self.cv_text = cv_text
        self._sectors: list[str] = []
        self._client = None
        # Vocabulaire CV : mots significatifs avec leur fréquence
        self._cv_vocab: Counter[str] = Counter(_tokenize(cv_text))

    def _get_client(self):
        if self._client is None:
            if config.provider == "ollama":
                import ollama
                self._client = ollama.Client(host=config.ollama_base_url)
            else:
                import anthropic
                self._client = anthropic.Anthropic(api_key=config.anthropic_api_key)
        return self._client

    def _prefilter(self, offers: list[JobOffer]) -> tuple[list[JobOffer], int]:
        """Heuristique rapide : garde les offres ayant un overlap minimal de mots-clés
        avec le CV. Retourne (offres_retenues, nombre_filtrées)."""
        if not self._cv_vocab:
            return offers, 0
        kept: list[JobOffer] = []
        dropped = 0
        for offer in offers:
            offer_tokens = set(_tokenize(f"{offer.title} {offer.description}"))
            overlap = sum(1 for t in offer_tokens if t in self._cv_vocab)
            if overlap >= PRE_FILTER_THRESHOLD:
                kept.append(offer)
            else:
                dropped += 1
        return kept, dropped

    def score_offers(
        self,
        offers: list[JobOffer],
        min_score: int = 6,
        sectors: list[str] | None = None,
    ) -> list[JobOffer]:
        self._sectors = sectors or []

        # Pré-filtre keyword (économise les appels LLM)
        offers, dropped = self._prefilter(offers)
        if dropped:
            console.print(f"[dim]Pré-filtre : {dropped} offre(s) clairement hors-sujet écartée(s).[/dim]")

        if not offers:
            return []

        self._get_client()
        scored = []
        for i in range(0, len(offers), BATCH_SIZE):
            batch = offers[i: i + BATCH_SIZE]
            console.print(f"[dim]  Analyse IA : lot {i // BATCH_SIZE + 1}/{(len(offers) - 1) // BATCH_SIZE + 1} ({len(batch)} offres)...[/dim]")
            self._score_batch(batch)
            scored.extend(batch)

        return sorted(
            [o for o in scored if (o.match_score or 0) >= min_score],
            key=lambda o: o.match_score or 0,
            reverse=True,
        )

    def _build_prompt(self, batch: list[JobOffer]) -> str:
        jobs_text = "\n\n---\n\n".join(
            f"[JOB_{i}]\n{job.to_text()}" for i, job in enumerate(batch)
        )
        sector_instruction = ""
        if self._sectors:
            joined = ", ".join(self._sectors)
            sector_instruction = (
                f"\nSECTEURS CIBLES : Le candidat souhaite travailler dans : {joined}. "
                "Pénalise fortement (score ≤ 3) les offres hors de ces secteurs. "
                "Précise dans les raisons si le secteur correspond ou non.\n"
            )
        return (
            f"Voici {len(batch)} offres d'emploi à analyser. Pour chaque offre, donne :\n"
            f"- Un score de correspondance de 0 à 10 (10 = correspondance parfaite)\n"
            f"- 2-3 raisons courtes (compétences ET secteur){sector_instruction}\n"
            "IMPORTANT : réponds UNIQUEMENT avec un tableau JSON valide, sans texte avant ni après.\n"
            'Le champ "reasons" doit être une CHAÎNE DE CARACTÈRES (pas une liste), '
            'exemple : "Expérience Python · Django · correspond au secteur tech"\n'
            "Format exact :\n"
            '[\n  {"job_index": 0, "score": 8, "reasons": "raison1 · raison2"},\n  ...\n]\n\n'
            f"Offres à analyser :\n{jobs_text}"
        )

    def _score_batch(self, batch: list[JobOffer]) -> None:
        prompt = self._build_prompt(batch)
        if config.provider == "ollama":
            raw = self._call_ollama(prompt)
        else:
            raw = self._call_anthropic(prompt)
        self._parse_response(raw, batch)

    def _call_anthropic(self, prompt: str) -> str:
        response = self._client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1024,
            system=[
                {
                    "type": "text",
                    "text": SYSTEM_PROMPT.format(cv=self.cv_text),
                    "cache_control": {"type": "ephemeral"},
                }
            ],
            messages=[{"role": "user", "content": prompt}],
        )
        return response.content[0].text.strip()

    def _call_ollama(self, prompt: str) -> str:
        response = self._client.chat(
            model=config.ollama_model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT.format(cv=self.cv_text)},
                {"role": "user", "content": prompt},
            ],
            options={"temperature": 0, "num_ctx": 8192},
        )
        return response.message.content.strip()

    def _parse_response(self, raw: str, batch: list[JobOffer]) -> None:
        # Chercher un tableau JSON — le LLM peut ajouter du texte autour
        start = raw.find("[")
        end = raw.rfind("]") + 1
        if start == -1 or end == 0:
            console.print("[yellow]Avertissement : le modèle n'a pas retourné de JSON valide pour ce lot.[/yellow]")
            return
        try:
            results = json.loads(raw[start:end])
        except json.JSONDecodeError:
            # Tentative de récupération : trouver les objets JSON individuels
            results = _extract_json_objects(raw)
            if not results:
                console.print("[yellow]Avertissement : JSON du matcher illisible, lot ignoré.[/yellow]")
                return

        for item in results:
            if not isinstance(item, dict):
                continue
            idx = item.get("job_index", -1)
            if not isinstance(idx, int) or not (0 <= idx < len(batch)):
                continue
            score = item.get("score", 0)
            batch[idx].match_score = int(score) if isinstance(score, (int, float)) else 0
            # Le LLM peut retourner reasons comme string ou liste — normaliser
            reasons = item.get("reasons", "")
            if isinstance(reasons, list):
                reasons = " · ".join(str(r).strip() for r in reasons if r)
            batch[idx].match_reasons = str(reasons).strip()


def _extract_json_objects(text: str) -> list[dict]:
    """Tente d'extraire des objets JSON individuels depuis un texte malformé."""
    results = []
    depth = 0
    start = -1
    for i, ch in enumerate(text):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start != -1:
                try:
                    obj = json.loads(text[start:i + 1])
                    if isinstance(obj, dict):
                        results.append(obj)
                except json.JSONDecodeError:
                    pass
                start = -1
    return results
