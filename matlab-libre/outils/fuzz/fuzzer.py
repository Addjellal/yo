#!/usr/bin/env python3
"""fuzzer.py — un fuzzeur maison de l'analyseur et de l'interpréteur.

    python3 -I outils/fuzz/fuzzer.py --analyse ANALYSESEULE --matlibre MATLIBRE \
            [--graine 1] [--nombre 4000] [--executions 1500] [--sortie DOSSIER]

Part des fichiers .m du dépôt (tests, exemples, toolbox) et en tire des
textes abîmés : tronqués, amputés d'un passage, doublés, mêlés à un
autre fichier, parsemés de jetons du langage ou d'octets changés. S'y
ajoutent des textes extrêmes : emboîtements de cent mille parenthèses,
lignes de dix mégaoctets, octets nuls, UTF-8 invalide.

Deux passes :
  1. ANALYSESEULE (outils/fuzz/analyseSeule.cpp) lexe et analyse chaque
     texte sans l'exécuter ;
  2. MATLIBRE exécute une partie des textes, chacun dans son processus,
     dans un dossier jetable, sous une limite de temps.

Une erreur MATLAB est la bonne réponse. Sont signalés : un plantage
(signal, rapport d'AddressSanitizer), un comportement indéfini (« runtime
error » d'UBSan), une exception C++ qui n'est pas une erreur MATLAB (code
3). Les textes fautifs sont gardés dans le dossier de sortie, pour
rejouer. Les mutations ne fabriquent ni « ! » en tête de ligne ni appel
au système, aux fichiers ou au réseau : un texte qui en contiendrait est
écarté avant d'être exécuté.
"""
import argparse
import os
import random
import re
import shutil
import subprocess
import sys
import tempfile

RACINE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

JETONS = ['end', '(', ')', '[', ']', '{', '}', "'", '"', '...', '%{', '%}', '@', '.', ':',
          ';', ',', '\n', ' ', 'function', 'if', 'else', 'elseif', 'for', 'parfor', 'while',
          'switch', 'case', 'otherwise', 'try', 'catch', 'classdef', 'properties', 'methods',
          'events', 'enumeration', 'return', 'break', 'continue', 'global', 'persistent',
          'x.(', '1e309', '0x', '0b', '1i', "'abc", '"abc', 'é', '\x00', '=', '==', '~=',
          '&&', '||', '.^', ".'", '\\', '/', '*', '+', '-', '~', '<', '>', '|', '&', '#',
          'end+1', '(end)', '{:}', '(:)', 'varargin{:}', 'nargin', 'x', 'y', '1', '0', '-1',
          'NaN', 'Inf', '[]', '{}', "''", '""', '@(x)', 'f(', 'x{', 'x(', '1:', ':end',
          '\t', '\r', '\r\n', 'arguments', 'spmd', 'do', 'until']

# Ce qu'un texte exécuté ne doit pas contenir : le système, les fichiers
# hors du dossier jetable, le réseau, la sortie du programme.
DANGEREUX = re.compile(
    r'(^\s*!)|\b(system|unix|dos|delete|rmdir|mkdir|movefile|copyfile|cd|'
    r'web\w*|ftp|sendmail|diary|save\w*|print|exit|quit|setenv|addpath|'
    r'rmpath|savepath|fopen|fwrite|fprintf\s*\(\s*f|dlmwrite|csvwrite|'
    r'writematrix|writetable|writecell|imwrite|audiowrite|parquetwrite|'
    r'xmlwrite|zip|unzip|tar|untar|gzip|gunzip|eval\w*|feval|evalin|'
    r'assignin|input|keyboard|pause|load|open\w*|edit|run|builtin|'
    r'matlibre_\w+|new_system|save_system|parpool|parfor|spmd|'
    r'parfeval|batch|pyrun|pyenv|java\w*|loadlibrary|calllib|mex|'
    r'coder\w*|codegen|rtwbuild|slbuild|Simulink)\b', re.M)


def graines():
    fichiers = []
    for dossier in ('tests/scripts', 'exemples', 'toolbox'):
        for base, _, noms in os.walk(os.path.join(RACINE, dossier)):
            for nom in noms:
                if nom.endswith('.m'):
                    fichiers.append(os.path.join(base, nom))
    fichiers.sort()
    return fichiers


def lire(chemin):
    with open(chemin, 'rb') as f:
        return f.read().decode('utf-8', 'replace')


def muter(texte, autre, alea):
    if not texte:
        return alea.choice(JETONS)
    n = len(texte)
    choix = alea.randrange(9)
    i = alea.randrange(n)
    j = min(n, i + alea.randrange(1, 200))
    if choix == 0:                      # tronqué
        return texte[:i]
    if choix == 1:                      # amputé d'un passage
        return texte[:i] + texte[j:]
    if choix == 2:                      # un passage doublé
        return texte[:j] + texte[i:j] + texte[j:]
    if choix == 3:                      # des jetons semés
        for _ in range(alea.randrange(1, 8)):
            k = alea.randrange(len(texte) + 1)
            texte = texte[:k] + alea.choice(JETONS) + texte[k:]
        return texte
    if choix == 4:                      # des octets changés
        car = list(texte)
        for _ in range(alea.randrange(1, 8)):
            k = alea.randrange(len(car))
            c = chr((ord(car[k]) ^ (1 << alea.randrange(7))) & 0x7F)
            car[k] = c if c != '!' else '?'
        return ''.join(car)
    if choix == 5:                      # deux lignes échangées
        lignes = texte.split('\n')
        if len(lignes) > 1:
            a, b = alea.randrange(len(lignes)), alea.randrange(len(lignes))
            lignes[a], lignes[b] = lignes[b], lignes[a]
        return '\n'.join(lignes)
    if choix == 6:                      # mêlé à un autre fichier
        k = alea.randrange(len(autre) + 1) if autre else 0
        return texte[:i] + autre[k:]
    if choix == 7:                      # une ligne répétée cent fois
        lignes = texte.split('\n')
        k = alea.randrange(len(lignes))
        return '\n'.join(lignes[:k] + [lignes[k]] * 100 + lignes[k:])
    # un délimiteur retiré
    positions = [m.start() for m in re.finditer(r'[()\[\]{}\'"]', texte)]
    if positions:
        k = alea.choice(positions)
        return texte[:k] + texte[k + 1:]
    return texte[:i]


def extremes():
    yield 'parentheses_1e3', '(' * 1000 + '1' + ')' * 1000
    yield 'parentheses_1e5', '(' * 100000 + '1' + ')' * 100000
    yield 'crochets_1e5', '[' * 100000 + '1' + ']' * 100000
    yield 'accolades_1e5', '{' * 100000 + '1' + '}' * 100000
    yield 'parentheses_ouvertes_1e5', 'x = ' + '(' * 100000
    yield 'si_1e4', 'if 1\n' * 10000 + 'end\n' * 10000
    yield 'pour_1e4', 'for k=1\n' * 10000 + 'end\n' * 10000
    yield 'fonctions_1e4', 'function f\n' * 10000
    yield 'somme_1e5', 'x = 1' + '+1' * 100000
    yield 'unaires_1e5', 'x = ' + '-' * 100000 + '1'
    yield 'non_1e5', 'x = ' + '~' * 100000 + '1'
    yield 'transposees_1e5', "x = 1" + "'" * 100000
    yield 'puissances_1e5', 'x = 1' + '^1' * 100000
    yield 'champs_1e5', 'x' + '.b' * 100000 + ' = 1'
    yield 'appels_1e5', 'x = f' + '(1)' * 100000
    yield 'anonymes_1e4', 'f = ' + '@()' * 10000 + '1'
    yield 'cellules_1e5', 'x = c' + '{1}' * 100000
    yield 'ligne_1e7', 'x = ' + '1' * 10000000 + ';'
    yield 'chaine_1e7', "x = '" + 'a' * 10000000 + "';"
    yield 'chaine_ouverte', "x = 'abc"
    yield 'commentaire_bloc_ouvert', '%{\nx = 1\n'
    yield 'commentaires_bloc_1e4', '%{\n' * 10000 + '%}\n' * 10000
    yield 'continuations_1e5', 'x = 1 ...\n' * 100000 + ';'
    yield 'octets_nuls', 'x = 1;\x00\x00 y = 2;\x00'
    yield 'utf8_invalide', 'x = \'\udcff\udcfe\';'
    yield 'nombre_enorme', 'x = 1e99999999999999999999;'
    yield 'nombre_long', 'x = 0.' + '1' * 100000 + ';'
    yield 'hexa_long', 'x = 0x' + 'F' * 1000 + ';'
    yield 'matrice_1e5', 'x = [' + '1 ' * 100000 + '];'
    yield 'matrice_lignes_1e5', 'x = [' + '1;' * 100000 + '];'
    yield 'virgules_1e5', 'x = f(' + '1,' * 100000 + '1);'
    yield 'affectations_multiples', '[' + 'a,' * 10000 + 'b] = deal(1);'
    yield 'classdef_vide', 'classdef'
    yield 'classdef_profond', 'classdef A\n' + 'properties\n' * 1000
    yield 'switch_1e4', 'switch 1\n' + 'case 1\n' * 10000 + 'end'
    yield 'essais_1e4', 'try\n' * 10000 + 'catch\nend\n' * 10000
    yield 'fin_seule', 'end'
    yield 'vide', ''
    yield 'blancs', ' \t\r\n' * 10000


def executer(commande, delai, dossier):
    env = dict(os.environ)
    env['HOME'] = dossier
    env['ASAN_OPTIONS'] = 'detect_leaks=0:abort_on_error=0'
    env['UBSAN_OPTIONS'] = 'print_stacktrace=1'
    try:
        r = subprocess.run(commande, cwd=dossier, env=env, stdin=subprocess.DEVNULL,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=delai)
        return r.returncode, r.stdout.decode('utf-8', 'replace'), \
            r.stderr.decode('utf-8', 'replace')
    except subprocess.TimeoutExpired:
        return 'delai', '', ''


def defaut(code, sortie, erreur):
    if code == 'delai':
        return None
    texte = sortie + erreur
    if 'AddressSanitizer' in texte or 'LeakSanitizer' in texte:
        return 'ASAN'
    if 'runtime error:' in texte:
        return 'UBSAN'
    if 'INTERNE' in texte or 'Erreur interne' in texte or code == 3:
        return 'INTERNE'
    if isinstance(code, int) and (code < 0 or code >= 128):
        return 'SIGNAL %d' % code
    return None


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--analyse', required=True)
    p.add_argument('--matlibre', required=True)
    p.add_argument('--graine', type=int, default=1)
    p.add_argument('--nombre', type=int, default=4000)
    p.add_argument('--executions', type=int, default=1500)
    p.add_argument('--sortie', default=None)
    a = p.parse_args()
    alea = random.Random(a.graine)
    sortie = a.sortie or tempfile.mkdtemp(prefix='fuzz_')
    corpus = os.path.join(sortie, 'corpus')
    fautifs = os.path.join(sortie, 'fautifs')
    os.makedirs(corpus, exist_ok=True)
    os.makedirs(fautifs, exist_ok=True)

    sources = graines()
    textes = []
    for nom, t in extremes():
        textes.append(('x_' + nom, t))
    for k in range(a.nombre):
        t = lire(alea.choice(sources))
        autre = lire(alea.choice(sources))
        for _ in range(alea.randrange(1, 4)):
            t = muter(t, autre, alea)
        textes.append(('m_%05d' % k, t))
    chemins = []
    for nom, t in textes:
        c = os.path.join(corpus, nom + '.m')
        with open(c, 'w', encoding='utf-8', errors='surrogateescape') as f:
            f.write(t)
        chemins.append(c)

    trouves = []
    # --- passe 1 : l'analyse seule, par lots ---------------------------
    lot = 100
    for k in range(0, len(chemins), lot):
        groupe = chemins[k:k + lot]
        code, so, se = executer([a.analyse] + groupe, 600, sortie)
        if defaut(code, so, se) is None and code != 'delai':
            continue
        for c in groupe:
            code, so, se = executer([a.analyse, c], 120, sortie)
            genre = defaut(code, so, se) or ('DELAI' if code == 'delai' else None)
            if genre:
                shutil.copy(c, fautifs)
                trouves.append(('analyse', genre, os.path.basename(c),
                                (so + se).strip().split('\n')[-1][:300]))
    print('passe 1 : %d textes analysés, %d défauts' % (len(chemins), len(trouves)))

    # --- passe 2 : l'exécution -----------------------------------------
    candidats = [c for c in chemins if os.path.basename(c).startswith('x_')]
    melanges = [c for c in chemins if os.path.basename(c).startswith('m_')]
    alea.shuffle(melanges)
    candidats += melanges
    executes = 0
    avant = len(trouves)
    for c in candidats:
        if executes >= a.executions:
            break
        texte = lire(c)
        if DANGEREUX.search(texte) or len(texte) > 200000 and not \
                os.path.basename(c).startswith('x_'):
            continue
        executes += 1
        jetable = tempfile.mkdtemp(prefix='fuzz_exec_', dir=sortie)
        script = os.path.join(jetable, 'fz.m')
        shutil.copy(c, script)
        code, so, se = executer([a.matlibre, '-q', script], 20, jetable)
        genre = defaut(code, so, se)
        if genre:
            shutil.copy(c, fautifs)
            lignes = [l for l in (so + se).split('\n')
                      if 'ERROR' in l or 'runtime error' in l or 'INTERNE' in l
                      or 'Erreur interne' in l or '#0' in l or '#1 ' in l]
            trouves.append(('execution', genre, os.path.basename(c),
                            ' | '.join(lignes[:4])[:400]))
        shutil.rmtree(jetable, ignore_errors=True)
    print('passe 2 : %d textes exécutés, %d défauts' % (executes, len(trouves) - avant))
    for t in trouves:
        print('%-9s %-10s %s  %s' % t)
    print('textes fautifs : %s' % fautifs)
    return 1 if trouves else 0


if __name__ == '__main__':
    sys.exit(main())
