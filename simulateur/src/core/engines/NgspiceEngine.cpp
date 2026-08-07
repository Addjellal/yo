#include "core/engines/NgspiceEngine.h"

#include <algorithm>
#include <cstring>
#include <sstream>

#include "core/Device.h"

#ifdef AVEC_NGSPICE
#include <stdbool.h>
#include <ngspice/sharedspice.h>
#endif

namespace coeur {

namespace {

std::vector<std::string>* g_erreurs = nullptr;

#ifdef AVEC_NGSPICE
int cb_sortie(char* message, int, void*) {
    if (message && g_erreurs) {
        std::string texte(message);
        if (texte.find("Error") != std::string::npos ||
            texte.find("error") != std::string::npos ||
            texte.find("Warning") != std::string::npos)
            g_erreurs->push_back(texte);
    }
    return 0;
}
int cb_statut(char*, int, void*) { return 0; }
int cb_sortie_forcee(int, NG_BOOL, NG_BOOL, int, void*) { return 0; }
int cb_donnees(pvecvaluesall, int, int, void*) { return 0; }
int cb_init(pvecinfoall, int, void*) { return 0; }
int cb_thread(NG_BOOL, int, void*) { return 0; }

bool g_initialise = false;
#endif

std::string minuscules(std::string texte) {
    std::transform(texte.begin(), texte.end(), texte.begin(),
                   [](unsigned char c) { return std::tolower(c); });
    return texte;
}

}  // namespace

NgspiceEngine::NgspiceEngine() {
#ifdef AVEC_NGSPICE
    disponible_ = true;
#else
    disponible_ = false;
#endif
}

NgspiceEngine::~NgspiceEngine() = default;

bool NgspiceEngine::compile_avec_ngspice() {
#ifdef AVEC_NGSPICE
    return true;
#else
    return false;
#endif
}

std::string NgspiceEngine::construire(
    const Netlist& netlist, const std::vector<BrocheElectrique>& broches) {
    lignes_.clear();
    lignes_.push_back("circuit simulateur embarque");

    // Alimentations de la carte
    lignes_.push_back("Valim " + std::string(Netlist::kAlim) + " 0 DC 5");
    lignes_.push_back("Valim33 3V3 0 DC 3.3");

    // Broches du microcontrôleur : source de Thévenin ou pull-up
    for (const auto& broche : broches) {
        const std::string interne = broche.noeud + "_src";
        switch (broche.mode) {
            case BrocheElectrique::Mode::Sortie: {
                std::ostringstream f;
                f << "V" << broche.noeud << " " << interne << " 0 DC "
                  << broche.tension;
                lignes_.push_back(f.str());
                std::ostringstream r;
                r << "R" << broche.noeud << " " << interne << " " << broche.noeud
                  << " " << broche.resistance;
                lignes_.push_back(r.str());
                break;
            }
            case BrocheElectrique::Mode::PullUp: {
                // pull-up interne de l'AVR : 20 kΩ à 50 kΩ selon la puce
                std::ostringstream r;
                r << "R" << broche.noeud << " " << Netlist::kAlim << " "
                  << broche.noeud << " "
                  << (broche.resistance > 1.0 ? broche.resistance : 20000.0);
                lignes_.push_back(r.str());
                break;
            }
            case BrocheElectrique::Mode::Entree:
                // entrée haute impédance : résistance de fuite, sinon le nœud
                // serait flottant et la matrice singulière
                lignes_.push_back("R" + broche.noeud + "_fuite " + broche.noeud +
                                  " 0 100e6");
                break;
        }
    }

    // Composants
    std::vector<std::string> directives;
    for (const auto& instance : netlist.instances()) {
        const Modele* modele = Catalogue::instance().modele(instance.type);
        if (!modele || !modele->vers_spice) continue;

        auto noeud_de = [&instance](const std::string& nom) -> std::string {
            const Borne* borne = instance.borne(nom);
            if (!borne || borne->noeud.empty())
                return instance.reference + "_nc_" + nom;  // borne en l'air
            if (borne->noeud == Netlist::kMasse) return "0";
            return borne->noeud;
        };

        for (const auto& ligne : modele->vers_spice(instance, noeud_de))
            lignes_.push_back(ligne);
        for (const auto& directive : modele->directives)
            if (std::find(directives.begin(), directives.end(), directive)
                == directives.end())
                directives.push_back(directive);

        // les bornes non connectées ont besoin d'un chemin vers la masse
        for (const auto& borne : instance.bornes)
            if (borne.noeud.empty())
                lignes_.push_back("R" + instance.reference + "_nc" + borne.nom +
                                  " " + instance.reference + "_nc_" + borne.nom +
                                  " 0 100e6");
    }

    for (const auto& directive : directives) lignes_.push_back(directive);

    // Chemin de fuite vers la masse sur chaque nœud. Un schéma en cours de
    // saisie comporte forcément des nœuds encore isolés : sans cela SPICE
    // refuserait le circuit (« no DC path to ground ») et l'utilisateur
    // n'aurait aucun retour tant que son montage n'est pas terminé. À 1 TΩ,
    // l'influence sur les résultats est nulle.
    int compteur_fuite = 0;
    for (const auto& noeud : netlist.noeuds()) {
        if (noeud.empty() || noeud == Netlist::kMasse) continue;
        std::ostringstream f;
        f << "Rfuite" << ++compteur_fuite << " " << noeud << " 0 1e12";
        lignes_.push_back(f.str());
    }

    // Demande explicite des courants de branche : sans .save, l'analyse au
    // point de repos ne conserve que les tensions de nœuds.
    std::ostringstream sauvegardes;
    sauvegardes << ".save all";
    for (const auto& ligne : lignes_) {
        if (ligne.empty()) continue;
        const char premier = static_cast<char>(std::tolower(ligne[0]));
        const std::string nom = ligne.substr(0, ligne.find(' '));
        if (premier == 'r')
            sauvegardes << " @" << minuscules(nom) << "[i]";
        else if (premier == 'd')
            sauvegardes << " @" << minuscules(nom) << "[id]";
    }
    lignes_.push_back(sauvegardes.str());
    lignes_.push_back(".op");
    lignes_.push_back(".end");

    std::ostringstream flux;
    for (const auto& ligne : lignes_) flux << ligne << "\n";
    source_ = flux.str();
    return source_;
}

bool NgspiceEngine::resoudre() {
    erreurs_.clear();
    tensions_.clear();
    courants_.clear();
#ifndef AVEC_NGSPICE
    erreurs_.push_back("ngspice n'est pas compilé dans cette version");
    return false;
#else
    g_erreurs = &erreurs_;
    if (!g_initialise) {
        ngSpice_Init(cb_sortie, cb_statut, cb_sortie_forcee, cb_donnees,
                     cb_init, cb_thread, nullptr);
        g_initialise = true;
    }

    // ngspice empile les circuits et les tracés d'une invocation à l'autre.
    // Un simulateur interactif résout des milliers de fois : sans ce ménage,
    // la mémoire grimpe et les noms de tracés dérivent (op1, op2, op3…).
    ngSpice_Command(const_cast<char*>("destroy all"));
    ngSpice_Command(const_cast<char*>("remcirc"));

    std::vector<char*> tableau;
    for (auto& ligne : lignes_) tableau.push_back(const_cast<char*>(ligne.c_str()));
    tableau.push_back(nullptr);
    if (ngSpice_Circ(tableau.data()) != 0) {
        erreurs_.push_back("ngspice a refusé le circuit");
        return false;
    }

    ngSpice_Command(const_cast<char*>("run"));

    // Le tracé courant se nomme op1, op2… selon l'historique : il faut le
    // demander, jamais le supposer.
    const char* tracé = ngSpice_CurPlot();
    if (!tracé) {
        erreurs_.push_back("ngspice n'a produit aucun résultat");
        return false;
    }
    const std::string prefixe = std::string(tracé) + ".";

    if (char** vecteurs = ngSpice_AllVecs(const_cast<char*>(tracé))) {
        for (int k = 0; vecteurs[k]; ++k) {
            const std::string complet = prefixe + vecteurs[k];
            pvector_info info = ngGet_Vec_Info(const_cast<char*>(complet.c_str()));
            if (!info || !info->v_realdata || info->v_length < 1) continue;
            const double valeur = info->v_realdata[0];
            const std::string cle = minuscules(vecteurs[k]);

            // Courant relevé par .save : "@dled1[id]", "@rr1[i]"
            if (!cle.empty() && cle.front() == '@') {
                const size_t crochet = cle.find('[');
                if (crochet == std::string::npos || crochet <= 1) continue;
                const std::string spice = cle.substr(1, crochet - 1);  // "dled1"
                courants_[spice] = valeur;
                // même courant sous la référence du schéma : "led1"
                if (spice.size() > 1) courants_[spice.substr(1)] = valeur;
                continue;
            }
            // Courant traversant une source de tension : "vd13#branch"
            const std::string suffixe = "#branch";
            if (cle.size() > suffixe.size() &&
                cle.compare(cle.size() - suffixe.size(), suffixe.size(), suffixe)
                    == 0) {
                const std::string spice = cle.substr(0, cle.size() - suffixe.size());
                courants_[spice] = valeur;
                if (spice.size() > 1) courants_[spice.substr(1)] = valeur;
                continue;
            }
            // Tension de nœud. ngspice enveloppe dans « V(...) » les noms qui
            // ne peuvent pas rester nus — typiquement ceux qui commencent par
            // un chiffre, comme notre nœud d'alimentation « 5V ».
            if (cle.size() > 3 && cle.compare(0, 2, "v(") == 0 &&
                cle.back() == ')')
                tensions_[cle.substr(2, cle.size() - 3)] = valeur;
            else
                tensions_[cle] = valeur;
        }
    }
    tensions_[minuscules(Netlist::kMasse)] = 0.0;
    tensions_["0"] = 0.0;
    return true;
#endif
}

double NgspiceEngine::tension(const std::string& noeud) const {
    if (noeud == Netlist::kMasse || noeud == "0") return 0.0;
    auto it = tensions_.find(minuscules(noeud));
    return it == tensions_.end() ? 0.0 : it->second;
}

double NgspiceEngine::courant(const std::string& reference) const {
    auto it = courants_.find(minuscules(reference));
    return it == courants_.end() ? 0.0 : it->second;
}

}  // namespace coeur
