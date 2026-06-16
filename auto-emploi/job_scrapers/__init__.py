from .base import JobOffer
from .france_travail import FranceTravailScraper
from .indeed import IndeedScraper
from .linkedin import LinkedInScraper
from .talent import TalentScraper
from .adzuna import AdzunaScraper

__all__ = [
    "JobOffer",
    "FranceTravailScraper",
    "IndeedScraper",
    "LinkedInScraper",
    "TalentScraper",
    "AdzunaScraper",
]
