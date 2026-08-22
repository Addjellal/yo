// Polynomes.cpp — polynômes et interpolation.
#include <algorithm>
#include <cmath>
#include <complex>

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

FONCTION(fnPolyval) {
    INUTILISE
    exigerArguments(args, 2, 4, "polyval");
    const Valeur& p = versDouble(args[0]);
    const Valeur& x = versDouble(args[1]);
    Valeur r = x;
    r.classe = Classe::Double;
    if (p.estComplexe() || x.estComplexe()) {
        r.assurerImaginaire();
        for (std::size_t k = 0; k < x.nelem(); ++k) {
            std::complex<double> z(x.re[k], x.im.empty() ? 0.0 : x.im[k]);
            std::complex<double> acc(0.0, 0.0);
            for (std::size_t i = 0; i < p.nelem(); ++i)
                acc = acc * z + std::complex<double>(p.re[i],
                                                     p.im.empty() ? 0.0 : p.im[i]);
            r.re[k] = acc.real();
            r.im[k] = acc.imag();
        }
        r.compacter();
        return {r};
    }
    for (std::size_t k = 0; k < x.nelem(); ++k) {
        double acc = 0;
        for (std::size_t i = 0; i < p.nelem(); ++i) acc = acc * x.re[k] + p.re[i];
        r.re[k] = acc;
    }
    return {r};
}

FONCTION(fnPolyvalm) {
    INUTILISE
    exigerArguments(args, 2, 2, "polyvalm");
    const Valeur& p = versDouble(args[0]);
    const Valeur& x = args[1];
    int n = x.nlignes();
    Valeur acc = Valeur::matrice(n, n);
    for (std::size_t i = 0; i < p.nelem(); ++i) {
        acc = produitMatrice(acc, x);
        for (int k = 0; k < n; ++k)
            acc.re[(std::size_t)k + (std::size_t)k * n] += p.re[i];
    }
    return {acc};
}

FONCTION(fnRoots) {
    INUTILISE
    exigerArguments(args, 1, 1, "roots");
    std::vector<double> c;
    for (std::size_t k = 0; k < args[0].nelem(); ++k) c.push_back(args[0].re[k]);
    // On retire les zéros de tête, puis on résout par la matrice compagnon.
    std::size_t debut = 0;
    while (debut < c.size() && c[debut] == 0) ++debut;
    c.erase(c.begin(), c.begin() + (long)debut);
    std::size_t fin = 0;
    while (c.size() > 1 && c.back() == 0) {
        c.pop_back();
        ++fin;
    }
    int n = (int)c.size() - 1;
    if (n < 1) {
        std::vector<double> zeros(fin, 0.0);
        return {Valeur::colonne(zeros)};
    }
    Valeur compagnon = Valeur::matrice(n, n);
    for (int j = 0; j < n; ++j)
        compagnon.re[(std::size_t)0 + (std::size_t)j * n] = -c[(std::size_t)j + 1] / c[0];
    for (int i = 1; i < n; ++i)
        compagnon.re[(std::size_t)i + (std::size_t)(i - 1) * n] = 1.0;
    Valeur valeurs;
    valeursPropres(compagnon, valeurs, nullptr);
    if (fin) {
        valeurs.assurerImaginaire();
        for (std::size_t k = 0; k < fin; ++k) {
            valeurs.re.push_back(0.0);
            valeurs.im.push_back(0.0);
        }
        valeurs.dims = {(int)valeurs.re.size(), 1};
        valeurs.compacter();
    }
    return {valeurs};
}

FONCTION(fnPoly) {
    INUTILISE
    exigerArguments(args, 1, 1, "poly");
    Valeur racines = args[0];
    if (!racines.estVecteur() && racines.estCarree()) {
        Valeur valeurs;
        valeursPropres(racines, valeurs, nullptr);
        racines = valeurs;
    }
    // Le calcul se fait en complexe : les paires conjuguées se recombinent
    // en coefficients réels, ce qu'un calcul sur les seules parties réelles
    // ne donnerait pas.
    std::vector<std::complex<double>> c = {std::complex<double>(1.0, 0.0)};
    for (std::size_t k = 0; k < racines.nelem(); ++k) {
        std::complex<double> r(racines.re.empty() ? 0.0 : racines.re[k],
                               racines.im.empty() ? 0.0 : racines.im[k]);
        std::vector<std::complex<double>> nouveau(c.size() + 1, std::complex<double>(0.0, 0.0));
        for (std::size_t i = 0; i < c.size(); ++i) {
            nouveau[i] += c[i];
            nouveau[i + 1] -= c[i] * r;
        }
        c = nouveau;
    }
    Valeur sortie;
    sortie.dims = {1, (int)c.size()};
    sortie.re.resize(c.size());
    sortie.im.resize(c.size());
    for (std::size_t k = 0; k < c.size(); ++k) {
        sortie.re[k] = c[k].real();
        sortie.im[k] = c[k].imag();
    }
    // Les résidus imaginaires numériques sont effacés.
    double maxIm = 0, maxRe = 0;
    for (std::size_t k = 0; k < c.size(); ++k) {
        maxIm = std::max(maxIm, std::fabs(sortie.im[k]));
        maxRe = std::max(maxRe, std::fabs(sortie.re[k]));
    }
    if (maxIm <= 1e-12 * std::max(maxRe, 1.0)) sortie.im.clear();
    return {sortie};
}

FONCTION(fnPolyfit) {
    INUTILISE
    exigerArguments(args, 3, 3, "polyfit");
    const Valeur& x = versDouble(args[0]);
    const Valeur& y = versDouble(args[1]);
    int n = (int)args[2].scal();
    int m = (int)x.nelem();
    Valeur A = Valeur::matrice(m, n + 1);
    for (int i = 0; i < m; ++i)
        for (int j = 0; j <= n; ++j)
            A.re[(std::size_t)i + (std::size_t)j * m] = std::pow(x.re[(std::size_t)i], n - j);
    Valeur b = Valeur::colonne(std::vector<double>(y.re.begin(), y.re.end()));
    Valeur c = divisionGauche(A, b);
    Valeur r = transposer(c, false);
    if (nargout >= 2) {
        Valeur structure = Valeur::structureVide();
        structure.poserChamp("normr", Valeur::scalaire(0));
        return {r, structure};
    }
    return {r};
}

FONCTION(fnPolyder) {
    INUTILISE
    exigerArguments(args, 1, 2, "polyder");
    const Valeur& p = versDouble(args[0]);
    int n = (int)p.nelem();
    if (n <= 1) return {Valeur::scalaire(0)};
    std::vector<double> d;
    for (int k = 0; k < n - 1; ++k) d.push_back(p.re[(std::size_t)k] * (n - 1 - k));
    return {Valeur::ligne(d)};
}

FONCTION(fnPolyint) {
    INUTILISE
    exigerArguments(args, 1, 2, "polyint");
    const Valeur& p = versDouble(args[0]);
    int n = (int)p.nelem();
    std::vector<double> d;
    for (int k = 0; k < n; ++k) d.push_back(p.re[(std::size_t)k] / (n - k));
    d.push_back(args.size() > 1 ? args[1].scal() : 0.0);
    return {Valeur::ligne(d)};
}

FONCTION(fnDeconv) {
    INUTILISE
    exigerArguments(args, 2, 2, "deconv");
    std::vector<double> num(args[0].re.begin(), args[0].re.end());
    std::vector<double> den(args[1].re.begin(), args[1].re.end());
    if (den.empty() || den[0] == 0)
        erreur("MATLAB:deconv:ZeroCoef", "First coefficient of B must be non-zero.");
    if (num.size() < den.size())
        return {Valeur::scalaire(0), Valeur::ligne(num)};
    std::size_t nq = num.size() - den.size() + 1;
    std::vector<double> q(nq, 0.0);
    std::vector<double> reste = num;
    for (std::size_t k = 0; k < nq; ++k) {
        q[k] = reste[k] / den[0];
        for (std::size_t j = 0; j < den.size(); ++j) reste[k + j] -= q[k] * den[j];
    }
    if (nargout >= 2) return {Valeur::ligne(q), Valeur::ligne(reste)};
    return {Valeur::ligne(q)};
}

// ---------------------------------------------------------- interpolation

double interpolerLineaire(const std::vector<double>& x, const std::vector<double>& y,
                          double xi, bool extrapoler) {
    std::size_t n = x.size();
    if (n == 0) return NAN;
    if (n == 1) return y[0];
    if (xi < x.front() || xi > x.back()) {
        if (!extrapoler) return NAN;
    }
    std::size_t k = 0;
    if (xi <= x.front()) k = 0;
    else if (xi >= x.back()) k = n - 2;
    else {
        auto it = std::upper_bound(x.begin(), x.end(), xi);
        k = (std::size_t)(it - x.begin()) - 1;
        if (k >= n - 1) k = n - 2;
    }
    double t = (xi - x[k]) / (x[k + 1] - x[k]);
    return y[k] + t * (y[k + 1] - y[k]);
}

FONCTION(fnInterp1) {
    INUTILISE
    exigerArguments(args, 2, 5, "interp1");
    std::vector<double> x, y;
    std::size_t decalage = 0;
    if (args.size() >= 3 && args[2].estNumerique() && !args[2].estVide()) {
        x.assign(args[0].re.begin(), args[0].re.end());
        y.assign(args[1].re.begin(), args[1].re.end());
        decalage = 2;
    } else {
        y.assign(args[0].re.begin(), args[0].re.end());
        for (std::size_t k = 0; k < y.size(); ++k) x.push_back((double)(k + 1));
        decalage = 1;
    }
    const Valeur& cible = args[decalage];
    std::string methode = "linear";
    bool extrapoler = false;
    for (std::size_t k = decalage + 1; k < args.size(); ++k) {
        if (args[k].estTexte() || args[k].estChaine()) {
            std::string s = args[k].versTexte();
            if (s == "extrap") extrapoler = true;
            else methode = s;
        }
    }
    Valeur r = versDouble(cible);
    for (std::size_t k = 0; k < cible.nelem(); ++k) {
        double xi = cible.re[k];
        if (methode == "nearest") {
            double meilleur = NAN;
            double distance = INFINITY;
            for (std::size_t i = 0; i < x.size(); ++i)
                if (std::fabs(x[i] - xi) < distance) {
                    distance = std::fabs(x[i] - xi);
                    meilleur = y[i];
                }
            r.re[k] = meilleur;
        } else if (methode == "previous") {
            double v = NAN;
            for (std::size_t i = 0; i < x.size(); ++i)
                if (x[i] <= xi) v = y[i];
            r.re[k] = v;
        } else if (methode == "next") {
            double v = NAN;
            for (std::size_t i = x.size(); i-- > 0;)
                if (x[i] >= xi) v = y[i];
            r.re[k] = v;
        } else {
            r.re[k] = interpolerLineaire(x, y, xi, extrapoler);
        }
    }
    return {r};
}

FONCTION(fnInterp2) {
    INUTILISE
    exigerArguments(args, 3, 6, "interp2");
    // Interpolation bilinéaire sur une grille régulière.
    const Valeur& X = versDouble(args[0]);
    const Valeur& Y = versDouble(args[1]);
    const Valeur& Z = versDouble(args[2]);
    const Valeur& xi = versDouble(args[3]);
    const Valeur& yi = versDouble(args[4 < args.size() ? 4 : 3]);
    std::vector<double> xs, ys;
    for (int j = 0; j < X.ncolonnes(); ++j) xs.push_back(X.re[(std::size_t)j * X.nlignes()]);
    for (int i = 0; i < Y.nlignes(); ++i) ys.push_back(Y.re[(std::size_t)i]);
    Valeur r = xi;
    for (std::size_t k = 0; k < xi.nelem(); ++k) {
        double px = xi.re[k], py = yi.re[std::min(k, yi.nelem() - 1)];
        auto trouver = [](const std::vector<double>& v, double p) {
            std::size_t i = 0;
            while (i + 2 < v.size() && v[i + 1] < p) ++i;
            return i;
        };
        std::size_t a = trouver(xs, px), b = trouver(ys, py);
        double tx = (xs.size() > 1) ? (px - xs[a]) / (xs[a + 1] - xs[a]) : 0.0;
        double ty = (ys.size() > 1) ? (py - ys[b]) / (ys[b + 1] - ys[b]) : 0.0;
        int l = Z.nlignes();
        double z00 = Z.re[b + a * (std::size_t)l];
        double z01 = Z.re[b + (a + 1) * (std::size_t)l];
        double z10 = Z.re[(b + 1) + a * (std::size_t)l];
        double z11 = Z.re[(b + 1) + (a + 1) * (std::size_t)l];
        r.re[k] = z00 * (1 - tx) * (1 - ty) + z01 * tx * (1 - ty) + z10 * (1 - tx) * ty +
                  z11 * tx * ty;
    }
    return {r};
}

// Spline cubique naturelle, évaluée directement.
FONCTION(fnSpline) {
    INUTILISE
    exigerArguments(args, 2, 3, "spline");
    std::vector<double> x(args[0].re.begin(), args[0].re.end());
    std::vector<double> y(args[1].re.begin(), args[1].re.end());
    std::size_t n = x.size();
    if (n < 3) {
        std::vector<Valeur> a = {args[0], args[1], args.size() > 2 ? args[2] : Valeur::vide()};
        return fnInterp1(it, a, 1);
    }
    std::vector<double> h(n - 1), alpha(n, 0.0), l(n, 1.0), mu(n, 0.0), z(n, 0.0), c(n, 0.0),
        b(n - 1), d(n - 1);
    for (std::size_t i = 0; i + 1 < n; ++i) h[i] = x[i + 1] - x[i];
    for (std::size_t i = 1; i + 1 < n; ++i)
        alpha[i] = 3.0 * ((y[i + 1] - y[i]) / h[i] - (y[i] - y[i - 1]) / h[i - 1]);
    for (std::size_t i = 1; i + 1 < n; ++i) {
        l[i] = 2 * (x[i + 1] - x[i - 1]) - h[i - 1] * mu[i - 1];
        mu[i] = h[i] / l[i];
        z[i] = (alpha[i] - h[i - 1] * z[i - 1]) / l[i];
    }
    for (std::size_t i = n - 1; i-- > 0;) {
        c[i] = z[i] - mu[i] * c[i + 1];
        b[i] = (y[i + 1] - y[i]) / h[i] - h[i] * (c[i + 1] + 2 * c[i]) / 3.0;
        d[i] = (c[i + 1] - c[i]) / (3.0 * h[i]);
    }
    if (args.size() < 3) {
        // Renvoie la structure « pp » de MATLAB.
        Valeur pp = Valeur::structureVide();
        pp.poserChamp("form", Valeur::texte("pp"));
        pp.poserChamp("breaks", Valeur::ligne(x));
        Valeur coefs = Valeur::matrice((int)n - 1, 4);
        for (std::size_t i = 0; i + 1 < n; ++i) {
            coefs.re[i + 0 * (n - 1)] = d[i];
            coefs.re[i + 1 * (n - 1)] = c[i];
            coefs.re[i + 2 * (n - 1)] = b[i];
            coefs.re[i + 3 * (n - 1)] = y[i];
        }
        pp.poserChamp("coefs", coefs);
        pp.poserChamp("pieces", Valeur::scalaire((double)(n - 1)));
        pp.poserChamp("order", Valeur::scalaire(4));
        return {pp};
    }
    const Valeur& cible = versDouble(args[2]);
    Valeur r = cible;
    for (std::size_t k = 0; k < cible.nelem(); ++k) {
        double xi = cible.re[k];
        std::size_t i = 0;
        while (i + 2 < n && x[i + 1] < xi) ++i;
        double dx = xi - x[i];
        r.re[k] = y[i] + b[i] * dx + c[i] * dx * dx + d[i] * dx * dx * dx;
    }
    return {r};
}

FONCTION(fnPpval) {
    INUTILISE
    exigerArguments(args, 2, 2, "ppval");
    const Valeur& pp = args[0];
    std::vector<double> ruptures;
    Valeur b = pp.champ("breaks");
    for (std::size_t k = 0; k < b.nelem(); ++k) ruptures.push_back(b.re[k]);
    Valeur coefs = pp.champ("coefs");
    int morceaux = coefs.nlignes(), ordre = coefs.ncolonnes();
    const Valeur& cible = versDouble(args[1]);
    Valeur r = cible;
    for (std::size_t k = 0; k < cible.nelem(); ++k) {
        double xi = cible.re[k];
        int i = 0;
        while (i + 1 < morceaux && ruptures[(std::size_t)i + 1] < xi) ++i;
        double dx = xi - ruptures[(std::size_t)i];
        double acc = 0;
        for (int j = 0; j < ordre; ++j)
            acc = acc * dx + coefs.re[(std::size_t)i + (std::size_t)j * morceaux];
        r.re[k] = acc;
    }
    return {r};
}

}  // namespace

void enregistrerPolynomes(Interpreteur& it) {
    it.enregistrer("polyval", fnPolyval, "polynomes", "polyval  Evalue un polynome.");
    it.enregistrer("polyvalm", fnPolyvalm, "polynomes", "polyvalm  Evalue sur une matrice.");
    it.enregistrer("roots", fnRoots, "polynomes", "roots  Racines d'un polynome.");
    it.enregistrer("poly", fnPoly, "polynomes", "poly  Polynome de racines donnees.");
    it.enregistrer("polyfit", fnPolyfit, "polynomes", "polyfit  Ajustement aux moindres carres.");
    it.enregistrer("polyder", fnPolyder, "polynomes", "polyder  Derivee d'un polynome.");
    it.enregistrer("polyint", fnPolyint, "polynomes", "polyint  Primitive d'un polynome.");
    it.enregistrer("deconv", fnDeconv, "polynomes", "deconv  Division polynomiale.");
    it.enregistrer("interp1", fnInterp1, "polynomes", "interp1  Interpolation 1-D.");
    it.enregistrer("interp2", fnInterp2, "polynomes", "interp2  Interpolation 2-D bilineaire.");
    it.enregistrer("spline", fnSpline, "polynomes", "spline  Spline cubique.");
    it.enregistrer("ppval", fnPpval, "polynomes", "ppval  Evalue une spline par morceaux.");
}

}  // namespace matlibre
