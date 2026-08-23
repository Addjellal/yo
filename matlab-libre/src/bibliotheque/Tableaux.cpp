// Tableaux.cpp — réductions et manipulations de tableaux.
#include <algorithm>
#include <cmath>
#include <complex>
#include <map>
#include <numeric>
#include <set>

#include "matlibre/AlgebreLineaire.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {
namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, std::vector<Valeur>& args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

Valeur enDouble(const Valeur& v) {
    if (v.classe == Classe::Cellule)
        erreur("MATLAB:UndefinedFunction",
               "Undefined function for input arguments of type 'cell'.");
    if (v.classe == Classe::Chaine || v.classe == Classe::Caractere) return versDouble(v);
    return v;
}

int dimensionArgument(std::vector<Valeur>& args, std::size_t position, const Valeur& v) {
    if (args.size() > position && !args[position].estVide() &&
        !(args[position].estTexte() || args[position].estChaine()))
        return (int)args[position].scal() - 1;
    return dimensionParDefaut(v);
}

bool omettreNaN(const std::vector<Valeur>& args) {
    for (const auto& a : args)
        if ((a.estTexte() || a.estChaine())) {
            std::string s = a.versTexte();
            if (s == "omitnan") return true;
        }
    return false;
}

Valeur reductionSomme(const Valeur& brut, int dim, bool produit, bool sansNaN) {
    Valeur v = enDouble(brut);
    if (v.estComplexe()) {
        Dims d = v.dims;
        while ((int)d.size() <= dim) d.push_back(1);
        Dims rd = d;
        rd[(std::size_t)dim] = 1;
        if (!produit) {
            // Une somme se decompose : parties reelle et imaginaire
            // s'additionnent chacune de leur cote.
            Valeur partieRe = v, partieIm = v;
            partieRe.im.clear();
            partieIm.re = v.im;
            partieIm.im.clear();
            Valeur sr = reductionSomme(partieRe, dim, false, sansNaN);
            Valeur si = reductionSomme(partieIm, dim, false, sansNaN);
            sr.assurerImaginaire();
            for (std::size_t k = 0; k < sr.re.size(); ++k) sr.im[k] = si.re[k];
            sr.compacter();
            return sr;
        }
        // Un produit, lui, ne se decompose pas : (a+ib)(c+id) melange les
        // deux parties. On multiplie donc en complexes.
        Valeur r = Valeur::matriceDims(rd);
        r.assurerImaginaire();
        std::size_t interne = 1;
        for (int k = 0; k < dim; ++k) interne *= (std::size_t)d[(std::size_t)k];
        std::size_t taille = (std::size_t)d[(std::size_t)dim];
        std::size_t externe = taille ? v.nelem() / (interne * taille) : 0;
        for (std::size_t a = 0; a < externe; ++a)
            for (std::size_t b = 0; b < interne; ++b) {
                std::complex<double> acc(1.0, 0.0);
                for (std::size_t i = 0; i < taille; ++i) {
                    std::size_t p = a * interne * taille + b + i * interne;
                    std::complex<double> z(v.re[p], v.im[p]);
                    if (sansNaN && (std::isnan(z.real()) || std::isnan(z.imag()))) continue;
                    acc *= z;
                }
                std::size_t q = a * interne + b;
                r.re[q] = acc.real();
                r.im[q] = acc.imag();
            }
        r.compacter();
        return r;
    }
    return reduire(v, dim, false, [produit, sansNaN](const std::vector<double>& t) {
        double acc = produit ? 1.0 : 0.0;
        for (double x : t) {
            if (sansNaN && std::isnan(x)) continue;
            if (produit) acc *= x;
            else acc += x;
        }
        return acc;
    });
}

FONCTION(fnSum) {
    INUTILISE
    exigerArguments(args, 1, 4, "sum");
    if (args[0].estVide()) return {Valeur::scalaire(0)};
    if (optionToutesDimensions(args))
        return {reductionSomme(aplatirColonne(args[0]), 0, false, omettreNaN(args))};
    int dim = dimensionArgument(args, 1, args[0]);
    return {reductionSomme(args[0], dim, false, omettreNaN(args))};
}
FONCTION(fnProd) {
    INUTILISE
    exigerArguments(args, 1, 4, "prod");
    if (args[0].estVide()) return {Valeur::scalaire(1)};
    if (optionToutesDimensions(args))
        return {reductionSomme(aplatirColonne(args[0]), 0, true, omettreNaN(args))};
    int dim = dimensionArgument(args, 1, args[0]);
    return {reductionSomme(args[0], dim, true, omettreNaN(args))};
}

Valeur cumulatif(const Valeur& brut, int dim, bool produit) {
    Valeur v = enDouble(brut);
    Valeur r = v;
    r.classe = Classe::Double;
    Dims d = v.dims;
    while ((int)d.size() <= dim) d.push_back(1);
    std::size_t interne = 1;
    for (int k = 0; k < dim; ++k) interne *= (std::size_t)d[(std::size_t)k];
    std::size_t taille = (std::size_t)d[(std::size_t)dim];
    std::size_t externe = taille ? v.nelem() / (interne * taille) : 0;
    if (v.estComplexe()) {
        // Le cumul porte sur les complexes entiers : pour un produit, les
        // parties reelle et imaginaire ne peuvent pas etre cumulees
        // separement.
        r.assurerImaginaire();
        for (std::size_t a = 0; a < externe; ++a)
            for (std::size_t b = 0; b < interne; ++b) {
                std::complex<double> acc = produit ? std::complex<double>(1.0, 0.0)
                                                   : std::complex<double>(0.0, 0.0);
                for (std::size_t i = 0; i < taille; ++i) {
                    std::size_t p = a * interne * taille + b + i * interne;
                    std::complex<double> z(v.re[p], v.im[p]);
                    if (produit) acc *= z;
                    else acc += z;
                    r.re[p] = acc.real();
                    r.im[p] = acc.imag();
                }
            }
        r.compacter();
        return r;
    }
    for (std::size_t a = 0; a < externe; ++a)
        for (std::size_t b = 0; b < interne; ++b) {
            double acc = produit ? 1.0 : 0.0;
            for (std::size_t i = 0; i < taille; ++i) {
                std::size_t p = a * interne * taille + b + i * interne;
                if (produit) acc *= v.re[p];
                else acc += v.re[p];
                r.re[p] = acc;
            }
        }
    return r;
}

FONCTION(fnCumsum) {
    INUTILISE
    exigerArguments(args, 1, 3, "cumsum");
    return {cumulatif(args[0], dimensionArgument(args, 1, args[0]), false)};
}
FONCTION(fnCumprod) {
    INUTILISE
    exigerArguments(args, 1, 3, "cumprod");
    return {cumulatif(args[0], dimensionArgument(args, 1, args[0]), true)};
}

// max / min : trois formes documentées.
std::vector<Valeur> extremum(Interpreteur& it, std::vector<Valeur>& args, int nargout,
                             bool maximum) {
    (void)it;
    const char* nom = maximum ? "max" : "min";
    exigerArguments(args, 1, 4, nom);
    if (optionToutesDimensions(args)) {
        std::vector<Valeur> plat = {aplatirColonne(args[0])};
        return extremum(it, plat, nargout, maximum);
    }
    if (args.size() >= 2 && !args[1].estVide()) {
        Valeur a = enDouble(args[0]), b = enDouble(args[1]);
        Classe cr = classeResultat(args[0], args[1], nom);
        return {diffuser(a, b,
                         [maximum](double x, double y) {
                             if (std::isnan(x)) return y;
                             if (std::isnan(y)) return x;
                             return maximum ? std::max(x, y) : std::min(x, y);
                         },
                         cr)};
    }
    Valeur v = enDouble(args[0]);
    if (v.estVide()) return {Valeur::vide(), Valeur::vide()};
    int dim = args.size() >= 3 ? (int)args[2].scal() - 1 : dimensionParDefaut(v);
    Dims d = v.dims;
    while ((int)d.size() <= dim) d.push_back(1);
    Dims rd = d;
    rd[(std::size_t)dim] = 1;
    Valeur res = Valeur::matriceDims(rd);
    Valeur idx = Valeur::matriceDims(rd);
    res.classe = v.classe == Classe::Logique ? Classe::Double : v.classe;
    bool complexe = v.estComplexe();
    if (complexe) res.assurerImaginaire();
    std::size_t interne = 1;
    for (int k = 0; k < dim; ++k) interne *= (std::size_t)d[(std::size_t)k];
    std::size_t taille = (std::size_t)d[(std::size_t)dim];
    std::size_t externe = taille ? v.nelem() / (interne * taille) : 0;
    for (std::size_t a = 0; a < externe; ++a)
        for (std::size_t b = 0; b < interne; ++b) {
            std::size_t meilleur = 0;
            double meilleureCle = NAN;
            bool trouve = false;
            for (std::size_t i = 0; i < taille; ++i) {
                std::size_t p = a * interne * taille + b + i * interne;
                double cle = complexe ? std::hypot(v.re[p], v.im[p]) : v.re[p];
                if (std::isnan(cle)) continue;
                if (!trouve || (maximum ? cle > meilleureCle : cle < meilleureCle)) {
                    meilleureCle = cle;
                    meilleur = i;
                    trouve = true;
                }
            }
            std::size_t sortiePos = a * interne + b;
            std::size_t source = a * interne * taille + b + meilleur * interne;
            res.re[sortiePos] = trouve ? v.re[source] : NAN;
            if (complexe) res.im[sortiePos] = trouve ? v.im[source] : NAN;
            idx.re[sortiePos] = (double)(meilleur + 1);
        }
    res.normaliserDims();
    idx.normaliserDims();
    if (nargout >= 2) return {res, idx};
    return {res};
}

FONCTION(fnMax) { return extremum(it, args, nargout, true); }
FONCTION(fnMin) { return extremum(it, args, nargout, false); }

FONCTION(fnCummax) {
    INUTILISE
    Valeur v = enDouble(args[0]);
    Valeur r = v;
    double acc = -INFINITY;
    for (std::size_t k = 0; k < r.re.size(); ++k) {
        acc = std::max(acc, v.re[k]);
        r.re[k] = acc;
    }
    return {r};
}
FONCTION(fnCummin) {
    INUTILISE
    Valeur v = enDouble(args[0]);
    Valeur r = v;
    double acc = INFINITY;
    for (std::size_t k = 0; k < r.re.size(); ++k) {
        acc = std::min(acc, v.re[k]);
        r.re[k] = acc;
    }
    return {r};
}

// ------------------------------------------------------------------- tri

std::vector<Valeur> trier(std::vector<Valeur>& args, int nargout) {
    exigerArguments(args, 1, 3, "sort");
    Valeur v = args[0];
    bool descendant = false;
    int dim = -1;
    for (std::size_t k = 1; k < args.size(); ++k) {
        if (args[k].estTexte() || args[k].estChaine()) {
            std::string mode = args[k].versTexte();
            if (mode == "descend") descendant = true;
        } else if (!args[k].estVide()) {
            dim = (int)args[k].scal() - 1;
        }
    }
    if (v.classe == Classe::Cellule || v.classe == Classe::Chaine) {
        // Tri lexicographique de textes.
        std::size_t n = v.nelem();
        std::vector<std::size_t> ordre(n);
        std::iota(ordre.begin(), ordre.end(), 0);
        auto texteDe = [&](std::size_t k) {
            return v.classe == Classe::Cellule ? v.cellules[k].versTexte() : v.chaines[k];
        };
        std::stable_sort(ordre.begin(), ordre.end(), [&](std::size_t a, std::size_t b) {
            return descendant ? texteDe(a) > texteDe(b) : texteDe(a) < texteDe(b);
        });
        Valeur r = v;
        Valeur idx = Valeur::matriceDims(v.dims);
        for (std::size_t k = 0; k < n; ++k) {
            if (v.classe == Classe::Cellule) r.cellules[k] = v.cellules[ordre[k]];
            else r.chaines[k] = v.chaines[ordre[k]];
            idx.re[k] = (double)(ordre[k] + 1);
        }
        if (nargout >= 2) return {r, idx};
        return {r};
    }
    if (dim < 0) dim = dimensionParDefaut(v);
    Dims d = v.dims;
    while ((int)d.size() <= dim) d.push_back(1);
    Valeur r = v;
    Valeur idx = Valeur::matriceDims(d);
    std::size_t interne = 1;
    for (int k = 0; k < dim; ++k) interne *= (std::size_t)d[(std::size_t)k];
    std::size_t taille = (std::size_t)d[(std::size_t)dim];
    std::size_t externe = taille ? v.nelem() / (interne * taille) : 0;
    bool complexe = v.estComplexe();
    for (std::size_t a = 0; a < externe; ++a)
        for (std::size_t b = 0; b < interne; ++b) {
            std::vector<std::size_t> ordre(taille);
            std::iota(ordre.begin(), ordre.end(), 0);
            auto cle = [&](std::size_t i) {
                std::size_t p = a * interne * taille + b + i * interne;
                return complexe ? std::hypot(v.re[p], v.im[p]) : v.re[p];
            };
            std::stable_sort(ordre.begin(), ordre.end(), [&](std::size_t x, std::size_t y) {
                double cx = cle(x), cy = cle(y);
                if (std::isnan(cx)) return false;
                if (std::isnan(cy)) return true;
                return descendant ? cx > cy : cx < cy;
            });
            for (std::size_t i = 0; i < taille; ++i) {
                std::size_t dst = a * interne * taille + b + i * interne;
                std::size_t src = a * interne * taille + b + ordre[i] * interne;
                r.re[dst] = v.re[src];
                if (complexe) r.im[dst] = v.im[src];
                idx.re[dst] = (double)(ordre[i] + 1);
            }
        }
    if (nargout >= 2) return {r, idx};
    return {r};
}

FONCTION(fnSort) {
    INUTILISE
    return trier(args, nargout);
}

FONCTION(fnSortrows) {
    INUTILISE
    exigerArguments(args, 1, 2, "sortrows");
    const Valeur& v = args[0];
    int l = v.nlignes(), c = v.ncolonnes();
    std::vector<int> colonnes;
    if (args.size() > 1)
        for (std::size_t k = 0; k < args[1].nelem(); ++k) colonnes.push_back((int)args[1].re[k]);
    else
        for (int k = 1; k <= c; ++k) colonnes.push_back(k);
    std::vector<std::size_t> ordre((std::size_t)l);
    std::iota(ordre.begin(), ordre.end(), 0);
    std::stable_sort(ordre.begin(), ordre.end(), [&](std::size_t a, std::size_t b) {
        for (int col : colonnes) {
            int j = std::abs(col) - 1;
            double x = v.re[a + (std::size_t)j * l], y = v.re[b + (std::size_t)j * l];
            if (x == y) continue;
            return col > 0 ? x < y : x > y;
        }
        return false;
    });
    Valeur r = v;
    for (int j = 0; j < c; ++j)
        for (int i = 0; i < l; ++i)
            r.re[(std::size_t)i + (std::size_t)j * l] =
                v.re[ordre[(std::size_t)i] + (std::size_t)j * l];
    std::vector<double> indices((std::size_t)l);
    for (int i = 0; i < l; ++i) indices[(std::size_t)i] = (double)(ordre[(std::size_t)i] + 1);
    if (nargout >= 2) return {r, Valeur::colonne(indices)};
    return {r};
}

// ------------------------------------------------------------------ find

FONCTION(fnFind) {
    INUTILISE
    exigerArguments(args, 1, 3, "find");
    const Valeur& v = args[0];
    std::size_t limite = args.size() > 1 ? (std::size_t)args[1].scal() : (std::size_t)-1;
    bool depuisFin = args.size() > 2 && args[2].versTexte() == "last";
    std::vector<std::size_t> trouves;
    for (std::size_t k = 0; k < v.nelem(); ++k) {
        double x = v.re.empty() ? 0.0 : v.re[k];
        double y = v.im.empty() ? 0.0 : v.im[k];
        if (x != 0.0 || y != 0.0) trouves.push_back(k);
    }
    if (limite != (std::size_t)-1 && trouves.size() > limite) {
        if (depuisFin) trouves.erase(trouves.begin(), trouves.end() - (long)limite);
        else trouves.resize(limite);
    }
    bool ligne = v.dims.size() == 2 && v.dims[0] == 1 && v.dims[1] != 1;
    auto fabriquer = [&](const std::vector<double>& x) {
        return ligne ? Valeur::ligne(x) : Valeur::colonne(x);
    };
    if (nargout <= 1) {
        std::vector<double> idx;
        for (auto k : trouves) idx.push_back((double)(k + 1));
        return {fabriquer(idx)};
    }
    int l = v.nlignes();
    std::vector<double> is, js, vs;
    for (auto k : trouves) {
        is.push_back((double)(k % (std::size_t)std::max(1, l) + 1));
        js.push_back((double)(k / (std::size_t)std::max(1, l) + 1));
        vs.push_back(v.re[k]);
    }
    if (nargout == 2) return {fabriquer(is), fabriquer(js)};
    return {fabriquer(is), fabriquer(js), fabriquer(vs)};
}

FONCTION(fnAny) {
    INUTILISE
    exigerArguments(args, 1, 2, "any");
    Valeur v = enDouble(args[0]);
    if (v.estVide()) return {Valeur::booleen(false)};
    if (optionToutesDimensions(args)) v = aplatirColonne(v);
    if (v.estVecteur() && (args.size() < 2 || optionToutesDimensions(args))) {
        for (std::size_t k = 0; k < v.re.size(); ++k)
            if (v.re[k] != 0 || (!v.im.empty() && v.im[k] != 0))
                return {Valeur::booleen(true)};
        return {Valeur::booleen(false)};
    }
    int dim = dimensionArgument(args, 1, v);
    Valeur r = reduire(v, dim, false, [](const std::vector<double>& t) {
        for (double x : t)
            if (x != 0 && !std::isnan(x)) return 1.0;
        return 0.0;
    });
    r.classe = Classe::Logique;
    return {r};
}

FONCTION(fnAll) {
    INUTILISE
    exigerArguments(args, 1, 2, "all");
    Valeur v = enDouble(args[0]);
    if (v.estVide()) return {Valeur::booleen(true)};
    if (optionToutesDimensions(args)) v = aplatirColonne(v);
    if (v.estVecteur() && (args.size() < 2 || optionToutesDimensions(args))) {
        for (std::size_t k = 0; k < v.re.size(); ++k)
            if (v.re[k] == 0 && (v.im.empty() || v.im[k] == 0))
                return {Valeur::booleen(false)};
        return {Valeur::booleen(true)};
    }
    int dim = dimensionArgument(args, 1, v);
    Valeur r = reduire(v, dim, false, [](const std::vector<double>& t) {
        for (double x : t)
            if (x == 0) return 0.0;
        return 1.0;
    });
    r.classe = Classe::Logique;
    return {r};
}

FONCTION(fnNnz) {
    INUTILISE
    std::size_t n = 0;
    for (std::size_t k = 0; k < args[0].re.size(); ++k)
        if (args[0].re[k] != 0 || (!args[0].im.empty() && args[0].im[k] != 0)) ++n;
    return {Valeur::scalaire((double)n)};
}

FONCTION(fnDiff) {
    INUTILISE
    exigerArguments(args, 1, 3, "diff");
    Valeur v = enDouble(args[0]);
    int ordre = args.size() > 1 && !args[1].estVide() ? (int)args[1].scal() : 1;
    int dim = args.size() > 2 ? (int)args[2].scal() - 1 : dimensionParDefaut(v);
    for (int tour = 0; tour < ordre; ++tour) {
        Dims d = v.dims;
        while ((int)d.size() <= dim) d.push_back(1);
        if (d[(std::size_t)dim] <= 1) {
            Dims vide = d;
            vide[(std::size_t)dim] = 0;
            v = Valeur::matriceDims(vide);
            break;
        }
        Dims rd = d;
        rd[(std::size_t)dim] -= 1;
        Valeur r = Valeur::matriceDims(rd);
        std::size_t interne = 1;
        for (int k = 0; k < dim; ++k) interne *= (std::size_t)d[(std::size_t)k];
        std::size_t taille = (std::size_t)d[(std::size_t)dim];
        std::size_t externe = v.nelem() / (interne * taille);
        for (std::size_t a = 0; a < externe; ++a)
            for (std::size_t b = 0; b < interne; ++b)
                for (std::size_t i = 0; i + 1 < taille; ++i) {
                    std::size_t p = a * interne * taille + b + i * interne;
                    std::size_t q = p + interne;
                    std::size_t dst = a * interne * (taille - 1) + b + i * interne;
                    r.re[dst] = v.re[q] - v.re[p];
                }
        v = r;
    }
    return {v};
}

// -------------------------------------------------------------- ensembles

struct CleValeur {
    bool texte = false;
    double nombre = 0;
    std::string chaine;
    bool operator<(const CleValeur& o) const {
        if (texte != o.texte) return texte < o.texte;
        if (texte) return chaine < o.chaine;
        return nombre < o.nombre;
    }
    bool operator==(const CleValeur& o) const {
        if (texte != o.texte) return false;
        return texte ? chaine == o.chaine : nombre == o.nombre;
    }
};

CleValeur cleDe(const Valeur& v, std::size_t k) {
    CleValeur c;
    if (v.classe == Classe::Cellule) {
        c.texte = true;
        c.chaine = v.cellules[k].versTexte();
    } else if (v.classe == Classe::Chaine) {
        c.texte = true;
        c.chaine = v.chaines[k];
    } else {
        c.nombre = v.re.empty() ? 0 : v.re[k];
    }
    return c;
}

// Quand l'un des ensembles est une cellule ou un tableau de chaînes, un
// tableau de caractères compte pour un seul élément : « ismember('b',
// {'a','b'}) » est vrai, alors que « ismember('abc','bcd') » compare les
// codes un à un.
bool ensembleDeTextes(const Valeur& v) {
    return v.classe == Classe::Cellule || v.classe == Classe::Chaine;
}

std::vector<CleValeur> clesDe(const Valeur& v, bool commeTexte) {
    std::vector<CleValeur> cles;
    if (commeTexte && v.classe == Classe::Caractere) {
        CleValeur c;
        c.texte = true;
        c.chaine = v.versTexte();
        cles.push_back(c);
        return cles;
    }
    for (std::size_t k = 0; k < v.nelem(); ++k) cles.push_back(cleDe(v, k));
    return cles;
}

Valeur elementDe(const Valeur& v, const std::vector<std::size_t>& indices, bool colonne) {
    Valeur r;
    if (v.classe == Classe::Cellule) {
        r = Valeur::celluleDims(colonne ? Dims{(int)indices.size(), 1}
                                        : Dims{1, (int)indices.size()});
        for (std::size_t k = 0; k < indices.size(); ++k) r.cellules[k] = v.cellules[indices[k]];
        return r;
    }
    if (v.classe == Classe::Chaine) {
        r.classe = Classe::Chaine;
        r.dims = colonne ? Dims{(int)indices.size(), 1} : Dims{1, (int)indices.size()};
        for (auto i : indices) r.chaines.push_back(v.chaines[i]);
        return r;
    }
    std::vector<double> x;
    for (auto i : indices) x.push_back(v.re[i]);
    r = colonne ? Valeur::colonne(x) : Valeur::ligne(x);
    r.classe = v.classe == Classe::Logique ? Classe::Logique : v.classe;
    return r;
}

FONCTION(fnUnique) {
    INUTILISE
    exigerArguments(args, 1, 3, "unique");
    const Valeur& v = args[0];
    bool stable = false;
    for (std::size_t k = 1; k < args.size(); ++k)
        if ((args[k].estTexte() || args[k].estChaine()) && args[k].versTexte() == "stable")
            stable = true;
    std::size_t n = v.nelem();
    std::vector<std::size_t> ordre(n);
    std::iota(ordre.begin(), ordre.end(), 0);
    if (!stable)
        std::stable_sort(ordre.begin(), ordre.end(),
                         [&](std::size_t a, std::size_t b) { return cleDe(v, a) < cleDe(v, b); });
    std::vector<std::size_t> gardes;
    std::vector<double> ic(n, 0);
    std::map<CleValeur, std::size_t> vues;
    for (std::size_t k : ordre) {
        CleValeur c = cleDe(v, k);
        auto trouve = vues.find(c);
        if (trouve == vues.end()) {
            vues[c] = gardes.size();
            gardes.push_back(k);
            ic[k] = (double)gardes.size();
        } else {
            ic[k] = (double)(trouve->second + 1);
        }
    }
    bool colonne = !(v.dims.size() == 2 && v.dims[0] == 1);
    Valeur u = elementDe(v, gardes, colonne);
    std::vector<double> ia;
    for (auto g : gardes) ia.push_back((double)(g + 1));
    if (nargout <= 1) return {u};
    if (nargout == 2) return {u, colonne ? Valeur::colonne(ia) : Valeur::ligne(ia)};
    return {u, colonne ? Valeur::colonne(ia) : Valeur::ligne(ia),
            colonne ? Valeur::colonne(ic) : Valeur::ligne(ic)};
}

FONCTION(fnIsmember) {
    INUTILISE
    exigerArguments(args, 2, 3, "ismember");
    const Valeur& a = args[0];
    const Valeur& b = args[1];
    bool commeTexte = ensembleDeTextes(a) || ensembleDeTextes(b);
    std::vector<CleValeur> clesA = clesDe(a, commeTexte);
    std::vector<CleValeur> clesB = clesDe(b, commeTexte);
    std::map<CleValeur, std::size_t> table;
    for (std::size_t k = 0; k < clesB.size(); ++k)
        if (!table.count(clesB[k])) table[clesB[k]] = k + 1;
    Dims forme = (clesA.size() == a.nelem()) ? a.dims : Dims{1, 1};
    Valeur r = Valeur::matriceDims(forme);
    r.classe = Classe::Logique;
    Valeur pos = Valeur::matriceDims(forme);
    r.re.assign(clesA.size(), 0.0);
    pos.re.assign(clesA.size(), 0.0);
    for (std::size_t k = 0; k < clesA.size(); ++k) {
        auto t = table.find(clesA[k]);
        r.re[k] = t == table.end() ? 0 : 1;
        pos.re[k] = t == table.end() ? 0 : (double)t->second;
    }
    if (nargout >= 2) return {r, pos};
    return {r};
}

std::vector<Valeur> operationEnsemble(std::vector<Valeur>& args, int nargout, int genre) {
    const Valeur& a = args[0];
    const Valeur& b = args[1];
    std::set<CleValeur> ensembleB;
    for (std::size_t k = 0; k < b.nelem(); ++k) ensembleB.insert(cleDe(b, k));
    std::set<CleValeur> ensembleA;
    for (std::size_t k = 0; k < a.nelem(); ++k) ensembleA.insert(cleDe(a, k));
    std::vector<std::size_t> gardes;
    std::set<CleValeur> deja;
    auto ajouter = [&](const Valeur& source, std::size_t k) {
        CleValeur c = cleDe(source, k);
        if (deja.count(c)) return false;
        deja.insert(c);
        return true;
    };
    std::vector<std::pair<const Valeur*, std::size_t>> resultat;
    if (genre == 0) {  // union
        std::vector<std::pair<const Valeur*, std::size_t>> tout;
        for (std::size_t k = 0; k < a.nelem(); ++k) tout.push_back({&a, k});
        for (std::size_t k = 0; k < b.nelem(); ++k) tout.push_back({&b, k});
        std::stable_sort(tout.begin(), tout.end(),
                         [&](const std::pair<const Valeur*, std::size_t>& x,
                             const std::pair<const Valeur*, std::size_t>& y) {
                             return cleDe(*x.first, x.second) < cleDe(*y.first, y.second);
                         });
        for (auto& p : tout)
            if (ajouter(*p.first, p.second)) resultat.push_back(p);
    } else {
        std::vector<std::size_t> indices;
        for (std::size_t k = 0; k < a.nelem(); ++k) indices.push_back(k);
        std::stable_sort(indices.begin(), indices.end(),
                         [&](std::size_t x, std::size_t y) { return cleDe(a, x) < cleDe(a, y); });
        for (auto k : indices) {
            bool dansB = ensembleB.count(cleDe(a, k)) > 0;
            if ((genre == 1 && dansB) || (genre == 2 && !dansB))
                if (ajouter(a, k)) resultat.push_back({&a, k});
        }
    }
    // Reconstitution
    bool colonne = !(a.dims.size() == 2 && a.dims[0] == 1);
    if (a.classe == Classe::Cellule) {
        Valeur r = Valeur::celluleDims(colonne ? Dims{(int)resultat.size(), 1}
                                               : Dims{1, (int)resultat.size()});
        for (std::size_t k = 0; k < resultat.size(); ++k)
            r.cellules[k] = resultat[k].first->cellules[resultat[k].second];
        return {r};
    }
    std::vector<double> x;
    std::vector<double> ia;
    for (auto& p : resultat) {
        x.push_back(p.first->re[p.second]);
        ia.push_back((double)(p.second + 1));
    }
    Valeur r = colonne ? Valeur::colonne(x) : Valeur::ligne(x);
    if (nargout >= 2) return {r, colonne ? Valeur::colonne(ia) : Valeur::ligne(ia)};
    return {r};
}

FONCTION(fnUnion) {
    INUTILISE
    exigerArguments(args, 2, 3, "union");
    return operationEnsemble(args, nargout, 0);
}
FONCTION(fnIntersect) {
    INUTILISE
    exigerArguments(args, 2, 3, "intersect");
    return operationEnsemble(args, nargout, 1);
}
FONCTION(fnSetdiff) {
    INUTILISE
    exigerArguments(args, 2, 3, "setdiff");
    return operationEnsemble(args, nargout, 2);
}

// ------------------------------------------------------------- matrices

FONCTION(fnDiag) {
    INUTILISE
    exigerArguments(args, 1, 2, "diag");
    const Valeur& v = enDouble(args[0]);
    int k = args.size() > 1 ? (int)args[1].scal() : 0;
    if (v.estVecteur() || v.estScalaire()) {
        int n = (int)v.nelem() + std::abs(k);
        Valeur r = Valeur::matrice(n, n);
        if (v.estComplexe()) r.assurerImaginaire();
        for (std::size_t i = 0; i < v.nelem(); ++i) {
            int li = (int)i + (k < 0 ? -k : 0);
            int co = (int)i + (k > 0 ? k : 0);
            r.re[(std::size_t)li + (std::size_t)co * n] = v.re[i];
            if (v.estComplexe()) r.im[(std::size_t)li + (std::size_t)co * n] = v.im[i];
        }
        return {r};
    }
    int l = v.nlignes(), c = v.ncolonnes();
    std::vector<double> d, di;
    for (int i = 0; i < l; ++i) {
        int j = i + k;
        if (j < 0 || j >= c) continue;
        d.push_back(v.re[(std::size_t)i + (std::size_t)j * l]);
        if (v.estComplexe()) di.push_back(v.im[(std::size_t)i + (std::size_t)j * l]);
    }
    Valeur r = Valeur::colonne(d);
    if (!di.empty()) r.im = di;
    return {r};
}

FONCTION(fnTriu) {
    INUTILISE
    exigerArguments(args, 1, 2, "triu");
    Valeur v = args[0];
    int k = args.size() > 1 ? (int)args[1].scal() : 0;
    int l = v.nlignes(), c = v.ncolonnes();
    for (int j = 0; j < c; ++j)
        for (int i = 0; i < l; ++i)
            if (j - i < k) {
                v.re[(std::size_t)i + (std::size_t)j * l] = 0;
                if (!v.im.empty()) v.im[(std::size_t)i + (std::size_t)j * l] = 0;
            }
    return {v};
}

FONCTION(fnTril) {
    INUTILISE
    exigerArguments(args, 1, 2, "tril");
    Valeur v = args[0];
    int k = args.size() > 1 ? (int)args[1].scal() : 0;
    int l = v.nlignes(), c = v.ncolonnes();
    for (int j = 0; j < c; ++j)
        for (int i = 0; i < l; ++i)
            if (j - i > k) {
                v.re[(std::size_t)i + (std::size_t)j * l] = 0;
                if (!v.im.empty()) v.im[(std::size_t)i + (std::size_t)j * l] = 0;
            }
    return {v};
}

FONCTION(fnKron) {
    INUTILISE
    exigerArguments(args, 2, 2, "kron");
    const Valeur& a = enDouble(args[0]);
    const Valeur& b = enDouble(args[1]);
    int la = a.nlignes(), ca = a.ncolonnes(), lb = b.nlignes(), cb = b.ncolonnes();
    Valeur r = Valeur::matrice(la * lb, ca * cb);
    for (int i = 0; i < la; ++i)
        for (int j = 0; j < ca; ++j)
            for (int p = 0; p < lb; ++p)
                for (int q = 0; q < cb; ++q)
                    r.re[(std::size_t)(i * lb + p) + (std::size_t)(j * cb + q) * (la * lb)] =
                        a.re[(std::size_t)i + (std::size_t)j * la] *
                        b.re[(std::size_t)p + (std::size_t)q * lb];
    return {r};
}

FONCTION(fnCross) {
    INUTILISE
    exigerArguments(args, 2, 3, "cross");
    const Valeur& a = enDouble(args[0]);
    const Valeur& b = enDouble(args[1]);
    if (a.nelem() != 3 || b.nelem() != 3)
        erreur("MATLAB:cross:InvalidDimAorBForCrossProd",
               "A and B must have at least one dimension of length 3.");
    std::vector<double> r = {a.re[1] * b.re[2] - a.re[2] * b.re[1],
                             a.re[2] * b.re[0] - a.re[0] * b.re[2],
                             a.re[0] * b.re[1] - a.re[1] * b.re[0]};
    return {a.estColonne() ? Valeur::colonne(r) : Valeur::ligne(r)};
}

FONCTION(fnDot) {
    INUTILISE
    exigerArguments(args, 2, 3, "dot");
    const Valeur& a = enDouble(args[0]);
    const Valeur& b = enDouble(args[1]);
    if (a.estVecteur() && b.estVecteur()) {
        double sr = 0, si = 0;
        for (std::size_t k = 0; k < a.nelem() && k < b.nelem(); ++k) {
            double ar = a.re[k], ai = a.im.empty() ? 0 : -a.im[k];
            double br = b.re[k], bi = b.im.empty() ? 0 : b.im[k];
            sr += ar * br - ai * bi;
            si += ar * bi + ai * br;
        }
        return {si == 0 ? Valeur::scalaire(sr) : Valeur::complexe(sr, si)};
    }
    Valeur produit = operationBinaire(".*", a, b);
    return {reduire(produit, dimensionParDefaut(produit), false,
                    [](const std::vector<double>& t) {
                        double s = 0;
                        for (double x : t) s += x;
                        return s;
                    })};
}

FONCTION(fnAccumarray) {
    INUTILISE
    exigerArguments(args, 2, 5, "accumarray");
    const Valeur& sujets = args[0];
    const Valeur& valeurs = args[1];
    std::size_t n = sujets.nlignes();
    int taille = 0;
    for (std::size_t k = 0; k < n; ++k) taille = std::max(taille, (int)sujets.re[k]);
    if (args.size() > 2 && !args[2].estVide()) taille = (int)args[2].re[0];
    Valeur r = Valeur::matrice(taille, 1);
    for (std::size_t k = 0; k < n; ++k) {
        int i = (int)sujets.re[k] - 1;
        if (i < 0 || i >= taille) continue;
        r.re[(std::size_t)i] += valeurs.nelem() == 1 ? valeurs.re[0] : valeurs.re[k];
    }
    return {r};
}

FONCTION(fnHistc) {
    INUTILISE
    exigerArguments(args, 2, 3, "histc");
    const Valeur& x = enDouble(args[0]);
    const Valeur& bords = enDouble(args[1]);
    std::size_t nb = bords.nelem();
    Valeur r = Valeur::matriceDims(bords.dims);
    for (std::size_t k = 0; k < x.nelem(); ++k) {
        double v = x.re[k];
        for (std::size_t b = 0; b < nb; ++b) {
            bool dedans = (b + 1 < nb) ? (v >= bords.re[b] && v < bords.re[b + 1])
                                       : (v == bords.re[b]);
            if (dedans) {
                r.re[b] += 1;
                break;
            }
        }
    }
    return {r};
}

FONCTION(fnCumtrapz) {
    INUTILISE
    exigerArguments(args, 1, 2, "cumtrapz");
    const Valeur& y = enDouble(args.size() > 1 ? args[1] : args[0]);
    std::vector<double> x;
    if (args.size() > 1)
        for (std::size_t k = 0; k < args[0].nelem(); ++k) x.push_back(args[0].re[k]);
    else
        for (std::size_t k = 0; k < y.nelem(); ++k) x.push_back((double)(k + 1));
    std::vector<double> r(y.nelem(), 0.0);
    for (std::size_t k = 1; k < y.nelem(); ++k)
        r[k] = r[k - 1] + 0.5 * (x[k] - x[k - 1]) * (y.re[k] + y.re[k - 1]);
    return {y.estColonne() ? Valeur::colonne(r) : Valeur::ligne(r)};
}

FONCTION(fnTrapz) {
    INUTILISE
    exigerArguments(args, 1, 3, "trapz");
    const Valeur& y = enDouble(args.size() > 1 ? args[1] : args[0]);
    std::vector<double> x;
    if (args.size() > 1)
        for (std::size_t k = 0; k < args[0].nelem(); ++k) x.push_back(args[0].re[k]);
    else
        for (std::size_t k = 0; k < y.nelem(); ++k) x.push_back((double)(k + 1));
    double s = 0;
    for (std::size_t k = 1; k < y.nelem(); ++k)
        s += 0.5 * (x[k] - x[k - 1]) * (y.re[k] + y.re[k - 1]);
    return {Valeur::scalaire(s)};
}

FONCTION(fnMagic) {
    INUTILISE
    int n = (int)argScalaire(args, 0, "magic");
    Valeur r = Valeur::matrice(n, n);
    auto poser = [&](int i, int j, double v) { r.re[(std::size_t)i + (std::size_t)j * n] = v; };
    if (n % 2 == 1) {
        int i = 0, j = n / 2;
        for (int k = 1; k <= n * n; ++k) {
            poser(i, j, k);
            int ni = (i - 1 + n) % n, nj = (j + 1) % n;
            if (r.re[(std::size_t)ni + (std::size_t)nj * n] != 0) {
                ni = (i + 1) % n;
                nj = j;
            }
            i = ni;
            j = nj;
        }
    } else if (n % 4 == 0) {
        for (int i = 0; i < n; ++i)
            for (int j = 0; j < n; ++j) {
                int v = i * n + j + 1;
                bool garde = ((i % 4 == 0 || i % 4 == 3) && (j % 4 == 0 || j % 4 == 3)) ||
                             ((i % 4 == 1 || i % 4 == 2) && (j % 4 == 1 || j % 4 == 2));
                poser(i, j, garde ? (n * n + 1 - v) : v);
            }
    } else {
        // Méthode LUX pour n = 4k+2.
        int m = n / 2;
        Valeur base = Valeur::matrice(m, m);
        int i = 0, j = m / 2;
        for (int k = 1; k <= m * m; ++k) {
            base.re[(std::size_t)i + (std::size_t)j * m] = k;
            int ni = (i - 1 + m) % m, nj = (j + 1) % m;
            if (base.re[(std::size_t)ni + (std::size_t)nj * m] != 0) {
                ni = (i + 1) % m;
                nj = j;
            }
            i = ni;
            j = nj;
        }
        int k = (n - 2) / 4;
        for (int a = 0; a < m; ++a)
            for (int b = 0; b < m; ++b) {
                double v = base.re[(std::size_t)a + (std::size_t)b * m];
                poser(a, b, v);
                poser(a + m, b + m, v + m * m);
                poser(a, b + m, v + 2 * m * m);
                poser(a + m, b, v + 3 * m * m);
            }
        for (int a = 0; a < m; ++a) {
            for (int b = 0; b < k; ++b) {
                int col = (a == m / 2) ? b + m / 2 : b;
                if (col < m) {
                    double t = r.re[(std::size_t)a + (std::size_t)col * n];
                    r.re[(std::size_t)a + (std::size_t)col * n] =
                        r.re[(std::size_t)(a + m) + (std::size_t)col * n];
                    r.re[(std::size_t)(a + m) + (std::size_t)col * n] = t;
                }
            }
            for (int b = 0; b < k - 1; ++b) {
                int col = n - 1 - b;
                double t = r.re[(std::size_t)a + (std::size_t)col * n];
                r.re[(std::size_t)a + (std::size_t)col * n] =
                    r.re[(std::size_t)(a + m) + (std::size_t)col * n];
                r.re[(std::size_t)(a + m) + (std::size_t)col * n] = t;
            }
        }
    }
    return {r};
}

}  // namespace

void enregistrerTableaux(Interpreteur& it) {
    it.enregistrer("sum", fnSum, "tableaux", "sum  Somme des elements.");
    it.enregistrer("prod", fnProd, "tableaux", "prod  Produit des elements.");
    it.enregistrer("cumsum", fnCumsum, "tableaux", "cumsum  Somme cumulee.");
    it.enregistrer("cumprod", fnCumprod, "tableaux", "cumprod  Produit cumule.");
    it.enregistrer("max", fnMax, "tableaux", "max  Plus grand element, avec son indice.");
    it.enregistrer("min", fnMin, "tableaux", "min  Plus petit element, avec son indice.");
    it.enregistrer("cummax", fnCummax, "tableaux", "cummax  Maximum cumule.");
    it.enregistrer("cummin", fnCummin, "tableaux", "cummin  Minimum cumule.");
    it.enregistrer("sort", fnSort, "tableaux", "sort  Tri croissant ou decroissant.");
    it.enregistrer("sortrows", fnSortrows, "tableaux", "sortrows  Tri des lignes d'une matrice.");
    it.enregistrer("find", fnFind, "tableaux", "find  Indices des elements non nuls.");
    it.enregistrer("any", fnAny, "tableaux", "any  Vrai si au moins un element est vrai.");
    it.enregistrer("all", fnAll, "tableaux", "all  Vrai si tous les elements sont vrais.");
    it.enregistrer("nnz", fnNnz, "tableaux", "nnz  Nombre d'elements non nuls.");
    it.enregistrer("diff", fnDiff, "tableaux", "diff  Differences successives.");
    it.enregistrer("unique", fnUnique, "tableaux", "unique  Valeurs distinctes triees.");
    it.enregistrer("ismember", fnIsmember, "tableaux", "ismember  Appartenance a un ensemble.");
    it.enregistrer("union", fnUnion, "tableaux", "union  Reunion de deux ensembles.");
    it.enregistrer("intersect", fnIntersect, "tableaux", "intersect  Intersection.");
    it.enregistrer("setdiff", fnSetdiff, "tableaux", "setdiff  Difference ensembliste.");
    it.enregistrer("diag", fnDiag, "tableaux", "diag  Diagonale ou matrice diagonale.");
    it.enregistrer("triu", fnTriu, "tableaux", "triu  Partie triangulaire superieure.");
    it.enregistrer("tril", fnTril, "tableaux", "tril  Partie triangulaire inferieure.");
    it.enregistrer("kron", fnKron, "tableaux", "kron  Produit de Kronecker.");
    it.enregistrer("cross", fnCross, "tableaux", "cross  Produit vectoriel.");
    it.enregistrer("dot", fnDot, "tableaux", "dot  Produit scalaire.");
    it.enregistrer("accumarray", fnAccumarray, "tableaux", "accumarray  Accumulation par indice.");
    it.enregistrer("histc", fnHistc, "tableaux", "histc  Comptage par intervalles.");
    it.enregistrer("trapz", fnTrapz, "tableaux", "trapz  Integration par trapezes.");
    it.enregistrer("cumtrapz", fnCumtrapz, "tableaux", "cumtrapz  Integration cumulee.");
    it.enregistrer("magic", fnMagic, "tableaux", "magic  Carre magique d'ordre n.");
}

}  // namespace matlibre
