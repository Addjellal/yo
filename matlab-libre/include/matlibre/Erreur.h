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

// Un cadre de la pile d'exécution, tel que le message d'erreur le nomme :
// « Error in monScript (line 12) », suivi de la ligne elle-même.
struct CadreErreur {
    std::string nom;       // fonction ou script ; vide pour la console
    std::string fichier;   // chemin du fichier, vide s'il n'y en a pas
    int ligne = 0;
};

struct ErreurMatlab : std::runtime_error {
    std::string identifiant;
    std::string message;
    // Du plus profond au plus haut : chaque cadre traversé s'y inscrit en
    // sortant. Vide quand l'erreur naît hors de tout fichier.
    std::vector<CadreErreur> pile;
    // Nom de la fonction native qui a levé l'erreur, s'il y en a une :
    // c'est ce que MATLAB nomme dans « Error using double ».
    std::string fonctionNative;
    ErreurMatlab(std::string id, std::string msg)
        : std::runtime_error(msg), identifiant(std::move(id)), message(std::move(msg)) {}
};

// Le rapport que MATLAB imprime : la fonction qui a échoué, le message,
// puis un cadre par appelant avec la ligne de code fautive. Sans pile, il
// se réduit à « Error: <message> », ce qu'on imprimait jusqu'ici.
std::string rapportErreur(const ErreurMatlab& e);

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
