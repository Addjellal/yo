# Fabrication du paquet portable.
#
# Exécuté par `cmake --install`, une fois l'exécutable copié. Son travail :
# ramasser tout ce dont l'application a besoin pour tourner sur une machine
# qui n'a rien d'installé, et le poser à côté d'elle.
#
#   Windows : `windeployqt`, livré avec Qt, sait exactement quelles DLL et
#             quels greffons emporter. On lui fait confiance.
#   Linux   : on résout les bibliothèques partagées avec CMake lui-même, on
#             écarte celles qui appartiennent au système (elles doivent venir
#             de la machine d'accueil, pas du paquet), et on écrit un
#             lanceur qui désigne le dossier `lib`.
#
# Le résultat se décompresse et se lance. Rien à installer, rien à régler.

if(NOT DEFINED SIM_EXECUTABLE)
  message(FATAL_ERROR "SIM_EXECUTABLE n'a pas été transmis au script de paquet")
endif()

get_filename_component(SIM_NOM "${SIM_EXECUTABLE}" NAME)
set(SIM_INSTALLE "${CMAKE_INSTALL_PREFIX}/${SIM_NOM}")

# ---------------------------------------------------------------------------
# Windows : windeployqt fait le travail
# ---------------------------------------------------------------------------
if(WIN32)
  if(NOT SIM_WINDEPLOYQT)
    message(WARNING
      "windeployqt est introuvable : le paquet contiendra l'exécutable sans "
      "les DLL de Qt, et ne démarrera pas sur une machine sans Qt. "
      "Indiquez-le avec -DSIM_WINDEPLOYQT=C:/Qt/6.x/mingw_64/bin/windeployqt.exe")
  else()
    message(STATUS "Déploiement de Qt avec ${SIM_WINDEPLOYQT}")
    execute_process(
      COMMAND "${SIM_WINDEPLOYQT}" --release --no-translations
              --no-system-d3d-compiler --no-opengl-sw --compiler-runtime
              "${SIM_INSTALLE}"
      RESULT_VARIABLE code)
    if(NOT code EQUAL 0)
      message(WARNING "windeployqt a échoué (code ${code})")
    endif()
  endif()
  return()
endif()

# ---------------------------------------------------------------------------
# Linux : bibliothèques et greffons ramassés à la main
# ---------------------------------------------------------------------------
file(MAKE_DIRECTORY "${CMAKE_INSTALL_PREFIX}/lib")

# Ce qui ne se met JAMAIS dans un paquet portable : la bibliothèque C, le
# chargeur dynamique, et tout ce qui touche au pilote graphique. Ces
# morceaux-là doivent venir de la machine sur laquelle on lance, sans quoi
# rien ne démarre.
set(EXCLUSIONS
    "ld-linux.*" "libc\\.so.*" "libm\\.so.*" "libdl\\.so.*" "libpthread\\.so.*"
    "librt\\.so.*" "libresolv\\.so.*" "libGL.*" "libEGL.*" "libGLX.*"
    "libGLdispatch.*" "libX11.*" "libxcb\\.so.*" "libXext.*" "libXrender.*"
    "libdrm.*" "libgbm.*" "libglib.*" "libgobject.*" "libgio.*"
    "libsystemd.*" "libudev.*" "libselinux.*" "libwayland.*")

file(GET_RUNTIME_DEPENDENCIES
     EXECUTABLES "${SIM_INSTALLE}"
     RESOLVED_DEPENDENCIES_VAR resolues
     UNRESOLVED_DEPENDENCIES_VAR manquantes
     POST_EXCLUDE_REGEXES ${EXCLUSIONS})

foreach(bibliotheque IN LISTS resolues)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib"
       TYPE SHARED_LIBRARY FOLLOW_SYMLINK_CHAIN FILES "${bibliotheque}")
endforeach()

list(LENGTH resolues nombre)
message(STATUS "${nombre} bibliothèques emportées dans le paquet")
if(manquantes)
  message(STATUS "Non résolues (fournies par le système) : ${manquantes}")
endif()

# Les greffons de plate-forme : sans eux, Qt ne sait pas ouvrir de fenêtre.
if(SIM_QT_PLUGINS AND EXISTS "${SIM_QT_PLUGINS}")
  foreach(famille platforms xcbglintegrations wayland-shell-integration
                  wayland-decoration-client wayland-graphics-integration-client
                  imageformats styles iconengines)
    if(EXISTS "${SIM_QT_PLUGINS}/${famille}")
      file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/plugins"
           TYPE DIRECTORY FILES "${SIM_QT_PLUGINS}/${famille}")
    endif()
  endforeach()
  # Les greffons tirent eux aussi des bibliothèques Qt : on les résout.
  file(GLOB_RECURSE greffons "${CMAKE_INSTALL_PREFIX}/plugins/*.so")
  if(greffons)
    file(GET_RUNTIME_DEPENDENCIES
         MODULES ${greffons}
         RESOLVED_DEPENDENCIES_VAR resolues_greffons
         POST_EXCLUDE_REGEXES ${EXCLUSIONS})
    foreach(bibliotheque IN LISTS resolues_greffons)
      file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib"
           TYPE SHARED_LIBRARY FOLLOW_SYMLINK_CHAIN FILES "${bibliotheque}")
    endforeach()
  endif()
endif()

# Le lanceur : il désigne le dossier des bibliothèques et celui des greffons,
# puis passe la main. C'est lui qu'on double-clique.
file(WRITE "${CMAKE_INSTALL_PREFIX}/simulateur.sh"
"#!/bin/sh
# Lanceur du paquet portable : tout est à côté, rien n'est installé.
ici=\"$(cd \"$(dirname \"$0\")\" && pwd)\"
LD_LIBRARY_PATH=\"$ici/lib:$LD_LIBRARY_PATH\"
QT_PLUGIN_PATH=\"$ici/plugins\"
export LD_LIBRARY_PATH QT_PLUGIN_PATH
exec \"$ici/${SIM_NOM}\" \"$@\"
")
execute_process(COMMAND chmod +x "${CMAKE_INSTALL_PREFIX}/simulateur.sh")
