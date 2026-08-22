// Erreur.h — erreurs du langage et ruptures de flux.
//
// MATLAB identifie chaque erreur par une chaîne « composant:mnémonique ».
// On reprend les identifiants publics documentés (MATLAB:undefinedFunction,
// MATLAB:nonExistentField…) pour que les « try/catch » écrits pour MATLAB
// attrapent la même chose ici.
#pragma once

#include <stdexcept>
#include <string>
#include <vector>

namespace matlibre {

struct ErreurMatlab : std::runtime_error {
    std::string identifiant;
    std::string message;
    std::vector<std::string> pile;
    ErreurMatlab(std::string id, std::string msg)
        : std::runtime_error(msg), identifiant(std::move(id)), message(std::move(msg)) {}
};

[[noreturn]] void erreur(const std::string& identifiant, const std::string& message);
[[noreturn]] void erreurSimple(const std::string& message);

// Formatage à la printf pour construire les messages.
std::string formater(const char* format, ...);

// Ruptures de flux : break, continue, return.
struct RuptureBoucle {};
struct ContinuerBoucle {};
struct RetourFonction {};
struct DemandeSortie { int code = 0; };

}  // namespace matlibre
