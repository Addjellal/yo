import re
import threading
import time

import requests
from rich.markup import escape
from .base import (BaseScraper, JobOffer, MAX_RESPONSE_BYTES, fetch_with_retry,
                   jitter_sleep, log_parse_error)
from config import config
from app_utils import console


TOKEN_URL = "https://entreprise.francetravail.fr/connexion/oauth2/access_token?realm=%2Fpartenaire"
SEARCH_URL = "https://api.francetravail.io/partenaire/offresdemploi/v2/offres/search"

PAGE_SIZE = 150       # l'API plafonne une requête à 150 résultats (range 0-149)
MAX_RANGE = 1149      # plafond de pagination (≈ 8 pages), aligné sur les autres sources


REGISTER_URL = "https://francetravail.io/produits-et-services/portail-partenaire"

# Jeton OAuth partagé au niveau module : une recherche globale crée un scraper
# par (requête × lieu) — chaque instance re-demandait son propre jeton, soit
# N×M appels d'authentification par scan pour un jeton valable ~25 min.
_TOKEN_LOCK = threading.Lock()
_TOKEN: str | None = None
_TOKEN_EXPIRES: float = 0.0

# Le paramètre `commune` de l'API attend un code INSEE (5 chiffres, lettre
# possible en Corse : 2A/2B), pas un nom de ville.
_INSEE_RE = re.compile(r"^\d{5}$|^2[AB]\d{3}$", re.IGNORECASE)


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

    def _get_token(self) -> str:
        global _TOKEN, _TOKEN_EXPIRES
        with _TOKEN_LOCK:
            if _TOKEN and time.time() < _TOKEN_EXPIRES - 60:
                return _TOKEN

            resp = fetch_with_retry(
                lambda: requests.post(
                    TOKEN_URL,
                    data={
                        "grant_type": "client_credentials",
                        "client_id": config.france_travail_client_id,
                        "client_secret": config.france_travail_client_secret,
                        "scope": "api_offresdemploiv2 o2dsoffre",
                    },
                    headers={"Content-Type": "application/x-www-form-urlencoded"},
                    timeout=10,
                ),
                self.source_name,
            )
            resp.raise_for_status()
            data = resp.json()
            if not isinstance(data, dict):
                raise ValueError("réponse d'authentification inattendue (pas un objet JSON)")
            token = data.get("access_token")
            if not token:
                raise ValueError("réponse d'authentification sans access_token")
            try:
                expires_in = float(data.get("expires_in") or 1200)
            except (TypeError, ValueError):
                expires_in = 1200
            _TOKEN = token
            _TOKEN_EXPIRES = time.time() + expires_in
            return _TOKEN

    def search(self, query: str, location: str = "", max_results: int = 50) -> list[JobOffer]:
        if config.country != "fr":
            raise ValueError("couvre uniquement la France")
        target = max(max_results, 1)
        offers: list[JobOffer] = []
        seen: set[str] = set()
        start = 0

        try:
            token = self._get_token()
            headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}

            while len(offers) < target and start <= MAX_RANGE:
                # Range borné par le plafond ET par le nombre encore voulu — jamais
                # de range invalide « 0--1 » (target≥1 garantit last≥start).
                last = min(start + PAGE_SIZE - 1, MAX_RANGE, start + (target - len(offers)) - 1)
                params = {"motsCles": query, "range": f"{start}-{last}"}
                if location:
                    # `commune` n'accepte qu'un code INSEE ; un nom de ville y
                    # provoquerait un 400 (toute la source tomberait). Un nom est
                    # donc joint aux mots-clés — moins précis mais fonctionnel.
                    if _INSEE_RE.match(location.strip()):
                        params["commune"] = location.strip()
                    else:
                        params["motsCles"] = f"{query} {location}".strip()

                resp = fetch_with_retry(
                    lambda p=dict(params): requests.get(
                        SEARCH_URL, params=p, headers=headers, timeout=15,
                    ),
                    self.source_name,
                )
                if resp.status_code == 204:
                    break
                resp.raise_for_status()
                if len(resp.content) > MAX_RESPONSE_BYTES:
                    console.print("[yellow][France Travail] Réponse anormalement volumineuse, ignorée.[/yellow]")
                    break
                data = resp.json()
                if not isinstance(data, dict):
                    break
                results = data.get("resultats", [])
                if not results:
                    break

                for item in results:
                    job = self._parse_item(item, location)
                    if job and job.unique_key() not in seen:
                        seen.add(job.unique_key())
                        offers.append(job)

                # Dernière page : l'API a renvoyé moins que la fenêtre demandée.
                if len(results) < (last - start + 1):
                    break
                start = last + 1
                jitter_sleep(config.request_delay)
        except (requests.RequestException, ValueError) as e:
            # Erreur côté France Travail (réseau, auth, JSON) : on dégrade
            # proprement comme les autres sources plutôt que de crasher le scan.
            console.print(
                f"[yellow][France Travail] L'API ne répond pas correctement "
                f"({escape(type(e).__name__)}) — erreur côté France Travail, réessayez plus tard.[/yellow]"
            )
            # On conserve ce qui a déjà été collecté avant l'erreur.
        return offers[:target]

    def _parse_item(self, item: dict, location: str) -> JobOffer | None:
        try:
            offer_id = item.get("id", "")
            if not offer_id:
                return None
            lieu = item.get("lieuTravail")
            lieu = lieu if isinstance(lieu, dict) else {}
            entreprise = item.get("entreprise")
            entreprise = entreprise if isinstance(entreprise, dict) else {}
            salaire = item.get("salaire")
            salaire = salaire if isinstance(salaire, dict) else {}
            contact = item.get("contact")
            contact = contact if isinstance(contact, dict) else {}
            detail_url = f"https://candidat.francetravail.fr/offres/recherche/detail/{offer_id}"
            return JobOffer(
                id=f"ft_{offer_id}",
                title=item.get("intitule", ""),
                company=entreprise.get("nom") or "N/A",
                location=lieu.get("libelle") or location,
                description=item.get("description", ""),
                url=detail_url,
                apply_url=contact.get("urlPostulation") or detail_url,
                source=self.source_name,
                salary=salaire.get("libelle"),
                contract_type=item.get("typeContrat"),
                date_posted=(item.get("dateCreation") or "")[:10] or None,
            )
        except Exception as e:
            log_parse_error(self.source_name, e, "item API")
            return None
