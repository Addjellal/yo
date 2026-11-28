# MatLibre — clone libre du langage MATLAB.
#
# Aucune dépendance obligatoire : un compilateur C++17 suffit, Qt6 pour
# le bureau s'il est la, et LAPACK et BLAS s'ils sont la (MATLIBRE_LAPACK,
# plus bas). L'algebre lineaire, la FFT, les matrices creuses et les images
# sont ecrites dans src/, et le restent : LAPACK accelere le produit, la
# resolution, la SVD et les valeurs propres ; sans lui, le meme calcul se
# fait par le code du depot. (Les anciennes options MATLIBRE_AVEC_LAPACK,
# _FFTW, _SUITESPARSE et _OPENCV liaient ces bibliotheques sans qu'aucune
# ligne du code ne s'en serve ; elles ont ete retirees.)
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

option(MATLIBRE_TESTS       "Construire les tests"               ON)

if(MSVC)
  add_compile_options(/W4 /utf-8 /bigobj)
else()
  # -ffp-contract=off : pas de fusion de a*b+c en une seule operation.
  # clang la fait par defaut sur ARM64 (macOS) : -70:0.1:90 finissait a
  # 90.00000000000001, et -2e-3:1e-7:2e-3 ne passait plus par zero. Les
  # memes chiffres sur toutes les machines valent mieux que l'ulp gagne.
  add_compile_options(-Wall -Wextra -Wno-unused-parameter -ffp-contract=off)
endif()

# Assainisseurs et couverture, pour chercher ce que les tests ne voient
# pas (gcc et clang) :
#   -DMATLIBRE_ASSAINIR=ON       lectures hors bornes, fuites, comportements
#                                indefinis (ASan et UBSan)
#   -DMATLIBRE_ASSAINIR=thread   courses entre fils, pour parfor (TSan)
#   -DMATLIBRE_COUVERTURE=ON     instrumentation gcov : ce que les tests
#                                exercent, ligne par ligne
# Un arbre a part pour chacun : build-asan, build-tsan, build-couverture.
set(MATLIBRE_ASSAINIR OFF CACHE STRING "ON (address,undefined), thread, ou OFF")
option(MATLIBRE_COUVERTURE "Instrumenter pour la couverture (gcov)" OFF)
if(MATLIBRE_ASSAINIR AND NOT MSVC)
  if(MATLIBRE_ASSAINIR STREQUAL "thread")
    set(MATLIBRE_FSANITIZE thread)
  else()
    set(MATLIBRE_FSANITIZE address,undefined)
  endif()
  add_compile_options(-fsanitize=${MATLIBRE_FSANITIZE} -fno-omit-frame-pointer -g)
  add_link_options(-fsanitize=${MATLIBRE_FSANITIZE})
  message(STATUS "MatLibre : assaini (-fsanitize=${MATLIBRE_FSANITIZE})")
endif()
if(MATLIBRE_COUVERTURE AND NOT MSVC)
  add_compile_options(--coverage -g)
  add_link_options(--coverage)
  message(STATUS "MatLibre : instrumente pour la couverture (gcov)")
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

find_package(Threads QUIET)
if(Threads_FOUND)
  target_link_libraries(matlibre_coeur PUBLIC Threads::Threads)
endif()

# --- LAPACK et BLAS, facultatifs -------------------------------------------
#   -DMATLIBRE_LAPACK=AUTO   (par defaut) employes s'ils sont trouves
#   -DMATLIBRE_LAPACK=ON     exiges : la configuration echoue sans eux
#   -DMATLIBRE_LAPACK=OFF    jamais : le code du depot sert seul
# Trouves, ils font le produit matriciel, A\b carre, svd et eig — les
# routines dont MATLAB se sert ; eig d'une matrice 300 x 300 passe d'un
# tiers de seconde a quelques millisecondes. OpenBLAS (libopenblas-dev),
# la reference (liblapack-dev), Accelerate sous macOS conviennent.
set(MATLIBRE_LAPACK AUTO CACHE STRING "LAPACK et BLAS : AUTO, ON ou OFF")
set_property(CACHE MATLIBRE_LAPACK PROPERTY STRINGS AUTO ON OFF)
set(MATLIBRE_LAPACK_LIE OFF)
if(NOT MATLIBRE_LAPACK STREQUAL "OFF")
  if(MATLIBRE_LAPACK STREQUAL "ON")
    find_package(LAPACK REQUIRED)
  else()
    find_package(LAPACK QUIET)
  endif()
  if(LAPACK_FOUND)
    target_link_libraries(matlibre_coeur PUBLIC ${LAPACK_LIBRARIES} ${LAPACK_LINKER_FLAGS})
    target_compile_definitions(matlibre_coeur PRIVATE MATLIBRE_AVEC_LAPACK)
    set(MATLIBRE_LAPACK_LIE ON)
    message(STATUS "MatLibre : LAPACK et BLAS employes (${LAPACK_LIBRARIES})")
  else()
    message(STATUS "MatLibre : pas de LAPACK, l'algebre lineaire du depot sert seule "
                   "(apt install libopenblas-dev pour l'accelerer)")
  endif()
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
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/FenetreSimulink.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/ToileSimulink.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/DialogueBloc.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/DialogueConfiguration.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/FenetreAide.cpp
      ${CMAKE_CURRENT_SOURCE_DIR}/src/bureau/Recherche.cpp
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
      # La toolbox est donnee comme aux tests en langage : sans elle, un
      # arbre de construction range hors du depot (build-asan ailleurs)
      # ne la trouvait pas, et le test echouait pour une autre raison.
      set_tests_properties(bureau PROPERTIES ENVIRONMENT
        "QT_QPA_PLATFORM=offscreen;MATLIBRE_TOOLBOX=${CMAKE_CURRENT_SOURCE_DIR}/toolbox")
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
  # Lie a LAPACK (ou a Qt), le binaire depend de bibliotheques que la
  # liste ci-dessus ne nomme pas : dpkg-shlibdeps les lit dans le binaire
  # lui-meme, et le paquet les declare.
  find_program(MATLIBRE_DPKG_SHLIBDEPS dpkg-shlibdeps)
  if((MATLIBRE_LAPACK_LIE OR TARGET matlibre-bureau) AND MATLIBRE_DPKG_SHLIBDEPS)
    set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
  endif()
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
  # La ligne de commande : les options se lisent dans n'importe quel ordre
  # jusqu'au script, « -q » n'est pas pris pour un nom de fichier, et une
  # option inconnue est refusee (code 2) au lieu d'etre ouverte comme un
  # script.
  add_test(NAME console_options
           COMMAND matlibre -q --path ${CMAKE_CURRENT_SOURCE_DIR}/toolbox -e "disp(6*7)")
  set_tests_properties(console_options PROPERTIES PASS_REGULAR_EXPRESSION "42")
  add_test(NAME console_option_inconnue COMMAND matlibre --option-inconnue)
  set_tests_properties(console_option_inconnue PROPERTIES WILL_FAIL TRUE)
  if(UNIX)
    add_test(NAME console_silencieuse
             COMMAND sh -c "echo 'disp(6*7)' | '$<TARGET_FILE:matlibre>' -q")
    set_tests_properties(console_silencieuse PROPERTIES
      PASS_REGULAR_EXPRESSION "42" FAIL_REGULAR_EXPRESSION "MatLibre")
    # Une entree qui n'est pas un terminal n'appelle ni banniere ni invite,
    # meme sans -q : comme « matlab -batch », la sortie ne porte que ce que
    # les commandes ecrivent.
    add_test(NAME console_tube
             COMMAND sh -c "echo 'disp(6*7)' | '$<TARGET_FILE:matlibre>'")
    set_tests_properties(console_tube PROPERTIES
      PASS_REGULAR_EXPRESSION "42" FAIL_REGULAR_EXPRESSION "MatLibre|>>")
    # L'edition de ligne, sous un vrai terminal (un pseudo-terminal) :
    # fleches, historique relu et ecrit, Tab, Ctrl-C, Ctrl-D.
    add_executable(matlibre_tests_terminal
                   ${CMAKE_CURRENT_SOURCE_DIR}/tests/console/test_terminal.cpp)
    add_test(NAME console_terminal
             COMMAND matlibre_tests_terminal $<TARGET_FILE:matlibre>
                     ${CMAKE_CURRENT_SOURCE_DIR}/toolbox)
  endif()
  # Les scripts qui passent la minute portent l'etiquette « lent » :
  # « ctest -LE lent » les laisse de cote — c'est la passe de chaque
  # poussee dans l'integration continue, et celle qu'on lance pendant le
  # travail, trois minutes sur quatre coeurs —, la batterie entiere les
  # prend. Durees du 27 novembre 2026, « ctest -j3 » sur quatre coeurs :
  # test_simulink 25 min, test_aide 18, test_exemples 4 min 40 s,
  # test_ondelettes et test_domaines 2 min 25 s, test_robuste 1 min 25 s ;
  # le plus long des autres, test_couverture, 56 s.
  set(MATLIBRE_TESTS_LENTS
      test_simulink test_aide test_exemples test_ondelettes test_domaines test_robuste)
  file(GLOB MATLIBRE_TESTS_M CONFIGURE_DEPENDS
       ${CMAKE_CURRENT_SOURCE_DIR}/tests/scripts/test_*.m)
  foreach(fichier ${MATLIBRE_TESTS_M})
    get_filename_component(nom ${fichier} NAME_WE)
    add_test(NAME langage_${nom}
             COMMAND matlibre --path ${CMAKE_CURRENT_SOURCE_DIR}/toolbox
                     --path ${CMAKE_CURRENT_SOURCE_DIR}/tests/scripts ${fichier})
    set_tests_properties(langage_${nom} PROPERTIES
      ENVIRONMENT "MATLIBRE_TOOLBOX=${CMAKE_CURRENT_SOURCE_DIR}/toolbox")
    if(nom IN_LIST MATLIBRE_TESTS_LENTS)
      set_tests_properties(langage_${nom} PROPERTIES LABELS lent)
    endif()
  endforeach()
  # Deux .m de meme nom, ou un .m qui masque une fonction native : le
  # controle de « make test », que CTest — et donc l'integration
  # continue — ne faisait pas.
  add_test(NAME outils_doublons
           COMMAND matlibre --path ${CMAKE_CURRENT_SOURCE_DIR}/toolbox
                   ${CMAKE_CURRENT_SOURCE_DIR}/outils/verifierDoublons.m)
  set_tests_properties(outils_doublons PROPERTIES
    ENVIRONMENT "MATLIBRE_TOOLBOX=${CMAKE_CURRENT_SOURCE_DIR}/toolbox")
  # Les valeurs qu'annoncent les fiches d'aide en commentaire de leurs
  # exemples (« pi % 3.1416 ») : test_aide execute les exemples sans lire
  # ces commentaires, verifierValeurs les compare a ce que rend la ligne,
  # et echoue au premier ecart.
  add_test(NAME aide_valeurs
           COMMAND matlibre --path ${CMAKE_CURRENT_SOURCE_DIR}/toolbox
                   ${CMAKE_CURRENT_SOURCE_DIR}/outils/verifierValeurs.m)
  set_tests_properties(aide_valeurs PROPERTIES
    ENVIRONMENT "MATLIBRE_TOOLBOX=${CMAKE_CURRENT_SOURCE_DIR}/toolbox")
endif()
