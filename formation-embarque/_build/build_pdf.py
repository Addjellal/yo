#!/usr/bin/env python3
"""Génère les PDF de la formation à partir des fichiers Markdown.

Pipeline : Markdown -> HTML (python-markdown + pygments) -> PDF (Chromium headless).
- Coloration syntaxique du code (C, C++, VHDL, Python, Java...).
- Les figures SVG et les liens relatifs sont résolus vers des chemins absolus.
- Chaque PDF a une page de couverture.

Usage : python3 build_pdf.py
"""
import base64
import glob
import os
import re
import subprocess
import sys
import tempfile
import urllib.parse

import markdown

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD = os.path.join(ROOT, "_build")
PDFDIR = os.path.join(ROOT, "pdf")
CSS = os.path.join(BUILD, "style.css")

# Trouver le binaire chromium
def find_chrome():
    for pat in ("/opt/pw-browsers/chromium-*/chrome-linux/chrome",
                "/opt/pw-browsers/chromium-*/chrome-linux/headless_shell"):
        hits = sorted(glob.glob(pat))
        if hits:
            return hits[-1]
    raise SystemExit("Chromium introuvable dans /opt/pw-browsers")

CHROME = find_chrome()

MD_EXT = [
    "extra",          # tables, fenced code, footnotes, attr_list...
    "sablededef",     # placeholder (ignoré si absent) -> retiré ci-dessous
    "toc",
    "admonition",
    "codehilite",
]
# 'sablededef' n'existe pas : on garde une liste propre
MD_EXT = ["extra", "toc", "admonition", "codehilite"]
MD_CFG = {"codehilite": {"guess_lang": False, "noclasses": False}}


def embed_svg(html, base_dir):
    """Remplace <img src="figures/x.svg"> par le SVG inline (autonome dans le PDF)."""
    def repl(m):
        src = m.group(1)
        src_dec = urllib.parse.unquote(src)
        if not src_dec.lower().endswith(".svg"):
            # autres images : chemin absolu file://
            path = os.path.normpath(os.path.join(base_dir, src_dec))
            if os.path.exists(path):
                return '<img src="file://%s"' % path
            return m.group(0)
        path = os.path.normpath(os.path.join(base_dir, src_dec))
        if os.path.exists(path):
            with open(path, encoding="utf-8") as f:
                svg = f.read()
            # retirer déclaration xml éventuelle
            svg = re.sub(r"<\?xml[^>]*\?>", "", svg).strip()
            return '<figure>' + svg + '<!--'
        return m.group(0)
    # <img src="..." alt="..."> -> on capture le src, on gère la fermeture
    html = re.sub(r'<img\s+[^>]*?src="([^"]+)"[^>]*?>', lambda m: _img(m, base_dir), html)
    return html


def _img(m, base_dir):
    tag = m.group(0)
    src = re.search(r'src="([^"]+)"', tag).group(1)
    alt = re.search(r'alt="([^"]*)"', tag)
    caption = alt.group(1) if alt else ""
    src_dec = urllib.parse.unquote(src)
    path = os.path.normpath(os.path.join(base_dir, src_dec))
    if src_dec.lower().endswith(".svg") and os.path.exists(path):
        # data-URI dans un <img> : isole totalement le SVG du CSS de la page
        # (sinon les classes courtes .s/.t/.w entrent en conflit avec Pygments).
        with open(path, "rb") as f:
            data = base64.b64encode(f.read()).decode()
        cap = ('<figcaption>%s</figcaption>' % caption) if caption else ""
        return ('<figure><img src="data:image/svg+xml;base64,%s"/>%s</figure>'
                % (data, cap))
    if os.path.exists(path):
        with open(path, "rb") as f:
            data = base64.b64encode(f.read()).decode()
        ext = os.path.splitext(path)[1].lstrip(".").lower()
        mime = {"png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg",
                "gif": "image/gif"}.get(ext, "image/png")
        cap = ('<figcaption>%s</figcaption>' % caption) if caption else ""
        return '<figure><img src="data:%s;base64,%s"/>%s</figure>' % (mime, data, cap)
    return tag


def render_html(md_path, title=None, subtitle=None, cover=True):
    with open(md_path, encoding="utf-8") as f:
        text = f.read()
    base_dir = os.path.dirname(md_path)
    md = markdown.Markdown(extensions=MD_EXT, extension_configs=MD_CFG)
    body = md.convert(text)
    body = embed_svg(body, base_dir)
    with open(CSS, encoding="utf-8") as f:
        css = f.read()

    cover_html = ""
    if cover:
        t = title or os.path.basename(md_path)
        s = subtitle or "Formation Systèmes embarqués & programmation bas niveau"
        cover_html = (
            '<div class="cover">'
            '<div class="badge">FORMATION EMBARQUÉE</div>'
            '<h1>%s</h1>'
            '<div class="sub">%s</div>'
            '<div class="meta">Systèmes embarqués · bas niveau · automatismes</div>'
            '</div>' % (t, s)
        )
    return (
        "<!doctype html><html lang='fr'><head><meta charset='utf-8'>"
        "<style>%s</style></head><body>%s%s</body></html>"
        % (css, cover_html, body)
    )


def html_to_pdf(html, out_pdf):
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False,
                                     encoding="utf-8", dir=BUILD) as f:
        f.write(html)
        tmp = f.name
    try:
        subprocess.run(
            [CHROME, "--headless", "--no-sandbox", "--disable-gpu",
             "--no-pdf-header-footer", "--print-to-pdf=%s" % out_pdf,
             "file://%s" % tmp],
            check=True, capture_output=True, timeout=120)
    finally:
        os.unlink(tmp)


# Titres lisibles pour la couverture
TITLES = {
    "00-fondamentaux": "Module 00 — Fondamentaux",
    "01-langage-c": "Module 01 — Langage C",
    "02-cpp": "Module 02 — C++",
    "03-arduino": "Module 03 — Arduino",
    "04-vhdl": "Module 04 — VHDL & FPGA",
    "05-java": "Module 05 — Java",
    "06-autres-langages": "Module 06 — Autres langages",
    "07-siemens": "Module 07 — Suite Siemens",
    "08-schneider": "Module 08 — Suite Schneider",
    "09-parcours-et-ressources": "Module 09 — Parcours & ressources",
    "10-stm32": "Module 10 — STM32",
    "README": "Guide de la formation",
    "guide-formateur": "Guide du formateur",
}


def nice_title(rel):
    stem = os.path.splitext(os.path.basename(rel))[0]
    if stem in TITLES:
        return TITLES[stem]
    if stem.startswith("td-"):
        return "TD " + stem[3:].replace("-", " ").title()
    if stem.startswith("tp"):
        return "TP — " + stem.replace("-", " ")
    if stem == "qcm":
        return "QCM de validation"
    if stem == "projets-notes":
        return "Projets d'évaluation"
    if stem == "seance-1" or stem.startswith("seance"):
        return stem.replace("-", " ").title()
    return stem.replace("-", " ").title()


def main():
    os.makedirs(PDFDIR, exist_ok=True)
    # Fichiers à convertir : tous les .md sauf ceux du build
    targets = []
    for md in sorted(glob.glob(os.path.join(ROOT, "*.md"))):
        targets.append(md)
    for sub in ("td", "evaluations", "tp", "code"):
        for md in sorted(glob.glob(os.path.join(ROOT, sub, "*.md"))):
            targets.append(md)
    for md in sorted(glob.glob(os.path.join(ROOT, "tp", "tp*-fiches", "*.md"))):
        targets.append(md)

    ok = 0
    for md in targets:
        rel = os.path.relpath(md, ROOT)
        # nom de sortie plat, préfixé par le sous-dossier
        flat = rel.replace(os.sep, "__").rsplit(".", 1)[0] + ".pdf"
        out = os.path.join(PDFDIR, flat)
        try:
            html = render_html(md, title=nice_title(rel))
            html_to_pdf(html, out)
            size = os.path.getsize(out)
            print("OK  %-55s %6.0f Ko" % (rel, size / 1024))
            ok += 1
        except Exception as e:  # noqa
            print("ERR %-55s %s" % (rel, e))
    print("\n%d/%d PDF générés dans %s" % (ok, len(targets), PDFDIR))


if __name__ == "__main__":
    main()
