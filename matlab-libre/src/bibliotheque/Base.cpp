// Base.cpp — création de tableaux, tailles, classes et conversions.
#include <algorithm>
#include <cmath>
#include <random>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {
namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, std::vector<Valeur>& args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

// Sépare une éventuelle classe finale : zeros(3,'int32').
Classe extraireClasse(std::vector<Valeur>& args, Classe defaut) {
    if (args.empty()) return defaut;
    const Valeur& dernier = args.back();
    if (dernier.estTexte() || dernier.estChaine()) {
        bool trouve = false;
        std::string nom = dernier.versTexte();
        if (nom == "like") return defaut;
        Classe c = classeDepuisNom(nom, &trouve);
        if (trouve) {
            args.pop_back();
            return c;
        }
    }
    return defaut;
}

FONCTION(fnSize) {
    INUTILISE
    exigerArguments(args, 1, 3, "size");
    Dims d = args[0].dims;
    while (d.size() < 2) d.push_back(1);
    if (args.size() >= 2) {
        std::vector<double> sorties;
        const Valeur& sel = args[1];
        for (std::size_t k = 0; k < sel.nelem(); ++k) {
            int dim = (int)sel.re[k];
            sorties.push_back(dim >= 1 && dim <= (int)d.size() ? d[(std::size_t)dim - 1] : 1);
        }
        if (sorties.size() == 1) return {Valeur::scalaire(sorties[0])};
        return {Valeur::ligne(sorties)};
    }
    if (nargout <= 1) {
        std::vector<double> v(d.begin(), d.end());
        return {Valeur::ligne(v)};
    }
    std::vector<Valeur> sorties;
    for (int k = 0; k < nargout; ++k) {
        if (k == nargout - 1) {
            double reste = 1;
            for (std::size_t j = (std::size_t)k; j < d.size(); ++j) reste *= d[j];
            sorties.push_back(Valeur::scalaire((std::size_t)k < d.size() ? reste : 1));
        } else {
            sorties.push_back(
                Valeur::scalaire((std::size_t)k < d.size() ? d[(std::size_t)k] : 1));
        }
    }
    return sorties;
}

FONCTION(fnNumel) {
    INUTILISE
    exigerArguments(args, 1, 0, "numel");
    return {Valeur::scalaire((double)args[0].nelem())};
}

FONCTION(fnLength) {
    INUTILISE
    exigerArguments(args, 1, 1, "length");
    if (args[0].nelem() == 0) return {Valeur::scalaire(0)};
    int m = 0;
    for (int d : args[0].dims) m = std::max(m, d);
    return {Valeur::scalaire(m)};
}

FONCTION(fnNdims) {
    INUTILISE
    exigerArguments(args, 1, 1, "ndims");
    return {Valeur::scalaire((double)std::max<std::size_t>(2, args[0].dims.size()))};
}

FONCTION(fnIsempty) {
    INUTILISE
    exigerArguments(args, 1, 1, "isempty");
    return {Valeur::booleen(args[0].nelem() == 0)};
}

FONCTION(fnIsscalar) {
    INUTILISE
    return {Valeur::booleen(args[0].nelem() == 1)};
}
FONCTION(fnIsvector) {
    INUTILISE
    const Valeur& v = args[0];
    return {Valeur::booleen(v.dims.size() == 2 && (v.dims[0] == 1 || v.dims[1] == 1) &&
                            v.nelem() >= 1)};
}
FONCTION(fnIsrow) {
    INUTILISE
    return {Valeur::booleen(args[0].dims.size() == 2 && args[0].dims[0] == 1)};
}
FONCTION(fnIscolumn) {
    INUTILISE
    return {Valeur::booleen(args[0].dims.size() == 2 && args[0].dims[1] == 1)};
}
FONCTION(fnIsmatrix) {
    INUTILISE
    return {Valeur::booleen(args[0].dims.size() <= 2)};
}

Valeur remplir(std::vector<Valeur>& args, double valeur, Classe defaut) {
    Classe c = extraireClasse(args, defaut);
    Dims d = dimsDepuisArguments(args, 0, args.size());
    Valeur v = Valeur::matriceDims(d, valeur);
    v.classe = c;
    return v;
}

FONCTION(fnZeros) { INUTILISE return {remplir(args, 0.0, Classe::Double)}; }
FONCTION(fnOnes) { INUTILISE return {remplir(args, 1.0, Classe::Double)}; }
FONCTION(fnTrue) { INUTILISE return {remplir(args, 1.0, Classe::Logique)}; }
FONCTION(fnFalse) { INUTILISE return {remplir(args, 0.0, Classe::Logique)}; }
FONCTION(fnNan) { INUTILISE return {remplir(args, NAN, Classe::Double)}; }
FONCTION(fnInf) { INUTILISE return {remplir(args, INFINITY, Classe::Double)}; }

FONCTION(fnEye) {
    INUTILISE
    Classe c = extraireClasse(args, Classe::Double);
    Dims d = dimsDepuisArguments(args, 0, args.size());
    if (args.empty()) d = Dims{1, 1};
    Valeur v = Valeur::matrice(d[0], d[1]);
    v.classe = c;
    for (int k = 0; k < std::min(d[0], d[1]); ++k)
        v.re[(std::size_t)k + (std::size_t)k * d[0]] = 1.0;
    return {v};
}

FONCTION(fnPi) { INUTILISE return {Valeur::scalaire(3.14159265358979323846)}; }
FONCTION(fnE) { INUTILISE return {Valeur::scalaire(2.71828182845904523536)}; }
FONCTION(fnEps) {
    INUTILISE
    if (args.empty()) return {Valeur::scalaire(2.220446049250313e-16)};
    if (args[0].estTexte() || args[0].estChaine()) {
        std::string s = args[0].versTexte();
        if (s == "single") {
            Valeur v = Valeur::scalaire(1.1920929e-07);
            v.classe = Classe::Simple;
            return {v};
        }
        return {Valeur::scalaire(2.220446049250313e-16)};
    }
    return {appliquerReel(args[0], [](double x) {
        if (x == 0) return 4.940656458412465e-324;
        double e = std::floor(std::log2(std::fabs(x)));
        return std::pow(2.0, e - 52.0);
    })};
}
FONCTION(fnRealmax) { INUTILISE return {Valeur::scalaire(1.7976931348623157e308)}; }
FONCTION(fnRealmin) { INUTILISE return {Valeur::scalaire(2.2250738585072014e-308)}; }
FONCTION(fnFlintmax) { INUTILISE return {Valeur::scalaire(9007199254740992.0)}; }
FONCTION(fnImaginaire) { INUTILISE return {Valeur::complexe(0, 1)}; }

FONCTION(fnIntmax) {
    INUTILISE
    std::string nom = args.empty() ? "int32" : args[0].versTexte();
    bool trouve;
    Classe c = classeDepuisNom(nom, &trouve);
    if (!trouve || !classeEntiere(c))
        erreur("MATLAB:intmax:invalidClassName", "Invalid integer class name.");
    Valeur v = Valeur::scalaire(borneHaute(c));
    v.classe = c;
    return {v};
}
FONCTION(fnIntmin) {
    INUTILISE
    std::string nom = args.empty() ? "int32" : args[0].versTexte();
    bool trouve;
    Classe c = classeDepuisNom(nom, &trouve);
    if (!trouve || !classeEntiere(c))
        erreur("MATLAB:intmin:invalidClassName", "Invalid integer class name.");
    Valeur v = Valeur::scalaire(borneBasse(c));
    v.classe = c;
    return {v};
}

// ------------------------------------------------------------- aléatoire

FONCTION(fnRand) {
    INUTILISE
    Classe c = extraireClasse(args, Classe::Double);
    if (!args.empty() && (args[0].estTexte() || args[0].estChaine())) {
        std::string quoi = args[0].versTexte();
        if (quoi == "seed" || quoi == "state" || quoi == "twister") {
            unsigned long long graine = args.size() > 1 ? (unsigned long long)args[1].scal() : 0;
            it.generateur.seed(graine ? graine : 5489u);
            return {};
        }
    }
    Dims d = dimsDepuisArguments(args, 0, args.size());
    Valeur v = Valeur::matriceDims(d);
    v.classe = c;
    std::uniform_real_distribution<double> loi(0.0, 1.0);
    for (auto& x : v.re) x = loi(it.generateur);
    return {v};
}

FONCTION(fnRandn) {
    INUTILISE
    Classe c = extraireClasse(args, Classe::Double);
    if (!args.empty() && (args[0].estTexte() || args[0].estChaine())) {
        it.generateur.seed((unsigned long long)(args.size() > 1 ? args[1].scal() : 5489));
        return {};
    }
    Dims d = dimsDepuisArguments(args, 0, args.size());
    Valeur v = Valeur::matriceDims(d);
    v.classe = c;
    std::normal_distribution<double> loi(0.0, 1.0);
    for (auto& x : v.re) x = loi(it.generateur);
    return {v};
}

FONCTION(fnRandi) {
    INUTILISE
    exigerArguments(args, 1, 0, "randi");
    Classe c = extraireClasse(args, Classe::Double);
    double bas = 1, haut = 1;
    if (args[0].nelem() >= 2) {
        bas = args[0].re[0];
        haut = args[0].re[1];
    } else {
        haut = args[0].scal();
    }
    Dims d = dimsDepuisArguments(args, 1, args.size());
    if (args.size() == 1) d = Dims{1, 1};
    Valeur v = Valeur::matriceDims(d);
    v.classe = c;
    std::uniform_int_distribution<long long> loi((long long)bas, (long long)haut);
    for (auto& x : v.re) x = (double)loi(it.generateur);
    return {v};
}

FONCTION(fnRandperm) {
    INUTILISE
    exigerArguments(args, 1, 2, "randperm");
    int n = (int)argScalaire(args, 0, "randperm");
    int k = args.size() > 1 ? (int)args[1].scal() : n;
    std::vector<double> v((std::size_t)n);
    for (int i = 0; i < n; ++i) v[(std::size_t)i] = i + 1;
    for (int i = n - 1; i > 0; --i) {
        std::uniform_int_distribution<int> loi(0, i);
        std::swap(v[(std::size_t)i], v[(std::size_t)loi(it.generateur)]);
    }
    v.resize((std::size_t)std::min(k, n));
    return {Valeur::ligne(v)};
}

FONCTION(fnRng) {
    INUTILISE
    if (args.empty()) return {};
    if (args[0].estTexte() || args[0].estChaine()) {
        std::string s = args[0].versTexte();
        if (s == "default") it.generateur.seed(5489u);
        else if (s == "shuffle") it.generateur.seed(std::random_device{}());
        return {};
    }
    it.generateur.seed((unsigned long long)args[0].scal());
    return {};
}

// ----------------------------------------------------------- constructions

FONCTION(fnLinspace) {
    INUTILISE
    exigerArguments(args, 2, 3, "linspace");
    double a = argScalaire(args, 0, "linspace");
    double b = argScalaire(args, 1, "linspace");
    int n = args.size() > 2 ? (int)args[2].scal() : 100;
    if (n < 1) return {Valeur::matrice(1, 0)};
    std::vector<double> v((std::size_t)n);
    if (n == 1) v[0] = b;
    else
        for (int k = 0; k < n; ++k) v[(std::size_t)k] = a + (b - a) * k / (n - 1);
    return {Valeur::ligne(v)};
}

FONCTION(fnLogspace) {
    INUTILISE
    exigerArguments(args, 2, 3, "logspace");
    double a = argScalaire(args, 0, "logspace");
    double b = argScalaire(args, 1, "logspace");
    int n = args.size() > 2 ? (int)args[2].scal() : 50;
    std::vector<double> v((std::size_t)std::max(0, n));
    for (int k = 0; k < n; ++k)
        v[(std::size_t)k] = std::pow(10.0, n == 1 ? b : a + (b - a) * k / (n - 1));
    return {Valeur::ligne(v)};
}

FONCTION(fnColon) {
    INUTILISE
    exigerArguments(args, 2, 3, "colon");
    if (args.size() == 2) return {construirePlage(args[0], Valeur::scalaire(1), args[1])};
    return {construirePlage(args[0], args[1], args[2])};
}

FONCTION(fnRepmat) {
    INUTILISE
    exigerArguments(args, 2, 0, "repmat");
    const Valeur& v = args[0];
    Dims rep = dimsDepuisArguments(args, 1, args.size());
    std::size_t nd = std::max(v.dims.size(), rep.size());
    Dims vd = v.dims, rd(nd, 1);
    vd.resize(nd, 1);
    rep.resize(nd, 1);
    for (std::size_t k = 0; k < nd; ++k) rd[k] = vd[k] * rep[k];
    Valeur r = v;
    r.dims = rd;
    std::size_t n = produitDims(rd);
    switch (v.classe) {
        case Classe::Cellule: r.cellules.assign(n, Valeur::vide()); break;
        case Classe::Chaine: r.chaines.assign(n, std::string()); break;
        case Classe::Structure:
        case Classe::Objet:
            r.detacherStructure();
            for (auto& kv : r.st->champs) kv.second.assign(n, Valeur::vide());
            break;
        default:
            r.re.assign(n, 0.0);
            if (!v.im.empty()) r.im.assign(n, 0.0);
            break;
    }
    std::vector<std::size_t> pasSrc(nd, 1);
    for (std::size_t k = 1; k < nd; ++k) pasSrc[k] = pasSrc[k - 1] * (std::size_t)vd[k - 1];
    for (std::size_t k = 0; k < n; ++k) {
        std::size_t reste = k, src = 0;
        for (std::size_t d = 0; d < nd; ++d) {
            std::size_t coord = reste % (std::size_t)std::max(1, rd[d]);
            reste /= (std::size_t)std::max(1, rd[d]);
            src += (coord % (std::size_t)std::max(1, vd[d])) * pasSrc[d];
        }
        switch (v.classe) {
            case Classe::Cellule: r.cellules[k] = v.cellules[src]; break;
            case Classe::Chaine: r.chaines[k] = v.chaines[src]; break;
            case Classe::Structure:
            case Classe::Objet:
                for (auto& kv : r.st->champs) {
                    const auto& source = v.st->champs.at(kv.first);
                    kv.second[k] = src < source.size() ? source[src] : Valeur::vide();
                }
                break;
            default:
                r.re[k] = v.re[src];
                if (!r.im.empty()) r.im[k] = v.im[src];
                break;
        }
    }
    r.normaliserDims();
    return {r};
}

FONCTION(fnCat) {
    INUTILISE
    exigerArguments(args, 1, 0, "cat");
    int dim = (int)argScalaire(args, 0, "cat") - 1;
    std::vector<Valeur> reste(args.begin() + 1, args.end());
    return {concatener(reste, std::max(0, dim))};
}
FONCTION(fnHorzcat) { INUTILISE return {concatener(args, 1)}; }
FONCTION(fnVertcat) { INUTILISE return {concatener(args, 0)}; }

FONCTION(fnReshape) {
    INUTILISE
    exigerArguments(args, 2, 0, "reshape");
    Dims d;
    int inconnue = -1;
    if (args.size() == 2) {
        for (std::size_t k = 0; k < args[1].nelem(); ++k) d.push_back((int)args[1].re[k]);
    } else {
        for (std::size_t k = 1; k < args.size(); ++k) {
            if (args[k].estVide()) {
                inconnue = (int)d.size();
                d.push_back(1);
            } else {
                d.push_back((int)args[k].scal());
            }
        }
    }
    if (inconnue >= 0) {
        std::size_t autres = 1;
        for (std::size_t k = 0; k < d.size(); ++k)
            if ((int)k != inconnue) autres *= (std::size_t)d[k];
        d[(std::size_t)inconnue] = autres ? (int)(args[0].nelem() / autres) : 0;
    }
    return {reshaperVers(args[0], d)};
}

FONCTION(fnPermute) {
    INUTILISE
    exigerArguments(args, 2, 2, "permute");
    std::vector<int> ordre;
    for (std::size_t k = 0; k < args[1].nelem(); ++k) ordre.push_back((int)args[1].re[k] - 1);
    return {permuterDims(args[0], ordre)};
}

FONCTION(fnIpermute) {
    INUTILISE
    exigerArguments(args, 2, 2, "ipermute");
    std::vector<int> ordre((std::size_t)args[1].nelem());
    for (std::size_t k = 0; k < args[1].nelem(); ++k)
        ordre[(std::size_t)((int)args[1].re[k] - 1)] = (int)k;
    return {permuterDims(args[0], ordre)};
}

FONCTION(fnSqueeze) {
    INUTILISE
    exigerArguments(args, 1, 1, "squeeze");
    Dims d;
    for (int x : args[0].dims)
        if (x != 1) d.push_back(x);
    while (d.size() < 2) d.push_back(1);
    if (args[0].dims.size() <= 2) return {args[0]};
    return {reshaperVers(args[0], d)};
}

FONCTION(fnCircshift) {
    INUTILISE
    exigerArguments(args, 2, 3, "circshift");
    const Valeur& v = args[0];
    Dims d = v.dims;
    std::vector<int> decalages(d.size(), 0);
    if (args.size() >= 3) {
        int dim = (int)args[2].scal() - 1;
        if (dim >= 0 && dim < (int)d.size()) decalages[(std::size_t)dim] = (int)args[1].scal();
    } else if (args[1].nelem() == 1) {
        int dim = dimensionParDefaut(v);
        decalages[(std::size_t)dim] = (int)args[1].scal();
    } else {
        for (std::size_t k = 0; k < args[1].nelem() && k < d.size(); ++k)
            decalages[k] = (int)args[1].re[k];
    }
    Valeur r = v;
    std::size_t n = v.nelem();
    std::vector<std::size_t> pas(d.size(), 1);
    for (std::size_t k = 1; k < d.size(); ++k) pas[k] = pas[k - 1] * (std::size_t)d[k - 1];
    for (std::size_t k = 0; k < n; ++k) {
        std::size_t reste = k, src = 0;
        for (std::size_t dd = 0; dd < d.size(); ++dd) {
            long long taille = std::max(1, d[dd]);
            long long coord = (long long)(reste % (std::size_t)taille);
            reste /= (std::size_t)taille;
            long long o = ((coord - decalages[dd]) % taille + taille) % taille;
            src += (std::size_t)o * pas[dd];
        }
        switch (v.classe) {
            case Classe::Cellule: r.cellules[k] = v.cellules[src]; break;
            case Classe::Chaine: r.chaines[k] = v.chaines[src]; break;
            default:
                r.re[k] = v.re[src];
                if (!r.im.empty()) r.im[k] = v.im[src];
                break;
        }
    }
    return {r};
}

Valeur retourner(const Valeur& v, int dimension) {
    Dims d = v.dims;
    while ((int)d.size() <= dimension) d.push_back(1);
    Valeur r = v;
    std::size_t n = v.nelem();
    std::vector<std::size_t> pas(d.size(), 1);
    for (std::size_t k = 1; k < d.size(); ++k) pas[k] = pas[k - 1] * (std::size_t)d[k - 1];
    for (std::size_t k = 0; k < n; ++k) {
        std::size_t reste = k, src = 0;
        for (std::size_t dd = 0; dd < d.size(); ++dd) {
            std::size_t taille = (std::size_t)std::max(1, d[dd]);
            std::size_t coord = reste % taille;
            reste /= taille;
            std::size_t o = ((int)dd == dimension) ? taille - 1 - coord : coord;
            src += o * pas[dd];
        }
        switch (v.classe) {
            case Classe::Cellule: r.cellules[k] = v.cellules[src]; break;
            case Classe::Chaine: r.chaines[k] = v.chaines[src]; break;
            default:
                r.re[k] = v.re[src];
                if (!r.im.empty()) r.im[k] = v.im[src];
                break;
        }
    }
    return r;
}

FONCTION(fnFlip) {
    INUTILISE
    exigerArguments(args, 1, 2, "flip");
    int dim = args.size() > 1 ? (int)args[1].scal() - 1 : dimensionParDefaut(args[0]);
    return {retourner(args[0], dim)};
}
FONCTION(fnFliplr) { INUTILISE return {retourner(args[0], 1)}; }
FONCTION(fnFlipud) { INUTILISE return {retourner(args[0], 0)}; }

FONCTION(fnRot90) {
    INUTILISE
    exigerArguments(args, 1, 2, "rot90");
    int k = args.size() > 1 ? ((int)args[1].scal() % 4 + 4) % 4 : 1;
    Valeur v = args[0];
    for (int i = 0; i < k; ++i) v = retourner(transposer(v, false), 0);
    return {v};
}

FONCTION(fnTranspose) { INUTILISE return {transposer(args[0], false)}; }
FONCTION(fnCtranspose) { INUTILISE return {transposer(args[0], true)}; }

FONCTION(fnMeshgrid) {
    INUTILISE
    exigerArguments(args, 1, 3, "meshgrid");
    Valeur x = args[0];
    Valeur y = args.size() > 1 ? args[1] : args[0];
    int nx = (int)x.nelem(), ny = (int)y.nelem();
    Valeur X = Valeur::matrice(ny, nx), Y = Valeur::matrice(ny, nx);
    for (int j = 0; j < nx; ++j)
        for (int i = 0; i < ny; ++i) {
            X.re[(std::size_t)i + (std::size_t)j * ny] = x.re[(std::size_t)j];
            Y.re[(std::size_t)i + (std::size_t)j * ny] = y.re[(std::size_t)i];
        }
    if (args.size() > 2 && nargout > 2) {
        const Valeur& z = args[2];
        int nz = (int)z.nelem();
        Dims d{ny, nx, nz};
        Valeur X3 = Valeur::matriceDims(d), Y3 = Valeur::matriceDims(d), Z3 =
            Valeur::matriceDims(d);
        for (int k = 0; k < nz; ++k)
            for (int j = 0; j < nx; ++j)
                for (int i = 0; i < ny; ++i) {
                    std::size_t p = (std::size_t)i + (std::size_t)j * ny +
                                    (std::size_t)k * ny * nx;
                    X3.re[p] = x.re[(std::size_t)j];
                    Y3.re[p] = y.re[(std::size_t)i];
                    Z3.re[p] = z.re[(std::size_t)k];
                }
        return {X3, Y3, Z3};
    }
    if (nargout <= 1) return {X};
    return {X, Y};
}

FONCTION(fnNdgrid) {
    INUTILISE
    exigerArguments(args, 1, 0, "ndgrid");
    if (args.size() == 1) args.push_back(args[0]);
    Valeur x = args[0], y = args[1];
    int nx = (int)x.nelem(), ny = (int)y.nelem();
    Valeur X = Valeur::matrice(nx, ny), Y = Valeur::matrice(nx, ny);
    for (int j = 0; j < ny; ++j)
        for (int i = 0; i < nx; ++i) {
            X.re[(std::size_t)i + (std::size_t)j * nx] = x.re[(std::size_t)i];
            Y.re[(std::size_t)i + (std::size_t)j * nx] = y.re[(std::size_t)j];
        }
    if (nargout <= 1) return {X};
    return {X, Y};
}

FONCTION(fnSub2ind) {
    INUTILISE
    exigerArguments(args, 2, 0, "sub2ind");
    Dims d;
    for (std::size_t k = 0; k < args[0].nelem(); ++k) d.push_back((int)args[0].re[k]);
    std::size_t n = args[1].nelem();
    Valeur r = args[1];
    r.classe = Classe::Double;
    for (std::size_t e = 0; e < n; ++e) {
        std::size_t idx = 0, pas = 1;
        for (std::size_t k = 1; k < args.size(); ++k) {
            std::size_t coord = (std::size_t)args[k].re[e] - 1;
            idx += coord * pas;
            pas *= (std::size_t)(k - 1 < d.size() ? d[k - 1] : 1);
        }
        r.re[e] = (double)(idx + 1);
    }
    return {r};
}

FONCTION(fnInd2sub) {
    INUTILISE
    exigerArguments(args, 2, 2, "ind2sub");
    Dims d;
    for (std::size_t k = 0; k < args[0].nelem(); ++k) d.push_back((int)args[0].re[k]);
    int sorties = std::max(1, nargout);
    std::vector<Valeur> res;
    for (int k = 0; k < sorties; ++k) res.push_back(args[1]);
    for (std::size_t e = 0; e < args[1].nelem(); ++e) {
        std::size_t reste = (std::size_t)args[1].re[e] - 1;
        for (int k = 0; k < sorties; ++k) {
            std::size_t taille = (std::size_t)((std::size_t)k < d.size() ? d[(std::size_t)k] : 1);
            if (k == sorties - 1) {
                res[(std::size_t)k].re[e] = (double)(reste + 1);
            } else {
                res[(std::size_t)k].re[e] = (double)(reste % taille + 1);
                reste /= taille;
            }
        }
    }
    for (auto& v : res) v.classe = Classe::Double;
    return res;
}

// ------------------------------------------------------------- classes

FONCTION(fnClass) {
    INUTILISE
    exigerArguments(args, 1, 1, "class");
    return {Valeur::texte(args[0].classeNom())};
}

FONCTION(fnIsa) {
    INUTILISE
    exigerArguments(args, 2, 2, "isa");
    std::string cible = args[1].versTexte();
    std::string reelle = args[0].classeNom();
    if (cible == reelle) return {Valeur::booleen(true)};
    if (cible == "numeric") return {Valeur::booleen(args[0].estNumerique())};
    if (cible == "float")
        return {Valeur::booleen(args[0].classe == Classe::Double ||
                                args[0].classe == Classe::Simple)};
    if (cible == "integer") return {Valeur::booleen(classeEntiere(args[0].classe))};
    return {Valeur::booleen(false)};
}

Valeur convertirVers(const Valeur& v, Classe c) {
    if (c == Classe::Cellule) {
        if (v.classe == Classe::Cellule) return v;
        Valeur r = Valeur::celluleDims(v.dims);
        for (std::size_t k = 0; k < v.nelem(); ++k) r.cellules[k] = extraireElement(v, k);
        return r;
    }
    if (c == Classe::Chaine) {
        if (v.classe == Classe::Chaine) return v;
        if (v.classe == Classe::Caractere) {
            Valeur r;
            r.classe = Classe::Chaine;
            r.dims = {1, 1};
            r.chaines = {v.versTexte()};
            return r;
        }
        Valeur r;
        r.classe = Classe::Chaine;
        r.dims = v.dims;
        r.chaines.resize(v.nelem());
        for (std::size_t k = 0; k < v.nelem(); ++k) {
            double x = v.re[k];
            r.chaines[k] = (x == std::floor(x) && std::fabs(x) < 1e15)
                               ? formater("%.0f", x)
                               : formater("%g", x);
        }
        return r;
    }
    if (c == Classe::Caractere && v.classe == Classe::Chaine) {
        // char("2D") rend le texte, pas le code numerique : c'est une
        // conversion de representation, pas de valeur. Un tableau de
        // chaines devient une matrice de caracteres completee par des
        // blancs, comme dans MATLAB.
        if (v.nelem() == 1) return Valeur::texte(v.chaines.empty() ? "" : v.chaines[0]);
        std::size_t largeur = 0;
        for (const auto& t : v.chaines) largeur = std::max(largeur, t.size());
        int lignes = (int)v.nelem();
        Valeur r = Valeur::matrice(lignes, (int)largeur, (double)' ');
        r.classe = Classe::Caractere;
        for (int i = 0; i < lignes; ++i) {
            const std::string& t = v.chaines[(std::size_t)i];
            for (std::size_t j = 0; j < t.size(); ++j)
                r.re[(std::size_t)i + j * (std::size_t)lignes] = (double)(unsigned char)t[j];
        }
        return r;
    }
    Valeur base = v;
    if (v.classe == Classe::Chaine) {
        // "3.5" -> 3.5 ; sinon les codes de caractères.
        Valeur r;
        r.dims = v.dims;
        r.re.resize(v.nelem());
        for (std::size_t k = 0; k < v.nelem(); ++k) r.re[k] = std::atof(v.chaines[k].c_str());
        base = r;
    }
    if (v.classe == Classe::Cellule)
        erreur("MATLAB:invalidConversion",
               "Conversion to double from cell is not possible.");
    return appliquerClasse(base, c);
}

FONCTION(fnCast) {
    INUTILISE
    exigerArguments(args, 2, 3, "cast");
    bool trouve;
    Classe c = classeDepuisNom(args[1].versTexte(), &trouve);
    if (!trouve) erreur("MATLAB:cast:invalidClass", "Invalid class name.");
    return {convertirVers(args[0], c)};
}

template <Classe C>
FONCTION(fnConversion) {
    INUTILISE
    if (args.empty()) return {Valeur::videClasse(C)};
    return {convertirVers(args[0], C)};
}

FONCTION(fnComplexe) {
    INUTILISE
    exigerArguments(args, 1, 2, "complex");
    Valeur a = args[0];
    Valeur b = args.size() > 1 ? args[1] : Valeur::scalaire(0);
    return {diffuserComplexe(a, b, [](double ar, double, double br, double, double& rr,
                                      double& ri) {
        rr = ar;
        ri = br;
    })};
}

FONCTION(fnIsnumeric) { INUTILISE return {Valeur::booleen(args[0].estNumerique())}; }
FONCTION(fnIschar) { INUTILISE return {Valeur::booleen(args[0].classe == Classe::Caractere)}; }
FONCTION(fnIsstring) { INUTILISE return {Valeur::booleen(args[0].classe == Classe::Chaine)}; }
FONCTION(fnIslogical) { INUTILISE return {Valeur::booleen(args[0].classe == Classe::Logique)}; }
FONCTION(fnIscell) { INUTILISE return {Valeur::booleen(args[0].classe == Classe::Cellule)}; }
FONCTION(fnIsstruct) {
    INUTILISE
    return {Valeur::booleen(args[0].classe == Classe::Structure)};
}
FONCTION(fnIsreal) { INUTILISE return {Valeur::booleen(!args[0].estComplexe())}; }
FONCTION(fnIsfloat) {
    INUTILISE
    return {Valeur::booleen(args[0].classe == Classe::Double ||
                            args[0].classe == Classe::Simple)};
}
FONCTION(fnIsinteger) { INUTILISE return {Valeur::booleen(classeEntiere(args[0].classe))}; }
FONCTION(fnIsobject) { INUTILISE return {Valeur::booleen(args[0].classe == Classe::Objet)}; }
FONCTION(fnIsFonction) {
    INUTILISE
    return {Valeur::booleen(args[0].classe == Classe::Fonction)};
}

bool egales(const Valeur& a, const Valeur& b, bool nanEgaux) {
    if (a.classe == Classe::Cellule || b.classe == Classe::Cellule) {
        if (a.classe != b.classe) return false;
        if (!memeDims(a.dims, b.dims)) return false;
        for (std::size_t k = 0; k < a.cellules.size(); ++k)
            if (!egales(a.cellules[k], b.cellules[k], nanEgaux)) return false;
        return true;
    }
    if (a.estStructure() || b.estStructure()) {
        if (!a.estStructure() || !b.estStructure()) return false;
        if (a.nelem() != b.nelem()) return false;
        auto ca = a.champs(), cb = b.champs();
        std::sort(ca.begin(), ca.end());
        std::sort(cb.begin(), cb.end());
        if (ca != cb) return false;
        for (std::size_t i = 0; i < a.nelem(); ++i)
            for (const auto& nom : ca)
                if (!egales(a.champ(nom, i), b.champ(nom, i), nanEgaux)) return false;
        return true;
    }
    if ((a.estTexte() || a.estChaine()) && (b.estTexte() || b.estChaine())) {
        if (a.classe == b.classe && a.classe == Classe::Chaine) {
            if (!memeDims(a.dims, b.dims)) return false;
            return a.chaines == b.chaines;
        }
        return a.versTexte() == b.versTexte();
    }
    if (a.classe == Classe::Fonction || b.classe == Classe::Fonction)
        return a.fn && b.fn && a.fn.get() == b.fn.get();
    if (!memeDims(a.dims, b.dims)) {
        if (a.estScalaire() || b.estScalaire()) {
            const Valeur& s = a.estScalaire() ? a : b;
            const Valeur& g = a.estScalaire() ? b : a;
            for (std::size_t k = 0; k < g.nelem(); ++k) {
                double x = g.re[k], y = s.re.empty() ? 0 : s.re[0];
                if (nanEgaux && std::isnan(x) && std::isnan(y)) continue;
                if (x != y) return false;
            }
            return true;
        }
        return false;
    }
    for (std::size_t k = 0; k < a.nelem(); ++k) {
        double x = a.re.empty() ? 0 : a.re[k], y = b.re.empty() ? 0 : b.re[k];
        if (nanEgaux && std::isnan(x) && std::isnan(y)) continue;
        if (x != y) return false;
        double xi = a.im.empty() ? 0 : a.im[k], yi = b.im.empty() ? 0 : b.im[k];
        if (nanEgaux && std::isnan(xi) && std::isnan(yi)) continue;
        if (xi != yi) return false;
    }
    return true;
}

FONCTION(fnIsequal) {
    INUTILISE
    exigerArguments(args, 2, 0, "isequal");
    for (std::size_t k = 1; k < args.size(); ++k)
        if (!egales(args[0], args[k], false)) return {Valeur::booleen(false)};
    return {Valeur::booleen(true)};
}

FONCTION(fnIsequaln) {
    INUTILISE
    exigerArguments(args, 2, 0, "isequaln");
    for (std::size_t k = 1; k < args.size(); ++k)
        if (!egales(args[0], args[k], true)) return {Valeur::booleen(false)};
    return {Valeur::booleen(true)};
}

FONCTION(fnValidateattributes) {
    INUTILISE
    return {};
}

}  // namespace

void enregistrerBase(Interpreteur& it) {
    it.enregistrer("size", fnSize, "base",
                   "size  Taille d'un tableau.\n  d = size(A) rend le vecteur des "
                   "dimensions.\n  [l,c] = size(A) rend lignes et colonnes.\n  "
                   "size(A,k) rend la k-ieme dimension.");
    it.enregistrer("numel", fnNumel, "base", "numel  Nombre d'elements d'un tableau.");
    it.enregistrer("length", fnLength, "base",
                   "length  Plus grande dimension, 0 si le tableau est vide.");
    it.enregistrer("ndims", fnNdims, "base", "ndims  Nombre de dimensions (au moins 2).");
    it.enregistrer("isempty", fnIsempty, "base", "isempty  Vrai si le tableau est vide.");
    it.enregistrer("isscalar", fnIsscalar, "base", "isscalar  Vrai pour un tableau 1x1.");
    it.enregistrer("isvector", fnIsvector, "base", "isvector  Vrai pour un vecteur.");
    it.enregistrer("isrow", fnIsrow, "base", "isrow  Vrai pour un vecteur ligne.");
    it.enregistrer("iscolumn", fnIscolumn, "base", "iscolumn  Vrai pour un vecteur colonne.");
    it.enregistrer("ismatrix", fnIsmatrix, "base", "ismatrix  Vrai pour un tableau 2-D.");

    it.enregistrer("zeros", fnZeros, "base", "zeros  Tableau de zeros.");
    it.enregistrer("ones", fnOnes, "base", "ones  Tableau de uns.");
    it.enregistrer("true", fnTrue, "base", "true  Tableau logique vrai.");
    it.enregistrer("false", fnFalse, "base", "false  Tableau logique faux.");
    it.enregistrer("nan", fnNan, "base", "nan  Tableau de NaN.");
    it.enregistrer("NaN", fnNan, "base", "NaN  Tableau de NaN.");
    it.enregistrer("inf", fnInf, "base", "inf  Tableau d'infinis.");
    it.enregistrer("Inf", fnInf, "base", "Inf  Tableau d'infinis.");
    it.enregistrer("eye", fnEye, "base", "eye  Matrice identite.");
    it.enregistrer("pi", fnPi, "base", "pi  3.14159265358979...");
    it.enregistrer("e", fnE, "base", "e  2.71828182845905...");
    it.enregistrer("eps", fnEps, "base", "eps  Precision relative des flottants.");
    it.enregistrer("realmax", fnRealmax, "base", "realmax  Plus grand flottant.");
    it.enregistrer("realmin", fnRealmin, "base", "realmin  Plus petit flottant normalise.");
    it.enregistrer("flintmax", fnFlintmax, "base", "flintmax  Plus grand entier exact.");
    it.enregistrer("i", fnImaginaire, "base", "i  Unite imaginaire.");
    it.enregistrer("j", fnImaginaire, "base", "j  Unite imaginaire.");
    it.enregistrer("I", fnImaginaire, "base", "I  Unite imaginaire.");
    it.enregistrer("J", fnImaginaire, "base", "J  Unite imaginaire.");
    it.enregistrer("intmax", fnIntmax, "base", "intmax  Plus grand entier d'une classe.");
    it.enregistrer("intmin", fnIntmin, "base", "intmin  Plus petit entier d'une classe.");

    it.enregistrer("rand", fnRand, "base", "rand  Nombres uniformes sur [0,1].");
    it.enregistrer("randn", fnRandn, "base", "randn  Nombres normaux centres reduits.");
    it.enregistrer("randi", fnRandi, "base", "randi  Entiers uniformes.");
    it.enregistrer("randperm", fnRandperm, "base", "randperm  Permutation aleatoire.");
    it.enregistrer("rng", fnRng, "base", "rng  Regle le generateur aleatoire.");

    it.enregistrer("linspace", fnLinspace, "base", "linspace  Vecteur a pas constant.");
    it.enregistrer("logspace", fnLogspace, "base", "logspace  Vecteur a pas logarithmique.");
    it.enregistrer("colon", fnColon, "base", "colon  Equivalent fonctionnel de a:b:c.");
    it.enregistrer("repmat", fnRepmat, "base", "repmat  Repete un tableau en mosaique.");
    it.enregistrer("cat", fnCat, "base", "cat  Concatene selon une dimension.");
    it.enregistrer("horzcat", fnHorzcat, "base", "horzcat  Concatenation horizontale.");
    it.enregistrer("vertcat", fnVertcat, "base", "vertcat  Concatenation verticale.");
    it.enregistrer("reshape", fnReshape, "base", "reshape  Change la forme sans copier.");
    it.enregistrer("permute", fnPermute, "base", "permute  Permute les dimensions.");
    it.enregistrer("ipermute", fnIpermute, "base", "ipermute  Permutation inverse.");
    it.enregistrer("squeeze", fnSqueeze, "base", "squeeze  Retire les dimensions unitaires.");
    it.enregistrer("circshift", fnCircshift, "base", "circshift  Decalage circulaire.");
    it.enregistrer("flip", fnFlip, "base", "flip  Retourne selon une dimension.");
    it.enregistrer("fliplr", fnFliplr, "base", "fliplr  Retourne de gauche a droite.");
    it.enregistrer("flipud", fnFlipud, "base", "flipud  Retourne de haut en bas.");
    it.enregistrer("rot90", fnRot90, "base", "rot90  Rotation de 90 degres.");
    it.enregistrer("transpose", fnTranspose, "base", "transpose  Transposition simple.");
    it.enregistrer("ctranspose", fnCtranspose, "base",
                   "ctranspose  Transposition conjuguee.");
    it.enregistrer("meshgrid", fnMeshgrid, "base", "meshgrid  Grille cartesienne.");
    it.enregistrer("ndgrid", fnNdgrid, "base", "ndgrid  Grille en ordre tableau.");
    it.enregistrer("sub2ind", fnSub2ind, "base", "sub2ind  Indices vers index lineaire.");
    it.enregistrer("ind2sub", fnInd2sub, "base", "ind2sub  Index lineaire vers indices.");

    it.enregistrer("class", fnClass, "base", "class  Nom de la classe d'une valeur.");
    it.enregistrer("isa", fnIsa, "base", "isa  Teste l'appartenance a une classe.");
    it.enregistrer("cast", fnCast, "base", "cast  Conversion vers une classe nommee.");
    it.enregistrer("double", fnConversion<Classe::Double>, "base", "double  Conversion double.");
    it.enregistrer("single", fnConversion<Classe::Simple>, "base", "single  Conversion single.");
    it.enregistrer("logical", fnConversion<Classe::Logique>, "base",
                   "logical  Conversion logique.");
    it.enregistrer("char", fnConversion<Classe::Caractere>, "base", "char  Conversion char.");
    it.enregistrer("int8", fnConversion<Classe::Int8>, "base", "int8  Entier signe 8 bits.");
    it.enregistrer("int16", fnConversion<Classe::Int16>, "base", "int16  Entier signe 16 bits.");
    it.enregistrer("int32", fnConversion<Classe::Int32>, "base", "int32  Entier signe 32 bits.");
    it.enregistrer("int64", fnConversion<Classe::Int64>, "base", "int64  Entier signe 64 bits.");
    it.enregistrer("uint8", fnConversion<Classe::UInt8>, "base", "uint8  Entier non signe 8 bits.");
    it.enregistrer("uint16", fnConversion<Classe::UInt16>, "base",
                   "uint16  Entier non signe 16 bits.");
    it.enregistrer("uint32", fnConversion<Classe::UInt32>, "base",
                   "uint32  Entier non signe 32 bits.");
    it.enregistrer("uint64", fnConversion<Classe::UInt64>, "base",
                   "uint64  Entier non signe 64 bits.");
    it.enregistrer("complex", fnComplexe, "base", "complex  Construit un nombre complexe.");

    it.enregistrer("isnumeric", fnIsnumeric, "base", "isnumeric  Vrai pour un tableau numerique.");
    it.enregistrer("ischar", fnIschar, "base", "ischar  Vrai pour un tableau de caracteres.");
    it.enregistrer("isstring", fnIsstring, "base", "isstring  Vrai pour un tableau string.");
    it.enregistrer("islogical", fnIslogical, "base", "islogical  Vrai pour un tableau logique.");
    it.enregistrer("iscell", fnIscell, "base", "iscell  Vrai pour un tableau de cellules.");
    it.enregistrer("isstruct", fnIsstruct, "base", "isstruct  Vrai pour une structure.");
    it.enregistrer("isreal", fnIsreal, "base", "isreal  Vrai si aucune partie imaginaire.");
    it.enregistrer("isfloat", fnIsfloat, "base", "isfloat  Vrai pour double ou single.");
    it.enregistrer("isinteger", fnIsinteger, "base", "isinteger  Vrai pour un entier machine.");
    it.enregistrer("isobject", fnIsobject, "base", "isobject  Vrai pour un objet.");
    it.enregistrer("is_function_handle", fnIsFonction, "base",
                   "is_function_handle  Vrai pour une poignee de fonction.");
    it.enregistrer("isequal", fnIsequal, "base", "isequal  Egalite de contenu.");
    it.enregistrer("isequaln", fnIsequaln, "base", "isequaln  Egalite, NaN compris.");
    it.enregistrer("validateattributes", fnValidateattributes, "base",
                   "validateattributes  Verifie des attributs (tolerant).");
}

}  // namespace matlibre
