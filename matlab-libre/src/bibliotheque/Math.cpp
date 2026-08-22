// Math.cpp — fonctions mathématiques élémentaires, élément par élément.
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

using cplx = std::complex<double>;

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, std::vector<Valeur>& args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

Valeur appliquerComplexe(const Valeur& v, cplx (*f)(const cplx&)) {
    Valeur r = v;
    r.classe = (v.classe == Classe::Simple) ? Classe::Simple : Classe::Double;
    r.chaines.clear();
    r.assurerImaginaire();
    for (std::size_t k = 0; k < r.re.size(); ++k) {
        cplx z = f(cplx(v.re[k], v.im.empty() ? 0.0 : v.im[k]));
        r.re[k] = z.real();
        r.im[k] = z.imag();
    }
    r.compacter();
    return r;
}

Valeur numerique(const Valeur& v) {
    if (v.classe == Classe::Chaine) return versDouble(v);
    if (v.classe == Classe::Cellule)
        erreur("MATLAB:UndefinedFunction",
               "Undefined function for input arguments of type 'cell'.");
    return v;
}

// Applique f aux réels, g aux complexes ; bascule en complexe si besoin.
Valeur elementaire(const Valeur& brut, double (*f)(double), cplx (*g)(const cplx&),
                   bool (*besoinComplexe)(double)) {
    Valeur v = numerique(brut);
    if (v.estComplexe()) return appliquerComplexe(v, g);
    if (besoinComplexe) {
        for (double x : v.re)
            if (besoinComplexe(x)) return appliquerComplexe(v, g);
    }
    return appliquerReel(v, f);
}

bool negatif(double x) { return x < 0; }
bool horsUn(double x) { return x < -1 || x > 1; }
bool sousUn(double x) { return x < 1; }

#define ELEMENTAIRE(nomFn, expr)                                     \
    FONCTION(nomFn) {                                                \
        INUTILISE                                                    \
        exigerArguments(args, 1, 1, #nomFn);                         \
        return {appliquerReel(numerique(args[0]),                    \
                              [](double x) { return (double)(expr); })}; \
    }

FONCTION(fnAbs) {
    INUTILISE
    exigerArguments(args, 1, 1, "abs");
    const Valeur& v = numerique(args[0]);
    if (v.estComplexe()) {
        Valeur r = v;
        r.im.clear();
        for (std::size_t k = 0; k < r.re.size(); ++k) r.re[k] = std::hypot(v.re[k], v.im[k]);
        r.classe = Classe::Double;
        return {r};
    }
    return {appliquerReel(v, [](double x) { return std::fabs(x); })};
}

FONCTION(fnSign) {
    INUTILISE
    return {appliquerReel(numerique(args[0]),
                          [](double x) { return (double)((x > 0) - (x < 0)); })};
}

FONCTION(fnSqrt) {
    INUTILISE
    exigerArguments(args, 1, 1, "sqrt");
    return {elementaire(args[0], [](double x) { return std::sqrt(x); },
                        [](const cplx& z) { return std::sqrt(z); }, negatif)};
}
FONCTION(fnExp) {
    INUTILISE
    return {elementaire(args[0], [](double x) { return std::exp(x); },
                        [](const cplx& z) { return std::exp(z); }, nullptr)};
}
FONCTION(fnLog) {
    INUTILISE
    return {elementaire(args[0], [](double x) { return std::log(x); },
                        [](const cplx& z) { return std::log(z); }, negatif)};
}
FONCTION(fnLog2) {
    INUTILISE
    return {elementaire(args[0], [](double x) { return std::log2(x); },
                        [](const cplx& z) { return std::log(z) / std::log(cplx(2, 0)); },
                        negatif)};
}
FONCTION(fnLog10) {
    INUTILISE
    return {elementaire(args[0], [](double x) { return std::log10(x); },
                        [](const cplx& z) { return std::log10(z); }, negatif)};
}
ELEMENTAIRE(fnLog1p, std::log1p(x))
ELEMENTAIRE(fnExpm1, std::expm1(x))
ELEMENTAIRE(fnSin, std::sin(x))
ELEMENTAIRE(fnCos, std::cos(x))
ELEMENTAIRE(fnTan, std::tan(x))
ELEMENTAIRE(fnSinh, std::sinh(x))
ELEMENTAIRE(fnCosh, std::cosh(x))
ELEMENTAIRE(fnTanh, std::tanh(x))
ELEMENTAIRE(fnAsinh, std::asinh(x))
ELEMENTAIRE(fnCot, 1.0 / std::tan(x))
ELEMENTAIRE(fnSec, 1.0 / std::cos(x))
ELEMENTAIRE(fnCsc, 1.0 / std::sin(x))
ELEMENTAIRE(fnCoth, 1.0 / std::tanh(x))
ELEMENTAIRE(fnSech, 1.0 / std::cosh(x))
ELEMENTAIRE(fnCsch, 1.0 / std::sinh(x))
ELEMENTAIRE(fnSind, std::sin(x * 3.14159265358979323846 / 180.0))
ELEMENTAIRE(fnCosd, std::cos(x * 3.14159265358979323846 / 180.0))
ELEMENTAIRE(fnTand, std::tan(x * 3.14159265358979323846 / 180.0))
ELEMENTAIRE(fnDeg2rad, x * 3.14159265358979323846 / 180.0)
ELEMENTAIRE(fnRad2deg, x * 180.0 / 3.14159265358979323846)
ELEMENTAIRE(fnFloor, std::floor(x))
ELEMENTAIRE(fnCeil, std::ceil(x))
ELEMENTAIRE(fnFix, (x < 0 ? std::ceil(x) : std::floor(x)))
ELEMENTAIRE(fnGammaLn, std::lgamma(x))
ELEMENTAIRE(fnGamma, std::tgamma(x))
ELEMENTAIRE(fnErf, std::erf(x))
ELEMENTAIRE(fnErfc, std::erfc(x))

FONCTION(fnAsin) {
    INUTILISE
    return {elementaire(args[0], [](double x) { return std::asin(x); },
                        [](const cplx& z) { return std::asin(z); }, horsUn)};
}
FONCTION(fnAcos) {
    INUTILISE
    return {elementaire(args[0], [](double x) { return std::acos(x); },
                        [](const cplx& z) { return std::acos(z); }, horsUn)};
}
FONCTION(fnAtan) {
    INUTILISE
    return {elementaire(args[0], [](double x) { return std::atan(x); },
                        [](const cplx& z) { return std::atan(z); }, nullptr)};
}
FONCTION(fnAcosh) {
    INUTILISE
    return {elementaire(args[0], [](double x) { return std::acosh(x); },
                        [](const cplx& z) { return std::acosh(z); }, sousUn)};
}
FONCTION(fnAtanh) {
    INUTILISE
    return {elementaire(args[0], [](double x) { return std::atanh(x); },
                        [](const cplx& z) { return std::atanh(z); }, horsUn)};
}

FONCTION(fnRound) {
    INUTILISE
    exigerArguments(args, 1, 2, "round");
    int chiffres = args.size() > 1 ? (int)args[1].scal() : 0;
    double echelle = std::pow(10.0, chiffres);
    Valeur v = numerique(args[0]);
    Valeur r = appliquerReel(v, [echelle](double x) {
        double y = x * echelle;
        double a = (y < 0) ? -std::floor(-y + 0.5) : std::floor(y + 0.5);
        return a / echelle;
    });
    if (v.estComplexe()) {
        r.im = v.im;
        for (auto& x : r.im) {
            double y = x * echelle;
            x = ((y < 0) ? -std::floor(-y + 0.5) : std::floor(y + 0.5)) / echelle;
        }
    }
    return {r};
}

FONCTION(fnAtan2) {
    INUTILISE
    exigerArguments(args, 2, 2, "atan2");
    return {diffuser(numerique(args[0]), numerique(args[1]),
                     [](double y, double x) { return std::atan2(y, x); }, Classe::Double)};
}
FONCTION(fnHypot) {
    INUTILISE
    exigerArguments(args, 2, 2, "hypot");
    return {diffuser(numerique(args[0]), numerique(args[1]),
                     [](double a, double b) { return std::hypot(a, b); }, Classe::Double)};
}

FONCTION(fnMod) {
    INUTILISE
    exigerArguments(args, 2, 2, "mod");
    return {diffuser(numerique(args[0]), numerique(args[1]),
                     [](double x, double y) {
                         if (y == 0) return x;
                         double r = std::fmod(x, y);
                         if (r != 0 && ((r < 0) != (y < 0))) r += y;
                         return r;
                     },
                     classeResultat(args[0], args[1], "mod"))};
}

FONCTION(fnRem) {
    INUTILISE
    exigerArguments(args, 2, 2, "rem");
    return {diffuser(numerique(args[0]), numerique(args[1]),
                     [](double x, double y) {
                         if (y == 0) return std::nan("");
                         return std::fmod(x, y);
                     },
                     classeResultat(args[0], args[1], "rem"))};
}

FONCTION(fnIdivide) {
    INUTILISE
    exigerArguments(args, 2, 3, "idivide");
    std::string mode = args.size() > 2 ? args[2].versTexte() : "fix";
    return {diffuser(args[0], args[1],
                     [&mode](double x, double y) {
                         double q = x / y;
                         if (mode == "ceil") return std::ceil(q);
                         if (mode == "floor") return std::floor(q);
                         if (mode == "round") return std::round(q);
                         return q < 0 ? std::ceil(q) : std::floor(q);
                     },
                     classeResultat(args[0], args[1], "idivide"))};
}

FONCTION(fnPowerFn) {
    INUTILISE
    exigerArguments(args, 2, 2, "power");
    return {operationBinaire(".^", args[0], args[1])};
}
FONCTION(fnMpower) { INUTILISE return {operationBinaire("^", args[0], args[1])}; }
FONCTION(fnPlus) { INUTILISE return {operationBinaire("+", args[0], args[1])}; }
FONCTION(fnMinus) { INUTILISE return {operationBinaire("-", args[0], args[1])}; }
FONCTION(fnTimes) { INUTILISE return {operationBinaire(".*", args[0], args[1])}; }
FONCTION(fnMtimes) { INUTILISE return {operationBinaire("*", args[0], args[1])}; }
FONCTION(fnRdivide) { INUTILISE return {operationBinaire("./", args[0], args[1])}; }
FONCTION(fnLdivide) { INUTILISE return {operationBinaire(".\\", args[0], args[1])}; }
FONCTION(fnMrdivide) { INUTILISE return {operationBinaire("/", args[0], args[1])}; }
FONCTION(fnMldivide) { INUTILISE return {operationBinaire("\\", args[0], args[1])}; }
FONCTION(fnUminus) { INUTILISE return {operationUnaire("-", args[0])}; }
FONCTION(fnUplus) { INUTILISE return {args[0]}; }
FONCTION(fnNot) { INUTILISE return {operationUnaire("~", args[0])}; }
FONCTION(fnAnd) { INUTILISE return {operationBinaire("&", args[0], args[1])}; }
FONCTION(fnOr) { INUTILISE return {operationBinaire("|", args[0], args[1])}; }
FONCTION(fnXor) {
    INUTILISE
    return {diffuser(args[0], args[1],
                     [](double x, double y) { return (double)((x != 0) != (y != 0)); },
                     Classe::Logique, true)};
}
FONCTION(fnEq) { INUTILISE return {operationBinaire("==", args[0], args[1])}; }
FONCTION(fnNe) { INUTILISE return {operationBinaire("~=", args[0], args[1])}; }
FONCTION(fnLt) { INUTILISE return {operationBinaire("<", args[0], args[1])}; }
FONCTION(fnLe) { INUTILISE return {operationBinaire("<=", args[0], args[1])}; }
FONCTION(fnGt) { INUTILISE return {operationBinaire(">", args[0], args[1])}; }
FONCTION(fnGe) { INUTILISE return {operationBinaire(">=", args[0], args[1])}; }

FONCTION(fnReal) {
    INUTILISE
    Valeur r = numerique(args[0]);
    r.im.clear();
    return {r};
}
FONCTION(fnImag) {
    INUTILISE
    Valeur v = numerique(args[0]);
    Valeur r = v;
    if (v.im.empty()) std::fill(r.re.begin(), r.re.end(), 0.0);
    else r.re = v.im;
    r.im.clear();
    r.classe = Classe::Double;
    return {r};
}
FONCTION(fnConj) {
    INUTILISE
    Valeur r = numerique(args[0]);
    for (auto& x : r.im) x = -x;
    return {r};
}
FONCTION(fnAngle) {
    INUTILISE
    Valeur v = numerique(args[0]);
    Valeur r = v;
    r.classe = Classe::Double;
    for (std::size_t k = 0; k < r.re.size(); ++k)
        r.re[k] = std::atan2(v.im.empty() ? 0.0 : v.im[k], v.re[k]);
    r.im.clear();
    return {r};
}

FONCTION(fnIsnan) {
    INUTILISE
    Valeur v = numerique(args[0]);
    Valeur r = v;
    r.classe = Classe::Logique;
    for (std::size_t k = 0; k < r.re.size(); ++k)
        r.re[k] = (std::isnan(v.re[k]) || (!v.im.empty() && std::isnan(v.im[k]))) ? 1 : 0;
    r.im.clear();
    return {r};
}
FONCTION(fnIsinf) {
    INUTILISE
    Valeur v = numerique(args[0]);
    Valeur r = v;
    r.classe = Classe::Logique;
    for (std::size_t k = 0; k < r.re.size(); ++k)
        r.re[k] = (std::isinf(v.re[k]) || (!v.im.empty() && std::isinf(v.im[k]))) ? 1 : 0;
    r.im.clear();
    return {r};
}
FONCTION(fnIsfinite) {
    INUTILISE
    Valeur v = numerique(args[0]);
    Valeur r = v;
    r.classe = Classe::Logique;
    for (std::size_t k = 0; k < r.re.size(); ++k)
        r.re[k] = (std::isfinite(v.re[k]) && (v.im.empty() || std::isfinite(v.im[k]))) ? 1 : 0;
    r.im.clear();
    return {r};
}

// -------------------------------------------------------- arithmétique entière

FONCTION(fnGcd) {
    INUTILISE
    exigerArguments(args, 2, 2, "gcd");
    return {diffuser(args[0], args[1],
                     [](double a, double b) {
                         long long x = (long long)std::llabs((long long)a);
                         long long y = (long long)std::llabs((long long)b);
                         while (y) {
                             long long t = x % y;
                             x = y;
                             y = t;
                         }
                         return (double)x;
                     },
                     classeResultat(args[0], args[1], "gcd"))};
}

FONCTION(fnLcm) {
    INUTILISE
    exigerArguments(args, 2, 2, "lcm");
    return {diffuser(args[0], args[1],
                     [](double a, double b) {
                         long long x = std::llabs((long long)a), y = std::llabs((long long)b);
                         if (!x || !y) return 0.0;
                         long long g = x, h = y;
                         while (h) {
                             long long t = g % h;
                             g = h;
                             h = t;
                         }
                         return (double)(x / g * y);
                     },
                     classeResultat(args[0], args[1], "lcm"))};
}

FONCTION(fnFactorial) {
    INUTILISE
    return {appliquerReel(numerique(args[0]),
                          [](double x) { return std::tgamma(std::floor(x) + 1.0); })};
}

FONCTION(fnNchoosek) {
    INUTILISE
    exigerArguments(args, 2, 2, "nchoosek");
    if (args[0].nelem() > 1) {
        // Toutes les combinaisons de k éléments.
        int n = (int)args[0].nelem(), k = (int)args[1].scal();
        std::vector<int> indices((std::size_t)k);
        for (int i = 0; i < k; ++i) indices[(std::size_t)i] = i;
        std::vector<std::vector<double>> lignes;
        if (k >= 0 && k <= n) {
            for (;;) {
                std::vector<double> ligne;
                for (int i = 0; i < k; ++i)
                    ligne.push_back(args[0].re[(std::size_t)indices[(std::size_t)i]]);
                lignes.push_back(ligne);
                int i = k - 1;
                while (i >= 0 && indices[(std::size_t)i] == n - k + i) --i;
                if (i < 0) break;
                ++indices[(std::size_t)i];
                for (int j = i + 1; j < k; ++j)
                    indices[(std::size_t)j] = indices[(std::size_t)j - 1] + 1;
            }
        }
        Valeur r = Valeur::matrice((int)lignes.size(), k);
        for (std::size_t i = 0; i < lignes.size(); ++i)
            for (int j = 0; j < k; ++j)
                r.re[i + (std::size_t)j * lignes.size()] = lignes[i][(std::size_t)j];
        return {r};
    }
    double n = argScalaire(args, 0, "nchoosek"), k = argScalaire(args, 1, "nchoosek");
    double r = std::round(std::exp(std::lgamma(n + 1) - std::lgamma(k + 1) -
                                   std::lgamma(n - k + 1)));
    return {Valeur::scalaire(r)};
}

FONCTION(fnPrimes) {
    INUTILISE
    long long n = (long long)argScalaire(args, 0, "primes");
    std::vector<bool> crible((std::size_t)std::max(0LL, n + 1), true);
    std::vector<double> sortie;
    for (long long p = 2; p <= n; ++p) {
        if (!crible[(std::size_t)p]) continue;
        sortie.push_back((double)p);
        for (long long q = p * p; q <= n; q += p) crible[(std::size_t)q] = false;
    }
    return {Valeur::ligne(sortie)};
}

FONCTION(fnIsprime) {
    INUTILISE
    return {appliquerClasse(appliquerReel(numerique(args[0]),
                                          [](double x) {
                                              long long n = (long long)x;
                                              if (n < 2) return 0.0;
                                              for (long long d = 2; d * d <= n; ++d)
                                                  if (n % d == 0) return 0.0;
                                              return 1.0;
                                          }),
                            Classe::Logique)};
}

FONCTION(fnFactor) {
    INUTILISE
    long long n = (long long)argScalaire(args, 0, "factor");
    std::vector<double> f;
    for (long long d = 2; d * d <= n; ++d)
        while (n % d == 0) {
            f.push_back((double)d);
            n /= d;
        }
    if (n > 1) f.push_back((double)n);
    return {Valeur::ligne(f)};
}

FONCTION(fnNthroot) {
    INUTILISE
    exigerArguments(args, 2, 2, "nthroot");
    return {diffuser(args[0], args[1],
                     [](double x, double n) {
                         if (x < 0 && std::fmod(n, 2.0) == 1.0)
                             return -std::pow(-x, 1.0 / n);
                         return std::pow(x, 1.0 / n);
                     },
                     Classe::Double)};
}

// ----------------------------------------------------------------- bits

FONCTION(fnBitand) {
    INUTILISE
    return {diffuser(args[0], args[1],
                     [](double a, double b) {
                         return (double)((unsigned long long)a & (unsigned long long)b);
                     },
                     classeResultat(args[0], args[1], "bitand"))};
}
FONCTION(fnBitor) {
    INUTILISE
    return {diffuser(args[0], args[1],
                     [](double a, double b) {
                         return (double)((unsigned long long)a | (unsigned long long)b);
                     },
                     classeResultat(args[0], args[1], "bitor"))};
}
FONCTION(fnBitxor) {
    INUTILISE
    return {diffuser(args[0], args[1],
                     [](double a, double b) {
                         return (double)((unsigned long long)a ^ (unsigned long long)b);
                     },
                     classeResultat(args[0], args[1], "bitxor"))};
}
FONCTION(fnBitshift) {
    INUTILISE
    return {diffuser(args[0], args[1],
                     [](double a, double n) {
                         unsigned long long x = (unsigned long long)a;
                         int k = (int)n;
                         return (double)(k >= 0 ? (x << k) : (x >> (-k)));
                     },
                     classeResultat(args[0], args[1], "bitshift"))};
}
FONCTION(fnBitcmp) {
    INUTILISE
    return {appliquerReel(args[0], [](double a) {
        return (double)(~(unsigned long long)a & 0xFFFFFFFFFFFFFULL);
    })};
}

// ---------------------------------------------------------- représentations

FONCTION(fnDec2bin) {
    INUTILISE
    exigerArguments(args, 1, 2, "dec2bin");
    unsigned long long n = (unsigned long long)argScalaire(args, 0, "dec2bin");
    int largeur = args.size() > 1 ? (int)args[1].scal() : 1;
    std::string s;
    while (n) {
        s = char('0' + (n & 1)) + s;
        n >>= 1;
    }
    if (s.empty()) s = "0";
    while ((int)s.size() < largeur) s = "0" + s;
    return {Valeur::texte(s)};
}
FONCTION(fnBin2dec) {
    INUTILISE
    std::string s = argTexte(args, 0, "bin2dec");
    double v = 0;
    for (char c : s)
        if (c == '0' || c == '1') v = v * 2 + (c - '0');
    return {Valeur::scalaire(v)};
}
FONCTION(fnDec2hex) {
    INUTILISE
    unsigned long long n = (unsigned long long)argScalaire(args, 0, "dec2hex");
    int largeur = args.size() > 1 ? (int)args[1].scal() : 1;
    std::string s = formater("%llX", n);
    while ((int)s.size() < largeur) s = "0" + s;
    return {Valeur::texte(s)};
}
FONCTION(fnHex2dec) {
    INUTILISE
    std::string s = argTexte(args, 0, "hex2dec");
    return {Valeur::scalaire((double)std::strtoull(s.c_str(), nullptr, 16))};
}

// ------------------------------------------------------- fonctions spéciales

double betaFn(double a, double b) {
    return std::exp(std::lgamma(a) + std::lgamma(b) - std::lgamma(a + b));
}

FONCTION(fnBeta) {
    INUTILISE
    exigerArguments(args, 2, 2, "beta");
    return {diffuser(args[0], args[1], [](double a, double b) { return betaFn(a, b); },
                     Classe::Double)};
}

double erfinvFn(double y) {
    if (y <= -1) return -INFINITY;
    if (y >= 1) return INFINITY;
    // Approximation de Giles, affinée par Newton.
    double w = -std::log((1.0 - y) * (1.0 + y));
    double x;
    if (w < 5.0) {
        w -= 2.5;
        x = 2.81022636e-08;
        x = 3.43273939e-07 + x * w;
        x = -3.5233877e-06 + x * w;
        x = -4.39150654e-06 + x * w;
        x = 0.00021858087 + x * w;
        x = -0.00125372503 + x * w;
        x = -0.00417768164 + x * w;
        x = 0.246640727 + x * w;
        x = 1.50140941 + x * w;
    } else {
        w = std::sqrt(w) - 3.0;
        x = -0.000200214257;
        x = 0.000100950558 + x * w;
        x = 0.00134934322 + x * w;
        x = -0.00367342844 + x * w;
        x = 0.00573950773 + x * w;
        x = -0.0076224613 + x * w;
        x = 0.00943887047 + x * w;
        x = 1.00167406 + x * w;
        x = 2.83297682 + x * w;
    }
    x *= y;
    for (int k = 0; k < 3; ++k) {
        double err = std::erf(x) - y;
        x -= err / (2.0 / std::sqrt(3.14159265358979323846) * std::exp(-x * x));
    }
    return x;
}

FONCTION(fnErfinv) {
    INUTILISE
    return {appliquerReel(numerique(args[0]), [](double x) { return erfinvFn(x); })};
}
FONCTION(fnErfcinv) {
    INUTILISE
    return {appliquerReel(numerique(args[0]), [](double x) { return erfinvFn(1.0 - x); })};
}

// Fonctions de Bessel de première espèce, par la série entière.
double besseljFn(double nu, double x) {
    double somme = 0;
    for (int k = 0; k < 60; ++k) {
        double terme = std::pow(-1.0, k) / (std::tgamma(k + 1) * std::tgamma(k + nu + 1)) *
                       std::pow(x / 2.0, 2 * k + nu);
        somme += terme;
        if (std::fabs(terme) < 1e-18 * (std::fabs(somme) + 1e-300)) break;
    }
    return somme;
}

FONCTION(fnBesselj) {
    INUTILISE
    exigerArguments(args, 2, 2, "besselj");
    return {diffuser(args[0], args[1], [](double nu, double x) { return besseljFn(nu, x); },
                     Classe::Double)};
}
FONCTION(fnBessely) {
    INUTILISE
    exigerArguments(args, 2, 2, "bessely");
    return {diffuser(args[0], args[1],
                     [](double nu, double x) {
                         if (nu == std::floor(nu)) nu += 1e-8;
                         return (besseljFn(nu, x) * std::cos(nu * 3.14159265358979323846) -
                                 besseljFn(-nu, x)) /
                                std::sin(nu * 3.14159265358979323846);
                     },
                     Classe::Double)};
}

// Fraction continue de Lentz pour la fonction beta incomplete.
double betaFractionContinue(double x, double a, double b) {
    const int maxIterations = 300;
    const double eps = 1e-15;
    const double minuscule = 1e-300;
    double qab = a + b, qap = a + 1, qam = a - 1;
    double c = 1.0;
    double d = 1.0 - qab * x / qap;
    if (std::fabs(d) < minuscule) d = minuscule;
    d = 1.0 / d;
    double h = d;
    for (int m = 1; m <= maxIterations; ++m) {
        int m2 = 2 * m;
        double aa = m * (b - m) * x / ((qam + m2) * (a + m2));
        d = 1.0 + aa * d;
        if (std::fabs(d) < minuscule) d = minuscule;
        c = 1.0 + aa / c;
        if (std::fabs(c) < minuscule) c = minuscule;
        d = 1.0 / d;
        h *= d * c;
        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
        d = 1.0 + aa * d;
        if (std::fabs(d) < minuscule) d = minuscule;
        c = 1.0 + aa / c;
        if (std::fabs(c) < minuscule) c = minuscule;
        d = 1.0 / d;
        double del = d * c;
        h *= del;
        if (std::fabs(del - 1.0) < eps) break;
    }
    return h;
}

double betaIncompleteRegularisee(double x, double a, double b) {
    if (x <= 0) return 0.0;
    if (x >= 1) return 1.0;
    double lbeta = std::lgamma(a) + std::lgamma(b) - std::lgamma(a + b);
    double devant = std::exp(a * std::log(x) + b * std::log1p(-x) - lbeta);
    if (x < (a + 1) / (a + b + 2))
        return devant * betaFractionContinue(x, a, b) / a;
    return 1.0 - devant * betaFractionContinue(1 - x, b, a) / b;
}

double gammaIncompleteRegularisee(double x, double a) {
    if (x <= 0) return 0.0;
    if (x < a + 1) {
        // Serie.
        double somme = 1.0 / a;
        double terme = somme;
        for (int n = 1; n < 500; ++n) {
            terme *= x / (a + n);
            somme += terme;
            if (std::fabs(terme) < std::fabs(somme) * 1e-16) break;
        }
        return somme * std::exp(-x + a * std::log(x) - std::lgamma(a));
    }
    // Fraction continue pour la partie superieure.
    const double minuscule = 1e-300;
    double b = x + 1 - a;
    double c = 1e300;
    double d = 1.0 / b;
    double h = d;
    for (int i = 1; i < 500; ++i) {
        double an = -i * (i - a);
        b += 2.0;
        d = an * d + b;
        if (std::fabs(d) < minuscule) d = minuscule;
        c = b + an / c;
        if (std::fabs(c) < minuscule) c = minuscule;
        d = 1.0 / d;
        double del = d * c;
        h *= del;
        if (std::fabs(del - 1.0) < 1e-16) break;
    }
    double q = std::exp(-x + a * std::log(x) - std::lgamma(a)) * h;
    return 1.0 - q;
}

FONCTION(fnBetainc) {
    INUTILISE
    exigerArguments(args, 3, 4, "betainc");
    double a = args[1].scal();
    double b = args[2].scal();
    bool superieure = args.size() > 3 && args[3].versTexte() == "upper";
    return {appliquerReel(versDouble(args[0]), [a, b, superieure](double x) {
        double v = betaIncompleteRegularisee(x, a, b);
        return superieure ? 1.0 - v : v;
    })};
}

FONCTION(fnGammainc) {
    INUTILISE
    exigerArguments(args, 2, 3, "gammainc");
    bool superieure = args.size() > 2 && args[2].versTexte() == "upper";
    double a = args[1].scal();
    return {appliquerReel(versDouble(args[0]), [a, superieure](double x) {
        double v = gammaIncompleteRegularisee(x, a);
        return superieure ? 1.0 - v : v;
    })};
}

FONCTION(fnSincFn) {
    INUTILISE
    return {appliquerReel(numerique(args[0]), [](double x) {
        if (x == 0) return 1.0;
        double t = 3.14159265358979323846 * x;
        return std::sin(t) / t;
    })};
}

}  // namespace

void enregistrerMath(Interpreteur& it) {
    struct Entree {
        const char* nom;
        Builtin f;
        const char* aide;
    };
    static const Entree table[] = {
        {"abs", fnAbs, "abs  Valeur absolue, module d'un complexe."},
        {"sign", fnSign, "sign  Signe : -1, 0 ou 1."},
        {"sqrt", fnSqrt, "sqrt  Racine carree (complexe si l'argument est negatif)."},
        {"exp", fnExp, "exp  Exponentielle."},
        {"log", fnLog, "log  Logarithme naturel."},
        {"log2", fnLog2, "log2  Logarithme en base 2."},
        {"log10", fnLog10, "log10  Logarithme decimal."},
        {"log1p", fnLog1p, "log1p  log(1+x), precis pres de zero."},
        {"expm1", fnExpm1, "expm1  exp(x)-1, precis pres de zero."},
        {"sin", fnSin, "sin  Sinus (radians)."},
        {"cos", fnCos, "cos  Cosinus (radians)."},
        {"tan", fnTan, "tan  Tangente (radians)."},
        {"asin", fnAsin, "asin  Arc sinus."},
        {"acos", fnAcos, "acos  Arc cosinus."},
        {"atan", fnAtan, "atan  Arc tangente."},
        {"atan2", fnAtan2, "atan2  Arc tangente a quatre quadrants."},
        {"sinh", fnSinh, "sinh  Sinus hyperbolique."},
        {"cosh", fnCosh, "cosh  Cosinus hyperbolique."},
        {"tanh", fnTanh, "tanh  Tangente hyperbolique."},
        {"asinh", fnAsinh, "asinh  Arc sinus hyperbolique."},
        {"acosh", fnAcosh, "acosh  Arc cosinus hyperbolique."},
        {"atanh", fnAtanh, "atanh  Arc tangente hyperbolique."},
        {"cot", fnCot, "cot  Cotangente."},
        {"sec", fnSec, "sec  Secante."},
        {"csc", fnCsc, "csc  Cosecante."},
        {"coth", fnCoth, "coth  Cotangente hyperbolique."},
        {"sech", fnSech, "sech  Secante hyperbolique."},
        {"csch", fnCsch, "csch  Cosecante hyperbolique."},
        {"sind", fnSind, "sind  Sinus en degres."},
        {"cosd", fnCosd, "cosd  Cosinus en degres."},
        {"tand", fnTand, "tand  Tangente en degres."},
        {"deg2rad", fnDeg2rad, "deg2rad  Degres vers radians."},
        {"rad2deg", fnRad2deg, "rad2deg  Radians vers degres."},
        {"floor", fnFloor, "floor  Arrondi vers moins l'infini."},
        {"ceil", fnCeil, "ceil  Arrondi vers plus l'infini."},
        {"fix", fnFix, "fix  Arrondi vers zero."},
        {"round", fnRound, "round  Arrondi au plus proche."},
        {"hypot", fnHypot, "hypot  sqrt(a^2+b^2) sans debordement."},
        {"mod", fnMod, "mod  Modulo, du signe du diviseur."},
        {"rem", fnRem, "rem  Reste, du signe du dividende."},
        {"idivide", fnIdivide, "idivide  Division entiere avec mode d'arrondi."},
        {"power", fnPowerFn, "power  Puissance element par element."},
        {"mpower", fnMpower, "mpower  Puissance matricielle."},
        {"plus", fnPlus, "plus  Addition."},
        {"minus", fnMinus, "minus  Soustraction."},
        {"times", fnTimes, "times  Produit element par element."},
        {"mtimes", fnMtimes, "mtimes  Produit matriciel."},
        {"rdivide", fnRdivide, "rdivide  Division a droite element par element."},
        {"ldivide", fnLdivide, "ldivide  Division a gauche element par element."},
        {"mrdivide", fnMrdivide, "mrdivide  Division matricielle a droite."},
        {"mldivide", fnMldivide, "mldivide  Division matricielle a gauche."},
        {"uminus", fnUminus, "uminus  Moins unaire."},
        {"uplus", fnUplus, "uplus  Plus unaire."},
        {"not", fnNot, "not  Negation logique."},
        {"and", fnAnd, "and  Et logique."},
        {"or", fnOr, "or  Ou logique."},
        {"xor", fnXor, "xor  Ou exclusif."},
        {"eq", fnEq, "eq  Egalite."},
        {"ne", fnNe, "ne  Difference."},
        {"lt", fnLt, "lt  Strictement inferieur."},
        {"le", fnLe, "le  Inferieur ou egal."},
        {"gt", fnGt, "gt  Strictement superieur."},
        {"ge", fnGe, "ge  Superieur ou egal."},
        {"real", fnReal, "real  Partie reelle."},
        {"imag", fnImag, "imag  Partie imaginaire."},
        {"conj", fnConj, "conj  Conjugue complexe."},
        {"angle", fnAngle, "angle  Argument d'un complexe."},
        {"arg", fnAngle, "arg  Argument d'un complexe."},
        {"isnan", fnIsnan, "isnan  Vrai pour les NaN."},
        {"isinf", fnIsinf, "isinf  Vrai pour les infinis."},
        {"isfinite", fnIsfinite, "isfinite  Vrai pour les valeurs finies."},
        {"gcd", fnGcd, "gcd  Plus grand commun diviseur."},
        {"lcm", fnLcm, "lcm  Plus petit commun multiple."},
        {"factorial", fnFactorial, "factorial  Factorielle."},
        {"nchoosek", fnNchoosek, "nchoosek  Coefficient binomial ou combinaisons."},
        {"primes", fnPrimes, "primes  Nombres premiers jusqu'a n."},
        {"isprime", fnIsprime, "isprime  Test de primalite."},
        {"factor", fnFactor, "factor  Decomposition en facteurs premiers."},
        {"nthroot", fnNthroot, "nthroot  Racine n-ieme reelle."},
        {"bitand", fnBitand, "bitand  Et binaire."},
        {"bitor", fnBitor, "bitor  Ou binaire."},
        {"bitxor", fnBitxor, "bitxor  Ou exclusif binaire."},
        {"bitshift", fnBitshift, "bitshift  Decalage binaire."},
        {"bitcmp", fnBitcmp, "bitcmp  Complement binaire."},
        {"dec2bin", fnDec2bin, "dec2bin  Entier vers chaine binaire."},
        {"bin2dec", fnBin2dec, "bin2dec  Chaine binaire vers entier."},
        {"dec2hex", fnDec2hex, "dec2hex  Entier vers chaine hexadecimale."},
        {"hex2dec", fnHex2dec, "hex2dec  Chaine hexadecimale vers entier."},
        {"gamma", fnGamma, "gamma  Fonction gamma."},
        {"gammaln", fnGammaLn, "gammaln  Logarithme de la fonction gamma."},
        {"beta", fnBeta, "beta  Fonction beta."},
        {"erf", fnErf, "erf  Fonction d'erreur."},
        {"erfc", fnErfc, "erfc  Fonction d'erreur complementaire."},
        {"erfinv", fnErfinv, "erfinv  Reciproque de erf."},
        {"erfcinv", fnErfcinv, "erfcinv  Reciproque de erfc."},
        {"besselj", fnBesselj, "besselj  Bessel de premiere espece."},
        {"bessely", fnBessely, "bessely  Bessel de seconde espece."},
        {"sinc", fnSincFn, "sinc  sin(pi x)/(pi x)."},
        {"betainc", fnBetainc, "betainc  Fonction beta incomplete regularisee."},
        {"gammainc", fnGammainc, "gammainc  Fonction gamma incomplete regularisee."},
    };
    for (const auto& e : table) it.enregistrer(e.nom, e.f, "math", e.aide);
}

}  // namespace matlibre
