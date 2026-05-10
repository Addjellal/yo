import time
import requests
from .base import BaseScraper, JobOffer
from config import config


TOKEN_URL = "https://entreprise.francetravail.fr/connexion/oauth2/access_token?realm=%2Fpartenaire"
SEARCH_URL = "https://api.francetravail.io/partenaire/offresdemploi/v2/offres/search"


REGISTER_URL = "https://francetravail.io/produits-et-services/portail-partenaire"


class FranceTravailScraper(BaseScraper):
    source_name = "France Travail"

    _PLACEHOLDERS = {"your_client_id", "your_client_secret", "votre_client_id", "votre_client_secret"}

    def __init__(self):
        cid = config.france_travail_client_id
        csecret = config.france_travail_client_secret
        if not cid or not csecret or cid in self._PLACEHOLDERS or csecret in self._PLACEHOLDERS:
            raise ValueError(
                "FRANCE_TRAVAIL_CLIENT_ID et FRANCE_TRAVAIL_CLIENT_SECRET manquants.\n"
                f"Inscrivez-vous sur {REGISTER_URL}"
            )
        self._token: str | None = None
        self._token_expires: float = 0

    def _get_token(self) -> str:
        if self._token and time.time() < self._token_expires - 60:
            return self._token

        resp = requests.post(
            TOKEN_URL,
            data={
                "grant_type": "client_credentials",
                "client_id": config.france_travail_client_id,
                "client_secret": config.france_travail_client_secret,
                "scope": "api_offresdemploiv2 o2dsoffre",
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            timeout=10,
        )
        resp.raise_for_status()
        data = resp.json()
        self._token = data["access_token"]
        self._token_expires = time.time() + data.get("expires_in", 1200)
        return self._token

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        token = self._get_token()
        headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}
        params = {
            "motsCles": query,
            "range": f"0-{min(max_results, 149) - 1}",
        }
        if location:
            params["commune"] = location

        resp = requests.get(SEARCH_URL, params=params, headers=headers, timeout=15)
        if resp.status_code == 204:
            return []
        resp.raise_for_status()

        offers = []
        for item in resp.json().get("resultats", []):
            offer_id = item.get("id", "")
            lieuTravail = item.get("lieuTravail", {})
            salaire = item.get("salaire", {})
            offers.append(JobOffer(
                id=f"ft_{offer_id}",
                title=item.get("intitule", ""),
                company=item.get("entreprise", {}).get("nom", "N/A"),
                location=lieuTravail.get("libelle", location),
                description=item.get("description", ""),
                url=f"https://candidat.francetravail.fr/offres/recherche/detail/{offer_id}",
                apply_url=item.get("contact", {}).get("urlPostulation") or f"https://candidat.francetravail.fr/offres/recherche/detail/{offer_id}",
                source=self.source_name,
                salary=salaire.get("libelle"),
                contract_type=item.get("typeContrat"),
            ))
        return offers
