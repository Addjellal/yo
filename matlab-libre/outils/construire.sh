#!/bin/sh
# construire.sh — compile MatLibre sur Linux et macOS.
#
#   ./outils/construire.sh                 compile en Release dans build/
#   ./outils/construire.sh --debug         compile avec les assertions
#   ./outils/construire.sh --tests         compile puis exécute les tests
#   ./outils/construire.sh --installer /usr/local
#   ./outils/construire.sh --paquet        fabrique les archives dans build/
#   ./outils/construire.sh --incrementale  garde l'arbre au lieu de l'effacer
#
# Chaque compilation part d'un arbre neuf : l'ancien est effacé avant de
# reconfigurer. C'est ce qui évite les objets orphelins et les caches
# périmés. « --incrementale » garde l'arbre, pour itérer.
#
# Aucune dépendance n'est requise : un compilateur C++17 et CMake suffisent.
# LAPACK, BLAS et FFTW sont utilisés s'ils sont trouvés.
set -eu

racine=$(cd "$(dirname "$0")/.." && pwd)
dossier="$racine/build"
type=Release
tests=0
paquet=0
prefixe=""
neuf=1

while [ $# -gt 0 ]; do
    case "$1" in
        --debug)     type=Debug; dossier="$racine/build-debug"; shift ;;
        --tests)     tests=1; shift ;;
        --paquet)    paquet=1; shift ;;
        --installer) prefixe="${2:-/usr/local}"; shift 2 ;;
        --dossier)   dossier="$2"; shift 2 ;;
        --incrementale) neuf=0; shift ;;
        -h|--help)
            sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo "option inconnue : $1" >&2; exit 2 ;;
    esac
done

if ! command -v cmake >/dev/null 2>&1; then
    echo "cmake est introuvable. Installez-le, puis relancez." >&2
    exit 1
fi

taches=$( (nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) )

# On part d'un arbre neuf. Un arbre garde ce qu'on croit avoir enleve :
# le .o d'un fichier supprime, une option de cache qui n'existe plus, une
# bibliotheque trouvee la fois d'avant et disparue depuis. Effacer coute
# quelques minutes ; chercher pourquoi « ca ne compile que chez moi » en
# coute davantage.
if [ "$neuf" -eq 1 ] && [ -d "$dossier" ]; then
    echo "MatLibre : l'arbre precedent est efface ($dossier)"
    rm -rf "$dossier"
elif [ -f "$dossier/CMakeCache.txt" ]; then
    # En incremental, on efface quand meme si le type de construction a
    # change : le cache garde celui du premier appel, et un cache qui ne
    # correspond plus donne des erreurs sans rapport avec la cause.
    typeCache=$(sed -n 's/^CMAKE_BUILD_TYPE:[^=]*=//p' "$dossier/CMakeCache.txt" | head -1)
    if [ -n "$typeCache" ] && [ "$typeCache" != "$type" ]; then
        echo "MatLibre : le cache est en « $typeCache », on demande « $type » : dossier efface"
        rm -rf "$dossier"
    fi
fi

echo "MatLibre : configuration ($type) dans $dossier"
# Les binaires sortent dans <dossier>/bin : l'arbre reste lisible.
binaires="$dossier/bin"
cmake -S "$racine" -B "$dossier" -DCMAKE_BUILD_TYPE="$type"
echo "MatLibre : compilation sur $taches taches"
cmake --build "$dossier" -j "$taches"

if [ "$tests" -eq 1 ]; then
    echo "MatLibre : tests"
    "$binaires/matlibre_tests"
    MATLIBRE_TOOLBOX="$racine/toolbox" "$binaires/matlibre" "$racine/outils/verifierDoublons.m"
    for f in "$racine"/tests/scripts/test_*.m; do
        echo "--> $f"
        MATLIBRE_TOOLBOX="$racine/toolbox" "$binaires/matlibre" --path "$racine/tests/scripts" "$f"
    done
    echo "tous les tests passent"
fi

if [ -n "$prefixe" ]; then
    echo "MatLibre : installation dans $prefixe"
    cmake --install "$dossier" --prefix "$prefixe"
fi

if [ "$paquet" -eq 1 ]; then
    echo "MatLibre : fabrication des archives"
    (cd "$dossier" && cpack)
    ls -1 "$dossier"/MatLibre-* 2>/dev/null || true
fi

echo "MatLibre : fini. L'executable est $binaires/matlibre"
if [ -x "$binaires/matlibre-bureau" ]; then
    echo "  $binaires/matlibre-bureau"
    echo "      le bureau : une fenetre, l'editeur, les figures, l'espace de travail"
fi
echo "  $binaires/matlibre-bureau  ouvre le bureau (si Qt6 est present)"
echo "  $binaires/matlibre         session interactive"
