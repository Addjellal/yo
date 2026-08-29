// Erreur.h — erreurs du langage et ruptures de flux.
//
// MATLAB identifie chaque erreur par une chaîne « composant:mnémonique ».
// On reprend les identifiants publics documentés (MATLAB:undefinedFunction,
// MATLAB:nonExistentField…) pour que les « try/catch » écrits pour MATLAB
// attrapent la même chose ici.
#pragma once

#include <atomic>
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

// --- interruption (Ctrl-C) --------------------------------------------
//
// Un calcul long doit pouvoir être coupé : sans cela, afficher un vecteur
// de dix millions d'éléments fige la fenêtre pour de bon. Le fil qui
// demande l'arrêt lève un drapeau ; l'interprète le lit aux points de
// contrôle — avant chaque instruction, et pendant l'affichage d'un grand
// tableau. Le drapeau est propre au fil : le bureau, la console et chaque
// travailleur du pool parallèle ont le leur.
//
// L'interruption n'est PAS une ErreurMatlab : « try/catch » ne l'attrape
// donc pas, exactement comme sous MATLAB.
struct InterruptionUtilisateur {};

void poserDrapeauInterruption(std::atomic<bool>* drapeau);
std::atomic<bool>* drapeauInterruption();
void demanderInterruption();

// Lève InterruptionUtilisateur si l'arrêt a été demandé, et rabaisse le
// drapeau : une interruption ne vaut que pour le calcul en cours.
void verifierInterruption();

}  // namespace matlibre
