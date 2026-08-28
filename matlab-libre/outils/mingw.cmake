# mingw.cmake — chaîne d'outils pour compiler MatLibre pour Windows depuis
# une machine Linux, avec le cross-compilateur MinGW-w64.
#
#   cmake -S . -B build-windows -DCMAKE_TOOLCHAIN_FILE=outils/mingw.cmake
#   cmake --build build-windows -j
#
# Il ne s'agit pas de produire la version officielle Windows, mais de
# vérifier que le code compile et s'édite ailleurs que sous libstdc++ :
# les en-têtes tirés par transitivité, les fonctions POSIX employées sans
# garde et les bibliothèques système oubliées se voient tout de suite.
#
# Sur Debian ou Ubuntu : apt install g++-mingw-w64-x86-64
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_C_COMPILER   x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)
set(CMAKE_RC_COMPILER  x86_64-w64-mingw32-windres)
set(CMAKE_FIND_ROOT_PATH /usr/x86_64-w64-mingw32)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
