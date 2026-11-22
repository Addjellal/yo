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

void chargerToolboxes(Interpreteur& it, const std::string& racine) {
    if (racine.empty()) return;
    it.definirRacineToolbox(racine);
    std::error_code ec;
    std::vector<std::string> dossiers;
    for (const auto& e : fs::directory_iterator(racine, ec)) {
        if (!e.is_directory()) continue;
        dossiers.push_back(e.path().string());
        // « homonymes » : les fonctions dont le nom ne diffère d'une autre
        // du module que par la casse — addmf et addMF. Sous Windows et
        // macOS, deux tels fichiers ne peuvent pas partager un dossier :
        // l'un écraserait l'autre. MATLAB range de même ses boîtes sur
        // plusieurs dossiers du chemin.
        fs::path homonymes = e.path() / "homonymes";
        if (fs::is_directory(homonymes, ec)) dossiers.push_back(homonymes.string());
    }
    std::sort(dossiers.begin(), dossiers.end());
    // La racine devant, puis les modules dans l'ordre alphabétique, en une
    // seule fois : ajoutés un à un, chacun réindexait tout le chemin — une
    // soixantaine de dossiers, quelque mille huit cents parcours, la moitié
    // du démarrage de la console et de chaque travailleur d'un parfor.
    dossiers.insert(dossiers.begin(), racine);
    it.ajouterChemins(dossiers, true);
}

}  // namespace matlibre
