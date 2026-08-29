// GenerationC.cpp — le traducteur MATLAB -> C.
//
// Principe : on part de l'arbre syntaxique, on propage les types et les
// dimensions depuis la signature donnée par l'utilisateur, et on écrit du C
// sans allocation dynamique. Un tableau MATLAB devient un tableau C de
// taille fixe rangé par colonnes ; un scalaire reste un scalaire.
//
// Ce que le traducteur refuse, il le dit : pas de C approximatif.
#include "matlibre/GenerationC.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <functional>
#include <map>
#include <set>
#include <sstream>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"

namespace matlibre {

std::string TypeC::nomC() const {
    if (complexe) return "matlibre_cplx";
    switch (base) {
        case Base::Double:    return "double";
        case Base::Single:    return "float";
        case Base::Int8:      return "int8_t";
        case Base::Int16:     return "int16_t";
        case Base::Int32:     return "int32_t";
        case Base::Int64:     return "int64_t";
        case Base::UInt8:     return "uint8_t";
        case Base::UInt16:    return "uint16_t";
        case Base::UInt32:    return "uint32_t";
        case Base::UInt64:    return "uint64_t";
        case Base::Logique:   return "bool";
        case Base::Caractere: return "char";
    }
    return "double";
}

std::string TypeC::nomMatlab() const {
    std::string prefixe = complexe ? "complex " : "";
    switch (base) {
        case Base::Double:    return prefixe + "double";
        case Base::Single:    return prefixe + "single";
        case Base::Int8:      return prefixe + "int8";
        case Base::Int16:     return prefixe + "int16";
        case Base::Int32:     return prefixe + "int32";
        case Base::Int64:     return prefixe + "int64";
        case Base::UInt8:     return prefixe + "uint8";
        case Base::UInt16:    return prefixe + "uint16";
        case Base::UInt32:    return prefixe + "uint32";
        case Base::UInt64:    return prefixe + "uint64";
        case Base::Logique:   return prefixe + "logical";
        case Base::Caractere: return prefixe + "char";
    }
    return prefixe + "double";
}

bool TypeC::entier() const {
    switch (base) {
        case Base::Int8: case Base::Int16: case Base::Int32: case Base::Int64:
        case Base::UInt8: case Base::UInt16: case Base::UInt32: case Base::UInt64:
            return true;
        default:
            return false;
    }
}

bool TypeC::signe() const {
    switch (base) {
        case Base::Int8: case Base::Int16: case Base::Int32: case Base::Int64:
            return true;
        default:
            return false;
    }
}

double TypeC::minimum() const {
    switch (base) {
        case Base::Int8:  return -128.0;
        case Base::Int16: return -32768.0;
        case Base::Int32: return -2147483648.0;
        case Base::Int64: return -9223372036854775808.0;
        default:          return 0.0;
    }
}

double TypeC::maximum() const {
    switch (base) {
        case Base::Int8:   return 127.0;
        case Base::Int16:  return 32767.0;
        case Base::Int32:  return 2147483647.0;
        case Base::Int64:  return 9223372036854775807.0;
        case Base::UInt8:  return 255.0;
        case Base::UInt16: return 65535.0;
        case Base::UInt32: return 4294967295.0;
        case Base::UInt64: return 18446744073709551615.0;
        default:           return 0.0;
    }
}

TypeC typeDepuisTexte(const std::string& classe, int lignes, int colonnes, bool complexe) {
    TypeC t;
    t.lignes = lignes;
    t.colonnes = colonnes;
    t.complexe = complexe;
    if (classe == "single") t.base = TypeC::Base::Single;
    else if (classe == "int8") t.base = TypeC::Base::Int8;
    else if (classe == "int16") t.base = TypeC::Base::Int16;
    else if (classe == "int32") t.base = TypeC::Base::Int32;
    else if (classe == "int64") t.base = TypeC::Base::Int64;
    else if (classe == "uint8") t.base = TypeC::Base::UInt8;
    else if (classe == "uint16") t.base = TypeC::Base::UInt16;
    else if (classe == "uint32") t.base = TypeC::Base::UInt32;
    else if (classe == "uint64") t.base = TypeC::Base::UInt64;
    else if (classe == "logical") t.base = TypeC::Base::Logique;
    else if (classe == "char") t.base = TypeC::Base::Caractere;
    else t.base = TypeC::Base::Double;
    return t;
}

namespace {

// Résultat de la traduction d'une expression : soit un scalaire, écrit
// directement dans le C produit, soit un tableau nommé, déjà rempli.
struct Expression {
    std::string code;   // scalaire : l'expression ; tableau : son identifiant
    TypeC type;
    bool tableau = false;
};

// Une expression C est-elle une constante numérique littérale ?
bool constanteDe(const std::string& code, double& valeur) {
    try {
        std::size_t pos = 0;
        valeur = std::stod(code, &pos);
        while (pos < code.size() && std::isspace((unsigned char)code[pos])) ++pos;
        return pos == code.size();
    } catch (...) {
        return false;
    }
}

struct Traducteur {
    Interpreteur& it;
    const OptionsC& options;
    std::ostringstream corps;
    std::ostringstream declarations;   // toutes les variables, en tête de fonction
    std::map<std::string, TypeC> variables;
    std::set<std::string> declarees;
    std::vector<std::string> avertissements;
    std::set<std::string> aides;       // fonctions d'appui à écrire
    bool utiliseSortie = false;        // un « return » a été traduit
    bool accumulateurProduit = false;  // « double s » déjà déclaré
    bool accumulateurProduitComplexe = false;  // « matlibre_cplx sc » déjà déclaré
    int compteurTemp = 0;
    int indentation = 1;
    std::string nomFonction;

    explicit Traducteur(Interpreteur& i, const OptionsC& o) : it(i), options(o) {}

    std::string marge() const { return std::string((std::size_t)indentation * 4, ' '); }
    std::string temporaire() { return "mlb_t" + std::to_string(compteurTemp++); }

    [[noreturn]] void refuser(const std::string& quoi, int ligne) {
        erreur("coder:codegen:Unsupported",
               "Line " + std::to_string(ligne) + ": " + quoi +
                   " is outside the subset that MatLibre Coder translates.");
    }

    // --- types -------------------------------------------------------------

    // Type du résultat d'une opération entre deux types, selon les règles de
    // MATLAB : un entier l'emporte sur double, single l'emporte sur double,
    // deux entiers de classes différentes sont une erreur.
    // Classe de base du résultat, sans regarder les dimensions.
    // Un complexe n'est stocké qu'en double : le complexe entier ou single
    // sort du sous-ensemble, et on le dit plutôt que de l'approcher.
    void verifierComplexe(const TypeC& t, int ligne) {
        if (!t.complexe || t.base == TypeC::Base::Double) return;
        TypeC reel = t;
        reel.complexe = false;
        refuser("complex " + reel.nomMatlab() + " values", ligne);
    }

    TypeC combinerBase(const TypeC& a, const TypeC& b, int ligne) {
        TypeC r;
        r.complexe = a.complexe || b.complexe;
        if (a.entier() && b.entier()) {
            if (a.base != b.base)
                refuser("mixing " + a.nomMatlab() + " and " + b.nomMatlab(), ligne);
            r.base = a.base;
        } else if (a.entier()) {
            r.base = a.base;
        } else if (b.entier()) {
            r.base = b.base;
        } else if (a.base == TypeC::Base::Single || b.base == TypeC::Base::Single) {
            r.base = TypeC::Base::Single;
        } else {
            r.base = TypeC::Base::Double;
        }
        verifierComplexe(r, ligne);
        return r;
    }

    TypeC combiner(const TypeC& a, const TypeC& b, int ligne) {
        TypeC r;
        r.complexe = a.complexe || b.complexe;
        if (a.entier() && b.entier()) {
            if (a.base != b.base)
                refuser("mixing " + a.nomMatlab() + " and " + b.nomMatlab(), ligne);
            r.base = a.base;
        } else if (a.entier()) {
            r.base = a.base;
        } else if (b.entier()) {
            r.base = b.base;
        } else if (a.base == TypeC::Base::Single || b.base == TypeC::Base::Single) {
            r.base = TypeC::Base::Single;
        } else {
            r.base = TypeC::Base::Double;
        }
        // Dimensions : diffusion scalaire, sinon égalité exigée.
        if (a.estScalaire()) {
            r.lignes = b.lignes; r.colonnes = b.colonnes;
        } else if (b.estScalaire()) {
            r.lignes = a.lignes; r.colonnes = a.colonnes;
        } else {
            if (a.lignes != b.lignes || a.colonnes != b.colonnes)
                refuser("array dimensions " + std::to_string(a.lignes) + "x" +
                            std::to_string(a.colonnes) + " and " + std::to_string(b.lignes) +
                            "x" + std::to_string(b.colonnes) + " do not agree",
                        ligne);
            r.lignes = a.lignes; r.colonnes = a.colonnes;
        }
        verifierComplexe(r, ligne);
        return r;
    }

    // Conversion d'une valeur double vers le type cible, avec saturation
    // quand la cible est entière : c'est la règle de MATLAB.
    std::string convertir(const std::string& valeur, const TypeC& cible) {
        if (!cible.entier()) {
            if (cible.base == TypeC::Base::Single) return "(float)(" + valeur + ")";
            if (cible.base == TypeC::Base::Logique) return "((" + valeur + ") != 0)";
            if (cible.base == TypeC::Base::Caractere) return "(char)(" + valeur + ")";
            return "(double)(" + valeur + ")";
        }
        aides.insert("saturer");
        std::ostringstream o;
        o << "(" << cible.nomC() << ")matlibre_saturer(" << valeur << ", "
          << cible.minimum() << ", " << cible.maximum() << ")";
        return o.str();
    }

    // --- complexes ------------------------------------------------------

    // Le type d'un élément : les dimensions tombent, la classe reste.
    static TypeC elementDe(TypeC t) {
        t.lignes = 1;
        t.colonnes = 1;
        return t;
    }

    static TypeC typeComplexe() {
        TypeC t;
        t.complexe = true;
        return t;
    }

    // Écrit une expression scalaire du type « de » sous la forme qu'exige
    // « vers ». Promouvoir un réel en complexe est licite ; l'inverse ne
    // l'est pas : MATLAB agrandirait la variable, le C figé ne le peut pas.
    std::string adapter(const std::string& code, const TypeC& de, const TypeC& vers,
                        int ligne) {
        if (vers.complexe) {
            verifierComplexe(vers, ligne);
            if (de.complexe) return code;
            aides.insert("complexe");
            aides.insert("cplx_de");
            return "matlibre_cplx_de((double)(" + code + "), 0.0)";
        }
        if (de.complexe)
            refuser("storing a complex value where a real " + vers.nomMatlab() +
                        " is expected (declare it with complex(...) first)",
                    ligne);
        return convertir(code, vers);
    }

    // La partie réelle d'une expression scalaire, en double.
    std::string partieReelle(const std::string& code, const TypeC& t) {
        if (t.complexe) return "(" + code + ").re";
        return "(double)(" + code + ")";
    }

    // Valeur de vérité de MATLAB : un complexe est vrai s'il est non nul.
    std::string estVrai(const std::string& code, const TypeC& t) {
        if (t.complexe) return "((" + code + ").re != 0 || (" + code + ").im != 0)";
        return "(" + code + ")";
    }

    // --- déclarations --------------------------------------------------------

    // Toutes les déclarations vont en tête de fonction : en MATLAB une
    // variable créée dans un « if » vit jusqu'à la fin de la fonction, ce
    // que la portée de bloc du C ne donnerait pas.
    // Le générateur se réserve le préfixe « mlb_ » pour ses indices de
    // boucle, ses temporaires et ses accumulateurs : une variable MATLAB
    // qui le porterait produirait du C incorrect en silence.
    void verifierNom(const std::string& nom, int ligne) {
        if (nom.size() < 4 || nom.compare(0, 4, "mlb_") != 0) return;
        erreur("coder:codegen:Unsupported",
               "Line " + std::to_string(ligne) + ": the name '" + nom +
                   "' uses the 'mlb_' prefix, which MatLibre Coder reserves for the "
                   "identifiers it generates.");
    }

    void declarer(const std::string& nom, const TypeC& t) {
        if (declarees.count(nom)) return;
        declarees.insert(nom);
        variables[nom] = t;
        if (t.estScalaire())
            declarations << "    " << t.nomC() << " " << nom << " = " << zeroDe(t) << ";\n";
        else
            declarations << "    " << t.nomC() << " " << nom << "[" << t.elements()
                         << "] = {" << zeroDe(t) << "};\n";
    }

    // Valeur nulle littérale : « 0 » pour un scalaire C, « {0, 0} » pour un
    // complexe — sans quoi gcc -Wall se plaint des accolades manquantes.
    static std::string zeroDe(const TypeC& t) { return t.complexe ? "{0, 0}" : "0"; }

    std::string nouveauTableau(const TypeC& t) {
        std::string nom = temporaire();
        declarations << "    " << t.nomC() << " " << nom << "[" << t.elements() << "];\n";
        return nom;
    }

    // Accumulateur scalaire : déclaré en tête, initialisé sur place.
    std::string nouvelAccumulateur(const std::string& typeC, const std::string& valeur) {
        std::string nom = temporaire();
        declarations << "    " << typeC << " " << nom << ";\n";
        corps << marge() << nom << " = " << valeur << ";\n";
        return nom;
    }

    // --- expressions ----------------------------------------------------------

    Expression traduire(const NoeudPtr& n);

    Expression scalaire(const std::string& code, TypeC t) {
        Expression e;
        e.code = code;
        t.lignes = 1;
        t.colonnes = 1;
        e.type = t;
        e.tableau = false;
        return e;
    }

    // Lecture d'un élément d'une expression, à l'indice linéaire donné.
    std::string element(const Expression& e, const std::string& indice) {
        if (!e.tableau) return "(" + e.code + ")";
        if (e.type.estScalaire()) return e.code + "[0]";
        return e.code + "[" + indice + "]";
    }

    // Range une expression dans un tableau nommé, en la diffusant si besoin.
    std::string materialiser(const Expression& e, const TypeC& forme) {
        if (e.tableau && e.type.lignes == forme.lignes && e.type.colonnes == forme.colonnes &&
            e.type.base == forme.base && e.type.complexe == forme.complexe)
            return e.code;
        std::string nom = nouveauTableau(forme);
        corps << marge() << "for (int mlb_k = 0; mlb_k < " << forme.elements() << "; mlb_k++) "
              << nom << "[mlb_k] = "
              << adapter(element(e, e.type.estScalaire() ? "0" : "mlb_k"), elementDe(e.type),
                         elementDe(forme), 0)
              << ";\n";
        return nom;
    }

    // Une opération scalaire dont au moins un opérande est complexe. Rend
    // l'expression C du résultat, déjà du type « t ».
    std::string operationComplexe(const std::string& op, const std::string& ea, const TypeC& ta,
                                  const std::string& eb, const TypeC& tb, const TypeC& t,
                                  int ligne) {
        // Comparaisons d'ordre : MATLAB ne regarde que la partie réelle.
        if (op == "<" || op == ">" || op == "<=" || op == ">=")
            return "(" + partieReelle(ea, ta) + " " + op + " " + partieReelle(eb, tb) + ")";
        if (op == "&" || op == "&&" || op == "|" || op == "||") {
            std::string cop = (op == "&" || op == "&&") ? "&&" : "||";
            return "(" + estVrai(ea, ta) + " " + cop + " " + estVrai(eb, tb) + ")";
        }
        aides.insert("complexe");
        TypeC cplx = typeComplexe();
        std::string A = adapter(ea, ta, cplx, ligne);
        std::string B = adapter(eb, tb, cplx, ligne);
        if (op == "==" || op == "~=") {
            aides.insert("ceq");
            std::string e = "matlibre_ceq(" + A + ", " + B + ")";
            return op == "==" ? e : "(!" + e + ")";
        }
        std::string appel;
        if (op == "+") appel = "cadd";
        else if (op == "-") appel = "csub";
        else if (op == "*" || op == ".*") appel = "cmul";
        else if (op == "/" || op == "./") appel = "cdiv";
        else if (op == "^" || op == ".^") appel = "cpow";
        else refuser("the operator '" + op + "' on complex values", ligne);
        aides.insert(appel);
        if (appel == "cpow") { aides.insert("cmul"); aides.insert("cdiv"); }
        (void)t;
        return "matlibre_" + appel + "(" + A + ", " + B + ")";
    }

    // Applique une transformation élément par élément, en gardant la forme.
    Expression appliquer(const Expression& a, const TypeC& t,
                         const std::function<std::string(const std::string&)>& f) {
        if (!a.tableau) return scalaire(f(a.code), t);
        std::string cible = nouveauTableau(t);
        corps << marge() << "for (int mlb_k = 0; mlb_k < " << t.elements() << "; mlb_k++) " << cible
              << "[mlb_k] = " << f(a.code + "[mlb_k]") << ";\n";
        Expression e;
        e.code = cible;
        e.type = t;
        e.tableau = true;
        return e;
    }

    Expression operationElementaire(const std::string& op, const Expression& a,
                                    const Expression& b, int ligne, bool comparaison) {
        TypeC t = combiner(a.type, b.type, ligne);
        if (comparaison) { t.base = TypeC::Base::Logique; t.complexe = false; }
        bool complexe = a.type.complexe || b.type.complexe;
        if (complexe) {
            TypeC ta = elementDe(a.type), tb = elementDe(b.type), te = elementDe(t);
            if (t.estScalaire() && !a.tableau && !b.tableau) {
                std::string ea = a.code, eb = b.code;
                return scalaire(operationComplexe(op, ea, ta, eb, tb, te, ligne), t);
            }
            std::string nom = nouveauTableau(t);
            corps << marge() << "for (int mlb_k = 0; mlb_k < " << t.elements() << "; mlb_k++) {\n";
            indentation++;
            std::string ea = element(a, a.type.estScalaire() ? "0" : "mlb_k");
            std::string eb = element(b, b.type.estScalaire() ? "0" : "mlb_k");
            corps << marge() << nom << "[mlb_k] = "
                  << operationComplexe(op, ea, ta, eb, tb, te, ligne) << ";\n";
            indentation--;
            corps << marge() << "}\n";
            Expression e;
            e.code = nom;
            e.type = t;
            e.tableau = true;
            return e;
        }
        std::string cop = op;
        if (op == "~=") cop = "!=";
        if (op == ".*" || op == "*") cop = "*";
        if (op == "./" || op == "/") cop = "/";
        if (op == "&&") cop = "&&";
        if (op == "||") cop = "||";
        if (op == "&") cop = "&&";
        if (op == "|") cop = "||";
        bool puissance = (op == "^" || op == ".^");
        if (t.estScalaire() && !a.tableau && !b.tableau) {
            std::string code;
            if (puissance) {
                aides.insert("pow");
                code = "pow((double)(" + a.code + "), (double)(" + b.code + "))";
            } else {
                code = "((" + a.code + ") " + cop + " (" + b.code + "))";
            }
            if (t.entier() && !comparaison) code = convertir(code, t);
            return scalaire(code, t);
        }
        // Au moins un tableau : boucle élément par élément.
        std::string nom = nouveauTableau(t);
        corps << marge() << "for (int mlb_k = 0; mlb_k < " << t.elements() << "; mlb_k++) {\n";
        indentation++;
        std::string ea = element(a, a.type.estScalaire() ? "0" : "mlb_k");
        std::string eb = element(b, b.type.estScalaire() ? "0" : "mlb_k");
        std::string valeur;
        if (puissance) {
            aides.insert("pow");
            valeur = "pow((double)" + ea + ", (double)" + eb + ")";
        } else {
            valeur = "(" + ea + " " + cop + " " + eb + ")";
        }
        corps << marge() << nom << "[mlb_k] = " << convertir(valeur, t) << ";\n";
        indentation--;
        corps << marge() << "}\n";
        Expression e;
        e.code = nom;
        e.type = t;
        e.tableau = true;
        return e;
    }

    Expression produitMatriciel(const Expression& a, const Expression& b, int ligne) {
        if (a.type.estScalaire() || b.type.estScalaire())
            return operationElementaire(".*", a, b, ligne, false);
        if (a.type.colonnes != b.type.lignes)
            refuser("inner matrix dimensions " + std::to_string(a.type.colonnes) + " and " +
                        std::to_string(b.type.lignes) + " must agree",
                    ligne);
        TypeC t = combinerBase(a.type, b.type, ligne);
        t.lignes = a.type.lignes;
        t.colonnes = b.type.colonnes;
        std::string nom = nouveauTableau(t);
        int M = a.type.lignes, K = a.type.colonnes, N = b.type.colonnes;
        if (t.complexe) {
            aides.insert("complexe");
            aides.insert("cplx_de");
            aides.insert("cadd");
            aides.insert("cmul");
            if (!accumulateurProduitComplexe) {
                declarations << "    matlibre_cplx mlb_sc;\n";
                accumulateurProduitComplexe = true;
            }
            TypeC cplx = typeComplexe();
            TypeC ea = elementDe(a.type), eb = elementDe(b.type);
            std::string ca = adapter(a.code + "[mlb_p * " + std::to_string(M) + " + mlb_i]", ea, cplx,
                                     ligne);
            std::string cb = adapter(b.code + "[mlb_j * " + std::to_string(K) + " + mlb_p]", eb, cplx,
                                     ligne);
            corps << marge() << "for (int mlb_j = 0; mlb_j < " << N << "; mlb_j++) {\n";
            indentation++;
            corps << marge() << "for (int mlb_i = 0; mlb_i < " << M << "; mlb_i++) {\n";
            indentation++;
            corps << marge() << "mlb_sc = matlibre_cplx_de(0.0, 0.0);\n";
            corps << marge() << "for (int mlb_p = 0; mlb_p < " << K
                  << "; mlb_p++) mlb_sc = matlibre_cadd(mlb_sc, matlibre_cmul(" << ca << ", " << cb
                  << "));\n";
            corps << marge() << nom << "[mlb_j * " << M << " + mlb_i] = mlb_sc;\n";
            indentation--;
            corps << marge() << "}\n";
            indentation--;
            corps << marge() << "}\n";
            Expression e;
            e.code = nom;
            e.type = t;
            e.tableau = true;
            return e;
        }
        if (!accumulateurProduit) {
            declarations << "    double mlb_s;\n";
            accumulateurProduit = true;
        }
        corps << marge() << "for (int mlb_j = 0; mlb_j < " << N << "; mlb_j++) {\n";
        indentation++;
        corps << marge() << "for (int mlb_i = 0; mlb_i < " << M << "; mlb_i++) {\n";
        indentation++;
        corps << marge() << "mlb_s = 0.0;\n";
        corps << marge() << "for (int mlb_p = 0; mlb_p < " << K << "; mlb_p++) mlb_s += (double)"
              << a.code << "[mlb_p * " << M << " + mlb_i] * (double)" << b.code << "[mlb_j * " << K
              << " + mlb_p];\n";
        corps << marge() << nom << "[mlb_j * " << M << " + mlb_i] = " << convertir("mlb_s", t) << ";\n";
        indentation--;
        corps << marge() << "}\n";
        indentation--;
        corps << marge() << "}\n";
        Expression e;
        e.code = nom;
        e.type = t;
        e.tableau = true;
        return e;
    }

    Expression transposer(const Expression& a, bool conjuguee) {
        TypeC t = a.type;
        std::swap(t.lignes, t.colonnes);
        bool conjuguer = conjuguee && a.type.complexe;
        if (a.type.estScalaire()) {
            if (!conjuguer) return a;
            aides.insert("complexe");
            aides.insert("cconj");
            return scalaire("matlibre_cconj(" + a.code + ")", t);
        }
        std::string nom = nouveauTableau(t);
        if (conjuguer) {
            aides.insert("complexe");
            aides.insert("cconj");
        }
        std::string lu = a.code + "[mlb_j * " + std::to_string(a.type.lignes) + " + mlb_i]";
        if (conjuguer) lu = "matlibre_cconj(" + lu + ")";
        corps << marge() << "for (int mlb_j = 0; mlb_j < " << a.type.colonnes << "; mlb_j++)\n";
        corps << marge() << "    for (int mlb_i = 0; mlb_i < " << a.type.lignes << "; mlb_i++)\n";
        corps << marge() << "        " << nom << "[mlb_i * " << a.type.colonnes << " + mlb_j] = "
              << lu << ";\n";
        Expression e;
        e.code = nom;
        e.type = t;
        e.tableau = true;
        return e;
    }

    // --- appels de fonctions ------------------------------------------------

    Expression appelIntrinseque(const std::string& nom, const std::vector<NoeudPtr>& args,
                                int ligne);

    // --- instructions ---------------------------------------------------
    void traduireBloc(const NoeudPtr& bloc);
    void traduireInstruction(const NoeudPtr& n);
    void affecter(const NoeudPtr& cible, const Expression& valeur, int ligne);

    // Indice linéaire, en C (base zéro), pour un accès A(i) ou A(i,j).
    std::string indiceLineaire(const std::vector<NoeudPtr>& args, const TypeC& t, int ligne) {
        if (args.size() == 1) {
            Expression i = traduire(args[0]);
            if (i.tableau) refuser("indexing with an array", ligne);
            if (i.type.complexe) refuser("indexing with a complex value", ligne);
            return "((int)(" + i.code + ") - 1)";
        }
        if (args.size() == 2) {
            Expression i = traduire(args[0]);
            Expression j = traduire(args[1]);
            if (i.tableau || j.tableau) refuser("indexing with an array", ligne);
            if (i.type.complexe || j.type.complexe)
                refuser("indexing with a complex value", ligne);
            return "(((int)(" + j.code + ") - 1) * " + std::to_string(t.lignes) + " + (int)(" +
                   i.code + ") - 1)";
        }
        refuser("indexing with more than two subscripts", ligne);
    }
};

Expression Traducteur::traduire(const NoeudPtr& n) {
    if (!n) refuser("an empty expression", 0);
    switch (n->type) {
        case TypeN::Nombre: {
            std::ostringstream o;
            o.precision(17);
            o << n->nombre;
            TypeC t;
            if (n->imaginaire) {
                aides.insert("complexe");
                aides.insert("cplx_de");
                t.complexe = true;
                return scalaire("matlibre_cplx_de(0.0, " + o.str() + ")", t);
            }
            return scalaire(o.str(), t);
        }
        case TypeN::Litteral: {
            // Une chaîne devient un tableau de caractères, comme en MATLAB.
            TypeC t;
            t.base = TypeC::Base::Caractere;
            t.lignes = 1;
            t.colonnes = (int)n->texte.size();
            std::string nom = nouveauTableau(t);
            for (std::size_t k = 0; k < n->texte.size(); ++k)
                corps << marge() << nom << "[" << k << "] = " << (int)n->texte[k] << ";\n";
            Expression e;
            e.code = nom;
            e.type = t;
            e.tableau = true;
            return e;
        }
        case TypeN::Ident: {
            auto p = variables.find(n->texte);
            if (p == variables.end()) {
                // Constantes connues du langage.
                if (n->texte == "pi") return scalaire("3.14159265358979323846", TypeC{});
                if (n->texte == "e") return scalaire("2.71828182845904523536", TypeC{});
                if (n->texte == "Inf" || n->texte == "inf")
                    return scalaire("INFINITY", TypeC{});
                if (n->texte == "NaN" || n->texte == "nan") return scalaire("NAN", TypeC{});
                if (n->texte == "i" || n->texte == "j" || n->texte == "I" ||
                    n->texte == "J") {
                    // Aucune variable ne les cache : c'est l'unité imaginaire.
                    aides.insert("complexe");
                    aides.insert("cplx_de");
                    TypeC t;
                    t.complexe = true;
                    return scalaire("matlibre_cplx_de(0.0, 1.0)", t);
                }
                if (n->texte == "true") {
                    TypeC t; t.base = TypeC::Base::Logique;
                    return scalaire("1", t);
                }
                if (n->texte == "false") {
                    TypeC t; t.base = TypeC::Base::Logique;
                    return scalaire("0", t);
                }
                // Fonction sans argument.
                std::vector<NoeudPtr> aucun;
                return appelIntrinseque(n->texte, aucun, n->ligne);
            }
            Expression e;
            e.type = p->second;
            e.code = n->texte;
            e.tableau = !p->second.estScalaire();
            return e;
        }
        case TypeN::OpBinaire: {
            const std::string& op = n->texte;
            if (op == "*") {
                Expression a = traduire(n->enfants[0]);
                Expression b = traduire(n->enfants[1]);
                return produitMatriciel(a, b, n->ligne);
            }
            Expression a = traduire(n->enfants[0]);
            Expression b = traduire(n->enfants[1]);
            bool comparaison = (op == "==" || op == "~=" || op == "<" || op == ">" ||
                                op == "<=" || op == ">=" || op == "&" || op == "|" ||
                                op == "&&" || op == "||");
            if (op == "\\" || op == ".\\")
                refuser("left division", n->ligne);
            if (op == "/" && b.tableau && !b.type.estScalaire())
                refuser("matrix right division", n->ligne);
            return operationElementaire(op, a, b, n->ligne, comparaison);
        }
        case TypeN::OpUnaire: {
            Expression a = traduire(n->enfants[0]);
            if (n->texte == "+") return a;
            bool negation = (n->texte == "~" || n->texte == "!");
            TypeC t = a.type;
            if (negation) { t.base = TypeC::Base::Logique; t.complexe = false; }
            if (a.type.complexe) {
                // « -z » nie les deux parties ; « ~z » teste la nullité.
                aides.insert("complexe");
                if (!negation) aides.insert("cneg");
                TypeC ta = elementDe(a.type);
                auto valeurDe = [&](const std::string& code) {
                    return negation ? "(!" + estVrai(code, ta) + ")"
                                    : "matlibre_cneg(" + code + ")";
                };
                if (!a.tableau) return scalaire(valeurDe(a.code), t);
                std::string nom = nouveauTableau(t);
                corps << marge() << "for (int mlb_k = 0; mlb_k < " << t.elements() << "; mlb_k++) " << nom
                      << "[mlb_k] = " << valeurDe(a.code + "[mlb_k]") << ";\n";
                Expression e;
                e.code = nom;
                e.type = t;
                e.tableau = true;
                return e;
            }
            std::string prefixe = negation ? "!" : "-";
            if (!a.tableau) return scalaire("(" + prefixe + "(" + a.code + "))", t);
            std::string nom = nouveauTableau(t);
            corps << marge() << "for (int mlb_k = 0; mlb_k < " << t.elements() << "; mlb_k++) " << nom
                  << "[mlb_k] = " << convertir(prefixe + "(" + a.code + "[mlb_k])", t) << ";\n";
            Expression e;
            e.code = nom;
            e.type = t;
            e.tableau = true;
            return e;
        }
        case TypeN::OpPostfixe: {
            Expression a = traduire(n->enfants[0]);
            return transposer(a, n->texte == "'");
        }
        case TypeN::Plage: {
            // Une plage sert dans les boucles ; hors boucle, elle donne un
            // vecteur ligne de taille connue.
            Expression debut = traduire(n->enfants[0]);
            Expression pas = n->enfants[1] ? traduire(n->enfants[1]) : scalaire("1", TypeC{});
            Expression fin = traduire(n->enfants[2]);
            double d, p, f;
            if (!constanteDe(debut.code, d) || !constanteDe(pas.code, p) ||
                !constanteDe(fin.code, f))
                refuser("a range whose bounds are not compile-time constants", n->ligne);
            int compte = p == 0 ? 0 : (int)std::floor((f - d) / p + 1e-12) + 1;
            if (compte < 0) compte = 0;
            TypeC t;
            t.lignes = 1;
            t.colonnes = compte;
            std::string nom = nouveauTableau(t);
            corps << marge() << "for (int mlb_k = 0; mlb_k < " << compte << "; mlb_k++) " << nom
                  << "[mlb_k] = " << d << " + mlb_k * (" << p << ");\n";
            Expression e;
            e.code = nom;
            e.type = t;
            e.tableau = true;
            return e;
        }
        case TypeN::Matrice: {
            // Littéral de matrice : toutes les cases doivent être scalaires.
            std::vector<std::vector<Expression>> rangees;
            for (const auto& r : n->rangees) {
                std::vector<Expression> ligne;
                for (const auto& x : r) ligne.push_back(traduire(x));
                rangees.push_back(ligne);
            }
            int nl = (int)rangees.size();
            int nc = rangees.empty() ? 0 : (int)rangees[0].size();
            TypeC t;
            for (const auto& r : rangees) {
                if ((int)r.size() != nc) refuser("a matrix with ragged rows", n->ligne);
                for (const auto& x : r) {
                    if (x.tableau && !x.type.estScalaire())
                        refuser("concatenating arrays", n->ligne);
                    t = combiner(t, x.type, n->ligne);
                }
            }
            t.lignes = nl;
            t.colonnes = nc;
            std::string nom = nouveauTableau(t);
            for (int i = 0; i < nl; ++i)
                for (int j = 0; j < nc; ++j) {
                    const Expression& x = rangees[(std::size_t)i][(std::size_t)j];
                    corps << marge() << nom << "[" << (j * nl + i) << "] = "
                          << adapter(element(x, "0"), elementDe(x.type), elementDe(t), n->ligne)
                          << ";\n";
                }
            Expression e;
            e.code = nom;
            e.type = t;
            e.tableau = true;
            return e;
        }
        case TypeN::Acces: {
            if (n->enfants.empty() || n->enfants[0]->type != TypeN::Ident)
                refuser("an indexed expression that is not a simple name", n->ligne);
            const std::string& nom = n->enfants[0]->texte;
            if (n->acces.size() != 1 || n->acces[0].genre != '(')
                refuser("cell or field indexing", n->ligne);
            auto p = variables.find(nom);
            if (p == variables.end()) return appelIntrinseque(nom, n->acces[0].args, n->ligne);
            const TypeC& t = p->second;
            std::string indice = indiceLineaire(n->acces[0].args, t, n->ligne);
            TypeC r = t;
            r.lignes = 1;
            r.colonnes = 1;
            return scalaire(nom + "[" + indice + "]", r);
        }
        default:
            refuser("this expression", n->ligne);
    }
}


// --- fonctions intrinsèques -------------------------------------------------

namespace {

// Fonctions à un argument qui existent telles quelles en C, sur des doubles.
const std::map<std::string, std::string>& mathUnaires() {
    static const std::map<std::string, std::string> m = {
        {"abs", "fabs"},   {"sqrt", "sqrt"},   {"exp", "exp"},     {"log", "log"},
        {"log2", "log2"},  {"log10", "log10"}, {"sin", "sin"},     {"cos", "cos"},
        {"tan", "tan"},    {"asin", "asin"},   {"acos", "acos"},   {"atan", "atan"},
        {"sinh", "sinh"},  {"cosh", "cosh"},   {"tanh", "tanh"},   {"floor", "floor"},
        {"ceil", "ceil"},  {"round", "round"}, {"fix", "trunc"},   {"sign", "matlibre_signe"},
        {"cbrt", "cbrt"},  {"expm1", "expm1"}, {"log1p", "log1p"}, {"gamma", "tgamma"},
        {"erf", "erf"},    {"erfc", "erfc"}};
    return m;
}

}  // namespace

Expression Traducteur::appelIntrinseque(const std::string& nom,
                                        const std::vector<NoeudPtr>& args, int ligne) {
    // --- fonctions propres aux complexes -----------------------------------
    if (nom == "complex") {
        if (args.empty() || args.size() > 2)
            refuser("complex with this number of arguments", ligne);
        Expression a = traduire(args[0]);
        aides.insert("complexe");
        aides.insert("cplx_de");
        TypeC cplx = typeComplexe();
        if (args.size() == 1) {
            TypeC t = a.type;
            t.complexe = true;
            verifierComplexe(t, ligne);
            TypeC ta = elementDe(a.type);
            return appliquer(a, t, [&](const std::string& c) {
                return adapter(c, ta, cplx, ligne);
            });
        }
        Expression b = traduire(args[1]);
        if (a.type.complexe || b.type.complexe)
            refuser("complex with an argument that is already complex", ligne);
        TypeC t = combiner(a.type, b.type, ligne);
        t.complexe = true;
        verifierComplexe(t, ligne);
        if (!a.tableau && !b.tableau)
            return scalaire("matlibre_cplx_de((double)(" + a.code + "), (double)(" + b.code +
                                "))",
                            t);
        std::string cible = nouveauTableau(t);
        corps << marge() << "for (int mlb_k = 0; mlb_k < " << t.elements() << "; mlb_k++) " << cible
              << "[mlb_k] = matlibre_cplx_de((double)"
              << element(a, a.type.estScalaire() ? "0" : "mlb_k") << ", (double)"
              << element(b, b.type.estScalaire() ? "0" : "mlb_k") << ");\n";
        Expression e;
        e.code = cible;
        e.type = t;
        e.tableau = true;
        return e;
    }
    if (nom == "real" || nom == "imag") {
        if (args.size() != 1) refuser(nom + " with more than one argument", ligne);
        Expression a = traduire(args[0]);
        TypeC t = a.type;
        t.complexe = false;
        if (!a.type.complexe) {
            if (nom == "real") return a;
            return appliquer(a, t, [](const std::string&) { return std::string("0"); });
        }
        std::string membre = nom == "real" ? ".re" : ".im";
        return appliquer(a, t,
                         [membre](const std::string& c) { return "(" + c + ")" + membre; });
    }
    if (nom == "conj") {
        if (args.size() != 1) refuser("conj with more than one argument", ligne);
        Expression a = traduire(args[0]);
        if (!a.type.complexe) return a;
        aides.insert("complexe");
        aides.insert("cconj");
        return appliquer(a, a.type,
                         [](const std::string& c) { return "matlibre_cconj(" + c + ")"; });
    }
    if (nom == "angle") {
        if (args.size() != 1) refuser("angle with more than one argument", ligne);
        Expression a = traduire(args[0]);
        TypeC t = a.type;
        t.complexe = false;
        t.base = TypeC::Base::Double;
        if (!a.type.complexe)
            return appliquer(a, t, [](const std::string& c) {
                return "atan2(0.0, (double)(" + c + "))";
            });
        aides.insert("complexe");
        aides.insert("cangle");
        return appliquer(a, t,
                         [](const std::string& c) { return "matlibre_cangle(" + c + ")"; });
    }
    if (nom == "isreal") {
        if (args.size() != 1) refuser("isreal with more than one argument", ligne);
        Expression a = traduire(args[0]);
        TypeC t;
        t.base = TypeC::Base::Logique;
        return scalaire(a.type.complexe ? "0" : "1", t);
    }

    auto u = mathUnaires().find(nom);
    if (u != mathUnaires().end()) {
        if (args.size() != 1) refuser(nom + " with this number of arguments", ligne);
        if (nom == "sign") aides.insert("signe");
        Expression a = traduire(args[0]);
        if (a.type.complexe) {
            // Seules abs, sqrt, exp et log ont un sens sur un complexe dans
            // ce sous-ensemble ; le reste est refusé plutôt qu'approché.
            aides.insert("complexe");
            TypeC t = a.type;
            std::string appel;
            if (nom == "abs") {
                appel = "cabs";
                t.complexe = false;
                t.base = TypeC::Base::Double;
            } else if (nom == "sqrt") appel = "csqrt";
            else if (nom == "exp") appel = "cexp";
            else if (nom == "log") appel = "clog";
            else refuser(nom + " of a complex value", ligne);
            aides.insert(appel);
            return appliquer(a, t, [appel](const std::string& c) {
                return "matlibre_" + appel + "(" + c + ")";
            });
        }
        TypeC t = a.type;
        if (nom == "sqrt" || nom == "log" || nom == "log2" || nom == "log10") {
            // Comme MATLAB Coder : sur un réel, ces fonctions rendent NaN là
            // où MATLAB rendrait un complexe. On le signale, on n'invente pas.
            std::string avis = "Line " + std::to_string(ligne) + ": " + nom +
                               " of a real value returns NaN for a negative argument, "
                               "where MATLAB returns a complex result. Write " +
                               nom + "(complex(x)) if the argument can be negative.";
            if (std::find(avertissements.begin(), avertissements.end(), avis) ==
                avertissements.end())
                avertissements.push_back(avis);
        }
        if (t.entier() && (nom == "sqrt" || nom == "exp" || nom == "log"))
            t.base = TypeC::Base::Double;
        if (!a.tableau)
            return scalaire(convertir(u->second + "((double)(" + a.code + "))", t), t);
        std::string cible = nouveauTableau(t);
        corps << marge() << "for (int mlb_k = 0; mlb_k < " << t.elements() << "; mlb_k++) " << cible
              << "[mlb_k] = " << convertir(u->second + "((double)" + a.code + "[mlb_k])", t) << ";\n";
        Expression e;
        e.code = cible;
        e.type = t;
        e.tableau = true;
        return e;
    }
    if (nom == "mod" || nom == "rem" || nom == "atan2" || nom == "hypot" || nom == "power") {
        if (args.size() != 2) refuser(nom + " with this number of arguments", ligne);
        Expression a = traduire(args[0]);
        Expression b = traduire(args[1]);
        if (a.type.complexe || b.type.complexe) {
            if (nom != "power") refuser(nom + " of a complex value", ligne);
            return operationElementaire(".^", a, b, ligne, false);
        }
        TypeC t = combiner(a.type, b.type, ligne);
        std::string appel;
        if (nom == "mod") { aides.insert("mod"); appel = "matlibre_mod"; }
        else if (nom == "rem") appel = "fmod";
        else if (nom == "atan2") appel = "atan2";
        else if (nom == "hypot") appel = "hypot";
        else appel = "pow";
        if (!a.tableau && !b.tableau)
            return scalaire(convertir(appel + "((double)(" + a.code + "), (double)(" + b.code +
                                          "))",
                                      t),
                            t);
        std::string cible = nouveauTableau(t);
        corps << marge() << "for (int mlb_k = 0; mlb_k < " << t.elements() << "; mlb_k++) " << cible
              << "[mlb_k] = "
              << convertir(appel + "((double)" + element(a, a.type.estScalaire() ? "0" : "mlb_k") +
                               ", (double)" + element(b, b.type.estScalaire() ? "0" : "mlb_k") + ")",
                           t)
              << ";\n";
        Expression e;
        e.code = cible;
        e.type = t;
        e.tableau = true;
        return e;
    }
    if (nom == "min" || nom == "max") {
        if (args.size() == 2) {
            Expression a = traduire(args[0]);
            Expression b = traduire(args[1]);
            if (a.type.complexe || b.type.complexe)
                refuser(nom + " of complex values", ligne);
            TypeC t = combiner(a.type, b.type, ligne);
            std::string op = nom == "min" ? "<" : ">";
            if (!a.tableau && !b.tableau) {
                std::string code = "(((" + a.code + ") " + op + " (" + b.code + ")) ? (" +
                                   a.code + ") : (" + b.code + "))";
                return scalaire(convertir(code, t), t);
            }
            std::string cible = nouveauTableau(t);
            std::string ea = element(a, a.type.estScalaire() ? "0" : "mlb_k");
            std::string eb = element(b, b.type.estScalaire() ? "0" : "mlb_k");
            std::string choix = "((" + ea + " " + op + " " + eb + ") ? " + ea + " : " + eb + ")";
            corps << marge() << "for (int mlb_k = 0; mlb_k < " << t.elements() << "; mlb_k++) "
                  << cible << "[mlb_k] = " << convertir(choix, t) << ";\n";
            Expression e;
            e.code = cible;
            e.type = t;
            e.tableau = true;
            return e;
        }
        if (args.size() == 1) {
            Expression a = traduire(args[0]);
            if (a.type.complexe) refuser(nom + " of complex values", ligne);
            if (!a.tableau) return a;
            TypeC t = a.type;
            t.lignes = 1;
            t.colonnes = 1;
            std::string acc = nouvelAccumulateur(t.nomC(), a.code + "[0]");
            corps << marge() << "for (int mlb_k = 1; mlb_k < " << a.type.elements() << "; mlb_k++) if ("
                  << a.code << "[mlb_k] " << (nom == "min" ? "<" : ">") << " " << acc << ") " << acc
                  << " = " << a.code << "[mlb_k];\n";
            return scalaire(acc, t);
        }
        refuser(nom + " with this number of arguments", ligne);
    }
    if (nom == "sum" || nom == "prod" || nom == "mean") {
        if (args.size() != 1) refuser(nom + " with more than one argument", ligne);
        Expression a = traduire(args[0]);
        TypeC t = a.type;
        t.lignes = 1;
        t.colonnes = 1;
        if (!a.tableau) return a;
        if (a.type.complexe) {
            aides.insert("complexe");
            aides.insert("cplx_de");
            aides.insert(nom == "prod" ? "cmul" : "cadd");
            std::string acc = nouvelAccumulateur(
                "matlibre_cplx",
                nom == "prod" ? "matlibre_cplx_de(1.0, 0.0)" : "matlibre_cplx_de(0.0, 0.0)");
            corps << marge() << "for (int mlb_k = 0; mlb_k < " << a.type.elements() << "; mlb_k++) " << acc
                  << " = matlibre_" << (nom == "prod" ? "cmul" : "cadd") << "(" << acc << ", "
                  << a.code << "[mlb_k]);\n";
            if (nom == "mean") {
                corps << marge() << acc << ".re /= " << a.type.elements() << ".0;\n";
                corps << marge() << acc << ".im /= " << a.type.elements() << ".0;\n";
            }
            return scalaire(acc, t);
        }
        std::string acc = nouvelAccumulateur("double", nom == "prod" ? "1.0" : "0.0");
        corps << marge() << "for (int mlb_k = 0; mlb_k < " << a.type.elements() << "; mlb_k++) " << acc
              << " " << (nom == "prod" ? "*=" : "+=") << " (double)" << a.code << "[mlb_k];\n";
        if (nom == "mean") {
            corps << marge() << acc << " /= " << a.type.elements() << ".0;\n";
            t.base = TypeC::Base::Double;
        }
        return scalaire(convertir(acc, t), t);
    }
    if (nom == "numel" || nom == "length") {
        if (args.size() != 1) refuser(nom + " with more than one argument", ligne);
        Expression a = traduire(args[0]);
        int v = nom == "numel" ? a.type.elements()
                               : std::max(a.type.lignes, a.type.colonnes);
        TypeC t;
        return scalaire(std::to_string(v), t);
    }
    if (nom == "size") {
        if (args.empty()) refuser("size with no argument", ligne);
        Expression a = traduire(args[0]);
        if (args.size() == 2) {
            Expression d = traduire(args[1]);
            double dim;
            if (!constanteDe(d.code, dim))
                refuser("size with a dimension that is not a constant", ligne);
            TypeC t;
            return scalaire(std::to_string((int)dim == 1 ? a.type.lignes : a.type.colonnes), t);
        }
        TypeC t;
        t.lignes = 1;
        t.colonnes = 2;
        std::string cible = nouveauTableau(t);
        corps << marge() << cible << "[0] = " << a.type.lignes << ";\n";
        corps << marge() << cible << "[1] = " << a.type.colonnes << ";\n";
        Expression e;
        e.code = cible;
        e.type = t;
        e.tableau = true;
        return e;
    }
    if (nom == "zeros" || nom == "ones" || nom == "eye") {
        TypeC t;
        int nl = 1, nc = 1;
        std::vector<double> dims;
        for (const auto& a : args) {
            Expression x = traduire(a);
            double v;
            if (!constanteDe(x.code, v))
                refuser(nom + " with a size that is not a compile-time constant", ligne);
            dims.push_back(v);
        }
        if (dims.size() == 1) { nl = (int)dims[0]; nc = (int)dims[0]; }
        else if (dims.size() >= 2) { nl = (int)dims[0]; nc = (int)dims[1]; }
        t.lignes = nl;
        t.colonnes = nc;
        std::string cible = nouveauTableau(t);
        if (nom == "eye") {
            corps << marge() << "for (int mlb_k = 0; mlb_k < " << t.elements() << "; mlb_k++) " << cible
                  << "[mlb_k] = 0;\n";
            corps << marge() << "for (int mlb_k = 0; mlb_k < " << std::min(nl, nc) << "; mlb_k++) " << cible
                  << "[mlb_k * " << nl << " + mlb_k] = 1;\n";
        } else {
            corps << marge() << "for (int mlb_k = 0; mlb_k < " << t.elements() << "; mlb_k++) " << cible
                  << "[mlb_k] = " << (nom == "ones" ? "1" : "0") << ";\n";
        }
        Expression e;
        e.code = cible;
        e.type = t;
        e.tableau = true;
        return e;
    }
    if (nom == "double" || nom == "single" || nom == "int8" || nom == "int16" ||
        nom == "int32" || nom == "int64" || nom == "uint8" || nom == "uint16" ||
        nom == "uint32" || nom == "uint64" || nom == "logical" || nom == "char") {
        if (args.size() != 1) refuser(nom + " with more than one argument", ligne);
        Expression a = traduire(args[0]);
        TypeC t = typeDepuisTexte(nom, a.type.lignes, a.type.colonnes, a.type.complexe);
        verifierComplexe(t, ligne);
        TypeC ta = elementDe(a.type), te = elementDe(t);
        return appliquer(a, t, [&](const std::string& c) { return adapter(c, ta, te, ligne); });
    }
    if (nom == "true" || nom == "false") {
        TypeC t;
        t.base = TypeC::Base::Logique;
        return scalaire(nom == "true" ? "1" : "0", t);
    }
    if (nom == "pi") return scalaire("3.14159265358979323846", TypeC{});
    if (nom == "eps") return scalaire("2.2204460492503131e-16", TypeC{});
    if (nom == "Inf" || nom == "inf") return scalaire("INFINITY", TypeC{});
    if (nom == "NaN" || nom == "nan") return scalaire("NAN", TypeC{});
    if (nom == "isnan" || nom == "isinf" || nom == "isfinite") {
        if (args.size() != 1) refuser(nom + " with more than one argument", ligne);
        Expression a = traduire(args[0]);
        TypeC t = a.type;
        t.base = TypeC::Base::Logique;
        t.complexe = false;
        std::string appel = nom == "isnan" ? "isnan" : (nom == "isinf" ? "isinf" : "isfinite");
        if (a.type.complexe) {
            // MATLAB regarde les deux parties : NaN ou Inf sur l'une suffit,
            // et le complexe n'est fini que si les deux le sont.
            std::string lien = nom == "isfinite" ? " && " : " || ";
            return appliquer(a, t, [appel, lien](const std::string& c) {
                return "((" + appel + "((" + c + ").re) != 0)" + lien + "(" + appel + "((" + c +
                       ").im) != 0))";
            });
        }
        return appliquer(a, t, [appel](const std::string& c) {
            return "(" + appel + "((double)(" + c + ")) != 0)";
        });
    }
    refuser("a call to '" + nom + "'", ligne);
}

// --- instructions -------------------------------------------------------------

void Traducteur::affecter(const NoeudPtr& cible, const Expression& valeur, int ligne) {
    if (cible->type == TypeN::Ident) {
        const std::string& nom = cible->texte;
        verifierNom(nom, ligne);
        auto p = variables.find(nom);
        if (p == variables.end()) {
            declarer(nom, valeur.type);
            p = variables.find(nom);
        }
        TypeC t = p->second;
        if (t.lignes != valeur.type.lignes || t.colonnes != valeur.type.colonnes) {
            // La taille change : c'est licite en MATLAB, pas en C figé.
            refuser("changing the size of '" + nom + "' after its first assignment", ligne);
        }
        TypeC tv = elementDe(valeur.type), te = elementDe(t);
        if (t.estScalaire()) {
            corps << marge() << nom << " = " << adapter(element(valeur, "0"), tv, te, ligne)
                  << ";\n";
        } else {
            std::string source = valeur.tableau ? valeur.code + "[mlb_k]" : valeur.code;
            corps << marge() << "for (int mlb_k = 0; mlb_k < " << t.elements() << "; mlb_k++) " << nom
                  << "[mlb_k] = " << adapter(source, tv, te, ligne) << ";\n";
        }
        return;
    }
    if (cible->type == TypeN::Acces && !cible->enfants.empty() &&
        cible->enfants[0]->type == TypeN::Ident && cible->acces.size() == 1 &&
        cible->acces[0].genre == '(') {
        const std::string& nom = cible->enfants[0]->texte;
        verifierNom(nom, ligne);
        auto p = variables.find(nom);
        if (p == variables.end())
            refuser("assigning into '" + nom + "' before it is created", ligne);
        std::string indice = indiceLineaire(cible->acces[0].args, p->second, ligne);
        corps << marge() << nom << "[" << indice << "] = "
              << adapter(element(valeur, "0"), elementDe(valeur.type), elementDe(p->second),
                         ligne)
              << ";\n";
        return;
    }
    refuser("this assignment target", ligne);
}

void Traducteur::traduireInstruction(const NoeudPtr& n) {
    if (!n) return;
    switch (n->type) {
        case TypeN::Rien:
            return;
        case TypeN::Bloc:
            traduireBloc(n);
            return;
        case TypeN::Expression: {
            Expression e = traduire(n->enfants[0]);
            (void)e;
            return;
        }
        case TypeN::Affectation: {
            if (n->cibles.size() != 1)
                refuser("an assignment with several outputs", n->ligne);
            Expression v = traduire(n->enfants[0]);
            affecter(n->cibles[0], v, n->ligne);
            return;
        }
        case TypeN::Si: {
            // enfants : condition, bloc, [condition, bloc]..., [bloc sinon]
            std::size_t k = 0;
            bool premier = true;
            while (k + 1 < n->enfants.size()) {
                Expression c = traduire(n->enfants[k]);
                corps << marge() << (premier ? "if (" : "} else if (")
                      << estVrai(element(c, "0"), elementDe(c.type)) << ") {\n";
                premier = false;
                indentation++;
                traduireBloc(n->enfants[k + 1]);
                indentation--;
                k += 2;
            }
            if (k < n->enfants.size()) {
                corps << marge() << "} else {\n";
                indentation++;
                traduireBloc(n->enfants[k]);
                indentation--;
            }
            corps << marge() << "}\n";
            return;
        }
        case TypeN::TantQue: {
            // La condition doit être réévaluée : on la calcule dans la boucle.
            corps << marge() << "for (;;) {\n";
            indentation++;
            Expression c = traduire(n->enfants[0]);
            corps << marge() << "if (!" << estVrai(element(c, "0"), elementDe(c.type))
                  << ") break;\n";
            traduireBloc(n->enfants[1]);
            indentation--;
            corps << marge() << "}\n";
            return;
        }
        case TypeN::Pour: {
            if (n->cibles.empty() || n->cibles[0]->type != TypeN::Ident)
                refuser("a for loop whose variable is not a simple name", n->ligne);
            const std::string& v = n->cibles[0]->texte;
            verifierNom(v, n->ligne);
            const NoeudPtr& plage = n->enfants[0];
            if (plage->type == TypeN::Plage) {
                Expression debut = traduire(plage->enfants[0]);
                Expression pas = plage->enfants[1] ? traduire(plage->enfants[1])
                                                   : scalaire("1", TypeC{});
                Expression fin = traduire(plage->enfants[2]);
                if (debut.type.complexe || pas.type.complexe || fin.type.complexe)
                    refuser("a for loop whose bounds are complex", n->ligne);
                declarer(v, TypeC{});
                double p = 1.0;
                bool constant = constanteDe(pas.code, p);
                std::string comparaison = (!constant || p >= 0) ? " <= " : " >= ";
                corps << marge() << "for (" << v << " = " << element(debut, "0") << "; " << v
                      << comparaison << element(fin, "0") << "; " << v << " += "
                      << element(pas, "0") << ") {\n";
                indentation++;
                traduireBloc(n->enfants[1]);
                indentation--;
                corps << marge() << "}\n";
                return;
            }
            Expression liste = traduire(plage);
            if (!liste.tableau) refuser("a for loop over this expression", n->ligne);
            TypeC t = liste.type;
            t.lignes = 1;
            t.colonnes = 1;
            declarer(v, t);
            std::string k = temporaire();
            corps << marge() << "for (int " << k << " = 0; " << k << " < "
                  << liste.type.elements() << "; " << k << "++) {\n";
            indentation++;
            corps << marge() << v << " = " << liste.code << "[" << k << "];\n";
            traduireBloc(n->enfants[1]);
            indentation--;
            corps << marge() << "}\n";
            return;
        }
        case TypeN::Rupture:
            corps << marge() << "break;\n";
            return;
        case TypeN::Continuer:
            corps << marge() << "continue;\n";
            return;
        case TypeN::Retour:
            utiliseSortie = true;
            corps << marge() << "goto sortie;\n";
            return;
        case TypeN::Choix: {
            // switch : traduit en chaîne de if, ce qui accepte les cas non
            // entiers comme le fait MATLAB.
            Expression sujet = traduire(n->enfants[0]);
            if (sujet.type.complexe) refuser("a switch on a complex value", n->ligne);
            std::string v = nouvelAccumulateur("double",
                                              "(double)" + element(sujet, "0"));
            bool premier = true;
            std::size_t k = 1;
            while (k + 1 < n->enfants.size()) {
                Expression c = traduire(n->enfants[k]);
                if (c.type.complexe) refuser("a switch case that is complex", n->ligne);
                corps << marge() << (premier ? "if (" : "} else if (") << v
                      << " == (double)" << element(c, "0") << ") {\n";
                premier = false;
                indentation++;
                traduireBloc(n->enfants[k + 1]);
                indentation--;
                k += 2;
            }
            if (k < n->enfants.size()) {
                corps << marge() << (premier ? "if (1) {" : "} else {") << "\n";
                indentation++;
                traduireBloc(n->enfants[k]);
                indentation--;
            }
            if (!premier || k < n->enfants.size()) corps << marge() << "}\n";
            return;
        }
        default:
            refuser("this statement", n->ligne);
    }
}

void Traducteur::traduireBloc(const NoeudPtr& bloc) {
    if (!bloc) return;
    if (bloc->type != TypeN::Bloc) {
        traduireInstruction(bloc);
        return;
    }
    for (const auto& e : bloc->enfants) traduireInstruction(e);
}

// --- assemblage ------------------------------------------------------------------

namespace {

std::string preludeAides(const std::set<std::string>& aides) {
    std::ostringstream o;
    if (aides.count("saturer"))
        o << "/* Conversion vers un entier avec saturation, comme MATLAB. */\n"
             "static double matlibre_saturer(double x, double bas, double haut)\n"
             "{\n"
             "    if (isnan(x)) return 0.0;\n"
             "    x = (x < 0.0) ? -floor(-x + 0.5) : floor(x + 0.5);\n"
             "    if (x < bas) return bas;\n"
             "    if (x > haut) return haut;\n"
             "    return x;\n"
             "}\n\n";
    if (aides.count("signe"))
        o << "static double matlibre_signe(double x)\n"
             "{\n"
             "    if (x > 0.0) return 1.0;\n"
             "    if (x < 0.0) return -1.0;\n"
             "    return 0.0;\n"
             "}\n\n";
    if (aides.count("mod"))
        o << "/* mod de MATLAB : le résultat suit le signe du diviseur. */\n"
             "static double matlibre_mod(double x, double y)\n"
             "{\n"
             "    double r;\n"
             "    if (y == 0.0) return x;\n"
             "    r = fmod(x, y);\n"
             "    if (r != 0.0 && ((r < 0.0) != (y < 0.0))) r += y;\n"
             "    return r;\n"
             "}\n\n";

    // --- complexes : le type est dans l'en-tête, les opérations ici. -------
    // Le constructeur n'est écrit que s'il sert, directement ou par une des
    // aides qui l'appellent : gcc -Wall refuse une fonction statique inutile.
    bool construit = aides.count("cplx_de") != 0;
    for (const char* a : {"cadd", "csub", "cmul", "cdiv", "cneg", "cconj", "csqrt", "cexp",
                          "clog", "cpow"})
        if (aides.count(a)) construit = true;
    if (construit)
        o << "static matlibre_cplx matlibre_cplx_de(double re, double im)\n"
             "{\n"
             "    matlibre_cplx z;\n"
             "    z.re = re;\n"
             "    z.im = im;\n"
             "    return z;\n"
             "}\n\n";
    if (aides.count("cadd"))
        o << "static matlibre_cplx matlibre_cadd(matlibre_cplx a, matlibre_cplx b)\n"
             "{\n"
             "    return matlibre_cplx_de(a.re + b.re, a.im + b.im);\n"
             "}\n\n";
    if (aides.count("csub"))
        o << "static matlibre_cplx matlibre_csub(matlibre_cplx a, matlibre_cplx b)\n"
             "{\n"
             "    return matlibre_cplx_de(a.re - b.re, a.im - b.im);\n"
             "}\n\n";
    if (aides.count("cmul"))
        o << "static matlibre_cplx matlibre_cmul(matlibre_cplx a, matlibre_cplx b)\n"
             "{\n"
             "    return matlibre_cplx_de(a.re * b.re - a.im * b.im,\n"
             "                            a.re * b.im + a.im * b.re);\n"
             "}\n\n";
    if (aides.count("cdiv"))
        o << "/* Division de Smith : on divise par le plus grand des deux\n"
             " * termes du dénominateur, ce qui évite de déborder. */\n"
             "static matlibre_cplx matlibre_cdiv(matlibre_cplx a, matlibre_cplx b)\n"
             "{\n"
             "    double r, d;\n"
             "    if (fabs(b.re) >= fabs(b.im)) {\n"
             "        if (b.re == 0.0) return matlibre_cplx_de(a.re / b.re, a.im / b.re);\n"
             "        r = b.im / b.re;\n"
             "        d = b.re + b.im * r;\n"
             "        return matlibre_cplx_de((a.re + a.im * r) / d, (a.im - a.re * r) / d);\n"
             "    }\n"
             "    r = b.re / b.im;\n"
             "    d = b.re * r + b.im;\n"
             "    return matlibre_cplx_de((a.re * r + a.im) / d, (a.im * r - a.re) / d);\n"
             "}\n\n";
    if (aides.count("cneg"))
        o << "static matlibre_cplx matlibre_cneg(matlibre_cplx a)\n"
             "{\n"
             "    return matlibre_cplx_de(-a.re, -a.im);\n"
             "}\n\n";
    if (aides.count("cconj"))
        o << "static matlibre_cplx matlibre_cconj(matlibre_cplx a)\n"
             "{\n"
             "    return matlibre_cplx_de(a.re, -a.im);\n"
             "}\n\n";
    if (aides.count("cabs"))
        o << "static double matlibre_cabs(matlibre_cplx a)\n"
             "{\n"
             "    return hypot(a.re, a.im);\n"
             "}\n\n";
    if (aides.count("cangle"))
        o << "static double matlibre_cangle(matlibre_cplx a)\n"
             "{\n"
             "    return atan2(a.im, a.re);\n"
             "}\n\n";
    if (aides.count("csqrt"))
        o << "/* Racine principale : partie réelle positive ou nulle, et le\n"
             " * signe de la partie imaginaire suit celui de l'argument. */\n"
             "static matlibre_cplx matlibre_csqrt(matlibre_cplx a)\n"
             "{\n"
             "    double m = hypot(a.re, a.im);\n"
             "    double re, im;\n"
             "    if (m == 0.0) return matlibre_cplx_de(0.0, 0.0);\n"
             "    re = sqrt(0.5 * (m + a.re));\n"
             "    im = sqrt(0.5 * (m - a.re));\n"
             "    if (a.im < 0.0) im = -im;\n"
             "    return matlibre_cplx_de(re, im);\n"
             "}\n\n";
    if (aides.count("cexp"))
        o << "static matlibre_cplx matlibre_cexp(matlibre_cplx a)\n"
             "{\n"
             "    double m = exp(a.re);\n"
             "    return matlibre_cplx_de(m * cos(a.im), m * sin(a.im));\n"
             "}\n\n";
    if (aides.count("clog"))
        o << "/* Logarithme principal : la partie imaginaire est dans ]-pi, pi]. */\n"
             "static matlibre_cplx matlibre_clog(matlibre_cplx a)\n"
             "{\n"
             "    return matlibre_cplx_de(log(hypot(a.re, a.im)), atan2(a.im, a.re));\n"
             "}\n\n";
    if (aides.count("cpow"))
        o << "/* z^w : par carrés successifs si l'exposant est un entier réel,\n"
             " * comme MATLAB — sans quoi (1+2i)^2 ne rendrait pas -3+4i tout\n"
             " * rond ; sinon exp(w log z), avec les cas de MATLAB en zéro. */\n"
             "static matlibre_cplx matlibre_cpow(matlibre_cplx a, matlibre_cplx b)\n"
             "{\n"
             "    double m, arg, re, im, e, reste;\n"
             "    matlibre_cplx r, facteur;\n"
             "    if (b.im == 0.0 && b.re == floor(b.re) && fabs(b.re) <= 9007199254740992.0 &&\n"
             "        !(a.re == 0.0 && a.im == 0.0)) {\n"
             "        r = matlibre_cplx_de(1.0, 0.0);\n"
             "        facteur = a;\n"
             "        reste = fabs(b.re);\n"
             "        while (reste > 0.0) {\n"
             "            if (fmod(reste, 2.0) == 1.0) r = matlibre_cmul(r, facteur);\n"
             "            facteur = matlibre_cmul(facteur, facteur);\n"
             "            reste = floor(reste / 2.0);\n"
             "        }\n"
             "        if (b.re < 0.0) return matlibre_cdiv(matlibre_cplx_de(1.0, 0.0), r);\n"
             "        return r;\n"
             "    }\n"
             "    if (a.re == 0.0 && a.im == 0.0) {\n"
             "        if (b.re == 0.0 && b.im == 0.0) return matlibre_cplx_de(1.0, 0.0);\n"
             "        if (b.re > 0.0) return matlibre_cplx_de(0.0, 0.0);\n"
             "        return matlibre_cplx_de(INFINITY, 0.0);\n"
             "    }\n"
             "    m = hypot(a.re, a.im);\n"
             "    arg = atan2(a.im, a.re);\n"
             "    re = b.re * log(m) - b.im * arg;\n"
             "    im = b.re * arg + b.im * log(m);\n"
             "    e = exp(re);\n"
             "    return matlibre_cplx_de(e * cos(im), e * sin(im));\n"
             "}\n\n";
    if (aides.count("ceq"))
        o << "static bool matlibre_ceq(matlibre_cplx a, matlibre_cplx b)\n"
             "{\n"
             "    return a.re == b.re && a.im == b.im;\n"
             "}\n\n";
    return o.str();
}

}  // namespace

}  // namespace

ResultatC genererC(Interpreteur& it, const OptionsC& options) {
    auto f = it.fonctionFichier(options.nomFonction);
    if (!f)
        erreur("coder:codegen:notFound",
               "Function '" + options.nomFonction + "' not found on the path.");
    std::size_t nEntrees = f->entrees.size();
    for (const auto& liste : {f->entrees, f->sorties})
        for (const auto& nom : liste)
            if (nom.size() >= 4 && nom.compare(0, 4, "mlb_") == 0)
                erreur("coder:codegen:Unsupported",
                       "The name '" + nom +
                           "' uses the 'mlb_' prefix, which MatLibre Coder reserves for the "
                           "identifiers it generates.");
    if (f->variadiqueEntree())
        erreur("coder:codegen:Unsupported", "varargin is outside the translatable subset.");
    if (f->variadiqueSortie())
        erreur("coder:codegen:Unsupported", "varargout is outside the translatable subset.");
    if (options.entrees.size() != nEntrees)
        erreur("coder:codegen:ArgCount",
               "Function '" + options.nomFonction + "' takes " + std::to_string(nEntrees) +
                   " input(s) but " + std::to_string(options.entrees.size()) +
                   " type(s) were given in -args.");

    int nsorties = std::min<int>((int)f->sorties.size(), std::max(1, options.nargout));
    if (f->sorties.empty()) nsorties = 0;

    // Première passe : on traduit pour découvrir le type des sorties. La
    // signature en dépend, et donc la façon de déclarer les variables.
    std::vector<TypeC> typesSortie;
    {
        Traducteur sonde(it, options);
        sonde.nomFonction = options.prefixe + options.nomFonction;
        for (std::size_t k = 0; k < nEntrees; ++k) {
            sonde.variables[f->entrees[k]] = options.entrees[k];
            sonde.declarees.insert(f->entrees[k]);
        }
        sonde.traduireBloc(f->corps);
        for (int k = 0; k < nsorties; ++k) {
            auto p = sonde.variables.find(f->sorties[(std::size_t)k]);
            if (p == sonde.variables.end())
                erreur("coder:codegen:OutputNotSet",
                       "Output '" + f->sorties[(std::size_t)k] + "' is never assigned.");
            typesSortie.push_back(p->second);
        }
    }
    bool retourScalaireSonde = nsorties == 1 && !typesSortie.empty() &&
                               typesSortie[0].estScalaire();

    // Deuxième passe : les sorties tableaux sont des paramètres, il ne faut
    // pas les redéclarer dans le corps.
    Traducteur t(it, options);
    t.nomFonction = options.prefixe + options.nomFonction;
    for (std::size_t k = 0; k < nEntrees; ++k) {
        t.variables[f->entrees[k]] = options.entrees[k];
        t.declarees.insert(f->entrees[k]);
    }
    if (!retourScalaireSonde)
        for (int k = 0; k < nsorties; ++k)
            if (!typesSortie[(std::size_t)k].estScalaire()) {
                t.variables[f->sorties[(std::size_t)k]] = typesSortie[(std::size_t)k];
                t.declarees.insert(f->sorties[(std::size_t)k]);
            }
    t.traduireBloc(f->corps);

    // Un complexe qui n'apparaît que dans la signature exige quand même le
    // type : l'en-tête doit le définir.
    for (const auto& e : options.entrees)
        if (e.complexe) t.aides.insert("complexe");
    for (const auto& sortie : typesSortie)
        if (sortie.complexe) t.aides.insert("complexe");

    // Signature : les sorties tableaux, et toutes les sorties au-delà de la
    // première, passent par pointeur, comme le fait MATLAB Coder.
    std::ostringstream signature;
    bool retourScalaire = nsorties == 1 && typesSortie[0].estScalaire();
    if (nsorties == 0) signature << "void";
    else if (retourScalaire) signature << typesSortie[0].nomC();
    else signature << "void";
    signature << " " << t.nomFonction << "(";
    bool premier = true;
    for (std::size_t k = 0; k < nEntrees; ++k) {
        if (!premier) signature << ", ";
        premier = false;
        const TypeC& e = options.entrees[k];
        if (e.estScalaire()) signature << e.nomC() << " " << f->entrees[k];
        else signature << "const " << e.nomC() << " " << f->entrees[k] << "[" << e.elements()
                       << "]";
    }
    for (int k = 0; k < nsorties; ++k) {
        if (retourScalaire) break;
        if (!premier) signature << ", ";
        premier = false;
        const TypeC& s = typesSortie[(std::size_t)k];
        if (s.estScalaire()) signature << s.nomC() << " *" << f->sorties[(std::size_t)k];
        else signature << s.nomC() << " " << f->sorties[(std::size_t)k] << "["
                       << s.elements() << "]";
    }
    if (premier) signature << "void";
    signature << ")";

    std::ostringstream source;
    source << "/* " << t.nomFonction << ".c — produit par MatLibre Coder.\n"
           << " * Source : " << (f->fichier.empty() ? options.nomFonction : f->fichier)
           << "\n"
           << " * Signature MATLAB : " << options.nomFonction << "(";
    for (std::size_t k = 0; k < nEntrees; ++k) {
        if (k) source << ", ";
        source << options.entrees[k].nomMatlab() << " " << options.entrees[k].lignes << "x"
               << options.entrees[k].colonnes;
    }
    source << ")\n */\n";
    source << "#include <math.h>\n#include <stdint.h>\n#include <stdbool.h>\n";
    if (options.langage == "c++") source << "#include <cstddef>\n";
    // L'en-tête vient avant les aides : c'est lui qui porte matlibre_cplx.
    source << "#include \"" << t.nomFonction << ".h\"\n\n";
    source << preludeAides(t.aides);
    source << signature.str() << "\n{\n";

    // Déclarations en tête, puis le corps : les sorties scalaires passées
    // par pointeur sont renommées, pour ne pas heurter le paramètre.
    std::string texteCorps = t.declarations.str() + t.corps.str();
    // Les sorties passées par pointeur sont écrites dans une variable locale
    // puis recopiées : cela garde le corps identique au MATLAB.
    for (int k = 0; k < nsorties; ++k) {
        if (retourScalaire) break;
        const TypeC& s = typesSortie[(std::size_t)k];
        const std::string& nom = f->sorties[(std::size_t)k];
        if (!s.estScalaire()) continue;
        // Renomme la variable locale pour ne pas heurter le pointeur.
        std::string local = "mlb_" + nom;
        std::string cherche = nom;
        std::string remplace = local;
        std::string sortieTexte;
        for (std::size_t i = 0; i < texteCorps.size();) {
            std::size_t p = texteCorps.find(cherche, i);
            if (p == std::string::npos) {
                sortieTexte += texteCorps.substr(i);
                break;
            }
            bool avant = p == 0 || (!std::isalnum((unsigned char)texteCorps[p - 1]) &&
                                    texteCorps[p - 1] != '_');
            std::size_t apres = p + cherche.size();
            bool suit = apres >= texteCorps.size() ||
                        (!std::isalnum((unsigned char)texteCorps[apres]) &&
                         texteCorps[apres] != '_');
            sortieTexte += texteCorps.substr(i, p - i);
            sortieTexte += (avant && suit) ? remplace : cherche;
            i = apres;
        }
        texteCorps = sortieTexte;
    }
    source << texteCorps;
    if (t.utiliseSortie) source << "sortie:\n";
    if (retourScalaire) {
        source << "    return " << f->sorties[0] << ";\n";
    } else {
        for (int k = 0; k < nsorties; ++k) {
            const TypeC& s = typesSortie[(std::size_t)k];
            const std::string& nom = f->sorties[(std::size_t)k];
            if (s.estScalaire())
                source << "    *" << nom << " = mlb_" << nom << ";\n";
            // Les tableaux sont déjà écrits en place.
        }
        source << "    return;\n";
    }
    source << "}\n";

    std::ostringstream entete;
    std::string garde = t.nomFonction;
    for (auto& c : garde) c = (char)std::toupper((unsigned char)c);
    entete << "/* " << t.nomFonction << ".h — produit par MatLibre Coder. */\n";
    entete << "#ifndef " << garde << "_H\n#define " << garde << "_H\n\n";
    entete << "#include <stdint.h>\n#include <stdbool.h>\n\n";
    if (t.aides.count("complexe"))
        entete << "/* Nombre complexe : deux doubles, comme le creal_T de MATLAB Coder.\n"
                  " * La garde permet à plusieurs en-têtes produits de coexister. */\n"
                  "#ifndef MATLIBRE_CPLX_DEFINED\n"
                  "#define MATLIBRE_CPLX_DEFINED\n"
                  "typedef struct {\n"
                  "    double re;\n"
                  "    double im;\n"
                  "} matlibre_cplx;\n"
                  "#endif\n\n";
    if (options.langage == "c++") entete << "extern \"C\" {\n\n";
    entete << signature.str() << ";\n\n";
    if (options.langage == "c++") entete << "}\n\n";
    entete << "#endif\n";

    ResultatC r;
    r.source = source.str();
    r.entete = entete.str();
    r.avertissements = t.avertissements;
    r.fonctions.push_back(t.nomFonction);

    if (options.principal) {
        std::ostringstream principal;
        principal << "\n/* Programme de démonstration : appelle " << t.nomFonction
                  << " avec des entrées nulles. */\n";
        principal << "#include <stdio.h>\n\nint main(void)\n{\n";
        auto zero = [](const TypeC& x) { return x.complexe ? "{0, 0}" : "0"; };
        for (std::size_t k = 0; k < nEntrees; ++k) {
            const TypeC& e = options.entrees[k];
            if (e.estScalaire())
                principal << "    " << e.nomC() << " " << f->entrees[k] << " = " << zero(e)
                          << ";\n";
            else
                principal << "    " << e.nomC() << " " << f->entrees[k] << "["
                          << e.elements() << "] = {" << zero(e) << "};\n";
        }
        if (retourScalaire) {
            principal << "    " << typesSortie[0].nomC() << " r = " << t.nomFonction << "(";
            for (std::size_t k = 0; k < nEntrees; ++k) {
                if (k) principal << ", ";
                principal << f->entrees[k];
            }
            if (typesSortie[0].complexe)
                principal << ");\n    printf(\"%g %+gi\\n\", r.re, r.im);\n";
            else
                principal << ");\n    printf(\"%g\\n\", (double)r);\n";
        } else {
            for (int k = 0; k < nsorties; ++k) {
                const TypeC& s = typesSortie[(std::size_t)k];
                if (s.estScalaire())
                    principal << "    " << s.nomC() << " " << f->sorties[(std::size_t)k]
                              << " = " << zero(s) << ";\n";
                else
                    principal << "    " << s.nomC() << " " << f->sorties[(std::size_t)k] << "["
                              << s.elements() << "] = {" << zero(s) << "};\n";
            }
            principal << "    " << t.nomFonction << "(";
            bool p2 = true;
            for (std::size_t k = 0; k < nEntrees; ++k) {
                if (!p2) principal << ", ";
                p2 = false;
                principal << f->entrees[k];
            }
            for (int k = 0; k < nsorties; ++k) {
                if (!p2) principal << ", ";
                p2 = false;
                const TypeC& s = typesSortie[(std::size_t)k];
                if (s.estScalaire()) principal << "&" << f->sorties[(std::size_t)k];
                else principal << f->sorties[(std::size_t)k];
            }
            principal << ");\n";
        }
        principal << "    return 0;\n}\n";
        r.source += principal.str();
    }
    return r;
}


// --- interface MATLAB -------------------------------------------------------

namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)

TypeC typeDepuisValeur(const Valeur& v) {
    std::string classe = "double";
    switch (v.classe) {
        case Classe::Logique:   classe = "logical"; break;
        case Classe::Caractere: classe = "char"; break;
        case Classe::Simple:    classe = "single"; break;
        case Classe::Int8:      classe = "int8"; break;
        case Classe::Int16:     classe = "int16"; break;
        case Classe::Int32:     classe = "int32"; break;
        case Classe::Int64:     classe = "int64"; break;
        case Classe::UInt8:     classe = "uint8"; break;
        case Classe::UInt16:    classe = "uint16"; break;
        case Classe::UInt32:    classe = "uint32"; break;
        case Classe::UInt64:    classe = "uint64"; break;
        default:                classe = "double"; break;
    }
    return typeDepuisTexte(classe, v.nlignes(), v.ncolonnes(), v.estComplexe());
}

// matlibre_codegen(nom, typesCellule, options) -> struct{source, entete}
FONCTION(fnCodegen) {
    (void)nargout;
    if (args.empty())
        erreur("MATLAB:minrhs", "matlibre_codegen requires a function name.");
    OptionsC o;
    o.nomFonction = args[0].versTexte();
    if (args.size() > 1 && args[1].classe == Classe::Cellule)
        for (const auto& c : args[1].cellules) o.entrees.push_back(typeDepuisValeur(c));
    if (args.size() > 2 && args[2].estStructure()) {
        const Valeur& s = args[2];
        if (s.aChamp("nargout")) o.nargout = (int)s.champ("nargout", 0).scal();
        if (s.aChamp("langage")) o.langage = s.champ("langage", 0).versTexte();
        if (s.aChamp("prefixe")) o.prefixe = s.champ("prefixe", 0).versTexte();
        if (s.aChamp("principal")) o.principal = s.champ("principal", 0).scal() != 0;
    }
    ResultatC r = genererC(it, o);
    Valeur sortie = Valeur::structureVide();
    sortie.poserChamp("source", Valeur::texte(r.source));
    sortie.poserChamp("entete", Valeur::texte(r.entete));
    std::vector<Valeur> noms;
    for (const auto& n : r.fonctions) noms.push_back(Valeur::texte(n));
    sortie.poserChamp("fonctions", Valeur::celluleLigne(noms));
    std::vector<Valeur> avert;
    for (const auto& a : r.avertissements) avert.push_back(Valeur::texte(a));
    sortie.poserChamp("avertissements", Valeur::celluleLigne(avert));
    return {sortie};
}

}  // namespace

void enregistrerGenerationC(Interpreteur& it) {
    it.enregistrer("matlibre_codegen", fnCodegen, "coder",
                   "matlibre_codegen  Traduit une fonction MATLAB en C.");
}

}  // namespace matlibre
