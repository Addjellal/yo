"""Tests des correctifs : typo lettres, HTML/sections offres, noms d'export
ASCII, arborescence output/, retries scrapers, suggestions de modèles locaux."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from ai.cover_letter import fix_typography
from job_scrapers.base import (
    strip_html, extract_sections, fetch_with_retry, JobOffer,
)
from integrations.local_models import suggest_models


class TestFixTypography(unittest.TestCase):
    def test_repare_majuscule_accentuee(self):
        self.assertEqual(fix_typography("Îquipe dynamique"), "Équipe dynamique")
        self.assertEqual(fix_typography("Îgalement motivé"), "Également motivé")

    def test_repare_ordinaux(self):
        self.assertEqual(fix_typography("en 2Îme lieu"), "en 2ème lieu")

    def test_preserve_ile(self):
        self.assertEqual(fix_typography("sur l'Île-de-France"), "sur l'Île-de-France")
        self.assertEqual(fix_typography("un Îlot calme"), "un Îlot calme")

    def test_espaces(self):
        self.assertEqual(fix_typography("bonjour  ,  merci ."), "bonjour, merci.")

    def test_texte_sain_inchange(self):
        text = "Madame, Monsieur,\n\nVotre offre d'Équipe m'intéresse."
        self.assertEqual(fix_typography(text), text)


class TestStripHtml(unittest.TestCase):
    def test_texte_brut_inchange(self):
        self.assertEqual(strip_html("Poste de dev Python.\nCDI."), "Poste de dev Python.\nCDI.")

    def test_balises_supprimees(self):
        out = strip_html("<p>Vos missions</p><ul><li>coder</li><li>tester</li></ul>")
        self.assertNotIn("<", out)
        self.assertIn("Vos missions", out)
        self.assertIn("coder", out)

    def test_entites_decodees(self):
        self.assertEqual(strip_html("R&amp;D &eacute;quipe"), "R&D équipe")

    def test_br_devient_saut_de_ligne(self):
        out = strip_html("ligne 1<br/>ligne 2")
        self.assertIn("ligne 1\nligne 2", out)


class TestExtractSections(unittest.TestCase):
    DESC = (
        "Entreprise leader.\n"
        "Vos missions :\n- développer\n- maintenir\n"
        "Profil recherché\n3 ans d'expérience Python.\n"
        "Compétences requises :\nPython, SQL, Docker\n"
    )

    def test_sections_detectees(self):
        sections = extract_sections(self.DESC)
        self.assertIn("missions", sections)
        self.assertIn("profil", sections)
        self.assertIn("competences", sections)
        self.assertIn("développer", sections["missions"])
        self.assertIn("Python, SQL", sections["competences"])

    def test_sans_titres_vide(self):
        self.assertEqual(extract_sections("Une description plate sans titres."), {})

    def test_to_text_met_les_sections_en_avant(self):
        offer = JobOffer(
            id="t1", title="Dev", company="ACME", location="Paris",
            description=self.DESC, url="https://example.com", source="Test",
        )
        text = offer.to_text()
        self.assertIn("Missions :", text)
        self.assertIn("Profil recherché :", text)


class TestAsciiSlug(unittest.TestCase):
    def test_accents_translitteres(self):
        from main import _ascii_slug
        self.assertEqual(_ascii_slug("développeur Python"), "developpeur_Python")
        # plus de « Fichier non autorisé » au téléchargement
        import re
        self.assertTrue(re.fullmatch(r"[A-Za-z0-9 ._-]+", _ascii_slug("ingénieur ML é à ç")))

    def test_vide_donne_defaut(self):
        from main import _ascii_slug
        self.assertEqual(_ascii_slug("éàç" * 0), "recherche")
        self.assertEqual(_ascii_slug("···"), "recherche")


class TestFetchWithRetry(unittest.TestCase):
    class _Resp:
        def __init__(self, status):
            self.status_code = status

    def test_succes_immediat(self):
        resp = fetch_with_retry(lambda: self._Resp(200), "Test")
        self.assertEqual(resp.status_code, 200)

    def test_4xx_non_retente(self):
        calls = []
        resp = fetch_with_retry(lambda: (calls.append(1), self._Resp(400))[1], "Test")
        self.assertEqual(resp.status_code, 400)
        self.assertEqual(len(calls), 1)

    def test_5xx_retente_puis_reussit(self):
        import job_scrapers.base as base
        old_delays = base.RETRY_DELAYS
        base.RETRY_DELAYS = (0.0, 0.0, 0.0)
        try:
            calls = []

            def send():
                calls.append(1)
                return self._Resp(503 if len(calls) < 3 else 200)

            resp = fetch_with_retry(send, "Test")
            self.assertEqual(resp.status_code, 200)
            self.assertEqual(len(calls), 3)
        finally:
            base.RETRY_DELAYS = old_delays

    def test_5xx_persistant_leve(self):
        import requests
        import job_scrapers.base as base
        old_delays = base.RETRY_DELAYS
        base.RETRY_DELAYS = (0.0,)
        try:
            with self.assertRaises(requests.HTTPError):
                fetch_with_retry(lambda: self._Resp(500), "Test")
        finally:
            base.RETRY_DELAYS = old_delays


class TestSuggestModels(unittest.TestCase):
    def test_petite_machine(self):
        models = [s["model"] for s in suggest_models(4.0, None)]
        self.assertIn("tinyllama", models)

    def test_grosse_machine_gpu(self):
        models = [s["model"] for s in suggest_models(64.0, 24.0)]
        self.assertIn("mixtral", models)

    def test_memoire_inconnue(self):
        self.assertTrue(suggest_models(None, None))


class TestOutputPaths(unittest.TestCase):
    def test_find_refuse_chemins(self):
        from output_paths import find_output_file
        # Tout chemin est réduit à son nom nu : pas de traversée possible
        self.assertIsNone(find_output_file("../../etc/passwd"))
        self.assertIsNone(find_output_file("/etc/passwd"))

    def test_sous_dossiers_crees(self):
        from output_paths import letters_dir, offers_raw_dir, logs_dir
        self.assertTrue(letters_dir().is_dir())
        self.assertTrue(offers_raw_dir().is_dir())
        self.assertTrue(logs_dir().is_dir())


if __name__ == "__main__":
    unittest.main()
