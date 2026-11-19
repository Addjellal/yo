// Installation.cpp — assemble la bibliothèque native au démarrage, et
// trouve les toolboxes.
#include "matlibre/Installation.h"

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <vector>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Interpreteur.h"

namespace fs = std::filesystem;

namespace matlibre {

void Interpreteur::installerBibliotheque() {
    enregistrerBase(*this);
    enregistrerMath(*this);
    enregistrerTableaux(*this);
    enregistrerTexte(*this);
    enregistrerStructures(*this);
    enregistrerFonctionnel(*this);
    enregistrerEntreeSortie(*this);
    enregistrerMat(*this);
    enregistrerAlgebre(*this);
    enregistrerStatistiques(*this);
    enregistrerSignal(*this);
    enregistrerPolynomes(*this);
    enregistrerOptimisation(*this);
    enregistrerTemps(*this);
    enregistrerSysteme(*this);
    enregistrerGraphique(*this);
    // Apres le graphique : « set » et « get » y remplacent les coquilles vides.
    enregistrerPoigneesGraphiques(*this);
    enregistrerTests(*this);
    enregistrerCartes(*this);
    enregistrerCreuses(*this);
    enregistrerParallele(*this);
    enregistrerGenerationC(*this);
    enregistrerDeboguage(*this);
    enregistrerInterface(*this);
    enregistrerArchives(*this);
}

std::string racineToolboxes(const std::string& executable) {
    std::error_code ec;
    fs::path exe = fs::weakly_canonical(fs::path(executable), ec);
    fs::path dossier = exe.parent_path();
    // Installé : <préfixe>/bin/matlibre, toolboxes dans
    // <préfixe>/share/matlibre. Arbre de construction : build/bin/matlibre,
    // toolboxes deux crans plus haut — trois avec Visual Studio, qui
    // ajoute un dossier par configuration.
    for (fs::path p : {dossier / ".." / "share" / "matlibre",
                       dossier / ".." / "toolbox",
                       dossier / "toolbox",
                       dossier / ".." / ".." / "toolbox",
                       dossier / ".." / ".." / ".." / "toolbox"}) {
        std::error_code e2;
        if (fs::is_directory(p, e2)) return fs::weakly_canonical(p, e2).string();
    }
    const char* env = std::getenv("MATLIBRE_TOOLBOX");
    if (env) return env;
    return std::string();
}

// Les sous-dossiers ordinaires d'un module, en profondeur et dans l'ordre
// alphabétique : ceux que garderait « genpath ». Les noms qui commencent
// par un point, « @ » ou « + », et « private », sont réservés — l'index
// explore lui-même les classes et les paquets, et une fonction privée
// n'a pas à devenir publique.
static void sousDossiersOrdinaires(const fs::path& dossier, std::vector<std::string>& liste) {
    std::error_code ec;
    std::vector<std::string> enfants;
    for (const auto& e : fs::directory_iterator(dossier, ec)) {
        std::error_code e2;
        if (!e.is_directory(e2)) continue;
        const std::string nom = e.path().filename().string();
        if (nom.empty() || nom[0] == '.' || nom[0] == '@' || nom[0] == '+' || nom == "private")
            continue;
        enfants.push_back(e.path().string());
    }
    std::sort(enfants.begin(), enfants.end());
    for (const auto& enfant : enfants) {
        liste.push_back(enfant);
        sousDossiersOrdinaires(enfant, liste);
    }
}

void chargerToolboxes(Interpreteur& it, const std::string& racine) {
    if (racine.empty()) return;
    it.definirRacineToolbox(racine);
    std::error_code ec;
    std::vector<std::string> modules;
    for (const auto& e : fs::directory_iterator(racine, ec))
        if (e.is_directory()) modules.push_back(e.path().string());
    std::sort(modules.begin(), modules.end());
    // Un module entraîne ses sous-dossiers : c'est ainsi que deux fonctions
    // dont le nom ne diffère que par la casse — addmf et addMF — tiennent
    // dans la même toolbox. Windows et macOS ne savent pas les ranger dans
    // un même dossier ; MATLAB les sépare de la même façon.
    std::vector<std::string> dossiers;
    for (const auto& module : modules) {
        dossiers.push_back(module);
        sousDossiersOrdinaires(module, dossiers);
    }
    // Ajoutés en tête, du dernier au premier : l'ordre final est
    // alphabétique, chaque module devant ses sous-dossiers, et la racine
    // passe devant.
    for (auto rit = dossiers.rbegin(); rit != dossiers.rend(); ++rit)
        it.ajouterChemin(*rit, true);
    it.ajouterChemin(racine, true);
}

}  // namespace matlibre
