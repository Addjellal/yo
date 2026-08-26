// Deboguage.cpp — profileur et points d'arrêt.
#include "matlibre/Deboguage.h"

#include <algorithm>
#include <filesystem>

namespace matlibre {
namespace {

std::string nomCourt(const std::string& chemin) {
    if (chemin.empty()) return chemin;
    std::filesystem::path p(chemin);
    return p.stem().string();
}

}  // namespace

void Profil::demarrer() {
    actif = true;
    pile.clear();
    tempsEnfants.clear();
    debut = 0.0;
}

void Profil::arreter() { actif = false; }

void Profil::effacer() {
    entrees.clear();
    pile.clear();
    tempsEnfants.clear();
}

void Profil::entrerAppel(const std::string& nom) {
    if (!actif) return;
    pile.emplace_back(nom, std::chrono::steady_clock::now());
    tempsEnfants.push_back(0.0);
}

void Profil::sortirAppel(const std::string& nom) {
    if (!actif || pile.empty()) return;
    auto fin = std::chrono::steady_clock::now();
    double total = std::chrono::duration<double>(fin - pile.back().second).count();
    double enfants = tempsEnfants.back();
    pile.pop_back();
    tempsEnfants.pop_back();
    if (!tempsEnfants.empty()) tempsEnfants.back() += total;
    EntreeProfil& e = entrees[nom];
    e.nom = nom;
    e.appels += 1;
    e.tempsTotal += total;
    e.tempsPropre += total - enfants;
}

void Profil::compterLigne(const std::string& fichier, int ligne) {
    if (!actif || !detailLignes || ligne <= 0) return;
    std::string nom = nomCourt(fichier);
    if (nom.empty()) return;
    EntreeProfil& e = entrees[nom];
    if (e.nom.empty()) e.nom = nom;
    e.lignes[ligne] += 1;
}

std::vector<EntreeProfil> Profil::classees() const {
    std::vector<EntreeProfil> v;
    v.reserve(entrees.size());
    for (const auto& kv : entrees) v.push_back(kv.second);
    std::sort(v.begin(), v.end(), [](const EntreeProfil& a, const EntreeProfil& b) {
        if (a.tempsPropre != b.tempsPropre) return a.tempsPropre > b.tempsPropre;
        return a.nom < b.nom;
    });
    return v;
}

bool Debogueur::doitArreter(const std::string& fichier, int ligne, int profondeur) const {
    if (enPause) return false;
    if (action == ActionDebogueur::PasAPas && profondeur <= profondeurPause) return true;
    if (action == ActionDebogueur::EntrerDedans) return true;
    if (action == ActionDebogueur::SortirDe && profondeur < profondeurPause) return true;
    if (points.empty()) return false;
    std::string nom = nomCourt(fichier);
    for (const auto& p : points) {
        if (p.surErreur || p.surAvertissement) continue;
        if (p.ligne == ligne && (p.fichier == nom || p.fichier == fichier)) return true;
    }
    return false;
}

void Debogueur::poser(const std::string& fichier, int ligne, const std::string& condition) {
    std::string nom = nomCourt(fichier);
    for (auto& p : points)
        if (p.fichier == nom && p.ligne == ligne) {
            p.condition = condition;
            return;
        }
    PointArret p;
    p.fichier = nom;
    p.ligne = ligne;
    p.condition = condition;
    points.push_back(p);
    actif = true;
}

void Debogueur::retirer(const std::string& fichier, int ligne) {
    std::string nom = nomCourt(fichier);
    points.erase(std::remove_if(points.begin(), points.end(),
                                [&](const PointArret& p) {
                                    return p.fichier == nom &&
                                           (ligne == 0 || p.ligne == ligne);
                                }),
                 points.end());
    actif = !points.empty();
}

void Debogueur::toutRetirer() {
    points.clear();
    actif = false;
}

}  // namespace matlibre
