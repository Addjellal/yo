// Catalogue de composants.
//
// Décision d'architecture importante pour la suite : un composant porte
// DEUX représentations distinctes, dès maintenant.
//   * le SYMBOLE   : ce qu'on dessine sur le schéma (et ses bornes) ;
//   * l'EMPREINTE  : ce qu'on posera sur le circuit imprimé (pastilles).
// Le futur module PCB n'aura donc rien à casser : la place est déjà prévue,
// et la netlist fait le lien entre les deux (comme dans KiCad).
//
// Ajouter un composant = décrire un Modele et l'enregistrer. Rien d'autre.
#pragma once

#include <functional>
#include <map>
#include <string>
#include <vector>

namespace coeur {

class Netlist;
struct Instance;

// --- géométrie du symbole (unités : dixièmes de millimètre à l'écran) -----
struct PointSymbole {
    double x = 0, y = 0;
};

struct BorneSymbole {
    std::string nom;          // "A", "K", "1"…
    PointSymbole position;    // par rapport au centre du symbole
    std::string libelle;      // texte affiché à côté (facultatif)
};

// --- dessin du symbole, décrit en données -------------------------------
// Le tracé n'est pas du code : c'est une liste de figures. Conséquence
// directe, ajouter un composant reste un bloc de description, sans jamais
// toucher au code de l'interface graphique.
struct TraitSymbole {
    enum class Genre { Ligne, Rect, Cercle, Polygone, Texte };
    Genre genre = Genre::Ligne;
    std::vector<PointSymbole> points;   // Ligne : 2 pts ; Rect : 2 coins ;
                                        // Cercle : centre ; Polygone : n pts ;
                                        // Texte : point d'ancrage
    double mesure = 0;                  // rayon (Cercle) ou taille (Texte)
    std::string texte;
    bool rempli = false;
};

// Empreinte : réservée au module PCB. Vide pour l'instant sur la plupart
// des modèles, mais le champ existe pour ne pas avoir à tout reprendre.
struct Pastille {
    std::string nom;          // doit correspondre au nom d'une borne
    double x = 0, y = 0;      // en millimètres
    double diametre = 1.6;
    double percage = 0.8;     // 0 = composant monté en surface
};

struct Empreinte {
    std::string nom;                    // "R_AXIAL_0207", "LED_5MM"…
    std::vector<Pastille> pastilles;
    double largeur = 0, hauteur = 0;    // encombrement, en millimètres
};

// --- description d'une propriété réglable ---------------------------------
struct Propriete {
    enum class Genre { Nombre, Choix, Curseur };
    std::string cle;                    // "ohms", "couleur"…
    std::string libelle;                // "Valeur (Ω)"
    Genre genre = Genre::Nombre;
    double defaut = 0;
    double mini = 0, maxi = 0;          // pour Curseur
    std::string defaut_texte;
    std::vector<std::string> choix;     // pour Choix
    std::string unite;
};

// --- évolution d'un composant à état ---------------------------------------
//
// Un servomoteur, un moteur ou un capteur à échos ne se décrivent pas par une
// équation électrique : ils ont une mécanique interne qui avance dans le
// temps. Après chaque fenêtre de calcul, on leur donne à lire *ce que le
// circuit leur a fait subir* — les formes d'onde de leurs bornes — et ils
// mettent à jour leur état.
//
// C'est ce qui referme la boucle : l'état sert à produire le circuit de la
// fenêtre suivante, où le composant redevient une source ou une charge.
struct Evolution {
    double duree = 0.0;                      // durée de la fenêtre, en secondes
    const std::vector<double>* temps = nullptr;

    // Tension d'une borne au fil de la fenêtre. Nul si la borne n'est pas
    // connectée ou si le nœud n'a pas été relevé.
    std::function<const std::vector<double>*(const std::string& borne)> tension;
    // Courant traversant ce composant, quand la question a un sens.
    std::function<const std::vector<double>*()> courant;

    // Raccourcis courants, calculés à la demande.
    double moyenne(const std::string& borne) const;
    // Largeur de la dernière impulsion haute complète, en secondes. C'est ce
    // que décode un servomoteur. Renvoie 0 s'il n'y en a pas.
    double largeur_impulsion(const std::string& borne, double seuil = 2.5) const;
    // Proportion du temps passé au-dessus du seuil.
    double rapport_cyclique(const std::string& borne, double seuil = 2.5) const;
};

// --- modèle de composant --------------------------------------------------
struct Modele {
    std::string type;                   // identifiant interne : "resistance"
    std::string libelle;                // "Résistance"
    std::string categorie;              // "Passifs", "Affichage", "Entrées"…
    std::string prefixe = "U";          // pour les références : R1, LED2…
    std::vector<BorneSymbole> bornes;
    std::vector<Propriete> proprietes;
    std::vector<TraitSymbole> symbole;  // tracé ; si vide, un cadre est dessiné
    Empreinte empreinte;                // pour le futur module PCB

    // Composant qui s'allume : l'interface teinte son corps selon le courant
    // calculé par ngspice (LED, lampe, afficheur…).
    bool lumineux = false;
    double courant_nominal = 0.02;      // courant qui donne l'éclat maximal
    std::string couleur_corps = "#c8c8c8";

    // Carte programmable : ses bornes ne sont pas des composants SPICE, ce
    // sont les broches du microcontrôleur pilotées par le firmware.
    bool carte = false;

    // Symbole d'alimentation : impose le nom du nœud auquel il est relié
    // ("GND", "5V"). Ne produit aucune ligne SPICE.
    std::string noeud_impose;

    // Générateur : le composant impose une tension au lieu de la subir. En
    // mettre deux en série ou les court-circuiter n'a pas de sens physique,
    // et les bancs d'essai automatiques doivent le savoir.
    bool generateur = false;

    // Génère les lignes SPICE de ce composant. `noeud` traduit un nom de
    // borne en nom de nœud SPICE. Renvoyer plusieurs lignes est autorisé
    // (un potentiomètre = deux résistances, une LED = diode + modèle…).
    std::function<std::vector<std::string>(
        const Instance&, const std::function<std::string(const std::string&)>&)>
        vers_spice;

    // Variante appelée en analyse transitoire, quand le composant doit
    // produire une source qui dépend du temps — l'écho d'un télémètre, les
    // voies d'un codeur. `duree` est la longueur de la fenêtre.
    std::function<std::vector<std::string>(
        const Instance&, const std::function<std::string(const std::string&)>&,
        double duree)>
        vers_spice_transitoire;

    // Fait avancer l'état interne. Appelé après chaque résolution.
    std::function<void(Instance&, const Evolution&)> evoluer;

    // Grandeur à afficher sur le schéma pendant la simulation (« 90° »,
    // « 1450 tr/min »). Vide si le composant n'a rien à montrer.
    std::function<std::string(const Instance&)> lecture;

    // Directives .model / sous-circuits à émettre une seule fois.
    std::vector<std::string> directives;
};

class Catalogue {
public:
    static Catalogue& instance();

    void enregistrer(Modele modele);
    const Modele* modele(const std::string& type) const;
    std::vector<const Modele*> tous() const;
    std::vector<std::string> categories() const;

private:
    Catalogue() { enregistrer_modeles_standards(); }
    void enregistrer_modeles_standards();
    std::map<std::string, Modele> modeles_;
};

}  // namespace coeur
