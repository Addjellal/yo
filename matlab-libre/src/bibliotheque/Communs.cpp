// Communs.cpp — briques partagées par tous les modules de la bibliothèque.
#include <algorithm>
#include <cctype>
#include <cmath>
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

Dims dimsDepuisArguments(const std::vector<Valeur>& args, std::size_t debut, std::size_t fin) {
    Dims d;
    if (debut >= fin) return Dims{1, 1};
    for (std::size_t k = debut; k < fin; ++k) exigerTailleNumerique(args[k]);
    if (fin - debut == 1) {
        const Valeur& v = args[debut];
        if (v.nelem() == 1) {
            int n = (int)v.scal();
            return Dims{std::max(0, n), std::max(0, n)};
        }
        for (std::size_t k = 0; k < v.nelem() && k < v.re.size(); ++k)
            d.push_back(std::max(0, (int)v.re[k]));
        if (d.size() < 2) d.push_back(d.empty() ? 0 : d[0]);
        rognerDimsFinales(d);
        return d;
    }
    for (std::size_t k = debut; k < fin; ++k) d.push_back(std::max(0, (int)args[k].scal()));
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

std::string texteExpression(const NoeudPtr& n) {
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
        case TypeN::OpBinaire:
            return "(" + texteExpression(n->enfants[0]) + " " + n->texte + " " +
                   texteExpression(n->enfants[1]) + ")";
        case TypeN::OpUnaire: return n->texte + texteExpression(n->enfants[0]);
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
                if (i) s += "; ";
                for (std::size_t j = 0; j < n->rangees[i].size(); ++j) {
                    if (j) s += ", ";
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
                        if (k) s += ", ";
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
            return s + ") " + texteExpression(n->enfants[0]);
        }
        case TypeN::PoigneeNom: return "@" + n->texte;
        default: return "";
    }
}

Valeur construireObjet(Interpreteur& it, const std::shared_ptr<DefinitionClasse>& def,
                       std::vector<Valeur>& args) {
    // L'objet est d'abord bâti avec ses valeurs par défaut, puis le
    // constructeur — s'il y en a un — le reçoit déjà prêt dans sa variable
    // de sortie, comme le fait MATLAB : on y écrit « obj.champ = ... »
    // sans avoir à le créer.
    Valeur obj = Valeur::structureVide();
    obj.classe = Classe::Objet;
    obj.nomObjet = def->nom;
    for (const auto& nom : def->ordreProprietes) {
        Valeur defaut = Valeur::vide();
        auto itd = def->defauts.find(nom);
        if (itd != def->defauts.end() && itd->second) defaut = it.evaluer(itd->second);
        obj.poserChamp(nom, defaut);
    }
    auto ctor = def->methodes.find(def->nom);
    if (ctor == def->methodes.end()) return obj;

    auto f = ctor->second;
    if (!f->variadiqueEntree() && args.size() > f->entrees.size())
        erreur("MATLAB:TooManyInputs",
               "Too many input arguments to the constructor of '" + def->nom + "'.");
    auto portee = std::make_shared<Portee>();
    portee->nomFonction = f->nom;
    portee->fonction = f;
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
    std::size_t externe = taille ? total / (interne * taille) : 0;
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

}  // namespace matlibre
