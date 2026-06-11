#!/usr/bin/env python3
"""
Interface web locale d'Auto Emploi.

    python web.py                 # démarre et ouvre le navigateur
    python web.py --port 9000     # autre port
    python web.py --no-browser    # sans ouvrir le navigateur

Aucune dépendance supplémentaire : le serveur repose uniquement sur la
bibliothèque standard de Python. Il n'écoute que sur 127.0.0.1.
"""
# Garantit que le dossier du projet est résolu en premier,
# avant les packages tiers installés dans site-packages.
import sys as _sys
import os as _os
_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
del _sys, _os

import argparse

from webapp.server import run


def main():
    parser = argparse.ArgumentParser(description="Interface web locale d'Auto Emploi")
    parser.add_argument("--port", type=int, default=8765, help="Port d'écoute (défaut : 8765)")
    parser.add_argument("--no-browser", action="store_true", help="Ne pas ouvrir le navigateur")
    args = parser.parse_args()
    port = max(1024, min(65535, args.port))
    run(port=port, open_browser=not args.no_browser)


if __name__ == "__main__":
    main()
