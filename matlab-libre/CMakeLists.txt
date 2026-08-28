# MatLibre — clone libre du langage MATLAB.
#
# Aucune dépendance obligatoire : un compilateur C++17 suffit. LAPACK, BLAS
# et FFTW sont utilisés s'ils sont présents, uniquement pour accélérer les
# gros calculs ; les mêmes algorithmes sont écrits dans src/coeur.
cmake_minimum_required(VERSION 3.16)
project(MatLibre VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# MatLibre n'emploie pas les modules C++20 : couper le balayage évite un
# travail inutile à chaque compilation.
if(POLICY CMP0155)
  cmake_policy(SET CMP0155 NEW)
endif()
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
endif()

# Le générateur Ninja met le type de construction dans le nom de ses
# règles : « rule CXX_COMPILER__matlibre_coeur_unscanned_Release ». Or « $ »
# ouvre une référence de variable dans la syntaxe de ninja. Un type de
# construction qui en contient un — une variable de shell qui n'a pas été
# remplacée, « $type » ou « %type% » — produit une règle que ninja refuse
# de lire, sur un message qui ne dit pas d'où vient le problème :
#
#   ninja: error: CMakeFiles/rules.ninja:17: expected newline, got lexing error
#
# La valeur est vérifiée ici, où l'on peut encore nommer le remède. Elle
# reste dans le cache tant que le dossier de construction existe : c'est
# pourquoi le message demande de l'effacer.
if(NOT CMAKE_BUILD_TYPE MATCHES "^[A-Za-z][A-Za-z0-9_]*$" AND NOT CMAKE_BUILD_TYPE STREQUAL "")
  message(FATAL_ERROR
    "CMAKE_BUILD_TYPE vaut « ${CMAKE_BUILD_TYPE} », ce qui n'est pas un type "
    "de construction : une variable de shell n'a pas ete remplacee. Effacez "
    "le dossier de construction, puis reconfigurez :\n"
    "    cmake -E rm -rf \"${CMAKE_BINARY_DIR}\"\n"
    "    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release")
endif()

option(MATLIBRE_AVEC_LAPACK "Utiliser LAPACK/BLAS si disponible" ON)
option(MATLIBRE_AVEC_FFTW   "Utiliser FFTW si disponible"        ON)
option(MATLIBRE_TESTS       "Construire les tests"               ON)

if(MSVC)
  add_compile_options(/W4 /utf-8 /bigobj)
else()
  add_compile_options(-Wall -Wextra -Wno-unused-parameter)
endif()

file(GLOB_RECURSE MATLIBRE_SOURCES
     ${CMAKE_CURRENT_SOURCE_DIR}/src/coeur/*.cpp
     ${CMAKE_CURRENT_SOURCE_DIR}/src/bibliotheque/*.cpp
     ${CMAKE_CURRENT_SOURCE_DIR}/src/graphique/*.cpp
     ${CMAKE_CURRENT_SOURCE_DIR}/src/ide/*.cpp)

add_library(matlibre_coeur STATIC ${MATLIBRE_SOURCES})
target_include_directories(matlibre_coeur PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

if(MATLIBRE_AVEC_LAPACK)
  find_package(LAPACK QUIET)
  if(LAPACK_FOUND)
    target_link_libraries(matlibre_coeur PUBLIC ${LAPACK_LIBRARIES})
    target_compile_definitions(matlibre_coeur PUBLIC MATLIBRE_LAPACK=1)
    message(STATUS "MatLibre : LAPACK trouve, il servira aux grandes matrices")
  else()
    message(STATUS "MatLibre : pas de LAPACK, algebre lineaire interne")
  endif()
endif()

if(MATLIBRE_AVEC_FFTW)
  find_library(FFTW3_LIB fftw3)
  find_path(FFTW3_INC fftw3.h)
  if(FFTW3_LIB AND FFTW3_INC)
    target_link_libraries(matlibre_coeur PUBLIC ${FFTW3_LIB})
    target_include_directories(matlibre_coeur PUBLIC ${FFTW3_INC})
    target_compile_definitions(matlibre_coeur PUBLIC MATLIBRE_FFTW=1)
    message(STATUS "MatLibre : FFTW trouve")
  else()
    message(STATUS "MatLibre : pas de FFTW, transformee interne")
  endif()
endif()

find_package(Threads QUIET)
if(Threads_FOUND)
  target_link_libraries(matlibre_coeur PUBLIC Threads::Threads)
endif()

# Le serveur de l'atelier ouvre une prise réseau. Sous Windows, les
# fonctions de Winsock vivent dans ws2_32 : sans cette ligne, MinGW
# s'arrête à l'édition de liens sur des références indéfinies à socket,
# bind et WSAStartup. Visual Studio ne s'en tire que grâce à un pragma,
# qu'on ne veut pas dans le code portable.
if(WIN32)
  target_link_libraries(matlibre_coeur PUBLIC ws2_32)
endif()

add_executable(matlibre ${CMAKE_CURRENT_SOURCE_DIR}/src/console/Principal.cpp)
target_link_libraries(matlibre PRIVATE matlibre_coeur)

# --- installation -----------------------------------------------------------
include(GNUInstallDirs)
install(TARGETS matlibre RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/toolbox/
        DESTINATION ${CMAKE_INSTALL_DATADIR}/matlibre)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/ide/
        DESTINATION ${CMAKE_INSTALL_DATADIR}/matlibre-ide)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/documentation/
        DESTINATION ${CMAKE_INSTALL_DOCDIR})

# --- dépendances optionnelles supplémentaires --------------------------------
option(MATLIBRE_AVEC_SUITESPARSE "Utiliser SuiteSparse (UMFPACK/CHOLMOD) si disponible" ON)
option(MATLIBRE_AVEC_OPENCV      "Utiliser OpenCV si disponible"                        ON)

if(MATLIBRE_AVEC_SUITESPARSE)
  find_library(UMFPACK_LIB umfpack)
  find_path(UMFPACK_INC umfpack.h PATH_SUFFIXES suitesparse)
  if(UMFPACK_LIB AND UMFPACK_INC)
    target_link_libraries(matlibre_coeur PUBLIC ${UMFPACK_LIB})
    target_include_directories(matlibre_coeur PUBLIC ${UMFPACK_INC})
    target_compile_definitions(matlibre_coeur PUBLIC MATLIBRE_SUITESPARSE=1)
    message(STATUS "MatLibre : SuiteSparse trouve, il servira aux grands systemes creux")
  else()
    message(STATUS "MatLibre : pas de SuiteSparse, solveur creux interne")
  endif()
endif()

if(MATLIBRE_AVEC_OPENCV)
  find_package(OpenCV QUIET COMPONENTS core imgproc imgcodecs)
  if(OpenCV_FOUND)
    target_link_libraries(matlibre_coeur PUBLIC ${OpenCV_LIBS})
    target_include_directories(matlibre_coeur PUBLIC ${OpenCV_INCLUDE_DIRS})
    target_compile_definitions(matlibre_coeur PUBLIC MATLIBRE_OPENCV=1)
    message(STATUS "MatLibre : OpenCV trouve, lecture et ecriture d'images elargies")
  else()
    message(STATUS "MatLibre : pas d'OpenCV, lecture d'images interne (PGM, PPM, BMP)")
  endif()
endif()

# --- fabrication de paquets ---------------------------------------------------
set(CPACK_PACKAGE_NAME "MatLibre")
set(CPACK_PACKAGE_VENDOR "MatLibre")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Clone libre du langage MATLAB")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_CONTACT "matlibre@example.invalid")
set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE)
set(CPACK_PACKAGE_INSTALL_DIRECTORY "MatLibre")
if(WIN32)
  set(CPACK_GENERATOR "ZIP")
elseif(APPLE)
  set(CPACK_GENERATOR "TGZ")
else()
  set(CPACK_GENERATOR "TGZ;DEB")
  set(CPACK_DEBIAN_PACKAGE_SECTION "math")
  set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6, libstdc++6")
  set(CPACK_DEBIAN_PACKAGE_MAINTAINER "MatLibre")
endif()
include(CPack)

# --- tests ------------------------------------------------------------------
if(MATLIBRE_TESTS)
  enable_testing()
  file(GLOB MATLIBRE_TESTS_CPP ${CMAKE_CURRENT_SOURCE_DIR}/tests/coeur/*.cpp)
  if(MATLIBRE_TESTS_CPP)
    add_executable(matlibre_tests ${MATLIBRE_TESTS_CPP})
    target_link_libraries(matlibre_tests PRIVATE matlibre_coeur)
    add_test(NAME unitaires COMMAND matlibre_tests)
  endif()
  file(GLOB MATLIBRE_TESTS_M ${CMAKE_CURRENT_SOURCE_DIR}/tests/scripts/test_*.m)
  foreach(fichier ${MATLIBRE_TESTS_M})
    get_filename_component(nom ${fichier} NAME_WE)
    add_test(NAME langage_${nom}
             COMMAND matlibre --path ${CMAKE_CURRENT_SOURCE_DIR}/toolbox
                     --path ${CMAKE_CURRENT_SOURCE_DIR}/tests/scripts ${fichier})
    set_tests_properties(langage_${nom} PROPERTIES
      ENVIRONMENT "MATLIBRE_TOOLBOX=${CMAKE_CURRENT_SOURCE_DIR}/toolbox")
  endforeach()
endif()
