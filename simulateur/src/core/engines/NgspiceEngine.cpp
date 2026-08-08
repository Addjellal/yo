#include "core/engines/NgspiceEngine.h"

#include <algorithm>
#include <cmath>
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

// ---------------------------------------------------------------------------
// Construction du fichier SPICE
// ---------------------------------------------------------------------------
void NgspiceEngine::emettre_corps(
    const Netlist& netlist, const std::vector<std::string>& sources_broches,
    double duree_fenetre) {
    lignes_.clear();
    lignes_.push_back("circuit simulateur embarque");

    // Alimentations de la carte
    lignes_.push_back("Valim " + std::string(Netlist::kAlim) + " 0 DC 5");
    lignes_.push_back("Valim33 3V3 0 DC 3.3");

    for (const auto& ligne : sources_broches) lignes_.push_back(ligne);

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

        // Un composant qui produit un signal daté — l'écho d'un télémètre,
        // les voies d'un codeur — a besoin de connaître la fenêtre.
        const std::vector<std::string> emises =
            (duree_fenetre > 0 && modele->vers_spice_transitoire)
                ? modele->vers_spice_transitoire(instance, noeud_de,
                                                 duree_fenetre)
                : modele->vers_spice(instance, noeud_de);
        for (const auto& ligne : emises) lignes_.push_back(ligne);
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

    // Demande explicite des courants de branche : sans .save, l'analyse ne
    // conserve que les tensions de nœuds.
    std::ostringstream sauvegardes;
    sauvegardes << ".save all";
    for (size_t rang = 0; rang < lignes_.size(); ++rang) {
        const std::string& ligne = lignes_[rang];
        // La première ligne est le titre du circuit, pas un composant. Elle
        // commence par « circuit » : la prendre pour un condensateur ferait
        // demander le courant d'un composant inexistant, ce que ngspice ne
        // pardonne pas.
        if (rang == 0 || ligne.empty()) continue;
        const char premier = static_cast<char>(std::tolower(ligne[0]));
        const std::string nom = ligne.substr(0, ligne.find(' '));
        // Courant de branche de chaque composant qui en expose un. Sans ces
        // demandes explicites, seules les tensions de nœuds seraient
        // conservées, et l'oscilloscope ne pourrait pas suivre un courant.
        if (premier == 'r' || premier == 'c' || premier == 'l')
            sauvegardes << " @" << minuscules(nom) << "[i]";
        else if (premier == 'd')
            sauvegardes << " @" << minuscules(nom) << "[id]";
    }
    lignes_.push_back(sauvegardes.str());
}

// Broches du microcontrôleur : source de Thévenin ou pull-up.
std::vector<std::string> NgspiceEngine::sources_continues(
    const std::vector<BrocheElectrique>& broches) const {
    std::vector<std::string> sources;
    for (const auto& broche : broches) {
        const std::string interne = broche.noeud + "_src";
        switch (broche.mode) {
            case BrocheElectrique::Mode::Sortie: {
                std::ostringstream f;
                f << "V" << broche.noeud << " " << interne << " 0 DC "
                  << broche.tension;
                sources.push_back(f.str());
                std::ostringstream r;
                r << "R" << broche.noeud << " " << interne << " " << broche.noeud
                  << " " << broche.resistance;
                sources.push_back(r.str());
                break;
            }
            case BrocheElectrique::Mode::PullUp: {
                // pull-up interne de l'AVR : 20 kΩ à 50 kΩ selon la puce
                std::ostringstream r;
                r << "R" << broche.noeud << " " << Netlist::kAlim << " "
                  << broche.noeud << " "
                  << (broche.resistance > 1.0 ? broche.resistance : 20000.0);
                sources.push_back(r.str());
                break;
            }
            case BrocheElectrique::Mode::Entree:
                // entrée haute impédance : résistance de fuite, sinon le nœud
                // serait flottant et la matrice singulière
                sources.push_back("R" + broche.noeud + "_fuite " + broche.noeud +
                                  " 0 100e6");
                break;
        }
    }
    return sources;
}

std::string NgspiceEngine::construire(
    const Netlist& netlist, const std::vector<BrocheElectrique>& broches) {
    emettre_corps(netlist, sources_continues(broches), 0.0);
    lignes_.push_back(".op");
    lignes_.push_back(".end");

    std::ostringstream flux;
    for (const auto& ligne : lignes_) flux << ligne << "\n";
    source_ = flux.str();
    return source_;
}

std::string NgspiceEngine::construire_analyse(
    const Netlist& netlist, const std::vector<BrocheElectrique>& broches,
    const std::string& directive) {
    emettre_corps(netlist, sources_continues(broches), 0.0);
    lignes_.push_back(directive);
    lignes_.push_back(".end");

    std::ostringstream flux;
    for (const auto& ligne : lignes_) flux << ligne << "\n";
    source_ = flux.str();
    return source_;
}

std::string NgspiceEngine::construire_transitoire(
    const Netlist& netlist, const std::vector<BrocheElectrique>& broches,
    const std::vector<TransitionBroche>& transitions, double duree,
    double pas) {
    if (duree <= 0) duree = 0.025;
    if (pas <= 0 || pas > duree / 4) pas = duree / 100;

    // Durée du front. Une sortie d'AVR bascule en quelques dizaines de
    // nanosecondes ; on prend 100 ns, assez raide pour être fidèle et assez
    // douce pour que le solveur ne peine pas. Les instants de PWL créent des
    // points de calcul obligatoires : le front est donc bien vu, même avec un
    // pas d'échantillonnage bien plus grand.
    const double front = 100e-9;

    std::vector<std::string> sources;
    for (const auto& broche : broches) {
        if (broche.mode == BrocheElectrique::Mode::PullUp) {
            std::ostringstream r;
            r << "R" << broche.noeud << " " << Netlist::kAlim << " "
              << broche.noeud << " "
              << (broche.resistance > 1.0 ? broche.resistance : 20000.0);
            sources.push_back(r.str());
            continue;
        }
        if (broche.mode == BrocheElectrique::Mode::Entree) {
            sources.push_back("R" + broche.noeud + "_fuite " + broche.noeud +
                              " 0 100e6");
            continue;
        }

        // Sortie : on décrit toute son histoire sur la fenêtre.
        std::vector<std::pair<double, double>> points;
        points.emplace_back(0.0, broche.tension);
        for (const auto& transition : transitions) {
            if (transition.noeud != broche.noeud) continue;
            double instant = transition.instant;
            if (instant <= 0) instant = 0;
            if (instant > duree) continue;
            const double precedente = points.back().second;
            if (std::fabs(transition.tension - precedente) < 1e-9) continue;
            // palier jusqu'au front, puis le front lui-même
            const double debut_front = std::max(points.back().first + front / 2,
                                                instant - front);
            if (debut_front > points.back().first)
                points.emplace_back(debut_front, precedente);
            points.emplace_back(std::max(instant, debut_front + front / 2),
                                transition.tension);
        }
        if (points.back().first < duree)
            points.emplace_back(duree, points.back().second);

        std::ostringstream f;
        f << "V" << broche.noeud << " " << broche.noeud << "_src 0 PWL(";
        for (size_t k = 0; k < points.size(); ++k) {
            if (k) f << " ";
            f << points[k].first << " " << points[k].second;
        }
        f << ")";
        sources.push_back(f.str());
        std::ostringstream r;
        r << "R" << broche.noeud << " " << broche.noeud << "_src "
          << broche.noeud << " " << broche.resistance;
        sources.push_back(r.str());
    }

    emettre_corps(netlist, sources, duree);

    // Conditions initiales : sans elles, chaque fenêtre repartirait d'un
    // circuit déchargé et aucun condensateur ne se chargerait jamais.
    for (const auto& mesure : etat_initial_) {
        if (mesure.first == "0" || mesure.first.empty()) continue;
        std::ostringstream f;
        f << ".ic V(" << mesure.first << ")=" << mesure.second;
        lignes_.push_back(f.str());
    }

    std::ostringstream analyse;
    analyse << ".tran " << pas << " " << duree << " 0 " << pas;
    if (!etat_initial_.empty()) analyse << " uic";
    lignes_.push_back(analyse.str());
    lignes_.push_back(".end");

    std::ostringstream flux;
    for (const auto& ligne : lignes_) flux << ligne << "\n";
    source_ = flux.str();
    return source_;
}

// ---------------------------------------------------------------------------
// Exécution
// ---------------------------------------------------------------------------
std::string NgspiceEngine::executer() {
#ifndef AVEC_NGSPICE
    return {};
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
        return {};
    }

    ngSpice_Command(const_cast<char*>("run"));

    // Le tracé courant se nomme op1, tran1… selon l'analyse et l'historique :
    // il faut le demander, jamais le supposer.
    const char* trace = ngSpice_CurPlot();
    if (!trace) {
        erreurs_.push_back("ngspice n'a produit aucun résultat");
        return {};
    }
    return trace;
#endif
}

#ifdef AVEC_NGSPICE
namespace {

// ATTENTION : ngGet_Vec_Info renvoie un pointeur vers une structure que
// ngspice réutilise d'un appel à l'autre. Deux relevés consécutifs sans copie
// intermédiaire pointent sur les mêmes données. On copie donc tout de suite.
std::vector<double> copier_vecteur(const std::string& trace,
                                   const std::string& nom) {
    const std::string complet = trace + "." + nom;
    pvector_info info = ngGet_Vec_Info(const_cast<char*>(complet.c_str()));
    std::vector<double> copie;
    if (info && info->v_realdata && info->v_length > 0)
        copie.assign(info->v_realdata, info->v_realdata + info->v_length);
    return copie;
}

// Même précaution pour un vecteur qui peut être complexe : en analyse
// alternative, ngspice range les résultats dans `v_compdata` et laisse
// `v_realdata` nul. L'imaginaire reste vide pour un vecteur réel.
void copier_complexe(const std::string& trace, const std::string& nom,
                     std::vector<double>& reel, std::vector<double>& imaginaire) {
    reel.clear();
    imaginaire.clear();
    const std::string complet = trace + "." + nom;
    pvector_info info = ngGet_Vec_Info(const_cast<char*>(complet.c_str()));
    if (!info || info->v_length <= 0) return;
    const int taille = info->v_length;
    if (info->v_compdata) {
        reel.reserve(taille);
        imaginaire.reserve(taille);
        for (int k = 0; k < taille; ++k) {
            reel.push_back(info->v_compdata[k].cx_real);
            imaginaire.push_back(info->v_compdata[k].cx_imag);
        }
    } else if (info->v_realdata) {
        reel.assign(info->v_realdata, info->v_realdata + taille);
    }
}

// Classe un nom de vecteur ngspice : courant de composant, courant de source,
// ou tension de nœud. Renvoie false si le vecteur doit être ignoré.
enum class Genre { CourantComposant, CourantSource, Tension };

bool classer(const std::string& cle, Genre& genre, std::string& nom) {
    if (cle.empty()) return false;
    if (cle.front() == '@') {                       // "@dled1[id]", "@rr1[i]"
        const size_t crochet = cle.find('[');
        if (crochet == std::string::npos || crochet <= 1) return false;
        genre = Genre::CourantComposant;
        nom = cle.substr(1, crochet - 1);
        return true;
    }
    const std::string suffixe = "#branch";          // "vd13#branch"
    if (cle.size() > suffixe.size() &&
        cle.compare(cle.size() - suffixe.size(), suffixe.size(), suffixe) == 0) {
        genre = Genre::CourantSource;
        nom = cle.substr(0, cle.size() - suffixe.size());
        return true;
    }
    // Tension de nœud. ngspice enveloppe dans « V(...) » les noms qui ne
    // peuvent pas rester nus — typiquement ceux qui commencent par un
    // chiffre, comme notre nœud d'alimentation « 5V ».
    genre = Genre::Tension;
    nom = (cle.size() > 3 && cle.compare(0, 2, "v(") == 0 && cle.back() == ')')
              ? cle.substr(2, cle.size() - 3)
              : cle;
    return true;
}

}  // namespace
#endif

bool NgspiceEngine::resoudre() {
    erreurs_.clear();
    tensions_.clear();
    courants_.clear();
#ifndef AVEC_NGSPICE
    erreurs_.push_back("ngspice n'est pas compilé dans cette version");
    return false;
#else
    const std::string trace = executer();
    if (trace.empty()) return false;

    if (char** vecteurs = ngSpice_AllVecs(const_cast<char*>(trace.c_str()))) {
        for (int k = 0; vecteurs[k]; ++k) {
            const std::string cle = minuscules(vecteurs[k]);
            Genre genre;
            std::string nom;
            if (!classer(cle, genre, nom)) continue;
            const std::vector<double> valeurs = copier_vecteur(trace, vecteurs[k]);
            if (valeurs.empty()) continue;
            switch (genre) {
                case Genre::CourantComposant:
                case Genre::CourantSource:
                    courants_[nom] = valeurs.front();
                    // même courant sous la référence du schéma : « led1 »
                    if (nom.size() > 1) courants_[nom.substr(1)] = valeurs.front();
                    break;
                case Genre::Tension:
                    tensions_[nom] = valeurs.front();
                    break;
            }
        }
    }
    tensions_[minuscules(Netlist::kMasse)] = 0.0;
    tensions_["0"] = 0.0;
    return true;
#endif
}

bool NgspiceEngine::resoudre_analyse() {
    erreurs_.clear();
    balayage_.vider();
#ifndef AVEC_NGSPICE
    erreurs_.push_back("ngspice n'est pas compilé dans cette version");
    return false;
#else
    const std::string trace = executer();
    if (trace.empty()) return false;

    char** vecteurs = ngSpice_AllVecs(const_cast<char*>(trace.c_str()));
    if (!vecteurs) {
        erreurs_.push_back("le balayage n'a produit aucun vecteur");
        return false;
    }

    // Le nom de l'abscisse dépend de ce qui est balayé : ngspice l'appelle
    // « v-sweep » pour une source, « res-sweep » pour une résistance,
    // « temp-sweep » pour la température, « frequency » en alternatif.
    std::string abscisse;
    for (int k = 0; vecteurs[k]; ++k) {
        const std::string cle = minuscules(vecteurs[k]);
        const std::string suffixe = "-sweep";
        if (cle == "frequency" ||
            (cle.size() > suffixe.size() &&
             cle.compare(cle.size() - suffixe.size(), suffixe.size(), suffixe)
                 == 0)) {
            abscisse = vecteurs[k];
            balayage_.logarithmique = (cle == "frequency");
            balayage_.unite = balayage_.logarithmique ? "Hz" : "";
            balayage_.grandeur = balayage_.logarithmique ? "Fréquence" : cle;
            break;
        }
    }
    if (abscisse.empty()) {
        erreurs_.push_back("aucune abscisse de balayage dans le résultat");
        return false;
    }

    std::vector<double> reel, imaginaire;
    copier_complexe(trace, abscisse, reel, imaginaire);
    balayage_.abscisse = reel;               // l'abscisse est toujours réelle
    if (balayage_.abscisse.empty()) {
        erreurs_.push_back("abscisse de balayage vide");
        return false;
    }

    for (int k = 0; vecteurs[k]; ++k) {
        const std::string brut = vecteurs[k];
        if (brut == abscisse) continue;
        const std::string cle = minuscules(brut);
        // Les nœuds internes (source de broche, borne en l'air) n'ont pas de
        // sens pour l'utilisateur : ils encombreraient la légende.
        if (cle.find("_src") != std::string::npos ||
            cle.find("_nc_") != std::string::npos)
            continue;
        Genre genre;
        std::string nom;
        if (!classer(cle, genre, nom)) continue;
        // Les rails d'alimentation que nous ajoutons nous-mêmes sont
        // constants : dans un balayage ils n'apporteraient qu'une ligne plate
        // de plus et masqueraient les courbes utiles. Le nom est comparé après
        // classement, car ngspice enveloppe « 5V » en « v(5v) ».
        if (nom == "5v" || nom == "3v3" || nom == "valim" || nom == "valim33")
            continue;
        // Les résistances de fuite n'appartiennent pas au montage : elles ne
        // sont là que pour donner un chemin vers la masse à un schéma en cours
        // de saisie.
        if (nom.rfind("rfuite", 0) == 0) continue;

        std::vector<double> partie_reelle, partie_imaginaire;
        copier_complexe(trace, brut, partie_reelle, partie_imaginaire);
        if (partie_reelle.empty()) continue;

        Courbe courbe;
        courbe.nom = (genre == Genre::Tension)
                         ? nom
                         : "I(" + (nom.size() > 1 ? nom.substr(1) : nom) + ")";
        if (partie_imaginaire.empty()) {
            courbe.valeurs = std::move(partie_reelle);
        } else {
            courbe.valeurs.reserve(partie_reelle.size());
            courbe.phases.reserve(partie_reelle.size());
            for (size_t j = 0; j < partie_reelle.size(); ++j) {
                courbe.valeurs.push_back(
                    std::hypot(partie_reelle[j], partie_imaginaire[j]));
                courbe.phases.push_back(std::atan2(partie_imaginaire[j],
                                                   partie_reelle[j])
                                        * 180.0 / 3.14159265358979323846);
            }
        }
        balayage_.courbes.push_back(std::move(courbe));
    }

    std::sort(balayage_.courbes.begin(), balayage_.courbes.end(),
              [](const Courbe& a, const Courbe& b) { return a.nom < b.nom; });
    return !balayage_.courbes.empty();
#endif
}

bool NgspiceEngine::resoudre_transitoire() {
    erreurs_.clear();
    formes_.vider();
    tensions_.clear();
    courants_.clear();
#ifndef AVEC_NGSPICE
    erreurs_.push_back("ngspice n'est pas compilé dans cette version");
    return false;
#else
    const std::string trace = executer();
    if (trace.empty()) return false;

    formes_.temps = copier_vecteur(trace, "time");
    if (formes_.temps.empty()) {
        erreurs_.push_back("l'analyse transitoire n'a produit aucun point");
        return false;
    }

    if (char** vecteurs = ngSpice_AllVecs(const_cast<char*>(trace.c_str()))) {
        for (int k = 0; vecteurs[k]; ++k) {
            const std::string cle = minuscules(vecteurs[k]);
            if (cle == "time") continue;
            Genre genre;
            std::string nom;
            if (!classer(cle, genre, nom)) continue;
            std::vector<double> valeurs = copier_vecteur(trace, vecteurs[k]);
            if (valeurs.empty()) continue;

            const double dernier = valeurs.back();
            switch (genre) {
                case Genre::CourantComposant:
                case Genre::CourantSource:
                    courants_[nom] = dernier;
                    if (nom.size() > 1) {
                        courants_[nom.substr(1)] = dernier;
                        formes_.courants[nom.substr(1)] = valeurs;
                    }
                    formes_.courants[nom] = std::move(valeurs);
                    break;
                case Genre::Tension:
                    tensions_[nom] = dernier;
                    etat_final_[nom] = dernier;
                    formes_.tensions[nom] = std::move(valeurs);
                    break;
            }
        }
    }
    tensions_[minuscules(Netlist::kMasse)] = 0.0;
    tensions_["0"] = 0.0;
    etat_final_.erase("0");
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
