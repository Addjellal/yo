// Module de circuit imprimé.
//
// La place lui était réservée depuis le premier jour : chaque composant du
// catalogue porte DEUX représentations, le symbole pour le schéma et
// l'empreinte pour la carte, et la netlist fait le lien entre les deux. Ce
// fichier consomme enfin cette préparation.
//
// Ce qu'il fait : placer les empreintes, dire quelles pastilles doivent être
// reliées (le chevelu), accepter des pistes, vérifier les distances (DRC), et
// produire les fichiers que réclame un fabricant — Gerber pour le cuivre,
// Excellon pour les perçages.
//
// Ce qu'il ne fait pas : router tout seul. Le tracé reste manuel, comme dans
// tout atelier sérieux où l'auto-routeur sert de point de départ, pas de
// livraison.
#pragma once

#include <string>
#include <vector>

#include "core/Device.h"
#include "core/Netlist.h"

namespace coeur {

// Une pastille posée sur la carte, coordonnées absolues en millimètres.
struct PastillePosee {
    std::string composant;    // « R1 »
    std::string borne;        // « 1 »
    std::string net;          // nœud auquel elle appartient
    double x = 0, y = 0;
    double diametre = 1.6;
    double percage = 0.8;     // 0 = montage en surface
    Pastille::Forme forme = Pastille::Forme::Ronde;
    double hauteur = 0;       // 0 : pastille de côté `diametre`
    int numero = 0;           // numéro physique de broche
    double rotation = 0;      // orientation héritée du composant, en degrés

    // Trou de fixation : il se perce mais ne se soude pas. Ni cuivre, ni net,
    // ni point de départ pour une piste.
    bool mecanique() const { return numero == 0 && borne.empty(); }
};

// Un composant placé : son empreinte, sa position, son orientation.
struct ComposantPose {
    std::string reference;
    std::string type;
    std::string empreinte;
    double x = 0, y = 0;
    double rotation = 0;      // en degrés, multiples de 90 en pratique
    double largeur = 0, hauteur = 0;
    std::vector<PastillePosee> pastilles;   // relatives, avant placement
    std::vector<TraitEmpreinte> serigraphie;   // idem : relative au centre
};

// Une piste de cuivre, d'un point à un autre, sur une couche.
struct Piste {
    std::string net;
    double x1 = 0, y1 = 0, x2 = 0, y2 = 0;
    double largeur = 0.4;     // mm
    int couche = 0;           // 0 = dessus, 1 = dessous
};

class CartePcb {
public:
    // Construit une carte à partir de la netlist : une empreinte par
    // composant, placée en grille. C'est le point de départ ; le placement se
    // reprend ensuite à la main.
    static CartePcb depuis_netlist(const Netlist& netlist);

    // Pastilles en coordonnées absolues, rotation appliquée.
    std::vector<PastillePosee> pastilles() const;

    // Chevelu : les liaisons qu'il reste à router. Pour chaque net, on relie
    // les pastilles de proche en proche — c'est l'arbre le plus court, et
    // c'est ce que montre tout logiciel de routage.
    struct Liaison {
        std::string net;
        double x1 = 0, y1 = 0, x2 = 0, y2 = 0;
        bool routee = false;
    };
    std::vector<Liaison> chevelu() const;

    // Contrôle des règles de fabrication : distance entre cuivres de nets
    // différents, largeur minimale, débordement de la carte.
    struct AnomaliePcb {
        std::string message;
        double x = 0, y = 0;
    };
    std::vector<AnomaliePcb> controler(double isolation = 0.2,
                                       double largeur_mini = 0.15) const;

    // --- fichiers de fabrication -------------------------------------------
    // Gerber RS-274X d'une couche de cuivre.
    std::string gerber(int couche) const;
    // Contour de la carte, couche mécanique.
    std::string gerber_contour() const;
    // Sérigraphie de la face composants : les contours blancs et les repères.
    std::string gerber_serigraphie() const;
    // Perçages, format Excellon.
    std::string excellon() const;

    std::vector<ComposantPose> composants;
    std::vector<Piste> pistes;
    double largeur = 100.0, hauteur = 80.0;   // mm

    // Déplace un composant (le placement est manuel).
    void deplacer(const std::string& reference, double x, double y);
    ComposantPose* trouver(const std::string& reference);

    // Une liaison est routée si des pistes du même net relient ses deux
    // extrémités, de proche en proche.
    bool reliees(double x1, double y1, double x2, double y2,
                 const std::string& net) const;

    // Ajuste le contour au placement : une carte se découpe à la taille de ce
    // qu'elle porte, avec une marge de garde.
    void ajuster_contour(double marge = 5.0);
};

// Sérigraphie d'un composant, placée et tournée.
std::vector<TraitEmpreinte> serigraphie_absolue(const ComposantPose& pose);

}  // namespace coeur
