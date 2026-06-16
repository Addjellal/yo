"""
Tests des fonctionnalités : historique de sessions, pré-filtre du re-scoring,
génération de lettre (LLM simulé), export PDF, routage IA par tâche.

Lancement :  python -m pytest tests/ -v   (depuis le dossier auto-emploi)
"""
import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from config import config
from job_scrapers.base import JobOffer
from history import SessionStore
from ai.matcher import JobMatcher
from ai.cover_letter import CoverLetterGenerator, detect_language
from ai import _client as llm_client


def make_offer(i: int, title: str, description: str = "", score: int | None = None) -> JobOffer:
    offer = JobOffer(
        id=f"test_{i}",
        title=title,
        company=f"Entreprise{i}",
        location="Rennes",
        description=description,
        url=f"https://example.com/{i}",
        apply_url=f"https://example.com/{i}",
        source="Test",
    )
    offer.match_score = score
    return offer


@pytest.fixture(autouse=True)
def isolated_config(tmp_path, monkeypatch):
    """Sorties dans un dossier temporaire + config IA neutre, restaurés après."""
    monkeypatch.setattr(config, "output_dir", str(tmp_path))
    monkeypatch.setattr(config, "provider", "anthropic")
    monkeypatch.setattr(config, "ai_prescore_backend", "")
    monkeypatch.setattr(config, "ai_match_backend", "")
    monkeypatch.setattr(config, "ai_letter_backend", "")
    monkeypatch.setattr(config, "ai_prescore_model", "")
    monkeypatch.setattr(config, "ai_match_model", "")
    monkeypatch.setattr(config, "ai_letter_model", "")
    monkeypatch.setattr(config, "ai_fallback", "none")
    monkeypatch.setattr(config, "candidate_name", "")
    monkeypatch.setattr(config, "candidate_email", "")
    monkeypatch.setattr(config, "candidate_phone", "")
    monkeypatch.setattr(config, "candidate_city", "")
    yield tmp_path


# ─── 1. Historique des sessions ───────────────────────────────────────────────

class TestSessionStore:
    def test_save_and_reload(self, tmp_path):
        path = tmp_path / ".sessions.json"
        store = SessionStore(path)
        offers = [make_offer(1, "Ingénieur Robotique", "ROS2 Python", score=8)]
        criteria = {"query": "robotique", "cv": "cv.pdf", "country": "fr",
                    "location": "Rennes", "sectors": ["tech"], "experience": "junior",
                    "sources": ["adzuna"], "min_score": 6, "exclude": ["senior"]}
        session_id = store.add_session("scan", criteria, offers, found=12)

        # Relecture depuis le disque par une nouvelle instance
        store2 = SessionStore(path)
        sessions = store2.list_sessions()
        assert len(sessions) == 1
        assert sessions[0]["id"] == session_id
        assert sessions[0]["found"] == 12
        assert sessions[0]["kept"] == 1
        assert sessions[0]["criteria"]["query"] == "robotique"
        assert sessions[0]["criteria"]["experience"] == "junior"

        # Les offres sont reconstruites avec leur score de l'époque
        session = store2.get_session(session_id)
        rebuilt = store2.session_offers(session)
        assert len(rebuilt) == 1
        assert rebuilt[0].title == "Ingénieur Robotique"
        assert rebuilt[0].match_score == 8
        assert rebuilt[0].unique_key() == offers[0].unique_key()

    def test_all_offers_dedup_latest_wins(self, tmp_path):
        store = SessionStore(tmp_path / ".sessions.json")
        old = make_offer(1, "Dev Python", "Django", score=5)
        store.add_session("scan", {}, [old, make_offer(2, "Roboticien", "ROS2", score=7)])
        newer = make_offer(1, "Dev Python", "Django", score=9)  # même offre, nouveau score
        store.add_session("scan", {}, [newer])

        all_offers = store.all_offers()
        assert len(all_offers) == 2  # dédupliqué par unique_key
        dev = next(o for o in all_offers if o.title == "Dev Python")
        assert dev.match_score == 9  # la version la plus récente gagne

    def test_letters_registry(self, tmp_path):
        store = SessionStore(tmp_path / ".sessions.json")
        offer = make_offer(1, "Dev Python")
        store.add_letter(offer, tone="directe", language="fr",
                         txt_file="lettre.txt", pdf_file="lettre.pdf")
        letters = SessionStore(tmp_path / ".sessions.json").list_letters()
        assert len(letters) == 1
        assert letters[0]["offer_key"] == offer.unique_key()
        assert letters[0]["tone"] == "directe"
        assert letters[0]["language"] == "fr"

    def test_corrupt_file_recovered(self, tmp_path):
        path = tmp_path / ".sessions.json"
        path.write_text("{ pas du json", encoding="utf-8")
        store = SessionStore(path)
        assert store.list_sessions() == []
        assert path.with_suffix(".json.corrupt").exists()  # historique mis de côté

    def test_session_cap(self, tmp_path):
        store = SessionStore(tmp_path / ".sessions.json")
        from history import _MAX_SESSIONS
        for i in range(_MAX_SESSIONS + 5):
            store._data["sessions"].append({"id": f"s{i}", "offers": []})
        store.add_session("scan", {}, [])
        assert len(store._data["sessions"]) == _MAX_SESSIONS


# ─── 2. Pré-filtre du re-scoring (code pur, aucun appel IA) ──────────────────

class TestRescorePrefilter:
    CV = ("Ingénieur robotique : Python, ROS2, navigation autonome, simulation "
          "Gazebo, vision OpenCV, C++, contrôle moteur, capteurs lidar")

    def test_prefilter_drops_irrelevant(self):
        matcher = JobMatcher(self.CV)
        relevant = make_offer(1, "Roboticien", "Python ROS2 navigation simulation")
        irrelevant = make_offer(2, "Boulanger", "pétrissage viennoiseries fournil")
        kept, dropped = matcher._prefilter([relevant, irrelevant])
        assert kept == [relevant]
        assert dropped == 1

    def test_top_k_keeps_best_overlap(self):
        matcher = JobMatcher(self.CV)
        strong = make_offer(1, "Robotique", "Python ROS2 navigation Gazebo OpenCV lidar")
        medium = make_offer(2, "Dev", "Python ROS2 simulation capteurs")
        weak = make_offer(3, "Support", "Python ROS2 vision")
        kept, dropped = matcher._prefilter([weak, strong, medium], top_k=2)
        assert len(kept) == 2
        assert strong in kept and medium in kept
        assert dropped == 1

    def test_two_stage_prescore_keeps_top(self, monkeypatch):
        """Le pré-scoring IA (mocké) classe les offres et ne garde que le top."""
        from ai import matcher as matcher_mod
        monkeypatch.setattr(matcher_mod, "TWO_STAGE_KEEP", 2)
        matcher = JobMatcher(self.CV)

        def fake_generate(system, user, max_tokens=1024, json_schema=None, **kw):
            count = user.count("<offre")
            return json.dumps({"results": [
                {"job_index": j, "score": 9 - j} for j in range(count)
            ]})
        monkeypatch.setattr(matcher._llm_prescore, "generate", fake_generate)

        offers = [make_offer(i, f"Poste {i}", "Python ROS2 navigation") for i in range(4)]
        top = matcher._prescore(offers)
        assert len(top) == 2
        assert top[0].title == "Poste 0"  # meilleur score simulé en premier


# ─── 2a-bis. Filtres type de contrat + années d'expérience ───────────────────

class TestContractFilter:
    def test_skip_alternance_quand_cdi_voulu(self):
        m = JobMatcher("CV")
        m._contracts = {"cdi", "cdd"}
        offers = [
            make_offer(1, "Dev Python", "Poste en CDI à pourvoir"),
            make_offer(2, "Data", "contrat en alternance / apprentissage"),
            make_offer(3, "Ingénieur", "rejoignez notre belle équipe"),  # ambigu
        ]
        kept, dropped = m._contract_filter(offers)
        titles = [o.title for o in kept]
        assert "Data" not in titles          # alternance écartée
        assert dropped == 1
        assert "Ingénieur" in titles         # ambigu conservé

    def test_aucun_contrat_selectionne_ne_filtre_pas(self):
        m = JobMatcher("CV")
        m._contracts = set()
        offers = [make_offer(1, "Alternance", "alternance")]
        kept, dropped = m._contract_filter(offers)
        assert dropped == 0 and len(kept) == 1


class TestExperienceYears:
    def test_junior_ecarte_3_ans(self):
        m = JobMatcher("CV")
        m._experience_level = "junior"
        offers = [
            make_offer(1, "Dev", "Vous avez 3 ans d'expérience minimum"),  # 3 > 2 → écartée
            make_offer(2, "Dev", "Débutant accepté, formation assurée"),    # conservée
            make_offer(3, "Dev", "2 ans d'expérience souhaités"),           # 2 ≤ 2 → conservée
        ]
        kept, dropped = m._experience_filter(offers)
        assert dropped == 1
        assert all("3 ans" not in o.description for o in kept)

    def test_sans_niveau_ne_filtre_pas(self):
        m = JobMatcher("CV")
        m._experience_level = ""
        offers = [make_offer(1, "Dev", "10 ans d'expérience exigés")]
        kept, dropped = m._experience_filter(offers)
        assert dropped == 0 and len(kept) == 1


# ─── 2b. Robustesse du parsing de réponse (modèles locaux capricieux) ─────────

class TestParseResponse:
    CV = "Python, ROS2, navigation autonome"

    def _scored(self, raw: str):
        matcher = JobMatcher(self.CV)
        batch = [make_offer(0, "Roboticien", "Python ROS2")]
        matcher._parse_response(raw, batch)  # ne doit jamais lever
        return batch[0]

    def test_resultats_non_liste_ne_plantent_pas(self):
        # "results" en entier / dict / chaîne : un for naïf lèverait TypeError
        for raw in ('{"results": 5}', '{"results": {"job_index": 0}}',
                    '{"results": "oops"}'):
            offer = self._scored(raw)
            assert offer.match_score is None  # aucun score appliqué, pas de crash

    def test_resultats_liste_valide_applique_score(self):
        offer = self._scored('{"results": [{"job_index": 0, "score": 8, '
                             '"reasons": "ok", "strengths": "x", "gaps": "y"}]}')
        assert offer.match_score == 8

    def test_recuperation_tableau_dans_texte(self):
        # Pas de clé "results" : récupération du tableau noyé dans du texte
        offer = self._scored('blabla [{"job_index": 0, "score": 7, "reasons": "", '
                             '"strengths": "", "gaps": ""}] fin')
        assert offer.match_score == 7


# ─── 2c. Transparence : progression lot par lot vers le journal web ───────────

class TestProgressCallback:
    CV = "Python, ROS2, navigation autonome, simulation, vision"

    def test_progress_recoit_chaque_lot(self, monkeypatch):
        """Le callback progress doit recevoir un message par lot d'analyse —
        c'est ce qui alimente le journal en direct de l'interface web."""
        matcher = JobMatcher(self.CV)

        def fake_score_batch(batch):
            for o in batch:
                o.match_score = 7
        monkeypatch.setattr(matcher, "_score_batch", fake_score_batch)

        offers = [make_offer(i, f"Dev {i}", "Python ROS2 navigation simulation vision")
                  for i in range(25)]  # 3 lots de 10
        logs: list[str] = []
        matcher.score_offers(offers, min_score=5, progress=logs.append)

        # Un message « Lot k/3 » par lot + un suivi cumulatif « analysée(s) »
        lots = [m for m in logs if m.startswith("Lot ")]
        assert len(lots) == 3
        assert any("3/3" in m for m in lots)
        assert any("offre(s) analysée(s)" in m for m in logs)

    def test_sans_progress_aucune_erreur(self, monkeypatch):
        """progress=None (mode CLI) : le scoring fonctionne sans callback."""
        matcher = JobMatcher(self.CV)
        monkeypatch.setattr(matcher, "_score_batch",
                            lambda batch: [setattr(o, "match_score", 8) for o in batch])
        offers = [make_offer(i, f"Dev {i}", "Python ROS2 navigation simulation") for i in range(5)]
        result = matcher.score_offers(offers, min_score=5)  # progress par défaut = None
        assert len(result) == 5


# ─── 3. Génération de lettre (LLM simulé) ─────────────────────────────────────

class FakeLLM:
    def __init__(self, payload: dict):
        self.payload = payload
        self.last_user_prompt = ""

    def generate(self, system, user, max_tokens=2048, json_schema=None, **kw):
        self.last_user_prompt = user
        return json.dumps(self.payload)

    def stream(self, system, user, max_tokens=2048, cache_system=True):
        # La lettre est générée en flux : on renvoie le JSON en un morceau.
        self.last_user_prompt = user
        yield json.dumps(self.payload)


class TestCoverLetter:
    def test_language_detection(self):
        assert detect_language("Nous recherchons un ingénieur pour notre équipe à Paris") == "fr"
        assert detect_language("We are looking for an engineer to join our team") == "en"
        assert detect_language("") == "fr"  # défaut : français

    def test_generate_french_structure(self):
        generator = CoverLetterGenerator("CV : Python, ROS2")
        fake = FakeLLM({"letter": "Madame, Monsieur, ...",
                        "email_subject": "Candidature", "email_body": "Bonjour"})
        generator._llm = fake
        offer = make_offer(1, "Ingénieur Robotique",
                           "Nous recherchons un ingénieur pour rejoindre notre équipe.")
        result = generator.generate(offer, tone="formelle")
        assert result["language"] == "fr"
        assert result["letter"].startswith("Madame")
        assert "Vous-Moi-Nous" in fake.last_user_prompt  # structure FR classique

    def test_generate_english_achievements(self):
        generator = CoverLetterGenerator("CV : Python, ROS2")
        fake = FakeLLM({"letter": "Dear Hiring Manager, ...",
                        "email_subject": "Application", "email_body": "Hello"})
        generator._llm = fake
        offer = make_offer(1, "Robotics Engineer",
                           "We are looking for an engineer to join our team and work on robots.")
        result = generator.generate(offer, tone="standard")
        assert result["language"] == "en"
        assert "IN ENGLISH" in fake.last_user_prompt
        assert "achievements" in fake.last_user_prompt  # orientée résultats

    def test_generate_partial_recovery(self):
        """Streaming interrompu (timeout/coupure) : on récupère le texte déjà
        produit, marqué partiel, sans relecture."""
        generator = CoverLetterGenerator("CV : Python, ROS2")

        class Cut:
            def stream(self, system, user, max_tokens=2048, cache_system=True):
                yield '{"letter": "Madame, Monsieur, je candidate au poste'
                raise RuntimeError("connexion coupée")

        generator._llm = Cut()
        offer = make_offer(1, "Dev", "Nous recherchons pour notre équipe")
        result = generator.generate(offer)
        assert result["partial"] is True
        assert result["letter"].startswith("Madame, Monsieur, je candidate")
        assert any("interrompue" in n.lower() for n in result["review_notes"])

    def test_generate_stream_fail_falls_back(self):
        """Si le streaming échoue avant tout chunk, on retombe sur l'appel
        non-streamé (qui gère AI_FALLBACK) — lettre complète, pas partielle."""
        generator = CoverLetterGenerator("CV : Python, ROS2")

        class FailStream:
            def stream(self, system, user, max_tokens=2048, cache_system=True):
                raise ConnectionError("stream indisponible")
                yield  # noqa: marque la fonction comme générateur

            def generate(self, system, user, max_tokens=2048, json_schema=None, **kw):
                return json.dumps({"letter": "Madame (repli non-streamé)",
                                   "email_subject": "x", "email_body": "y"})

        generator._llm = FailStream()
        result = generator.generate(make_offer(1, "Dev", "Nous recherchons pour notre équipe"))
        assert result["partial"] is False
        assert "repli" in result["letter"]

    def test_salvage_letter_decode(self):
        from ai.cover_letter import _salvage_letter
        assert _salvage_letter('{"letter": "Bonjour\\nMonde", "email_subject": "x"}') == "Bonjour\nMonde"
        assert _salvage_letter('{"letter": "Tronqué sans fin') == "Tronqué sans fin"
        assert _salvage_letter("texte brut sans json") == "texte brut sans json"

    def test_doc_type_message_uses_message_prompt(self):
        """doc_type='message' → gabarit « message d'approche », pas la lettre."""
        generator = CoverLetterGenerator("CV : Python")
        fake = FakeLLM({"letter": "Bonjour, je suis intéressé.",
                        "email_subject": "Candidature", "email_body": ""})
        generator._llm = fake
        offer = make_offer(1, "Dev", "Nous recherchons pour notre équipe à Paris")
        result = generator.generate(offer, doc_type="message", max_words=150)
        assert result["doc_type"] == "message"
        assert "MESSAGE COURT" in fake.last_user_prompt
        assert "150 mots" in fake.last_user_prompt
        assert "Vous-Moi-Nous" not in fake.last_user_prompt

    def test_doc_type_default_is_lettre(self):
        generator = CoverLetterGenerator("CV : Python")
        fake = FakeLLM({"letter": "Madame, Monsieur,", "email_subject": "x", "email_body": "y"})
        generator._llm = fake
        result = generator.generate(make_offer(1, "Dev", "Nous recherchons pour notre équipe"))
        assert result["doc_type"] == "lettre"
        assert "LETTRE DE MOTIVATION" in fake.last_user_prompt

    def test_max_words_borne(self):
        """max_words est borné (80–1200) dans generate() avant injection."""
        generator = CoverLetterGenerator("CV : Python")
        fake = FakeLLM({"letter": "Madame,", "email_subject": "x", "email_body": "y"})
        generator._llm = fake
        offer = make_offer(1, "Dev", "Nous recherchons pour notre équipe")
        generator.generate(offer, max_words=5)
        assert "80 mots" in fake.last_user_prompt   # plancher
        generator.generate(offer, max_words=99999)
        assert "1200 mots" in fake.last_user_prompt  # plafond

    def test_save_includes_candidate_contact(self, monkeypatch, tmp_path):
        monkeypatch.setattr(config, "candidate_name", "Jean Dupont")
        monkeypatch.setattr(config, "candidate_email", "jean@exemple.com")
        generator = CoverLetterGenerator("CV")
        offer = make_offer(1, "Dev Python")
        txt_path, _ = generator.save(offer, {
            "letter": "Corps de la lettre.", "email_subject": "Objet", "email_body": "Email",
        })
        content = txt_path.read_text(encoding="utf-8")
        assert content.startswith("Jean Dupont")
        assert "jean@exemple.com" in content
        assert "Corps de la lettre." in content
        assert "EMAIL D'ACCOMPAGNEMENT" in content


# ─── 4. Export PDF ────────────────────────────────────────────────────────────

class TestPdfExport:
    def test_pdf_written_with_candidate_header(self, monkeypatch, tmp_path):
        pytest.importorskip("fpdf")
        monkeypatch.setattr(config, "candidate_name", "Jean Dupont")
        generator = CoverLetterGenerator("CV")
        offer = make_offer(1, "Ingénieur Émérite — détails")
        _, pdf_path = generator.save(offer, {
            "letter": "Premier paragraphe.\n\nDeuxième paragraphe avec accents : éàü.",
        })
        assert pdf_path.exists()
        assert pdf_path.read_bytes()[:5] == b"%PDF-"


# ─── 5. Routage IA par tâche ──────────────────────────────────────────────────

class TestLLMRouting:
    def test_default_follows_provider(self, monkeypatch):
        monkeypatch.setattr(config, "provider", "ollama")
        backend, model = llm_client.resolve_backend("match")
        assert backend == "ollama"
        assert model == config.ollama_model

    def test_per_task_override(self, monkeypatch):
        monkeypatch.setattr(config, "provider", "anthropic")
        monkeypatch.setattr(config, "ai_prescore_backend", "local")
        monkeypatch.setattr(config, "ai_prescore_model", "qwen3:4b")
        assert llm_client.resolve_backend("prescore") == ("ollama", "qwen3:4b")
        # Les autres tâches suivent toujours le provider
        assert llm_client.resolve_backend("letter")[0] == "anthropic"

    def test_fallback_used_on_failure(self, monkeypatch):
        monkeypatch.setattr(config, "ai_match_backend", "local")
        monkeypatch.setattr(config, "ai_fallback", "claude")
        client = llm_client.LLMClient(task="match")
        calls = []

        def fake_call(backend, model, *args, **kwargs):
            calls.append(backend)
            if backend == "ollama":
                raise RuntimeError("Ollama down")
            return "réponse de secours"
        monkeypatch.setattr(client, "_call", fake_call)

        assert client.generate("sys", "user") == "réponse de secours"
        assert calls == ["ollama", "anthropic"]

    def test_no_fallback_raises(self, monkeypatch):
        monkeypatch.setattr(config, "ai_match_backend", "local")
        monkeypatch.setattr(config, "ai_fallback", "none")
        client = llm_client.LLMClient(task="match")

        def fake_call(backend, model, *args, **kwargs):
            raise RuntimeError("Ollama down")
        monkeypatch.setattr(client, "_call", fake_call)

        with pytest.raises(RuntimeError):
            client.generate("sys", "user")

    def test_fallback_never_same_backend(self, monkeypatch):
        monkeypatch.setattr(config, "ai_match_backend", "local")
        monkeypatch.setattr(config, "ai_fallback", "local")  # identique au primaire
        assert llm_client._fallback_backend("ollama") is None
