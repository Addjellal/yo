// Valeur.h — le type unique qui porte toutes les données du langage.
//
// Dans MATLAB tout est un tableau : un scalaire est une matrice 1x1, une
// chaîne de caractères une matrice 1xN de codes, un booléen une matrice de
// 0 et de 1. On garde ce modèle tel quel : une seule classe C++ porte les
// dimensions, la classe MATLAB (double, int32, cell, struct…) et les
// données. Les nombres sont toujours stockés en double, même pour int8 ou
// single : la saturation et l'arrondi se font au moment des opérations,
// jamais au stockage. C'est plus simple et cela suffit pour reproduire le
// comportement observable.
//
// Le rangement est celui de MATLAB : par colonnes (column-major).
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

namespace matlibre {

class Interpreteur;
class Valeur;

enum class Classe {
    Double, Simple, Logique, Caractere, Chaine,
    Cellule, Structure, Fonction, Objet,
    Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64
};

const char* nomClasse(Classe c);
bool classeEntiere(Classe c);
bool classeNumerique(Classe c);
double borneBasse(Classe c);
double borneHaute(Classe c);
double saturer(double v, Classe c);

using Dims = std::vector<int>;

// --- poignée de fonction (@sin, @(x) x.^2, ou une fonction de fichier) ---
struct Bloc;   // Arbre.h
struct Noeud;  // Arbre.h
struct FonctionUtilisateur;

class Arguments;

using Builtin = std::vector<Valeur> (*)(Interpreteur&, Arguments, int);

struct Fonction {
    enum Genre { Native, Utilisateur, Anonyme } genre = Native;
    std::string nom;
    Builtin native = nullptr;
    std::shared_ptr<FonctionUtilisateur> utilisateur;
    // anonyme :
    std::vector<std::string> parametres;
    std::shared_ptr<Noeud> corps;
    std::shared_ptr<std::unordered_map<std::string, Valeur>> capture;
    // Portée de la fonction qui a créé la poignée : une fonction imbriquée
    // appelée par un rappel y retrouve les variables de son parent.
    std::shared_ptr<struct Portee> porteeEnglobante;
    // Fonction où la poignée a été créée : ses sous-fonctions restent
    // visibles depuis le corps, comme dans MATLAB.
    std::shared_ptr<FonctionUtilisateur> contexte;
    std::string texte;  // pour func2str
};

// --- tableau creux : colonnes comprimées, comme SuiteSparse et MATLAB ---
struct DonneesCreuses {
    std::vector<int> debutColonne;   // taille ncolonnes + 1
    std::vector<int> ligne;          // indice de ligne de chaque non-nul
    std::vector<double> valeur;      // valeurs non nulles
    std::vector<double> imaginaire;  // vide si réel
};

// --- tableau de structures : chaque champ porte autant de valeurs que
//     d'éléments dans le tableau, dans l'ordre des colonnes. ---
struct ChampsStructure {
    std::vector<std::string> ordre;
    std::unordered_map<std::string, std::vector<Valeur>> champs;
};

class Valeur {
public:
    Classe classe = Classe::Double;
    Dims dims{0, 0};
    std::vector<double> re;
    std::vector<double> im;                 // vide si réel
    std::vector<Valeur> cellules;           // Cellule
    std::vector<std::string> chaines;       // Chaine (string array)
    std::shared_ptr<ChampsStructure> st;    // Structure / Objet
    std::shared_ptr<Fonction> fn;           // Fonction
    std::string nomObjet;                   // Objet : nom de la classe
    // Un objet de classe « handle » partage son état entre toutes ses
    // copies : l'écriture ne détache donc pas la structure.
    bool poigneeObjet = false;
    // Tableau creux : rangement par colonnes comprimées (CSC).
    std::shared_ptr<struct DonneesCreuses> creux;

    Valeur() = default;

    // ---- fabriques ----
    static Valeur scalaire(double v);
    static Valeur complexe(double r, double i);
    static Valeur booleen(bool b);
    static Valeur vide();                        // 0x0 double
    static Valeur videClasse(Classe c);
    static Valeur texte(const std::string& s);   // 1xN char
    static Valeur chaine(const std::string& s);  // string 1x1
    static Valeur matrice(int l, int c, double remplissage = 0.0);
    static Valeur matriceDims(const Dims& d, double remplissage = 0.0);
    static Valeur ligne(const std::vector<double>& v);
    static Valeur colonne(const std::vector<double>& v);
    static Valeur celluleDims(const Dims& d);
    static Valeur celluleLigne(const std::vector<Valeur>& v);
    static Valeur structureVide();
    static Valeur poignee(std::shared_ptr<Fonction> f);

    // ---- interrogation ----
    std::size_t nelem() const;
    int nlignes() const { return dims.empty() ? 0 : dims[0]; }
    int ncolonnes() const;
    int ndims() const { return (int)dims.size(); }
    bool estVide() const { return nelem() == 0; }
    bool estScalaire() const { return nelem() == 1; }
    bool estVecteur() const;
    bool estLigne() const { return dims.size() == 2 && dims[0] == 1; }
    bool estColonne() const { return dims.size() == 2 && dims[1] == 1; }
    bool estCarree() const { return dims.size() == 2 && dims[0] == dims[1]; }
    bool estComplexe() const { return !im.empty(); }
    bool estNumerique() const { return classeNumerique(classe); }
    bool estTexte() const { return classe == Classe::Caractere; }
    bool estChaine() const { return classe == Classe::Chaine; }
    bool estCellule() const { return classe == Classe::Cellule; }
    bool estStructure() const { return classe == Classe::Structure || classe == Classe::Objet; }
    bool estFonction() const { return classe == Classe::Fonction; }
    bool estCreux() const { return creux != nullptr; }
    bool estReel() const { return im.empty(); }

    // ---- accès ----
    double scal() const;                 // premier élément, erreur si vide
    double scalIm() const;
    bool vrai() const;                   // sémantique de « if » : tous non nuls
    std::string versTexte() const;       // char array ou string -> std::string
    std::string classeNom() const;

    void compacter();                    // supprime la partie imaginaire nulle
    void normaliserDims();               // enlève les dimensions 1 en trop
    void redimensionner(const Dims& d);  // change dims (même nombre d'éléments)
    void assurerImaginaire();
    void assurerTaille(std::size_t n);

    std::vector<Valeur>& structElem();          // valeurs d'un champ (accès sûr)
    const std::vector<std::string>& champs() const;
    bool aChamp(const std::string& nom) const;
    Valeur champ(const std::string& nom, std::size_t idx = 0) const;
    void poserChamp(const std::string& nom, Valeur v, std::size_t idx = 0);
    void retirerChamp(const std::string& nom);
    void detacherStructure();  // copie à l'écriture
};

// Les arguments d'une fonction native : le vecteur lui-même, avec un
// « operator[] » qui refuse au lieu de lire hors du tableau.
//
// C'est un contrôle par accès — une comparaison d'entiers —, et il vaut
// pour toutes les fonctions natives à la fois. Sans lui, chacune
// devait penser à vérifier son arité : « asin() » sans argument lisait
// args[0] d'un vecteur vide et le programme tombait, là où MATLAB dit
// « Not enough input arguments ».
class Arguments {
public:
    Arguments(std::vector<Valeur>& v) : v_(v) {}   // conversion voulue
    Valeur& operator[](std::size_t k) const {
        if (k >= v_.size()) manquant();
        return v_[k];
    }
    std::size_t size() const { return v_.size(); }
    bool empty() const { return v_.empty(); }
    std::vector<Valeur>::iterator begin() const { return v_.begin(); }
    std::vector<Valeur>::iterator end() const { return v_.end(); }
    Valeur& back() const {
        if (v_.empty()) manquant();
        return v_.back();
    }
    void push_back(Valeur v) { v_.push_back(std::move(v)); }
    void pop_back() { v_.pop_back(); }
    void resize(std::size_t n) { v_.resize(n); }
    // Quelques fonctions réécrivent leur liste d'arguments avant de la
    // relire : « conv2 » la remplace par la forme séparable.
    Arguments& operator=(const std::vector<Valeur>& autre) {
        v_ = autre;
        return *this;
    }
    // Pour tout ce qui attend encore un vecteur : les fonctions communes,
    // « appeler », la boucle des tranches.
    operator std::vector<Valeur>&() const { return v_; }

private:
    [[noreturn]] static void manquant();
    std::vector<Valeur>& v_;
};


std::size_t produitDims(const Dims& d);
Dims dimsDe(int l, int c);
bool memeDims(const Dims& a, const Dims& b);
std::string texteDims(const Dims& d);

// Conversions utiles partout.
Valeur versDouble(const Valeur& v);
Valeur appliquerClasse(Valeur v, Classe c);

}  // namespace matlibre
