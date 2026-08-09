#include "core/pcb/Routeur.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <functional>
#include <queue>
#include <set>

namespace coeur {

namespace {

// La grille : une case par pas, par couche. Chaque case porte le net qui
// l'occupe — la case vide porte une chaîne vide. Garder le NET plutôt qu'un
// simple « occupé » change tout : une piste peut traverser le cuivre de son
// propre net, c'est même ce qu'on souhaite.
class Grille {
public:
    Grille(double largeur, double hauteur, double pas, int couches)
        : pas_(pas),
          colonnes_(std::max(2, static_cast<int>(std::ceil(largeur / pas)) + 1)),
          lignes_(std::max(2, static_cast<int>(std::ceil(hauteur / pas)) + 1)),
          couches_(couches),
          cases_(static_cast<size_t>(colonnes_) * lignes_ * couches_) {}

    int colonnes() const { return colonnes_; }
    int lignes() const { return lignes_; }
    int couches() const { return couches_; }

    int colonne_de(double x) const {
        return static_cast<int>(std::lround(x / pas_));
    }
    int ligne_de(double y) const { return static_cast<int>(std::lround(y / pas_)); }
    double x_de(int colonne) const { return colonne * pas_; }
    double y_de(int ligne) const { return ligne * pas_; }

    bool dedans(int colonne, int ligne) const {
        return colonne >= 0 && colonne < colonnes_ && ligne >= 0
               && ligne < lignes_;
    }

    const std::string& occupant(int colonne, int ligne, int couche) const {
        return cases_[rang(colonne, ligne, couche)];
    }
    void occuper(int colonne, int ligne, int couche, const std::string& net) {
        if (!dedans(colonne, ligne) || couche < 0 || couche >= couches_) return;
        std::string& case_ = cases_[rang(colonne, ligne, couche)];
        // Le cuivre d'un net ne s'efface pas au profit d'un autre : la
        // première occupation gagne, et la suivante devra contourner.
        if (case_.empty()) case_ = net;
    }

    // Marque un disque de cuivre : une pastille, ou le bout d'une piste.
    void marquer_disque(double x, double y, double rayon, int couche,
                        const std::string& net) {
        const int portee = static_cast<int>(std::ceil(rayon / pas_));
        const int c0 = colonne_de(x), l0 = ligne_de(y);
        for (int dc = -portee; dc <= portee; ++dc) {
            for (int dl = -portee; dl <= portee; ++dl) {
                const double ex = x_de(c0 + dc) - x, ey = y_de(l0 + dl) - y;
                if (ex * ex + ey * ey > rayon * rayon) continue;
                occuper(c0 + dc, l0 + dl, couche, net);
            }
        }
    }

    // Marque un segment de cuivre, avec sa demi-largeur.
    void marquer_segment(double x1, double y1, double x2, double y2,
                         double rayon, int couche, const std::string& net) {
        const double longueur = std::hypot(x2 - x1, y2 - y1);
        const int pas_nombre =
            std::max(1, static_cast<int>(std::ceil(longueur / (pas_ / 2))));
        for (int k = 0; k <= pas_nombre; ++k) {
            const double t = static_cast<double>(k) / pas_nombre;
            marquer_disque(x1 + (x2 - x1) * t, y1 + (y2 - y1) * t, rayon, couche,
                           net);
        }
    }

private:
    size_t rang(int colonne, int ligne, int couche) const {
        return (static_cast<size_t>(couche) * lignes_ + ligne) * colonnes_
               + colonne;
    }
    double pas_;
    int colonnes_, lignes_, couches_;
    std::vector<std::string> cases_;
};

struct CaseRoutage {
    int colonne, ligne, couche, direction;
    double cout;
    bool operator>(const CaseRoutage& autre) const { return cout > autre.cout; }
};

// Les quatre directions, plus le changement de face.
constexpr int kDx[4] = {1, -1, 0, 0};
constexpr int kDy[4] = {0, 0, 1, -1};

}  // namespace

std::string CompteRenduRoutage::resume() const {
    std::string texte = std::to_string(routees) + "/" + std::to_string(liaisons)
                        + " liaisons routées";
    if (liaisons > 0)
        texte += " (" + std::to_string(routees * 100 / liaisons) + " %)";
    texte += ", " + std::to_string(vias) + " via(s), "
             + std::to_string(static_cast<int>(longueur + 0.5)) + " mm de cuivre";
    if (!echecs.empty()) {
        texte += "\nNon routé : ";
        for (size_t k = 0; k < echecs.size(); ++k) {
            if (k) texte += ", ";
            texte += echecs[k];
        }
        texte += "\nDéplacez les composants concernés, ou tirez ces pistes à "
                 "la main.";
    }
    return texte;
}

CompteRenduRoutage router(CartePcb& carte, const ReglagesRoutage& reglages) {
    CompteRenduRoutage rendu;
    const double pas = std::max(0.1, reglages.pas);
    const int couches = reglages.deux_couches ? 2 : 1;
    Grille grille(carte.largeur, carte.hauteur, pas, couches);

    // Le rayon de garde autour de tout cuivre : sa demi-largeur, plus
    // l'isolation exigée. C'est lui qui fait la différence entre une carte
    // fabricable et une carte que le contrôle refuse.
    const double garde = reglages.largeur / 2 + reglages.isolation;

    const std::vector<PastillePosee> pastilles = carte.pastilles();

    // 1. Les pastilles occupent les deux faces : elles sont traversantes, et
    //    même une pastille montée en surface interdit le passage sous elle.
    for (const PastillePosee& pastille : pastilles) {
        const double rayon = std::max(pastille.diametre, pastille.hauteur) / 2
                             + reglages.isolation;
        const std::string net = pastille.mecanique() ? "@fixation" : pastille.net;
        for (int couche = 0; couche < couches; ++couche)
            grille.marquer_disque(pastille.x, pastille.y, rayon, couche, net);
    }

    // 2. Les pistes déjà tracées : on les respecte au lieu de les refaire.
    for (const Piste& piste : carte.pistes) {
        grille.marquer_segment(piste.x1, piste.y1, piste.x2, piste.y2,
                               piste.largeur / 2 + reglages.isolation,
                               piste.couche, piste.net);
    }

    // 3. Les liaisons à router, les plus courtes d'abord. C'est la règle
    //    classique : une courte liaison route presque toujours, et laisse
    //    plus de place aux longues ; l'inverse encombre la carte pour rien.
    std::vector<CartePcb::Liaison> liaisons;
    for (const CartePcb::Liaison& liaison : carte.chevelu())
        if (!liaison.routee) liaisons.push_back(liaison);
    std::sort(liaisons.begin(), liaisons.end(),
              [](const CartePcb::Liaison& a, const CartePcb::Liaison& b) {
                  return std::hypot(a.x2 - a.x1, a.y2 - a.y1)
                         < std::hypot(b.x2 - b.x1, b.y2 - b.y1);
              });
    rendu.liaisons = static_cast<int>(liaisons.size());

    const size_t total_cases =
        static_cast<size_t>(grille.colonnes()) * grille.lignes() * couches;

    for (const CartePcb::Liaison& liaison : liaisons) {
        const int c_depart = grille.colonne_de(liaison.x1);
        const int l_depart = grille.ligne_de(liaison.y1);
        const int c_arrivee = grille.colonne_de(liaison.x2);
        const int l_arrivee = grille.ligne_de(liaison.y2);
        if (!grille.dedans(c_depart, l_depart)
            || !grille.dedans(c_arrivee, l_arrivee)) {
            rendu.echecs.push_back(liaison.net + " (hors carte)");
            continue;
        }

        // A* : le coût déjà payé, plus la distance restante à vol d'oiseau.
        // Cette estimation ne surestime jamais, donc le chemin trouvé est
        // bien le moins cher — ce n'est pas une heuristique approximative.
        std::vector<double> couts(total_cases, 1e18);
        std::vector<int> precedent(total_cases, -1);
        std::vector<int> direction_de(total_cases, -1);
        auto rang = [&](int c, int l, int f) {
            return (static_cast<size_t>(f) * grille.lignes() + l)
                   * grille.colonnes() + c;
        };
        auto estimation = [&](int c, int l) {
            return static_cast<double>(std::abs(c - c_arrivee)
                                       + std::abs(l - l_arrivee));
        };

        std::priority_queue<CaseRoutage, std::vector<CaseRoutage>, std::greater<CaseRoutage>> file;
        for (int couche = 0; couche < couches; ++couche) {
            couts[rang(c_depart, l_depart, couche)] = 0;
            file.push({c_depart, l_depart, couche, -1,
                       estimation(c_depart, l_depart)});
        }

        int arrivee_couche = -1;
        while (!file.empty()) {
            const CaseRoutage tete = file.top();
            file.pop();
            const size_t ici = rang(tete.colonne, tete.ligne, tete.couche);
            if (tete.cout > couts[ici] + estimation(tete.colonne, tete.ligne) + 1e-9)
                continue;
            if (tete.colonne == c_arrivee && tete.ligne == l_arrivee) {
                arrivee_couche = tete.couche;
                break;
            }

            // Les quatre voisins de la même face.
            for (int d = 0; d < 4; ++d) {
                const int c = tete.colonne + kDx[d], l = tete.ligne + kDy[d];
                if (!grille.dedans(c, l)) continue;
                const std::string& occupant =
                    grille.occupant(c, l, tete.couche);
                const bool arrivee = c == c_arrivee && l == l_arrivee;
                // On traverse le vide, son propre net, et l'on entre dans la
                // pastille visée. Rien d'autre.
                if (!occupant.empty() && occupant != liaison.net && !arrivee)
                    continue;
                const double virage =
                    (tete.direction >= 0 && tete.direction != d)
                        ? reglages.cout_virage
                        : 0.0;
                const double cout = couts[ici] + 1.0 + virage;
                const size_t la = rang(c, l, tete.couche);
                if (cout + 1e-9 >= couts[la]) continue;
                couts[la] = cout;
                precedent[la] = static_cast<int>(ici);
                direction_de[la] = d;
                file.push({c, l, tete.couche, d, cout + estimation(c, l)});
            }

            // Le changement de face, au prix d'un via.
            for (int autre = 0; autre < couches; ++autre) {
                if (autre == tete.couche) continue;
                const std::string& occupant =
                    grille.occupant(tete.colonne, tete.ligne, autre);
                if (!occupant.empty() && occupant != liaison.net) continue;
                const double cout = couts[ici] + reglages.cout_via;
                const size_t la = rang(tete.colonne, tete.ligne, autre);
                if (cout + 1e-9 >= couts[la]) continue;
                couts[la] = cout;
                precedent[la] = static_cast<int>(ici);
                direction_de[la] = -1;
                file.push({tete.colonne, tete.ligne, autre, -1,
                           cout + estimation(tete.colonne, tete.ligne)});
            }
        }

        if (arrivee_couche < 0) {
            rendu.echecs.push_back(liaison.net);
            continue;
        }

        // Remonter le chemin, et le poser en segments : un segment par
        // portion droite. Une piste faite d'une case à la fois serait juste,
        // mais illisible à l'écran comme dans le Gerber.
        std::vector<std::array<int, 3>> chemin;
        for (int position = static_cast<int>(rang(c_arrivee, l_arrivee,
                                                  arrivee_couche));
             position >= 0; position = precedent[position]) {
            const int couche = position
                               / (grille.lignes() * grille.colonnes());
            const int reste = position
                              % (grille.lignes() * grille.colonnes());
            chemin.push_back({reste % grille.colonnes(),
                              reste / grille.colonnes(), couche});
        }
        std::reverse(chemin.begin(), chemin.end());

        // Poser le chemin en segments : un segment par portion droite d'une
        // même face. Une piste faite d'une case à la fois serait juste, mais
        // illisible à l'écran comme dans le fichier de fabrication.
        auto poser = [&](size_t debut, size_t fin) {
            if (fin <= debut) return;
            Piste piste;
            piste.net = liaison.net;
            piste.x1 = grille.x_de(chemin[debut][0]);
            piste.y1 = grille.y_de(chemin[debut][1]);
            piste.x2 = grille.x_de(chemin[fin][0]);
            piste.y2 = grille.y_de(chemin[fin][1]);
            piste.largeur = reglages.largeur;
            piste.couche = chemin[debut][2];
            rendu.longueur += std::hypot(piste.x2 - piste.x1,
                                         piste.y2 - piste.y1);
            grille.marquer_segment(piste.x1, piste.y1, piste.x2, piste.y2,
                                   garde, piste.couche, liaison.net);
            carte.pistes.push_back(piste);
        };

        size_t debut = 0;
        for (size_t k = 1; k < chemin.size(); ++k) {
            // Un via : même case, autre face. Le segment s'arrête juste
            // avant, et le suivant repart de l'autre côté.
            if (chemin[k][2] != chemin[k - 1][2]) {
                poser(debut, k - 1);
                ++rendu.vias;
                for (int face : {chemin[k][2], chemin[k - 1][2]})
                    grille.marquer_disque(grille.x_de(chemin[k][0]),
                                          grille.y_de(chemin[k][1]), garde,
                                          face, liaison.net);
                debut = k;
                continue;
            }
            // Un virage, ou la fin du chemin : on ferme le segment ici.
            const bool derniere = k + 1 == chemin.size();
            bool tourne = false;
            if (!derniere && chemin[k + 1][2] == chemin[k][2]) {
                tourne = (chemin[k + 1][0] - chemin[k][0]
                          != chemin[k][0] - chemin[k - 1][0])
                         || (chemin[k + 1][1] - chemin[k][1]
                             != chemin[k][1] - chemin[k - 1][1]);
            }
            if (derniere || tourne) {
                poser(debut, k);
                debut = k;
            }
        }

        ++rendu.routees;
    }
    return rendu;
}

}  // namespace coeur
