// Statistiques.cpp — statistiques descriptives et lois usuelles.
#include <algorithm>
#include <cctype>
#include <limits>
#include <cmath>
#include <functional>
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

double varianceDe(const std::vector<double>& t, int normalisation);

double medianeDe(std::vector<double> t) {
    if (t.empty()) return NAN;
    std::sort(t.begin(), t.end());
    std::size_t n = t.size();
    return (n % 2) ? t[n / 2] : 0.5 * (t[n / 2 - 1] + t[n / 2]);
}

// « reduire » ne parcourt que la partie reelle : une valeur complexe y
// perdait son imaginaire en silence, et « mean([1+2i 3+4i]) » rendait 2
// au lieu de 2+3i. Ces deux passerelles rendent la reduction complete.
//
// La premiere applique la meme reduction aux deux parties et recolle ;
// la seconde donne les deux parties d'une meme tranche a la fonction,
// pour ce qui les melange — la variance, la mediane.
Valeur reduireDeuxParties(const Valeur& v, int dimension,
                          const std::function<double(const std::vector<double>&)>& f) {
    Valeur reelle = reduire(v, dimension, false, f);
    if (!v.estComplexe()) return reelle;
    Valeur imaginaire = v;
    imaginaire.re = v.im;
    imaginaire.im.clear();
    Valeur partie = reduire(imaginaire, dimension, false, f);
    reelle.assurerImaginaire();
    for (std::size_t k = 0; k < reelle.im.size() && k < partie.re.size(); ++k)
        reelle.im[k] = partie.re[k];
    return reelle;
}

Valeur reduirePaires(
    const Valeur& v, int dimension,
    const std::function<double(const std::vector<double>&, const std::vector<double>&)>& f) {
    Dims d = v.dims;
    while ((int)d.size() <= dimension) d.push_back(1);
    Dims rd = d;
    rd[(std::size_t)dimension] = 1;
    Valeur r = Valeur::matriceDims(rd);
    r.normaliserDims();
    std::vector<std::vector<double>> tranchesImaginaires;
    if (v.estComplexe()) {
        Valeur imaginaire = v;
        imaginaire.re = v.im;
        imaginaire.im.clear();
        parcourirTranches(imaginaire, dimension,
                          [&](std::vector<double>& t, std::size_t k) {
                              if (tranchesImaginaires.size() <= k)
                                  tranchesImaginaires.resize(k + 1);
                              tranchesImaginaires[k] = t;
                          });
    }
    parcourirTranches(v, dimension, [&](std::vector<double>& t, std::size_t k) {
        std::vector<double> zeros(t.size(), 0.0);
        if (k < r.re.size())
            r.re[k] = f(t, k < tranchesImaginaires.size() ? tranchesImaginaires[k] : zeros);
    });
    return r;
}

// Les paires (reel, imaginaire) privees de celles ou l'un des deux est
// NaN : c'est ce que veut dire « omitnan » pour une valeur complexe.
void sansNaNPaires(std::vector<double>& re, std::vector<double>& im) {
    std::vector<double> gr, gi;
    for (std::size_t k = 0; k < re.size(); ++k) {
        double partieIm = k < im.size() ? im[k] : 0.0;
        if (std::isnan(re[k]) || std::isnan(partieIm)) continue;
        gr.push_back(re[k]);
        gi.push_back(partieIm);
    }
    re = gr;
    im = gi;
}

// La variance d'un echantillon complexe : la moyenne des carres des
// modules des ecarts, c'est-a-dire la somme des variances des deux
// parties. Elle est reelle, comme dans MATLAB.
double varianceComplexeDe(std::vector<double> re, std::vector<double> im, int normalisation,
                          bool omettre) {
    if (omettre) sansNaNPaires(re, im);
    if (re.size() < 2) return normalisation == 1 ? 0.0 : (re.empty() ? NAN : 0.0);
    bool complexe = false;
    for (double x : im)
        if (x != 0.0) complexe = true;
    double v = varianceDe(re, normalisation);
    if (complexe) v += varianceDe(im, normalisation);
    return v;
}

// La mediane d'un echantillon complexe : on classe par module, puis par
// argument, comme le fait le « sort » de MATLAB, et l'on rend la partie
// demandee du terme du milieu — la demi-somme des deux, en nombre pair.
double medianeComplexe(std::vector<double> re, std::vector<double> im, bool omettre,
                       bool partieReelle) {
    if (omettre) sansNaNPaires(re, im);
    if (re.empty()) return NAN;
    std::vector<std::size_t> ordre(re.size());
    for (std::size_t k = 0; k < ordre.size(); ++k) ordre[k] = k;
    std::sort(ordre.begin(), ordre.end(), [&](std::size_t a, std::size_t b) {
        double ma = std::hypot(re[a], im.size() > a ? im[a] : 0.0);
        double mb = std::hypot(re[b], im.size() > b ? im[b] : 0.0);
        if (ma != mb) return ma < mb;
        return std::atan2(im.size() > a ? im[a] : 0.0, re[a]) <
               std::atan2(im.size() > b ? im[b] : 0.0, re[b]);
    });
    auto partie = [&](std::size_t k) {
        std::size_t i = ordre[k];
        return partieReelle ? re[i] : (im.size() > i ? im[i] : 0.0);
    };
    std::size_t n = ordre.size();
    return (n % 2) ? partie(n / 2) : 0.5 * (partie(n / 2 - 1) + partie(n / 2));
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
    bool omettre = optionOmettreNaN(args);
    exigerArguments(args, 1, 3, "mean");
    Valeur v = versDouble(args[0]);
    if (v.estVide()) return {Valeur::scalaire(NAN)};
    if (optionToutesDimensions(args)) v = aplatirColonne(v);
    int dim = dimensionChoisie(args, 1, v);
    return {reduireDeuxParties(v, dim, [omettre](const std::vector<double>& t) {
        return moyenneDe(omettre ? sansNaN(t) : t);
    })};
}

FONCTION(fnMedian) {
    INUTILISE
    bool omettre = optionOmettreNaN(args);
    exigerArguments(args, 1, 3, "median");
    Valeur v = versDouble(args[0]);
    if (v.estVide()) return {Valeur::scalaire(NAN)};
    if (optionToutesDimensions(args)) v = aplatirColonne(v);
    int dim = dimensionChoisie(args, 1, v);
    if (!v.estComplexe())
        return {reduire(v, dim, false, [omettre](const std::vector<double>& t) {
            return medianeDe(omettre ? sansNaN(t) : t);
        })};
    // MATLAB classe les complexes par module, puis par argument : la
    // mediane d'un echantillon complexe suit ce meme ordre.
    Valeur partieReelle = reduirePaires(
        v, dim, [omettre](const std::vector<double>& re, const std::vector<double>& im) {
            return medianeComplexe(re, im, omettre, true);
        });
    Valeur partieImaginaire = reduirePaires(
        v, dim, [omettre](const std::vector<double>& re, const std::vector<double>& im) {
            return medianeComplexe(re, im, omettre, false);
        });
    partieReelle.assurerImaginaire();
    for (std::size_t k = 0; k < partieReelle.im.size() && k < partieImaginaire.re.size(); ++k)
        partieReelle.im[k] = partieImaginaire.re[k];
    return {partieReelle};
}

FONCTION(fnMode) {
    INUTILISE
    optionOmettreNaN(args);
    exigerArguments(args, 1, 2, "mode");
    Valeur v = versDouble(args[0]);
    int dim = dimensionChoisie(args, 1, v);
    // MODE écarte toujours les NaN, avec ou sans option : ils ne sont
    // égaux à rien, pas même à eux-mêmes, donc ne peuvent dominer.
    return {reduire(v, dim, false, [](const std::vector<double>& brut) {
        std::vector<double> t = sansNaN(brut);
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
    bool omettre = optionOmettreNaN(args);
    exigerArguments(args, 1, 3, "var");
    Valeur v = versDouble(args[0]);
    int normalisation = args.size() > 1 && !args[1].estVide() ? (int)args[1].scal() : 0;
    int dim = args.size() > 2 ? (int)args[2].scal() - 1 : dimensionParDefaut(v);
    if (v.estVecteur() && args.size() <= 2) dim = dimensionParDefaut(v);
    return {reduirePaires(v, dim,
                          [normalisation, omettre](const std::vector<double>& re,
                                                   const std::vector<double>& im) {
                              return varianceComplexeDe(re, im, normalisation, omettre);
                          })};
}

FONCTION(fnStd) {
    INUTILISE
    bool omettre = optionOmettreNaN(args);
    exigerArguments(args, 1, 3, "std");
    Valeur v = versDouble(args[0]);
    int normalisation = args.size() > 1 && !args[1].estVide() ? (int)args[1].scal() : 0;
    int dim = args.size() > 2 ? (int)args[2].scal() - 1 : dimensionParDefaut(v);
    return {reduirePaires(v, dim,
                          [normalisation, omettre](const std::vector<double>& re,
                                                   const std::vector<double>& im) {
                              return std::sqrt(varianceComplexeDe(re, im, normalisation, omettre));
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

// ---------------------------------------------------- fonctions glissantes

// Les huit fonctions « mov… » ne different que par ce qu'elles font
// d'une fenetre ; tout le reste — la largeur, la dimension, les bords,
// les NaN — leur est commun.
enum class Glisse { Moyenne, Mediane, Somme, Produit, Maximum, Minimum, EcartType, Variance };

double agregerFenetre(Glisse g, std::vector<double>& f) {
    if (f.empty()) {
        switch (g) {
            case Glisse::Somme: return 0;
            case Glisse::Produit: return 1;
            default: return std::numeric_limits<double>::quiet_NaN();
        }
    }
    switch (g) {
        case Glisse::Moyenne: return moyenneDe(f);
        case Glisse::Mediane: {
            std::sort(f.begin(), f.end());
            std::size_t n = f.size();
            return n % 2 ? f[n / 2] : 0.5 * (f[n / 2 - 1] + f[n / 2]);
        }
        case Glisse::Somme: return std::accumulate(f.begin(), f.end(), 0.0);
        case Glisse::Produit: {
            double p = 1;
            for (double x : f) p *= x;
            return p;
        }
        case Glisse::Maximum: return *std::max_element(f.begin(), f.end());
        case Glisse::Minimum: return *std::min_element(f.begin(), f.end());
        case Glisse::EcartType: return std::sqrt(varianceDe(f, 0));
        case Glisse::Variance: return varianceDe(f, 0);
    }
    return std::numeric_limits<double>::quiet_NaN();
}

// « Endpoints » dit ce qu'on fait la ou la fenetre deborde : la
// retrecir (defaut), ne rendre que les fenetres pleines, ou completer
// le tableau par NaN ou par une valeur donnee.
enum class Bords { Retrecir, Jeter, Completer };

std::string enMinuscules(std::string s) {
    for (char& c : s) c = (char)std::tolower((unsigned char)c);
    return s;
}

std::vector<Valeur> glissante(Arguments args, const char* nom, Glisse g) {
    exigerArguments(args, 2, 8, nom);
    std::vector<Valeur>& liste = args;
    bool omettre = optionOmettreNaN(liste);
    Bords bords = Bords::Retrecir;
    double remplissage = std::numeric_limits<double>::quiet_NaN();
    for (std::size_t k = 2; k + 1 < liste.size();) {
        if ((liste[k].estTexte() || liste[k].estChaine()) &&
            enMinuscules(liste[k].versTexte()) == "endpoints") {
            const Valeur& mode = liste[k + 1];
            if (mode.estTexte() || mode.estChaine()) {
                std::string m = enMinuscules(mode.versTexte());
                if (m == "shrink") bords = Bords::Retrecir;
                else if (m == "discard") bords = Bords::Jeter;
                else if (m == "fill") bords = Bords::Completer;
                else erreur("MATLAB:movfun:badEndpoints",
                            std::string(nom) + " : bord inconnu « " + m + " ».");
            } else {
                bords = Bords::Completer;
                remplissage = mode.scal();
            }
            liste.erase(liste.begin() + (std::ptrdiff_t)k,
                        liste.begin() + (std::ptrdiff_t)k + 2);
        } else {
            ++k;
        }
    }
    exigerNumerique(liste[0], nom);
    Valeur v = versDouble(liste[0]);
    exigerNumerique(liste[1], nom);
    const Valeur& fenetre = liste[1];
    long avant = 0, apres = 0;
    if (fenetre.nelem() == 1) {
        long k = (long)fenetre.scal();
        if (k < 1) erreur("MATLAB:movfun:badWindow",
                          std::string(nom) + " : la fenetre doit valoir au moins 1.");
        // Fenetre impaire : centree. Fenetre paire : elle penche du cote
        // du passe, comme dans MATLAB.
        avant = k % 2 ? (k - 1) / 2 : k / 2;
        apres = k % 2 ? (k - 1) / 2 : k / 2 - 1;
    } else if (fenetre.nelem() == 2) {
        avant = (long)fenetre.re[0];
        apres = (long)fenetre.re[1];
        if (avant < 0 || apres < 0)
            erreur("MATLAB:movfun:badWindow",
                   std::string(nom) + " : les deux largeurs doivent etre positives.");
    } else {
        erreur("MATLAB:movfun:badWindow",
               std::string(nom) + " : la fenetre est un scalaire ou deux largeurs.");
    }
    int dimension = liste.size() > 2 ? (int)liste[2].scal() - 1 : dimensionParDefaut(v);
    exigerDimension(dimension);

    Dims d = v.dims;
    while ((int)d.size() <= dimension) d.push_back(1);
    std::size_t interne = 1;
    for (int k = 0; k < dimension; ++k) interne *= (std::size_t)d[(std::size_t)k];
    long taille = (long)d[(std::size_t)dimension];
    std::size_t externe = taille ? v.nelem() / (interne * (std::size_t)taille) : 0;
    long premier = 0, dernier = taille - 1;
    if (bords == Bords::Jeter) {
        premier = avant;
        dernier = taille - 1 - apres;
        if (dernier < premier) { premier = 0; dernier = -1; }
    }
    long garde = dernier - premier + 1;
    if (garde < 0) garde = 0;
    Dims rd = d;
    rd[(std::size_t)dimension] = (int)garde;
    Valeur r = Valeur::matriceDims(rd);
    r.normaliserDims();
    std::vector<double> f;
    for (std::size_t a = 0; a < externe; ++a) {
        for (std::size_t b = 0; b < interne; ++b) {
            std::size_t base = a * interne * (std::size_t)taille + b;
            std::size_t baseSortie = a * interne * (std::size_t)garde + b;
            for (long i = premier; i <= dernier; ++i) {
                f.clear();
                bool deborde = false;
                for (long j = i - avant; j <= i + apres; ++j) {
                    if (j < 0 || j >= taille) { deborde = true; continue; }
                    f.push_back(v.re[base + (std::size_t)j * interne]);
                }
                if (deborde && bords == Bords::Completer) {
                    long manquants = (avant + apres + 1) - (long)f.size();
                    for (long j = 0; j < manquants; ++j) f.push_back(remplissage);
                }
                if (omettre) f = sansNaN(f);
                std::size_t position = baseSortie + (std::size_t)(i - premier) * interne;
                if (position < r.re.size()) r.re[position] = agregerFenetre(g, f);
            }
        }
    }
    return {r};
}

FONCTION(fnMovmean) {
    INUTILISE
    return glissante(args, "movmean", Glisse::Moyenne);
}
FONCTION(fnMovmedian) {
    INUTILISE
    return glissante(args, "movmedian", Glisse::Mediane);
}
FONCTION(fnMovsum) {
    INUTILISE
    return glissante(args, "movsum", Glisse::Somme);
}
FONCTION(fnMovprod) {
    INUTILISE
    return glissante(args, "movprod", Glisse::Produit);
}
FONCTION(fnMovmax) {
    INUTILISE
    return glissante(args, "movmax", Glisse::Maximum);
}
FONCTION(fnMovmin) {
    INUTILISE
    return glissante(args, "movmin", Glisse::Minimum);
}
FONCTION(fnMovstd) {
    INUTILISE
    return glissante(args, "movstd", Glisse::EcartType);
}
FONCTION(fnMovvar) {
    INUTILISE
    return glissante(args, "movvar", Glisse::Variance);
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
    it.enregistrer("movmedian", fnMovmedian, "statistiques", "movmedian  Mediane glissante.");
    it.enregistrer("movsum", fnMovsum, "statistiques", "movsum  Somme glissante.");
    it.enregistrer("movprod", fnMovprod, "statistiques", "movprod  Produit glissant.");
    it.enregistrer("movmax", fnMovmax, "statistiques", "movmax  Maximum glissant.");
    it.enregistrer("movmin", fnMovmin, "statistiques", "movmin  Minimum glissant.");
    it.enregistrer("movstd", fnMovstd, "statistiques", "movstd  Ecart type glissant.");
    it.enregistrer("movvar", fnMovvar, "statistiques", "movvar  Variance glissante.");
    it.enregistrer("normalize", fnNormalize, "statistiques", "normalize  Centrage et reduction.");
}

}  // namespace matlibre
