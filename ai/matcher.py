import json
from scrapers.base import JobOffer
from config import config
from utils import console

BATCH_SIZE = 10

SYSTEM_PROMPT = (
    "Tu es un expert RH qui analyse la correspondance entre un CV et des offres d'emploi. "
    "Tu réponds toujours avec un JSON valide, sans texte supplémentaire.\n\n"
    "CV du candidat :\n{cv}"
)


class JobMatcher:
    def __init__(self, cv_text: str):
        self.cv_text = cv_text
        self._sectors: list[str] = []
        self._client = None

    def _get_client(self):
        if self._client is None:
            if config.provider == "ollama":
                import ollama
                self._client = ollama.Client(host=config.ollama_base_url)
            else:
                import anthropic
                self._client = anthropic.Anthropic(api_key=config.anthropic_api_key)
        return self._client

    def score_offers(
        self,
        offers: list[JobOffer],
        min_score: int = 6,
        sectors: list[str] | None = None,
    ) -> list[JobOffer]:
        self._sectors = sectors or []
        self._get_client()
        scored = []
        for i in range(0, len(offers), BATCH_SIZE):
            batch = offers[i: i + BATCH_SIZE]
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
            "Réponds UNIQUEMENT avec un JSON valide sous cette forme exacte :\n"
            '[\n  {"job_index": 0, "score": 8, "reasons": "..."},\n  ...\n]\n\n'
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
            options={"temperature": 0},
        )
        return response.message.content.strip()

    def _parse_response(self, raw: str, batch: list[JobOffer]) -> None:
        start = raw.find("[")
        end = raw.rfind("]") + 1
        if start == -1 or end == 0:
            console.print("[yellow]Avertissement : le modèle n'a pas retourné de JSON valide pour ce lot.[/yellow]")
            return
        try:
            results = json.loads(raw[start:end])
        except json.JSONDecodeError as e:
            console.print(f"[yellow]Avertissement : erreur JSON du matcher ({e}). Lot ignoré.[/yellow]")
            return
        for item in results:
            idx = item.get("job_index", -1)
            if 0 <= idx < len(batch):
                batch[idx].match_score = item.get("score", 0)
                batch[idx].match_reasons = item.get("reasons", "")
