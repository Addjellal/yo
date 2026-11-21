// Communs.cpp — briques partagées par tous les modules de la bibliothèque.
#include <algorithm>
#include <cctype>
#include <cmath>
#include <filesystem>
#include <functional>
#include <memory>
#include <sstream>

#include "matlibre/Affichage.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {

void exigerArguments(const std::vector<Valeur>& args, std::size_t mini, std::size_t maxi,
                     const char* nom) {
    if (args.size() < mini)
        erreur("MATLAB:minrhs",
               formater("Not enough input arguments to '%s'.", nom));
    if (maxi != 0 && args.size() > maxi)
        erreur("MATLAB:TooManyInputs",
               formater("Too many input arguments to '%s'.", nom));
}

// Ce qui ne porte pas de nombres : une cellule, une structure, un objet,
// une poignee. « nelem » y compte des elements que « re » n'a pas, si
// bien qu'un parcours de « re » sort du tableau. A appeler avant de le
// parcourir, dans les fonctions qui le font a la main.
void exigerNumerique(const Valeur& v, const char* nom) {
    if (v.classe == Classe::Cellule || v.classe == Classe::Structure ||
        v.classe == Classe::Objet || v.classe == Classe::Fonction ||
        v.classe == Classe::Chaine)
        erreur("MATLAB:UndefinedFunction",
               formater("Undefined function '%s' for input arguments of type '%s'.", nom,
                        v.classeNom().c_str()));
}

// Une taille : finie, positive, representable en « int ». Sans ce
// controle, « (int)NaN » vaut INT_MIN et l'on demandait un tableau de
// taille negative.
int argTaille(double x, const char* nom) {
    if (!std::isfinite(x) || x < 0.0 || x > 2147483647.0)
        erreur("MATLAB:invalidSizeInput",
               formater("Size argument of '%s' must be a finite non-negative integer.",
                        nom));
    return (int)x;
}

// L'ordre donne a PERMUTE doit etre une permutation de 1..N, N valant au
// moins le nombre de dimensions : un ordre incomplet ou hors bornes
// indexait le tableau hors de lui.
void exigerPermutation(const Valeur& ordre, const Valeur& v, const char* nom) {
    std::size_t n = ordre.nelem();
    if (n < v.dims.size())
        erreur("MATLAB:permute:invalidPermutation",
               formater("ORDER must have at least N elements for an N-D array in '%s'.",
                        nom));
    std::vector<bool> vus(n, false);
    for (std::size_t k = 0; k < n && k < ordre.re.size(); ++k) {
        double x = ordre.re[k];
        if (!(x >= 1.0 && x <= (double)n) || x != std::floor(x) || vus[(std::size_t)x - 1])
            erreur("MATLAB:permute:invalidPermutation",
                   formater("ORDER must be a permutation of 1:N in '%s'.", nom));
        vus[(std::size_t)x - 1] = true;
    }
}

// Comme au-dessus, mais les cellules restent admises : « sort », « setdiff »
// et « string » travaillent aussi sur des cellules de textes.
void exigerSansObjet(const Valeur& v, const char* nom) {
    if (v.classe == Classe::Structure || v.classe == Classe::Objet ||
        v.classe == Classe::Fonction)
        erreur("MATLAB:UndefinedFunction",
               formater("Undefined function '%s' for input arguments of type '%s'.", nom,
                        v.classeNom().c_str()));
}

double argScalaire(const std::vector<Valeur>& args, std::size_t k, const char* nom) {
    if (k >= args.size())
        erreur("MATLAB:minrhs", formater("Not enough input arguments to '%s'.", nom));
    const Valeur& v = args[k];
    if (v.nelem() < 1)
        erreur("MATLAB:expectedScalar",
               formater("Expected input number %zu of '%s' to be a scalar.", k + 1, nom));
    return v.re.empty() ? 0.0 : v.re[0];
}

std::string argTexte(const std::vector<Valeur>& args, std::size_t k, const char* nom) {
    if (k >= args.size())
        erreur("MATLAB:minrhs", formater("Not enough input arguments to '%s'.", nom));
    const Valeur& v = args[k];
    if (!v.estTexte() && !v.estChaine())
        erreur("MATLAB:invalidType",
               formater("Expected input number %zu of '%s' to be a character vector or "
                        "string.", k + 1, nom));
    return v.versTexte();
}

void rognerDimsFinales(Dims& d) {
    // MATLAB ne garde jamais de dimension singleton en queue au-dela de la
    // deuxieme : size(zeros(2,2,1,1)) vaut [2 2].
    while (d.size() > 2 && d.back() == 1) d.pop_back();
    while (d.size() < 2) d.push_back(1);
}

// Une cellule, une structure, un objet ou une poignee ne portent aucun
// nombre : « nelem » compte leurs elements, mais « re » est vide. Lire
// « re[k] » sortait du tableau, et « zeros({1,2}) » faisait tomber le
// programme. MATLAB refuse, en le disant.
static void exigerTailleNumerique(const Valeur& v) {
    if (v.classe == Classe::Cellule || v.classe == Classe::Structure ||
        v.classe == Classe::Objet || v.classe == Classe::Fonction ||
        v.classe == Classe::Chaine)
        erreur("MATLAB:invalidSizeInput", "Size inputs must be numeric.");
}

// Une taille demandée à zeros, ones, rand... « (int)1e10 » est un
// comportement indéfini qui vaut INT_MIN sur x86, ramené ensuite à zéro :
// zeros(1e10) rendait un tableau vide sans rien dire, ones(2^31, 1) un
// 0×1, zeros(NaN) aussi. Une taille non représentable est refusée ; une
// taille négative vaut zéro, comme dans MATLAB.
static int tailleDemandee(double x) {
    if (std::isnan(x)) erreur("MATLAB:NonIntegerInput", "Size inputs must be integers.");
    if (x <= 0) return 0;
    if (x > 2147483647.0)
        erreur("MATLAB:array:SizeLimitExceeded",
               "Requested array exceeds the maximum possible variable size.");
    return (int)x;
}

Dims dimsDepuisArguments(const std::vector<Valeur>& args, std::size_t debut, std::size_t fin) {
    Dims d;
    if (debut >= fin) return Dims{1, 1};
    for (std::size_t k = debut; k < fin; ++k) exigerTailleNumerique(args[k]);
    if (fin - debut == 1) {
        const Valeur& v = args[debut];
        if (v.nelem() == 1) {
            int n = tailleDemandee(v.scal());
            return Dims{n, n};
        }
        for (std::size_t k = 0; k < v.nelem() && k < v.re.size(); ++k)
            d.push_back(tailleDemandee(v.re[k]));
        if (d.size() < 2) d.push_back(d.empty() ? 0 : d[0]);
        rognerDimsFinales(d);
        return d;
    }
    for (std::size_t k = debut; k < fin; ++k) d.push_back(tailleDemandee(args[k].scal()));
    while (d.size() < 2) d.push_back(1);
    rognerDimsFinales(d);
    return d;
}

int dimensionParDefaut(const Valeur& v) {
    // MATLAB opère sur la première dimension non singleton.
    for (std::size_t k = 0; k < v.dims.size(); ++k)
        if (v.dims[k] != 1) return (int)k;
    return 0;
}

bool optionToutesDimensions(const std::vector<Valeur>& args) {
    for (std::size_t k = 1; k < args.size(); ++k) {
        const Valeur& a = args[k];
        if ((a.estTexte() || a.estChaine()) && a.versTexte() == "all") return true;
    }
    return false;
}

// « mean(x,'omitnan') » : MATLAB écarte alors les NaN au lieu de les
// laisser contaminer toute la réduction. L'option est retirée de la
// liste d'arguments, si bien que la suite — le contrôle d'arité, la
// dimension — n'a pas à la connaître.
bool optionOmettreNaN(std::vector<Valeur>& args) {
    bool omettre = false;
    for (std::size_t k = args.size(); k-- > 1;) {
        const Valeur& a = args[k];
        if (!(a.estTexte() || a.estChaine())) continue;
        std::string t = a.versTexte();
        for (char& c : t) c = (char)std::tolower((unsigned char)c);
        if (t == "omitnan" || t == "omitmissing") {
            omettre = true;
            args.erase(args.begin() + (std::ptrdiff_t)k);
        } else if (t == "includenan" || t == "includemissing") {
            args.erase(args.begin() + (std::ptrdiff_t)k);
        }
    }
    return omettre;
}

std::vector<double> sansNaN(const std::vector<double>& t) {
    std::vector<double> r;
    r.reserve(t.size());
    for (double x : t)
        if (!std::isnan(x)) r.push_back(x);
    return r;
}

Valeur aplatirColonne(const Valeur& v) {
    Valeur r = v;
    r.dims = {(int)v.nelem(), 1};
    return r;
}

Classe classeDepuisNom(const std::string& nom, bool* trouve) {
    if (trouve) *trouve = true;
    if (nom == "double") return Classe::Double;
    if (nom == "single") return Classe::Simple;
    if (nom == "logical") return Classe::Logique;
    if (nom == "char") return Classe::Caractere;
    if (nom == "string") return Classe::Chaine;
    if (nom == "cell") return Classe::Cellule;
    if (nom == "struct") return Classe::Structure;
    if (nom == "int8") return Classe::Int8;
    if (nom == "int16") return Classe::Int16;
    if (nom == "int32") return Classe::Int32;
    if (nom == "int64") return Classe::Int64;
    if (nom == "uint8") return Classe::UInt8;
    if (nom == "uint16") return Classe::UInt16;
    if (nom == "uint32") return Classe::UInt32;
    if (nom == "uint64") return Classe::UInt64;
    if (trouve) *trouve = false;
    return Classe::Double;
}

Valeur construirePlage(const Valeur& debut, const Valeur& pas, const Valeur& fin) {
    if (debut.estVide() || fin.estVide() || pas.estVide()) return Valeur::matrice(1, 0);
    double a = debut.scal(), s = pas.scal(), b = fin.scal();
    if (s == 0 || (s > 0 && a > b) || (s < 0 && a < b)) {
        Valeur v = Valeur::matrice(1, 0);
        return v;
    }
    double brut = (b - a) / s;
    long long n = (long long)std::floor(brut + 1e-10) + 1;
    if (n < 0) n = 0;
    std::vector<double> valeurs;
    valeurs.reserve((std::size_t)n);
    for (long long k = 0; k < n; ++k) valeurs.push_back(a + (double)k * s);
    if (!valeurs.empty() && s == std::floor(s) && a == std::floor(a)) {
        // Les plages entières restent exactes.
        for (long long k = 0; k < n; ++k) valeurs[(std::size_t)k] = a + (double)k * s;
    }
    Valeur r = Valeur::ligne(valeurs);
    if (debut.classe == Classe::Caractere && fin.classe == Classe::Caractere)
        r.classe = Classe::Caractere;
    else if (classeEntiere(debut.classe)) r.classe = debut.classe;
    else if (classeEntiere(fin.classe)) r.classe = fin.classe;
    else if (debut.classe == Classe::Simple || fin.classe == Classe::Simple)
        r.classe = Classe::Simple;
    return r;
}

bool comparerCas(const Valeur& sujet, const Valeur& cas) {
    // un membre d'énumération : son nom, face à un membre ou à un texte ;
    // sa valeur, face à un nombre
    auto membre = [](const Valeur& v) {
        return v.classe == Classe::Objet && v.st &&
               v.st->champs.count(Interpreteur::champMembre) > 0 && v.nelem() == 1;
    };
    if (membre(sujet) || membre(cas)) {
        const Valeur& e = membre(sujet) ? sujet : cas;
        const Valeur& autre = membre(sujet) ? cas : sujet;
        const std::string nom = e.champ(Interpreteur::champMembre).versTexte();
        if (membre(autre))
            return autre.nomObjet == e.nomObjet &&
                   autre.champ(Interpreteur::champMembre).versTexte() == nom;
        if (autre.estTexte() || autre.estChaine()) return autre.versTexte() == nom;
        if (e.aChamp(Interpreteur::champValeurEnum) && autre.estNumerique() &&
            autre.nelem() == 1)
            return e.champ(Interpreteur::champValeurEnum).scal() == autre.scal();
        return false;
    }
    if ((sujet.estTexte() || sujet.estChaine()) && (cas.estTexte() || cas.estChaine()))
        return sujet.versTexte() == cas.versTexte();
    if (sujet.estTexte() || sujet.estChaine() || cas.estTexte() || cas.estChaine()) return false;
    if (sujet.estVide() || cas.estVide()) return sujet.estVide() && cas.estVide();
    if (cas.estScalaire() && sujet.estScalaire())
        return sujet.re[0] == cas.re[0] &&
               (sujet.im.empty() ? 0.0 : sujet.im[0]) == (cas.im.empty() ? 0.0 : cas.im[0]);
    if (!memeDims(sujet.dims, cas.dims)) return false;
    for (std::size_t k = 0; k < sujet.re.size(); ++k)
        if (sujet.re[k] != cas.re[k]) return false;
    return true;
}

std::string nomMethodeOperateur(const std::string& op) {
    if (op == "+") return "plus";
    if (op == "-") return "minus";
    if (op == "*") return "mtimes";
    if (op == ".*") return "times";
    if (op == "/") return "mrdivide";
    if (op == "./") return "rdivide";
    if (op == "\\") return "mldivide";
    if (op == ".\\") return "ldivide";
    if (op == "^") return "mpower";
    if (op == ".^") return "power";
    if (op == "==") return "eq";
    if (op == "~=") return "ne";
    if (op == "<") return "lt";
    if (op == "<=") return "le";
    if (op == ">") return "gt";
    if (op == ">=") return "ge";
    if (op == "&") return "and";
    if (op == "|") return "or";
    return "";
}

// Le rang d'un operateur : plus il est haut, plus il lie fort. L'ordre
// est celui de MATLAB, et c'est lui qui decide des parentheses.
static int rangOperateur(const std::string& op) {
    if (op == "||") return 1;
    if (op == "&&") return 2;
    if (op == "|") return 3;
    if (op == "&") return 4;
    if (op == "<" || op == "<=" || op == ">" || op == ">=" || op == "==" || op == "~=")
        return 5;
    if (op == ":") return 6;
    if (op == "+" || op == "-") return 7;
    if (op == "*" || op == "/" || op == "\\" || op == ".*" || op == "./" || op == ".\\")
        return 8;
    if (op == "^" || op == ".^") return 9;
    return 10;
}

std::string texteExpression(const NoeudPtr& n) { return texteExpression(n, 0); }

// PRIORITE est celle du contexte : on n'entoure de parentheses que ce qui
// lierait moins fort que lui. Sans cela « @(y)y+1 » revenait de
// « func2str » sous la forme « @(y)(y+1) » — juste, mais illisible des
// que l'expression grandit, et different de ce que l'utilisateur a ecrit.
//
// Rien n'est espace, pas meme apres une virgule : c'est ce que rend
// MATLAB, dont la documentation donne « @(x)x.^2+1 ». Du code qui
// compare le texte d'une poignee a une chaine attendue en depend, et
// c'est le seul usage ou l'espacement se voie.
std::string texteExpression(const NoeudPtr& n, int priorite) {
    if (!n) return "";
    switch (n->type) {
        case TypeN::Nombre: {
            std::string s = nombreVersTexte(n->nombre, 15);
            return n->imaginaire ? s + "i" : s;
        }
        case TypeN::Litteral: return "'" + n->texte + "'";
        case TypeN::LitteralChaine: return "\"" + n->texte + "\"";
        case TypeN::Ident: return n->texte;
        case TypeN::FinIndice: return "end";
        case TypeN::DeuxPointsSeul: return ":";
        case TypeN::OpBinaire: {
            int rang = rangOperateur(n->texte);
            // Les operateurs sont associatifs a gauche : le membre droit
            // de meme rang a bien ete parenthese dans la source, et doit
            // le rester — « a - (b - c) » n'est pas « a - b - c ».
            std::string texte = texteExpression(n->enfants[0], rang) + n->texte +
                                texteExpression(n->enfants[1], rang + 1);
            return rang < priorite ? "(" + texte + ")" : texte;
        }
        case TypeN::OpUnaire: {
            // Un unaire lie plus fort qu'un produit, moins fort qu'une
            // puissance : « -a*b » vaut « (-a)*b », « -a^2 » vaut « -(a^2) ».
            std::string texte = n->texte + texteExpression(n->enfants[0], 9);
            return 8 < priorite ? "(" + texte + ")" : texte;
        }
        case TypeN::OpPostfixe: return texteExpression(n->enfants[0]) + n->texte;
        case TypeN::Plage: {
            std::string s = texteExpression(n->enfants[0]) + ":";
            if (n->enfants[1]) s += texteExpression(n->enfants[1]) + ":";
            return s + texteExpression(n->enfants[2]);
        }
        case TypeN::Matrice:
        case TypeN::Cellule: {
            std::string s = n->type == TypeN::Matrice ? "[" : "{";
            for (std::size_t i = 0; i < n->rangees.size(); ++i) {
                if (i) s += ";";
                for (std::size_t j = 0; j < n->rangees[i].size(); ++j) {
                    if (j) s += ",";
                    s += texteExpression(n->rangees[i][j]);
                }
            }
            return s + (n->type == TypeN::Matrice ? "]" : "}");
        }
        case TypeN::Acces: {
            std::string s = texteExpression(n->enfants[0]);
            for (const auto& a : n->acces) {
                if (a.genre == '.') {
                    s += "." + a.nom;
                } else if (a.genre == '?') {
                    s += ".(" + (a.args.empty() ? "" : texteExpression(a.args[0])) + ")";
                } else {
                    s += (a.genre == '(') ? "(" : "{";
                    for (std::size_t k = 0; k < a.args.size(); ++k) {
                        if (k) s += ",";
                        s += texteExpression(a.args[k]);
                    }
                    s += (a.genre == '(') ? ")" : "}";
                }
            }
            return s;
        }
        case TypeN::Anonyme: {
            std::string s = "@(";
            for (std::size_t k = 0; k < n->noms.size(); ++k) {
                if (k) s += ",";
                s += n->noms[k];
            }
            return s + ")" + texteExpression(n->enfants[0]);
        }
        case TypeN::PoigneeNom: return "@" + n->texte;
        default: return "";
    }
}

Valeur construireObjet(Interpreteur& it, const std::shared_ptr<DefinitionClasse>& def,
                       std::vector<Valeur>& args) {
    // « Jour(2) », « Couleur('Rouge') » : une énumération ne se construit
    // pas, elle convertit des valeurs ou des noms en ses membres
    if (def->estEnumeration() && !it.enConstructionEnumeration) {
        if (args.size() != 1)
            erreur("MATLAB:class:EnumerationConstructor",
                   "L'enumeration '" + def->nom + "' se convertit d'une valeur ou d'un nom : " +
                       def->nom + "(2), " + def->nom + "('" + def->enumerations[0] + "').");
        return it.convertirEnEnumeration(def, args[0]);
    }
    // L'objet est d'abord bâti avec ses valeurs par défaut, puis le
    // constructeur — s'il y en a un — le reçoit déjà prêt dans sa variable
    // de sortie, comme le fait MATLAB : on y écrit « obj.champ = ... »
    // sans avoir à le créer.
    Valeur obj = Valeur::structureVide();
    obj.classe = Classe::Objet;
    obj.nomObjet = def->nom;
    // « classdef X < handle » : l'objet partage son etat avec ses copies.
    // Sans cela, « p.addParameter(...) » n'avait aucun effet visible,
    // puisque la methode travaillait sur une copie.
    obj.poigneeObjet = def->poignee;
    for (const auto& nom : def->ordreProprietes) {
        Valeur defaut = Valeur::vide();
        auto itd = def->defauts.find(nom);
        if (itd != def->defauts.end() && itd->second) defaut = it.evaluer(itd->second);
        obj.poserChamp(nom, defaut);
    }
    auto ctor = def->methodes.find(def->nom);
    if (ctor == def->methodes.end()) {
        // Sans constructeur propre, une classe dérivée passe ses arguments
        // au constructeur de son parent, comme sous MATLAB : on n'a pas à
        // écrire un constructeur qui ne ferait que les transmettre.
        for (const auto& nomParent : def->parents) {
            auto parent = it.classeDefinie(nomParent);
            if (!parent || !parent->methodes.count(parent->nom)) continue;
            std::vector<Valeur> appel = {obj, Valeur::texte(nomParent)};
            for (const auto& a : args) appel.push_back(a);
            auto r = it.appeler("matlibre_heriter", appel, 1);
            if (!r.empty()) obj = r[0];
            obj.classe = Classe::Objet;
            obj.nomObjet = def->nom;
            obj.poigneeObjet = def->poignee;
            return obj;
        }
        return obj;
    }

    auto f = ctor->second;
    if (!f->variadiqueEntree() && args.size() > f->entrees.size())
        erreur("MATLAB:TooManyInputs",
               "Too many input arguments to the constructor of '" + def->nom + "'.");
    auto portee = std::make_shared<Portee>();
    portee->nomFonction = f->nom;
    portee->fonction = f;
    // Le constructeur voit les noms des variables qu'on lui passe, comme
    // toute fonction : « table(y,x) » nomme ainsi ses colonnes.
    portee->nomsEntrees = it.prendreNomsArguments();
    std::size_t fixes = f->entrees.size();
    if (f->variadiqueEntree()) fixes -= 1;
    for (std::size_t k = 0; k < fixes && k < args.size(); ++k)
        portee->variables[f->entrees[k]] = args[k];
    if (f->variadiqueEntree()) {
        std::vector<Valeur> extra;
        for (std::size_t k = fixes; k < args.size(); ++k) extra.push_back(args[k]);
        portee->variables["varargin"] = Valeur::celluleLigne(extra);
    }
    std::string nomSortie = f->sorties.empty() ? std::string("obj") : f->sorties[0];
    portee->variables[nomSortie] = obj;
    portee->nargin = (int)args.size();
    portee->nargout = 1;
    {
        GardePortee garde(it, portee);
        // Le constructeur est un cadre d'execution comme un autre : sans
        // cela, ses instructions ecrasaient la ligne courante de
        // l'appelant, et le message d'erreur nommait la mauvaise.
        GardeCadre cadre(it, f->nom, f->fichier);
        try {
            it.executerBloc(f->corps);
        } catch (RetourFonction&) {
        } catch (ErreurMatlab& e) {
            e.pile.push_back(it.cadres.back());
            throw;
        }
        const Valeur* resultat = it.trouverVariable(nomSortie);
        if (resultat) obj = *resultat;
    }
    obj.classe = Classe::Objet;
    obj.nomObjet = def->nom;
    obj.poigneeObjet = def->poignee;
    return obj;
}

// ------------------------------------------------------------- réductions

// Une dimension negative indexait « d[(std::size_t)dimension] », donc un
// mot situe bien avant le tableau : le tas etait ecrase, et le programme
// tombait plus tard, ailleurs. Les deux parcours qui suivent sont le
// passage oblige de toutes les reductions : le controle y tient une fois
// pour toutes.
void exigerDimension(int dimension) {
    if (dimension < 0)
        erreur("MATLAB:getdimarg:dimensionMustBePositiveInteger",
               "Dimension argument must be a positive integer scalar within indexing "
               "range.");
}

void parcourirTranches(const Valeur& v, int dimension,
                       const std::function<void(std::vector<double>&, std::size_t)>& f) {
    exigerDimension(dimension);
    Dims d = v.dims;
    while ((int)d.size() <= dimension) d.push_back(1);
    std::size_t interne = 1;
    for (int k = 0; k < dimension; ++k) interne *= (std::size_t)d[(std::size_t)k];
    std::size_t taille = (std::size_t)d[(std::size_t)dimension];
    std::size_t total = v.nelem();
    std::size_t externe = (taille && interne) ? total / (interne * taille) : 0;
    std::vector<double> tranche(taille);
    for (std::size_t a = 0; a < externe; ++a) {
        for (std::size_t b = 0; b < interne; ++b) {
            std::size_t base = a * interne * taille + b;
            for (std::size_t i = 0; i < taille; ++i) tranche[i] = v.re[base + i * interne];
            f(tranche, a * interne + b);
        }
    }
}

Valeur reduire(const Valeur& v, int dimension, bool garderDim,
               const std::function<double(const std::vector<double>&)>& f) {
    exigerDimension(dimension);
    Dims d = v.dims;
    while ((int)d.size() <= dimension) d.push_back(1);
    Dims rd = d;
    rd[(std::size_t)dimension] = 1;
    Valeur r = Valeur::matriceDims(rd);
    if (!garderDim) r.normaliserDims();
    parcourirTranches(v, dimension, [&](std::vector<double>& tranche, std::size_t k) {
        if (k < r.re.size()) r.re[k] = f(tranche);
    });
    return r;
}

std::string fichierSurChemin(Interpreteur& it, const std::string& nom) {
    namespace fs = std::filesystem;
    std::error_code ec;
    fs::path p(nom);
    if (nom.empty() || p.has_parent_path()) return std::string();
    if (fs::is_regular_file(p, ec)) return fs::absolute(p, ec).string();
    for (const std::string& dossier : it.chemin()) {
        fs::path candidat = fs::path(dossier) / p;
        if (fs::is_regular_file(candidat, ec)) return candidat.string();
    }
    return std::string();
}

Valeur appliquerParElements(const std::vector<Valeur>& arguments, const char* nom,
                            const std::function<double(const double*)>& f) {
    std::vector<Valeur> valeurs;
    valeurs.reserve(arguments.size());
    for (const Valeur& a : arguments) {
        if (!(a.estNumerique() || a.classe == Classe::Logique))
            erreur(formater("MATLAB:%s:InputType", nom),
                   formater("Arguments of %s must be numeric.", nom));
        if (a.estComplexe())
            erreur(formater("MATLAB:%s:ComplexInput", nom),
                   formater("Arguments of %s must be real.", nom));
        valeurs.push_back(versDouble(a));
    }
    Dims dims{1, 1};
    bool tailleFixee = false;
    for (const Valeur& v : valeurs) {
        if (v.nelem() == 1) continue;
        if (!tailleFixee) {
            dims = v.dims;
            tailleFixee = true;
        } else if (v.dims != dims) {
            erreur(formater("stats:%s:InputSizeMismatch", nom),
                   "Non-scalar arguments must match in size.");
        }
    }
    Valeur r = Valeur::matriceDims(dims);
    std::vector<double> courants(valeurs.size());
    for (std::size_t k = 0; k < r.re.size(); ++k) {
        for (std::size_t i = 0; i < valeurs.size(); ++i)
            courants[i] = valeurs[i].nelem() == 1 ? valeurs[i].re[0] : valeurs[i].re[k];
        r.re[k] = f(courants.data());
    }
    return r;
}

// Quantile de la loi normale centrée réduite : l'algorithme AS 241 de
// Wichura (1988), juste à 1e-16 près sur tout ]0,1[, puis un pas de Newton
// sur la queue inférieure, calculée par erfc sans soustraction. Les
// queues sont traitées en p ou 1-p, jamais en 2p-1 : norminv(1e-20) vaut
// -9.2623, non -Inf.
double quantileNormal(double p) {
    if (std::isnan(p) || p < 0 || p > 1) return std::nan("");
    if (p == 0) return -INFINITY;
    if (p == 1) return INFINITY;
    if (p > 0.5) return -quantileNormal(1.0 - p);  // 1-p exact ici
    const double q = p - 0.5;
    double x;
    if (std::fabs(q) <= 0.425) {
        const double r = 0.180625 - q * q;
        x = q * (((((((2.5090809287301226727e3 * r + 3.3430575583588128105e4) * r +
                      6.7265770927008700853e4) * r + 4.5921953931549871457e4) * r +
                    1.3731693765509461125e4) * r + 1.9715909503065514427e3) * r +
                  1.3314166789178437745e2) * r + 3.3871328727963666080e0) /
            (((((((5.2264952788528545610e3 * r + 2.8729085735721942674e4) * r +
                  3.9307895800092710610e4) * r + 2.1213794301586595867e4) * r +
                5.3941960214247511077e3) * r + 6.8718700749205790830e2) * r +
              4.2313330701600911252e1) * r + 1.0);
    } else {
        double r = std::sqrt(-std::log(p));
        if (r <= 5.0) {
            r -= 1.6;
            x = (((((((7.74545014278341407640e-4 * r + 2.27238449892691845833e-2) * r +
                      2.41780725177450611770e-1) * r + 1.27045825245236838258e0) * r +
                    3.64784832476320460504e0) * r + 5.76949722146069140550e0) * r +
                  4.63033784615654529590e0) * r + 1.42343711074968357734e0) /
                (((((((1.05075007164441684324e-9 * r + 5.47593808499534494600e-4) * r +
                      1.51986665636164571966e-2) * r + 1.48103976427480074590e-1) * r +
                    6.89767334985100004550e-1) * r + 1.67638483018380384940e0) * r +
                  2.05319162663775882187e0) * r + 1.0);
        } else {
            r -= 5.0;
            x = (((((((2.01033439929228813265e-7 * r + 2.71155556874348757815e-5) * r +
                      1.24266094738807843860e-3) * r + 2.65321895265761230930e-2) * r +
                    2.96560571828504891230e-1) * r + 1.78482653991729133580e0) * r +
                  5.46378491116411436990e0) * r + 6.65790464350110377720e0) /
                (((((((2.04426310338993978564e-15 * r + 1.42151175831644588870e-7) * r +
                      1.84631831751005468180e-5) * r + 7.86869131145613259100e-4) * r +
                    1.48753612908506148525e-2) * r + 1.36929880922735805310e-1) * r +
                  5.99832206555887937690e-1) * r + 1.0);
        }
        x = -x;  // queue inférieure
    }
    // Un pas de Newton : Phi(x) = erfc(-x/sqrt2)/2 garde ses chiffres pour x < 0.
    const double densite = std::exp(-0.5 * x * x) / std::sqrt(2.0 * 3.14159265358979323846);
    if (densite > 0 && p > 1e-300) {
        const double phi = 0.5 * std::erfc(-x / std::sqrt(2.0));
        x -= (phi - p) / densite;
    }
    return x;
}

}  // namespace matlibre
