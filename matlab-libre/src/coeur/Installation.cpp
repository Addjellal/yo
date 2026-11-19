// Installation.cpp — assemble la bibliothèque native au démarrage, et
// trouve les toolboxes.
#include "matlibre/Installation.h"

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <set>
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

// Les dossiers d'un niveau, triés. Avec « ordinaires », seuls ceux que
// GENPATH garde : il écarte un nom qui commence par un point, « @classe »,
// « +paquet » et « private » — l'index explore « @ » et « + » à part.
// Les deux listes doivent s'accorder : installToolbox ajoute une toolbox
// par « addpath(genpath(d)) », et uninstallToolbox la retire de même.
static std::vector<fs::path> sousDossiers(const fs::path& dossier, bool ordinaires) {
    std::error_code ec;
    std::vector<fs::path> trouves;
    for (const auto& e : fs::directory_iterator(dossier, ec)) {
        std::error_code e2;
        if (!e.is_directory(e2)) continue;
        const std::string nom = e.path().filename().string();
        if (ordinaires && (nom.empty() || nom[0] == '.' || nom[0] == '@' || nom[0] == '+' ||
                           nom == "private"))
            continue;
        trouves.push_back(e.path());
    }
    std::sort(trouves.begin(), trouves.end());
    return trouves;
}

// Un dossier puis ses sous-dossiers ordinaires, en profondeur, dans l'ordre
// de GENPATH. Un lien symbolique qui remonterait vers un parent ferait
// tourner la descente sans fin : un dossier déjà vu n'est pas revisité.
static void avecSousDossiers(const fs::path& dossier, std::set<fs::path>& vus,
                             std::vector<std::string>& dossiers) {
    std::error_code ec;
    if (!vus.insert(fs::weakly_canonical(dossier, ec)).second) return;
    dossiers.push_back(dossier.string());
    for (const auto& sous : sousDossiers(dossier, true)) avecSousDossiers(sous, vus, dossiers);
}

void chargerToolboxes(Interpreteur& it, const std::string& racine) {
    if (racine.empty()) return;
    it.definirRacineToolbox(racine);
    // La racine devant, puis chaque module dans l'ordre alphabétique, suivi
    // de ses sous-dossiers : une toolbox installée qui range ses fonctions
    // dans « outils/ » les retrouve au démarrage suivant.
    std::vector<std::string> dossiers = {racine};
    std::set<fs::path> vus;
    for (const auto& module : sousDossiers(racine, false)) avecSousDossiers(module, vus, dossiers);
    it.ajouterChemins(dossiers, true);
}

}  // namespace matlibre
