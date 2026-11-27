// EditionLigne.h — l'édition de la ligne de commande dans un terminal.
//
// La console lisait par std::getline : les flèches écrivaient « ^[[A »,
// rien ne se rappelait, rien ne se complétait. Ce qui suit lui donne ce
// que la fenêtre de commandes de MATLAB offre au clavier, sans
// bibliothèque :
//
//   ← → Début Fin, Ctrl-A Ctrl-E    se déplacer ; Ctrl-← Ctrl-→ par mot
//   Retour arrière, Suppr           effacer
//   Ctrl-K, Ctrl-U, Ctrl-W          couper jusqu'au bout, au début, le mot
//   ↑ ↓                             l'historique ; filtré par ce qu'on a
//                                   déjà tapé, comme dans MATLAB : « pl »
//                                   puis ↑ rappelle le dernier « plot(...) »
//   Tab                             compléter un nom, un champ, un fichier
//                                   entre apostrophes, aussi loin que les
//                                   choix s'accordent ; au-delà, les montrer
//   Échap                           effacer la ligne, comme dans MATLAB
//   Ctrl-C                          abandonner la ligne
//   Ctrl-D                          sur une ligne vide : fin de la session
//   Ctrl-L                          effacer l'écran
//
// Trois pièces, dont deux sans terminal, pour qu'on puisse les éprouver :
// le décodeur fait des octets lus des touches, l'éditeur fait des touches
// une ligne, un curseur et ce qu'il faut écrire pour la montrer ; le
// lecteur, seul à parler au système, met le terminal en mode brut le
// temps de lire une ligne — POSIX par termios, Windows par les séquences
// VT de sa console — et retombe sur std::getline quand l'entrée n'est
// pas un terminal.
#pragma once

#include <cstddef>
#include <functional>
#include <memory>
#include <string>
#include <vector>

namespace matlibre {

enum class Touche {
    Texte,          // un caractère imprimable, en UTF-8 dans « texte »
    Entree,
    Gauche, Droite, Haut, Bas, Debut, Fin, MotGauche, MotDroite,
    RetourArriere, Supprimer,
    CouperFin,      // Ctrl-K
    CouperDebut,    // Ctrl-U
    CouperMot,      // Ctrl-W
    Tabulation,
    Echap,
    Interrompre,    // Ctrl-C
    FinFichier,     // Ctrl-D
    EffacerEcran,   // Ctrl-L
    Ignoree,        // une séquence reconnue mais sans effet (F1, Inser...)
};

struct Evenement {
    Touche touche = Touche::Ignoree;
    std::string texte;
};

// Des octets aux touches. Les terminaux codent les flèches et leurs
// voisines en séquences d'échappement — « ESC [ A », « ESC O H »,
// « ESC [ 3 ~ », « ESC [ 1 ; 5 C » avec Ctrl — et les caractères hors
// ASCII en plusieurs octets d'UTF-8. On pousse les octets un à un ; une
// séquence commencée attend sa fin.
class DecodeurTouches {
public:
    // Ajoute à SORTIE les événements que l'octet achève : aucun au milieu
    // d'une séquence, un le plus souvent, deux quand un ESC suivi d'une
    // lettre ordinaire se révèle être la touche Échap, puis la lettre.
    void pousser(unsigned char octet, std::vector<Evenement>& sortie);
    // Vrai quand une séquence est entamée : un ESC seul attend de savoir
    // s'il est la touche Échap ou le début d'une flèche.
    bool enCours() const { return !tampon_.empty(); }
    // L'attente est finie sans suite : ce qui était entamé est une touche
    // Échap (ou rien, pour un caractère UTF-8 tronqué).
    bool vider(Evenement& e);

private:
    bool decoder(unsigned char octet, Evenement& e);
    std::string tampon_;
    std::size_t utf8Attendus_ = 0;
    bool relire_ = false;
    bool apresCR_ = false;
};

class EditeurLigne {
public:
    enum class Issue { Continuer, Valider, Abandonner, Fin };

    // Les complétions du mot qui finit au curseur. La fonction rend les
    // mots complets, et pose dans « debut » l'octet où le mot commence.
    using Completeur = std::function<std::vector<std::string>(
        const std::string& ligne, std::size_t curseur, std::size_t& debut)>;

    void definirCompleteur(Completeur c) { completeur_ = std::move(c); }

    // Une ligne neuve, sous cette invite, qui porte déjà TEXTE (la
    // commande corrigée d'un « Did you mean: », par exemple).
    void commencer(const std::string& invite, const std::string& texte = std::string());
    Issue traiter(const Evenement& e);

    const std::string& ligne() const { return ligne_; }
    std::size_t curseur() const { return curseur_; }   // en octets
    const std::string& invite() const { return invite_; }

    // Ce qu'il faut écrire pour montrer la ligne et placer le curseur, sur
    // un terminal de LARGEUR colonnes. Une ligne plus large défile
    // horizontalement autour du curseur au lieu de déborder.
    std::string rendu(int largeur);
    // Les choix qu'un second Tab demande de montrer ; vide sinon. Lire
    // la liste la vide.
    std::vector<std::string> prendreChoix();
    // Vrai quand l'écran doit être effacé (Ctrl-L) ; lire le remet à faux.
    bool prendreEffacement();

    // --- historique ---
    void ajouterHistorique(const std::string& ligne);
    const std::vector<std::string>& historique() const { return historique_; }
    void definirHistorique(std::vector<std::string> h);

private:
    void inserer(const std::string& texte);
    void remplacerLigne(const std::string& texte);
    void rappeler(int sens);
    void completer();

    std::string invite_;
    std::string ligne_;
    std::size_t curseur_ = 0;
    std::size_t debutVue_ = 0;       // premier caractère montré, en points de code

    std::vector<std::string> historique_;
    // Pendant qu'on parcourt l'historique : la position (historique_.size()
    // quand on n'y est pas), et ce qu'on avait tapé, qui sert de filtre et
    // revient au bas de la liste.
    std::size_t indexHistorique_ = 0;
    std::string tape_;
    bool dansHistorique_ = false;

    Completeur completeur_;
    std::vector<std::string> choix_;
    bool effacerEcran_ = false;
};

// Lit des lignes au clavier. Un seul par processus : il tient l'état du
// terminal, l'historique et ce qui a été tapé d'avance.
class LecteurLignes {
public:
    enum class Resultat { Ligne, Abandon, FinFichier };

    LecteurLignes();
    ~LecteurLignes();
    LecteurLignes(const LecteurLignes&) = delete;
    LecteurLignes& operator=(const LecteurLignes&) = delete;

    // Vrai quand l'entrée et la sortie sont un terminal que l'on sait
    // piloter : sinon « lire » se contente de std::getline.
    bool editionPossible() const;

    // Lit une ligne sous INVITE. TEXTEINITIAL est posé dans la saisie,
    // prêt à être exécuté ou modifié ; il est ignoré sans édition.
    Resultat lire(const std::string& invite, std::string& ligne,
                  const std::string& texteInitial = std::string());

    void definirCompleteur(EditeurLigne::Completeur c);
    // L'historique se relit d'un fichier et s'y ajoute ligne à ligne ;
    // un chemin vide n'enregistre rien.
    void ouvrirHistorique(const std::string& chemin);
    void retenir(const std::string& ligne);

    // Le fichier d'historique par défaut : MATLIBRE_HISTORIQUE s'il est
    // posé (vide : aucun), sinon « .matlibre_historique » dans le dossier
    // personnel.
    static std::string cheminHistoriqueParDefaut();

    struct Etat;   // l'état du terminal, propre à chaque système

private:
    std::unique_ptr<Etat> etat_;
};

}  // namespace matlibre
