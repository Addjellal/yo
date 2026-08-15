#!/bin/bash
#
# Ce que ce hook empêche, et pourquoi il existe.
#
# Le simulateur se construit et passe au vert SANS ngspice ni simavr. Mais
# alors les sections [21] et [22] du banc — les deux seules confrontations à
# une implémentation indépendante — SE SAUTENT TOUTES SEULES, en l'annonçant
# sur une ligne noyée au milieu de quatre cents « ok ».
#
# Autrement dit : un banc vert ne veut pas dire la même chose selon la
# machine. 401 assertions sans ces paquets, 416 avec ; les quinze de
# différence SONT la vérification indépendante de l'analogique et de l'AVR.
#
# Un audit l'a découvert après que la garantie eut été annoncée pendant
# plusieurs sessions. La leçon : une garantie qui dépend d'un paquet
# facultatif ne tient pas dans un document — elle tient dans un script.
#
# Deux autres pertes constatées à l'usage, réparées ici pour la même raison :
# le conteneur peut perdre Qt6 en cours de route, et la chaîne ARM n'est pas
# toujours présente (quinze essais de compilation tombent alors en rouge, et
# l'on croit à une régression du code).
set -euo pipefail

# Ce hook ne sert qu'aux environnements distants et jetables. Sur une machine
# de travail, l'utilisateur gère ses paquets lui-même — les lui réinstaller à
# chaque ouverture de session serait présomptueux et lent.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Rien à faire si ce dépôt n'est pas celui qu'on croit.
if [ ! -f "${CLAUDE_PROJECT_DIR:-.}/simulateur/CMakeLists.txt" ]; then
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

# Idempotent : on ne réinstalle que ce qui manque. `dpkg -s` est le seul juge
# fiable — la présence d'un exécutable dans le PATH ne dit rien des en-têtes.
MANQUANTS=""
for paquet in \
    cmake \
    qt6-base-dev qt6-base-dev-tools libgl1-mesa-dev \
    gcc-avr avr-libc \
    gcc-arm-none-eabi \
    libngspice0-dev \
    simavr libsimavr-dev libelf-dev ; do
  if ! dpkg -s "$paquet" >/dev/null 2>&1; then
    MANQUANTS="$MANQUANTS $paquet"
  fi
done

if [ -z "$MANQUANTS" ]; then
  echo "simulateur : tous les paquets sont là (Qt6, AVR, ARM, ngspice, simavr)."
  exit 0
fi

echo "simulateur : installation de$MANQUANTS"
apt-get update -qq
# shellcheck disable=SC2086
apt-get install -y -qq $MANQUANTS

# Le contrôle qui compte : les deux moteurs de référence sont-ils VRAIMENT
# liables ? Un paquet installé dont l'en-tête manque ne servirait à rien, et
# l'on repartirait pour une session à croire un banc incomplet.
MOTEURS=""
[ -f /usr/include/ngspice/sharedspice.h ] && MOTEURS="$MOTEURS ngspice"
[ -f /usr/include/simavr/sim_avr.h ] && MOTEURS="$MOTEURS simavr"
if [ -n "$MOTEURS" ]; then
  echo "simulateur : moteurs de référence disponibles —$MOTEURS"
  echo "  Le banc cœur doit compter 416 assertions, pas 401."
else
  echo "simulateur : ATTENTION — aucun moteur de référence n'est liable."
  echo "  Les sections [21] et [22] du banc se sauteront, et le vert qu'il"
  echo "  affichera ne couvrira ni l'analogique ni l'AVR de façon indépendante."
fi
