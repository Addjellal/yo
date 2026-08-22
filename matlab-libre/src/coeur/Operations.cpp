#include "matlibre/Operations.h"

#include <algorithm>
#include <cmath>
#include <complex>

#include "matlibre/AlgebreLineaire.h"
#include "matlibre/Erreur.h"

namespace matlibre {

using cplx = std::complex<double>;

Dims dimsDiffusees(const Dims& a, const Dims& b) {
    std::size_t n = std::max(a.size(), b.size());
    Dims r(n, 1);
    for (std::size_t k = 0; k < n; ++k) {
        int x = k < a.size() ? a[k] : 1;
        int y = k < b.size() ? b[k] : 1;
        if (x == y) r[k] = x;
        else if (x == 1) r[k] = y;
        else if (y == 1) r[k] = x;
        else
            erreur("MATLAB:dimagree",
                   "Arrays have incompatible sizes for this operation.");
    }
    return r;
}

// Index linéaire dans « src » (dimensions d) correspondant à l'index
// linéaire « k » du résultat (dimensions rd), avec expansion implicite.
static std::size_t indexDiffuse(std::size_t k, const Dims& rd, const Dims& d) {
    std::size_t reste = k, idx = 0, pas = 1;
    for (std::size_t i = 0; i < rd.size(); ++i) {
        int taille = rd[i] > 0 ? rd[i] : 1;
        std::size_t coord = reste % (std::size_t)taille;
        reste /= (std::size_t)taille;
        int di = i < d.size() ? d[i] : 1;
        std::size_t c = (di == 1) ? 0 : coord;
        idx += c * pas;
        pas *= (std::size_t)std::max(1, di);
    }
    return idx;
}

Classe classeResultat(const Valeur& a, const Valeur& b, const std::string& op) {
    Classe ca = a.classe, cb = b.classe;
    if (classeEntiere(ca) && classeEntiere(cb)) {
        if (ca != cb)
            erreur("MATLAB:integers:numericTypeMismatch",
                   formater("Integers can only be combined with integers of the same "
                            "class, or scalar doubles. (%s)", op.c_str()));
        return ca;
    }
    if (classeEntiere(ca)) {
        if (cb == Classe::Double || cb == Classe::Simple || cb == Classe::Logique ||
            cb == Classe::Caractere)
            return ca;
        return ca;
    }
    if (classeEntiere(cb)) return cb;
    if (ca == Classe::Simple || cb == Classe::Simple) return Classe::Simple;
    return Classe::Double;
}

Valeur diffuser(const Valeur& a, const Valeur& b,
                const std::function<double(double, double)>& f, Classe forcee,
                bool logique) {
    Dims rd = dimsDiffusees(a.dims, b.dims);
    Valeur r;
    r.dims = rd;
    std::size_t n = produitDims(rd);
    r.re.resize(n);
    bool aSimple = a.nelem() == n && memeDims(a.dims, rd);
    bool bSimple = b.nelem() == n && memeDims(b.dims, rd);
    for (std::size_t k = 0; k < n; ++k) {
        std::size_t ia = aSimple ? k : indexDiffuse(k, rd, a.dims);
        std::size_t ib = bSimple ? k : indexDiffuse(k, rd, b.dims);
        r.re[k] = f(a.re.empty() ? 0.0 : a.re[ia], b.re.empty() ? 0.0 : b.re[ib]);
    }
    r.classe = logique ? Classe::Logique : forcee;
    if (!logique && (classeEntiere(forcee) || forcee == Classe::Simple))
        for (auto& x : r.re) x = saturer(x, forcee);
    r.normaliserDims();
    return r;
}

Valeur diffuserComplexe(
    const Valeur& a, const Valeur& b,
    const std::function<void(double, double, double, double, double&, double&)>& f) {
    Dims rd = dimsDiffusees(a.dims, b.dims);
    Valeur r;
    r.dims = rd;
    std::size_t n = produitDims(rd);
    r.re.resize(n);
    r.im.resize(n);
    for (std::size_t k = 0; k < n; ++k) {
        std::size_t ia = indexDiffuse(k, rd, a.dims);
        std::size_t ib = indexDiffuse(k, rd, b.dims);
        double ar = a.re.empty() ? 0 : a.re[ia];
        double ai = a.im.empty() ? 0 : a.im[ia];
        double br = b.re.empty() ? 0 : b.re[ib];
        double bi = b.im.empty() ? 0 : b.im[ib];
        f(ar, ai, br, bi, r.re[k], r.im[k]);
    }
    r.compacter();
    r.normaliserDims();
    return r;
}

Valeur appliquerReel(const Valeur& a, const std::function<double(double)>& f) {
    Valeur r = a;
    r.classe = (a.classe == Classe::Simple) ? Classe::Simple : Classe::Double;
    if (classeEntiere(a.classe)) r.classe = a.classe;
    r.chaines.clear();
    for (auto& x : r.re) x = f(x);
    if (classeEntiere(r.classe))
        for (auto& x : r.re) x = saturer(x, r.classe);
    return r;
}

// ------------------------------------------------------------ conversions

static Valeur preparer(const Valeur& v) {
    // char et logical participent aux calculs comme des doubles.
    if (v.classe == Classe::Caractere || v.classe == Classe::Logique) {
        Valeur r = v;
        r.classe = Classe::Double;
        return r;
    }
    if (v.classe == Classe::Chaine) {
        Valeur r = Valeur::texte(v.chaines.empty() ? std::string() : v.chaines[0]);
        r.classe = Classe::Double;
        return r;
    }
    return v;
}

static bool estChaineTexte(const Valeur& v) { return v.classe == Classe::Chaine; }

static std::string texteElement(const Valeur& v, std::size_t k) {
    if (v.classe == Classe::Chaine) return k < v.chaines.size() ? v.chaines[k] : std::string();
    if (v.classe == Classe::Caractere) return v.versTexte();
    double x = v.re.empty() ? 0.0 : v.re[std::min(k, v.re.size() - 1)];
    if (x == std::floor(x) && std::fabs(x) < 1e15) return formater("%g", x);
    return formater("%.5g", x);
}

// « "a" + "b" » concatène, comme dans MATLAB depuis R2017a.
static Valeur concatChaines(const Valeur& a, const Valeur& b) {
    Dims rd = dimsDiffusees(a.dims, b.dims);
    Valeur r;
    r.classe = Classe::Chaine;
    r.dims = rd;
    std::size_t n = produitDims(rd);
    r.chaines.resize(n);
    for (std::size_t k = 0; k < n; ++k) {
        std::size_t ia = indexDiffuse(k, rd, a.dims);
        std::size_t ib = indexDiffuse(k, rd, b.dims);
        r.chaines[k] = texteElement(a, ia) + texteElement(b, ib);
    }
    return r;
}

// --------------------------------------------------------------- opérateurs

static Valeur puissanceElement(const Valeur& a, const Valeur& b) {
    bool complexeNecessaire = a.estComplexe() || b.estComplexe();
    if (!complexeNecessaire) {
        // Une base négative avec un exposant fractionnaire donne un complexe.
        Dims rd = dimsDiffusees(a.dims, b.dims);
        std::size_t n = produitDims(rd);
        for (std::size_t k = 0; k < n && !complexeNecessaire; ++k) {
            double x = a.re.empty() ? 0 : a.re[indexDiffuse(k, rd, a.dims)];
            double y = b.re.empty() ? 0 : b.re[indexDiffuse(k, rd, b.dims)];
            if (x < 0 && y != std::floor(y)) complexeNecessaire = true;
        }
    }
    if (!complexeNecessaire)
        return diffuser(a, b, [](double x, double y) { return std::pow(x, y); },
                        classeResultat(a, b, ".^"));
    return diffuserComplexe(a, b,
                            [](double ar, double ai, double br, double bi, double& rr,
                               double& ri) {
                                cplx z = std::pow(cplx(ar, ai), cplx(br, bi));
                                rr = z.real();
                                ri = z.imag();
                            });
}

Valeur transposer(const Valeur& a, bool conjuguee) {
    if (a.dims.size() > 2)
        erreur("MATLAB:transpose:NDArray", "Transpose on ND array is not defined.");
    Valeur r = a;
    int l = a.nlignes(), c = a.ncolonnes();
    r.dims = {c, l};
    if (a.classe == Classe::Cellule) {
        r.cellules.resize(a.cellules.size());
        for (int i = 0; i < l; ++i)
            for (int k = 0; k < c; ++k) r.cellules[(std::size_t)k + (std::size_t)i * c] =
                a.cellules[(std::size_t)i + (std::size_t)k * l];
        return r;
    }
    if (a.classe == Classe::Chaine) {
        r.chaines.resize(a.chaines.size());
        for (int i = 0; i < l; ++i)
            for (int k = 0; k < c; ++k) r.chaines[(std::size_t)k + (std::size_t)i * c] =
                a.chaines[(std::size_t)i + (std::size_t)k * l];
        return r;
    }
    if (a.estStructure()) {
        r.detacherStructure();
        for (auto& kv : r.st->champs) {
            std::vector<Valeur> v(kv.second.size());
            for (int i = 0; i < l; ++i)
                for (int k = 0; k < c; ++k)
                    v[(std::size_t)k + (std::size_t)i * c] =
                        kv.second[(std::size_t)i + (std::size_t)k * l];
            kv.second = v;
        }
        return r;
    }
    r.re.resize(a.re.size());
    for (int i = 0; i < l; ++i)
        for (int k = 0; k < c; ++k)
            r.re[(std::size_t)k + (std::size_t)i * c] = a.re[(std::size_t)i + (std::size_t)k * l];
    if (!a.im.empty()) {
        r.im.resize(a.im.size());
        double signe = conjuguee ? -1.0 : 1.0;
        for (int i = 0; i < l; ++i)
            for (int k = 0; k < c; ++k)
                r.im[(std::size_t)k + (std::size_t)i * c] =
                    signe * a.im[(std::size_t)i + (std::size_t)k * l];
    }
    return r;
}

Valeur operationUnaire(const std::string& op, const Valeur& v) {
    if (op == "+") return v;
    if (op == "-") {
        Valeur a = preparer(v);
        Valeur r = a;
        for (auto& x : r.re) x = -x;
        for (auto& x : r.im) x = -x;
        if (classeEntiere(r.classe))
            for (auto& x : r.re) x = saturer(x, r.classe);
        return r;
    }
    if (op == "~") {
        Valeur a = preparer(v);
        Valeur r;
        r.classe = Classe::Logique;
        r.dims = a.dims;
        r.re.resize(a.re.size());
        for (std::size_t k = 0; k < a.re.size(); ++k) {
            double im = a.im.empty() ? 0.0 : a.im[k];
            r.re[k] = (a.re[k] == 0.0 && im == 0.0) ? 1.0 : 0.0;
        }
        return r;
    }
    erreur("MATLAB:UndefinedFunction", "Unknown unary operator '" + op + "'.");
}

static void verifierOperandes(const Valeur& a, const Valeur& b, const std::string& op) {
    if (a.classe == Classe::Cellule || b.classe == Classe::Cellule)
        erreur("MATLAB:UndefinedFunction",
               formater("Operator '%s' is not supported for operands of type 'cell'.",
                        op.c_str()));
    if (a.estStructure() || b.estStructure())
        erreur("MATLAB:UndefinedFunction",
               formater("Operator '%s' is not supported for operands of type 'struct'.",
                        op.c_str()));
}

// Cas le plus fréquent de tous : deux scalaires réels doubles. Le traiter
// à part évite le calcul des dimensions diffusées et l'indirection des
// std::function.
static bool scalaireSimple(const Valeur& v) {
    return v.classe == Classe::Double && v.im.empty() && v.re.size() == 1 &&
           v.dims.size() == 2 && v.dims[0] == 1 && v.dims[1] == 1;
}

Valeur operationBinaire(const std::string& op, const Valeur& ga, const Valeur& gb) {
    if (scalaireSimple(ga) && scalaireSimple(gb) && op.size() <= 2) {
        double x = ga.re[0], y = gb.re[0];
        switch (op[0]) {
            case '+': if (op.size() == 1) return Valeur::scalaire(x + y); break;
            case '-': if (op.size() == 1) return Valeur::scalaire(x - y); break;
            case '*': if (op.size() == 1) return Valeur::scalaire(x * y); break;
            case '/': if (op.size() == 1) return Valeur::scalaire(x / y); break;
            case '<':
                if (op.size() == 1) return Valeur::booleen(x < y);
                if (op[1] == '=') return Valeur::booleen(x <= y);
                break;
            case '>':
                if (op.size() == 1) return Valeur::booleen(x > y);
                if (op[1] == '=') return Valeur::booleen(x >= y);
                break;
            case '=': if (op.size() == 2 && op[1] == '=') return Valeur::booleen(x == y); break;
            case '~': if (op.size() == 2 && op[1] == '=') return Valeur::booleen(x != y); break;
            case '.':
                if (op.size() == 2) {
                    if (op[1] == '*') return Valeur::scalaire(x * y);
                    if (op[1] == '/') return Valeur::scalaire(x / y);
                }
                break;
            default: break;
        }
    }
    // Chaînes : « + » concatène ; les comparaisons se font sur le texte.
    if ((estChaineTexte(ga) || estChaineTexte(gb)) &&
        (op == "+" )) {
        return concatChaines(ga, gb);
    }
    if ((estChaineTexte(ga) || estChaineTexte(gb)) && (op == "==" || op == "~=")) {
        Dims rd = dimsDiffusees(ga.dims, gb.dims);
        Valeur r;
        r.classe = Classe::Logique;
        r.dims = rd;
        std::size_t n = produitDims(rd);
        r.re.resize(n);
        for (std::size_t k = 0; k < n; ++k) {
            std::string x = texteElement(ga, indexDiffuse(k, rd, ga.dims));
            std::string y = texteElement(gb, indexDiffuse(k, rd, gb.dims));
            bool egal = (x == y);
            r.re[k] = (op == "==") ? (egal ? 1 : 0) : (egal ? 0 : 1);
        }
        return r;
    }
    verifierOperandes(ga, gb, op);
    Valeur a = preparer(ga), b = preparer(gb);
    Classe cr = classeResultat(a, b, op);

    if (op == "+" || op == "-") {
        if (a.estComplexe() || b.estComplexe()) {
            double s = (op == "+") ? 1.0 : -1.0;
            return diffuserComplexe(a, b,
                                    [s](double ar, double ai, double br, double bi,
                                        double& rr, double& ri) {
                                        rr = ar + s * br;
                                        ri = ai + s * bi;
                                    });
        }
        if (op == "+")
            return diffuser(a, b, [](double x, double y) { return x + y; }, cr);
        return diffuser(a, b, [](double x, double y) { return x - y; }, cr);
    }
    if (op == ".*" || (op == "*" && (a.estScalaire() || b.estScalaire()))) {
        if (a.estComplexe() || b.estComplexe())
            return diffuserComplexe(a, b,
                                    [](double ar, double ai, double br, double bi,
                                       double& rr, double& ri) {
                                        rr = ar * br - ai * bi;
                                        ri = ar * bi + ai * br;
                                    });
        return diffuser(a, b, [](double x, double y) { return x * y; }, cr);
    }
    if (op == "./" || (op == "/" && b.estScalaire())) {
        if (a.estComplexe() || b.estComplexe())
            return diffuserComplexe(a, b,
                                    [](double ar, double ai, double br, double bi,
                                       double& rr, double& ri) {
                                        cplx z = cplx(ar, ai) / cplx(br, bi);
                                        rr = z.real();
                                        ri = z.imag();
                                    });
        if (classeEntiere(cr))
            return diffuser(a, b,
                            [](double x, double y) {
                                if (y == 0) return x > 0 ? INFINITY : (x < 0 ? -INFINITY : 0.0);
                                return x / y;
                            },
                            cr);
        return diffuser(a, b, [](double x, double y) { return x / y; }, cr);
    }
    if (op == ".\\" || (op == "\\" && a.estScalaire())) {
        return operationBinaire(op == ".\\" ? "./" : "/", gb, ga);
    }
    if (op == ".^") return puissanceElement(a, b);
    if (op == "^") {
        if (a.estScalaire() && b.estScalaire()) return puissanceElement(a, b);
        return puissanceMatrice(a, b);
    }
    if (op == "*") return produitMatrice(a, b);
    if (op == "/") return divisionDroite(a, b);
    if (op == "\\") return divisionGauche(a, b);

    if (op == "==" || op == "~=" || op == "<" || op == "<=" || op == ">" || op == ">=") {
        if ((a.estComplexe() || b.estComplexe()) && (op == "==" || op == "~=")) {
            Dims rd = dimsDiffusees(a.dims, b.dims);
            Valeur r;
            r.classe = Classe::Logique;
            r.dims = rd;
            std::size_t n = produitDims(rd);
            r.re.resize(n);
            for (std::size_t k = 0; k < n; ++k) {
                std::size_t ia = indexDiffuse(k, rd, a.dims);
                std::size_t ib = indexDiffuse(k, rd, b.dims);
                double ar = a.re.empty() ? 0 : a.re[ia], ai = a.im.empty() ? 0 : a.im[ia];
                double br = b.re.empty() ? 0 : b.re[ib], bi = b.im.empty() ? 0 : b.im[ib];
                bool egal = (ar == br && ai == bi);
                r.re[k] = (op == "==") ? egal : !egal;
            }
            return r;
        }
        std::function<double(double, double)> f;
        if (op == "==") f = [](double x, double y) { return (double)(x == y); };
        else if (op == "~=") f = [](double x, double y) { return (double)(x != y); };
        else if (op == "<") f = [](double x, double y) { return (double)(x < y); };
        else if (op == "<=") f = [](double x, double y) { return (double)(x <= y); };
        else if (op == ">") f = [](double x, double y) { return (double)(x > y); };
        else f = [](double x, double y) { return (double)(x >= y); };
        return diffuser(a, b, f, Classe::Logique, true);
    }
    if (op == "&")
        return diffuser(a, b, [](double x, double y) { return (double)(x != 0 && y != 0); },
                        Classe::Logique, true);
    if (op == "|")
        return diffuser(a, b, [](double x, double y) { return (double)(x != 0 || y != 0); },
                        Classe::Logique, true);
    erreur("MATLAB:UndefinedFunction", "Unknown operator '" + op + "'.");
}

// ------------------------------------------------------------ concaténation

Valeur valeurNulleDe(const Valeur& modele) {
    switch (modele.classe) {
        case Classe::Cellule: return Valeur::vide();
        case Classe::Caractere: return Valeur::texte(" ");
        case Classe::Chaine: return Valeur::chaine("");
        default: {
            Valeur z = Valeur::scalaire(0);
            z.classe = classeNumerique(modele.classe) || modele.classe == Classe::Logique
                           ? modele.classe
                           : Classe::Double;
            return z;
        }
    }
}

Valeur extraireElement(const Valeur& v, std::size_t k) {
    switch (v.classe) {
        case Classe::Cellule: {
            Valeur r = Valeur::celluleDims({1, 1});
            r.cellules[0] = k < v.cellules.size() ? v.cellules[k] : Valeur::vide();
            return r;
        }
        case Classe::Chaine: {
            Valeur r = Valeur::chaine(k < v.chaines.size() ? v.chaines[k] : std::string());
            return r;
        }
        case Classe::Structure:
        case Classe::Objet: {
            Valeur r;
            r.classe = v.classe;
            r.nomObjet = v.nomObjet;
            r.dims = {1, 1};
            r.st = std::make_shared<ChampsStructure>();
            if (v.st) {
                r.st->ordre = v.st->ordre;
                for (const auto& nom : v.st->ordre) {
                    const auto& col = v.st->champs.at(nom);
                    r.st->champs[nom] = {k < col.size() ? col[k] : Valeur::vide()};
                }
            }
            return r;
        }
        case Classe::Fonction: {
            Valeur r = v;
            r.dims = {1, 1};
            return r;
        }
        default: {
            Valeur r;
            r.classe = v.classe;
            r.dims = {1, 1};
            r.re = {k < v.re.size() ? v.re[k] : 0.0};
            if (!v.im.empty()) r.im = {k < v.im.size() ? v.im[k] : 0.0};
            return r;
        }
    }
}

void poserElement(Valeur& v, std::size_t k, const Valeur& e) {
    switch (v.classe) {
        case Classe::Cellule:
            if (v.cellules.size() <= k) v.cellules.resize(k + 1, Valeur::vide());
            v.cellules[k] = (e.classe == Classe::Cellule && e.nelem() == 1) ? e.cellules[0] : e;
            break;
        case Classe::Chaine:
            if (v.chaines.size() <= k) v.chaines.resize(k + 1);
            v.chaines[k] = e.versTexte();
            break;
        case Classe::Structure:
        case Classe::Objet: {
            v.detacherStructure();
            std::size_t n = std::max(k + 1, produitDims(v.dims));
            for (const auto& nom : e.champs()) {
                if (!v.st->champs.count(nom)) {
                    v.st->ordre.push_back(nom);
                    v.st->champs[nom] = std::vector<Valeur>(n, Valeur::vide());
                }
            }
            for (auto& kv : v.st->champs) {
                if (kv.second.size() < n) kv.second.resize(n, Valeur::vide());
                kv.second[k] = e.aChamp(kv.first) ? e.champ(kv.first, 0) : Valeur::vide();
            }
            break;
        }
        default:
            if (v.re.size() <= k) v.re.resize(k + 1, 0.0);
            v.re[k] = e.re.empty() ? 0.0 : e.re[0];
            if (!e.im.empty()) {
                v.assurerImaginaire();
                v.im.resize(std::max(v.im.size(), k + 1), 0.0);
                v.im[k] = e.im[0];
            } else if (!v.im.empty()) {
                v.im.resize(std::max(v.im.size(), k + 1), 0.0);
                v.im[k] = 0.0;
            }
            break;
    }
}

static Classe classeConcat(const std::vector<Valeur>& v) {
    bool cellule = false, chaine = false, caractere = false, structure = false;
    bool simple = false, logique = true, fonction = false;
    Classe entier = Classe::Double;
    bool aEntier = false;
    for (const auto& x : v) {
        if (x.classe == Classe::Cellule) cellule = true;
        else if (x.classe == Classe::Chaine) chaine = true;
        else if (x.classe == Classe::Caractere) caractere = true;
        else if (x.estStructure()) structure = true;
        else if (x.classe == Classe::Fonction) fonction = true;
        else if (x.classe == Classe::Simple) simple = true;
        else if (classeEntiere(x.classe)) { entier = x.classe; aEntier = true; }
        if (x.classe != Classe::Logique) logique = false;
    }
    if (cellule) return Classe::Cellule;
    if (structure) return Classe::Structure;
    if (chaine) return Classe::Chaine;
    if (caractere) return Classe::Caractere;
    if (fonction) return Classe::Fonction;
    if (aEntier) return entier;
    if (simple) return Classe::Simple;
    if (logique && !v.empty()) return Classe::Logique;
    return Classe::Double;
}

static Valeur convertirPour(const Valeur& v, Classe c) {
    if (v.classe == c) return v;
    if (c == Classe::Cellule) {
        if (v.classe == Classe::Cellule) return v;
        Valeur r = Valeur::celluleDims({1, 1});
        r.cellules[0] = v;
        return r;
    }
    if (c == Classe::Chaine) {
        if (v.classe == Classe::Chaine) return v;
        if (v.classe == Classe::Caractere) return Valeur::chaine(v.versTexte());
        Valeur r;
        r.classe = Classe::Chaine;
        r.dims = v.dims;
        r.chaines.resize(v.nelem());
        for (std::size_t k = 0; k < r.chaines.size(); ++k)
            r.chaines[k] = texteElement(v, k);
        return r;
    }
    if (c == Classe::Caractere) {
        Valeur r = v;
        if (v.classe == Classe::Chaine) r = Valeur::texte(v.chaines.empty() ? "" : v.chaines[0]);
        r.classe = Classe::Caractere;
        r.im.clear();
        return r;
    }
    Valeur r = v;
    if (v.classe == Classe::Chaine) r = Valeur::texte(v.chaines.empty() ? "" : v.chaines[0]);
    r.classe = c;
    if (classeEntiere(c))
        for (auto& x : r.re) x = saturer(x, c);
    return r;
}

Valeur concatener(const std::vector<Valeur>& elementsBruts, int dimension) {
    std::vector<Valeur> elements;
    for (const auto& e : elementsBruts)
        if (!(e.estVide() && e.classe != Classe::Cellule && !e.estStructure())) elements.push_back(e);
    if (elements.empty()) {
        for (const auto& e : elementsBruts)
            if (e.classe == Classe::Cellule) return Valeur::celluleDims({0, 0});
        return Valeur::vide();
    }
    if (elements.size() == 1 && elements[0].classe != Classe::Chaine) {
        Classe cible = classeConcat(elements);
        return convertirPour(elements[0], cible);
    }
    Classe cible = classeConcat(elements);
    std::vector<Valeur> conv;
    conv.reserve(elements.size());
    for (const auto& e : elements) conv.push_back(convertirPour(e, cible));

    // Dimensions du résultat.
    std::size_t nd = 2;
    for (const auto& e : conv) nd = std::max(nd, e.dims.size());
    nd = std::max(nd, (std::size_t)dimension + 1);
    Dims rd(nd, 1);
    for (std::size_t i = 0; i < nd; ++i) {
        if ((int)i == dimension) continue;
        int taille = -1;
        for (const auto& e : conv) {
            int t = i < e.dims.size() ? e.dims[i] : 1;
            if (taille < 0) taille = t;
            else if (taille != t) {
                if (cible == Classe::Caractere && dimension == 0 && i == 1) {
                    taille = std::max(taille, t);  // char : complété par des blancs
                } else {
                    erreur("MATLAB:catenate:dimensionMismatch",
                           dimension == 0
                               ? "Dimensions of arrays being concatenated are not consistent."
                               : "Dimensions of arrays being concatenated are not consistent.");
                }
            }
        }
        rd[i] = taille < 0 ? 0 : taille;
    }
    int total = 0;
    for (const auto& e : conv) total += (dimension < (int)e.dims.size()) ? e.dims[dimension] : 1;
    rd[dimension] = total;

    Valeur r;
    r.classe = cible;
    r.nomObjet = conv[0].nomObjet;
    r.dims = rd;
    std::size_t n = produitDims(rd);
    switch (cible) {
        case Classe::Cellule: r.cellules.assign(n, Valeur::vide()); break;
        case Classe::Chaine: r.chaines.assign(n, std::string()); break;
        case Classe::Structure:
        case Classe::Objet: {
            r.st = std::make_shared<ChampsStructure>();
            for (const auto& e : conv)
                for (const auto& nom : e.champs())
                    if (!r.st->champs.count(nom)) {
                        r.st->ordre.push_back(nom);
                        r.st->champs[nom] = std::vector<Valeur>(n, Valeur::vide());
                    }
            break;
        }
        case Classe::Fonction: r.fn = conv[0].fn; r.dims = {1, 1}; return r;
        default:
            r.re.assign(n, cible == Classe::Caractere ? 32.0 : 0.0);
            for (const auto& e : conv)
                if (e.estComplexe()) { r.im.assign(n, 0.0); break; }
            break;
    }

    // Recopie bloc par bloc.
    std::vector<std::size_t> pas(nd, 1);
    for (std::size_t i = 1; i < nd; ++i) pas[i] = pas[i - 1] * (std::size_t)rd[i - 1];
    int decalage = 0;
    for (const auto& e : conv) {
        Dims ed = e.dims;
        ed.resize(std::max(ed.size(), nd), 1);
        std::size_t ne = e.nelem();
        for (std::size_t k = 0; k < ne; ++k) {
            std::size_t reste = k, cible_i = 0;
            for (std::size_t i = 0; i < nd; ++i) {
                std::size_t coord = reste % (std::size_t)std::max(1, ed[i]);
                reste /= (std::size_t)std::max(1, ed[i]);
                if ((int)i == dimension) coord += (std::size_t)decalage;
                cible_i += coord * pas[i];
            }
            switch (cible) {
                case Classe::Cellule: r.cellules[cible_i] = e.cellules[k]; break;
                case Classe::Chaine: r.chaines[cible_i] = e.chaines[k]; break;
                case Classe::Structure:
                case Classe::Objet:
                    for (auto& kv : r.st->champs)
                        kv.second[cible_i] = e.aChamp(kv.first) ? e.champ(kv.first, k)
                                                                : Valeur::vide();
                    break;
                default:
                    r.re[cible_i] = e.re[k];
                    if (!r.im.empty()) r.im[cible_i] = e.im.empty() ? 0.0 : e.im[k];
                    break;
            }
        }
        decalage += (dimension < (int)ed.size()) ? ed[dimension] : 1;
    }
    r.normaliserDims();
    return r;
}

Valeur concatenerRangees(const std::vector<std::vector<Valeur>>& rangees) {
    std::vector<Valeur> lignes;
    for (const auto& r : rangees) {
        if (r.empty()) continue;
        lignes.push_back(concatener(r, 1));  // horzcat
    }
    if (lignes.empty()) return Valeur::vide();
    return concatener(lignes, 0);  // vertcat
}

Valeur celluleDepuisRangees(const std::vector<std::vector<Valeur>>& rangees) {
    // Dans « { } », chaque élément occupe une case, y compris s'il est
    // lui-même une cellule : « {c, 1} » fabrique une cellule de deux cases
    // dont la première contient c. C'est « [c, {1}] » qui concatène.
    std::vector<Valeur> lignes;
    for (const auto& r : rangees) {
        std::vector<Valeur> cases;
        for (const auto& e : r) {
            Valeur c = Valeur::celluleDims({1, 1});
            c.cellules[0] = e;
            cases.push_back(c);
        }
        if (!cases.empty()) lignes.push_back(concatener(cases, 1));
    }
    if (lignes.empty()) return Valeur::celluleDims({0, 0});
    return concatener(lignes, 0);
}

Valeur reshaperVers(const Valeur& v, const Dims& d) {
    Valeur r = v;
    if (produitDims(d) != v.nelem())
        erreur("MATLAB:getReshapeDims:notSameNumel",
               formater("To RESHAPE the number of elements must not change."));
    r.dims = d;
    r.normaliserDims();
    return r;
}

Valeur permuterDims(const Valeur& v, const std::vector<int>& ordre) {
    std::size_t nd = std::max(v.dims.size(), ordre.size());
    Dims src = v.dims;
    src.resize(nd, 1);
    Dims rd(nd, 1);
    for (std::size_t i = 0; i < ordre.size(); ++i) rd[i] = src[(std::size_t)ordre[i]];
    Valeur r = v;
    r.dims = rd;
    std::size_t n = v.nelem();
    std::vector<std::size_t> pasSrc(nd, 1);
    for (std::size_t i = 1; i < nd; ++i) pasSrc[i] = pasSrc[i - 1] * (std::size_t)src[i - 1];
    if (v.classe == Classe::Cellule) r.cellules.assign(n, Valeur::vide());
    else if (v.classe == Classe::Chaine) r.chaines.assign(n, std::string());
    else {
        r.re.assign(n, 0.0);
        if (!v.im.empty()) r.im.assign(n, 0.0);
    }
    for (std::size_t k = 0; k < n; ++k) {
        std::size_t reste = k, isrc = 0;
        for (std::size_t i = 0; i < nd; ++i) {
            std::size_t coord = reste % (std::size_t)std::max(1, rd[i]);
            reste /= (std::size_t)std::max(1, rd[i]);
            isrc += coord * pasSrc[(std::size_t)ordre[i]];
        }
        if (v.classe == Classe::Cellule) r.cellules[k] = v.cellules[isrc];
        else if (v.classe == Classe::Chaine) r.chaines[k] = v.chaines[isrc];
        else {
            r.re[k] = v.re[isrc];
            if (!r.im.empty()) r.im[k] = v.im[isrc];
        }
    }
    r.normaliserDims();
    return r;
}

}  // namespace matlibre
