// Générateur de figures : des schémas électriques en SVG, dessinés à partir
// du catalogue du simulateur.
//
// L'intérêt n'est pas d'économiser du dessin à la main. C'est que la figure
// du cours et le symbole de l'atelier sont le même objet : ajouter un
// composant au catalogue le rend dessinable dans les deux, et il est
// impossible qu'ils divergent.
//
//   ./generer_figures <dossier de sortie>

#include <cmath>
#include <cstdio>
#include <fstream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

#include "core/Device.h"
#include "core/Netlist.h"

namespace {

// --- description d'une figure ---------------------------------------------
struct Placement {
    std::string reference;
    std::string type;
    double x = 0, y = 0;
    int rotation = 0;                          // 0, 90, 180 ou 270
    std::string etiquette;                     // remplace la valeur affichée
    std::map<std::string, std::string> textes;
    // Pour une carte : les seules broches à représenter. Dessiner les vingt
    // broches d'un Arduino quand une seule est câblée noie le montage — un
    // schéma de cours montre ce qui sert.
    std::vector<std::string> bornes_visibles;
};

struct Fil {
    std::string de, borne_de;
    std::string vers, borne_vers;
};

struct Note {
    double x = 0, y = 0;
    std::string texte;
    bool encadree = false;
};

struct Figure {
    std::string fichier;
    std::string titre;
    std::vector<Placement> composants;
    std::vector<Fil> fils;
    std::vector<Note> notes;
    double marge_droite = 0;                   // place pour les annotations
};

// --- géométrie -------------------------------------------------------------
struct Point {
    double x = 0, y = 0;
};

Point tourner(const coeur::PointSymbole& p, int rotation) {
    const double a = rotation * M_PI / 180.0;
    return {p.x * std::cos(a) - p.y * std::sin(a),
            p.x * std::sin(a) + p.y * std::cos(a)};
}

const coeur::Modele* modele_de(const Placement& placement) {
    return coeur::Catalogue::instance().modele(placement.type);
}

// Disposition d'une carte réduite à quelques broches : un rectangle, les
// broches d'alimentation et analogiques à gauche, les numériques à droite.
struct CarteReduite {
    bool active = false;
    double demi_largeur = 60, demi_hauteur = 40;
    std::map<std::string, coeur::PointSymbole> bornes;
    std::vector<std::string> gauche, droite;
};

CarteReduite reduire(const Placement& placement) {
    CarteReduite reduite;
    const coeur::Modele* modele = modele_de(placement);
    if (!modele || !modele->carte || placement.bornes_visibles.empty())
        return reduite;
    reduite.active = true;

    for (const std::string& nom : placement.bornes_visibles) {
        const bool a_gauche = nom.empty() || nom[0] == 'A' || nom == "5V" ||
                              nom == "3V3" || nom == "GND" || nom == "VIN";
        (a_gauche ? reduite.gauche : reduite.droite).push_back(nom);
    }

    const double pas = 30;
    const size_t rangees =
        std::max(reduite.gauche.size(), reduite.droite.size());
    reduite.demi_hauteur = std::max(38.0, (rangees * pas) / 2 + 14);
    reduite.demi_largeur = 62;

    auto poser = [&](const std::vector<std::string>& colonne, double x) {
        const double depart = -((colonne.size() - 1) * pas) / 2.0;
        for (size_t k = 0; k < colonne.size(); ++k)
            reduite.bornes[colonne[k]] = {x, depart + k * pas};
    };
    if (!reduite.gauche.empty()) poser(reduite.gauche, -reduite.demi_largeur - 22);
    if (!reduite.droite.empty()) poser(reduite.droite, reduite.demi_largeur + 22);
    return reduite;
}

// Position absolue d'une borne, rotation comprise.
Point borne_absolue(const Placement& placement, const std::string& nom) {
    const coeur::Modele* modele = modele_de(placement);
    if (!modele) return {placement.x, placement.y};
    const CarteReduite reduite = reduire(placement);
    if (reduite.active) {
        auto it = reduite.bornes.find(nom);
        if (it != reduite.bornes.end()) {
            const Point local = tourner(it->second, placement.rotation);
            return {placement.x + local.x, placement.y + local.y};
        }
    }
    for (const auto& borne : modele->bornes)
        if (borne.nom == nom) {
            const Point local = tourner(borne.position, placement.rotation);
            return {placement.x + local.x, placement.y + local.y};
        }
    return {placement.x, placement.y};
}

std::string nombre(double v) {
    std::ostringstream flux;
    flux.setf(std::ios::fixed);
    flux.precision(2);
    flux << v;
    std::string texte = flux.str();
    while (texte.size() > 1 && texte.back() == '0') texte.pop_back();
    if (!texte.empty() && texte.back() == '.') texte.pop_back();
    return texte;
}

std::string echapper(const std::string& texte) {
    std::string sortie;
    for (char c : texte) {
        if (c == '&') sortie += "&amp;";
        else if (c == '<') sortie += "&lt;";
        else if (c == '>') sortie += "&gt;";
        else sortie += c;
    }
    return sortie;
}

// --- tracé -----------------------------------------------------------------
class Dessin {
public:
    void ajouter(const std::string& ligne) { corps_ += "  " + ligne + "\n"; }

    void etendre(double x, double y) {
        gauche_ = std::min(gauche_, x);
        droite_ = std::max(droite_, x);
        haut_ = std::min(haut_, y);
        bas_ = std::max(bas_, y);
    }

    std::string produire(const std::string& titre, double marge_droite) const {
        const double marge = 26;
        const double x0 = gauche_ - marge;
        const double y0 = haut_ - marge - 24;          // place pour le titre
        const double largeur = (droite_ - gauche_) + 2 * marge + marge_droite;
        const double hauteur = (bas_ - haut_) + 2 * marge + 24;

        std::ostringstream flux;
        flux << "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\""
             << nombre(x0) << " " << nombre(y0) << " " << nombre(largeur) << " "
             << nombre(hauteur) << "\" font-family=\"'Segoe UI',Arial,"
             << "sans-serif\">\n"
             << "  <!-- Figure produite par simulateur/outils/generer_figures\n"
             << "       à partir du catalogue de composants : ne pas modifier"
             << " à la main. -->\n"
             << "  <!-- fond explicite : garde la figure lisible en dark mode"
             << " (GitHub, PDF) -->\n"
             << "  <rect id=\"fond\" x=\"" << nombre(x0) << "\" y=\""
             << nombre(y0) << "\" width=\"" << nombre(largeur) << "\" height=\""
             << nombre(hauteur) << "\" fill=\"#ffffff\"/>\n"
             // Noms de classes en trois lettres au moins : les feuilles de
             // style de coloration syntaxique utilisent une et deux lettres,
             // et écraseraient les nôtres dans les PDF.
             << "  <style>\n"
             << "    .titre{fill:#1a2332;font-size:15px;font-weight:600}\n"
             << "    .trait{fill:none;stroke:#1a2332;stroke-width:2;"
             << "stroke-linecap:round;stroke-linejoin:round}\n"
             << "    .plein{fill:#1a2332;stroke:#1a2332;stroke-width:2;"
             << "stroke-linejoin:round}\n"
             << "    .fil{fill:none;stroke:#334155;stroke-width:2;"
             << "stroke-linecap:round;stroke-linejoin:round}\n"
             // Liseré blanc derrière les textes : une étiquette peut tomber
             // sur un fil, elle reste lisible sans qu'il faille déplacer le
             // composant à la main.
             << "    .refc{fill:#1d4ed8;font-size:13px;font-weight:700;"
             << "stroke:#ffffff;stroke-width:3.5;paint-order:stroke}\n"
             << "    .valc{fill:#475569;font-size:12px;stroke:#ffffff;"
             << "stroke-width:3.5;paint-order:stroke}\n"
             << "    .marq{fill:#334155}\n"
             << "    .note{fill:#b45309;font-size:12.5px;stroke:#ffffff;"
             << "stroke-width:3.5;paint-order:stroke}\n"
             << "    .cadre{fill:#fffbeb;stroke:#f59e0b;stroke-width:1.2}\n"
             << "    .symtxt{fill:#1a2332;font-size:11px;stroke:#ffffff;"
             << "stroke-width:3;paint-order:stroke}\n"
             << "  </style>\n"
             << "  <text x=\"" << nombre(x0 + 16) << "\" y=\""
             << nombre(y0 + 26) << "\" class=\"titre\">" << echapper(titre)
             << "</text>\n"
             << corps_ << "</svg>\n";
        return flux.str();
    }

private:
    std::string corps_;
    double gauche_ = 1e9, droite_ = -1e9, haut_ = 1e9, bas_ = -1e9;
};

void dessiner_composant(Dessin& dessin, const Placement& placement) {
    const coeur::Modele* modele = modele_de(placement);
    if (!modele) {
        std::fprintf(stderr, "composant inconnu : %s\n", placement.type.c_str());
        return;
    }
    auto absolu = [&placement](const coeur::PointSymbole& p) {
        const Point local = tourner(p, placement.rotation);
        return Point{placement.x + local.x, placement.y + local.y};
    };

    // Carte réduite : on dessine soi-même le boîtier et les broches retenues,
    // au lieu du symbole complet du catalogue.
    const CarteReduite reduite = reduire(placement);
    if (reduite.active) {
        std::ostringstream boite;
        boite << "<rect x=\"" << nombre(placement.x - reduite.demi_largeur)
              << "\" y=\"" << nombre(placement.y - reduite.demi_hauteur)
              << "\" width=\"" << nombre(2 * reduite.demi_largeur)
              << "\" height=\"" << nombre(2 * reduite.demi_hauteur)
              << "\" rx=\"4\" class=\"trait\"/>";
        dessin.ajouter(boite.str());
        dessin.etendre(placement.x - reduite.demi_largeur,
                       placement.y - reduite.demi_hauteur);
        dessin.etendre(placement.x + reduite.demi_largeur,
                       placement.y + reduite.demi_hauteur);

        std::ostringstream nom_carte;
        nom_carte << "<text x=\"" << nombre(placement.x) << "\" y=\""
                  << nombre(placement.y - reduite.demi_hauteur + 20)
                  << "\" class=\"symtxt\" text-anchor=\"middle\" "
                  << "style=\"font-size:12px;font-weight:600\">"
                  << echapper(modele->libelle == "Carte Arduino Uno"
                                  ? "ARDUINO UNO"
                                  : modele->libelle)
                  << "</text>";
        dessin.ajouter(nom_carte.str());

        for (const auto& paire : reduite.bornes) {
            const Point p = {placement.x + paire.second.x,
                             placement.y + paire.second.y};
            const bool a_gauche = paire.second.x < 0;
            const double bord = placement.x +
                                (a_gauche ? -reduite.demi_largeur
                                          : reduite.demi_largeur);
            std::ostringstream patte;
            patte << "<line x1=\"" << nombre(p.x) << "\" y1=\"" << nombre(p.y)
                  << "\" x2=\"" << nombre(bord) << "\" y2=\"" << nombre(p.y)
                  << "\" class=\"trait\"/>"
                  << "<circle cx=\"" << nombre(p.x) << "\" cy=\"" << nombre(p.y)
                  << "\" r=\"2.6\" class=\"marq\"/>"
                  << "<text x=\"" << nombre(bord + (a_gauche ? 8 : -8))
                  << "\" y=\"" << nombre(p.y + 4) << "\" class=\"symtxt\" "
                  << "text-anchor=\"" << (a_gauche ? "start" : "end") << "\">"
                  << echapper(paire.first) << "</text>";
            dessin.ajouter(patte.str());
            dessin.etendre(p.x, p.y);
        }

        std::ostringstream reference;
        reference << "<text x=\"" << nombre(placement.x) << "\" y=\""
                  << nombre(placement.y - reduite.demi_hauteur - 9)
                  << "\" class=\"refc\" text-anchor=\"middle\">"
                  << echapper(placement.reference) << "</text>";
        dessin.ajouter(reference.str());
        dessin.etendre(placement.x, placement.y - reduite.demi_hauteur - 22);
        return;
    }

    for (const auto& trait : modele->symbole) {
        const char* classe = trait.rempli ? "plein" : "trait";
        std::ostringstream f;
        switch (trait.genre) {
            case coeur::TraitSymbole::Genre::Ligne: {
                if (trait.points.size() < 2) break;
                const Point a = absolu(trait.points[0]);
                const Point b = absolu(trait.points[1]);
                f << "<line x1=\"" << nombre(a.x) << "\" y1=\"" << nombre(a.y)
                  << "\" x2=\"" << nombre(b.x) << "\" y2=\"" << nombre(b.y)
                  << "\" class=\"trait\"/>";
                dessin.etendre(a.x, a.y);
                dessin.etendre(b.x, b.y);
                break;
            }
            case coeur::TraitSymbole::Genre::Rect: {
                if (trait.points.size() < 2) break;
                // La rotation d'un rectangle passe par ses quatre coins :
                // sinon un composant tourné de 90° garderait sa boîte droite.
                const coeur::PointSymbole coins[4] = {
                    trait.points[0],
                    {trait.points[1].x, trait.points[0].y},
                    trait.points[1],
                    {trait.points[0].x, trait.points[1].y}};
                f << "<polygon points=\"";
                for (int k = 0; k < 4; ++k) {
                    const Point p = absolu(coins[k]);
                    f << (k ? " " : "") << nombre(p.x) << "," << nombre(p.y);
                    dessin.etendre(p.x, p.y);
                }
                f << "\" class=\"" << classe << "\"/>";
                break;
            }
            case coeur::TraitSymbole::Genre::Cercle: {
                if (trait.points.empty()) break;
                const Point c = absolu(trait.points[0]);
                f << "<circle cx=\"" << nombre(c.x) << "\" cy=\"" << nombre(c.y)
                  << "\" r=\"" << nombre(trait.mesure) << "\" class=\"" << classe
                  << "\"/>";
                dessin.etendre(c.x - trait.mesure, c.y - trait.mesure);
                dessin.etendre(c.x + trait.mesure, c.y + trait.mesure);
                break;
            }
            case coeur::TraitSymbole::Genre::Polygone: {
                f << "<polygon points=\"";
                for (size_t k = 0; k < trait.points.size(); ++k) {
                    const Point p = absolu(trait.points[k]);
                    f << (k ? " " : "") << nombre(p.x) << "," << nombre(p.y);
                    dessin.etendre(p.x, p.y);
                }
                f << "\" class=\"" << classe << "\"/>";
                break;
            }
            case coeur::TraitSymbole::Genre::Texte: {
                if (trait.points.empty()) break;
                const Point p = absolu(trait.points[0]);
                f << "<text x=\"" << nombre(p.x) << "\" y=\"" << nombre(p.y)
                  << "\" class=\"symtxt\" style=\"font-size:"
                  << nombre(trait.mesure) << "px\">" << echapper(trait.texte)
                  << "</text>";
                dessin.etendre(p.x, p.y);
                break;
            }
        }
        if (!f.str().empty()) dessin.ajouter(f.str());
    }

    // Repères de bornes : de petits disques, comme sur un schéma d'atelier.
    for (const auto& borne : modele->bornes) {
        const Point p = absolu(borne.position);
        std::ostringstream f;
        f << "<circle cx=\"" << nombre(p.x) << "\" cy=\"" << nombre(p.y)
          << "\" r=\"2.6\" class=\"marq\"/>";
        dessin.ajouter(f.str());
    }

    // Référence au-dessus, valeur en dessous.
    double sommet = 1e9, fond = -1e9;
    for (const auto& borne : modele->bornes) {
        const Point p = absolu(borne.position);
        sommet = std::min(sommet, p.y);
        fond = std::max(fond, p.y);
    }
    for (const auto& trait : modele->symbole)
        for (const auto& point : trait.points) {
            const Point p = absolu(point);
            sommet = std::min(sommet, p.y - trait.mesure);
            fond = std::max(fond, p.y + trait.mesure);
        }

    const bool symbole_alimentation = !modele->noeud_impose.empty();
    if (!placement.reference.empty() && !symbole_alimentation) {
        std::ostringstream f;
        f << "<text x=\"" << nombre(placement.x) << "\" y=\""
          << nombre(sommet - 9) << "\" class=\"refc\" text-anchor=\"middle\">"
          << echapper(placement.reference) << "</text>";
        dessin.ajouter(f.str());
        dessin.etendre(placement.x, sommet - 22);
    }
    if (!placement.etiquette.empty()) {
        // Un composant couché porte sa valeur sur le côté, pas dessous :
        // sous un symbole vertical, elle tomberait sur ce qui suit dans la
        // branche — typiquement le symbole de masse.
        const bool couche =
            placement.rotation == 90 || placement.rotation == 270;
        double droite = -1e9;
        for (const auto& borne : modele->bornes)
            droite = std::max(droite, absolu(borne.position).x);
        for (const auto& trait : modele->symbole)
            for (const auto& point : trait.points)
                droite = std::max(droite, absolu(point).x + trait.mesure);

        std::ostringstream f;
        if (couche) {
            f << "<text x=\"" << nombre(droite + 10) << "\" y=\""
              << nombre(placement.y + 4) << "\" class=\"valc\">"
              << echapper(placement.etiquette) << "</text>";
            dessin.etendre(droite + 10 + 7.0 * placement.etiquette.size() * 0.62,
                           placement.y + 4);
        } else {
            f << "<text x=\"" << nombre(placement.x) << "\" y=\""
              << nombre(fond + 18) << "\" class=\"valc\" "
              << "text-anchor=\"middle\">"
              << echapper(placement.etiquette) << "</text>";
            dessin.etendre(placement.x, fond + 24);
        }
        dessin.ajouter(f.str());
    }
}

// Fil en équerre entre deux bornes : jamais de diagonale sur un schéma.
void dessiner_fil(Dessin& dessin, const std::map<std::string, Placement>& par_ref,
                  const Fil& fil) {
    auto a_it = par_ref.find(fil.de);
    auto b_it = par_ref.find(fil.vers);
    if (a_it == par_ref.end() || b_it == par_ref.end()) {
        std::fprintf(stderr, "fil vers un composant inconnu : %s -> %s\n",
                     fil.de.c_str(), fil.vers.c_str());
        return;
    }
    const Point a = borne_absolue(a_it->second, fil.borne_de);
    const Point b = borne_absolue(b_it->second, fil.borne_vers);

    std::ostringstream f;
    f << "<polyline points=\"" << nombre(a.x) << "," << nombre(a.y);
    if (std::fabs(a.y - b.y) > 0.5 && std::fabs(a.x - b.x) > 0.5) {
        // Coude : on part horizontalement, on tourne à mi-chemin.
        const double milieu = (a.x + b.x) / 2;
        f << " " << nombre(milieu) << "," << nombre(a.y) << " " << nombre(milieu)
          << "," << nombre(b.y);
        dessin.etendre(milieu, a.y);
        dessin.etendre(milieu, b.y);
    }
    f << " " << nombre(b.x) << "," << nombre(b.y) << "\" class=\"fil\"/>";
    dessin.ajouter(f.str());
    dessin.etendre(a.x, a.y);
    dessin.etendre(b.x, b.y);
}

void dessiner_note(Dessin& dessin, const Note& note) {
    std::ostringstream f;
    if (note.encadree) {
        const double largeur = 8.0 * note.texte.size() * 0.62 + 16;
        f << "<rect x=\"" << nombre(note.x - 8) << "\" y=\""
          << nombre(note.y - 15) << "\" width=\"" << nombre(largeur)
          << "\" height=\"22\" rx=\"4\" class=\"cadre\"/>";
        dessin.ajouter(f.str());
        dessin.etendre(note.x - 8, note.y - 15);
        dessin.etendre(note.x - 8 + largeur, note.y + 7);
        f.str("");
    }
    f << "<text x=\"" << nombre(note.x) << "\" y=\"" << nombre(note.y)
      << "\" class=\"note\">" << echapper(note.texte) << "</text>";
    dessin.ajouter(f.str());
    dessin.etendre(note.x, note.y);
    dessin.etendre(note.x + 7.0 * note.texte.size() * 0.62, note.y + 6);
}

void produire(const Figure& figure, const std::string& dossier) {
    Dessin dessin;
    std::map<std::string, Placement> par_ref;
    for (const Placement& placement : figure.composants)
        par_ref[placement.reference] = placement;

    // Les fils d'abord : ils passent sous les symboles.
    for (const Fil& fil : figure.fils) dessiner_fil(dessin, par_ref, fil);
    for (const Placement& placement : figure.composants)
        dessiner_composant(dessin, placement);
    for (const Note& note : figure.notes) dessiner_note(dessin, note);

    const std::string chemin = dossier + "/" + figure.fichier;
    std::ofstream sortie(chemin);
    if (!sortie) {
        std::fprintf(stderr, "écriture impossible : %s\n", chemin.c_str());
        return;
    }
    sortie << dessin.produire(figure.titre, figure.marge_droite);
    std::printf("  %s\n", figure.fichier.c_str());
}

std::vector<Figure> catalogue_figures();

}  // namespace

int main(int argc, char** argv) {
    const std::string dossier = argc > 1 ? argv[1] : ".";
    std::printf("Figures produites dans %s :\n", dossier.c_str());
    for (const Figure& figure : catalogue_figures()) produire(figure, dossier);
    return 0;
}

#include "figures_liste.inc"
