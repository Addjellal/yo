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

# Les bibliotheques ci-dessous sont des ACCELERATEURS, pas des dependances :
# MatLibre a ses propres algorithmes pour tout ce qu'elles font, et les
# resultats sont les memes. On note celles qui manquent pour les resumer en
# une ligne a la fin, au lieu de quatre lignes qui ressemblent a des pannes.
set(MATLIBRE_INTERNES)
set(MATLIBRE_TROUVEES)

option(MATLIBRE_AVEC_LAPACK "Utiliser LAPACK/BLAS si disponible" ON)
option(MATLIBRE_AVEC_FFTW   "Utiliser FFTW si disponible"        ON)
option(MATLIBRE_TESTS       "Construire les tests"               ON)

if(MSVC)
  add_compile_options(/W4 /utf-8 /bigobj)
else()
  add_compile_options(-Wall -Wextra -Wno-unused-parameter)
endif()

# Un arbre de construction lisible : les executables dans bin/, les
# bibliotheques dans lib/, et tout le reste — le cache de CMake, les
# fichiers intermediaires, les sources engendrees par moc — la ou CMake
# les met. On ouvre build/bin et l'on y trouve ce qu'on cherche.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
# Les generateurs multi-configuration (Visual Studio, Xcode) ajoutent
# sinon un sous-dossier par type de compilation.
foreach(config ${CMAKE_CONFIGURATION_TYPES})
  string(TOUPPER ${config} CONFIG_MAJ)
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CONFIG_MAJ} ${CMAKE_BINARY_DIR}/bin)
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CONFIG_MAJ} ${CMAKE_BINARY_DIR}/lib)
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONFIG_MAJ} ${CMAKE_BINARY_DIR}/lib)
endforeach()

# CONFIGURE_DEPENDS : sans lui, un fichier ajoute n'entre dans la
# compilation qu'apres un « cmake » explicite, et l'edition de liens
# echoue sur un symbole qu'on vient pourtant d'ecrire.
file(GLOB_RECURSE MATLIBRE_SOURCES CONFIGURE_DEPENDS
     ${CMAKE_CURRENT_SOURCE_DIR}/src/coeur/*.cpp
     ${CMAKE_CURRENT_SOURCE_DIR}/src/bibliotheque/*.cpp
     ${CMAKE_CURRENT_SOURCE_DIR}/src/graphique/*.cpp
     )

add_library(matlibre_coeur STATIC ${MATLIBRE_SOURCES})
target_include_directories(matlibre_coeur PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

if(MATLIBRE_AVEC_LAPACK)
  find_package(LAPACK QUIET)
  if(LAPACK_FOUND)
    target_link_libraries(matlibre_coeur PUBLIC ${LAPACK_LIBRARIES})
    target_compile_definitions(matlibre_coeur PUBLIC MATLIBRE_LAPACK=1)
    list(APPEND MATLIBRE_TROUVEES "LAPACK/BLAS")
  else()
    list(APPEND MATLIBRE_INTERNES "LAPACK/BLAS")
  endif()
endif()

if(MATLIBRE_AVEC_FFTW)
  find_library(FFTW3_LIB fftw3)
  find_path(FFTW3_INC fftw3.h)
  if(FFTW3_LIB AND FFTW3_INC)
    target_link_libraries(matlibre_coeur PUBLIC ${FFTW3_LIB})
    target_include_directories(matlibre_coeur PUBLIC ${FFTW3_INC})
    target_compile_definitions(matlibre_coeur PUBLIC MATLIBRE_FFTW=1)
    list(APPEND MATLIBRE_TROUVEES "FFTW")
  else()
    list(APPEND MATLIBRE_INTERNES "FFTW")
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
    list(APPEND MATLIBRE_TROUVEES "SuiteSparse")
  else()
    list(APPEND MATLIBRE_INTERNES "SuiteSparse")
  endif()
endif()

if(MATLIBRE_AVEC_OPENCV)
  find_package(OpenCV QUIET COMPONENTS core imgproc imgcodecs)
  if(OpenCV_FOUND)
    target_link_libraries(matlibre_coeur PUBLIC ${OpenCV_LIBS})
    target_include_directories(matlibre_coeur PUBLIC ${OpenCV_INCLUDE_DIRS})
    target_compile_definitions(matlibre_coeur PUBLIC MATLIBRE_OPENCV=1)
    list(APPEND MATLIBRE_TROUVEES "OpenCV")
  else()
    list(APPEND MATLIBRE_INTERNES "OpenCV")
  endif()
endif()

# --- resume des accelerateurs -------------------------------------------------
if(MATLIBRE_TROUVEES)
  list(JOIN MATLIBRE_TROUVEES ", " MATLIBRE_TEXTE_TROUVEES)
  message(STATUS "MatLibre : acceleree par ${MATLIBRE_TEXTE_TROUVEES}")
endif()
if(MATLIBRE_INTERNES)
  list(JOIN MATLIBRE_INTERNES ", " MATLIBRE_TEXTE_INTERNES)
  message(STATUS
    "MatLibre : ${MATLIBRE_TEXTE_INTERNES} absente(s) — les algorithmes internes "
    "prennent le relais, rien ne manque a l'execution. Ces bibliotheques ne font "
    "qu'accelerer les gros calculs.")
endif()

# --- bureau natif (facultatif : le reste se compile et se teste sans Qt) ------
#
# « matlibre-bureau » est un seul exécutable : la fenêtre, l'interpréteur,
# l'éditeur et les figures dans le même processus. Pas de navigateur, pas de
# serveur, pas de second processus. Qt6 Widgets est la seule dépendance, et
# elle reste facultative : sans Qt, tout le reste se compile comme avant.
option(MATLIBRE_BUREAU "Construire le bureau natif si Qt6 est present" ON)
if(MATLIBRE_BUREAU)
  # Qt ne se trouve pas tout seul sous Windows : l'installateur le pose dans
  # C:/Qt/<version>/<compilateur>, qui n'est sur aucun chemin que CMake
  # regarde. On l'y cherche donc, en prenant la version la plus recente dont
  # le compilateur correspond au notre — melanger un Qt MSVC avec MinGW ne
  # produit rien de bon, et la panne serait obscure.
  #
  # Tout ce qu'indique l'utilisateur passe avant : -DCMAKE_PREFIX_PATH,
  # -DQt6_DIR, ou la variable d'environnement QTDIR.
  if(WIN32 AND NOT Qt6_DIR AND NOT DEFINED ENV{Qt6_DIR})
    set(MATLIBRE_QT_INDICES)
    if(DEFINED ENV{QTDIR})
      list(APPEND MATLIBRE_QT_INDICES "$ENV{QTDIR}")
    endif()
    if(MINGW)
      set(MATLIBRE_QT_ABI "mingw")
    else()
      set(MATLIBRE_QT_ABI "msvc")
    endif()
    file(GLOB MATLIBRE_QT_CANDIDATS
         "C:/Qt/6.*/${MATLIBRE_QT_ABI}*"
         "C:/Qt/Qt6*/6.*/${MATLIBRE_QT_ABI}*"
         "D:/Qt/6.*/${MATLIBRE_QT_ABI}*")
    # La plus recente d'abord : « 6.11.1 » doit passer avant « 6.9.0 », ce
    # qu'un tri alphabetique ne donne pas.
    list(SORT MATLIBRE_QT_CANDIDATS COMPARE NATURAL ORDER DESCENDING)
    list(APPEND MATLIBRE_QT_INDICES ${MATLIBRE_QT_CANDIDATS})
    foreach(candidat ${MATLIBRE_QT_INDICES})
      if(EXISTS "${candidat}/lib/cmake/Qt6/Qt6Config.cmake")
        list(APPEND CMAKE_PREFIX_PATH "${candidat}")
        message(STATUS "MatLibre : Qt trouve dans ${candidat}")
        break()
      endif()
    endforeach()
  endif()

  find_package(Qt6 COMPONENTS Widgets QUIET)
  if(Qt6_FOUND)
    set(CMAKE_AUTOMOC ON)
    # La fenetre est une bibliotheque a part : elle se verifie ainsi sans
    # lancer l'application, sur un ecran hors-champ, et c'est la que se
    # jouent les gestes qu'on ne voit pas a l'oeil — l'espace de travail qui
    # se met a jour, la figure qui se peint, le fil qui ne bloque pas.
    add_library(matlibre_bureau STATIC
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/FenetrePrincipale.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/Editeur.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/VueFigure.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/Moteur.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/ConsoleCommandes.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/Theme.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/Ruban.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/FenetreFigure.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/FenetreProfileur.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/FenetreAide.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/Icone.cpp)
    target_link_libraries(matlibre_bureau PUBLIC matlibre_coeur Qt6::Widgets)
    target_include_directories(matlibre_bureau PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau)

    add_executable(matlibre-bureau
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/Principal.cpp
      # L'icone du FICHIER sous Windows : celle de l'explorateur, avant
      # meme qu'on lance. Qt ne peut pas la poser, c'est une ressource de
      # l'executable. Ignoree ailleurs.
      $<$<BOOL:${WIN32}>:${CMAKE_CURRENT_SOURCE_DIR}/ressources/icone.rc>)
    target_link_libraries(matlibre-bureau PRIVATE matlibre_bureau)
    install(TARGETS matlibre-bureau RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

    if(MATLIBRE_TESTS AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tests/bureau/test_bureau.cpp")
      add_executable(matlibre_tests_bureau
                     ${CMAKE_CURRENT_SOURCE_DIR}/tests/bureau/test_bureau.cpp)
      target_link_libraries(matlibre_tests_bureau PRIVATE matlibre_bureau)
      add_test(NAME bureau COMMAND matlibre_tests_bureau)
      set_tests_properties(bureau PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
    endif()

    # Pas de console derriere la fenetre, sous Windows.
    #
    # C'est le sous-systeme inscrit dans l'executable qui decide : « console »
    # et Windows en ouvre une systematiquement, « GUI » et il n'en ouvre
    # aucune. WIN32_EXECUTABLE demande le bon sous-systeme, mais fait aussi
    # entrer Qt6::EntryPoint dans l'edition de liens ; cette bibliotheque-la
    # vient compilee de chez Qt et reclame __imp___argc, que le CRT d'un
    # autre MinGW n'exporte pas. Sous MinGW, « -mwindows » inscrit le meme
    # sous-systeme sans reclamer EntryPoint.
    if(WIN32)
      if(MINGW)
        target_link_options(matlibre-bureau PRIVATE -mwindows)
      else()
        set_target_properties(matlibre-bureau PROPERTIES WIN32_EXECUTABLE ON)
      endif()
    endif()
    # --- deploiement des DLL a cote de l'executable, sous Windows ---------
    #
    # Un executable qui existe doit se lancer. Sans les DLL de Qt dans son
    # dossier, celui-ci va les chercher dans le PATH, y trouve autre chose
    # ou rien, et meurt avant main() sur un 0xC0000135 sans message.
    if(WIN32)
      get_target_property(MATLIBRE_QMAKE Qt6::qmake IMPORTED_LOCATION)
      get_filename_component(MATLIBRE_QT_BIN "${MATLIBRE_QMAKE}" DIRECTORY)
      find_program(MATLIBRE_WINDEPLOYQT NAMES windeployqt windeployqt6
                   HINTS "${MATLIBRE_QT_BIN}")

      # Le runtime du compilateur doit voyager lui aussi. windeployqt sait le
      # faire, mais il depose celui DE QT — c'est-a-dire du MinGW avec lequel
      # Qt a ete bati. Quand on compile avec un autre MinGW (WinLibs, MSYS2),
      # ces DLL-la sont plus anciennes que le code qu'elles doivent servir ;
      # et comme le dossier de l'executable passe avant le PATH, ce sont
      # elles que le chargeur prend. L'application meurt alors avant main(),
      # sans fenetre et sans message, sur un 0xC0000139 (« point d'entree
      # introuvable »). On copie donc le runtime du compilateur qu'on utilise
      # vraiment, et on interdit a windeployqt de poser le sien.
      set(MATLIBRE_OPT_RUNTIME --compiler-runtime)
      set(MATLIBRE_DLL_RUNTIME)
      if(MINGW)
        set(MATLIBRE_OPT_RUNTIME --no-compiler-runtime)
        get_filename_component(MATLIBRE_DOSSIER_CXX "${CMAKE_CXX_COMPILER}" DIRECTORY)
        foreach(nom libstdc++-6 libgcc_s_seh-1 libgcc_s_dw2-1 libwinpthread-1)
          if(EXISTS "${MATLIBRE_DOSSIER_CXX}/${nom}.dll")
            list(APPEND MATLIBRE_DLL_RUNTIME "${MATLIBRE_DOSSIER_CXX}/${nom}.dll")
          endif()
        endforeach()
      endif()

      if(MATLIBRE_WINDEPLOYQT)
        # Les greffons vont dans un seul dossier, un qt.conf dit ou. Les DLL,
        # elles, RESTENT a cote de l'executable : le chargeur de Windows les
        # cherche la, et nulle part ailleurs.
        add_custom_command(TARGET matlibre-bureau POST_BUILD
          COMMAND "${MATLIBRE_WINDEPLOYQT}" --release --no-translations
                  --no-system-d3d-compiler --no-opengl-sw ${MATLIBRE_OPT_RUNTIME}
                  --plugindir "$<TARGET_FILE_DIR:matlibre-bureau>/greffons"
                  "$<TARGET_FILE:matlibre-bureau>"
          COMMENT "Depot des DLL de Qt a cote de matlibre-bureau")
        file(GENERATE
          OUTPUT "$<TARGET_FILE_DIR:matlibre-bureau>/qt.conf"
          CONTENT "[Paths]\nPlugins = greffons\n")
        if(MATLIBRE_DLL_RUNTIME)
          # Apres windeployqt, pour ecraser un runtime depose par une
          # construction anterieure : c'est le notre qui doit rester.
          add_custom_command(TARGET matlibre-bureau POST_BUILD
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different ${MATLIBRE_DLL_RUNTIME}
                    "$<TARGET_FILE_DIR:matlibre-bureau>"
            COMMENT "Depot du runtime du compilateur")
        endif()
      else()
        message(WARNING
          "MatLibre : windeployqt est introuvable. matlibre-bureau.exe sera "
          "construit mais ne demarrera pas tant que les DLL de Qt ne seront "
          "pas dans son dossier ou dans le PATH.")
      endif()
    endif()
    message(STATUS "MatLibre : Qt6 trouve, le bureau natif sera construit")
  else()
    if(WIN32)
      message(STATUS
        "MatLibre : Qt6 introuvable, pas de bureau natif. Si Qt est installe, "
        "indiquez-le : construire.ps1 -Qt C:/Qt/6.11.1/mingw_64, ou "
        "cmake -DCMAKE_PREFIX_PATH=C:/Qt/6.11.1/mingw_64. Attention : le "
        "dossier doit correspondre au compilateur (mingw_64 avec MinGW, "
        "msvc2022_64 avec Visual Studio).")
    else()
      message(STATUS "MatLibre : pas de Qt6, pas de bureau natif "
                     "(apt install qt6-base-dev)")
    endif()
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
  file(GLOB MATLIBRE_TESTS_CPP CONFIGURE_DEPENDS
       ${CMAKE_CURRENT_SOURCE_DIR}/tests/coeur/*.cpp)
  if(MATLIBRE_TESTS_CPP)
    add_executable(matlibre_tests ${MATLIBRE_TESTS_CPP})
    target_link_libraries(matlibre_tests PRIVATE matlibre_coeur)
    add_test(NAME unitaires COMMAND matlibre_tests)
  endif()
  file(GLOB MATLIBRE_TESTS_M CONFIGURE_DEPENDS
       ${CMAKE_CURRENT_SOURCE_DIR}/tests/scripts/test_*.m)
  foreach(fichier ${MATLIBRE_TESTS_M})
    get_filename_component(nom ${fichier} NAME_WE)
    add_test(NAME langage_${nom}
             COMMAND matlibre --path ${CMAKE_CURRENT_SOURCE_DIR}/toolbox
                     --path ${CMAKE_CURRENT_SOURCE_DIR}/tests/scripts ${fichier})
    set_tests_properties(langage_${nom} PROPERTIES
      ENVIRONMENT "MATLIBRE_TOOLBOX=${CMAKE_CURRENT_SOURCE_DIR}/toolbox")
  endforeach()
endif()
