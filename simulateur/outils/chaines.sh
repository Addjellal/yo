#!/usr/bin/env bash
# Installe les compilateurs à côté de l'exécutable (voir chaines.ps1 pour la
# version Windows et l'explication complète).
#
# Sous Linux, la plupart des distributions ont déjà ces chaînes en paquets :
# c'est plus simple, plus léger, et l'application les trouve dans le PATH.
# Ce script ne sert donc qu'à préparer une archive portable à emporter.
set -euo pipefail
cd "$(dirname "$0")/.."

dossier="chaines"
for candidat in build-paquet build; do
    [ -d "$candidat" ] && dossier="$candidat/chaines" && break
done
mkdir -p "$dossier"

echo "Sous Linux, préférez les paquets de votre distribution :"
echo "  AVR    : sudo apt install gcc-avr avr-libc"
echo "  ARM    : sudo apt install gcc-arm-none-eabi"
echo "  Xtensa : voir espressif/crosstool-NG (pas de paquet officiel)"
echo
echo "L'application les trouvera dans le PATH. Pour une archive portable,"
echo "copiez une chaîne dans : $dossier/<avr|arm|xtensa>/"
echo
echo "ATTENTION : copiez l'ARBRE ENTIER de la chaîne, pas seulement bin/."
echo "GCC cherche ses fichiers de support (device-specs, lib, include) par"
echo "un chemin relatif au binaire : un bin/ seul échoue avec un message"
echo "aussi obscur que « device-specs/specs-atmega328p: No such file »."
