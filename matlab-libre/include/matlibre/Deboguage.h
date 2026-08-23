// Deboguage.h — profileur et débogueur.
//
// Les deux s'appuient sur deux crochets posés dans l'interpréteur : l'un
// avant chaque instruction, l'autre autour de chaque appel. Quand ils sont
// éteints, le coût est un test de booléen ; l'interpréteur ne ralentit pas.
#pragma once

#include <chrono>
#include <map>
#include <set>
#include <string>
#include <vector>

namespace matlibre {

class Interpreteur;

// Une entrée du profil : ce que MATLAB affiche dans profile viewer.
struct EntreeProfil {
    std::string nom;
    long long appels = 0;
    double tempsTotal = 0.0;    // secondes, appels imbriqués compris
    double tempsPropre = 0.0;   // secondes, hors appels imbriqués
    std::map<int, long long> lignes;  // ligne -> nombre de passages
};

// État du profileur, tenu par l'interpréteur.
struct Profil {
    bool actif = false;
    bool detailLignes = true;
    std::map<std::string, EntreeProfil> entrees;
    std::vector<std::pair<std::string, std::chrono::steady_clock::time_point>> pile;
    std::vector<double> tempsEnfants;
    double debut = 0.0;

    void demarrer();
    void arreter();
    void effacer();
    void entrerAppel(const std::string& nom);
    void sortirAppel(const std::string& nom);
    void compterLigne(const std::string& fichier, int ligne);
    std::vector<EntreeProfil> classees() const;
};

// Point d'arrêt : un fichier et une ligne, éventuellement conditionnel.
struct PointArret {
    std::string fichier;   // nom court, sans dossier ni extension
    int ligne = 0;
    std::string condition; // expression MATLAB, vide si inconditionnel
    bool surErreur = false;
    bool surAvertissement = false;
};

// Ce que le débogueur doit faire au prochain arrêt.
enum class ActionDebogueur { Continuer, PasAPas, EntrerDedans, SortirDe, Quitter };

struct Debogueur {
    bool actif = false;                 // au moins un point d'arrêt posé
    bool arretSurErreur = false;
    std::vector<PointArret> points;
    ActionDebogueur action = ActionDebogueur::Continuer;
    bool enPause = false;
    int profondeurPause = 0;
    std::string fichierCourant;
    int ligneCourante = 0;

    bool doitArreter(const std::string& fichier, int ligne, int profondeur) const;
    void poser(const std::string& fichier, int ligne, const std::string& condition);
    void retirer(const std::string& fichier, int ligne);
    void toutRetirer();
};

}  // namespace matlibre
