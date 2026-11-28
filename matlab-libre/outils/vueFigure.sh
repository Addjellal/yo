#!/bin/bash
# vueFigure.sh — construit outils/vueFigure.cpp contre la bibliothèque du
# bureau, puis peint hors écran les figures d'un script.
#
# Usage : outils/vueFigure.sh SCRIPT.m DOSSIER_PNG
# Demande un build/ à jour (cmake --build build) avec Qt6.
set -euo pipefail
racine="$(cd "$(dirname "$0")/.." && pwd)"
script="$1"
sortie="$2"
mkdir -p "$sortie"
qt=/usr/include/x86_64-linux-gnu/qt6
binaire="$racine/build/vueFigure"
c++ -std=gnu++17 -O1 -fPIC -DQT_CORE_LIB -DQT_GUI_LIB -DQT_WIDGETS_LIB \
    -I"$racine/build/matlibre_bureau_autogen/include" -I"$racine/src/bureau" \
    -I"$racine/include" -isystem "$qt" -isystem "$qt/QtWidgets" -isystem "$qt/QtCore" \
    -isystem "$qt/QtGui" -isystem /usr/lib/x86_64-linux-gnu/qt6/mkspecs/linux-g++ \
    "$racine/outils/vueFigure.cpp" -o "$binaire" \
    "$racine/build/CMakeFiles/matlibre-bureau.dir/matlibre-bureau_autogen/mocs_compilation.cpp.o" \
    "$racine/build/lib/libmatlibre_bureau.a" "$racine/build/lib/libmatlibre_coeur.a" \
    -lQt6Widgets -lQt6Gui -lQt6Core -lpthread
QT_QPA_PLATFORM=offscreen "$binaire" "$racine/toolbox" "$script" "$sortie"
