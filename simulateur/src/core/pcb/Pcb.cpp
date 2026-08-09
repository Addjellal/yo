#include "core/pcb/Pcb.h"

#include <algorithm>
#include <cmath>
#include <iomanip>
#include <map>
#include <set>
#include <sstream>

#include "core/Device.h"
#include "core/pcb/Empreintes.h"

namespace coeur {

namespace {

constexpr double kPi = 3.14159265358979323846;

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
    double x = 6.0, y = 6.0;
    double hauteur_rangee = 0;

    for (const Instance& instance : netlist.instances()) {
        const Modele* modele = Catalogue::instance().modele(instance.type);
        if (!modele) continue;
        // Masse, symboles d'alimentation, voltmètres, sondes : rien de tout
        // cela n'a d'existence physique sur une carte.
        if (!empreintes::physique(*modele)) continue;

        // L'empreinte vient de la bibliothèque, pas d'une rangée de trous
        // déduite du nombre de bornes : c'est ce qui fait la différence entre
        // une carte et un croquis.
        const Empreinte empreinte = empreintes::resoudre(*modele);

        ComposantPose pose;
        pose.reference = instance.reference;
        pose.type = instance.type;
        pose.empreinte = empreinte.nom;
        pose.largeur = empreinte.largeur > 0 ? empreinte.largeur : 5.0;
        pose.hauteur = empreinte.hauteur > 0 ? empreinte.hauteur : 5.0;
        pose.serigraphie = empreinte.serigraphie;

        for (const Pastille& pastille : empreinte.pastilles) {
            PastillePosee posee;
            posee.composant = instance.reference;
            posee.borne = pastille.nom;
            posee.x = pastille.x;
            posee.y = pastille.y;
            posee.diametre = pastille.diametre;
            posee.percage = pastille.percage;
            posee.forme = pastille.forme;
            posee.hauteur = pastille.hauteur;
            posee.numero = pastille.numero;
            if (const Borne* borne = instance.borne(pastille.nom))
                posee.net = borne->noeud;
            pose.pastilles.push_back(posee);
        }

        // Placement en grille : un point de départ, pas une proposition de
        // routage. On repasse dessus à la main.
        if (x > 6.0 && x + pose.largeur > carte.largeur - 6.0) {
            x = 6.0;
            y += hauteur_rangee + 6.0;
            hauteur_rangee = 0;
        }
        pose.x = x + pose.largeur / 2;
        pose.y = y + pose.hauteur / 2;
        x += pose.largeur + 6.0;
        hauteur_rangee = std::max(hauteur_rangee, pose.hauteur);

        carte.composants.push_back(std::move(pose));
    }
    carte.ajuster_contour(6.0);
    return carte;
}

void CartePcb::ajuster_contour(double marge) {
    double droite = 0, bas = 0;
    for (const ComposantPose& pose : composants) {
        droite = std::max(droite, pose.x + pose.largeur / 2);
        bas = std::max(bas, pose.y + pose.hauteur / 2);
    }
    for (const PastillePosee& pastille : pastilles()) {
        droite = std::max(droite, pastille.x + pastille.diametre / 2);
        bas = std::max(bas, pastille.y + pastille.diametre / 2);
    }
    // Les pistes comptent aussi : rétrécir la carte sous une piste déjà tirée
    // la mettrait hors contour sans prévenir.
    for (const Piste& piste : pistes) {
        droite = std::max(droite, std::max(piste.x1, piste.x2) + piste.largeur);
        bas = std::max(bas, std::max(piste.y1, piste.y2) + piste.largeur);
    }
    // Une carte se découpe à la taille de ce qu'elle porte : le prix d'un
    // circuit imprimé se compte au centimètre carré.
    largeur = std::max(30.0, droite + marge);
    hauteur = std::max(20.0, bas + marge);
}

std::vector<TraitEmpreinte> serigraphie_absolue(const ComposantPose& pose) {
    const double angle = pose.rotation * kPi / 180.0;
    const double cosinus = std::cos(angle), sinus = std::sin(angle);
    auto placer = [&](double x, double y) {
        return std::make_pair(pose.x + x * cosinus - y * sinus,
                              pose.y + x * sinus + y * cosinus);
    };

    std::vector<TraitEmpreinte> traits;
    for (const TraitEmpreinte& trait : pose.serigraphie) {
        TraitEmpreinte place = trait;
        if (trait.genre == TraitEmpreinte::Genre::Cercle) {
            const auto centre = placer(trait.x1, trait.y1);
            place.x1 = centre.first;
            place.y1 = centre.second;
        } else {
            const auto debut = placer(trait.x1, trait.y1);
            const auto fin = placer(trait.x2, trait.y2);
            place.x1 = debut.first;
            place.y1 = debut.second;
            place.x2 = fin.first;
            place.y2 = fin.second;
        }
        traits.push_back(place);
    }
    return traits;
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
        const double angle = pose.rotation * kPi / 180.0;
        const double cosinus = std::cos(angle), sinus = std::sin(angle);
        for (const PastillePosee& pastille : pose.pastilles) {
            PastillePosee absolue = pastille;
            absolue.x = pose.x + pastille.x * cosinus - pastille.y * sinus;
            absolue.y = pose.y + pastille.x * sinus + pastille.y * cosinus;
            absolue.rotation = pose.rotation;
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

    // Un trou mécanique qui traverse du cuivre. Un trou de fixation fait
    // souvent trois millimètres, une pastille en fait deux : le foret emporte
    // la pastille et la liaison avec elle. Rien ne le signale à l'écran — le
    // cuivre et le perçage sont dans deux fichiers différents, et c'est en
    // les superposant que le fabricant le découvre, ou pire, l'atelier.
    {
        const std::vector<PastillePosee> toutes = pastilles();
        for (const PastillePosee& trou : toutes) {
            if (!trou.mecanique() || trou.percage <= 0) continue;
            for (const PastillePosee& cuivre : toutes) {
                if (cuivre.mecanique()) continue;
                const double ecart = std::hypot(cuivre.x - trou.x,
                                                cuivre.y - trou.y);
                // Le foret mord la pastille dès qu'il entame son cuivre.
                if (ecart >= trou.percage / 2 + cuivre.diametre / 2) continue;
                anomalies.push_back(
                    {"trou de fixation dans la pastille " + cuivre.composant
                         + "." + cuivre.borne + " : le perçage l'emporterait",
                     trou.x, trou.y});
            }
        }
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
            // Deux pastilles d'un même boîtier sont à leur écartement normalisé
            // : c'est l'affaire de l'empreinte, pas du contrôle de la carte.
            if (toutes[a].composant == toutes[b].composant) continue;
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
    flux << "%LPD*%\n";

    // Une ouverture par forme et par taille. Le Gerber ne connaît que trois
    // formes utiles ici : C ronde, R rectangulaire, O oblongue.
    struct Ouverture {
        char forme = 'C';
        double largeur = 0, hauteur = 0;
    };
    std::vector<Ouverture> ouvertures;
    auto rang_ouverture = [&ouvertures](char forme, double largeur,
                                        double hauteur) {
        for (size_t k = 0; k < ouvertures.size(); ++k)
            if (ouvertures[k].forme == forme
                && std::fabs(ouvertures[k].largeur - largeur) < 1e-9
                && std::fabs(ouvertures[k].hauteur - hauteur) < 1e-9)
                return static_cast<int>(k) + 10;
        ouvertures.push_back({forme, largeur, hauteur});
        return static_cast<int>(ouvertures.size()) + 9;
    };
    std::ostringstream corps;
    // Pastilles : elles existent sur les deux faces d'un trou traversant.
    for (const PastillePosee& pastille : pastilles()) {
        if (pastille.mecanique()) continue;   // un trou de fixation n'est pas du cuivre
        double largeur_pastille = pastille.diametre;
        double hauteur_pastille =
            pastille.hauteur > 0 ? pastille.hauteur : pastille.diametre;
        // Une empreinte tournée d'un quart de tour échange les deux côtés.
        const int quart = static_cast<int>(std::llround(pastille.rotation / 90.0)) & 3;
        if (quart % 2) std::swap(largeur_pastille, hauteur_pastille);
        char forme = 'C';
        if (pastille.forme == Pastille::Forme::Rectangulaire) forme = 'R';
        if (pastille.forme == Pastille::Forme::Oblongue) forme = 'O';
        const int rang =
            rang_ouverture(forme, largeur_pastille, hauteur_pastille);
        corps << "D" << rang << "*\n";
        corps << "X" << coordonnee(pastille.x) << "Y" << coordonnee(pastille.y)
              << "D03*\n";
    }
    for (const Piste& piste : pistes) {
        if (piste.couche != couche) continue;
        const int rang = rang_ouverture('C', piste.largeur, piste.largeur);
        corps << "D" << rang << "*\n";
        corps << "X" << coordonnee(piste.x1) << "Y" << coordonnee(piste.y1)
              << "D02*\n";
        corps << "X" << coordonnee(piste.x2) << "Y" << coordonnee(piste.y2)
              << "D01*\n";
    }
    for (size_t k = 0; k < ouvertures.size(); ++k) {
        flux << "%ADD" << (k + 10) << ouvertures[k].forme << ","
             << ouvertures[k].largeur;
        if (ouvertures[k].forme != 'C')
            flux << "X" << ouvertures[k].hauteur;
        flux << "*%\n";
    }
    flux << "G01*\n" << corps.str() << "M02*\n";
    return flux.str();
}

std::string CartePcb::gerber_contour() const {
    std::ostringstream flux;
    flux << "G04 Simulateur embarque - contour*\n";
    flux << "%FSLAX46Y46*%\n%MOMM*%\n%LPD*%\n";
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

std::string CartePcb::gerber_serigraphie() const {
    std::ostringstream flux;
    flux << "G04 Simulateur embarque - serigraphie dessus*\n";
    flux << "%FSLAX46Y46*%\n%MOMM*%\n%LPD*%\n";
    flux << "%ADD10C,0.150000*%\nD10*\nG01*\n";

    auto tracer = [&flux](double x1, double y1, double x2, double y2) {
        flux << "X" << coordonnee(x1) << "Y" << coordonnee(y1) << "D02*\n";
        flux << "X" << coordonnee(x2) << "Y" << coordonnee(y2) << "D01*\n";
    };

    for (const ComposantPose& pose : composants) {
        for (const TraitEmpreinte& trait : serigraphie_absolue(pose)) {
            switch (trait.genre) {
                case TraitEmpreinte::Genre::Ligne:
                    tracer(trait.x1, trait.y1, trait.x2, trait.y2);
                    break;
                case TraitEmpreinte::Genre::Rect:
                    tracer(trait.x1, trait.y1, trait.x2, trait.y1);
                    tracer(trait.x2, trait.y1, trait.x2, trait.y2);
                    tracer(trait.x2, trait.y2, trait.x1, trait.y2);
                    tracer(trait.x1, trait.y2, trait.x1, trait.y1);
                    break;
                case TraitEmpreinte::Genre::Cercle: {
                    // Un cercle approché par vingt-quatre cordes : le rendu du
                    // fabricant est le même, et le fichier reste lisible.
                    constexpr int kCotes = 24;
                    const double rayon = trait.x2;
                    for (int k = 0; k < kCotes; ++k) {
                        const double a = 2 * kPi * k / kCotes;
                        const double b = 2 * kPi * (k + 1) / kCotes;
                        tracer(trait.x1 + rayon * std::cos(a),
                               trait.y1 + rayon * std::sin(a),
                               trait.x1 + rayon * std::cos(b),
                               trait.y1 + rayon * std::sin(b));
                    }
                    break;
                }
            }
        }
    }
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
