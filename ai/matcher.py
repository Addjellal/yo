import json
import anthropic
from scrapers.base import JobOffer
from config import config
from utils import console

BATCH_SIZE = 10


class JobMatcher:
    """Score job offers against a CV using Claude with prompt caching."""

    def __init__(self, cv_text: str):
        self.cv_text = cv_text
        self.client = anthropic.Anthropic(api_key=config.anthropic_api_key)
        self._sectors: list[str] = []

    def score_offers(
        self,
        offers: list[JobOffer],
        min_score: int = 6,
        sectors: list[str] | None = None,
    ) -> list[JobOffer]:
        self._sectors = sectors or []
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

    def _score_batch(self, batch: list[JobOffer]) -> None:
        jobs_text = "\n\n---\n\n".join(
            f"[JOB_{i}]\n{job.to_text()}" for i, job in enumerate(batch)
        )

        sector_instruction = ""
        if self._sectors:
            joined = ", ".join(self._sectors)
            sector_instruction = (
                f"\nSECTEURS CIBLES : Le candidat souhaite travailler dans : {joined}. "
                "Pénalise fortement (score ≤ 3) les offres hors de ces secteurs, "
                "même si les compétences techniques correspondent. "
                "Précise dans les raisons si le secteur correspond ou non.\n"
            )

        prompt = f"""Voici {len(batch)} offres d'emploi à analyser. Pour chaque offre, donne :
- Un score de correspondance de 0 à 10 (10 = correspondance parfaite)
- 2-3 raisons courtes (compétences ET secteur){sector_instruction}
Réponds UNIQUEMENT avec un JSON valide sous cette forme exacte :
[
  {{"job_index": 0, "score": 8, "reasons": "Correspond au profil Python senior. Secteur fintech ciblé."}},
  ...
]

Offres à analyser :
{jobs_text}"""

        response = self.client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1024,
            system=[
                {
                    "type": "text",
                    "text": (
                        "Tu es un expert RH qui analyse la correspondance entre un CV et des offres d'emploi. "
                        "Tu réponds toujours avec un JSON valide, sans texte supplémentaire.\n\n"
                        f"CV du candidat :\n{self.cv_text}"
                    ),
                    "cache_control": {"type": "ephemeral"},
                }
            ],
            messages=[{"role": "user", "content": prompt}],
        )

        raw = response.content[0].text.strip()
        start = raw.find("[")
        end = raw.rfind("]") + 1
        if start == -1 or end == 0:
            console.print("[yellow]Avertissement : Claude n'a pas retourné de JSON valide pour ce lot.[/yellow]")
            return

        try:
            results = json.loads(raw[start:end])
        except json.JSONDecodeError as e:
            console.print(f"[yellow]Avertissement : erreur de parsing JSON du matcher ({e}). Lot ignoré.[/yellow]")
            return

        for item in results:
            idx = item.get("job_index", -1)
            if 0 <= idx < len(batch):
                batch[idx].match_score = item.get("score", 0)
                batch[idx].match_reasons = item.get("reasons", "")
