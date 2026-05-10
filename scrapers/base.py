from dataclasses import dataclass, field
from typing import Optional
from datetime import datetime


@dataclass
class JobOffer:
    id: str
    title: str
    company: str
    location: str
    description: str
    url: str
    source: str
    salary: Optional[str] = None
    contract_type: Optional[str] = None
    posted_date: Optional[datetime] = None
    apply_url: Optional[str] = None
    match_score: Optional[int] = None
    match_reasons: Optional[str] = None

    def to_text(self) -> str:
        parts = [
            f"Poste : {self.title}",
            f"Entreprise : {self.company}",
            f"Lieu : {self.location}",
        ]
        if self.contract_type:
            parts.append(f"Contrat : {self.contract_type}")
        if self.salary:
            parts.append(f"Salaire : {self.salary}")
        parts.append(f"\nDescription :\n{self.description[:3000]}")
        return "\n".join(parts)

    def unique_key(self) -> str:
        return f"{self.title.lower().strip()}|{self.company.lower().strip()}"


class BaseScraper:
    source_name: str = "unknown"

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        raise NotImplementedError
