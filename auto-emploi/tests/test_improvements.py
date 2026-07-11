"""Tests des correctifs : typo lettres, HTML/sections offres, noms d'export
ASCII, arborescence output/, retries scrapers, suggestions de modèles locaux."""
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from ai.cover_letter import (
    fix_typography, letter_issues, CoverLetterGenerator,
)
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


class TestLetterIssues(unittest.TestCase):
    GOOD = "Madame, Monsieur,\n\n" + "Votre offre m'intéresse vivement. " * 25

    def test_lettre_correcte_aucun_defaut(self):
        self.assertEqual(letter_issues(self.GOOD), [])

    def test_trop_courte(self):
        self.assertTrue(any("courte" in i for i in letter_issues("Bonjour.")))

    def test_marqueurs_gabarit(self):
        issues = letter_issues(self.GOOD + "\n\nSignature [Votre nom], réf XXXX.")
        self.assertTrue(any("gabarit" in i for i in issues))

    def test_paragraphe_duplique(self):
        para = "Je suis très motivé par ce poste et votre entreprise me passionne."
        issues = letter_issues(f"Madame,\n\n{para}\n\n{para}")
        self.assertTrue(any("dupliqué" in i for i in issues))


class TestLetterReview(unittest.TestCase):
    """La relecture IA est conservatrice : elle n'adopte une correction que si
    elle est plausible (longueur proche, pas de nouveaux défauts)."""

    def _gen(self):
        gen = CoverLetterGenerator.__new__(CoverLetterGenerator)
        gen.cv_text = "Développeur Python, 5 ans d'expérience."
        return gen

    def _job(self):
        return JobOffer(id="j1", title="Dev Python", company="ACME",
                        location="Paris", description="Poste Python.",
                        url="https://example.com", source="Test")

    def _patch_review(self, gen, payload):
        import ai.cover_letter as cl

        class _FakeClient:
            def __init__(self, task="match"):
                pass

            def generate(self, **kw):
                return json.dumps(payload)

        self._orig = cl.LLMClient
        cl.LLMClient = _FakeClient

    def tearDown(self):
        import ai.cover_letter as cl
        if hasattr(self, "_orig"):
            cl.LLMClient = self._orig

    def test_correction_plausible_adoptee(self):
        original = "Madame, Monsieur,\n\n" + "Phrase correcte. " * 30
        fixed = "Madame, Monsieur,\n\n" + "Phrase corrigée. " * 30
        gen = self._gen()
        self._patch_review(gen, {"issues": ["accent corrigé"], "corrected_letter": fixed})
        out, notes = gen._review(self._job(), "fr", original, [])
        self.assertEqual(out, fixed.strip())
        self.assertIn("accent corrigé", notes)

    def test_correction_tronquee_rejetee(self):
        original = "Madame, Monsieur,\n\n" + "Phrase correcte. " * 30
        gen = self._gen()
        self._patch_review(gen, {"issues": ["x"], "corrected_letter": "Trop court."})
        out, _ = gen._review(self._job(), "fr", original, [])
        self.assertEqual(out, original)  # original conservé

    def test_backend_indisponible_garde_original(self):
        import ai.cover_letter as cl
        original = "Madame, Monsieur,\n\n" + "Phrase correcte. " * 30

        class _Boom:
            def __init__(self, task="match"):
                pass

            def generate(self, **kw):
                raise RuntimeError("backend down")

        self._orig = cl.LLMClient
        cl.LLMClient = _Boom
        out, notes = self._gen()._review(self._job(), "fr", original, ["défaut"])
        self.assertEqual(out, original)
        self.assertEqual(notes, ["défaut"])


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


class TestCleanLlmHtml(unittest.TestCase):
    """Nettoyage conservateur du HTML émis par les modèles dans les lettres :
    retire les vraies balises sans abîmer les « < » / « > » en prose."""

    def setUp(self):
        from ai.cover_letter import _clean_llm_html
        self.clean = _clean_llm_html

    def test_br_devient_paragraphe(self):
        self.assertEqual(self.clean("Mon experience <br><br> en auto."),
                         "Mon experience\n\nen auto.")

    def test_balises_bloc_et_inline(self):
        self.assertEqual(self.clean("<p>Bonjour,</p><p>Je postule.</p>"), "Bonjour,\nJe postule.")
        self.assertEqual(self.clean("Je suis <strong>autonome</strong>."), "Je suis autonome.")

    def test_comparaison_en_prose_preservee(self):
        # Régression : « < 45k et > » ne doit JAMAIS être pris pour une balise.
        self.assertEqual(self.clean("Salaire < 45k et > 35k selon profil."),
                         "Salaire < 45k et > 35k selon profil.")
        self.assertEqual(self.clean("si x<y alors ok"), "si x<y alors ok")

    def test_entites_decodees(self):
        self.assertEqual(self.clean("Python &amp; C++, prix &lt; 100&euro;."),
                         "Python & C++, prix < 100€.")

    def test_texte_propre_inchange(self):
        # Sans « < » ni « & » : aucun traitement, formatage intact.
        txt = "Para 1.\n\nPara 2 avec   espaces.\n\nCordialement,"
        self.assertEqual(self.clean(txt), txt)

    def test_rd_sans_point_virgule_preserve(self):
        self.assertEqual(self.clean("experience en R&D et gestion"), "experience en R&D et gestion")


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


class TestCsvSafe(unittest.TestCase):
    """Anti-injection de formules ET anti-injection de lignes dans l'export CSV."""

    def test_prefixe_formule_neutralise(self):
        from main import _csv_safe
        for dangereux in ("=CMD()", "+1+2", "-2+3", "@SUM", "|cmd", "%bad"):
            self.assertTrue(_csv_safe(dangereux).startswith("'"),
                            f"{dangereux!r} devrait être préfixé d'une apostrophe")

    def test_tabulation_neutralisee(self):
        from main import _csv_safe
        self.assertEqual(_csv_safe("\t=evil")[0], "'")

    def test_valeur_normale_inchangee(self):
        from main import _csv_safe
        self.assertEqual(_csv_safe("Développeur Python"), "Développeur Python")
        self.assertEqual(_csv_safe("Lyon, Rhône"), "Lyon, Rhône")

    def test_sauts_de_ligne_internes_neutralises(self):
        """Un \\r\\n interne pourrait injecter une fausse ligne CSV → remplacé par espace."""
        from main import _csv_safe
        out = _csv_safe("Dev\r\n=CMD|' /C calc'!A0")
        self.assertNotIn("\n", out)
        self.assertNotIn("\r", out)
        # Le = ne se retrouve plus en début de cellule (pas de nouvelle ligne)
        self.assertFalse(out.startswith("'"))  # commence par "Dev", inoffensif

    def test_none_donne_chaine_vide(self):
        from main import _csv_safe
        self.assertEqual(_csv_safe(None), "")

    def test_espace_avant_formule_neutralise(self):
        """Un tableur qui rogne les espaces de tête ne doit pas re-exposer
        une formule cachée derrière un espace (« \\u00a0=cmd »)."""
        from main import _csv_safe
        self.assertTrue(_csv_safe("  =1+1").startswith("'"))
        self.assertTrue(_csv_safe(" \t@SUM").startswith("'"))

    def test_tabulation_interne_devient_espace(self):
        from main import _csv_safe
        self.assertEqual(_csv_safe("a\tb\tc"), "a b c")


class TestSaveResultsEmpty(unittest.TestCase):
    """save_results ne doit pas planter sur une liste d'offres vide (P5)."""

    def test_export_vide_ecrit_entete_seul(self):
        import os
        import tempfile
        from unittest import mock
        with tempfile.TemporaryDirectory() as tmp:
            with mock.patch.dict(os.environ, {"OUTPUT_DIR": tmp}):
                from config import config
                old = config.output_dir
                config.output_dir = tmp
                try:
                    from main import save_results
                    _, csv_path = save_results([], "rien")
                    content = csv_path.read_text(encoding="utf-8-sig").strip()
                finally:
                    config.output_dir = old
        self.assertEqual(
            content,
            "titre;entreprise;lieu;contrat;salaire;source;score;correspondance;url",
        )


class TestMinScoreClamp(unittest.TestCase):
    """_clean_criteria : min_score typé, borné 0–10, bool refusé (P4)."""

    def test_bool_refuse(self):
        from history import _clean_criteria
        self.assertEqual(_clean_criteria({"min_score": True})["min_score"], 6)
        self.assertEqual(_clean_criteria({"min_score": False})["min_score"], 6)

    def test_borne_haut_et_bas(self):
        from history import _clean_criteria
        self.assertEqual(_clean_criteria({"min_score": 9999})["min_score"], 10)
        self.assertEqual(_clean_criteria({"min_score": -5})["min_score"], 0)

    def test_valeur_valide_conservee(self):
        from history import _clean_criteria
        self.assertEqual(_clean_criteria({"min_score": 7})["min_score"], 7)

    def test_non_entier_donne_defaut(self):
        from history import _clean_criteria
        self.assertEqual(_clean_criteria({"min_score": "8"})["min_score"], 6)


class TestIndeedBalancedObject(unittest.TestCase):
    """Extraction du bundle mosaic Indeed par accolades équilibrées (Sc1)."""

    def test_objet_pretty_printed_complet(self):
        import json
        from job_scrapers.indeed import _balanced_object
        # '}' suivi d'un saut de ligne EN INTERNE : l'ancienne regex tronquait ici.
        html = ('window.x = {\n  "meta": {\n    "c": 1\n  },\n'
                '  "results": [1, 2, 3]\n}\n;tail')
        data = json.loads(_balanced_object(html, html.index("=")))
        self.assertEqual(data, {"meta": {"c": 1}, "results": [1, 2, 3]})

    def test_accolade_dans_chaine_ignoree(self):
        import json
        from job_scrapers.indeed import _balanced_object
        html = 'z = {"title": "Dev } H/F", "n": 5};'
        self.assertEqual(json.loads(_balanced_object(html, 0)),
                         {"title": "Dev } H/F", "n": 5})

    def test_absence_dobjet_donne_none(self):
        from job_scrapers.indeed import _balanced_object
        self.assertIsNone(_balanced_object("aucune accolade", 0))


class TestCleanLineStripHtml(unittest.TestCase):
    """Champs mono-ligne d'une offre : HTML retiré, rendu inerte (Sc3)."""

    def test_balise_script_retiree(self):
        from job_scrapers.base import _clean_line
        out = _clean_line("<script>alert(1)</script>Dev", 300)
        self.assertNotIn("<", out)
        self.assertNotIn("script", out.lower())
        self.assertIn("Dev", out)

    def test_entites_decodees(self):
        from job_scrapers.base import _clean_line
        self.assertEqual(_clean_line("Smith &amp; Co", 300), "Smith & Co")

    def test_texte_simple_inchange(self):
        from job_scrapers.base import _clean_line
        self.assertEqual(_clean_line("Développeur Python", 300), "Développeur Python")


class TestLetterFileName(unittest.TestCase):
    """Nom de fichier d'une lettre : accents translittérés (é → e), pas
    remplacés par « _ » — sinon le téléchargement affichait « d_veloppeur »."""

    def _name(self, title, company):
        import re
        import unicodedata
        folded = unicodedata.normalize("NFKD", f"{title}_{company}").encode("ascii", "ignore").decode("ascii")
        return re.sub(r"[^a-z0-9_-]", "_", folded.lower())[:60].strip("_") or "lettre"

    def test_save_translittere_les_accents(self):
        import re
        from ai.cover_letter import CoverLetterGenerator
        gen = CoverLetterGenerator("CV")
        offer = JobOffer(id="1", title="Développeur Réseau", company="Société Générale",
                         location="Paris", description="", url="https://x/1", source="t")

        captured = {}
        gen._save_pdf = lambda path, job, letter: captured.setdefault("pdf", path)
        import output_paths
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            original = output_paths.letters_dir
            output_paths.letters_dir = lambda: Path(d)
            try:
                txt, pdf = gen.save(offer, {"letter": "Madame, Monsieur,", "email_subject": "", "email_body": ""})
            finally:
                output_paths.letters_dir = original
        self.assertEqual(txt.stem, "developpeur_reseau_societe_generale")
        self.assertNotIn("_veloppeur", txt.stem)        # é n'a pas été perdu
        self.assertTrue(re.fullmatch(r"[a-z0-9_-]+", txt.stem))  # toujours sûr

    def test_pas_de_traversee_de_chemin(self):
        import re
        self.assertTrue(re.fullmatch(r"[a-z0-9_-]+", self._name("../../etc", "passwd")))
        self.assertNotIn("/", self._name("a/b\\c", ".."))


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


class TestAvailabilityCheck(unittest.TestCase):
    """Vérification de disponibilité sans IA : mapping des codes HTTP."""

    def _check(self, head_code, get_code=None, raise_exc=False):
        import requests
        import webapp.server as srv

        class _R:
            def __init__(self, code):
                self.status_code = code

            def close(self):
                pass

        orig_head, orig_get = requests.head, requests.get
        try:
            if raise_exc:
                requests.head = lambda *a, **k: (_ for _ in ()).throw(requests.RequestException("x"))
            else:
                requests.head = lambda *a, **k: _R(head_code)
            requests.get = lambda *a, **k: _R(get_code if get_code is not None else head_code)
            return srv._check_one("https://example.com/offre")
        finally:
            requests.head, requests.get = orig_head, orig_get

    def test_en_ligne(self):
        self.assertIs(self._check(200)["available"], True)

    def test_retiree(self):
        self.assertIs(self._check(404)["available"], False)
        self.assertIs(self._check(410)["available"], False)

    def test_indetermine(self):
        self.assertIsNone(self._check(500, 500)["available"])
        self.assertIsNone(self._check(0, raise_exc=True)["available"])

    def test_url_non_http_rejetee(self):
        import webapp.server as srv
        self.assertIsNone(srv._check_one("javascript:alert(1)")["available"])
        self.assertIsNone(srv._check_one("")["available"])

    def test_ssrf_guard(self):
        """Anti-SSRF : seules les URLs http(s) vers un hôte public passent."""
        import webapp.server as srv
        self.assertTrue(srv._is_public_http_url("https://www.apec.fr/offre/1"))
        self.assertTrue(srv._is_public_http_url("https://fr.indeed.com/viewjob?jk=ab"))
        for bad in ("http://127.0.0.1:8765/", "http://localhost/x",
                    "http://169.254.169.254/latest/meta-data/", "http://192.168.0.1/",
                    "http://10.1.1.1/", "ftp://example.com/x", "http://[::1]/"):
            self.assertFalse(srv._is_public_http_url(bad), bad)


class TestLetterFileParsing(unittest.TestCase):
    """Aperçu d'une lettre : décodage du fichier .txt généré par save()."""

    SEP = "=" * 60

    def _make(self, with_email=True):
        email = ""
        if with_email:
            email = ("EMAIL D'ACCOMPAGNEMENT\n" + "-" * 60 + "\n"
                     + "Objet : Candidature Dev\n\nBonjour, ma candidature.\n\n"
                     + self.SEP + "\n\n")
        return ("Jean Dupont\njean@x.fr\n\n"
                "Poste : Dev\nEntreprise : ACME\nSource : apec\nURL : https://x/y\n\n"
                + self.SEP + "\n\n" + email
                + "LETTRE DE MOTIVATION\n" + "-" * 60 + "\n\nMadame, Monsieur,\n\nCorps.")

    def test_parse_avec_email(self):
        import webapp.server as srv
        d = srv._parse_letter_file(self._make(True))
        self.assertEqual(d["email_subject"], "Candidature Dev")
        self.assertEqual(d["email_body"], "Bonjour, ma candidature.")
        self.assertTrue(d["letter"].startswith("Madame, Monsieur,"))

    def test_parse_sans_email(self):
        import webapp.server as srv
        d = srv._parse_letter_file(self._make(False))
        self.assertEqual(d["email_subject"], "")
        self.assertEqual(d["letter"], "Madame, Monsieur,\n\nCorps.")

    def test_header_block_preserve(self):
        import webapp.server as srv
        h = srv._letter_header_block(self._make(True))
        self.assertIn("Poste : Dev", h)
        self.assertIn("Jean Dupont", h)
        self.assertTrue(h.endswith("\n\n"))
        self.assertNotIn("LETTRE DE MOTIVATION", h)


class TestMatchedOffersSplit(unittest.TestCase):
    """Retenues + mises de côté cohabitent dans job.offers ; aside_from sépare
    les deux. _matched_offers ne renvoie que les retenues (export, Notion, dispo,
    historique) — sans recalcul ni pollution par les offres sous le seuil."""

    def _offer(self, i):
        return JobOffer(id=f"o{i}", title=f"Poste {i}", company="C", location="P",
                        description="", url=f"https://x/{i}", source="t")

    def test_sans_mise_de_cote(self):
        import webapp.server as srv
        job = srv._Job("scan")
        job.offers = [self._offer(0), self._offer(1)]
        job.aside_from = None  # session rechargée : tout est retenu
        self.assertEqual(srv._matched_offers(job), job.offers)

    def test_frontiere_aside_from(self):
        import webapp.server as srv
        job = srv._Job("scan")
        kept = [self._offer(0), self._offer(1)]
        aside = [self._offer(2)]
        job.offers = kept + aside
        job.aside_from = len(kept)
        self.assertEqual([o.id for o in srv._matched_offers(job)], ["o0", "o1"])

    def test_aucune_retenue_que_des_mises_de_cote(self):
        import webapp.server as srv
        job = srv._Job("scan")
        job.offers = [self._offer(0)]
        job.aside_from = 0  # 0 retenue, 1 mise de côté
        self.assertEqual(srv._matched_offers(job), [])


class TestMultiLocation(unittest.TestCase):
    """Plusieurs localisations : normalisation de la saisie utilisateur."""

    def test_split_separateurs(self):
        import webapp.server as srv
        self.assertEqual(srv._parse_locations(None, "Rennes, Nantes; Paris\nLyon"),
                         ["Rennes", "Nantes", "Paris", "Lyon"])

    def test_dedoublonne_insensible_casse(self):
        import webapp.server as srv
        self.assertEqual(srv._parse_locations(["Lyon", "lyon", "  "], ""), ["Lyon"])

    def test_vide_sans_filtre(self):
        import webapp.server as srv
        self.assertEqual(srv._parse_locations(None, ""), [])

    def test_plafond_huit(self):
        import webapp.server as srv
        self.assertEqual(len(srv._parse_locations(None, ",".join(str(i) for i in range(20)))), 8)


class TestOutputPaths(unittest.TestCase):
    def test_find_refuse_chemins(self):
        from output_paths import find_output_file
        # Tout chemin est réduit à son nom nu : pas de traversée possible
        self.assertIsNone(find_output_file("../../etc/passwd"))
        self.assertIsNone(find_output_file("/etc/passwd"))

    def test_find_refuse_dotfiles(self):
        """État interne jamais exposable au téléchargement, même par nom nu (P1)."""
        import os
        import tempfile
        from unittest import mock
        from config import config
        with tempfile.TemporaryDirectory() as tmp:
            # Crée de vrais fichiers d'état pour prouver qu'ils restent introuvables
            for name in (".sessions.json", ".cvs.json", ".tracker.json", ".env"):
                (Path(tmp) / name).write_text("secret")
            with mock.patch.dict(os.environ, {"OUTPUT_DIR": tmp}):
                old = config.output_dir
                config.output_dir = tmp
                try:
                    from output_paths import find_output_file
                    for name in (".sessions.json", ".cvs.json", ".tracker.json", ".env"):
                        self.assertIsNone(find_output_file(name), name)
                finally:
                    config.output_dir = old

    def test_migration_anciens_fichiers(self):
        import tempfile
        from pathlib import Path
        from config import config
        import output_paths as op
        old_dir = config.output_dir
        tmp = tempfile.mkdtemp()
        config.output_dir = tmp
        try:
            root = Path(tmp)
            (root / "dev.json").write_text("[]")
            (root / "dev.csv").write_text("x")
            (root / "Lettre_ACME.txt").write_text("l")
            (root / ".tracker.json").write_text("{}")     # état interne
            (root / "x.corrupt").write_text("x")           # non concerné
            self.assertEqual(op.migrate_legacy_files(), 3)
            self.assertTrue((op.offers_scored_dir() / "dev.json").exists())
            self.assertTrue((op.offers_scored_dir() / "dev.csv").exists())
            self.assertTrue((op.letters_dir() / "Lettre_ACME.txt").exists())
            self.assertTrue((root / ".tracker.json").exists())   # jamais déplacé
            self.assertTrue((root / "x.corrupt").exists())
            self.assertEqual(op.migrate_legacy_files(), 0)       # idempotent
        finally:
            config.output_dir = old_dir

    def test_sous_dossiers_crees(self):
        from output_paths import letters_dir, offers_raw_dir, logs_dir
        self.assertTrue(letters_dir().is_dir())
        self.assertTrue(offers_raw_dir().is_dir())
        self.assertTrue(logs_dir().is_dir())


class TestAuditFixes(unittest.TestCase):
    """Régressions des correctifs d'audit : robustesse scrapers, lecture texte
    tolérante, neutralisation du chemin de cache, départage multi-CV sûr."""

    def test_cache_path_neutralise_traversee(self):
        from pathlib import Path
        from config import config
        import cv_parser
        evil = Path("/tmp/../../etc/cv évadé.txt")
        cache = cv_parser._cache_path(evil)
        # Le cache reste sous output/ (sous-dossier cv/.cache) et le nom ne
        # contient aucun séparateur ni « .. »
        self.assertEqual(cache.parent, Path(config.output_dir).resolve() / "cv" / ".cache")
        self.assertNotIn("..", cache.name)
        self.assertNotIn("/", cache.name)
        self.assertTrue(cache.name.startswith(".cv_"))

    def test_read_text_tolerant_cp1252(self):
        import tempfile, os
        from pathlib import Path
        import cv_parser
        fd, p = tempfile.mkstemp(suffix=".txt")
        os.close(fd)
        try:
            # « é » en cp1252 (0xE9) : invalide en UTF-8 strict
            Path(p).write_bytes(b"Profil ing\xe9nieur logiciel")
            txt = cv_parser._read_text_tolerant(Path(p))
            self.assertIn("ingénieur", txt)
        finally:
            os.unlink(p)

    def test_write_cache_atomic_permissions(self):
        import tempfile, os, sys
        from pathlib import Path
        import cv_parser
        d = tempfile.mkdtemp()
        try:
            cache = Path(d) / ".cv_test.txt"
            cv_parser._write_cache_atomic(cache, "contenu")
            self.assertEqual(cache.read_text(encoding="utf-8"), "contenu")
            if sys.platform != "win32":
                self.assertEqual(cache.stat().st_mode & 0o777, 0o600)
        finally:
            import shutil
            shutil.rmtree(d, ignore_errors=True)

    def test_scrapers_resistent_aux_champs_null(self):
        # company/organization/location présents mais null → offre conservée,
        # pas de crash AttributeError.
        from job_scrapers.adzuna import AdzunaScraper
        from job_scrapers.talent import TalentScraper
        a = AdzunaScraper.__new__(AdzunaScraper)
        off = a._parse_item({"id": "1", "title": "Dev", "company": None,
                             "location": None, "redirect_url": "https://x"})
        self.assertIsNotNone(off)
        self.assertEqual(off.company, "N/A")

        t = TalentScraper.__new__(TalentScraper)
        off = t._parse_jsonld_item({"title": "Dev", "hiringOrganization": None,
                                    "jobLocation": None}, "https://fr.talent.com")
        self.assertIsNotNone(off)
        self.assertEqual(off.company, "N/A")

    def test_france_travail_range_pagination_valide(self):
        # Invariant de la pagination : tant que len(offers) < target, le range
        # calculé reste valide (last >= start), donc jamais de « 50-49 » / « 0--1 ».
        from job_scrapers.france_travail import PAGE_SIZE, MAX_RANGE
        for target in (1, 50, 300, 10_000):
            start = 0
            got = 0
            steps = 0
            while got < target and start <= MAX_RANGE and steps < 50:
                last = min(start + PAGE_SIZE - 1, MAX_RANGE, start + (target - got) - 1)
                self.assertGreaterEqual(last, start)   # range jamais inversé
                self.assertLessEqual(last, MAX_RANGE)
                got += (last - start + 1)              # simule une page pleine
                start = last + 1
                steps += 1

    def test_clamp_score_accepte_float(self):
        from history import _clamp_score
        self.assertEqual(_clamp_score(7.0), 7)
        self.assertEqual(_clamp_score(7.6), 8)
        self.assertEqual(_clamp_score(42), 10)        # borné à 10
        self.assertEqual(_clamp_score(-3), 0)         # borné à 0
        self.assertEqual(_clamp_score("9"), 0)        # non numérique → défaut
        self.assertIsNone(_clamp_score(None, default=None))
        self.assertEqual(_clamp_score(True), 0)       # bool exclu

    def test_save_to_env_rejette_numerique_invalide(self):
        from config import config, save_to_env
        before = config.min_match_score
        with self.assertRaises(ValueError):
            save_to_env("MIN_MATCH_SCORE", "pas-un-nombre")
        # La valeur en mémoire n'a pas changé (et rien n'a été écrit dans .env).
        self.assertEqual(config.min_match_score, before)

    def test_tracker_stats_statut_inconnu(self):
        import tracker as tk
        t = tk.Tracker.__new__(tk.Tracker)
        t._data = {"offers": {
            "a": {"status": "applied"},
            "b": {"status": "zombie"},   # statut hérité/inconnu
            "c": {"status": "seen"},
        }}
        stats = t.stats()
        self.assertNotIn("zombie", stats)
        self.assertEqual(stats["total"], 3)
        # « zombie » est rattaché à seen (avec c) → 2.
        self.assertEqual(stats["seen"], 2)

    def test_redact_notion_masque_les_secrets(self):
        from integrations import notion
        msg = "auth failed: Bearer ntn_ABCDEFGH12345678 rejected"
        red = notion._redact(msg)
        self.assertNotIn("ntn_ABCDEFGH12345678", red)
        self.assertIn("***", red)

    def test_get_json_rejette_schemas_non_http(self):
        from integrations.local_models import _get_json
        self.assertIsNone(_get_json("file:///etc/passwd"))
        self.assertIsNone(_get_json("gopher://localhost/"))

    def test_save_survit_aux_surrogates(self):
        # Un surrogate isolé (\udfde, issu d'un PDF/scraping malformé) ne doit
        # PAS faire planter l'écriture utf-8 (« surrogates not allowed »).
        import tempfile, shutil
        from pathlib import Path
        from history import SessionStore
        from job_scrapers.base import JobOffer
        d = tempfile.mkdtemp()
        try:
            store = SessionStore(Path(d) / ".sessions.json")
            bad = JobOffer(id="x", title="Dev \udfde embarqué", company="ACME",
                           location="", description="desc \udfde", url="https://x",
                           source="Test")
            store.add_session(kind="web", criteria={}, offers=[bad], found=1)  # ne lève pas
            reloaded = SessionStore(Path(d) / ".sessions.json")
            self.assertEqual(len(reloaded.list_sessions()), 1)
        finally:
            shutil.rmtree(d, ignore_errors=True)

    def test_tidy_output_root_nettoie_la_racine(self):
        # Les caches .cv_*.txt sont déplacés vers cv/.cache/, les .tmp orphelins
        # supprimés ; les fichiers d'état (.sessions.json…) restent intacts.
        import tempfile, shutil
        from pathlib import Path
        from unittest import mock
        from config import config
        import output_paths
        d = tempfile.mkdtemp()
        try:
            root = Path(d)
            (root / ".cv_mon_cv_abc123.txt").write_text("cache", encoding="utf-8")
            (root / ".sessions_orphelin.tmp").write_text("", encoding="utf-8")
            (root / ".sessions.json").write_text("{}", encoding="utf-8")
            with mock.patch.object(config, "output_dir", str(root)):
                moved = output_paths._tidy_output_root(root)
            self.assertEqual(moved, 1)
            self.assertFalse((root / ".cv_mon_cv_abc123.txt").exists())
            self.assertTrue((root / "cv" / ".cache" / ".cv_mon_cv_abc123.txt").exists())
            self.assertFalse((root / ".sessions_orphelin.tmp").exists())
            self.assertTrue((root / ".sessions.json").exists())  # état préservé
        finally:
            shutil.rmtree(d, ignore_errors=True)


class TestPickBestAvailable(unittest.TestCase):
    """Sélection automatique du modèle de remplacement le plus adapté."""

    def _probe(self, models_gb):
        """Simule probe_ollama() avec une liste (nom, taille_go)."""
        return {"models": [{"name": n, "size_gb": s} for n, s in models_gb]}

    def _pick(self, missing, models_gb):
        from unittest import mock
        from ai._client import _pick_best_available
        import integrations.local_models as lm
        with mock.patch.object(lm, "probe_ollama", lambda: self._probe(models_gb)):
            return _pick_best_available(missing)

    def test_prend_le_plus_grand_en_dessous(self):
        # gemma3:12b (~7.8 GB) → préfère le plus grand modèle ≤ 7.8 GB
        result = self._pick("gemma3:12b", [
            ("llama3.2:latest", 2.0), ("qwen2.5:7b", 4.7), ("llama3.1:8b", 4.9),
        ])
        self.assertEqual(result, "llama3.1:8b")  # 4.9 GB : le plus grand ≤ 7.8

    def test_prend_le_plus_petit_au_dessus_si_rien_en_dessous(self):
        # gemma3:1b (~0.65 GB) → rien en-dessous, prend le plus petit au-dessus
        result = self._pick("gemma3:1b", [
            ("llama3.2:latest", 2.0), ("qwen2.5:7b", 4.7),
        ])
        self.assertEqual(result, "llama3.2:latest")

    def test_taille_inconnue_prend_le_plus_gros(self):
        # nom sans paramétrie → le plus gros disponible
        result = self._pick("mon-modele-custom", [
            ("llama3.2:latest", 2.0), ("qwen2.5:7b", 4.7),
        ])
        self.assertEqual(result, "qwen2.5:7b")

    def test_aucun_modele_retourne_none(self):
        from unittest import mock
        from ai._client import _pick_best_available
        import integrations.local_models as lm
        with mock.patch.object(lm, "probe_ollama", lambda: {"models": []}):
            self.assertIsNone(_pick_best_available("gemma3:12b"))

    def test_probe_echoue_retourne_none(self):
        from unittest import mock
        from ai._client import _pick_best_available
        import integrations.local_models as lm
        with mock.patch.object(lm, "probe_ollama", lambda: None):
            self.assertIsNone(_pick_best_available("gemma3:12b"))

    def test_estimate_model_gb(self):
        from ai._client import _estimate_model_gb
        self.assertAlmostEqual(_estimate_model_gb("gemma3:12b"), 7.8, places=1)
        self.assertAlmostEqual(_estimate_model_gb("qwen2.5:3b"), 1.95, places=1)
        self.assertIsNone(_estimate_model_gb("nomic-embed-text:latest"))

    def test_model_env_key_tache_specifique(self):
        from ai._client import _model_env_key
        from config import config
        orig = config.ai_match_model
        config.ai_match_model = "gemma3:12b"
        try:
            self.assertEqual(_model_env_key("match", "gemma3:12b"), "AI_MATCH_MODEL")
        finally:
            config.ai_match_model = orig

    def test_model_env_key_defaut(self):
        from ai._client import _model_env_key
        from config import config
        orig = config.ai_match_model
        config.ai_match_model = ""
        try:
            # Si la clé de tâche est vide, c'est OLLAMA_MODEL qui porte la valeur
            self.assertEqual(_model_env_key("match", "gemma3:12b"), "OLLAMA_MODEL")
        finally:
            config.ai_match_model = orig


class TestSaveToEnvModelValidation(unittest.TestCase):
    """save_to_env rejette un nom de modèle invalide AVANT toute écriture
    (sinon il serait silencieusement remplacé par le défaut au chargement)."""

    def test_nom_modele_invalide_rejete_sans_ecrire(self):
        from unittest import mock
        from config import save_to_env
        import config as cfg
        # Si la validation échoue, l'exception doit survenir avant mkstemp.
        with mock.patch.object(cfg.tempfile, "mkstemp",
                               side_effect=AssertionError("ne doit pas écrire")):
            with self.assertRaises(ValueError):
                save_to_env("OLLAMA_MODEL", "modèle invalide avec espaces")

    def test_valeur_vide_autorisee_pour_modele_de_tache(self):
        # AI_*_MODEL vide = « suivre le backend » : la validation ne doit pas
        # rejeter une chaîne vide (on vérifie juste qu'aucune ValueError de
        # format n'est levée ; l'écriture réelle est court-circuitée).
        from unittest import mock
        from config import save_to_env
        import config as cfg
        with mock.patch.object(cfg.tempfile, "mkstemp",
                               side_effect=RuntimeError("stop avant écriture")):
            with self.assertRaises(RuntimeError):   # pas ValueError de format
                save_to_env("AI_MATCH_MODEL", "")


class TestLLMTimeout(unittest.TestCase):
    """Délai LLM par tâche : toujours FINI. Les analyses (prescore/match) et
    LLM_TIMEOUT=0 reçoivent le plafond très large _SLOW_TASK_CEILING — jamais
    None : un appel suspendu ne doit pas tenir les verrous indéfiniment."""

    def setUp(self):
        from config import config
        self._orig = config.llm_timeout

    def tearDown(self):
        from config import config
        config.llm_timeout = self._orig

    def test_analyses_plafond_large_mais_fini(self):
        from ai._client import LLMClient, _SLOW_TASK_CEILING
        from config import config
        config.llm_timeout = 120
        self.assertEqual(LLMClient(task="prescore")._timeout(), _SLOW_TASK_CEILING)
        self.assertEqual(LLMClient(task="match")._timeout(), _SLOW_TASK_CEILING)

    def test_taches_interactives_bornees(self):
        from ai._client import LLMClient
        from config import config
        config.llm_timeout = 90
        self.assertEqual(LLMClient(task="letter")._timeout(), 90.0)
        self.assertEqual(LLMClient(task="review")._timeout(), 90.0)

    def test_zero_donne_le_plafond_large(self):
        from ai._client import LLMClient, _SLOW_TASK_CEILING
        from config import config
        config.llm_timeout = 0
        self.assertEqual(LLMClient(task="letter")._timeout(), _SLOW_TASK_CEILING)

    def test_valeur_invalide_retombe_sur_defaut(self):
        from ai._client import LLMClient
        from config import config
        config.llm_timeout = "pas un nombre"
        self.assertEqual(LLMClient(task="letter")._timeout(), 120.0)

    def test_config_accepte_zero(self):
        import os
        from config import _env_int
        os.environ["LLM_TIMEOUT_TEST_TMP"] = "0"
        try:
            self.assertEqual(_env_int("LLM_TIMEOUT_TEST_TMP", 120, 0, 600), 0)
        finally:
            del os.environ["LLM_TIMEOUT_TEST_TMP"]


class TestStartupModelCheck(unittest.TestCase):
    """Sonde des modèles locaux au démarrage : ne lève jamais, même sans serveur."""

    def test_aucun_serveur_ne_leve_pas(self):
        import io
        from contextlib import redirect_stdout
        from unittest import mock
        import integrations
        import webapp.server as srv
        with mock.patch.object(integrations, "detect_servers", lambda: []):
            with redirect_stdout(io.StringIO()):
                srv._startup_model_check()  # ne doit pas lever

    def test_detection_en_echec_ne_leve_pas(self):
        import io
        from contextlib import redirect_stdout
        from unittest import mock
        import integrations
        import webapp.server as srv

        def _boom():
            raise RuntimeError("nvidia-smi absent")

        with mock.patch.object(integrations, "detect_servers", _boom):
            with redirect_stdout(io.StringIO()):
                srv._startup_model_check()  # échec avalé, pas de crash


class TestTeeProgress(unittest.TestCase):
    """Le callback de progression alimente À LA FOIS le journal du job (affiché
    dans le navigateur) et le terminal — l'utilisateur suit l'état d'avancement
    et la fin des tâches directement dans le CMD."""

    def test_ecrit_dans_log_et_console(self):
        import webapp.server as srv
        from app_utils import console
        job = srv._Job("scan")
        cb = srv._tee_progress(job)
        with console.capture() as cap:
            cb("Lot 3/12 : analyse de 10 offre(s)…")
        self.assertIn("Lot 3/12 : analyse de 10 offre(s)…", job.log)
        self.assertIn("Lot 3/12", cap.get())

    def test_markup_rich_echappe(self):
        # Un message contenant des crochets ne doit pas être interprété comme du
        # balisage Rich (ni planter) : il s'affiche tel quel dans le terminal.
        import webapp.server as srv
        from app_utils import console
        job = srv._Job("scan")
        cb = srv._tee_progress(job)
        with console.capture() as cap:
            cb("[gras] texte brut")
        self.assertIn("[gras] texte brut", job.log)
        self.assertIn("[gras] texte brut", cap.get())


class TestSsrfGuards(unittest.TestCase):
    """Garde-fous anti-SSRF : la vérification de dispo d'une offre du web ne doit
    cibler que des hôtes publics ; les sondes de modèles locaux que des hôtes
    réellement locaux (loopback/LAN), jamais le link-local (métadonnées cloud)."""

    def test_offre_publique_autorisee(self):
        import webapp.server as srv
        self.assertTrue(srv._is_public_http_url("https://example.com/job"))
        self.assertTrue(srv._is_public_http_url("http://8.8.8.8/job"))

    def test_offre_interne_bloquee(self):
        import webapp.server as srv
        for u in ("http://127.0.0.1/x", "http://localhost/x",
                  "http://192.168.1.10/x", "http://10.0.0.5/x",
                  "http://169.254.169.254/latest/meta-data/",
                  "ftp://8.8.8.8/x"):
            self.assertFalse(srv._is_public_http_url(u), u)

    def test_sonde_locale_autorisee(self):
        from integrations.local_models import _is_local_url
        for u in ("http://localhost:11434/api/tags",
                  "http://127.0.0.1:11434/api/tags",
                  "http://192.168.1.50:11434/api/tags",
                  "http://10.0.0.5:11434/"):
            self.assertTrue(_is_local_url(u), u)

    def test_sonde_non_locale_bloquee(self):
        from integrations.local_models import _is_local_url
        for u in ("http://169.254.169.254/", "http://8.8.8.8/",
                  "https://evil.example.com/", "file:///etc/passwd"):
            self.assertFalse(_is_local_url(u), u)


class TestLetterTimeoutZero(unittest.TestCase):
    """LLM_TIMEOUT=0 = illimité : la lettre ne doit PAS être tronquée (« partiel »)
    dès le premier chunk reçu en flux."""

    def test_timeout_zero_ne_tronque_pas(self):
        import time
        import json as _json
        from unittest import mock
        from config import config
        from job_scrapers.base import JobOffer

        offer = JobOffer(id="1", title="Développeur Python", company="Acme",
                         location="Paris", description="Poste de dev backend.",
                         url="https://example.com/job", source="test")
        payload = _json.dumps({
            "letter": "Madame, Monsieur,\n\n" + "Je suis motivé. " * 30,
            "email_subject": "Candidature", "email_body": "Bonjour, ci-joint.",
            "language": "fr",
        })

        def fake_stream(*a, **k):
            # Plusieurs chunks avec une micro-pause : si la deadline valait
            # « maintenant+0 », le 2e chunk déclencherait « partiel ».
            for piece in (payload[:40], payload[40:]):
                time.sleep(0.01)
                yield piece

        gen = CoverLetterGenerator("CV de test")
        with mock.patch.object(config, "llm_timeout", 0), \
             mock.patch.object(config, "letter_review", "off"), \
             mock.patch.object(gen._llm, "stream", fake_stream):
            result = gen.generate(offer, tone="standard")
        self.assertFalse(result["partial"], "LLM_TIMEOUT=0 ne doit pas tronquer")
        self.assertIn("Je suis motivé", result["letter"])


class TestTalentScraper(unittest.TestCase):
    """Talent.com : payload RSC __next_f (principal), JSON-LD et cartes (repli)."""

    @staticmethod
    def _rsc_html(jobs):
        # Reconstitue un <script>self.__next_f.push([1,"…"])</script> réaliste :
        # Next.js double-encode (le tableau jobs est une chaîne JSON échappée).
        inner = '["$","$L2c",null,' + json.dumps({"jobs": jobs}) + ']'
        chunk = "self.__next_f.push([1," + json.dumps(inner) + "])"
        return f"<html><body><script>{chunk}</script></body></html>"

    def test_parse_next_f(self):
        from job_scrapers.talent import TalentScraper
        html = self._rsc_html([{
            "id": "606894651927700468",
            "source_title": "INGENIEUR ENVIRONNEMENT ET ENERGIE H/F",
            "distilled_title": "INGENIEUR ENVIRONNEMENT ET ENERGIE HF",
            "enrich_company_name": "Délifrance",
            "source_location": "Romans-sur-Isère, Drôme, France",
            "source_jobdesc_text": "Description du poste avec [crochets] et \"guillemets\".",
            "source_link": "https://inrecruitingfr.intervieweb.it/annunci.php?l=x",
            "show_salary_on_front": True,
            "enrich_salary_min": 40000, "enrich_salary_max": 50000,
            "enrich_salary_currency": "EUR",
        }])
        t = TalentScraper.__new__(TalentScraper)
        jobs = t._parse_next_f(html, "https://fr.talent.com")
        self.assertEqual(len(jobs), 1)
        j = jobs[0]
        self.assertEqual(j.title, "INGENIEUR ENVIRONNEMENT ET ENERGIE H/F")
        self.assertEqual(j.company, "Délifrance")
        self.assertEqual(j.location, "Romans-sur-Isère, Drôme, France")
        self.assertEqual(j.url, "https://fr.talent.com/view?id=606894651927700468")
        self.assertEqual(j.apply_url, "https://inrecruitingfr.intervieweb.it/annunci.php?l=x")
        self.assertIn("40000", j.salary or "")
        self.assertIn("[crochets]", j.description)  # crochets dans une chaîne : pas de coupure

    def test_next_f_prioritaire_sur_jsonld_et_cartes(self):
        # Si le payload RSC est présent, _parse_page ne retombe pas sur le reste.
        from job_scrapers.talent import TalentScraper
        rsc = self._rsc_html([{"id": "1", "source_title": "Vrai poste RSC",
                               "enrich_company_name": "Co"}])
        page = rsc.replace(
            "</body>",
            '<script type="application/ld+json">{"@type":"JobPosting",'
            '"title":"NE PAS LIRE","hiringOrganization":{"name":"X"}}</script>'
            '<div class="card"><h2 class="card__job-title">NON PLUS</h2></div></body>',
        )
        t = TalentScraper.__new__(TalentScraper)
        jobs = t._parse_page(page, "https://fr.talent.com")
        self.assertEqual([j.title for j in jobs], ["Vrai poste RSC"])

    def test_next_f_plusieurs_offres(self):
        from job_scrapers.talent import TalentScraper
        html = self._rsc_html([
            {"id": str(i), "source_title": f"Poste {i}",
             "enrich_company_name": f"Co{i}"} for i in range(5)
        ])
        t = TalentScraper.__new__(TalentScraper)
        jobs = t._parse_next_f(html, "https://fr.talent.com")
        self.assertEqual(len(jobs), 5)
        self.assertEqual(jobs[2].title, "Poste 2")

    def test_parse_jsonld_itemlist(self):
        from job_scrapers.talent import TalentScraper
        page = '''
        <html><head>
        <script type="application/ld+json">
        {"@context":"https://schema.org","@type":"ItemList","itemListElement":[
          {"@type":"ListItem","item":{"@type":"JobPosting","title":"Data Engineer",
            "url":"/view?id=42","employmentType":"CDI","datePosted":"2026-04-10",
            "hiringOrganization":{"@type":"Organization","name":"DataCorp"},
            "jobLocation":{"address":{"addressLocality":"Lyon","addressRegion":"ARA"}},
            "baseSalary":{"@type":"MonetaryAmount","currency":"EUR",
              "value":{"minValue":40000,"maxValue":50000}}}}]}
        </script></head><body></body></html>'''
        t = TalentScraper.__new__(TalentScraper)
        from bs4 import BeautifulSoup
        jobs = t._parse_jsonld(BeautifulSoup(page, "html.parser"), "https://fr.talent.com")
        self.assertEqual(len(jobs), 1)
        j = jobs[0]
        self.assertEqual(j.title, "Data Engineer")
        self.assertEqual(j.company, "DataCorp")
        self.assertEqual(j.location, "Lyon, ARA")
        self.assertEqual(j.url, "https://fr.talent.com/view?id=42")
        self.assertEqual(j.contract_type, "CDI")
        self.assertIn("40000", j.salary or "")

    def test_parse_cards_html(self):
        from job_scrapers.talent import TalentScraper
        page = '''
        <div class="card link__job-link" data-id="7">
          <a href="/view?id=7"><h2 class="card__job-title">Ingénieur QA</h2></a>
          <div class="card__job-empname-label">TestCo</div>
          <div class="card__job-location">Nantes</div>
          <div class="card__job-snippet">Tests automatisés, CI/CD.</div>
        </div>'''
        t = TalentScraper.__new__(TalentScraper)
        from bs4 import BeautifulSoup
        jobs = t._parse_cards(BeautifulSoup(page, "html.parser"), "https://fr.talent.com")
        self.assertEqual(len(jobs), 1)
        j = jobs[0]
        self.assertEqual(j.title, "Ingénieur QA")
        self.assertEqual(j.company, "TestCo")
        self.assertEqual(j.location, "Nantes")
        self.assertEqual(j.url, "https://fr.talent.com/view?id=7")

    def test_jsonld_prioritaire_sur_cartes(self):
        # Si du JSON-LD est présent, _parse_page ne retombe pas sur les cartes.
        from job_scrapers.talent import TalentScraper
        page = '''
        <script type="application/ld+json">
        {"@type":"JobPosting","title":"Dev","url":"/view?id=1",
         "hiringOrganization":{"name":"Co"}}</script>
        <div class="card"><h2 class="card__job-title">NE PAS LIRE</h2></div>'''
        t = TalentScraper.__new__(TalentScraper)
        jobs = t._parse_page(page, "https://fr.talent.com")
        self.assertEqual([j.title for j in jobs], ["Dev"])

    def test_domaine_par_pays(self):
        from job_scrapers import talent
        from config import config
        from unittest import mock
        with mock.patch.object(config, "country", "fr"):
            self.assertEqual(talent._domain(), "fr.talent.com")
        with mock.patch.object(config, "country", "us"):
            self.assertEqual(talent._domain(), "www.talent.com")
        with mock.patch.object(config, "country", "zz"):  # inconnu → défaut FR
            self.assertEqual(talent._domain(), "fr.talent.com")


class TestSourceMap(unittest.TestCase):
    """APEC et WTTJ retirés, Talent.com ajouté dans la liste des sources."""

    def test_sources_retirees_et_talent_present(self):
        from main import SOURCE_MAP
        self.assertNotIn("apec", SOURCE_MAP)
        self.assertNotIn("wttj", SOURCE_MAP)
        self.assertIn("talent", SOURCE_MAP)
        self.assertEqual(SOURCE_MAP["talent"][0], "Talent.com")

    def test_modules_supprimes(self):
        import importlib
        for mod in ("job_scrapers.apec", "job_scrapers.wttj"):
            with self.assertRaises(ImportError):
                importlib.import_module(mod)


class TestLocationSuggest(unittest.TestCase):
    """Autocomplétion : suggestions régions + villes, tolérantes aux accents."""

    def test_ville_prefixe(self):
        from locations import suggest_locations
        vals = [s["value"] for s in suggest_locations("fr", "renn")]
        self.assertIn("Rennes", vals)

    def test_accents_et_casse_ignores(self):
        from locations import suggest_locations
        # "ile" doit trouver "Île-de-France" (région), "PARI" → "Paris" (ville)
        self.assertIn("Île-de-France", [s["value"] for s in suggest_locations("fr", "ile")])
        self.assertEqual(
            [s["value"] for s in suggest_locations("fr", "PARI")][0], "Paris"
        )

    def test_type_region_vs_ville(self):
        from locations import suggest_locations
        types = {s["value"]: s["type"] for s in suggest_locations("fr", "bret")}
        self.assertEqual(types.get("Bretagne"), "region")

    def test_regions_etrangeres(self):
        from locations import suggest_locations
        # Les régions des autres pays sont aussi suggérées (type "region").
        types_de = {s["value"]: s["type"] for s in suggest_locations("de", "bav")}
        self.assertEqual(types_de.get("Bavière"), "region")
        types_us = {s["value"]: s["type"] for s in suggest_locations("us", "calif")}
        self.assertEqual(types_us.get("Californie"), "region")
        # Et les villes étrangères restent disponibles (repli intégré).
        self.assertIn("Munich", [s["value"] for s in suggest_locations("de", "munich")])

    def test_requete_vide_et_limite(self):
        from locations import suggest_locations
        self.assertEqual(suggest_locations("fr", ""), [])
        self.assertLessEqual(len(suggest_locations("fr", "a", limit=3)), 3)

    def test_gouv_communes_repli_silencieux(self):
        # Sans réseau (ou API en échec), le repli ne lève pas : renvoie None.
        import sys
        sys.path.insert(0, "webapp")
        import server
        import requests
        from unittest import mock

        def _boom(*a, **k):
            raise requests.RequestException("offline")

        with mock.patch.object(requests, "get", _boom):
            self.assertIsNone(server._gouv_communes("rennes"))

    def test_photon_filtre_pays_et_type(self):
        # Photon renvoie le monde entier : on ne garde que les lieux peuplés du
        # pays sélectionné, avec la région en métadonnée.
        import sys
        sys.path.insert(0, "webapp")
        import server
        import requests
        from unittest import mock

        class _Resp:
            status_code = 200
            content = b"x"

            def json(self):
                return {"features": [
                    {"properties": {"name": "Munich", "osm_key": "place",
                                    "osm_value": "city", "countrycode": "DE",
                                    "state": "Bavière"}},
                    {"properties": {"name": "Paris", "osm_key": "place",
                                    "osm_value": "city", "countrycode": "FR"}},
                    {"properties": {"name": "Une rue", "osm_key": "highway",
                                    "osm_value": "residential", "countrycode": "DE"}},
                ]}

        with mock.patch.object(requests, "get", lambda *a, **k: _Resp()):
            res = server._photon_cities("mun", "de")
        vals = [s["value"] for s in res]
        self.assertIn("Munich", vals)
        self.assertNotIn("Paris", vals)        # mauvais pays
        self.assertNotIn("Une rue", vals)      # pas un lieu peuplé
        self.assertTrue(all(s["type"] == "city" for s in res))
        self.assertEqual(res[0]["label"], "Munich (Bavière)")


class TestLocationConfigs(unittest.TestCase):
    """Configs de lieu multiples (pays + localisation) du scan."""

    def _server(self):
        import sys
        sys.path.insert(0, "webapp")
        import server
        return server

    def test_parse_configs_dedup_et_pays_inconnu(self):
        server = self._server()
        raw = [
            {"country": "fr", "location": "Rennes"},
            {"country": "FR", "location": "rennes"},   # doublon (casse)
            {"country": "de", "location": "Munich"},
            {"country": "zz", "location": "X"},        # pays inconnu → ignoré
            {"country": "us", "location": ""},         # pays entier
            "pas un dict",
        ]
        out = server._parse_location_configs(raw)
        self.assertEqual(out, [
            {"country": "fr", "location": "Rennes"},
            {"country": "de", "location": "Munich"},
            {"country": "us", "location": ""},
        ])

    def test_validate_multi_pays(self):
        server = self._server()
        body = {"query": "ingénieur", "no_ai": True, "sources": ["indeed"],
                "location_configs": [
                    {"country": "fr", "location": "Rennes"},
                    {"country": "de", "location": "Munich"},
                ]}
        p, err = server._validate_scan_params(body)
        self.assertEqual(err, "")
        self.assertEqual(p["country"], "fr")               # premier pays
        self.assertEqual(p["location"], "Rennes, Munich")  # affichage
        self.assertEqual(len(p["configs"]), 2)

    def test_retrocompat_sans_configs(self):
        server = self._server()
        body = {"query": "dev", "no_ai": True, "sources": ["indeed"],
                "country": "be", "location": "Bruxelles, Liège"}
        p, _ = server._validate_scan_params(body)
        self.assertEqual(p["configs"],
                         [{"country": "be", "location": "Bruxelles"},
                          {"country": "be", "location": "Liège"}])

    def test_groupement_par_pays(self):
        # Le regroupement (logique de _run_scan) : pays → localisations uniques.
        server = self._server()
        configs = [
            {"country": "fr", "location": "Rennes"},
            {"country": "fr", "location": "Nantes"},
            {"country": "de", "location": "Munich"},
        ]
        groups = {}
        for cfg in configs:
            groups.setdefault(cfg["country"], [])
            if cfg["location"] not in groups[cfg["country"]]:
                groups[cfg["country"]].append(cfg["location"])
        self.assertEqual(groups, {"fr": ["Rennes", "Nantes"], "de": ["Munich"]})


class TestGenerationSerialisee(unittest.TestCase):
    """La génération (lettres + analyses CV) est sérialisée par _GEN_LOCK :
    jamais deux en parallèle, les suivantes patientent en file d'attente."""

    def test_run_cv_analyze_attend_le_verrou(self):
        import threading
        import time as _t
        import webapp.server as srv

        # Store factice : get() renvoie None → _run_cv_analyze lève « CV
        # introuvable », mais SEULEMENT après avoir acquis _GEN_LOCK.
        class _DummyStore:
            def get(self, _id):
                return None

        orig = srv._get_cv_store
        srv._get_cv_store = lambda: _DummyStore()
        try:
            self.assertFalse(srv._GEN_LOCK.locked())
            srv._GEN_LOCK.acquire()              # simule une génération en cours
            job = srv._Job("cv")
            try:
                t = threading.Thread(
                    target=srv._run_cv_analyze, args=(job, "inexistant"), daemon=True
                )
                t.start()
                _t.sleep(0.1)
                # Bloqué sur l'acquisition → marqué en file, statut toujours running.
                self.assertEqual(job.status, "running")
                self.assertTrue(job.queued)
            finally:
                srv._GEN_LOCK.release()          # libère : le thread peut démarrer
            t.join(timeout=2.0)
            self.assertFalse(t.is_alive())
            self.assertFalse(job.queued)
            self.assertEqual(job.status, "error")     # CV introuvable
            self.assertFalse(srv._GEN_LOCK.locked())   # verrou toujours relâché (finally)
        finally:
            srv._get_cv_store = orig


class TestTrackerPrune(unittest.TestCase):
    """Plafond d'entrées du tracker : au-delà, les plus anciennes entrées
    « seen »/« new » sont évincées — jamais les décisions explicites."""

    def test_evince_les_seen_les_plus_anciens_jamais_les_decisions(self):
        import tempfile
        import tracker as tracker_mod
        from tracker import Tracker
        from pathlib import Path

        old_cap = tracker_mod._MAX_TRACKER_ENTRIES
        tracker_mod._MAX_TRACKER_ENTRIES = 5
        try:
            with tempfile.TemporaryDirectory() as td:
                t = Tracker(Path(td) / ".tracker.json")
                # 4 « seen » anciens + 3 décisions explicites = 7 entrées (> 5)
                for i in range(4):
                    t._data["offers"][f"seen{i}"] = {
                        "status": "seen", "updated": f"2026-01-0{i + 1}T00:00:00",
                    }
                for i, st in enumerate(("applied", "favorite", "rejected")):
                    t._data["offers"][f"kept{i}"] = {
                        "status": st, "updated": "2026-01-01T00:00:00",
                    }
                t._save()
                offers = t._data["offers"]
                self.assertEqual(len(offers), 5)
                # Les décisions explicites sont intactes
                for i in range(3):
                    self.assertIn(f"kept{i}", offers)
                # Les 2 « seen » les plus anciens ont été évincés
                self.assertNotIn("seen0", offers)
                self.assertNotIn("seen1", offers)
                self.assertIn("seen2", offers)
                self.assertIn("seen3", offers)
        finally:
            tracker_mod._MAX_TRACKER_ENTRIES = old_cap


class TestFranceTravailCommune(unittest.TestCase):
    """Le paramètre `commune` de l'API France Travail attend un code INSEE :
    un nom de ville doit être détecté comme tel (et rejoindre les mots-clés)."""

    def test_regex_insee(self):
        from job_scrapers.france_travail import _INSEE_RE
        self.assertTrue(_INSEE_RE.match("35238"))    # Rennes
        self.assertTrue(_INSEE_RE.match("2A004"))    # Ajaccio (Corse-du-Sud)
        self.assertTrue(_INSEE_RE.match("2B033"))    # Bastia (Haute-Corse)
        self.assertFalse(_INSEE_RE.match("Rennes"))
        self.assertFalse(_INSEE_RE.match("Paris 15"))
        self.assertFalse(_INSEE_RE.match("353"))
        self.assertFalse(_INSEE_RE.match("353381"))


class TestResultCacheTTL(unittest.TestCase):
    """Cache de secours des scrapers : clé incluant le pays, TTL, copies."""

    def _offer(self, title="Dev"):
        from job_scrapers.base import JobOffer
        return JobOffer(id="x1", title=title, company="ACME", location="Rennes",
                        description="", url="https://example.com/a", source="Test")

    def test_cle_par_pays_et_copies_defensives(self):
        from job_scrapers import base as b
        from config import config
        old_country = config.country
        try:
            config.country = "fr"
            offer = self._offer()
            b.cache_results("Test", "dev", "rennes", [offer])
            hit = b.cached_results("Test", "dev", "rennes")
            self.assertIsNotNone(hit)
            # Copie défensive : muter l'offre rendue ne touche pas le cache
            hit[0].match_score = 9
            again = b.cached_results("Test", "dev", "rennes")
            self.assertIsNone(again[0].match_score)
            # Autre pays → clé différente → pas de résultat
            config.country = "de"
            self.assertIsNone(b.cached_results("Test", "dev", "rennes"))
        finally:
            config.country = old_country

    def test_ttl_expire(self):
        from job_scrapers import base as b
        from config import config
        old_country = config.country
        try:
            config.country = "fr"
            b.cache_results("TestTTL", "dev", "", [self._offer()])
            key = b._cache_key("TestTTL", "dev", "")
            ts, offers = b._RESULT_CACHE[key]
            b._RESULT_CACHE[key] = (ts - b._CACHE_TTL - 1, offers)  # vieilli artificiellement
            self.assertIsNone(b.cached_results("TestTTL", "dev", ""))
        finally:
            config.country = old_country


if __name__ == "__main__":
    unittest.main()
