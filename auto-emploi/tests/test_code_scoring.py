"""
Tests du scoring 100 % code (sans IA) et des offres « mises de côté ».

- Le scoring local repose sur le recouvrement de mots-clés CV/offre pondéré
  TF-IDF (titre du poste pondéré plus fort). Aucun appel LLM.
- set_aside_out collecte les offres ANALYSÉES mais sous le seuil (déjà évaluées,
  consultables sans recalcul).
- llm_available choisit entre analyse IA et repli local au lancement d'un scan.

Lancement :  python -m pytest tests/ -v   (depuis le dossier auto-emploi)
"""
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from config import config
from job_scrapers.base import JobOffer
from ai import matcher as matcher_mod
from ai.matcher import JobMatcher, score_offers_multi
from ai._client import llm_available


CV_DATA = (
    "Ingénieur data Python, 3 ans d'expérience. Compétences : Python, SQL, "
    "Airflow, Spark, ETL, data pipeline, AWS, machine learning, pandas, docker, "
    "kubernetes. Construction de pipelines de données, modélisation, dataviz."
)


def make_offer(i: int, title: str, description: str = "") -> JobOffer:
    return JobOffer(
        id=f"test_{i}", title=title, company=f"E{i}", location="Rennes",
        description=description, url=f"https://example.com/{i}", source="Test",
    )


def data_offers() -> list[JobOffer]:
    boiler = ("Nous recherchons un candidat motivé pour rejoindre notre équipe "
              "dynamique. Poste en CDI, télétravail, avantages.")
    return [
        make_offer(1, "Data Engineer", boiler + " Python SQL Airflow Spark ETL pipeline AWS docker kubernetes data."),
        make_offer(2, "Ingénieur Big Data", boiler + " Spark Hadoop pipeline data Python ETL AWS."),
        make_offer(3, "Data Scientist", boiler + " Python machine learning pandas modélisation SQL dataviz."),
        make_offer(4, "Boulanger pâtissier", boiler + " pains viennoiseries pâte fournil vente boutique."),
        make_offer(5, "Commercial terrain", boiler + " prospection négociation CRM clients vente B2B."),
    ]


@pytest.fixture(autouse=True)
def isolated_config(tmp_path, monkeypatch):
    """Config IA neutre : aucune clé, aucun backend — toute fuite vers un vrai
    appel LLM échouerait, ce qui prouve que le scoring code n'en fait aucun."""
    monkeypatch.setattr(config, "output_dir", str(tmp_path))
    monkeypatch.setattr(config, "provider", "anthropic")
    monkeypatch.setattr(config, "anthropic_api_key", "")
    monkeypatch.setattr(config, "ai_match_backend", "")
    monkeypatch.setattr(config, "ai_prescore_backend", "")
    monkeypatch.setattr(config, "ai_fallback", "none")
    yield tmp_path


# ─── 1. Scoring code pur ──────────────────────────────────────────────────────

class TestCodeScoring:
    def test_aucun_appel_llm_et_scores_renseignes(self, monkeypatch):
        """En mode code, _score_batch (le seul chemin LLM) ne doit JAMAIS être
        appelé, et chaque offre retenue porte un score."""
        def boom(self, batch):
            raise AssertionError("le scoring code ne doit appeler aucun LLM")
        monkeypatch.setattr(JobMatcher, "_score_batch", boom)

        results = score_offers_multi({"cv": CV_DATA}, data_offers(), min_score=0, code=True)
        assert results, "le scoring local devrait retenir des offres"
        assert all(o.match_score is not None for o in results)

    def test_offre_pertinente_mieux_notee_que_hors_sujet(self, monkeypatch):
        # Pré-filtre neutralisé : on veut comparer les scores, pas l'overlap.
        monkeypatch.setattr(matcher_mod, "PRE_FILTER_THRESHOLD", 0)
        results = score_offers_multi({"cv": CV_DATA}, data_offers(), min_score=0, code=True)
        by_title = {o.title: o.match_score for o in results}
        assert by_title["Data Engineer"] > by_title["Boulanger pâtissier"]
        assert by_title["Ingénieur Big Data"] > by_title["Commercial terrain"]

    def test_scores_dans_la_plage_0_10(self, monkeypatch):
        monkeypatch.setattr(matcher_mod, "PRE_FILTER_THRESHOLD", 0)
        results = score_offers_multi({"cv": CV_DATA}, data_offers(), min_score=0, code=True)
        assert all(0 <= o.match_score <= 10 for o in results)

    def test_metadata_indique_lorigine_locale(self, monkeypatch):
        monkeypatch.setattr(matcher_mod, "PRE_FILTER_THRESHOLD", 0)
        results = score_offers_multi({"cv": CV_DATA}, data_offers(), min_score=0, code=True)
        engineer = next(o for o in results if o.title == "Data Engineer")
        assert "sans IA" in (engineer.match_reasons or "")
        assert "aucun modèle IA" in (engineer.match_gaps or "")

    def test_accents_et_pluriels_apparies(self):
        """« ingénieur »/« ingenieur » et « pipelines »/« pipeline » doivent
        s'apparier (repli d'accents + canonisation des pluriels)."""
        m = JobMatcher("ingénieur pipeline données")
        offer = make_offer(1, "Ingenieur", "construction de pipelines de donnees")
        idf = m._build_idf([offer])
        score, terms = m._code_score(offer, idf)
        assert score > 0
        assert "ingenieur" in terms and "pipeline" in terms

    def test_cv_vide_score_zero(self):
        m = JobMatcher("")
        offer = make_offer(1, "Data Engineer", "Python SQL Spark")
        idf = m._build_idf([offer])
        assert m._code_score(offer, idf) == (0, [])


# ─── 2. Offres mises de côté (analysées mais sous le seuil) ───────────────────

class TestSetAside:
    def test_collecte_les_offres_sous_le_seuil_triees(self, monkeypatch):
        monkeypatch.setattr(matcher_mod, "PRE_FILTER_THRESHOLD", 0)
        aside: list[JobOffer] = []
        results = score_offers_multi(
            {"cv": CV_DATA}, data_offers(), min_score=10, code=True, set_aside_out=aside,
        )
        # Seuil très haut : peu (voire rien) de retenu, le reste évalué part de côté.
        assert all(o.match_score >= 10 for o in results)
        assert aside, "les offres évaluées sous le seuil devraient être mises de côté"
        assert all(0 < o.match_score < 10 for o in aside)
        # Triées par score décroissant
        assert [o.match_score for o in aside] == sorted((o.match_score for o in aside), reverse=True)

    def test_score_zero_jamais_mis_de_cote(self, monkeypatch):
        # CV sans rapport : certaines offres tombent à 0 → ni retenues ni de côté.
        monkeypatch.setattr(matcher_mod, "PRE_FILTER_THRESHOLD", 0)
        aside: list[JobOffer] = []
        score_offers_multi(
            {"cv": "boulangerie pâtisserie fournil viennoiserie"}, data_offers(),
            min_score=6, code=True, set_aside_out=aside,
        )
        assert all(o.match_score > 0 for o in aside)

    def test_multi_cv_mise_de_cote_sur_le_meilleur(self, monkeypatch):
        """En multi-CV, une offre part de côté si son MEILLEUR score reste sous le
        seuil ; elle garde best_cv et son score principal."""
        monkeypatch.setattr(matcher_mod, "PRE_FILTER_THRESHOLD", 0)

        def fake_batch(self, batch):
            robot_cv = "ROS2" in self.cv_text
            for o in batch:
                is_robot = "robot" in o.title.lower()
                o.match_score = (9 if is_robot else 5) if robot_cv else (2 if is_robot else 5)
                o.match_reasons = "x"; o.match_strengths = "y"; o.match_gaps = "z"
        monkeypatch.setattr(JobMatcher, "_score_batch", fake_batch)

        offers = [make_offer(1, "Ingénieur Robotique", "Python ROS2"),
                  make_offer(2, "Développeur Web", "Python Django")]
        aside: list[JobOffer] = []
        results = score_offers_multi(
            {"CV Robot": "ROS2 navigation", "CV Web": "Django React"}, offers,
            min_score=8, set_aside_out=aside,
        )
        assert [o.title for o in results] == ["Ingénieur Robotique"]  # best 9 ≥ 8
        web = next(o for o in aside if "Web" in o.title)
        assert web.match_score == 5 and web.best_cv  # best des deux CV, sous le seuil

    def test_set_aside_out_optionnel(self, monkeypatch):
        """Sans set_aside_out, le comportement (retour) est inchangé."""
        monkeypatch.setattr(matcher_mod, "PRE_FILTER_THRESHOLD", 0)
        results = score_offers_multi({"cv": CV_DATA}, data_offers(), min_score=10, code=True)
        assert isinstance(results, list)


# ─── 3. Détection de la disponibilité d'un LLM ────────────────────────────────

class TestLlmAvailable:
    def test_anthropic_sans_cle_indisponible(self, monkeypatch):
        monkeypatch.setattr(config, "provider", "anthropic")
        monkeypatch.setattr(config, "ai_match_backend", "")
        monkeypatch.setattr(config, "ai_fallback", "none")
        monkeypatch.setattr(config, "anthropic_api_key", "")
        assert llm_available("match") is False

    def test_anthropic_avec_cle_disponible(self, monkeypatch):
        monkeypatch.setattr(config, "provider", "anthropic")
        monkeypatch.setattr(config, "ai_match_backend", "")
        monkeypatch.setattr(config, "anthropic_api_key", "sk-test")
        assert llm_available("match") is True

    def test_backend_local_toujours_tente(self, monkeypatch):
        monkeypatch.setattr(config, "anthropic_api_key", "")
        monkeypatch.setattr(config, "ai_match_backend", "local")
        assert llm_available("match") is True

    def test_fallback_local_compense_absence_de_cle(self, monkeypatch):
        monkeypatch.setattr(config, "provider", "anthropic")
        monkeypatch.setattr(config, "ai_match_backend", "")
        monkeypatch.setattr(config, "anthropic_api_key", "")
        monkeypatch.setattr(config, "ai_fallback", "local")
        assert llm_available("match") is True
