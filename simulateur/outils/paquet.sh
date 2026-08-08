#!/bin/sh
# Fabrique le paquet portable Linux.
#
#   ./outils/paquet.sh
#
# Produit « build-paquet/simulateur-embarque-<version>-linux-x64.tar.gz » :
# un dossier qui se décompresse n'importe où et se lance par ./simulateur.sh,
# sans rien installer.
set -e
racine=$(cd "$(dirname "$0")/.." && pwd)
dossier="${1:-$racine/build-paquet}"

# Le paquet ne doit dépendre que de Qt : les moteurs de simulation sont dans
# l'exécutable, on ignore ngspice et simavr même s'ils sont installés.
cmake -S "$racine" -B "$dossier" -DCMAKE_BUILD_TYPE=Release -DSIM_AUTONOME=ON
cmake --build "$dossier" --target paquet -j"$(nproc 2>/dev/null || echo 4)"

archive=$(ls -t "$dossier"/*.tar.gz 2>/dev/null | head -1)
if [ -n "$archive" ]; then
    printf '\nPaquet prêt : %s (%s)\n' "$archive" "$(du -h "$archive" | cut -f1)"
    echo "Il se décompresse où l'on veut et se lance par ./simulateur.sh."
fi
