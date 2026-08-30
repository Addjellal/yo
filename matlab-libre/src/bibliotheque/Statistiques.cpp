// Statistiques.cpp — statistiques descriptives et lois usuelles.
#include <algorithm>
#include <cmath>
#include <map>
#include <numeric>
#include <random>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {
namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

const double PI = 3.14159265358979323846;

int dimensionChoisie(std::vector<Valeur>& args, std::size_t position, const Valeur& v) {
    if (args.size() > position && !args[position].estVide() &&
        !(args[position].estTexte() || args[position].estChaine())) {
        exigerNumerique(args[position], "dim");
        int d = (int)args[position].scal() - 1;
        exigerDimension(d);
        return d;
    }
    return dimensionParDefaut(v);
}

double moyenneDe(const std::vector<double>& t) {
    if (t.empty()) return NAN;
    double s = 0;
    for (double x : t) s += x;
    return s / (double)t.size();
}

double medianeDe(std::vector<double> t) {
    if (t.empty()) return NAN;
    std::sort(t.begin(), t.end());
    std::size_t n = t.size();
    return (n % 2) ? t[n / 2] : 0.5 * (t[n / 2 - 1] + t[n / 2]);
}

double varianceDe(const std::vector<double>& t, int normalisation) {
    if (t.size() < 2) return normalisation == 1 ? 0.0 : (t.empty() ? NAN : 0.0);
    double m = moyenneDe(t);
    double s = 0;
    for (double x : t) s += (x - m) * (x - m);
    return s / (double)(t.size() - (normalisation == 1 ? 0 : 1));
}

FONCTION(fnMean) {
    INUTILISE
    exigerArguments(args, 1, 3, "mean");
    Valeur v = versDouble(args[0]);
    if (v.estVide()) return {Valeur::scalaire(NAN)};
    if (optionToutesDimensions(args)) v = aplatirColonne(v);
    int dim = dimensionChoisie(args, 1, v);
    return {reduire(v, dim, false, moyenneDe)};
}

FONCTION(fnMedian) {
    INUTILISE
    exigerArguments(args, 1, 3, "median");
    Valeur v = versDouble(args[0]);
    if (v.estVide()) return {Valeur::scalaire(NAN)};
    if (optionToutesDimensions(args)) v = aplatirColonne(v);
    int dim = dimensionChoisie(args, 1, v);
    return {reduire(v, dim, false, [](const std::vector<double>& t) { return medianeDe(t); })};
}

FONCTION(fnMode) {
    INUTILISE
    exigerArguments(args, 1, 2, "mode");
    Valeur v = versDouble(args[0]);
    int dim = dimensionChoisie(args, 1, v);
    return {reduire(v, dim, false, [](const std::vector<double>& t) {
        std::map<double, int> compte;
        for (double x : t) ++compte[x];
        double meilleur = NAN;
        int n = -1;
        for (const auto& kv : compte)
            if (kv.second > n) {
                n = kv.second;
                meilleur = kv.first;
            }
        return meilleur;
    })};
}

FONCTION(fnVar) {
    INUTILISE
    exigerArguments(args, 1, 3, "var");
    Valeur v = versDouble(args[0]);
    int normalisation = args.size() > 1 && !args[1].estVide() ? (int)args[1].scal() : 0;
    int dim = args.size() > 2 ? (int)args[2].scal() - 1 : dimensionParDefaut(v);
    if (v.estVecteur() && args.size() <= 2) dim = dimensionParDefaut(v);
    return {reduire(v, dim, false, [normalisation](const std::vector<double>& t) {
        return varianceDe(t, normalisation);
    })};
}

FONCTION(fnStd) {
    INUTILISE
    exigerArguments(args, 1, 3, "std");
    Valeur v = versDouble(args[0]);
    int normalisation = args.size() > 1 && !args[1].estVide() ? (int)args[1].scal() : 0;
    int dim = args.size() > 2 ? (int)args[2].scal() - 1 : dimensionParDefaut(v);
    return {reduire(v, dim, false, [normalisation](const std::vector<double>& t) {
        return std::sqrt(varianceDe(t, normalisation));
    })};
}

FONCTION(fnRange) {
    INUTILISE
    Valeur v = versDouble(args[0]);
    int dim = dimensionChoisie(args, 1, v);
    return {reduire(v, dim, false, [](const std::vector<double>& t) -> double {
        if (t.empty()) return NAN;
        auto mm = std::minmax_element(t.begin(), t.end());
        return *mm.second - *mm.first;
    })};
}

double quantileDe(std::vector<double> t, double p) {
    if (t.empty()) return NAN;
    std::sort(t.begin(), t.end());
    std::size_t n = t.size();
    // Convention de MATLAB : les points sont aux fréquences (k-0.5)/n.
    double position = p * (double)n - 0.5;
    if (position <= 0) return t.front();
    if (position >= (double)(n - 1)) return t.back();
    std::size_t bas = (std::size_t)std::floor(position);
    double frac = position - (double)bas;
    return t[bas] * (1 - frac) + t[bas + 1] * frac;
}

FONCTION(fnQuantile) {
    INUTILISE
    exigerArguments(args, 2, 3, "quantile");
    exigerNumerique(args[0], "quantile");
    if (args.size() > 1) exigerNumerique(args[1], "quantile");
    Valeur v = versDouble(args[0]);
    std::vector<double> t(v.re.begin(), v.re.end());
    const Valeur& p = args[1];
    if (p.estScalaire()) return {Valeur::scalaire(quantileDe(t, p.scal()))};
    Valeur r = Valeur::matriceDims(p.dims);
    for (std::size_t k = 0; k < p.nelem(); ++k) r.re[k] = quantileDe(t, p.re[k]);
    return {r};
}

FONCTION(fnPrctile) {
    INUTILISE
    exigerArguments(args, 2, 3, "prctile");
    exigerNumerique(args[0], "prctile");
    if (args.size() > 1) exigerNumerique(args[1], "prctile");
    Valeur v = versDouble(args[0]);
    std::vector<double> t(v.re.begin(), v.re.end());
    const Valeur& p = args[1];
    if (p.estScalaire()) return {Valeur::scalaire(quantileDe(t, p.scal() / 100.0))};
    Valeur r = Valeur::matriceDims(p.dims);
    for (std::size_t k = 0; k < p.nelem(); ++k) r.re[k] = quantileDe(t, p.re[k] / 100.0);
    return {r};
}

FONCTION(fnCov) {
    INUTILISE
    exigerArguments(args, 1, 3, "cov");
    if (args.size() >= 2 && args[1].nelem() == args[0].nelem() && !args[1].estScalaire()) {
        std::vector<double> x(args[0].re.begin(), args[0].re.end());
        std::vector<double> y(args[1].re.begin(), args[1].re.end());
        double mx = moyenneDe(x), my = moyenneDe(y);
        double sxy = 0, sxx = 0, syy = 0;
        for (std::size_t k = 0; k < x.size(); ++k) {
            sxy += (x[k] - mx) * (y[k] - my);
            sxx += (x[k] - mx) * (x[k] - mx);
            syy += (y[k] - my) * (y[k] - my);
        }
        double n = (double)x.size() - 1;
        Valeur r = Valeur::matrice(2, 2);
        r.re[0] = sxx / n;
        r.re[1] = sxy / n;
        r.re[2] = sxy / n;
        r.re[3] = syy / n;
        return {r};
    }
    const Valeur& v = args[0];
    if (v.estVecteur()) {
        std::vector<double> t(v.re.begin(), v.re.end());
        return {Valeur::scalaire(varianceDe(t, 0))};
    }
    int l = v.nlignes(), c = v.ncolonnes();
    std::vector<double> moyennes((std::size_t)c, 0.0);
    for (int j = 0; j < c; ++j) {
        double s = 0;
        for (int i = 0; i < l; ++i) s += v.re[(std::size_t)i + (std::size_t)j * l];
        moyennes[(std::size_t)j] = s / l;
    }
    Valeur r = Valeur::matrice(c, c);
    for (int a = 0; a < c; ++a)
        for (int b = 0; b < c; ++b) {
            double s = 0;
            for (int i = 0; i < l; ++i)
                s += (v.re[(std::size_t)i + (std::size_t)a * l] - moyennes[(std::size_t)a]) *
                     (v.re[(std::size_t)i + (std::size_t)b * l] - moyennes[(std::size_t)b]);
            r.re[(std::size_t)a + (std::size_t)b * c] = s / (l - 1);
        }
    return {r};
}

FONCTION(fnCorr) {
    INUTILISE
    exigerArguments(args, 1, 2, "corrcoef");
    std::vector<Valeur> a = args;
    auto cov = fnCov(it, a, 1);
    Valeur c = cov[0];
    int n = c.nlignes();
    Valeur r = c;
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j) {
            double d = std::sqrt(c.re[(std::size_t)i + (std::size_t)i * n] *
                                 c.re[(std::size_t)j + (std::size_t)j * n]);
            r.re[(std::size_t)i + (std::size_t)j * n] =
                d == 0 ? NAN : c.re[(std::size_t)i + (std::size_t)j * n] / d;
        }
    return {r};
}

FONCTION(fnHistcounts) {
    INUTILISE
    exigerArguments(args, 1, 3, "histcounts");
    exigerNumerique(args[0], "histcounts");
    if (args.size() > 1) exigerNumerique(args[1], "histcounts");
    Valeur v = versDouble(args[0]);
    int nbClasses = 10;
    std::vector<double> bords;
    if (args.size() > 1) {
        if (args[1].nelem() == 1) nbClasses = (int)args[1].scal();
        else
            for (std::size_t k = 0; k < args[1].nelem(); ++k) bords.push_back(args[1].re[k]);
    }
    if (bords.empty()) {
        double mn = INFINITY, mx = -INFINITY;
        for (double x : v.re) {
            mn = std::min(mn, x);
            mx = std::max(mx, x);
        }
        if (!std::isfinite(mn)) {
            mn = 0;
            mx = 1;
        }
        if (mn == mx) {
            mn -= 0.5;
            mx += 0.5;
        }
        for (int k = 0; k <= nbClasses; ++k)
            bords.push_back(mn + (mx - mn) * k / nbClasses);
    }
    std::vector<double> compte(bords.size() - 1, 0.0);
    for (double x : v.re) {
        for (std::size_t k = 0; k + 1 < bords.size(); ++k) {
            bool dernier = (k + 2 == bords.size());
            if (x >= bords[k] && (dernier ? x <= bords[k + 1] : x < bords[k + 1])) {
                compte[k] += 1;
                break;
            }
        }
    }
    if (nargout >= 2) return {Valeur::ligne(compte), Valeur::ligne(bords)};
    return {Valeur::ligne(compte)};
}

// ------------------------------------------------------------------ lois

double normpdfFn(double x, double mu, double sigma) {
    double z = (x - mu) / sigma;
    return std::exp(-0.5 * z * z) / (sigma * std::sqrt(2 * PI));
}
double normcdfFn(double x, double mu, double sigma) {
    return 0.5 * std::erfc(-(x - mu) / (sigma * std::sqrt(2.0)));
}

double erfinvLocal(double y) {
    if (y <= -1) return -INFINITY;
    if (y >= 1) return INFINITY;
    double x = 0;
    for (int k = 0; k < 60; ++k) {
        double err = std::erf(x) - y;
        double d = 2.0 / std::sqrt(PI) * std::exp(-x * x);
        if (d == 0) break;
        double pas = err / d;
        x -= pas;
        if (std::fabs(pas) < 1e-15) break;
    }
    return x;
}

FONCTION(fnNormpdf) {
    INUTILISE
    exigerArguments(args, 1, 3, "normpdf");
    double mu = args.size() > 1 ? args[1].scal() : 0.0;
    double sigma = args.size() > 2 ? args[2].scal() : 1.0;
    return {appliquerReel(versDouble(args[0]),
                          [mu, sigma](double x) { return normpdfFn(x, mu, sigma); })};
}
FONCTION(fnNormcdf) {
    INUTILISE
    exigerArguments(args, 1, 3, "normcdf");
    double mu = args.size() > 1 ? args[1].scal() : 0.0;
    double sigma = args.size() > 2 ? args[2].scal() : 1.0;
    return {appliquerReel(versDouble(args[0]),
                          [mu, sigma](double x) { return normcdfFn(x, mu, sigma); })};
}
FONCTION(fnNorminv) {
    INUTILISE
    exigerArguments(args, 1, 3, "norminv");
    double mu = args.size() > 1 ? args[1].scal() : 0.0;
    double sigma = args.size() > 2 ? args[2].scal() : 1.0;
    return {appliquerReel(versDouble(args[0]), [mu, sigma](double p) {
        return mu + sigma * std::sqrt(2.0) * erfinvLocal(2 * p - 1);
    })};
}
FONCTION(fnNormrnd) {
    INUTILISE
    double mu = args.size() > 0 ? args[0].scal() : 0.0;
    double sigma = args.size() > 1 ? args[1].scal() : 1.0;
    Dims d = dimsDepuisArguments(args, 2, args.size());
    if (args.size() <= 2) d = Dims{1, 1};
    Valeur r = Valeur::matriceDims(d);
    std::normal_distribution<double> loi(mu, sigma);
    for (auto& x : r.re) x = loi(it.generateur);
    return {r};
}

FONCTION(fnUnifrnd) {
    INUTILISE
    double a = args.size() > 0 ? args[0].scal() : 0.0;
    double b = args.size() > 1 ? args[1].scal() : 1.0;
    Dims d = dimsDepuisArguments(args, 2, args.size());
    if (args.size() <= 2) d = Dims{1, 1};
    Valeur r = Valeur::matriceDims(d);
    std::uniform_real_distribution<double> loi(a, b);
    for (auto& x : r.re) x = loi(it.generateur);
    return {r};
}

FONCTION(fnExppdf) {
    INUTILISE
    double mu = args.size() > 1 ? args[1].scal() : 1.0;
    return {appliquerReel(versDouble(args[0]), [mu](double x) {
        return x < 0 ? 0.0 : std::exp(-x / mu) / mu;
    })};
}
FONCTION(fnExpcdf) {
    INUTILISE
    double mu = args.size() > 1 ? args[1].scal() : 1.0;
    return {appliquerReel(versDouble(args[0]),
                          [mu](double x) { return x < 0 ? 0.0 : 1.0 - std::exp(-x / mu); })};
}

FONCTION(fnPoisspdf) {
    INUTILISE
    exigerArguments(args, 2, 2, "poisspdf");
    return {diffuser(versDouble(args[0]), versDouble(args[1]),
                     [](double k, double lambda) {
                         if (k < 0) return 0.0;
                         return std::exp(-lambda + k * std::log(lambda) -
                                         std::lgamma(k + 1));
                     },
                     Classe::Double)};
}

FONCTION(fnBinopdf) {
    INUTILISE
    exigerArguments(args, 3, 3, "binopdf");
    double n = args[1].scal(), p = args[2].scal();
    return {appliquerReel(versDouble(args[0]), [n, p](double k) {
        if (k < 0 || k > n) return 0.0;
        double lc = std::lgamma(n + 1) - std::lgamma(k + 1) - std::lgamma(n - k + 1);
        return std::exp(lc + k * std::log(p) + (n - k) * std::log(1 - p));
    })};
}

FONCTION(fnTpdf) {
    INUTILISE
    exigerArguments(args, 2, 2, "tpdf");
    double nu = args[1].scal();
    return {appliquerReel(versDouble(args[0]), [nu](double x) {
        return std::exp(std::lgamma((nu + 1) / 2) - std::lgamma(nu / 2)) /
               std::sqrt(nu * PI) * std::pow(1 + x * x / nu, -(nu + 1) / 2);
    })};
}

FONCTION(fnChi2pdf) {
    INUTILISE
    exigerArguments(args, 2, 2, "chi2pdf");
    double k = args[1].scal();
    return {appliquerReel(versDouble(args[0]), [k](double x) {
        if (x < 0) return 0.0;
        if (x == 0.0) {
            // En zero la densite depend de la forme k/2 : elle diverge
            // en dessous de 1, vaut 1/2 a 1 degre de liberte pres, et
            // s'annule au-dela. Le calcul general y donnerait 0*log(0).
            if (k < 2.0) return (double)INFINITY;
            if (k == 2.0) return 0.5;
            return 0.0;
        }
        return std::exp((k / 2 - 1) * std::log(x) - x / 2 - std::lgamma(k / 2) -
                        (k / 2) * std::log(2.0));
    })};
}

FONCTION(fnRandsample) {
    INUTILISE
    exigerArguments(args, 2, 4, "randsample");
    exigerNumerique(args[0], "randsample");
    exigerNumerique(args[1], "randsample");
    const Valeur& population = args[0];
    int k = (int)args[1].scal();
    std::vector<double> valeurs;
    if (population.nelem() == 1)
        for (int i = 1; i <= (int)population.scal(); ++i) valeurs.push_back(i);
    else
        valeurs.assign(population.re.begin(), population.re.end());
    bool remise = args.size() > 2 && args[2].vrai();
    std::vector<double> sortie;
    if (remise) {
        std::uniform_int_distribution<std::size_t> loi(0, valeurs.size() - 1);
        for (int i = 0; i < k; ++i) sortie.push_back(valeurs[loi(it.generateur)]);
    } else {
        std::shuffle(valeurs.begin(), valeurs.end(), it.generateur);
        for (int i = 0; i < k && i < (int)valeurs.size(); ++i) sortie.push_back(valeurs[(std::size_t)i]);
    }
    return {Valeur::colonne(sortie)};
}

FONCTION(fnMovmean) {
    INUTILISE
    exigerArguments(args, 2, 2, "movmean");
    Valeur v = versDouble(args[0]);
    int f = (int)args[1].scal();
    Valeur r = v;
    int n = (int)v.nelem();
    for (int i = 0; i < n; ++i) {
        int debut = std::max(0, i - (f - 1) / 2);
        int fin = std::min(n - 1, i + f / 2);
        double s = 0;
        for (int k = debut; k <= fin; ++k) s += v.re[(std::size_t)k];
        r.re[(std::size_t)i] = s / (fin - debut + 1);
    }
    return {r};
}

FONCTION(fnNormalize) {
    INUTILISE
    exigerArguments(args, 1, 3, "normalize");
    Valeur v = versDouble(args[0]);
    std::vector<double> t(v.re.begin(), v.re.end());
    double m = moyenneDe(t), s = std::sqrt(varianceDe(t, 0));
    Valeur r = v;
    for (auto& x : r.re) x = s == 0 ? 0 : (x - m) / s;
    return {r};
}

}  // namespace

void enregistrerStatistiques(Interpreteur& it) {
    it.enregistrer("mean", fnMean, "statistiques", "mean  Moyenne arithmetique.");
    it.enregistrer("median", fnMedian, "statistiques", "median  Mediane.");
    it.enregistrer("mode", fnMode, "statistiques", "mode  Valeur la plus frequente.");
    it.enregistrer("var", fnVar, "statistiques", "var  Variance.");
    it.enregistrer("std", fnStd, "statistiques", "std  Ecart type.");
    it.enregistrer("range", fnRange, "statistiques", "range  Etendue.");
    it.enregistrer("quantile", fnQuantile, "statistiques", "quantile  Quantiles empiriques.");
    it.enregistrer("prctile", fnPrctile, "statistiques", "prctile  Centiles empiriques.");
    it.enregistrer("cov", fnCov, "statistiques", "cov  Covariance.");
    it.enregistrer("corrcoef", fnCorr, "statistiques", "corrcoef  Coefficients de correlation.");
    it.enregistrer("histcounts", fnHistcounts, "statistiques", "histcounts  Comptage par classes.");
    it.enregistrer("normpdf", fnNormpdf, "statistiques", "normpdf  Densite normale.");
    it.enregistrer("normcdf", fnNormcdf, "statistiques", "normcdf  Repartition normale.");
    it.enregistrer("norminv", fnNorminv, "statistiques", "norminv  Quantile normal.");
    it.enregistrer("normrnd", fnNormrnd, "statistiques", "normrnd  Tirage normal.");
    it.enregistrer("unifrnd", fnUnifrnd, "statistiques", "unifrnd  Tirage uniforme.");
    it.enregistrer("exppdf", fnExppdf, "statistiques", "exppdf  Densite exponentielle.");
    it.enregistrer("expcdf", fnExpcdf, "statistiques", "expcdf  Repartition exponentielle.");
    it.enregistrer("poisspdf", fnPoisspdf, "statistiques", "poisspdf  Densite de Poisson.");
    it.enregistrer("binopdf", fnBinopdf, "statistiques", "binopdf  Densite binomiale.");
    it.enregistrer("tpdf", fnTpdf, "statistiques", "tpdf  Densite de Student.");
    it.enregistrer("chi2pdf", fnChi2pdf, "statistiques", "chi2pdf  Densite du khi-deux.");
    it.enregistrer("randsample", fnRandsample, "statistiques", "randsample  Tirage dans un ensemble.");
    it.enregistrer("movmean", fnMovmean, "statistiques", "movmean  Moyenne glissante.");
    it.enregistrer("normalize", fnNormalize, "statistiques", "normalize  Centrage et reduction.");
}

}  // namespace matlibre
