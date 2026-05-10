from .base import JobOffer
from .france_travail import FranceTravailScraper
from .indeed import IndeedScraper
from .wttj import WTTJScraper
from .linkedin import LinkedInScraper
from .apec import ApecScraper
from .adzuna import AdzunaScraper

__all__ = [
    "JobOffer",
    "FranceTravailScraper",
    "IndeedScraper",
    "WTTJScraper",
    "LinkedInScraper",
    "ApecScraper",
    "AdzunaScraper",
]
