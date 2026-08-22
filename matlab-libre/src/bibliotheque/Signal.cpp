// Signal.cpp — transformée de Fourier, convolution, filtrage, fenêtres.
//
// La FFT est écrite ici : radix-2 quand la longueur est une puissance de
// deux, algorithme de Bluestein sinon — donc exacte pour toute longueur,
// sans dépendance à FFTW.
#include <algorithm>
#include <cmath>
#include <complex>
#include <vector>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {

using cplx = std::complex<double>;
static const double PI = 3.14159265358979323846;

// FFT itérative de Cooley-Tukey, longueur puissance de deux.
static void fftPuissanceDeux(std::vector<cplx>& a, bool inverse) {
    std::size_t n = a.size();
    for (std::size_t i = 1, j = 0; i < n; ++i) {
        std::size_t bit = n >> 1;
        for (; j & bit; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) std::swap(a[i], a[j]);
    }
    for (std::size_t longueur = 2; longueur <= n; longueur <<= 1) {
        double angle = 2 * PI / (double)longueur * (inverse ? 1 : -1);
        cplx pas(std::cos(angle), std::sin(angle));
        for (std::size_t i = 0; i < n; i += longueur) {
            cplx w(1);
            for (std::size_t j = 0; j < longueur / 2; ++j) {
                cplx u = a[i + j];
                cplx v = a[i + j + longueur / 2] * w;
                a[i + j] = u + v;
                a[i + j + longueur / 2] = u - v;
                w *= pas;
            }
        }
    }
    if (inverse)
        for (auto& x : a) x /= (double)n;
}

// Bluestein : ramène une longueur quelconque à une convolution.
void transformeeFourier(std::vector<cplx>& a, bool inverse) {
    std::size_t n = a.size();
    if (n <= 1) return;
    if ((n & (n - 1)) == 0) {
        fftPuissanceDeux(a, inverse);
        return;
    }
    std::size_t m = 1;
    while (m < 2 * n + 1) m <<= 1;
    std::vector<cplx> an(m, cplx(0)), bn(m, cplx(0));
    double signe = inverse ? 1.0 : -1.0;
    for (std::size_t k = 0; k < n; ++k) {
        double angle = signe * PI * (double)((k * k) % (2 * n)) / (double)n;
        cplx w(std::cos(angle), std::sin(angle));
        an[k] = a[k] * w;
        bn[k] = std::conj(w);
        if (k) bn[m - k] = std::conj(w);
    }
    fftPuissanceDeux(an, false);
    fftPuissanceDeux(bn, false);
    for (std::size_t k = 0; k < m; ++k) an[k] *= bn[k];
    fftPuissanceDeux(an, true);
    for (std::size_t k = 0; k < n; ++k) {
        double angle = signe * PI * (double)((k * k) % (2 * n)) / (double)n;
        cplx w(std::cos(angle), std::sin(angle));
        a[k] = an[k] * w;
        if (inverse) a[k] /= (double)n;
    }
}

namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, std::vector<Valeur>& args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

std::vector<cplx> versVecteurComplexe(const Valeur& v) {
    std::vector<cplx> a(v.nelem());
    for (std::size_t k = 0; k < a.size(); ++k)
        a[k] = cplx(v.re.empty() ? 0 : v.re[k], v.im.empty() ? 0 : v.im[k]);
    return a;
}

Valeur depuisVecteurComplexe(const std::vector<cplx>& a, bool colonne) {
    Valeur r;
    r.dims = colonne ? Dims{(int)a.size(), 1} : Dims{1, (int)a.size()};
    r.re.resize(a.size());
    r.im.resize(a.size());
    for (std::size_t k = 0; k < a.size(); ++k) {
        r.re[k] = a[k].real();
        r.im[k] = a[k].imag();
    }
    r.compacter();
    return r;
}

Valeur fftColonnes(const Valeur& v, std::size_t n, bool inverse, int dim) {
    Valeur source = versDouble(v);
    if (source.estVecteur() || source.estScalaire()) {
        std::vector<cplx> a = versVecteurComplexe(source);
        if (n == 0) n = a.size();
        a.resize(n, cplx(0));
        transformeeFourier(a, inverse);
        return depuisVecteurComplexe(a, source.estColonne());
    }
    Dims d = source.dims;
    while ((int)d.size() <= dim) d.push_back(1);
    std::size_t taille = (std::size_t)d[(std::size_t)dim];
    if (n == 0) n = taille;
    Dims rd = d;
    rd[(std::size_t)dim] = (int)n;
    Valeur r = Valeur::matriceDims(rd);
    r.assurerImaginaire();
    std::size_t interne = 1;
    for (int k = 0; k < dim; ++k) interne *= (std::size_t)d[(std::size_t)k];
    std::size_t externe = taille ? source.nelem() / (interne * taille) : 0;
    for (std::size_t a2 = 0; a2 < externe; ++a2)
        for (std::size_t b = 0; b < interne; ++b) {
            std::vector<cplx> colonne(n, cplx(0));
            for (std::size_t i = 0; i < taille && i < n; ++i) {
                std::size_t p = a2 * interne * taille + b + i * interne;
                colonne[i] = cplx(source.re[p], source.im.empty() ? 0 : source.im[p]);
            }
            transformeeFourier(colonne, inverse);
            for (std::size_t i = 0; i < n; ++i) {
                std::size_t p = a2 * interne * n + b + i * interne;
                r.re[p] = colonne[i].real();
                r.im[p] = colonne[i].imag();
            }
        }
    r.compacter();
    return r;
}

FONCTION(fnFft) {
    INUTILISE
    exigerArguments(args, 1, 3, "fft");
    std::size_t n = args.size() > 1 && !args[1].estVide() ? (std::size_t)args[1].scal() : 0;
    int dim = args.size() > 2 ? (int)args[2].scal() - 1 : dimensionParDefaut(args[0]);
    return {fftColonnes(args[0], n, false, dim)};
}

FONCTION(fnIfft) {
    INUTILISE
    exigerArguments(args, 1, 3, "ifft");
    std::size_t n = args.size() > 1 && !args[1].estVide() ? (std::size_t)args[1].scal() : 0;
    int dim = args.size() > 2 ? (int)args[2].scal() - 1 : dimensionParDefaut(args[0]);
    Valeur r = fftColonnes(args[0], n, true, dim);
    // ifft d'un signal à symétrie hermitienne est réel : on nettoie le bruit.
    if (r.estComplexe()) {
        double maxIm = 0, maxRe = 0;
        for (std::size_t k = 0; k < r.nelem(); ++k) {
            maxIm = std::max(maxIm, std::fabs(r.im[k]));
            maxRe = std::max(maxRe, std::fabs(r.re[k]));
        }
        if (maxIm <= 1e-12 * std::max(maxRe, 1.0)) r.im.clear();
    }
    return {r};
}

FONCTION(fnFft2) {
    INUTILISE
    exigerArguments(args, 1, 3, "fft2");
    Valeur r = fftColonnes(args[0], 0, false, 0);
    return {fftColonnes(r, 0, false, 1)};
}
FONCTION(fnIfft2) {
    INUTILISE
    Valeur r = fftColonnes(args[0], 0, true, 0);
    return {fftColonnes(r, 0, true, 1)};
}

Valeur decalage(const Valeur& v, bool inverse) {
    Valeur r = v;
    std::size_t n = v.nelem();
    if (v.estVecteur() || v.estScalaire()) {
        std::size_t moitie = inverse ? n / 2 : (n + 1) / 2;
        for (std::size_t k = 0; k < n; ++k) {
            std::size_t src = (k + moitie) % n;
            r.re[k] = v.re[src];
            if (!v.im.empty()) r.im[k] = v.im[src];
        }
        return r;
    }
    int l = v.nlignes(), c = v.ncolonnes();
    int dl = inverse ? l / 2 : (l + 1) / 2;
    int dc = inverse ? c / 2 : (c + 1) / 2;
    for (int i = 0; i < l; ++i)
        for (int j = 0; j < c; ++j) {
            std::size_t src = (std::size_t)((i + dl) % l) + (std::size_t)((j + dc) % c) * l;
            std::size_t dst = (std::size_t)i + (std::size_t)j * l;
            r.re[dst] = v.re[src];
            if (!v.im.empty()) r.im[dst] = v.im[src];
        }
    return r;
}

FONCTION(fnFftshift) { INUTILISE return {decalage(args[0], false)}; }
FONCTION(fnIfftshift) { INUTILISE return {decalage(args[0], true)}; }

FONCTION(fnConv) {
    INUTILISE
    exigerArguments(args, 2, 3, "conv");
    const Valeur& a = versDouble(args[0]);
    const Valeur& b = versDouble(args[1]);
    std::size_t na = a.nelem(), nb = b.nelem();
    if (na == 0 || nb == 0) return {Valeur::matrice(1, 0)};
    std::vector<double> r(na + nb - 1, 0.0);
    for (std::size_t i = 0; i < na; ++i)
        for (std::size_t j = 0; j < nb; ++j) r[i + j] += a.re[i] * b.re[j];
    std::string forme = args.size() > 2 ? args[2].versTexte() : "full";
    if (forme == "same") {
        std::size_t debut = (nb - 1) / 2;
        std::vector<double> s(r.begin() + (long)debut, r.begin() + (long)(debut + na));
        r = s;
    } else if (forme == "valid") {
        if (na >= nb) {
            std::vector<double> s(r.begin() + (long)(nb - 1), r.begin() + (long)na);
            r = s;
        } else {
            r.clear();
        }
    }
    bool colonne = a.estColonne() && !a.estScalaire();
    return {colonne ? Valeur::colonne(r) : Valeur::ligne(r)};
}

FONCTION(fnConv2) {
    INUTILISE
    exigerArguments(args, 2, 3, "conv2");
    const Valeur& a = versDouble(args[0]);
    const Valeur& b = versDouble(args[1]);
    int la = a.nlignes(), ca = a.ncolonnes(), lb = b.nlignes(), cb = b.ncolonnes();
    int lr = la + lb - 1, cr = ca + cb - 1;
    Valeur plein = Valeur::matrice(lr, cr);
    for (int i = 0; i < la; ++i)
        for (int j = 0; j < ca; ++j) {
            double x = a.re[(std::size_t)i + (std::size_t)j * la];
            if (x == 0) continue;
            for (int p = 0; p < lb; ++p)
                for (int q = 0; q < cb; ++q)
                    plein.re[(std::size_t)(i + p) + (std::size_t)(j + q) * lr] +=
                        x * b.re[(std::size_t)p + (std::size_t)q * lb];
        }
    std::string forme = args.size() > 2 ? args[2].versTexte() : "full";
    if (forme == "same") {
        Valeur r = Valeur::matrice(la, ca);
        int di = (lb - 1) / 2, dj = (cb - 1) / 2;
        for (int i = 0; i < la; ++i)
            for (int j = 0; j < ca; ++j)
                r.re[(std::size_t)i + (std::size_t)j * la] =
                    plein.re[(std::size_t)(i + di) + (std::size_t)(j + dj) * lr];
        return {r};
    }
    return {plein};
}

FONCTION(fnFilter) {
    INUTILISE
    exigerArguments(args, 3, 4, "filter");
    const Valeur& b = versDouble(args[0]);
    const Valeur& a = versDouble(args[1]);
    const Valeur& x = versDouble(args[2]);
    if (a.nelem() == 0 || a.re[0] == 0)
        erreur("MATLAB:filter:zeroLeadingCoefficient",
               "First denominator filter coefficient must be non-zero.");
    double a0 = a.re[0];
    std::size_t n = x.nelem();
    std::vector<double> y(n, 0.0);
    for (std::size_t i = 0; i < n; ++i) {
        double s = 0;
        for (std::size_t k = 0; k < b.nelem(); ++k)
            if (i >= k) s += b.re[k] * x.re[i - k];
        for (std::size_t k = 1; k < a.nelem(); ++k)
            if (i >= k) s -= a.re[k] * y[i - k];
        y[i] = s / a0;
    }
    return {x.estColonne() && !x.estScalaire() ? Valeur::colonne(y) : Valeur::ligne(y)};
}

FONCTION(fnFiltfilt) {
    INUTILISE
    exigerArguments(args, 3, 3, "filtfilt");
    std::vector<Valeur> a1 = args;
    auto aller = fnFilter(it, a1, 1);
    Valeur inverse = aller[0];
    std::reverse(inverse.re.begin(), inverse.re.end());
    std::vector<Valeur> a2 = {args[0], args[1], inverse};
    auto retour = fnFilter(it, a2, 1);
    Valeur r = retour[0];
    std::reverse(r.re.begin(), r.re.end());
    return {r};
}

FONCTION(fnXcorr) {
    INUTILISE
    exigerArguments(args, 1, 3, "xcorr");
    const Valeur& x = versDouble(args[0]);
    const Valeur& y = args.size() > 1 && args[1].nelem() > 1 ? versDouble(args[1]) : x;
    int n = (int)x.nelem(), m = (int)y.nelem();
    int maxDecalage = std::max(n, m) - 1;
    std::vector<double> r;
    for (int d = -maxDecalage; d <= maxDecalage; ++d) {
        double s = 0;
        for (int i = 0; i < n; ++i) {
            int j = i - d;
            if (j >= 0 && j < m) s += x.re[(std::size_t)i] * y.re[(std::size_t)j];
        }
        r.push_back(s);
    }
    std::vector<double> decalages;
    for (int d = -maxDecalage; d <= maxDecalage; ++d) decalages.push_back(d);
    if (nargout >= 2) return {Valeur::ligne(r), Valeur::ligne(decalages)};
    return {Valeur::ligne(r)};
}

Valeur fenetre(int n, int genre) {
    Valeur w = Valeur::matrice(n, 1);
    for (int k = 0; k < n; ++k) {
        double x = (n == 1) ? 0.0 : (double)k / (double)(n - 1);
        double v = 1.0;
        switch (genre) {
            case 0: v = 0.54 - 0.46 * std::cos(2 * PI * x); break;                  // hamming
            case 1: v = 0.5 - 0.5 * std::cos(2 * PI * x); break;                    // hann
            case 2:
                v = 0.42 - 0.5 * std::cos(2 * PI * x) + 0.08 * std::cos(4 * PI * x);
                break;                                                              // blackman
            case 3: v = 1.0 - std::fabs(2 * x - 1); break;                          // bartlett
            default: v = 1.0; break;                                                // rect
        }
        w.re[(std::size_t)k] = v;
    }
    return w;
}

FONCTION(fnHamming) {
    INUTILISE
    return {fenetre((int)argScalaire(args, 0, "hamming"), 0)};
}
FONCTION(fnHann) {
    INUTILISE
    return {fenetre((int)argScalaire(args, 0, "hann"), 1)};
}
FONCTION(fnBlackman) {
    INUTILISE
    return {fenetre((int)argScalaire(args, 0, "blackman"), 2)};
}
FONCTION(fnBartlett) {
    INUTILISE
    return {fenetre((int)argScalaire(args, 0, "bartlett"), 3)};
}
FONCTION(fnRectwin) {
    INUTILISE
    return {fenetre((int)argScalaire(args, 0, "rectwin"), 4)};
}

FONCTION(fnUnwrap) {
    INUTILISE
    exigerArguments(args, 1, 2, "unwrap");
    Valeur v = versDouble(args[0]);
    double tol = args.size() > 1 ? args[1].scal() : PI;
    Valeur r = v;
    double correction = 0;
    for (std::size_t k = 1; k < r.nelem(); ++k) {
        double d = v.re[k] - v.re[k - 1];
        if (d > tol) correction -= 2 * PI;
        else if (d < -tol) correction += 2 * PI;
        r.re[k] = v.re[k] + correction;
    }
    return {r};
}

FONCTION(fnFreqz) {
    INUTILISE
    exigerArguments(args, 2, 3, "freqz");
    const Valeur& b = versDouble(args[0]);
    const Valeur& a = versDouble(args[1]);
    int n = args.size() > 2 ? (int)args[2].scal() : 512;
    Valeur h;
    h.dims = {n, 1};
    h.re.resize((std::size_t)n);
    h.im.resize((std::size_t)n);
    std::vector<double> w((std::size_t)n);
    for (int k = 0; k < n; ++k) {
        double omega = PI * k / n;
        cplx num(0), den(0);
        for (std::size_t i = 0; i < b.nelem(); ++i)
            num += b.re[i] * std::exp(cplx(0, -omega * (double)i));
        for (std::size_t i = 0; i < a.nelem(); ++i)
            den += a.re[i] * std::exp(cplx(0, -omega * (double)i));
        cplx z = num / den;
        h.re[(std::size_t)k] = z.real();
        h.im[(std::size_t)k] = z.imag();
        w[(std::size_t)k] = omega;
    }
    if (nargout >= 2) return {h, Valeur::colonne(w)};
    return {h};
}

FONCTION(fnDownsample) {
    INUTILISE
    exigerArguments(args, 2, 3, "downsample");
    const Valeur& v = args[0];
    int n = (int)args[1].scal();
    int decalage = args.size() > 2 ? (int)args[2].scal() : 0;
    std::vector<double> r;
    for (std::size_t k = (std::size_t)decalage; k < v.nelem(); k += (std::size_t)n)
        r.push_back(v.re[k]);
    return {v.estColonne() ? Valeur::colonne(r) : Valeur::ligne(r)};
}

FONCTION(fnUpsample) {
    INUTILISE
    exigerArguments(args, 2, 3, "upsample");
    const Valeur& v = args[0];
    int n = (int)args[1].scal();
    std::vector<double> r(v.nelem() * (std::size_t)n, 0.0);
    for (std::size_t k = 0; k < v.nelem(); ++k) r[k * (std::size_t)n] = v.re[k];
    return {v.estColonne() ? Valeur::colonne(r) : Valeur::ligne(r)};
}

}  // namespace

void enregistrerSignal(Interpreteur& it) {
    it.enregistrer("fft", fnFft, "signal", "fft  Transformee de Fourier discrete.");
    it.enregistrer("ifft", fnIfft, "signal", "ifft  Transformee inverse.");
    it.enregistrer("fft2", fnFft2, "signal", "fft2  Transformee 2-D.");
    it.enregistrer("ifft2", fnIfft2, "signal", "ifft2  Transformee 2-D inverse.");
    it.enregistrer("fftshift", fnFftshift, "signal", "fftshift  Recentre le spectre.");
    it.enregistrer("ifftshift", fnIfftshift, "signal", "ifftshift  Annule fftshift.");
    it.enregistrer("conv", fnConv, "signal", "conv  Convolution de deux vecteurs.");
    it.enregistrer("conv2", fnConv2, "signal", "conv2  Convolution 2-D.");
    it.enregistrer("filter", fnFilter, "signal", "filter  Filtre rationnel a reponse causale.");
    it.enregistrer("filtfilt", fnFiltfilt, "signal", "filtfilt  Filtrage aller-retour.");
    it.enregistrer("xcorr", fnXcorr, "signal", "xcorr  Correlation croisee.");
    it.enregistrer("hamming", fnHamming, "signal", "hamming  Fenetre de Hamming.");
    it.enregistrer("hann", fnHann, "signal", "hann  Fenetre de Hann.");
    it.enregistrer("hanning", fnHann, "signal", "hanning  Fenetre de Hann.");
    it.enregistrer("blackman", fnBlackman, "signal", "blackman  Fenetre de Blackman.");
    it.enregistrer("bartlett", fnBartlett, "signal", "bartlett  Fenetre triangulaire.");
    it.enregistrer("rectwin", fnRectwin, "signal", "rectwin  Fenetre rectangulaire.");
    it.enregistrer("unwrap", fnUnwrap, "signal", "unwrap  Deroule la phase.");
    it.enregistrer("freqz", fnFreqz, "signal", "freqz  Reponse en frequence.");
    it.enregistrer("downsample", fnDownsample, "signal", "downsample  Decimation.");
    it.enregistrer("upsample", fnUpsample, "signal", "upsample  Sur-echantillonnage.");
}

}  // namespace matlibre
