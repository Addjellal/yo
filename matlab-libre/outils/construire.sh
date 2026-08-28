#!/bin/sh
# construire.sh — compile MatLibre sur Linux et macOS.
#
#   ./outils/construire.sh                 compile en Release dans build/
#   ./outils/construire.sh --debug         compile avec les assertions
#   ./outils/construire.sh --tests         compile puis exécute les tests
#   ./outils/construire.sh --installer /usr/local
#   ./outils/construire.sh --paquet        fabrique les archives dans build/
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

while [ $# -gt 0 ]; do
    case "$1" in
        --debug)     type=Debug; dossier="$racine/build-debug"; shift ;;
        --tests)     tests=1; shift ;;
        --paquet)    paquet=1; shift ;;
        --installer) prefixe="${2:-/usr/local}"; shift 2 ;;
        --dossier)   dossier="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo "option inconnue : $1" >&2; exit 2 ;;
    esac
done

if ! command -v cmake >/dev/null 2>&1; then
    echo "cmake est introuvable. Installez-le, puis relancez." >&2
    exit 1
fi

taches=$( (nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) )

# Le cache de CMake garde le type de construction du premier appel. Un
# cache qui ne correspond plus donne des erreurs sans rapport avec la
# cause : on efface plutot que de compiler sur une configuration perimee.
if [ -f "$dossier/CMakeCache.txt" ]; then
    typeCache=$(sed -n 's/^CMAKE_BUILD_TYPE:[^=]*=//p' "$dossier/CMakeCache.txt" | head -1)
    if [ -n "$typeCache" ] && [ "$typeCache" != "$type" ]; then
        echo "MatLibre : le cache est en « $typeCache », on demande « $type » : dossier efface"
        rm -rf "$dossier"
    fi
fi

echo "MatLibre : configuration ($type) dans $dossier"
cmake -S "$racine" -B "$dossier" -DCMAKE_BUILD_TYPE="$type"
echo "MatLibre : compilation sur $taches taches"
cmake --build "$dossier" -j "$taches"

if [ "$tests" -eq 1 ]; then
    echo "MatLibre : tests"
    "$dossier/matlibre_tests"
    MATLIBRE_TOOLBOX="$racine/toolbox" "$dossier/matlibre" "$racine/outils/verifierDoublons.m"
    for f in "$racine"/tests/scripts/test_*.m; do
        echo "--> $f"
        MATLIBRE_TOOLBOX="$racine/toolbox" "$dossier/matlibre" --path "$racine/tests/scripts" "$f"
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

echo "MatLibre : fini. L'executable est $dossier/matlibre"
echo "  $dossier/matlibre --ide   ouvre l'atelier : editeur de scripts, figures, debogueur"
echo "  $dossier/matlibre         session interactive ; la commande « ide » y ouvre l'atelier"
