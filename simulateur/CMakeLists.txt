cmake_minimum_required(VERSION 3.16)
project(SimulateurEmbarque VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

if(MSVC)
  add_compile_options(/W4 /utf-8)
else()
  add_compile_options(-Wall -Wextra)
endif()

# ---------------------------------------------------------------------------
# Dépendances.
#
# OBLIGATOIRE : un compilateur C++17, et Qt 6 pour l'interface. Rien d'autre.
# Le solveur analogique est écrit dans ce projet (src/core/engines/
# SolveurIntegre.cpp) : il n'y a aucune bibliothèque de simulation à
# télécharger, aucune DLL à poser à côté de l'exécutable.
#
# FACULTATIF, et seulement pour ce qui suit :
#   ngspice -> second moteur analogique, celui de référence. Utile pour
#              comparer : les tests font tourner les deux sur les mêmes
#              circuits quand il est là.
#   simavr  -> second cœur AVR, celui de référence. Le cœur ATmega328P est
#              lui aussi écrit dans ce projet (CoeurAvr.cpp) ; simavr ne sert
#              qu'à le confronter dans les tests.
#
# Pour écrire un programme AVR depuis l'application, il faut `avr-gcc` dans le
# PATH — un compilateur C ne s'embarque pas. Sans lui, on charge un .elf déjà
# compilé, et tout le reste fonctionne.
# ---------------------------------------------------------------------------
# Sous Windows, ngspice se télécharge en archive plutôt qu'il ne s'installe.
# « -DNGSPICE_ROOT=C:/Spice64_dll » suffit alors : les sous-dossiers de la
# distribution officielle sont connus ici, il n'y a pas à désigner le fichier.
set(NGSPICE_ROOT "" CACHE PATH
    "Dossier de ngspice décompressé (celui qui contient include/ et dll-vs/)")
find_path(NGSPICE_INCLUDE_DIR ngspice/sharedspice.h
          HINTS ${NGSPICE_ROOT} ${NGSPICE_ROOT}/include)
# L'ordre compte : bibliothèque d'import Visual Studio si elle est là, sinon
# la DLL elle-même — l'éditeur de liens de MinGW sait s'y attacher directement.
find_library(NGSPICE_LIBRARY
             NAMES ngspice
             HINTS ${NGSPICE_ROOT}
                   ${NGSPICE_ROOT}/lib/lib-vs
                   ${NGSPICE_ROOT}/lib
                   ${NGSPICE_ROOT}/dll-vs
                   ${NGSPICE_ROOT}/bin)

# La distribution Windows officielle ne livre ni « libngspice.dll.a » ni
# « ngspice.a » : find_library, qui raisonne par préfixe et suffixe, passe donc
# à côté. On désigne alors le fichier par son nom exact — l'éditeur de liens
# de MinGW comme celui de Visual Studio savent s'attacher à l'un ou à l'autre.
if(NOT NGSPICE_LIBRARY)
  find_file(NGSPICE_LIBRARY
            NAMES ngspice.lib ngspice.dll libngspice-0.dll
            HINTS ${NGSPICE_ROOT}
                  ${NGSPICE_ROOT}/lib/lib-vs
                  ${NGSPICE_ROOT}/dll-vs
                  ${NGSPICE_ROOT}/bin
            NO_DEFAULT_PATH)
endif()
find_path(SIMAVR_INCLUDE_DIR simavr/sim_avr.h)
find_library(SIMAVR_LIBRARY NAMES simavr)
find_library(ELF_LIBRARY NAMES elf)

# Un paquet portable ne doit rien traîner d'autre que lui-même : cette
# option ignore ngspice et simavr même s'ils sont installés sur la machine de
# compilation, pour que l'exécutable produit ne dépende que de Qt.
option(SIM_AUTONOME "Ignorer ngspice et simavr (paquet portable)" OFF)

set(MOTEUR_NGSPICE OFF)
if(NGSPICE_INCLUDE_DIR AND NGSPICE_LIBRARY AND NOT SIM_AUTONOME)
  set(MOTEUR_NGSPICE ON)
endif()
set(MOTEUR_SIMAVR OFF)
if(SIMAVR_INCLUDE_DIR AND SIMAVR_LIBRARY AND ELF_LIBRARY AND NOT SIM_AUTONOME)
  set(MOTEUR_SIMAVR ON)
endif()
if(SIM_AUTONOME)
  message(STATUS
    "SIM_AUTONOME : ngspice et simavr sont ignorés — l'exécutable ne "
    "dépendra que de Qt.")
endif()

message(STATUS "Moteur analogique : solveur intégré (toujours actif)")
message(STATUS "Second moteur ngspice   : ${MOTEUR_NGSPICE} (facultatif)")
message(STATUS "Cœur AVR          : cœur intégré (toujours actif)")
message(STATUS "Second cœur simavr      : ${MOTEUR_SIMAVR} (facultatif)")

# ngspice n'est plus nécessaire : le solveur intégré calcule tout. Sa
# présence n'ajoute qu'un point de comparaison, et les tests s'en servent.
if(NOT MOTEUR_NGSPICE)
  message(STATUS
    "ngspice absent : le solveur intégré calcule tout (point de repos, "
    "transitoire, .dc, .ac, bruit). Installer ngspice n'apporterait qu'un "
    "second moteur pour comparer.")
endif()
if(NOT MOTEUR_SIMAVR)
  message(STATUS
    "simavr absent : le cœur AVR intégré exécute le firmware. Installer "
    "simavr n'apporterait qu'un second cœur pour comparer.")
endif()

# ---------------------------------------------------------------------------
# Bibliothèque « cœur » : aucune dépendance à l'interface graphique, donc
# testable sans écran et réutilisable par le futur module PCB.
# ---------------------------------------------------------------------------
add_library(coeur STATIC
  src/core/Netlist.cpp
  src/core/Device.cpp
  src/core/catalogue/base.cpp
  src/core/catalogue/cartes.cpp
  src/core/catalogue/semiconducteurs.cpp
  src/core/catalogue/capteurs.cpp
  src/core/catalogue/electromecanique.cpp
  src/core/catalogue/logique.cpp
  src/core/catalogue/instruments.cpp
  src/core/catalogue/actionneurs_dynamiques.cpp
  src/core/catalogue/capteurs_avances.cpp
  src/core/catalogue/sources.cpp
  src/core/catalogue/numerique.cpp
  src/core/engines/SolveurIntegre.cpp
  src/core/engines/ExpressionSpice.cpp
  src/core/engines/NgspiceEngine.cpp
  src/core/engines/CoeurAvr.cpp
  src/core/engines/AvrEngine.cpp
  src/core/engines/MoteurNumerique.cpp
  src/core/analysis/Analyses.cpp
  src/core/analysis/Campagne.cpp
  src/core/export/Documents.cpp
  src/core/pcb/Pcb.cpp
  src/core/pcb/Empreintes.cpp
)
target_include_directories(coeur PUBLIC src)

if(MOTEUR_NGSPICE)
  target_compile_definitions(coeur PUBLIC AVEC_NGSPICE=1)
  target_include_directories(coeur PUBLIC ${NGSPICE_INCLUDE_DIR})
  target_link_libraries(coeur PUBLIC ${NGSPICE_LIBRARY})
endif()
if(MOTEUR_SIMAVR)
  target_compile_definitions(coeur PUBLIC AVEC_SIMAVR=1)
  target_include_directories(coeur PUBLIC ${SIMAVR_INCLUDE_DIR})
  target_link_libraries(coeur PUBLIC ${SIMAVR_LIBRARY} ${ELF_LIBRARY})
endif()

# ---------------------------------------------------------------------------
# Tests du cœur (sans interface graphique)
# ---------------------------------------------------------------------------
enable_testing()
add_executable(tests_coeur tests/test_coeur.cpp)
target_link_libraries(tests_coeur PRIVATE coeur)
add_test(NAME coeur COMMAND tests_coeur)

# ---------------------------------------------------------------------------
# Générateur de figures : dessine les schémas du cours à partir du catalogue.
# Sans Qt : c'est du SVG écrit directement.
# ---------------------------------------------------------------------------
add_executable(generer_figures outils/generer_figures.cpp)
target_link_libraries(generer_figures PRIVATE coeur)
target_include_directories(generer_figures PRIVATE outils)
# Les figures sont une table de données : omettre les derniers champs d'un
# placement est voulu et se lit mieux que « , {} » répété quarante fois.
if(NOT MSVC)
  target_compile_options(generer_figures PRIVATE -Wno-missing-field-initializers)
endif()

# ---------------------------------------------------------------------------
# Application Qt (facultative : le cœur se compile et se teste sans Qt)
# ---------------------------------------------------------------------------
find_package(Qt6 COMPONENTS Widgets QUIET)
if(Qt6_FOUND AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp")
  set(CMAKE_AUTOMOC ON)
  set(CMAKE_AUTORCC ON)
  # La saisie de schéma est une bibliothèque à part : elle est ainsi
  # testable sans lancer l'application ni ouvrir de fenêtre.
  add_library(schema STATIC
    src/app/schematic/SceneSchema.cpp
    src/app/schematic/VueSchema.cpp
    src/app/schematic/ItemComposant.cpp
    src/app/schematic/ItemFil.cpp
    src/app/panels/PanneauAnalyses.cpp
    src/app/panels/FenetreInstrument.cpp
    src/app/panels/PanneauPcb.cpp
    src/app/Oscilloscope.cpp
  )
  target_link_libraries(schema PUBLIC coeur Qt6::Widgets)

  add_executable(simulateur
    src/main.cpp
    src/app/FenetrePrincipale.cpp
    src/app/MoteurSimulation.cpp
  )
  target_link_libraries(simulateur PRIVATE schema)

  # Sous Windows, une application graphique se construit « WIN32 » pour ne pas
  # traîner une console derrière elle. C'est aussi ce qui fait entrer
  # Qt6::EntryPoint dans l'édition de liens — et cette bibliothèque-là vient
  # telle quelle de chez Qt : elle n'accepte que le compilateur avec lequel Qt
  # a été construit (sinon « undefined reference to __imp___argc »).
  # « -DFENETRE_WIN32=OFF » permet donc de compiler malgré tout avec un autre
  # MinGW, au prix d'une console qui reste ouverte : dépannage, pas remède.
  option(FENETRE_WIN32 "Application fenêtrée sans console (Windows)" ON)
  if(WIN32 AND FENETRE_WIN32)
    set_target_properties(simulateur PROPERTIES WIN32_EXECUTABLE ON)
  endif()

  add_executable(tests_schema tests/test_schema.cpp)
  target_link_libraries(tests_schema PRIVATE schema)
  add_test(NAME schema COMMAND tests_schema)
  # Sans écran, Qt tente le greffon xcb et abandonne : ctest doit lui imposer
  # le rendu hors écran.
  set_tests_properties(schema PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
  message(STATUS "Application Qt : activée (Qt ${Qt6_VERSION})")

  # -------------------------------------------------------------------------
  # Paquet portable : un dossier qu'on décompresse et qu'on lance.
  #
  #   cmake --build build --target paquet
  #
  # Rien n'est installé sur la machine d'accueil : Qt voyage avec
  # l'application, et les moteurs de simulation sont déjà dans l'exécutable.
  # -------------------------------------------------------------------------
  install(TARGETS simulateur RUNTIME DESTINATION . BUNDLE DESTINATION .)
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/README.md"
                "${CMAKE_CURRENT_SOURCE_DIR}/COMPARAISON.md"
          DESTINATION documentation)

  # Le mot d'accueil du paquet : ce qu'il contient, comment on le lance, et
  # la seule chose qui reste à installer si l'on veut écrire du C.
  configure_file("${CMAKE_CURRENT_SOURCE_DIR}/outils/LISEZ-MOI.txt.in"
                 "${CMAKE_CURRENT_BINARY_DIR}/LISEZ-MOI.txt" @ONLY)
  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/LISEZ-MOI.txt" DESTINATION .)

  # windeployqt vit à côté de qmake ; le dossier des greffons se demande à Qt.
  get_target_property(QT_QMAKE Qt6::qmake IMPORTED_LOCATION)
  get_filename_component(QT_DOSSIER_BIN "${QT_QMAKE}" DIRECTORY)
  find_program(SIM_WINDEPLOYQT NAMES windeployqt windeployqt6
               HINTS "${QT_DOSSIER_BIN}")
  execute_process(COMMAND "${QT_QMAKE}" -query QT_INSTALL_PLUGINS
                  OUTPUT_VARIABLE SIM_QT_PLUGINS
                  OUTPUT_STRIP_TRAILING_WHITESPACE
                  ERROR_QUIET)

  install(CODE "set(SIM_EXECUTABLE \"$<TARGET_FILE:simulateur>\")")
  install(CODE "set(SIM_WINDEPLOYQT \"${SIM_WINDEPLOYQT}\")")
  install(CODE "set(SIM_QT_PLUGINS \"${SIM_QT_PLUGINS}\")")
  install(SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/outils/paquet.cmake")

  set(CPACK_PACKAGE_NAME "simulateur-embarque")
  set(CPACK_PACKAGE_VENDOR "Formation embarquée")
  set(CPACK_PACKAGE_DESCRIPTION_SUMMARY
      "Schéma, simulation analogique et exécution de firmware AVR")
  set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
  set(CPACK_PACKAGE_INSTALL_DIRECTORY "simulateur-embarque")
  set(CPACK_VERBATIM_VARIABLES ON)
  # Une archive, pas un installateur : le paquet doit pouvoir vivre sur une
  # clé USB et tourner sans droits d'administration.
  if(WIN32)
    set(CPACK_GENERATOR "ZIP")
    set(CPACK_SYSTEM_NAME "windows-x64")
  elseif(APPLE)
    set(CPACK_GENERATOR "TGZ")
    set(CPACK_SYSTEM_NAME "macos")
  else()
    set(CPACK_GENERATOR "TGZ")
    set(CPACK_SYSTEM_NAME "linux-x64")
  endif()
  set(CPACK_PACKAGE_FILE_NAME
      "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CPACK_SYSTEM_NAME}")
  include(CPack)

  add_custom_target(paquet
    COMMAND "${CMAKE_CPACK_COMMAND}" --config "${CMAKE_BINARY_DIR}/CPackConfig.cmake"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    DEPENDS simulateur
    COMMENT "Fabrication du paquet portable")
else()
  message(STATUS "Application Qt : désactivée (Qt6 introuvable) — le cœur reste compilable")
endif()
