// Console.cpp — bascule la console de Windows en UTF-8, et la remet.
#include "matlibre/Console.h"

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

namespace matlibre {

ConsoleUtf8::ConsoleUtf8() {
#ifdef _WIN32
    // GetConsoleOutputCP rend 0 quand il n'y a pas de console — un pipe,
    // un service. On ne touche alors à rien : les octets passent tels
    // quels, ce qui est exactement ce qu'il faut pour une redirection.
    sortieInitiale = GetConsoleOutputCP();
    entreeInitiale = GetConsoleCP();
    if (sortieInitiale != 0 && sortieInitiale != CP_UTF8) SetConsoleOutputCP(CP_UTF8);
    if (entreeInitiale != 0 && entreeInitiale != CP_UTF8) SetConsoleCP(CP_UTF8);
#endif
}

ConsoleUtf8::~ConsoleUtf8() {
#ifdef _WIN32
    if (sortieInitiale != 0 && sortieInitiale != CP_UTF8) SetConsoleOutputCP(sortieInitiale);
    if (entreeInitiale != 0 && entreeInitiale != CP_UTF8) SetConsoleCP(entreeInitiale);
#endif
}

}  // namespace matlibre
