#include "core/pcb/Pcb.h"

#include <algorithm>
#include <cmath>
#include <iomanip>
#include <map>
#include <set>
#include <sstream>

#include "core/Device.h"

namespace coeur {

namespace {

constexpr double kPas = 2.54;    // pas standard, en millimètres

// Empreinte de secours pour un composant qui n'en déclare pas : une rangée de
// pastilles au pas de 2,54 mm. Mieux vaut une empreinte approximative qu'un
// composant absent de la carte — on la corrige ensuite dans le catalogue.
Empreinte empreinte_par_defaut(const Modele& modele) {
    Empreinte secours;
    secours.nom = "GENERIQUE_" + std::to_string(modele.bornes.size());
    const int nombre = static_cast<int>(modele.bornes.size());
    if (nombre <= 0) return secours;
    if (nombre <= 3) {
        for (int k = 0; k < nombre; ++k)
            secours.pastilles.push_back(
                {modele.bornes[k].nom, (k - (nombre - 1) / 2.0) * kPas, 0.0,
                 1.6, 0.8});
        secours.largeur = nombre * kPas;
        secours.hauteur = 2.5;
        return secours;
    }
    // Au-delà, un boîtier à deux rangées, comme un DIP.
    const int par_rangee = (nombre + 1) / 2;
    for (int k = 0; k < nombre; ++k) {
        const int rangee = k < par_rangee ? 0 : 1;
        const int position = rangee == 0 ? k : k - par_rangee;
        secours.pastilles.push_back({modele.bornes[k].nom,
                                     (position - (par_rangee - 1) / 2.0) * kPas,
                                     rangee == 0 ? -3.81 : 3.81, 1.6, 0.8});
    }
    secours.largeur = par_rangee * kPas;
    secours.hauteur = 7.62 + 2.0;
    return secours;
}

double distance_point_segment(double px, double py, double x1, double y1,
                              double x2, double y2) {
    const double dx = x2 - x1, dy = y2 - y1;
    const double longueur = dx * dx + dy * dy;
    if (longueur < 1e-12) return std::hypot(px - x1, py - y1);
    double t = ((px - x1) * dx + (py - y1) * dy) / longueur;
    t = std::max(0.0, std::min(1.0, t));
    return std::hypot(px - (x1 + t * dx), py - (y1 + t * dy));
}

// Distance entre deux segments, cas du plan. Suffisante pour un contrôle
// d'isolation : si elle est supérieure à la règle, aucun point des deux
// pistes n'est trop proche.
double distance_segments(const Piste& a, const Piste& b) {
    return std::min(
        std::min(distance_point_segment(a.x1, a.y1, b.x1, b.y1, b.x2, b.y2),
                 distance_point_segment(a.x2, a.y2, b.x1, b.y1, b.x2, b.y2)),
        std::min(distance_point_segment(b.x1, b.y1, a.x1, a.y1, a.x2, a.y2),
                 distance_point_segment(b.x2, b.y2, a.x1, a.y1, a.x2, a.y2)));
}

// Gerber travaille en unités entières ; on choisit le format 4.6 en
// millimètres, celui que tout le monde accepte.
std::string coordonnee(double millimetres) {
    std::ostringstream flux;
    flux << static_cast<long long>(std::llround(millimetres * 1e6));
    return flux.str();
}

}  // namespace

CartePcb CartePcb::depuis_netlist(const Netlist& netlist) {
    CartePcb carte;
    double x = 12.0, y = 12.0;
    double hauteur_rangee = 0;

    for (const Instance& instance : netlist.instances()) {
        const Modele* modele = Catalogue::instance().modele(instance.type);
        if (!modele) continue;
        // Masse et symboles d'alimentation n'existent pas sur une carte.
        if (!modele->noeud_impose.empty()) continue;

        const Empreinte& source = modele->empreinte.pastilles.empty()
                                      ? empreinte_par_defaut(*modele)
                                      : modele->empreinte;
        // `empreinte_par_defaut` renvoie un temporaire : on le recopie avant
        // que la référence ne meure.
        const Empreinte empreinte = source;

        ComposantPose pose;
        pose.reference = instance.reference;
        pose.type = instance.type;
        pose.empreinte = empreinte.nom;
        pose.largeur = empreinte.largeur > 0 ? empreinte.largeur : 5.0;
        pose.hauteur = empreinte.hauteur > 0 ? empreinte.hauteur : 5.0;

        for (const Pastille& pastille : empreinte.pastilles) {
            PastillePosee posee;
            posee.composant = instance.reference;
            posee.borne = pastille.nom;
            posee.x = pastille.x;
            posee.y = pastille.y;
            posee.diametre = pastille.diametre;
            posee.percage = pastille.percage;
            if (const Borne* borne = instance.borne(pastille.nom))
                posee.net = borne->noeud;
            pose.pastilles.push_back(posee);
        }

        // Placement en grille : un point de départ, pas une proposition de
        // routage. On repasse dessus à la main.
        if (x + pose.largeur > carte.largeur - 10.0) {
            x = 12.0;
            y += hauteur_rangee + 8.0;
            hauteur_rangee = 0;
        }
        pose.x = x + pose.largeur / 2;
        pose.y = y + pose.hauteur / 2;
        x += pose.largeur + 8.0;
        hauteur_rangee = std::max(hauteur_rangee, pose.hauteur);

        carte.composants.push_back(std::move(pose));
    }
    if (y + hauteur_rangee + 12.0 > carte.hauteur)
        carte.hauteur = y + hauteur_rangee + 12.0;
    return carte;
}

ComposantPose* CartePcb::trouver(const std::string& reference) {
    for (ComposantPose& pose : composants)
        if (pose.reference == reference) return &pose;
    return nullptr;
}

void CartePcb::deplacer(const std::string& reference, double x, double y) {
    if (ComposantPose* pose = trouver(reference)) {
        pose->x = x;
        pose->y = y;
    }
}

std::vector<PastillePosee> CartePcb::pastilles() const {
    std::vector<PastillePosee> resultat;
    for (const ComposantPose& pose : composants) {
        const double angle = pose.rotation * 3.14159265358979323846 / 180.0;
        const double cosinus = std::cos(angle), sinus = std::sin(angle);
        for (const PastillePosee& pastille : pose.pastilles) {
            PastillePosee absolue = pastille;
            absolue.x = pose.x + pastille.x * cosinus - pastille.y * sinus;
            absolue.y = pose.y + pastille.x * sinus + pastille.y * cosinus;
            resultat.push_back(absolue);
        }
    }
    return resultat;
}

bool CartePcb::reliees(double x1, double y1, double x2, double y2,
                       const std::string& net) const {
    // Parcours de proche en proche : deux pastilles sont reliées si une
    // chaîne de pistes du même net va de l'une à l'autre. La tolérance vaut
    // un demi-millimètre, l'ordre de grandeur d'une pastille.
    constexpr double kTolerance = 0.5;
    std::vector<std::pair<double, double>> atteints = {{x1, y1}};
    std::vector<bool> utilisee(pistes.size(), false);
    bool progres = true;
    while (progres) {
        progres = false;
        for (size_t k = 0; k < pistes.size(); ++k) {
            if (utilisee[k] || pistes[k].net != net) continue;
            for (const auto& point : atteints) {
                const bool touche_debut =
                    std::hypot(point.first - pistes[k].x1,
                               point.second - pistes[k].y1) <= kTolerance;
                const bool touche_fin =
                    std::hypot(point.first - pistes[k].x2,
                               point.second - pistes[k].y2) <= kTolerance;
                if (!touche_debut && !touche_fin) continue;
                atteints.emplace_back(touche_debut ? pistes[k].x2 : pistes[k].x1,
                                      touche_debut ? pistes[k].y2 : pistes[k].y1);
                utilisee[k] = true;
                progres = true;
                break;
            }
        }
        for (const auto& point : atteints)
            if (std::hypot(point.first - x2, point.second - y2) <= kTolerance)
                return true;
    }
    return false;
}

std::vector<CartePcb::Liaison> CartePcb::chevelu() const {
    std::vector<Liaison> liaisons;
    std::map<std::string, std::vector<PastillePosee>> par_net;
    for (const PastillePosee& pastille : pastilles()) {
        if (pastille.net.empty()) continue;
        par_net[pastille.net].push_back(pastille);
    }

    for (const auto& paire : par_net) {
        const std::vector<PastillePosee>& groupe = paire.second;
        if (groupe.size() < 2) continue;
        // Arbre de proche en proche : on part de la première pastille et on
        // rattache à chaque fois la plus proche de celles déjà reliées.
        std::vector<bool> dedans(groupe.size(), false);
        dedans[0] = true;
        for (size_t restantes = 1; restantes < groupe.size(); ++restantes) {
            double meilleure = 1e18;
            size_t depuis = 0, vers = 0;
            for (size_t a = 0; a < groupe.size(); ++a) {
                if (!dedans[a]) continue;
                for (size_t b = 0; b < groupe.size(); ++b) {
                    if (dedans[b]) continue;
                    const double d =
                        std::hypot(groupe[a].x - groupe[b].x,
                                   groupe[a].y - groupe[b].y);
                    if (d >= meilleure) continue;
                    meilleure = d;
                    depuis = a;
                    vers = b;
                }
            }
            dedans[vers] = true;
            Liaison liaison;
            liaison.net = paire.first;
            liaison.x1 = groupe[depuis].x;
            liaison.y1 = groupe[depuis].y;
            liaison.x2 = groupe[vers].x;
            liaison.y2 = groupe[vers].y;
            liaison.routee = reliees(liaison.x1, liaison.y1, liaison.x2,
                                     liaison.y2, liaison.net);
            liaisons.push_back(liaison);
        }
    }
    return liaisons;
}

std::vector<CartePcb::AnomaliePcb> CartePcb::controler(
    double isolation, double largeur_mini) const {
    std::vector<AnomaliePcb> anomalies;

    for (const Piste& piste : pistes) {
        if (piste.largeur < largeur_mini)
            anomalies.push_back({"piste trop fine sur le net " + piste.net,
                                 piste.x1, piste.y1});
        if (piste.x1 < 0 || piste.y1 < 0 || piste.x2 < 0 || piste.y2 < 0
            || piste.x1 > largeur || piste.x2 > largeur || piste.y1 > hauteur
            || piste.y2 > hauteur)
            anomalies.push_back({"piste hors du contour de la carte", piste.x1,
                                 piste.y1});
    }

    // Deux cuivres de nets différents trop proches : c'est le défaut que la
    // fabrication ne pardonne pas.
    for (size_t a = 0; a < pistes.size(); ++a) {
        for (size_t b = a + 1; b < pistes.size(); ++b) {
            if (pistes[a].couche != pistes[b].couche) continue;
            if (pistes[a].net == pistes[b].net) continue;
            const double marge = distance_segments(pistes[a], pistes[b])
                                 - (pistes[a].largeur + pistes[b].largeur) / 2;
            if (marge < isolation)
                anomalies.push_back({"isolation insuffisante entre les nets "
                                         + pistes[a].net + " et " + pistes[b].net,
                                     pistes[a].x1, pistes[a].y1});
        }
    }

    const std::vector<PastillePosee> toutes = pastilles();
    for (size_t a = 0; a < toutes.size(); ++a) {
        for (size_t b = a + 1; b < toutes.size(); ++b) {
            if (toutes[a].net == toutes[b].net && !toutes[a].net.empty())
                continue;
            const double marge =
                std::hypot(toutes[a].x - toutes[b].x, toutes[a].y - toutes[b].y)
                - (toutes[a].diametre + toutes[b].diametre) / 2;
            if (marge < isolation)
                anomalies.push_back({"pastilles trop proches : "
                                         + toutes[a].composant + "." + toutes[a].borne
                                         + " et " + toutes[b].composant + "."
                                         + toutes[b].borne,
                                     toutes[a].x, toutes[a].y});
        }
    }
    return anomalies;
}

// ---------------------------------------------------------------------------
// Fichiers de fabrication
// ---------------------------------------------------------------------------
std::string CartePcb::gerber(int couche) const {
    std::ostringstream flux;
    flux << "G04 Simulateur embarque - couche "
         << (couche == 0 ? "dessus" : "dessous") << "*\n";
    flux << "%FSLAX46Y46*%\n";        // format 4.6
    flux << "%MOMM*%\n";              // millimètres
    flux << "%LP D*%\n";

    // Une ouverture par diamètre de pastille, une par largeur de piste.
    std::vector<double> ouvertures;
    auto rang_ouverture = [&ouvertures](double taille) {
        for (size_t k = 0; k < ouvertures.size(); ++k)
            if (std::fabs(ouvertures[k] - taille) < 1e-9)
                return static_cast<int>(k) + 10;
        ouvertures.push_back(taille);
        return static_cast<int>(ouvertures.size()) + 9;
    };
    std::ostringstream corps;
    // Pastilles : elles existent sur les deux faces d'un trou traversant.
    for (const PastillePosee& pastille : pastilles()) {
        const int rang = rang_ouverture(pastille.diametre);
        corps << "D" << rang << "*\n";
        corps << "X" << coordonnee(pastille.x) << "Y" << coordonnee(pastille.y)
              << "D03*\n";
    }
    for (const Piste& piste : pistes) {
        if (piste.couche != couche) continue;
        const int rang = rang_ouverture(piste.largeur);
        corps << "D" << rang << "*\n";
        corps << "X" << coordonnee(piste.x1) << "Y" << coordonnee(piste.y1)
              << "D02*\n";
        corps << "X" << coordonnee(piste.x2) << "Y" << coordonnee(piste.y2)
              << "D01*\n";
    }
    for (size_t k = 0; k < ouvertures.size(); ++k)
        flux << "%ADD" << (k + 10) << "C," << ouvertures[k] << "*%\n";
    flux << "G01*\n" << corps.str() << "M02*\n";
    return flux.str();
}

std::string CartePcb::gerber_contour() const {
    std::ostringstream flux;
    flux << "G04 Simulateur embarque - contour*\n";
    flux << "%FSLAX46Y46*%\n%MOMM*%\n%LP D*%\n";
    flux << "%ADD10C,0.150000*%\nD10*\nG01*\n";
    const double points[5][2] = {{0, 0}, {largeur, 0}, {largeur, hauteur},
                                 {0, hauteur}, {0, 0}};
    flux << "X" << coordonnee(points[0][0]) << "Y" << coordonnee(points[0][1])
         << "D02*\n";
    for (int k = 1; k < 5; ++k)
        flux << "X" << coordonnee(points[k][0]) << "Y"
             << coordonnee(points[k][1]) << "D01*\n";
    flux << "M02*\n";
    return flux.str();
}

std::string CartePcb::excellon() const {
    std::ostringstream flux;
    flux << "M48\n";                  // en-tête
    flux << "; Simulateur embarque - percages\n";
    flux << "METRIC,TZ\n";

    std::vector<double> outils;
    for (const PastillePosee& pastille : pastilles()) {
        if (pastille.percage <= 0) continue;
        bool connu = false;
        for (double diametre : outils)
            if (std::fabs(diametre - pastille.percage) < 1e-9) connu = true;
        if (!connu) outils.push_back(pastille.percage);
    }
    std::sort(outils.begin(), outils.end());
    for (size_t k = 0; k < outils.size(); ++k)
        flux << "T" << (k + 1) << "C" << std::fixed << std::setprecision(3)
             << outils[k] << "\n";
    flux << "%\n";

    for (size_t k = 0; k < outils.size(); ++k) {
        flux << "T" << (k + 1) << "\n";
        for (const PastillePosee& pastille : pastilles()) {
            if (std::fabs(pastille.percage - outils[k]) > 1e-9) continue;
            flux << "X" << std::fixed << std::setprecision(3) << pastille.x
                 << "Y" << pastille.y << "\n";
        }
    }
    flux << "T0\nM30\n";
    return flux.str();
}

}  // namespace coeur
