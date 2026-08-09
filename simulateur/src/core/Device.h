// Catalogue de composants.
//
// Décision d'architecture importante pour la suite : un composant porte
// DEUX représentations distinctes, dès maintenant.
//   * le SYMBOLE   : ce qu'on dessine sur le schéma (et ses bornes) ;
//   * l'EMPREINTE  : ce qu'on posera sur le circuit imprimé (pastilles).
// Le module PCB consomme cette préparation : la netlist fait le lien entre
// les deux (comme dans KiCad), et le nom de l'empreinte déclaré ici désigne
// un gabarit de la bibliothèque `core/pcb/Empreintes`.
//
// Ajouter un composant = décrire un Modele et l'enregistrer. Rien d'autre.
#pragma once

#include <cstdint>
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

// Empreinte : ce qu'on pose sur le circuit imprimé. Le modèle nomme son
// boîtier ; la bibliothèque d'empreintes le dessine aux cotes normalisées.
struct Pastille {
    std::string nom;          // doit correspondre au nom d'une borne
    double x = 0, y = 0;      // en millimètres
    double diametre = 1.6;
    double percage = 0.8;     // 0 = composant monté en surface

    // Ce qui suit distingue une empreinte crédible d'une rangée de ronds.
    // Sur une vraie carte, la broche 1 est carrée — c'est le repère qu'on
    // cherche des yeux quand on soude —, une pastille de connecteur est
    // souvent oblongue, et le numéro de broche est sérigraphié.
    enum class Forme { Ronde, Rectangulaire, Oblongue };
    Forme forme = Forme::Ronde;
    double hauteur = 0;       // 0 : pastille de côté `diametre`
    int numero = 0;           // numéro physique ; 0 = non numérotée

    Pastille() = default;
    Pastille(std::string nom_, double x_, double y_, double diametre_,
             double percage_)
        : nom(std::move(nom_)), x(x_), y(y_), diametre(diametre_),
          percage(percage_) {}
};

// Trait de sérigraphie : le dessin blanc imprimé sur le vernis, qui montre
// où pose le corps du composant. En millimètres, relatif au centre.
struct TraitEmpreinte {
    enum class Genre { Ligne, Cercle, Rect };
    Genre genre = Genre::Ligne;
    double x1 = 0, y1 = 0;    // Cercle : centre
    double x2 = 0, y2 = 0;    // Cercle : x2 = rayon
};

struct Empreinte {
    std::string nom;                    // "R_AXIAL_0207", "LED_5MM"…
    std::vector<Pastille> pastilles;
    double largeur = 0, hauteur = 0;    // encombrement, en millimètres
    std::vector<TraitEmpreinte> serigraphie;

    Empreinte() = default;
    Empreinte(std::string nom_, std::vector<Pastille> pastilles_,
              double largeur_, double hauteur_,
              std::vector<TraitEmpreinte> serigraphie_ = {})
        : nom(std::move(nom_)), pastilles(std::move(pastilles_)),
          largeur(largeur_), hauteur(hauteur_),
          serigraphie(std::move(serigraphie_)) {}
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

// --- composants numériques -------------------------------------------------
//
// Un 74HC595 ne se décrit pas par une équation : il réagit à des fronts. Le
// modéliser en analogique demanderait un pas de calcul si fin que la
// simulation deviendrait inutilisable — alors que ses entrées, elles, sont
// déjà datées au cycle d'horloge près par le microcontrôleur.
//
// D'où ce troisième moteur : on lui donne les événements de la fenêtre, il
// rend ceux de ses sorties, et ceux-ci redeviennent des sources linéaires par
// morceaux dans le même circuit analogique. Rien n'est approximé au passage —
// une horloge à 4 MHz est traitée aussi exactement qu'une à 1 Hz.
struct EvenementNumerique {
    double instant = 0;        // en secondes, depuis le début de la fenêtre
    std::string borne;
    bool haut = false;
};

struct EntreesNumeriques {
    double duree = 0;
    // Niveau de chaque borne au début de la fenêtre.
    std::map<std::string, bool> niveaux;
    // Événements des entrées, triés par instant.
    std::vector<EvenementNumerique> evenements;

    // Niveau d'une borne à un instant donné, événements compris.
    bool niveau_a(const std::string& borne, double instant) const;
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
    Empreinte empreinte;                // nom du boîtier, pour la carte

    // Composant qui s'allume : l'interface teinte son corps selon le courant
    // calculé par ngspice (LED, lampe, afficheur…).
    bool lumineux = false;
    double courant_nominal = 0.02;      // courant qui donne l'éclat maximal
    std::string couleur_corps = "#c8c8c8";

    // Carte programmable : ses bornes ne sont pas des composants SPICE, ce
    // sont les broches du microcontrôleur pilotées par le firmware.
    bool carte = false;

    // Microcontrôleur porté par la carte, tel que l'attend avr-gcc :
    // « atmega328p ». C'est lui qui décide du jeu d'instructions compilé.
    std::string mcu;
    // Fréquence d'horloge, en hertz : le quartz de la carte.
    uint32_t horloge = 16000000;
    // Le programme proposé quand on pose la carte. Une carte Arduino reçoit
    // un croquis (setup / loop, pinMode, digitalWrite) ; un microcontrôleur
    // nu reçoit du C sur registres, parce que c'est ainsi qu'on le programme
    // réellement. Le style suit le contrôleur, il n'est pas imposé d'en haut.
    std::string programme_exemple;
    // Ce qui s'écrit dans l'éditeur pour cette carte, tel qu'affiché sur
    // l'onglet : « Arduino » pour un croquis, « C (registres) » pour une puce
    // nue. Deux mots qui évitent de chercher pourquoi digitalWrite n'existe
    // pas là où il n'a rien à faire.
    std::string langage = "Arduino";

    // Symbole d'alimentation : impose le nom du nœud auquel il est relié
    // ("GND", "5V"). Ne produit aucune ligne SPICE.
    std::string noeud_impose;

    // Étiquette de nœud : le nom vient d'une propriété de l'instance, pas du
    // modèle. Deux étiquettes portant le même nom désignent le même nœud —
    // c'est ce qui permet de relier deux points sans tirer de fil à travers
    // toute la feuille.
    std::string noeud_depuis_texte;

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

    // Composant numérique : réagit aux fronts de ses entrées et produit ceux
    // de ses sorties. L'état interne vit dans l'instance.
    std::function<std::vector<EvenementNumerique>(Instance&,
                                                  const EntreesNumeriques&)>
        reagir;
    // Bornes qui sont des sorties pilotées par `reagir` : elles deviennent des
    // sources dans le circuit, et ne doivent donc pas être lues comme des
    // entrées.
    std::vector<std::string> sorties_numeriques;
    double impedance_sortie = 100.0;    // ohms, résistance série des sorties

    // Grandeur à afficher sur le schéma pendant la simulation (« 90° »,
    // « 1450 tr/min »). Vide si le composant n'a rien à montrer.
    std::function<std::string(const Instance&)> lecture;

    // Instrument de mesure : ce qu'il affiche ne vient pas d'un état interne
    // mais du circuit résolu. C'est ce qui distingue un voltmètre d'un
    // servomoteur : l'un lit, l'autre se souvient.
    //
    // Un multimètre réel ne montre pas la valeur instantanée : en continu il
    // affiche la moyenne, en alternatif la valeur efficace de la partie
    // variable. Il lui faut donc l'histoire de la dernière fenêtre, pas
    // seulement le dernier point — d'où les formes d'onde.
    struct Lecture {
        std::function<double(const std::string& borne)> tension;   // instantané
        double courant = 0;                                        // instantané
        const std::vector<double>* temps = nullptr;                // peut être nul
        std::function<const std::vector<double>*(const std::string& borne)>
            forme_tension;
        const std::vector<double>* forme_courant = nullptr;
    };
    std::function<std::string(const Instance&, const Lecture&)> mesure_instrument;

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
