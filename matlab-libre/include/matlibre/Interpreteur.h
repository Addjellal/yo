// Interpreteur.h — exécution de l'arbre syntaxique.
//
// L'interpréteur tient les espaces de travail (pile de portées), la table
// des fonctions natives, l'index des fichiers .m visibles sur le chemin de
// recherche, et l'état global visible par l'utilisateur (format
// d'affichage, générateur aléatoire, dernier message d'erreur).
#pragma once

#include <atomic>
#include <functional>
#include <iosfwd>
#include <map>
#include <memory>
#include <random>
#include <set>
#include <string>
#include <tuple>
#include <unordered_map>
#include <vector>

#include "matlibre/Arbre.h"
#include "matlibre/Erreur.h"
#include "matlibre/Deboguage.h"
#include "matlibre/Valeur.h"

namespace matlibre {

struct EntreeNative {
    Builtin fonction = nullptr;
    std::string aide;
    std::string groupe;
};

struct Portee;

struct Portee {
    std::unordered_map<std::string, Valeur> variables;
    std::set<std::string> globales;
    std::map<std::string, std::string> liensPersistants;  // nom local -> clé globale
    std::string nomFonction;
    int nargin = 0;
    int nargout = 0;
    std::shared_ptr<FonctionUtilisateur> fonction;
    // Portée de la fonction englobante : une fonction imbriquée lit et écrit
    // les variables de son parent à travers ce chaînage.
    std::shared_ptr<Portee> englobante;
    // Vraie pour l'activation d'une fonction anonyme : sa table n'est qu'une
    // copie de la capture, ce n'est pas là que vivent les variables partagées.
    bool anonyme = false;
};

enum class Format { Court, Long, CourtE, LongE, CourtG, LongG, Hex, Rationnel, Plus, Banque };

struct Figure;  // Graphique.h

// Un composant d'interface : ce que pose uifigure, uibutton, uislider…
// Une interface lit cette table pour dessiner la fenêtre, et renvoie les
// événements qui déclenchent les rappels.
struct ComposantInterface {
    long long id = 0;
    long long parent = 0;
    std::string type;
    std::string texte;
    std::vector<double> position;   // [x y largeur hauteur]
    Valeur valeur;
    std::vector<std::string> items;
    double minimum = 0.0;
    double maximum = 1.0;
    bool actif = true;
    bool visible = true;
    Valeur rappel;
    std::map<std::string, Valeur> autres;
};

// Table associative de « containers.Map ». Elle vit dans l'interpréteur et
// non dans la valeur : c'est ce qui donne à containers.Map sa sémantique de
// poignée, où toutes les copies désignent la même table.
struct CarteAssociative {
    std::vector<std::string> ordre;                 // clés triées
    std::map<std::string, Valeur> valeurs;
    std::map<std::string, Valeur> clesOriginales;
    std::string typeCle = "char";
    std::string typeValeur = "any";
};

class Interpreteur {
public:
    Interpreteur();
    ~Interpreteur();

    // --- mise en route ---
    void installerBibliotheque();
    void ajouterChemin(const std::string& dossier, bool enTete = true);
    void retirerChemin(const std::string& dossier);
    const std::vector<std::string>& chemin() const { return chemin_; }
    void reindexerChemin();
    std::string racineToolbox() const { return racineToolbox_; }
    void definirRacineToolbox(const std::string& r) { racineToolbox_ = r; }

    // --- exécution ---
    void executerTexte(const std::string& source, const std::string& origine);
    void executerFichier(const std::string& fichier);
    void executerBloc(const NoeudPtr& b);
    void executerInstruction(const NoeudPtr& n);

    // --- évaluation ---
    Valeur evaluer(const NoeudPtr& n);
    std::vector<Valeur> evaluerMulti(const NoeudPtr& n, int nargout);
    std::vector<Valeur> evaluerListe(const std::vector<NoeudPtr>& args);

    // --- appels ---
    std::vector<Valeur> appeler(const std::string& nom, std::vector<Valeur> args, int nargout);
    std::vector<Valeur> appelerValeur(const Valeur& poignee, std::vector<Valeur> args,
                                      int nargout);
    std::vector<Valeur> appelerUtilisateur(const std::shared_ptr<FonctionUtilisateur>& f,
                                           std::vector<Valeur>& args, int nargout);
    bool fonctionExiste(const std::string& nom) const;
    std::shared_ptr<Fonction> resoudrePoignee(const std::string& nom);

    // --- espace de travail ---
    Portee& portee() { return *piles_.back(); }
    const Portee& portee() const { return *piles_.back(); }
    Portee& porteeBase() { return *piles_.front(); }
    const Portee& porteeNumero(int k) const { return *piles_[(std::size_t)k]; }
    Portee& porteeAppelante();
    bool existeVariable(const std::string& nom) const;
    const Valeur* trouverVariable(const std::string& nom) const;
    Valeur lireVariable(const std::string& nom) const;
    void ecrireVariable(const std::string& nom, Valeur v);
    void effacerVariable(const std::string& nom);
    std::vector<std::string> nomsVariables() const;
    int profondeur() const { return (int)piles_.size(); }

    // --- table des fonctions ---
    void enregistrer(const std::string& nom, Builtin f, const std::string& groupe,
                     const std::string& aide);
    const EntreeNative* natif(const std::string& nom) const;
    std::vector<std::string> nomsNatifs() const;
    std::shared_ptr<FonctionUtilisateur> fonctionFichier(const std::string& nom);
    const std::map<std::string, std::string>& indexFichiers() const { return indexM_; }
    std::shared_ptr<DefinitionClasse> classeDefinie(const std::string& nom);

    // --- sorties ---
    // Posé par une interface graphique : « clc » l'appelle au lieu
    // d'écrire une séquence ANSI que la fenêtre afficherait telle quelle.
    // Ctrl-C : le fil graphique, ou le gestionnaire de signal de la
    // console, leve ce drapeau ; l'interprete s'arrete au prochain point
    // de controle. Il est atomique parce que deux fils y touchent.
    std::atomic<bool> interruption{false};
    // A appeler dans le fil qui execute, au debut de chaque commande de
    // l'utilisateur : le drapeau devient celui de ce fil, et il est remis
    // a zero. Sans cette remise a zero, un Ctrl-C arrive juste apres la
    // fin d'un calcul coupait la commande suivante — MATLAB, lui, oublie
    // un Ctrl-C qui n'a rien trouve a interrompre.
    void armerInterruption() {
        interruption.store(false, std::memory_order_relaxed);
        poserDrapeauInterruption(&interruption);
    }
    // Pose le drapeau sans l'effacer : pour les entrees imbriquees — un
    // script qui en lance un autre — qui ne doivent pas annuler un Ctrl-C
    // deja demande.
    void suivreInterruption() { poserDrapeauInterruption(&interruption); }
    void demanderArret() { interruption.store(true, std::memory_order_relaxed); }

    std::function<void()> effacerEcran;
    // « doc nom » : le bureau ouvre son navigateur d'aide. Sans crochet,
    // « doc » imprime la documentation dans la console.
    std::function<void(const std::string& nom)> crochetDocumentation;

    std::ostream& sortie();
    std::ostream& erreurSortie();
    void definirSortie(std::ostream* s) { sortie_ = s; }
    void ouvrirJournal(const std::string& fichier);
    void fermerJournal();

    // --- état visible par l'utilisateur ---
    // MatLibre montre par défaut tous les chiffres que la valeur porte —
    // « pi » s'écrit 3.141592653589793, un single 3.1415927. MATLAB, lui,
    // démarre en « format short » et n'en montre que quatre décimales :
    // c'est le seul écart, et « format short » le rétablit.
    Format format = Format::Long;
    bool formatCompact = false;
    std::mt19937_64 generateur{5489u};
    std::string dernierIdentifiant;
    std::string dernierMessage;
    Valeur derniereErreur;
    std::set<std::string> avertissementsEteints;
    bool avertissementsActifs = true;
    std::map<int, std::shared_ptr<Figure>> figures;
    int figureCourante = 0;
    std::map<std::string, Valeur> persistantes;
    std::unordered_map<std::string, Valeur> globales;
    long long compteurAppels = 0;
    bool modeInteractif = false;
    std::string fichierCourant;   // fichier en cours, pour mfilename

    // Pile d'exécution : le nom, le fichier et la ligne de chaque cadre.
    // Tenue en permanence — une écriture d'entier par instruction — pour
    // que le message d'erreur puisse dire dans quel fichier et à quelle
    // ligne le calcul s'est arrêté, comme le fait MATLAB.
    std::vector<CadreErreur> cadres;

    // --- profileur et débogueur (Deboguage.h) ---
    Profil profil;
    Debogueur debogueur;
    // Appelé avant chaque instruction quand le débogueur est armé. Rend la
    // main quand l'utilisateur reprend l'exécution.
    std::function<void(Interpreteur&, const std::string& fichier, int ligne)> crochetArret;

    // --- objets et classes (Objets.cpp) ---
    std::shared_ptr<DefinitionClasse> classeDe(const Valeur& v);
    bool classePossede(const Valeur& v, const std::string& methode);
    // Vrai quand le code en cours d'exécution est une méthode de « classe » :
    // MATLAB n'appelle alors ni subsref ni subsasgn, l'indexation à
    // l'intérieur d'une méthode reste celle du langage.
    bool dansMethodeDe(const std::string& classe) const;
    std::vector<Valeur> appelerMethode(const Valeur& objet, const std::string& methode,
                                       std::vector<Valeur> args, int nargout);
    Valeur concatenerObjets(const std::vector<std::vector<Valeur>>& rangees);
    std::size_t nomPointe(const std::string& nom, const std::vector<ElementAcces>& acces);
    std::string fichierExecute() const;
    Valeur substruct(const std::vector<ElementAcces>& chaine, std::size_t debut,
                     const Valeur* base);
    Valeur lireProprieteObjet(const Valeur& objet, const std::string& nom);
    Valeur ecrireProprieteObjet(Valeur objet, const std::string& nom, const Valeur& valeur);
    bool estCarte(const Valeur& v) const;
    std::shared_ptr<CarteAssociative> carteDe(const Valeur& v);
    Valeur creerCarte(std::shared_ptr<CarteAssociative> carte);
    Valeur lireCarte(const Valeur& carte, const Valeur& cle);
    void ecrireCarte(const Valeur& carte, const Valeur& cle, const Valeur& valeur);
    std::string cleCanonique(const Valeur& cle);
    std::map<long long, std::shared_ptr<CarteAssociative>> cartes;
    long long prochaineCarte = 1;
    std::map<std::string, std::vector<Valeur>> auditeurs;  // événements

    // --- interface (Interface.cpp) ---
    std::map<long long, ComposantInterface> composantsInterface;
    long long prochainComposant = 1;
    long long figureInterfaceCourante = 0;

    // --- indexation (Indexation.cpp) ---
    Valeur indexer(const Valeur& base, std::vector<Valeur>& idx, char genre);
    std::vector<Valeur> indexerListe(const Valeur& base, std::vector<Valeur>& idx, char genre);
    Valeur ecrireIndex(Valeur base, std::vector<Valeur>& idx, const Valeur& v, char genre);
    Valeur affecterIndex(Valeur base, const std::vector<ElementAcces>& chaine, std::size_t k,
                         const Valeur& v, bool suppression);
    std::vector<Valeur> evaluerIndices(const std::vector<NoeudPtr>& args, const Valeur* base,
                                       int position, int total);

private:
    std::vector<std::shared_ptr<Portee>> piles_;
    // Portée à rattacher au prochain appel d'une fonction imbriquée.
    std::shared_ptr<Portee> englobanteEnAttente_;
    std::shared_ptr<Portee> trouverPortee(const Portee* brut) const;
    std::unordered_map<std::string, EntreeNative> natifs_;
    std::vector<std::string> chemin_;
    std::map<std::string, std::string> indexM_;       // nom -> fichier
    std::map<std::string, std::string> indexClasses_; // nom -> fichier classdef
    std::map<std::string, std::shared_ptr<FonctionUtilisateur>> cacheFonctions_;
    std::map<std::string, std::shared_ptr<DefinitionClasse>> cacheClasses_;
    std::string racineToolbox_;
    std::vector<std::tuple<const Valeur*, int, int>> pileFin_;
    std::ostream* sortie_ = nullptr;
    std::shared_ptr<std::ostream> journal_;

    Valeur evaluerAcces(const NoeudPtr& n, int nargout, std::vector<Valeur>* multi);
    void affecter(const NoeudPtr& cible, const Valeur& v);
    std::vector<std::size_t> ciblesCellule(const NoeudPtr& cible);
    friend struct GardePortee;
};

// Utilitaires partagés par la bibliothèque.
Valeur listeVersCellule(const std::vector<Valeur>& v);
bool estColonMagique(const Valeur& v);

struct GardePortee {
    Interpreteur& it;
    explicit GardePortee(Interpreteur& i, std::shared_ptr<Portee> p);
    ~GardePortee();
};

// Empile un cadre d'exécution — nom, fichier, ligne — pour la durée d'un
// appel, et le dépile en sortant.
struct GardeCadre {
    Interpreteur& it;
    GardeCadre(Interpreteur& i, const std::string& nom, const std::string& fichier);
    ~GardeCadre();
};

// Le nom qu'un message d'erreur donne à un cadre : celui de la fonction,
// ou celui du fichier pour un script.
std::string nomCourt(const std::string& nom, const std::string& fichier);

// Crochets posés par la bibliothèque graphique : ils donnent aux poignées
// de figure et d'axes leurs propriétés — « ax.XTick », « f.Name ». Rendent
// vrai quand la propriété leur appartient.
extern std::function<bool(Interpreteur&, const Valeur&, const std::string&, const Valeur&)>
    crochetEcrirePropriete;
extern std::function<bool(Interpreteur&, const Valeur&, const std::string&, Valeur&)>
    crochetLirePropriete;

}  // namespace matlibre
