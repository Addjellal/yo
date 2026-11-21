#!/usr/bin/env python3
"""fichiersAbimes.py — fait lire à MatLibre des fichiers abîmés.

    python3 -I outils/fuzz/fichiersAbimes.py --matlibre MATLIBRE --graines DOSSIER \
            [--mutants 30] [--graine 1]

DOSSIER contient des fichiers valides, un par format (.mat, .csv, .json,
.slx, .pgm, .ppm, .wav, .xml, .parquet), écrits par exemple par MatLibre
lui-même. Chacun est tronqué, ses octets changés, des plages mises à
zéro ou à 0xFF — ce qui fausse les longueurs annoncées dans les en-têtes
— puis relu par la fonction de MATLAB qui le lit, dans son propre
processus. Une erreur est la bonne réponse ; sont signalés un plantage,
un rapport d'AddressSanitizer ou d'UBSan, une exception interne et un
dépassement du délai.
"""
import argparse
import os
import random
import shutil
import subprocess
import sys
import tempfile

LECTEURS = {
    '.mat': "s = load('{f}');",
    '.csv': "a = readmatrix('{f}'); b = readtable('{f}');",
    '.json': "a = jsondecode(fileread('{f}'));",
    '.slx': "load_system('{f}'); bdclose('all');",
    '.pgm': "a = imread('{f}');",
    '.ppm': "a = imread('{f}');",
    '.wav': "[y, fs] = audioread('{f}');",
    '.xml': "d = xmlread('{f}');",
    '.parquet': "t = parquetread('{f}');",
}


def muter(octets, alea):
    b = bytearray(octets)
    choix = alea.randrange(5)
    if not b:
        return bytes(b)
    if choix == 0:
        return bytes(b[:alea.randrange(len(b))])
    if choix == 1:
        for _ in range(alea.randrange(1, 10)):
            b[alea.randrange(len(b))] = alea.randrange(256)
        return bytes(b)
    if choix == 2:
        i = alea.randrange(len(b))
        for k in range(i, min(len(b), i + alea.randrange(1, 16))):
            b[k] = 0xFF
        return bytes(b)
    if choix == 3:
        i = alea.randrange(len(b))
        for k in range(i, min(len(b), i + alea.randrange(1, 16))):
            b[k] = 0
        return bytes(b)
    i = alea.randrange(len(b) + 1)
    return bytes(b[:i] + bytes(alea.randrange(256) for _ in range(alea.randrange(1, 64))) + b[i:])


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--matlibre', required=True)
    p.add_argument('--graines', required=True)
    p.add_argument('--mutants', type=int, default=30)
    p.add_argument('--graine', type=int, default=1)
    a = p.parse_args()
    alea = random.Random(a.graine)
    travail = tempfile.mkdtemp(prefix='abimes_')
    fautifs = os.path.join(travail, 'fautifs')
    os.makedirs(fautifs)
    env = dict(os.environ, ASAN_OPTIONS='detect_leaks=0', HOME=travail)
    trouves, total = [], 0
    for nom in sorted(os.listdir(a.graines)):
        ext = os.path.splitext(nom)[1].lower()
        if ext not in LECTEURS:
            continue
        octets = open(os.path.join(a.graines, nom), 'rb').read()
        for k in range(a.mutants):
            total += 1
            cible = os.path.join(travail, 'm%03d%s' % (k, ext))
            with open(cible, 'wb') as f:
                f.write(muter(octets, alea))
            code = 'try, ' + LECTEURS[ext].format(f=cible) + ' catch, end'
            try:
                r = subprocess.run([a.matlibre, '-q', '-e', code], cwd=travail, env=env,
                                   stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, timeout=60)
                texte = (r.stdout + r.stderr).decode('utf-8', 'replace')
                genre = None
                if 'AddressSanitizer' in texte:
                    genre = 'ASAN'
                elif 'runtime error:' in texte:
                    genre = 'UBSAN'
                elif 'Erreur interne' in texte or r.returncode == 3:
                    genre = 'INTERNE'
                elif r.returncode < 0 or r.returncode >= 128:
                    genre = 'SIGNAL %d' % r.returncode
            except subprocess.TimeoutExpired:
                genre, texte = 'DELAI', ''
            if genre:
                garde = os.path.join(fautifs, '%s_%s' % (os.path.splitext(nom)[0], os.path.basename(cible)))
                shutil.copy(cible, garde)
                lignes = [l for l in texte.split('\n') if 'ERROR' in l or 'runtime error' in l
                          or 'Erreur interne' in l or l.strip().startswith('#1 ')]
                trouves.append((genre, garde, ' | '.join(lignes[:3])[:300]))
            os.remove(cible)
    print('%d fichiers abimes lus, %d defauts' % (total, len(trouves)))
    for t in trouves:
        print('%-8s %s  %s' % t)
    return 1 if trouves else 0


if __name__ == '__main__':
    sys.exit(main())
