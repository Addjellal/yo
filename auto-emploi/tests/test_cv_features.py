"""
Tests des fonctionnalités CV & lettres enrichies : skills de rédaction,
exemples de style (few-shot), registre des CV (profil IA + corrections
manuelles + suppression), extraction structurée, matching multi-CV.

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
from cv_store import CVStore, _clean_profile, render_profile, list_cv_files
from ai import matcher as matcher_mod
from ai.matcher import JobMatcher, score_offers_multi
from ai import cover_letter as cl
from ai.cover_letter import (
    CoverLetterGenerator, load_skill, merge_cv_texts, recent_letter_examples,
)
from ai.cv_extract import CVExtractor


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


class FakeLLM:
    """Double du client LLM : mémorise les prompts, répond un JSON fixe."""
    def __init__(self, payload):
        self.payload = payload
        self.last_system = ""
        self.last_user = ""

    def generate(self, system, user, max_tokens=2048, json_schema=None, **kw):
        self.last_system = system
        self.last_user = user
        return json.dumps(self.payload)


@pytest.fixture(autouse=True)
def isolated_config(tmp_path, monkeypatch):
    """Sorties dans un dossier temporaire + config IA neutre."""
    monkeypatch.setattr(config, "output_dir", str(tmp_path))
    monkeypatch.setattr(config, "provider", "anthropic")
    monkeypatch.setattr(config, "ai_prescore_backend", "")
    monkeypatch.setattr(config, "ai_match_backend", "")
    monkeypatch.setattr(config, "ai_letter_backend", "")
    monkeypatch.setattr(config, "ai_fallback", "none")
    monkeypatch.setattr(config, "letter_examples", "off")
    monkeypatch.setattr(config, "candidate_name", "")
    monkeypatch.setattr(config, "candidate_email", "")
    monkeypatch.setattr(config, "candidate_phone", "")
    monkeypatch.setattr(config, "candidate_city", "")
    yield tmp_path


# ─── 1. Skills de rédaction (prompts/skills/*.md) ─────────────────────────────

class TestSkills:
    def test_skill_files_exist_and_load(self):
        fr = load_skill("fr")
        en = load_skill("en")
        assert "Vous – Moi – Nous" in fr
        assert "ATS" in fr
        assert "results-first" in en or "achievement" in en

    def test_skill_injected_into_system_prompt_fr(self):
        generator = CoverLetterGenerator("CV : Python, ROS2")
        fake = FakeLLM({"letter": "Madame, Monsieur, ...",
                        "email_subject": "x", "email_body": "y"})
        generator._llm = fake
        offer = make_offer(1, "Ingénieur Robotique",
                           "Nous recherchons un ingénieur pour rejoindre notre équipe.")
        generator.generate(offer)
        assert "GUIDE DE RÉDACTION" in fake.last_system
        assert "Vous – Moi – Nous" in fake.last_system  # skill FR

    def test_skill_injected_into_system_prompt_en(self):
        generator = CoverLetterGenerator("CV: Python")
        fake = FakeLLM({"letter": "Dear...", "email_subject": "x", "email_body": "y"})
        generator._llm = fake
        offer = make_offer(1, "Robotics Engineer",
                           "We are looking for an engineer to join our team.")
        generator.generate(offer)
        assert "GUIDE DE RÉDACTION" in fake.last_system
        assert "Dear Hiring Manager" in fake.last_system  # skill EN

    def test_missing_skill_dir_degrades_gracefully(self, tmp_path, monkeypatch):
        monkeypatch.setattr(cl, "_SKILLS_DIR", tmp_path / "absent")
        assert load_skill("fr") == ""
        generator = CoverLetterGenerator("CV")
        fake = FakeLLM({"letter": "ok", "email_subject": "x", "email_body": "y"})
        generator._llm = fake
        generator.generate(make_offer(1, "Poste", "Nous recherchons pour notre équipe"))
        assert "GUIDE DE RÉDACTION" not in fake.last_system

    def test_user_can_edit_skill(self, tmp_path, monkeypatch):
        """Le fichier est relu à chaque appel : une édition est prise en compte."""
        skills = tmp_path / "skills"
        skills.mkdir()
        (skills / "lettre_fr.md").write_text("CONSIGNE V1", encoding="utf-8")
        monkeypatch.setattr(cl, "_SKILLS_DIR", skills)
        assert load_skill("fr") == "CONSIGNE V1"
        (skills / "lettre_fr.md").write_text("CONSIGNE V2", encoding="utf-8")
        assert load_skill("fr") == "CONSIGNE V2"


# ─── 2. Exemples de style (few-shot) ──────────────────────────────────────────

class TestStyleExamples:
    def test_examples_injected_for_matching_language(self):
        generator = CoverLetterGenerator(
            "CV", style_examples={"fr": ["Texte de ma lettre précédente ABC"], "en": []},
        )
        fake = FakeLLM({"letter": "ok", "email_subject": "x", "email_body": "y"})
        generator._llm = fake
        generator.generate(make_offer(1, "Poste", "Nous recherchons un profil pour notre équipe"))
        assert "EXEMPLES DE STYLE" in fake.last_user
        assert "Texte de ma lettre précédente ABC" in fake.last_user

    def test_no_examples_for_other_language(self):
        generator = CoverLetterGenerator(
            "CV", style_examples={"fr": ["Exemple FR"], "en": []},
        )
        fake = FakeLLM({"letter": "ok", "email_subject": "x", "email_body": "y"})
        generator._llm = fake
        generator.generate(make_offer(1, "Engineer", "We are looking for an engineer to join the team"))
        assert "EXEMPLES DE STYLE" not in fake.last_user

    def test_recent_letter_examples_reads_store_files(self, tmp_path):
        store = SessionStore(tmp_path / ".sessions.json")
        body = "Madame, Monsieur,\n\nMon style inimitable.\n\nCordialement."
        (tmp_path / "lettre_test.txt").write_text(
            "En-tête\n\nLETTRE DE MOTIVATION\n" + "-" * 60 + "\n\n" + body,
            encoding="utf-8",
        )
        store.add_letter(make_offer(1, "Dev"), tone="standard", language="fr",
                         txt_file="lettre_test.txt", pdf_file="")
        examples = recent_letter_examples(store)
        assert examples["fr"] == [body]
        assert examples["en"] == []


# ─── 3. Fusion multi-CV pour les lettres ──────────────────────────────────────

class TestMergeCvTexts:
    def test_single_cv_passthrough(self):
        assert merge_cv_texts({"cv": "contenu brut"}) == "contenu brut"

    def test_multi_cv_named_blocks(self):
        merged = merge_cv_texts({"CV Data": "texte data", "CV Robotique": "texte robot"})
        assert "PLUSIEURS CV" in merged
        assert '<cv source="CV Data">' in merged
        assert '<cv source="CV Robotique">' in merged
        assert "texte data" in merged and "texte robot" in merged

    def test_label_quotes_neutralized(self):
        merged = merge_cv_texts({'CV "spécial"': "a", "autre": "b"})
        assert '"spécial"' not in merged.split("\n")[0]
        assert "<cv source=\"CV 'spécial'\">" in merged


# ─── 4. Registre des CV (profil, corrections, suppression) ───────────────────

class TestCVStore:
    def test_register_idempotent(self, tmp_path):
        store = CVStore(tmp_path / ".cvs.json")
        a = store.register("mon_cv.pdf")
        b = store.register("mon_cv.pdf")
        assert a["id"] == b["id"]
        assert a["label"] == "mon_cv"
        # Relecture disque
        again = CVStore(tmp_path / ".cvs.json").get("mon_cv.pdf")
        assert again["id"] == a["id"]

    def test_lookup_by_id_filename_label(self, tmp_path):
        store = CVStore(tmp_path / ".cvs.json")
        entry = store.register("cv_data.pdf")
        store.set_label(entry["id"], "CV Data 2026")
        assert store.get(entry["id"])["id"] == entry["id"]
        assert store.get("cv_data.pdf")["id"] == entry["id"]
        assert store.get("cv data 2026")["id"] == entry["id"]  # label, casse libre

    def test_manual_overrides_win(self, tmp_path):
        store = CVStore(tmp_path / ".cvs.json")
        entry = store.register("cv.pdf")
        store.set_profile(entry["id"], {
            "contact": {"name": "Extrait IA", "email": "ia@x.fr"},
            "skills": [{"category": "Langages", "items": ["Python"]}],
        })
        store.set_overrides(entry["id"], {
            "contact": {"name": "Corrigé Manuel", "email": "moi@x.fr"},
        })
        profile, sources = CVStore.effective_profile(store.get(entry["id"]))
        assert profile["contact"]["name"] == "Corrigé Manuel"   # le manuel gagne
        assert sources["contact"] == "manual"
        assert sources["skills"] == "ai"                         # section non touchée

    def test_overrides_removed_reverts_to_ai(self, tmp_path):
        store = CVStore(tmp_path / ".cvs.json")
        entry = store.register("cv.pdf")
        store.set_profile(entry["id"], {"contact": {"name": "IA"}})
        store.set_overrides(entry["id"], {"contact": {"name": "Manuel"}})
        store.set_overrides(entry["id"], {})  # retour à l'extraction
        profile, sources = CVStore.effective_profile(store.get(entry["id"]))
        assert profile["contact"]["name"] == "IA"
        assert sources["contact"] == "ai"

    def test_effective_text_appends_priority_block(self, tmp_path):
        store = CVStore(tmp_path / ".cvs.json")
        entry = store.register("cv.pdf")
        store.set_overrides(entry["id"], {
            "skills": [{"category": "Langages", "items": ["Rust", "Go"]}],
        })
        text = store.effective_text(store.get(entry["id"]), "TEXTE BRUT DU CV")
        assert text.startswith("TEXTE BRUT DU CV")
        assert "VÉRIFIÉES PAR LE CANDIDAT" in text
        assert "Rust, Go" in text
        # Sans override : texte inchangé
        entry2 = store.register("autre.pdf")
        assert store.effective_text(entry2, "BRUT") == "BRUT"

    def test_delete_keeps_history_label(self, tmp_path):
        store = CVStore(tmp_path / ".cvs.json")
        entry = store.register("vieux_cv.pdf")
        store.set_label(entry["id"], "Mon vieux CV")
        deleted = store.mark_deleted(entry["id"])
        assert deleted["deleted"] is True
        assert store.get("vieux_cv.pdf") is None  # plus actif
        # L'historique affiche un libellé cohérent
        assert store.history_label("vieux_cv.pdf", file_exists=False) == "CV supprimé : Mon vieux CV"
        # Ré-upload du même nom : entrée neuve, le tombstone reste
        fresh = store.register("vieux_cv.pdf")
        assert fresh["id"] != entry["id"]
        assert store.history_label("vieux_cv.pdf", file_exists=True) == "vieux_cv"

    def test_unknown_cv_missing_file_label(self, tmp_path):
        store = CVStore(tmp_path / ".cvs.json")
        assert store.history_label("inconnu.pdf", file_exists=False) == "CV supprimé : inconnu.pdf"
        assert store.history_label("inconnu.pdf", file_exists=True) == "inconnu.pdf"

    def test_active_entry_missing_file_label(self, tmp_path):
        """Entrée active dont le fichier a disparu (CV hors projet) :
        pas de faux « supprimé », mais un avertissement explicite."""
        store = CVStore(tmp_path / ".cvs.json")
        store.register("ailleurs.pdf")
        assert store.history_label("ailleurs.pdf", file_exists=False) == \
            "ailleurs (fichier introuvable)"

    def test_clean_profile_bounds(self):
        dirty = {
            "contact": {"name": "X" * 500, "junk": "dropped"},
            "skills": [{"category": "Cat", "items": ["i" * 500] * 100}] * 50,
            "experiences": [{"title": "T", "company": "C", "evil": "x"}] * 50,
            "languages": [{"name": "", "level": "vide ignoré"}],
            "inconnu": "ignoré",
        }
        cleaned = _clean_profile(dirty)
        assert len(cleaned["contact"]["name"]) == 80
        assert "junk" not in cleaned["contact"]
        assert len(cleaned["skills"]) == 12
        assert len(cleaned["skills"][0]["items"]) == 30
        assert len(cleaned["skills"][0]["items"][0]) == 60
        assert len(cleaned["experiences"]) == 20
        assert "evil" not in cleaned["experiences"][0]
        assert "languages" not in cleaned  # entrée sans nom → section omise
        assert "inconnu" not in cleaned

    def test_render_profile_readable(self):
        text = render_profile({
            "contact": {"name": "Jean", "headline": "Dev", "email": "j@x.fr", "phone": "", "city": "Rennes"},
            "skills": [{"category": "Langages", "items": ["Python", "Go"]}],
            "experiences": [{"title": "Dev", "company": "ACME", "start": "2023", "end": "auj.", "description": "Fait des trucs."}],
            "languages": [{"name": "Anglais", "level": "C1"}],
        })
        assert "Jean" in text and "Langages" in text
        assert "Dev — ACME (2023–auj.)" in text
        assert "Anglais (C1)" in text

    def test_list_cv_files_filters(self, tmp_path):
        (tmp_path / "cv.pdf").write_bytes(b"x")
        (tmp_path / "notes.docx").write_bytes(b"x")
        (tmp_path / "requirements.txt").write_text("x")
        (tmp_path / ".cache.pdf").write_bytes(b"x")
        (tmp_path / "code.py").write_text("x")
        assert list_cv_files(tmp_path) == ["cv.pdf", "notes.docx"]


# ─── 5. Extraction IA du profil ───────────────────────────────────────────────

class TestCVExtract:
    PROFILE = {
        "contact": {"name": "Jean Dupont", "headline": "Ingénieur", "email": "j@x.fr",
                    "phone": "06", "city": "Rennes"},
        "skills": [{"category": "Langages", "items": ["Python"]}],
        "experiences": [{"title": "Dev", "company": "ACME", "start": "2023",
                         "end": "auj.", "description": "Plateforme robotique."}],
        "education": [{"degree": "Master", "school": "INSA", "year": "2022"}],
        "languages": [{"name": "Anglais", "level": "C1"}],
    }

    def test_extract_returns_clean_profile(self, monkeypatch):
        extractor = CVExtractor()
        fake = FakeLLM(self.PROFILE)
        monkeypatch.setattr(extractor, "_llm", fake)
        profile = extractor.extract("CV de Jean Dupont, ingénieur Python à Rennes")
        assert profile["contact"]["name"] == "Jean Dupont"
        assert profile["skills"][0]["items"] == ["Python"]
        assert profile["education"][0]["degree"] == "Master"
        assert "CV de Jean Dupont" in fake.last_user  # le CV est bien transmis

    def test_extract_recovers_json_in_prose(self, monkeypatch):
        extractor = CVExtractor()
        raw = "Voici le profil :\n" + json.dumps(self.PROFILE) + "\nVoilà."

        def fake_generate(**kw):
            return raw
        monkeypatch.setattr(extractor._llm, "generate", lambda *a, **k: raw)
        profile = extractor.extract("CV")
        assert profile["contact"]["name"] == "Jean Dupont"

    def test_extract_raises_on_garbage(self, monkeypatch):
        extractor = CVExtractor()
        monkeypatch.setattr(extractor._llm, "generate", lambda *a, **k: "pas de json ici")
        with pytest.raises(ValueError):
            extractor.extract("CV")


# ─── 6. Matching multi-CV ─────────────────────────────────────────────────────

CV_ROBOT = "Ingénieur robotique : Python, ROS2, navigation autonome, Gazebo, lidar"
CV_WEB = "Développeur web : Python, Django, React, SQL, API REST, backend"


def fake_score_batch(self, batch):
    """Score déterministe selon le CV du matcher : robot vs web."""
    robot_cv = "ROS2" in self.cv_text
    for offer in batch:
        is_robot_offer = "robot" in offer.title.lower()
        offer.match_score = (9 if is_robot_offer else 3) if robot_cv else (2 if is_robot_offer else 8)
        offer.match_reasons = f"éval {'robot' if robot_cv else 'web'}"
        offer.match_strengths = "atouts"
        offer.match_gaps = "lacunes"


class TestMultiCV:
    @pytest.fixture(autouse=True)
    def no_prefilter(self, monkeypatch):
        # Pré-filtre neutralisé : on teste la fusion, pas l'overlap de mots-clés
        monkeypatch.setattr(matcher_mod, "PRE_FILTER_THRESHOLD", 0)
        monkeypatch.setattr(JobMatcher, "_score_batch", fake_score_batch)

    def offers(self):
        return [
            make_offer(1, "Ingénieur Robotique", "Python ROS2 navigation"),
            make_offer(2, "Développeur Web", "Python Django React"),
        ]

    def test_best_cv_wins_and_detail_kept(self):
        results = score_offers_multi(
            {"CV Robot": CV_ROBOT, "CV Web": CV_WEB}, self.offers(), min_score=6,
        )
        assert len(results) == 2
        robot = next(o for o in results if "Robotique" in o.title)
        web = next(o for o in results if "Web" in o.title)

        assert robot.match_score == 9
        assert robot.best_cv == "CV Robot"
        assert robot.cv_scores["CV Robot"]["score"] == 9
        assert robot.cv_scores["CV Web"]["score"] == 2     # détail par CV conservé

        assert web.match_score == 8
        assert web.best_cv == "CV Web"
        # Tri par meilleur score décroissant
        assert results[0] is robot

    def test_min_score_filters_on_best(self):
        results = score_offers_multi(
            {"CV Robot": CV_ROBOT, "CV Web": CV_WEB}, self.offers(), min_score=9,
        )
        assert [o.title for o in results] == ["Ingénieur Robotique"]  # web : best 8 < 9

    def test_single_cv_keeps_legacy_behavior(self):
        results = score_offers_multi({"CV Robot": CV_ROBOT}, self.offers(), min_score=6)
        assert len(results) == 1                  # l'offre web score 3 → filtrée
        assert results[0].cv_scores is None       # pas de détail multi en mono-CV
        assert results[0].best_cv is None

    def test_single_cv_resets_stale_multi_fields(self):
        # Offres rechargées d'une session multi-CV puis re-scorées avec 1 CV :
        # best_cv/cv_scores de l'ancienne session ne doivent pas survivre.
        offers = self.offers()
        for o in offers:
            o.best_cv = "Ancien CV"
            o.cv_scores = {"Ancien CV": {"score": 9, "reasons": "", "strengths": "", "gaps": ""}}
        results = score_offers_multi({"CV Robot": CV_ROBOT}, offers, min_score=0)
        assert results and all(o.best_cv is None for o in results)
        assert all(o.cv_scores is None for o in results)

    def test_original_offers_untouched(self):
        offers = self.offers()
        score_offers_multi({"CV Robot": CV_ROBOT, "CV Web": CV_WEB}, offers, min_score=0)
        assert all(o.match_score is None for o in offers)  # copies seulement

    def test_session_store_roundtrips_cv_scores(self, tmp_path):
        results = score_offers_multi(
            {"CV Robot": CV_ROBOT, "CV Web": CV_WEB}, self.offers(), min_score=6,
        )
        store = SessionStore(tmp_path / ".sessions.json")
        store.add_session("scan", {}, results)
        rebuilt = SessionStore(tmp_path / ".sessions.json").all_offers()
        robot = next(o for o in rebuilt if "Robotique" in o.title)
        assert robot.best_cv == "CV Robot"
        assert robot.cv_scores["CV Web"]["score"] == 2
