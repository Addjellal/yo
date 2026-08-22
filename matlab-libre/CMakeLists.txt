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
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
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
     ${CMAKE_CURRENT_SOURCE_DIR}/src/graphique/*.cpp)

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

add_executable(matlibre ${CMAKE_CURRENT_SOURCE_DIR}/src/console/Principal.cpp)
target_link_libraries(matlibre PRIVATE matlibre_coeur)

# --- installation -----------------------------------------------------------
include(GNUInstallDirs)
install(TARGETS matlibre RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/toolbox/
        DESTINATION ${CMAKE_INSTALL_DATADIR}/matlibre)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/documentation/
        DESTINATION ${CMAKE_INSTALL_DOCDIR})

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
