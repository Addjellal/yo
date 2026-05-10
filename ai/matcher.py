import json
import anthropic
from scrapers.base import JobOffer
from config import config

BATCH_SIZE = 10


class JobMatcher:
    """Score job offers against a CV using Claude with prompt caching."""

    def __init__(self, cv_text: str):
        self.cv_text = cv_text
        self.client = anthropic.Anthropic(api_key=config.anthropic_api_key)

    def score_offers(self, offers: list[JobOffer], min_score: int = 6) -> list[JobOffer]:
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

        prompt = f"""Voici {len(batch)} offres d'emploi à analyser. Pour chaque offre, donne :
- Un score de correspondance de 0 à 10 (10 = correspondance parfaite)
- 2-3 raisons courtes

Réponds UNIQUEMENT avec un JSON valide sous cette forme exacte :
[
  {{"job_index": 0, "score": 8, "reasons": "Correspond au profil Python senior. Secteur fintech comme demandé."}},
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
        # Extraire le JSON même si Claude ajoute du texte autour
        start = raw.find("[")
        end = raw.rfind("]") + 1
        if start == -1 or end == 0:
            return

        results = json.loads(raw[start:end])
        for item in results:
            idx = item.get("job_index", -1)
            if 0 <= idx < len(batch):
                batch[idx].match_score = item.get("score", 0)
                batch[idx].match_reasons = item.get("reasons", "")
