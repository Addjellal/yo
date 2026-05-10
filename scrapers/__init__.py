from .base import JobOffer
from .france_travail import FranceTravailScraper
from .indeed import IndeedScraper
from .wttj import WTTJScraper
from .linkedin import LinkedInScraper

__all__ = ["JobOffer", "FranceTravailScraper", "IndeedScraper", "WTTJScraper", "LinkedInScraper"]
