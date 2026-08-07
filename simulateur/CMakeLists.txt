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
# Dépendances optionnelles : l'application fonctionne sans elles (moteurs
# internes), et gagne le réalisme « Proteus » quand elles sont présentes.
#   ngspice -> simulation analogique complète (transistors, AOP, transitoire)
#   simavr  -> exécution du VRAI firmware compilé par avr-gcc
# ---------------------------------------------------------------------------
find_path(NGSPICE_INCLUDE_DIR ngspice/sharedspice.h)
find_library(NGSPICE_LIBRARY NAMES ngspice)
find_path(SIMAVR_INCLUDE_DIR simavr/sim_avr.h)
find_library(SIMAVR_LIBRARY NAMES simavr)
find_library(ELF_LIBRARY NAMES elf)

set(MOTEUR_NGSPICE OFF)
if(NGSPICE_INCLUDE_DIR AND NGSPICE_LIBRARY)
  set(MOTEUR_NGSPICE ON)
endif()
set(MOTEUR_SIMAVR OFF)
if(SIMAVR_INCLUDE_DIR AND SIMAVR_LIBRARY AND ELF_LIBRARY)
  set(MOTEUR_SIMAVR ON)
endif()

message(STATUS "Moteur analogique ngspice : ${MOTEUR_NGSPICE}")
message(STATUS "Moteur AVR simavr        : ${MOTEUR_SIMAVR}")

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
  src/core/engines/NgspiceEngine.cpp
  src/core/engines/AvrEngine.cpp
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
  )
  target_link_libraries(schema PUBLIC coeur Qt6::Widgets)

  add_executable(simulateur WIN32
    src/main.cpp
    src/app/FenetrePrincipale.cpp
    src/app/MoteurSimulation.cpp
    src/app/Oscilloscope.cpp
  )
  target_link_libraries(simulateur PRIVATE schema)

  add_executable(tests_schema tests/test_schema.cpp)
  target_link_libraries(tests_schema PRIVATE schema)
  add_test(NAME schema COMMAND tests_schema)
  # Sans écran, Qt tente le greffon xcb et abandonne : ctest doit lui imposer
  # le rendu hors écran.
  set_tests_properties(schema PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
  message(STATUS "Application Qt : activée (Qt ${Qt6_VERSION})")
else()
  message(STATUS "Application Qt : désactivée (Qt6 introuvable) — le cœur reste compilable")
endif()
