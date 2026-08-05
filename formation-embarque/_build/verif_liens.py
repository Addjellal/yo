#!/usr/bin/env python3
"""Vérifie tous les liens relatifs des fichiers Markdown de la formation.

Usage : python3 _build/verif_liens.py   (ou : make verif)
Sortie : 0 si tout est bon, 1 s'il reste un lien cassé.

Ignore les URL externes (http/https/mailto) et les ancres seules (#...).
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Un lien Markdown : ](cible). On exclut les cas qui n'en sont pas
# (ex. lambda C++ `[capture](int16_t v)` dans un bloc de code).
LIEN = re.compile(r"\]\(([^)\s]+)\)")


def liens_du_fichier(chemin):
    """Retourne les cibles relatives, en sautant les blocs de code."""
    dans_bloc = False
    with open(chemin, encoding="utf-8") as f:
        for num, ligne in enumerate(f, 1):
            if ligne.lstrip().startswith("```"):
                dans_bloc = not dans_bloc
                continue
            if dans_bloc:
                continue
            for m in LIEN.finditer(ligne):
                cible = m.group(1)
                if cible.startswith(("http://", "https://", "mailto:", "#")):
                    continue
                yield num, cible


def main():
    casses = []
    total = 0
    fichiers = [p for p in glob.glob(os.path.join(ROOT, "**", "*.md"),
                                     recursive=True)
                if os.sep + "pdf" + os.sep not in p]

    for chemin in sorted(fichiers):
        base = os.path.dirname(chemin)
        for num, cible in liens_du_fichier(chemin):
            total += 1
            chemin_cible = cible.split("#")[0]
            if not chemin_cible:
                continue
            absolu = os.path.normpath(os.path.join(base, chemin_cible))
            if not os.path.exists(absolu):
                casses.append((os.path.relpath(chemin, ROOT), num, cible))

    print("%d fichiers Markdown, %d liens relatifs vérifiés."
          % (len(fichiers), total))
    if casses:
        print("\n%d LIEN(S) CASSÉ(S) :" % len(casses))
        for f, n, c in casses:
            print("  %s:%d  ->  %s" % (f, n, c))
        return 1
    print("Aucun lien cassé.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
