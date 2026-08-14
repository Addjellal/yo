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
# Le dépôt en emporte une copie sous « tiers/ngspice » : c'est le défaut, et
# sur Windows il n'y a donc rien à faire. Seuls trois fichiers y sont — l'
# en-tête, la DLL et la bibliothèque d'import — et non la distribution
# entière, qui pèse dix fois plus.
#
# La copie embarquée est celle de Windows — une DLL et sa bibliothèque
# d'import PE. Ailleurs elle n'est bonne à rien, et pire : l'éditeur de liens
# de GNU l'accepte à l'entrée puis échoue sur « dangerous relocation:
# R_AMD64_IMAGEBASE ». Sur les autres systèmes, ngspice s'installe par le
# gestionnaire de paquets et se trouve tout seul ; le défaut y reste vide.
if(WIN32)
  set(NGSPICE_DEFAUT "${CMAKE_CURRENT_SOURCE_DIR}/tiers/ngspice")
else()
  set(NGSPICE_DEFAUT "")
endif()
set(NGSPICE_ROOT "${NGSPICE_DEFAUT}" CACHE PATH
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
  src/core/engines/CoeurCortexM.cpp
  src/core/engines/CoeurXtensa.cpp
  src/core/engines/XtensaEngine.cpp
  src/core/engines/CortexEngine.cpp
  src/core/engines/AvrEngine.cpp
  src/core/engines/Chaines.cpp
  src/core/engines/Microcontroleur.cpp
  src/core/engines/MoteurNumerique.cpp
  src/core/analysis/Analyses.cpp
  src/core/analysis/Campagne.cpp
  src/core/export/Documents.cpp
  src/core/pcb/Pcb.cpp
  src/core/pcb/Empreintes.cpp
  src/core/pcb/Routeur.cpp
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

# --- La passe sanitizers -----------------------------------------------------
#
# ASan et UBSan trouvent ce qu'aucun test fonctionnel ne voit : un dépassement
# de tableau qui tombe sur de la mémoire encore valide, un décalage à gauche
# qui déborde, une lecture après libération. Le simulateur en a déjà eu — neuf
# décalages signés débordants dans les trois cœurs, trouvés par cette passe et
# invisibles autrement, parce que le résultat était juste sur cette machine-là.
#
# Elle n'était lancée qu'à la main, donc pas lancée. Elle est maintenant un
# ensemble ctest à part, parce qu'elle demande une SECONDE construction : on ne
# peut pas assainir un binaire déjà compilé.
#
#   cmake -S . -B build-san -DSANITISER=ON -DCMAKE_BUILD_TYPE=Debug
#   cmake --build build-san -j8 --target tests_coeur
#   ctest --test-dir build-san -L sanitiseurs
#
# La détection de fuites est éteinte : Qt et ngspice en laissent au dernier
# souffle, et les traquer ici noierait le signal.
option(SANITISER "Compiler avec ASan et UBSan (construction séparée)" OFF)
if(SANITISER)
  foreach(cible coeur tests_coeur)
    target_compile_options(${cible} PRIVATE
      -fsanitize=address,undefined -fno-omit-frame-pointer -g)
    target_link_options(${cible} PRIVATE -fsanitize=address,undefined)
  endforeach()
  set_tests_properties(coeur PROPERTIES
    LABELS sanitiseurs
    ENVIRONMENT "ASAN_OPTIONS=detect_leaks=0;UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1")
endif()

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
    src/app/schematic/ItemJonction.cpp
    src/app/panels/PanneauAnalyses.cpp
    src/app/panels/FenetreInstrument.cpp
    src/app/panels/PanneauPcb.cpp
    src/app/Oscilloscope.cpp
    # Le couplage des moteurs ne dépend pas de la fenêtre : le mettre ici le
    # rend testable sans ouvrir l'application, et c'est là que se jouent les
    # gestes risqués (effacer un composant pendant que ça tourne).
    src/app/MoteurSimulation.cpp
    # La fenêtre entre ici pour la même raison : ses commandes — pivoter,
    # supprimer, changer de page — se vérifient sans ouvrir l'application, et
    # ce sont justement celles où une erreur de portée est invisible à l'œil.
    src/app/FenetrePrincipale.cpp
  )
  target_link_libraries(schema PUBLIC coeur Qt6::Widgets)

  add_executable(simulateur
    src/main.cpp
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

  # windeployqt vit à côté de qmake ; le dossier des greffons se demande à Qt.
  get_target_property(QT_QMAKE Qt6::qmake IMPORTED_LOCATION)
  get_filename_component(QT_DOSSIER_BIN "${QT_QMAKE}" DIRECTORY)
  find_program(SIM_WINDEPLOYQT NAMES windeployqt windeployqt6
               HINTS "${QT_DOSSIER_BIN}")
  execute_process(COMMAND "${QT_QMAKE}" -query QT_INSTALL_PLUGINS
                  OUTPUT_VARIABLE SIM_QT_PLUGINS
                  OUTPUT_STRIP_TRAILING_WHITESPACE
                  ERROR_QUIET)

  # Le runtime du compilateur (libstdc++, libgcc, libwinpthread) doit voyager
  # lui aussi. windeployqt sait le faire — « --compiler-runtime » — mais il
  # dépose celui **de Qt**, c'est-à-dire du MinGW avec lequel Qt a été bâti.
  # Quand on construit avec un autre MinGW (WinLibs, MSYS2), ces DLL-là sont
  # plus anciennes que le code qu'elles doivent servir ; et comme le dossier
  # de l'exécutable passe avant le PATH, ce sont elles que le chargeur prend.
  # L'application meurt alors avant main(), sans message et sans fenêtre, avec
  # le code 0xC0000139 (« point d'entrée introuvable »). On copie donc le
  # runtime du compilateur qu'on utilise vraiment, et on interdit à
  # windeployqt de poser le sien.
  set(SIM_OPT_RUNTIME --compiler-runtime)
  set(SIM_DLL_RUNTIME)
  if(WIN32 AND MINGW)
    set(SIM_OPT_RUNTIME --no-compiler-runtime)
    get_filename_component(SIM_DOSSIER_CXX "${CMAKE_CXX_COMPILER}" DIRECTORY)
    # seh sur x86_64, dw2 sur x86 ; un MinGW lié statiquement n'en a aucune,
    # et alors il n'y a rien à emporter.
    foreach(nom libstdc++-6 libgcc_s_seh-1 libgcc_s_dw2-1 libwinpthread-1)
      if(EXISTS "${SIM_DOSSIER_CXX}/${nom}.dll")
        list(APPEND SIM_DLL_RUNTIME "${SIM_DOSSIER_CXX}/${nom}.dll")
      endif()
    endforeach()
    if(SIM_DLL_RUNTIME)
      message(STATUS "Runtime du compilateur : ${SIM_DOSSIER_CXX}")
    else()
      message(STATUS "Runtime du compilateur : lié statiquement, rien à copier")
    endif()
  endif()

  # Sous Windows, on dépose les DLL de Qt à côté de l'exécutable dès la
  # compilation. Sans cela, le fichier produit dans le dossier de
  # construction refuse de démarrer — il va chercher Qt dans le PATH, y
  # trouve une autre version, et se plaint d'un point d'entrée introuvable.
  # Un exécutable qui existe doit se lancer : c'est le minimum.
  if(WIN32 AND SIM_WINDEPLOYQT)
    add_custom_command(TARGET simulateur POST_BUILD
      COMMAND "${SIM_WINDEPLOYQT}" --release --no-translations
              --no-system-d3d-compiler --no-opengl-sw ${SIM_OPT_RUNTIME}
              "$<TARGET_FILE:simulateur>"
      COMMENT "Dépôt des DLL de Qt à côté de l'exécutable")
    # Après windeployqt, pour écraser un runtime déposé par une construction
    # antérieure : c'est le nôtre qui doit rester.
    if(SIM_DLL_RUNTIME)
      add_custom_command(TARGET simulateur POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different ${SIM_DLL_RUNTIME}
                "$<TARGET_FILE_DIR:simulateur>"
        COMMENT "Dépôt du runtime du compilateur")
    endif()
  elseif(WIN32)
    message(WARNING
      "windeployqt introuvable : l'exécutable produit ne démarrera que si "
      "le dossier bin de Qt est dans le PATH.")
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
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/INSTALLATION-WINDOWS.md"
          DESTINATION .)
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/README.md"
                "${CMAKE_CURRENT_SOURCE_DIR}/COMPARAISON.md"
          DESTINATION documentation)

  # Le mot d'accueil du paquet : ce qu'il contient, comment on le lance, et
  # la seule chose qui reste à installer si l'on veut écrire du C.
  configure_file("${CMAKE_CURRENT_SOURCE_DIR}/outils/LISEZ-MOI.txt.in"
                 "${CMAKE_CURRENT_BINARY_DIR}/LISEZ-MOI.txt" @ONLY)
  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/LISEZ-MOI.txt" DESTINATION .)

  install(CODE "set(SIM_EXECUTABLE \"$<TARGET_FILE:simulateur>\")")
  install(CODE "set(SIM_WINDEPLOYQT \"${SIM_WINDEPLOYQT}\")")
  install(CODE "set(SIM_QT_PLUGINS \"${SIM_QT_PLUGINS}\")")
  install(CODE "set(SIM_OPT_RUNTIME \"${SIM_OPT_RUNTIME}\")")
  install(CODE "set(SIM_DLL_RUNTIME \"${SIM_DLL_RUNTIME}\")")
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

# ---------------------------------------------------------------------------
# Les chaînes de compilation emportées par le paquet.
#
# Elles ne sont pas dans le dépôt — plusieurs centaines de mégaoctets n'ont
# rien à faire dans un historique de code. Le script outils/chaines les pose
# dans « <build>/chaines », et ce bloc les emporte dans l'archive si elles y
# sont. Le paquet devient alors autosuffisant : plus rien à installer sur la
# machine qui le reçoit.
# ---------------------------------------------------------------------------
if(EXISTS "${CMAKE_BINARY_DIR}/chaines")
  install(DIRECTORY "${CMAKE_BINARY_DIR}/chaines"
          DESTINATION .
          USE_SOURCE_PERMISSIONS)
  message(STATUS
    "Chaînes de compilation trouvées : elles seront emportées par le paquet.")
else()
  message(STATUS
    "Aucune chaîne dans ${CMAKE_BINARY_DIR}/chaines : le paquet dépendra de "
    "ce qui est installé sur la machine. Lancez outils/chaines pour le rendre "
    "autosuffisant.")
endif()
