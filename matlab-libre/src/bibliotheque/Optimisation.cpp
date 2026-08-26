// Optimisation.cpp — zéros, minimisation, quadrature, équations différentielles.
#include <array>
#include <cctype>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <functional>

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

// Enveloppe une poignée MATLAB en fonction C++ scalaire.
std::function<double(double)> fonctionScalaire(Interpreteur& it, const Valeur& f) {
    return [&it, f](double x) {
        std::vector<Valeur> a = {Valeur::scalaire(x)};
        auto r = it.appelerValeur(f, a, 1);
        if (r.empty()) return std::nan("");
        return r[0].re.empty() ? std::nan("") : r[0].re[0];
    };
}

std::function<Valeur(const Valeur&)> fonctionVectorielle(Interpreteur& it, const Valeur& f) {
    return [&it, f](const Valeur& x) {
        std::vector<Valeur> a = {x};
        auto r = it.appelerValeur(f, a, 1);
        return r.empty() ? Valeur::vide() : r[0];
    };
}

double lireOption(const std::vector<Valeur>& args, std::size_t debut, const char* nom,
                  double defaut) {
    for (std::size_t k = debut; k < args.size(); ++k) {
        if (!args[k].estStructure()) continue;
        if (args[k].aChamp(nom)) {
            Valeur v = args[k].champ(nom);
            if (!v.estVide()) return v.scal();
        }
    }
    return defaut;
}

FONCTION(fnFzero) {
    INUTILISE
    exigerArguments(args, 2, 3, "fzero");
    auto f = fonctionScalaire(it, args[0]);
    double a, b;
    if (args[1].nelem() >= 2) {
        a = args[1].re[0];
        b = args[1].re[1];
    } else {
        // Recherche d'un encadrement autour du point donné.
        double x0 = args[1].scal();
        double pas = (x0 == 0) ? 0.02 : std::fabs(x0) / 50.0;
        a = x0;
        b = x0;
        double fa = f(a), fb = fa;
        int essais = 0;
        while (fa * fb > 0 && essais < 200) {
            pas *= 1.4142135623730951;
            a = x0 - pas;
            b = x0 + pas;
            fa = f(a);
            fb = f(b);
            ++essais;
        }
        if (fa * fb > 0)
            erreur("MATLAB:fzero:NoSignChange",
                   "Function values at the interval endpoints must differ in sign.");
    }
    double fa = f(a), fb = f(b);
    if (fa == 0) return {Valeur::scalaire(a)};
    if (fb == 0) return {Valeur::scalaire(b)};
    if (fa * fb > 0)
        erreur("MATLAB:fzero:ValuesAtEndPtsSameSign",
               "The function values at the interval endpoints must differ in sign.");
    // Méthode de Brent.
    double c = a, fc = fa, d = b - a, e = d;
    for (int k = 0; k < 200; ++k) {
        if (fb * fc > 0) {
            c = a;
            fc = fa;
            d = b - a;
            e = d;
        }
        if (std::fabs(fc) < std::fabs(fb)) {
            a = b; b = c; c = a;
            fa = fb; fb = fc; fc = fa;
        }
        double tol = 2 * 2.220446049250313e-16 * std::fabs(b) + 1e-15;
        double m = 0.5 * (c - b);
        if (std::fabs(m) <= tol || fb == 0) break;
        if (std::fabs(e) < tol || std::fabs(fa) <= std::fabs(fb)) {
            d = m;
            e = m;
        } else {
            double s = fb / fa, p, q;
            if (a == c) {
                p = 2 * m * s;
                q = 1 - s;
            } else {
                double r = fb / fc;
                q = fa / fc;
                p = s * (2 * m * q * (q - r) - (b - a) * (r - 1));
                q = (q - 1) * (r - 1) * (s - 1);
            }
            if (p > 0) q = -q;
            p = std::fabs(p);
            if (2 * p < std::min(3 * m * q - std::fabs(tol * q), std::fabs(e * q))) {
                e = d;
                d = p / q;
            } else {
                d = m;
                e = m;
            }
        }
        a = b;
        fa = fb;
        b += (std::fabs(d) > tol) ? d : (m > 0 ? tol : -tol);
        fb = f(b);
    }
    if (nargout >= 2) return {Valeur::scalaire(b), Valeur::scalaire(fb)};
    return {Valeur::scalaire(b)};
}

FONCTION(fnFminbnd) {
    INUTILISE
    exigerArguments(args, 3, 4, "fminbnd");
    auto f = fonctionScalaire(it, args[0]);
    double a = args[1].scal(), b = args[2].scal();
    const double phi = 0.6180339887498949;
    double c = b - phi * (b - a), d = a + phi * (b - a);
    double fc = f(c), fd = f(d);
    for (int k = 0; k < 200 && std::fabs(b - a) > 1e-10; ++k) {
        if (fc < fd) {
            b = d;
            d = c;
            fd = fc;
            c = b - phi * (b - a);
            fc = f(c);
        } else {
            a = c;
            c = d;
            fc = fd;
            d = a + phi * (b - a);
            fd = f(d);
        }
    }
    double x = 0.5 * (a + b);
    if (nargout >= 2) return {Valeur::scalaire(x), Valeur::scalaire(f(x))};
    return {Valeur::scalaire(x)};
}

// Nelder-Mead, tel que décrit dans la documentation de fminsearch.
FONCTION(fnFminsearch) {
    INUTILISE
    exigerArguments(args, 2, 3, "fminsearch");
    auto f = fonctionVectorielle(it, args[0]);
    Valeur x0 = versDouble(args[1]);
    std::size_t n = x0.nelem();
    double tolX = lireOption(args, 2, "TolX", 1e-8);
    double tolF = lireOption(args, 2, "TolFun", 1e-8);
    int maxIterations = (int)lireOption(args, 2, "MaxIter", (double)(200 * n));

    auto evaluer = [&](const std::vector<double>& p) {
        Valeur v = x0;
        for (std::size_t k = 0; k < n; ++k) v.re[k] = p[k];
        Valeur r = f(v);
        return r.re.empty() ? NAN : r.re[0];
    };
    std::vector<std::vector<double>> simplexe;
    std::vector<double> valeurs;
    std::vector<double> base(x0.re.begin(), x0.re.end());
    simplexe.push_back(base);
    for (std::size_t k = 0; k < n; ++k) {
        std::vector<double> p = base;
        p[k] = (p[k] != 0) ? p[k] * 1.05 : 0.00025;
        simplexe.push_back(p);
    }
    for (auto& p : simplexe) valeurs.push_back(evaluer(p));

    for (int iteration = 0; iteration < maxIterations; ++iteration) {
        std::vector<std::size_t> ordre(simplexe.size());
        for (std::size_t k = 0; k < ordre.size(); ++k) ordre[k] = k;
        std::sort(ordre.begin(), ordre.end(),
                  [&](std::size_t a, std::size_t b) { return valeurs[a] < valeurs[b]; });
        std::vector<std::vector<double>> s2;
        std::vector<double> v2;
        for (auto k : ordre) {
            s2.push_back(simplexe[k]);
            v2.push_back(valeurs[k]);
        }
        simplexe = s2;
        valeurs = v2;

        double ecartX = 0, ecartF = 0;
        for (std::size_t k = 1; k < simplexe.size(); ++k) {
            ecartF = std::max(ecartF, std::fabs(valeurs[k] - valeurs[0]));
            for (std::size_t j = 0; j < n; ++j)
                ecartX = std::max(ecartX, std::fabs(simplexe[k][j] - simplexe[0][j]));
        }
        if (ecartX < tolX && ecartF < tolF) break;

        std::vector<double> centre(n, 0.0);
        for (std::size_t k = 0; k + 1 < simplexe.size(); ++k)
            for (std::size_t j = 0; j < n; ++j) centre[j] += simplexe[k][j] / (double)n;
        std::vector<double> pire = simplexe.back();
        std::vector<double> reflechi(n);
        for (std::size_t j = 0; j < n; ++j) reflechi[j] = centre[j] + (centre[j] - pire[j]);
        double fr = evaluer(reflechi);
        if (fr < valeurs[0]) {
            std::vector<double> etendu(n);
            for (std::size_t j = 0; j < n; ++j)
                etendu[j] = centre[j] + 2.0 * (centre[j] - pire[j]);
            double fe = evaluer(etendu);
            simplexe.back() = (fe < fr) ? etendu : reflechi;
            valeurs.back() = std::min(fe, fr);
        } else if (fr < valeurs[valeurs.size() - 2]) {
            simplexe.back() = reflechi;
            valeurs.back() = fr;
        } else {
            std::vector<double> contracte(n);
            for (std::size_t j = 0; j < n; ++j)
                contracte[j] = centre[j] + 0.5 * (pire[j] - centre[j]);
            double fc = evaluer(contracte);
            if (fc < valeurs.back()) {
                simplexe.back() = contracte;
                valeurs.back() = fc;
            } else {
                for (std::size_t k = 1; k < simplexe.size(); ++k) {
                    for (std::size_t j = 0; j < n; ++j)
                        simplexe[k][j] = simplexe[0][j] + 0.5 * (simplexe[k][j] - simplexe[0][j]);
                    valeurs[k] = evaluer(simplexe[k]);
                }
            }
        }
    }
    std::size_t meilleur = 0;
    for (std::size_t k = 1; k < valeurs.size(); ++k)
        if (valeurs[k] < valeurs[meilleur]) meilleur = k;
    Valeur x = x0;
    for (std::size_t k = 0; k < n; ++k) x.re[k] = simplexe[meilleur][k];
    if (nargout >= 2) return {x, Valeur::scalaire(valeurs[meilleur])};
    return {x};
}

FONCTION(fnFminunc) {
    INUTILISE
    return fnFminsearch(it, args, nargout);
}

FONCTION(fnFsolve) {
    INUTILISE
    exigerArguments(args, 2, 3, "fsolve");
    auto f = fonctionVectorielle(it, args[0]);
    Valeur x = versDouble(args[1]);
    std::size_t n = x.nelem();
    for (int iteration = 0; iteration < 200; ++iteration) {
        Valeur fx = f(x);
        double norme = 0;
        for (double v : fx.re) norme += v * v;
        if (std::sqrt(norme) < 1e-12) break;
        // Jacobien par différences finies.
        std::size_t m = fx.nelem();
        Valeur J = Valeur::matrice((int)m, (int)n);
        for (std::size_t j = 0; j < n; ++j) {
            Valeur xp = x;
            double h = 1e-7 * std::max(1.0, std::fabs(x.re[j]));
            xp.re[j] += h;
            Valeur fp = f(xp);
            for (std::size_t i = 0; i < m; ++i)
                J.re[i + j * m] = (fp.re[i] - fx.re[i]) / h;
        }
        Valeur second = Valeur::colonne(std::vector<double>(fx.re.begin(), fx.re.end()));
        Valeur pas = divisionGauche(J, second);
        double amplitude = 0;
        for (std::size_t j = 0; j < n && j < pas.nelem(); ++j) {
            x.re[j] -= pas.re[j];
            amplitude = std::max(amplitude, std::fabs(pas.re[j]));
        }
        if (amplitude < 1e-14) break;
    }
    if (nargout >= 2) return {x, f(x)};
    return {x};
}

// Quadrature adaptative de Simpson.
double simpsonAdaptatif(const std::function<double(double)>& f, double a, double b, double eps,
                        double total, double fa, double fm, double fb, int profondeur) {
    double c = 0.5 * (a + b);
    double d = 0.5 * (a + c), e = 0.5 * (c + b);
    double fd = f(d), fe = f(e);
    double gauche = (c - a) / 6 * (fa + 4 * fd + fm);
    double droite = (b - c) / 6 * (fm + 4 * fe + fb);
    if (profondeur <= 0 || std::fabs(gauche + droite - total) <= 15 * eps)
        return gauche + droite + (gauche + droite - total) / 15;
    return simpsonAdaptatif(f, a, c, eps / 2, gauche, fa, fd, fm, profondeur - 1) +
           simpsonAdaptatif(f, c, b, eps / 2, droite, fm, fe, fb, profondeur - 1);
}

FONCTION(fnIntegral) {
    INUTILISE
    exigerArguments(args, 3, 0, "integral");
    auto brut = fonctionVectorielle(it, args[0]);
    auto f = [&](double x) {
        Valeur r = brut(Valeur::scalaire(x));
        return r.re.empty() ? 0.0 : r.re[0];
    };
    double a = args[1].scal(), b = args[2].scal();
    if (a == b) return {Valeur::scalaire(0)};
    double signe = 1.0;
    if (a > b) {
        std::swap(a, b);
        signe = -1.0;
    }
    double fa = f(a), fb = f(b), fm = f(0.5 * (a + b));
    double total = (b - a) / 6 * (fa + 4 * fm + fb);
    double v = simpsonAdaptatif(f, a, b, 1e-10, total, fa, fm, fb, 50);
    return {Valeur::scalaire(signe * v)};
}

FONCTION(fnQuad) {
    INUTILISE
    return fnIntegral(it, args, nargout);
}

FONCTION(fnQuadgk) {
    INUTILISE
    return fnIntegral(it, args, nargout);
}

FONCTION(fnIntegral2) {
    INUTILISE
    exigerArguments(args, 5, 5, "integral2");
    Valeur f = args[0];
    double ax = args[1].scal(), bx = args[2].scal();
    double ay = args[3].scal(), by = args[4].scal();
    const int n = 200;
    double hx = (bx - ax) / n, hy = (by - ay) / n;
    double somme = 0;
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j) {
            double x = ax + (i + 0.5) * hx;
            double y = ay + (j + 0.5) * hy;
            std::vector<Valeur> a = {Valeur::scalaire(x), Valeur::scalaire(y)};
            auto r = it.appelerValeur(f, a, 1);
            somme += r.empty() || r[0].re.empty() ? 0.0 : r[0].re[0];
        }
    return {Valeur::scalaire(somme * hx * hy)};
}

// Resolution d'un systeme dense, definie plus bas avec les methodes
// implicites : la matrice de masse en a besoin ici.
bool resoudreDense(std::vector<double>& a, std::vector<double>& b, std::size_t n);

// Lecture d'une option qui n'est pas un scalaire : matrice de masse,
// jacobienne fournie, fonction d'evenements.
Valeur lireOptionValeur(const std::vector<Valeur>& args, std::size_t debut, const char* nom) {
    for (std::size_t k = debut; k < args.size(); ++k) {
        if (!args[k].estStructure()) continue;
        if (args[k].aChamp(nom)) return args[k].champ(nom);
    }
    return Valeur::vide();
}

// Detection d'evenements. La fonction rend trois vecteurs : la valeur
// dont on cherche l'annulation, un drapeau d'arret et un sens de
// traversee (+1 montant, -1 descendant, 0 les deux).
struct EvenementsEDO {
    Interpreteur* it = nullptr;
    Valeur f;
    bool actif = false;
    std::vector<double> terminal;
    std::vector<double> direction;

    std::vector<double> valeurs(double t, const Valeur& y) {
        std::vector<Valeur> a = {Valeur::scalaire(t), y};
        auto r = it->appelerValeur(f, a, 3);
        if (r.empty())
            erreur("MATLAB:ode:BadEvents", "The events function returned nothing.");
        Valeur v = versDouble(r[0]);
        std::vector<double> g(v.re.begin(), v.re.end());
        if (terminal.size() != g.size()) {
            terminal.assign(g.size(), 0.0);
            direction.assign(g.size(), 0.0);
            if (r.size() > 1) {
                Valeur d = versDouble(r[1]);
                for (std::size_t k = 0; k < g.size() && k < d.re.size(); ++k)
                    terminal[k] = d.re[k];
            }
            if (r.size() > 2) {
                Valeur d = versDouble(r[2]);
                for (std::size_t k = 0; k < g.size() && k < d.re.size(); ++k)
                    direction[k] = d.re[k];
            }
        }
        return g;
    }
};

// Dormand-Prince 4(5), le cœur de ode45.
std::vector<Valeur> resoudreEDO(Interpreteur& it, std::vector<Valeur>& args, int nargout,
                                bool ordreFaible) {
    exigerArguments(args, 3, 4, "ode45");
    Valeur f = args[0];
    const Valeur& intervalle = args[1];
    Valeur y = versDouble(args[2]);
    std::size_t n = y.nelem();
    double t0 = intervalle.re[0];
    double tf = intervalle.re[intervalle.nelem() - 1];
    std::vector<double> pointsDemandes;
    if (intervalle.nelem() > 2)
        for (std::size_t k = 0; k < intervalle.nelem(); ++k)
            pointsDemandes.push_back(intervalle.re[k]);
    double tolRelative = lireOption(args, 3, "RelTol", 1e-6);
    double tolAbsolue = lireOption(args, 3, "AbsTol", 1e-9);
    double sens = (tf >= t0) ? 1.0 : -1.0;
    double etendue = std::fabs(tf - t0);
    double hMax = lireOption(args, 3, "MaxStep", etendue > 0 ? etendue / 10.0 : 1.0);
    double hInitial = lireOption(args, 3, "InitialStep", 0.0);
    int raffinement = (int)lireOption(args, 3, "Refine", 4.0);
    if (raffinement < 1) raffinement = 1;

    // Masse : le systeme s'ecrit M(t,y) y' = f(t,y). On resout donc a
    // chaque evaluation, ce qui suppose M inversible — les problemes
    // algebro-differentiels, ou M est singuliere, ne sont pas traites.
    Valeur masse = lireOptionValeur(args, 3, "Mass");
    bool masseConstante = !masse.estVide() && !masse.estFonction();
    std::vector<double> facteurMasse;
    auto appliquerMasse = [&](double t, const Valeur& etat, Valeur& d) {
        if (masse.estVide()) return;
        Valeur M;
        if (masseConstante) {
            M = versDouble(masse);
        } else {
            std::vector<Valeur> a = {Valeur::scalaire(t), etat};
            auto r = it.appelerValeur(masse, a, 1);
            if (r.empty()) erreur("MATLAB:ode:BadMass", "The mass function returned nothing.");
            M = versDouble(r[0]);
        }
        std::vector<double> A(M.re.begin(), M.re.end());
        std::vector<double> b(d.re.begin(), d.re.end());
        if (A.size() != n * n) erreur("MATLAB:ode:BadMass", "The mass matrix has the wrong size.");
        if (!resoudreDense(A, b, n))
            erreur("MATLAB:ode:SingularMass", "The mass matrix is singular.");
        for (std::size_t k = 0; k < n; ++k) d.re[k] = b[k];
    };

    auto derivee = [&](double t, const Valeur& etat) {
        std::vector<Valeur> a = {Valeur::scalaire(t), etat};
        auto r = it.appelerValeur(f, a, 1);
        if (r.empty()) erreur("MATLAB:ode45:BadFunction", "The ODE function returned nothing.");
        Valeur d = versDouble(r[0]);
        d.dims = {(int)n, 1};
        d.re.resize(n, 0.0);
        appliquerMasse(t, etat, d);
        return d;
    };
    auto combiner = [](const Valeur& a, const Valeur& b, double coefficient) {
        Valeur r = a;
        for (std::size_t k = 0; k < r.re.size() && k < b.re.size(); ++k)
            r.re[k] += coefficient * b.re[k];
        return r;
    };

    EvenementsEDO evenements;
    Valeur fonctionEvenements = lireOptionValeur(args, 3, "Events");
    if (!fonctionEvenements.estVide()) {
        evenements.it = &it;
        evenements.f = fonctionEvenements;
        evenements.actif = true;
    }

    static const double a2 = 1.0 / 5, a3 = 3.0 / 10, a4 = 4.0 / 5, a5 = 8.0 / 9;
    // Coefficients de la sortie dense d'ordre cinq (Hairer, Norsett, Wanner).
    static const double d1 = -12715105075.0 / 11282082432.0;
    static const double d3 = 87487479700.0 / 32700410799.0;
    static const double d4 = -10690763975.0 / 1880347072.0;
    static const double d5 = 701980252875.0 / 199316789632.0;
    static const double d6 = -1453857185.0 / 822651844.0;
    static const double d7 = 69997945.0 / 29380423.0;

    std::vector<double> temps = {t0};
    std::vector<Valeur> etats = {y};
    // Cinq vecteurs de coefficients par pas accepte : ils permettent
    // d'evaluer la solution partout dans le pas, a l'ordre cinq.
    std::vector<std::array<std::vector<double>, 5>> coefficients;
    std::vector<double> hPas;

    double h = hInitial;
    if (!(h > 0)) h = (tf - t0) / 100.0;
    if (h == 0) h = 1e-3;
    if (std::fabs(h) > hMax) h = sens * hMax;
    double t = t0;
    int pas = 0;

    std::vector<double> gPrecedent;
    if (evenements.actif) gPrecedent = evenements.valeurs(t0, y);
    std::vector<double> tEvenements;
    std::vector<Valeur> yEvenements;
    std::vector<double> iEvenements;
    bool arret = false;

    // Interpolation dans le pas courant, formule de Hairer.
    auto interpoler = [&](const std::array<std::vector<double>, 5>& c, double theta) {
        Valeur r = y;
        r.re.assign(n, 0.0);
        double s = 1.0 - theta;
        for (std::size_t i = 0; i < n; ++i)
            r.re[i] = c[0][i] + theta * (c[1][i] + s * (c[2][i] + theta * (c[3][i] + s * c[4][i])));
        return r;
    };

    while (!arret && (tf - t) * sens > 0 && pas < 200000) {
        ++pas;
        if ((t + h - tf) * sens > 0) h = tf - t;
        Valeur k1 = derivee(t, y);
        Valeur k2 = derivee(t + a2 * h, combiner(y, k1, h / 5));
        Valeur y3 = y;
        for (std::size_t i = 0; i < y3.re.size(); ++i)
            y3.re[i] += h * (3.0 / 40 * k1.re[i] + 9.0 / 40 * k2.re[i]);
        Valeur k3 = derivee(t + a3 * h, y3);
        Valeur y4 = y;
        for (std::size_t i = 0; i < y4.re.size(); ++i)
            y4.re[i] += h * (44.0 / 45 * k1.re[i] - 56.0 / 15 * k2.re[i] + 32.0 / 9 * k3.re[i]);
        Valeur k4 = derivee(t + a4 * h, y4);
        Valeur y5 = y;
        for (std::size_t i = 0; i < y5.re.size(); ++i)
            y5.re[i] += h * (19372.0 / 6561 * k1.re[i] - 25360.0 / 2187 * k2.re[i] +
                             64448.0 / 6561 * k3.re[i] - 212.0 / 729 * k4.re[i]);
        Valeur k5 = derivee(t + a5 * h, y5);
        Valeur y6 = y;
        for (std::size_t i = 0; i < y6.re.size(); ++i)
            y6.re[i] += h * (9017.0 / 3168 * k1.re[i] - 355.0 / 33 * k2.re[i] +
                             46732.0 / 5247 * k3.re[i] + 49.0 / 176 * k4.re[i] -
                             5103.0 / 18656 * k5.re[i]);
        Valeur k6 = derivee(t + h, y6);
        Valeur suivant = y;
        for (std::size_t i = 0; i < suivant.re.size(); ++i)
            suivant.re[i] += h * (35.0 / 384 * k1.re[i] + 500.0 / 1113 * k3.re[i] +
                                  125.0 / 192 * k4.re[i] - 2187.0 / 6784 * k5.re[i] +
                                  11.0 / 84 * k6.re[i]);
        Valeur k7 = derivee(t + h, suivant);
        double erreurMax = 0;
        for (std::size_t i = 0; i < suivant.re.size(); ++i) {
            double estimation =
                h * (71.0 / 57600 * k1.re[i] - 71.0 / 16695 * k3.re[i] +
                     71.0 / 1920 * k4.re[i] - 17253.0 / 339200 * k5.re[i] +
                     22.0 / 525 * k6.re[i] - 1.0 / 40 * k7.re[i]);
            double echelle = tolAbsolue + tolRelative * std::max(std::fabs(y.re[i]),
                                                                 std::fabs(suivant.re[i]));
            if (!std::isfinite(estimation)) { erreurMax = INFINITY; break; }
            erreurMax = std::max(erreurMax, std::fabs(estimation) / echelle);
        }
        if (erreurMax <= 1.0 || std::fabs(h) < 1e-14) {
            std::array<std::vector<double>, 5> c;
            for (int j = 0; j < 5; ++j) c[j].assign(n, 0.0);
            for (std::size_t i = 0; i < n; ++i) {
                double delta = suivant.re[i] - y.re[i];
                c[0][i] = y.re[i];
                c[1][i] = delta;
                c[2][i] = h * k1.re[i] - delta;
                c[3][i] = delta - h * k7.re[i] - c[2][i];
                c[4][i] = h * (d1 * k1.re[i] + d3 * k3.re[i] + d4 * k4.re[i] +
                               d5 * k5.re[i] + d6 * k6.re[i] + d7 * k7.re[i]);
            }
            double tSuivant = t + h;
            if (evenements.actif) {
                std::vector<double> gSuivant = evenements.valeurs(tSuivant, suivant);
                double thetaArret = 2.0;
                for (std::size_t e = 0; e < gSuivant.size() && e < gPrecedent.size(); ++e) {
                    double avant = gPrecedent[e], apres = gSuivant[e];
                    bool traverse = (avant == 0.0 && pas > 1) ? false
                                                             : (avant * apres < 0.0 || apres == 0.0);
                    if (!traverse) continue;
                    double sensTraversee = (apres > avant) ? 1.0 : -1.0;
                    double voulu = e < evenements.direction.size() ? evenements.direction[e] : 0.0;
                    if (voulu != 0.0 && voulu != sensTraversee) continue;
                    // Dichotomie sur l'interpolant : la racine est
                    // localisee a la precision machine sans nouveau pas.
                    double bas = 0.0, haut = 1.0;
                    double gBas = avant;
                    for (int iter = 0; iter < 60; ++iter) {
                        double milieu = (bas + haut) / 2;
                        Valeur yMilieu = interpoler(c, milieu);
                        std::vector<double> gMilieu =
                            evenements.valeurs(t + milieu * h, yMilieu);
                        if (gMilieu[e] == 0.0) { bas = milieu; haut = milieu; break; }
                        if (gBas * gMilieu[e] < 0) {
                            haut = milieu;
                        } else {
                            bas = milieu;
                            gBas = gMilieu[e];
                        }
                    }
                    double theta = (bas + haut) / 2;
                    Valeur yRacine = interpoler(c, theta);
                    tEvenements.push_back(t + theta * h);
                    yEvenements.push_back(yRacine);
                    iEvenements.push_back((double)(e + 1));
                    double estArret = e < evenements.terminal.size() ? evenements.terminal[e] : 0.0;
                    if (estArret != 0.0) thetaArret = std::min(thetaArret, theta);
                }
                gPrecedent = gSuivant;
                if (thetaArret <= 1.0) {
                    // Le pas est tronque a l'instant de l'evenement.
                    Valeur yArret = interpoler(c, thetaArret);
                    double tArret = t + thetaArret * h;
                    for (std::size_t i = 0; i < n; ++i) {
                        double delta = yArret.re[i] - y.re[i];
                        c[1][i] *= thetaArret;
                        c[2][i] = thetaArret * (h * k1.re[i]) - delta;
                        c[3][i] = delta - c[1][i] - c[2][i];
                        c[4][i] = 0.0;
                        c[1][i] = delta;
                    }
                    hPas.push_back(thetaArret * h);
                    coefficients.push_back(c);
                    t = tArret;
                    y = yArret;
                    temps.push_back(t);
                    etats.push_back(y);
                    arret = true;
                    break;
                }
            }
            hPas.push_back(h);
            coefficients.push_back(c);
            t = tSuivant;
            y = suivant;
            temps.push_back(t);
            etats.push_back(y);
        }
        double facteur = (erreurMax == 0) ? 5.0 : 0.9 * std::pow(1.0 / erreurMax, 0.2);
        if (!std::isfinite(facteur)) facteur = 0.1;
        facteur = std::min(5.0, std::max(0.1, facteur));
        h *= ordreFaible ? std::min(facteur, 2.0) : facteur;
        if (std::fabs(h) > hMax) h = sens * hMax;
    }

    // Evaluation de la solution dense en un instant quelconque.
    auto evaluerDense = [&](double td) {
        if (coefficients.empty()) return etats[0];
        std::size_t k = 0;
        while (k + 1 < temps.size() && (td - temps[k + 1]) * sens > 0) ++k;
        if (k >= coefficients.size()) k = coefficients.size() - 1;
        double theta = (hPas[k] == 0) ? 0.0 : (td - temps[k]) / hPas[k];
        return interpoler(coefficients[k], theta);
    };

    std::vector<double> tSortie;
    std::vector<Valeur> ySortie;
    if (!pointsDemandes.empty()) {
        for (double td : pointsDemandes) {
            tSortie.push_back(td);
            ySortie.push_back(evaluerDense(td));
        }
    } else if (raffinement > 1 && temps.size() > 1) {
        // Refine points intermediaires par pas, comme MATLAB : la sortie
        // suit la courbe au lieu de la relier par des cordes.
        tSortie.push_back(temps[0]);
        ySortie.push_back(etats[0]);
        for (std::size_t k = 0; k + 1 < temps.size(); ++k) {
            for (int r = 1; r <= raffinement; ++r) {
                double theta = (double)r / raffinement;
                tSortie.push_back(temps[k] + theta * hPas[k]);
                ySortie.push_back(interpoler(coefficients[k], theta));
            }
        }
    } else {
        tSortie = temps;
        ySortie = etats;
    }
    Valeur Y = Valeur::matrice((int)tSortie.size(), (int)n);
    for (std::size_t i = 0; i < ySortie.size(); ++i)
        for (std::size_t j = 0; j < n; ++j)
            Y.re[i + j * tSortie.size()] = ySortie[i].re[j];
    if (nargout <= 1) {
        Valeur sol = Valeur::structureVide();
        sol.poserChamp("solver", Valeur::texte(ordreFaible ? "ode23" : "ode45"));
        sol.poserChamp("x", Valeur::ligne(temps));
        Valeur Ycomplet = Valeur::matrice((int)n, (int)temps.size());
        for (std::size_t i = 0; i < temps.size(); ++i)
            for (std::size_t j = 0; j < n; ++j)
                Ycomplet.re[j + i * n] = etats[i].re[j];
        sol.poserChamp("y", Ycomplet);
        // Coefficients de la sortie dense, ranges en cinq matrices n x pas.
        Valeur donnees = Valeur::structureVide();
        for (int j = 0; j < 5; ++j) {
            Valeur C = Valeur::matrice((int)n, (int)coefficients.size());
            for (std::size_t k = 0; k < coefficients.size(); ++k)
                for (std::size_t i = 0; i < n; ++i)
                    C.re[i + k * n] = coefficients[k][j][i];
            donnees.poserChamp(std::string("c") + char('1' + j), C);
        }
        donnees.poserChamp("h", Valeur::ligne(hPas));
        sol.poserChamp("idata", donnees);
        if (!tEvenements.empty()) {
            sol.poserChamp("xe", Valeur::ligne(tEvenements));
            Valeur Ye = Valeur::matrice((int)n, (int)tEvenements.size());
            for (std::size_t i = 0; i < tEvenements.size(); ++i)
                for (std::size_t j = 0; j < n; ++j)
                    Ye.re[j + i * n] = yEvenements[i].re[j];
            sol.poserChamp("ye", Ye);
            sol.poserChamp("ie", Valeur::ligne(iEvenements));
        }
        return {sol};
    }
    std::vector<Valeur> sorties{Valeur::colonne(tSortie), Y};
    if (nargout >= 3) {
        sorties.push_back(Valeur::colonne(tEvenements));
        Valeur Ye = Valeur::matrice((int)tEvenements.size(), (int)n);
        for (std::size_t i = 0; i < tEvenements.size(); ++i)
            for (std::size_t j = 0; j < n; ++j)
                Ye.re[i + j * tEvenements.size()] = yEvenements[i].re[j];
        sorties.push_back(Ye);
        sorties.push_back(Valeur::colonne(iEvenements));
    }
    return sorties;
}

// Evaluation d'une solution rendue par un solveur, en des instants
// quelconques.
FONCTION(fnDeval) {
    INUTILISE
    exigerArguments(args, 2, 3, "deval");
    Valeur sol = args[0];
    Valeur points = versDouble(args[1]);
    std::size_t indexComposante = 0;
    bool uneComposante = false;
    if (args.size() > 2 && !args[2].estVide()) {
        indexComposante = (std::size_t)args[2].scal();
        uneComposante = true;
    }
    if (!sol.estStructure() || !sol.aChamp("x") || !sol.aChamp("y"))
        erreur("MATLAB:deval:BadSolution", "The first argument must be a solution structure.");
    Valeur X = versDouble(sol.champ("x"));
    Valeur Y = versDouble(sol.champ("y"));
    std::size_t n = (std::size_t)Y.nlignes();
    std::size_t nPas = X.nelem();
    std::vector<double> temps(X.re.begin(), X.re.end());
    bool dense = sol.aChamp("idata");
    Valeur idata;
    if (dense) idata = sol.champ("idata");
    bool cinqCoefficients = dense && idata.estStructure() && idata.aChamp("c1") && idata.aChamp("h");
    bool hermite = dense && idata.estStructure() && idata.aChamp("yp");
    std::size_t nSortie = uneComposante ? 1 : n;
    Valeur R = Valeur::matrice((int)nSortie, (int)points.nelem());
    for (std::size_t q = 0; q < points.nelem(); ++q) {
        double td = points.re[q];
        std::size_t k = 0;
        double sens = (nPas > 1 && temps.back() < temps.front()) ? -1.0 : 1.0;
        while (k + 1 < nPas && (td - temps[k + 1]) * sens > 0) ++k;
        std::vector<double> valeur(n, 0.0);
        if (cinqCoefficients) {
            Valeur h = versDouble(idata.champ("h"));
            std::size_t kc = std::min(k, (std::size_t)std::max<int>(0, (int)h.nelem() - 1));
            double pasCourant = h.nelem() ? h.re[kc] : 0.0;
            double theta = (pasCourant == 0) ? 0.0 : (td - temps[kc]) / pasCourant;
            double s = 1.0 - theta;
            std::vector<Valeur> C;
            for (int j = 0; j < 5; ++j)
                C.push_back(versDouble(idata.champ(std::string("c") + char('1' + j))));
            for (std::size_t i = 0; i < n; ++i) {
                double c1 = C[0].re[i + kc * n], c2 = C[1].re[i + kc * n];
                double c3 = C[2].re[i + kc * n], c4 = C[3].re[i + kc * n];
                double c5 = C[4].re[i + kc * n];
                valeur[i] = c1 + theta * (c2 + s * (c3 + theta * (c4 + s * c5)));
            }
        } else if (hermite) {
            // Cubique d'Hermite : elle raccorde valeurs et derivees aux
            // deux bouts du pas, donc elle est exacte a l'ordre trois.
            Valeur YP = versDouble(idata.champ("yp"));
            std::size_t k1 = std::min(k + 1, nPas - 1);
            double large = temps[k1] - temps[k];
            double theta = (large == 0) ? 0.0 : (td - temps[k]) / large;
            double h00 = (1 + 2 * theta) * (1 - theta) * (1 - theta);
            double h10 = theta * (1 - theta) * (1 - theta);
            double h01 = theta * theta * (3 - 2 * theta);
            double h11 = theta * theta * (theta - 1);
            for (std::size_t i = 0; i < n; ++i)
                valeur[i] = h00 * Y.re[i + k * n] + h10 * large * YP.re[i + k * n] +
                            h01 * Y.re[i + k1 * n] + h11 * large * YP.re[i + k1 * n];
        } else {
            // Interpolation lineaire entre les deux pas encadrants, faute
            // de coefficients de sortie dense.
            std::size_t k1 = std::min(k + 1, nPas - 1);
            double denominateur = temps[k1] - temps[k];
            double frac = (denominateur == 0) ? 0.0 : (td - temps[k]) / denominateur;
            for (std::size_t i = 0; i < n; ++i)
                valeur[i] = Y.re[i + k * n] + frac * (Y.re[i + k1 * n] - Y.re[i + k * n]);
        }
        if (uneComposante) {
            if (indexComposante < 1 || indexComposante > n)
                erreur("MATLAB:deval:BadIndex", "Component index out of range.");
            R.re[q] = valeur[indexComposante - 1];
        } else {
            for (std::size_t i = 0; i < n; ++i) R.re[i + q * nSortie] = valeur[i];
        }
    }
    return {R};
}

// -------------------------------------------- equations differentielles raides
//
// Un probleme est raide quand ses echelles de temps sont tres separees :
// un solveur explicite y prend alors des pas dictes par la stabilite et
// non par la precision, et n'avance plus. Les methodes qui suivent sont
// implicites. Chaque pas resout un systeme non lineaire par Newton, avec
// une jacobienne calculee par differences finies avant.

// Elimination de Gauss a pivot partiel. La matrice est rangee par
// colonnes ; la permutation des lignes reste logique, on ne deplace rien.
bool resoudreDense(std::vector<double>& a, std::vector<double>& b, std::size_t n) {
    std::vector<std::size_t> ordre(n);
    for (std::size_t i = 0; i < n; ++i) ordre[i] = i;
    for (std::size_t k = 0; k < n; ++k) {
        std::size_t meilleur = k;
        double pivot = std::fabs(a[ordre[k] + k * n]);
        for (std::size_t i = k + 1; i < n; ++i) {
            double v = std::fabs(a[ordre[i] + k * n]);
            if (v > pivot) {
                pivot = v;
                meilleur = i;
            }
        }
        if (!(pivot > 0.0)) return false;
        std::swap(ordre[k], ordre[meilleur]);
        for (std::size_t i = k + 1; i < n; ++i) {
            double facteur = a[ordre[i] + k * n] / a[ordre[k] + k * n];
            for (std::size_t j = k + 1; j < n; ++j)
                a[ordre[i] + j * n] -= facteur * a[ordre[k] + j * n];
            b[ordre[i]] -= facteur * b[ordre[k]];
        }
    }
    std::vector<double> x(n, 0.0);
    for (std::size_t ii = n; ii-- > 0;) {
        double somme = b[ordre[ii]];
        for (std::size_t j = ii + 1; j < n; ++j) somme -= a[ordre[ii] + j * n] * x[j];
        x[ii] = somme / a[ordre[ii] + ii * n];
    }
    b = x;
    return true;
}

struct EDORaide {
    Interpreteur* it = nullptr;
    Valeur f;
    std::size_t n = 0;
    // Masse : le systeme s'ecrit M(t,y) y' = f(t,y).
    Valeur masse;
    bool masseConstante = false;
    // Jacobienne fournie par l'utilisateur : matrice constante, ou
    // fonction de (t,y). Sans elle, elle est calculee par differences.
    Valeur jacobienneFournie;
    // Motif de creux : les entrees hors motif sont structurellement
    // nulles, et les colonnes qui ne se recouvrent pas se calculent d'une
    // seule evaluation.
    std::vector<char> motif;

    std::vector<double> evaluer(double t, const std::vector<double>& y) {
        std::vector<Valeur> a = {Valeur::scalaire(t), Valeur::colonne(y)};
        auto r = it->appelerValeur(f, a, 1);
        if (r.empty()) erreur("MATLAB:ode:BadFunction", "The ODE function returned nothing.");
        Valeur d = versDouble(r[0]);
        std::vector<double> s(n, 0.0);
        for (std::size_t k = 0; k < n && k < d.re.size(); ++k) s[k] = d.re[k];
        appliquerMasse(t, y, s);
        return s;
    }

    void appliquerMasse(double t, const std::vector<double>& y, std::vector<double>& s) {
        if (masse.estVide()) return;
        Valeur M;
        if (masseConstante) {
            M = versDouble(masse);
        } else {
            std::vector<Valeur> a = {Valeur::scalaire(t), Valeur::colonne(y)};
            auto r = it->appelerValeur(masse, a, 1);
            if (r.empty()) erreur("MATLAB:ode:BadMass", "The mass function returned nothing.");
            M = versDouble(r[0]);
        }
        if (M.re.size() != n * n)
            erreur("MATLAB:ode:BadMass", "The mass matrix has the wrong size.");
        std::vector<double> A(M.re.begin(), M.re.end());
        if (!resoudreDense(A, s, n))
            erreur("MATLAB:ode:SingularMass", "The mass matrix is singular.");
    }

    // Jacobienne par differences avant. Le pas suit MATLAB : racine de
    // l'epsilon machine, mise a l'echelle de la composante. Quand
    // l'utilisateur la fournit, on la prend telle quelle ; quand il donne
    // un motif de creux, les colonnes disjointes sont groupees, ce qui
    // ramene le nombre d'evaluations au nombre de groupes.
    void jacobienne(double t, const std::vector<double>& y, const std::vector<double>& f0,
                    std::vector<double>& J) {
        if (!jacobienneFournie.estVide()) {
            Valeur Jv;
            if (jacobienneFournie.estFonction()) {
                std::vector<Valeur> a = {Valeur::scalaire(t), Valeur::colonne(y)};
                auto r = it->appelerValeur(jacobienneFournie, a, 1);
                if (r.empty())
                    erreur("MATLAB:ode:BadJacobian", "The Jacobian function returned nothing.");
                Jv = versDouble(r[0]);
            } else {
                Jv = versDouble(jacobienneFournie);
            }
            if (Jv.re.size() != n * n)
                erreur("MATLAB:ode:BadJacobian", "The Jacobian has the wrong size.");
            J.assign(Jv.re.begin(), Jv.re.end());
            return;
        }
        J.assign(n * n, 0.0);
        std::vector<std::vector<std::size_t>> groupes = grouperColonnes();
        std::vector<double> yp = y;
        for (const auto& groupe : groupes) {
            std::vector<double> pasParColonne(groupe.size(), 0.0);
            std::vector<double> effectifs(groupe.size(), 0.0);
            for (std::size_t g = 0; g < groupe.size(); ++g) {
                std::size_t j = groupe[g];
                double sauve = y[j];
                double pas = 1.4901161193847656e-08 * std::max(std::fabs(sauve), 1e-3);
                yp[j] = sauve + pas;
                effectifs[g] = yp[j] - sauve;   // le pas reellement pris apres arrondi
                pasParColonne[g] = pas;
            }
            std::vector<double> f1 = evaluer(t, yp);
            for (std::size_t g = 0; g < groupe.size(); ++g) {
                std::size_t j = groupe[g];
                yp[j] = y[j];
                for (std::size_t i = 0; i < n; ++i) {
                    if (!motif.empty() && !motif[i + j * n]) continue;
                    J[i + j * n] = (f1[i] - f0[i]) / effectifs[g];
                }
            }
        }
    }

    // Groupement de colonnes : deux colonnes dont les lignes non nulles
    // sont disjointes peuvent etre perturbees ensemble sans se melanger.
    std::vector<std::vector<std::size_t>> grouperColonnes() {
        std::vector<std::vector<std::size_t>> groupes;
        if (motif.empty()) {
            for (std::size_t j = 0; j < n; ++j) groupes.push_back({j});
            return groupes;
        }
        std::vector<std::vector<char>> occupees;
        for (std::size_t j = 0; j < n; ++j) {
            bool place = false;
            for (std::size_t g = 0; g < groupes.size() && !place; ++g) {
                bool libre = true;
                for (std::size_t i = 0; i < n && libre; ++i)
                    if (motif[i + j * n] && occupees[g][i]) libre = false;
                if (libre) {
                    groupes[g].push_back(j);
                    for (std::size_t i = 0; i < n; ++i)
                        if (motif[i + j * n]) occupees[g][i] = 1;
                    place = true;
                }
            }
            if (!place) {
                groupes.push_back({j});
                occupees.push_back(std::vector<char>(n, 0));
                for (std::size_t i = 0; i < n; ++i)
                    if (motif[i + j * n]) occupees.back()[i] = 1;
            }
        }
        return groupes;
    }

    double deriveeTemps(double t, const std::vector<double>& y,
                        const std::vector<double>& f0, std::vector<double>& T) {
        double pas = 1.4901161193847656e-08 * std::max(std::fabs(t), 1e-3);
        std::vector<double> f1 = evaluer(t + pas, y);
        T.assign(n, 0.0);
        for (std::size_t i = 0; i < n; ++i) T[i] = (f1[i] - f0[i]) / pas;
        return pas;
    }
};

double normeEchelle(const std::vector<double>& e, const std::vector<double>& y,
                    const std::vector<double>& yPrecedent, double tolRel, double tolAbs) {
    double pire = 0.0;
    for (std::size_t i = 0; i < e.size(); ++i) {
        if (!std::isfinite(e[i])) return INFINITY;   // un NaN n'est pas une petite erreur
        double echelle = tolAbs + tolRel * std::max(std::fabs(y[i]), std::fabs(yPrecedent[i]));
        pire = std::max(pire, std::fabs(e[i]) / echelle);
    }
    return pire;
}

// Poids de la derivee du polynome de Lagrange au premier noeud : c'est ce
// qui donne les coefficients d'une BDF a pas variable, sans supposer un
// pas constant ni redemarrer a l'ordre 1 apres chaque changement de pas.
void poidsBDF(const std::vector<double>& noeuds, std::vector<double>& alpha) {
    std::size_t m = noeuds.size();
    alpha.assign(m, 0.0);
    double t0 = noeuds[0];
    double somme = 0.0;
    for (std::size_t j = 1; j < m; ++j) somme += 1.0 / (t0 - noeuds[j]);
    alpha[0] = somme;
    for (std::size_t i = 1; i < m; ++i) {
        double haut = 1.0, bas = 1.0;
        for (std::size_t j = 1; j < m; ++j)
            if (j != i) haut *= (t0 - noeuds[j]);
        for (std::size_t j = 0; j < m; ++j)
            if (j != i) bas *= (noeuds[i] - noeuds[j]);
        alpha[i] = haut / bas;
    }
}

// Valeur en T du polynome interpolant les couples (noeuds, valeurs).
void extrapolerLagrange(const std::vector<double>& noeuds,
                        const std::vector<std::vector<double>>& valeurs, double t,
                        std::vector<double>& sortie) {
    std::size_t m = noeuds.size();
    std::size_t n = valeurs.empty() ? 0 : valeurs[0].size();
    sortie.assign(n, 0.0);
    for (std::size_t i = 0; i < m; ++i) {
        double poids = 1.0;
        for (std::size_t j = 0; j < m; ++j)
            if (j != i) poids *= (t - noeuds[j]) / (noeuds[i] - noeuds[j]);
        for (std::size_t k = 0; k < n; ++k) sortie[k] += poids * valeurs[i][k];
    }
}

enum class MethodeRaide { BDF, Rosenbrock, Trapeze, TrBdf2 };

std::vector<Valeur> resoudreEDORaide(Interpreteur& it, std::vector<Valeur>& args, int nargout,
                                     MethodeRaide methode, const char* nom) {
    exigerArguments(args, 3, 4, nom);
    EDORaide p;
    p.it = &it;
    p.f = args[0];
    const Valeur& intervalle = args[1];
    Valeur depart = versDouble(args[2]);
    p.n = depart.nelem();
    if (p.n == 0) erreur("MATLAB:ode:EmptyInitial", "The initial condition is empty.");
    std::vector<double> y(p.n, 0.0);
    for (std::size_t k = 0; k < p.n; ++k) y[k] = depart.re[k];

    double t0 = intervalle.re[0];
    double tf = intervalle.re[intervalle.nelem() - 1];
    std::vector<double> pointsDemandes;
    if (intervalle.nelem() > 2)
        for (std::size_t k = 0; k < intervalle.nelem(); ++k)
            pointsDemandes.push_back(intervalle.re[k]);
    // Les tolerances par defaut sont celles des autres solveurs du module.
    double tolRel = lireOption(args, 3, "RelTol", 1e-6);
    double tolAbs = lireOption(args, 3, "AbsTol", 1e-9);
    double sens = (tf >= t0) ? 1.0 : -1.0;
    double etendue = std::fabs(tf - t0);
    double hMax = lireOption(args, 3, "MaxStep", etendue > 0 ? etendue / 10.0 : 1.0);
    double h = lireOption(args, 3, "InitialStep", 0.0);
    if (!(h > 0)) h = std::min(hMax, etendue > 0 ? etendue / 1000.0 : 1e-3);
    if (h <= 0) h = 1e-3;
    int ordreMaximum = (int)lireOption(args, 3, "MaxOrder", 5.0);
    ordreMaximum = std::min(5, std::max(1, ordreMaximum));

    // Masse, jacobienne fournie et motif de creux.
    p.masse = lireOptionValeur(args, 3, "Mass");
    p.masseConstante = !p.masse.estVide() && !p.masse.estFonction();
    p.jacobienneFournie = lireOptionValeur(args, 3, "Jacobian");
    Valeur motif = lireOptionValeur(args, 3, "JPattern");
    if (!motif.estVide()) {
        Valeur M = versDouble(motif);
        if (M.re.size() == p.n * p.n) {
            p.motif.assign(p.n * p.n, 0);
            for (std::size_t k = 0; k < p.n * p.n; ++k)
                p.motif[k] = (M.re[k] != 0.0) ? 1 : 0;
        }
    }
    // Evenements : meme convention que pour ode45.
    EvenementsEDO evenements;
    Valeur fonctionEvenements = lireOptionValeur(args, 3, "Events");
    if (!fonctionEvenements.estVide()) {
        evenements.it = &it;
        evenements.f = fonctionEvenements;
        evenements.actif = true;
    }
    std::vector<double> gPrecedent;
    if (evenements.actif) gPrecedent = evenements.valeurs(t0, Valeur::colonne(y));
    std::vector<double> tEvenements;
    std::vector<std::vector<double>> yEvenements;
    std::vector<double> iEvenements;
    bool arretEvenement = false;

    std::vector<double> temps = {t0};
    std::vector<std::vector<double>> etats = {y};
    std::vector<double> f0 = p.evaluer(t0, y);
    // Les derivees aux points de sortie permettent une interpolation
    // cubique d'Hermite, exacte a l'ordre trois, la ou une corde ne l'est
    // qu'a l'ordre un.
    std::vector<std::vector<double>> derivees = {f0};
    std::vector<double> J, T, alpha, prediction;

    const double d = 1.0 / (2.0 + std::sqrt(2.0));       // Rosenbrock (2,3)
    const double e32 = 6.0 + std::sqrt(2.0);
    const double gamma = 2.0 - std::sqrt(2.0);           // TR-BDF2

    // Toutes les methodes implicites d'ici resolvent la meme forme :
    //     c0 * x - coefF * f(t1, x) = reste.
    // Newton s'arrete des qu'il diverge : raccourcir le pas rend la
    // matrice c0*I - coefF*J diagonalement dominante, et fait mieux que
    // s'acharner sur une jacobienne perimee.
    auto newton = [&](double c0, double coefF, double t1, const std::vector<double>& reste,
                      std::vector<double>& x) -> bool {
        double amplitudePrecedente = INFINITY;
        for (int iteration = 0; iteration < 20; ++iteration) {
            std::vector<double> fCourant = p.evaluer(t1, x);
            for (std::size_t i = 0; i < p.n; ++i)
                if (!std::isfinite(fCourant[i])) return false;
            std::vector<double> M(p.n * p.n, 0.0), correction(p.n, 0.0);
            for (std::size_t i = 0; i < p.n; ++i)
                for (std::size_t j = 0; j < p.n; ++j)
                    M[i + j * p.n] = (i == j ? c0 : 0.0) - coefF * J[i + j * p.n];
            for (std::size_t i = 0; i < p.n; ++i)
                correction[i] = -(c0 * x[i] - coefF * fCourant[i] - reste[i]);
            if (!resoudreDense(M, correction, p.n)) return false;
            double amplitude = 0.0;
            for (std::size_t i = 0; i < p.n; ++i) {
                x[i] += correction[i];
                if (!std::isfinite(x[i])) return false;
                double echelle = tolAbs + tolRel * std::fabs(x[i]);
                amplitude = std::max(amplitude, std::fabs(correction[i]) / echelle);
            }
            if (amplitude < 0.05) return true;
            if (iteration > 0 && amplitude > 2.0 * amplitudePrecedente) return false;
            amplitudePrecedente = amplitude;
        }
        return false;
    };

    double t = t0;
    int pasFaits = 0;
    int refusConsecutifs = 0;
    // La BDF n'est zero-stable a l'ordre eleve que si les pas voisins se
    // ressemblent. On ne monte donc en ordre qu'apres autant de pas
    // acceptes que d'ordre vise, et le compteur repart de zero des qu'un
    // pas est refuse.
    int pasStables = 0;
    const int maxPas = 500000;
    while ((tf - t) * sens > 1e-14 * std::max(1.0, std::fabs(tf)) && pasFaits < maxPas) {
        if ((t + sens * h - tf) * sens > 0) h = std::fabs(tf - t);
        double pas = sens * h;
        if (t + pas == t)
            erreur("MATLAB:ode:UnableToMeetTolerances",
                   "Unable to meet integration tolerances without reducing the step size "
                   "below the smallest value allowed.");
        std::vector<double> yNouveau = y, erreurLocale(p.n, 0.0);
        bool reussi = false;
        int ordre = 1;

        p.jacobienne(t, y, f0, J);

        if (methode == MethodeRaide::Rosenbrock) {
            ordre = 2;
            p.deriveeTemps(t, y, f0, T);
            std::vector<double> W(p.n * p.n, 0.0);
            for (std::size_t i = 0; i < p.n; ++i)
                for (std::size_t j = 0; j < p.n; ++j)
                    W[i + j * p.n] = (i == j ? 1.0 : 0.0) - pas * d * J[i + j * p.n];
            std::vector<double> k1(p.n);
            for (std::size_t i = 0; i < p.n; ++i) k1[i] = f0[i] + pas * d * T[i];
            std::vector<double> copie = W;
            if (resoudreDense(copie, k1, p.n)) {
                std::vector<double> milieu(p.n);
                for (std::size_t i = 0; i < p.n; ++i) milieu[i] = y[i] + 0.5 * pas * k1[i];
                std::vector<double> f1 = p.evaluer(t + 0.5 * pas, milieu);
                std::vector<double> k2(p.n);
                for (std::size_t i = 0; i < p.n; ++i) k2[i] = f1[i] - k1[i];
                copie = W;
                if (resoudreDense(copie, k2, p.n)) {
                    for (std::size_t i = 0; i < p.n; ++i) k2[i] += k1[i];
                    for (std::size_t i = 0; i < p.n; ++i) yNouveau[i] = y[i] + pas * k2[i];
                    std::vector<double> f2 = p.evaluer(t + pas, yNouveau);
                    std::vector<double> k3(p.n);
                    for (std::size_t i = 0; i < p.n; ++i)
                        k3[i] = f2[i] - e32 * (k2[i] - f1[i]) - 2.0 * (k1[i] - f0[i]) +
                                pas * d * T[i];
                    copie = W;
                    if (resoudreDense(copie, k3, p.n)) {
                        for (std::size_t i = 0; i < p.n; ++i)
                            erreurLocale[i] = pas / 6.0 * (k1[i] - 2.0 * k2[i] + k3[i]);
                        reussi = true;
                    }
                }
            }
        } else if (methode == MethodeRaide::BDF) {
            std::size_t dispo = temps.size();
            std::size_t k = std::min<std::size_t>((std::size_t)ordreMaximum, dispo);
            k = std::min<std::size_t>(k, (std::size_t)pasStables + 1);
            if (k < 1) k = 1;
            ordre = (int)k;
            double t1 = t + pas;
            std::vector<double> noeuds = {t1};
            for (std::size_t j = 0; j < k; ++j) noeuds.push_back(temps[temps.size() - 1 - j]);
            poidsBDF(noeuds, alpha);
            std::vector<double> reste(p.n, 0.0);
            for (std::size_t i = 0; i < p.n; ++i) {
                double somme = 0.0;
                for (std::size_t j = 1; j < alpha.size(); ++j)
                    somme += alpha[j] * etats[etats.size() - j][i];
                reste[i] = -somme;
            }
            // Predicteur : le polynome passant par les k+1 derniers points,
            // extrapole en t1. Son erreur est du meme ordre que celle du
            // correcteur, ce qui en fait une estimation de l'erreur locale.
            std::size_t m = std::min<std::size_t>(k + 1, dispo);
            std::vector<double> noeudsPred(m);
            std::vector<std::vector<double>> valeursPred(m);
            for (std::size_t j = 0; j < m; ++j) {
                noeudsPred[j] = temps[temps.size() - 1 - j];
                valeursPred[j] = etats[etats.size() - 1 - j];
            }
            extrapolerLagrange(noeudsPred, valeursPred, t1, prediction);
            yNouveau = prediction;
            if (newton(alpha[0], 1.0, t1, reste, yNouveau)) {
                for (std::size_t i = 0; i < p.n; ++i)
                    erreurLocale[i] = (yNouveau[i] - prediction[i]) / (ordre + 1.0);
                reussi = true;
            }
        } else {
            ordre = 2;
            double t1 = t + pas;
            std::vector<double> reste(p.n, 0.0);
            double c0 = 1.0, coefF = 0.5 * pas;
            if (methode == MethodeRaide::Trapeze) {
                for (std::size_t i = 0; i < p.n; ++i) reste[i] = y[i] + 0.5 * pas * f0[i];
            } else {
                // TR-BDF2 : trapeze jusqu'a t + gamma*h, puis BDF2 sur le
                // reste du pas. Les deux etages partagent la jacobienne.
                double h1 = gamma * pas;
                std::vector<double> restePremier(p.n), yEtoile = y;
                for (std::size_t i = 0; i < p.n; ++i)
                    restePremier[i] = y[i] + 0.5 * h1 * f0[i];
                if (!newton(1.0, 0.5 * h1, t + h1, restePremier, yEtoile)) {
                    ++refusConsecutifs;
                    pasStables = 0;
                    h *= 0.25;
                    if (refusConsecutifs > 200)
                        erreur("MATLAB:ode:UnableToMeetTolerances",
                               "Unable to meet integration tolerances without reducing the "
                               "step size below the smallest value allowed.");
                    continue;
                }
                double denom = gamma * (2.0 - gamma);
                coefF = (1.0 - gamma) / (2.0 - gamma) * pas;
                for (std::size_t i = 0; i < p.n; ++i)
                    reste[i] = yEtoile[i] / denom -
                               ((1.0 - gamma) * (1.0 - gamma) / denom) * y[i];
            }
            yNouveau = y;
            if (newton(c0, coefF, t1, reste, yNouveau)) {
                // Euler implicite au meme pas donne la solution d'ordre
                // un. L'ecart majore l'erreur locale du schema d'ordre
                // deux : l'estimation est prudente, le pas retenu plus
                // court que necessaire.
                std::vector<double> yEuler = yNouveau;
                if (newton(1.0, pas, t1, y, yEuler)) {
                    for (std::size_t i = 0; i < p.n; ++i)
                        erreurLocale[i] = 0.25 * (yNouveau[i] - yEuler[i]);
                    reussi = true;
                }
            }
        }

        if (reussi)
            for (std::size_t i = 0; i < p.n; ++i)
                if (!std::isfinite(yNouveau[i])) reussi = false;

        double mesure = reussi ? normeEchelle(erreurLocale, yNouveau, y, tolRel, tolAbs)
                               : INFINITY;
        static const bool tracer = std::getenv("MATLIBRE_ODE_TRACE") != nullptr;
        if (tracer)
            std::fprintf(stderr, "%s t=%.6g h=%.3g ordre=%d mesure=%.3g %s\n", nom, t, h, ordre,
                         mesure, (reussi && mesure <= 1.0) ? "ok" : "refuse");

        if (reussi && mesure <= 1.0) {
            double tNouveau = t + pas;
            std::vector<double> fNouveau = p.evaluer(tNouveau, yNouveau);
            // Interpolation cubique d'Hermite dans le pas qui vient d'etre
            // accepte : elle sert a placer les evenements.
            auto interpolerPas = [&](double theta) {
                std::vector<double> r(p.n, 0.0);
                double h00 = (1 + 2 * theta) * (1 - theta) * (1 - theta);
                double h10 = theta * (1 - theta) * (1 - theta);
                double h01 = theta * theta * (3 - 2 * theta);
                double h11 = theta * theta * (theta - 1);
                for (std::size_t i = 0; i < p.n; ++i)
                    r[i] = h00 * y[i] + h10 * pas * f0[i] + h01 * yNouveau[i] +
                           h11 * pas * fNouveau[i];
                return r;
            };
            if (evenements.actif) {
                std::vector<double> gSuivant =
                    evenements.valeurs(tNouveau, Valeur::colonne(yNouveau));
                double thetaArret = 2.0;
                for (std::size_t e = 0; e < gSuivant.size() && e < gPrecedent.size(); ++e) {
                    double avant = gPrecedent[e], apres = gSuivant[e];
                    bool traverse = (avant == 0.0 && pasFaits > 0)
                                        ? false
                                        : (avant * apres < 0.0 || apres == 0.0);
                    if (!traverse) continue;
                    double sensTraversee = (apres > avant) ? 1.0 : -1.0;
                    double voulu =
                        e < evenements.direction.size() ? evenements.direction[e] : 0.0;
                    if (voulu != 0.0 && voulu != sensTraversee) continue;
                    double bas = 0.0, haut = 1.0, gBas = avant;
                    for (int iter = 0; iter < 60; ++iter) {
                        double milieu = (bas + haut) / 2;
                        std::vector<double> yMilieu = interpolerPas(milieu);
                        std::vector<double> gMilieu =
                            evenements.valeurs(t + milieu * pas, Valeur::colonne(yMilieu));
                        if (gMilieu[e] == 0.0) { bas = milieu; haut = milieu; break; }
                        if (gBas * gMilieu[e] < 0) {
                            haut = milieu;
                        } else {
                            bas = milieu;
                            gBas = gMilieu[e];
                        }
                    }
                    double theta = (bas + haut) / 2;
                    tEvenements.push_back(t + theta * pas);
                    yEvenements.push_back(interpolerPas(theta));
                    iEvenements.push_back((double)(e + 1));
                    double estArret =
                        e < evenements.terminal.size() ? evenements.terminal[e] : 0.0;
                    if (estArret != 0.0) thetaArret = std::min(thetaArret, theta);
                }
                gPrecedent = gSuivant;
                if (thetaArret <= 1.0) {
                    std::vector<double> yArret = interpolerPas(thetaArret);
                    t = t + thetaArret * pas;
                    y = yArret;
                    f0 = p.evaluer(t, y);
                    temps.push_back(t);
                    etats.push_back(y);
                    derivees.push_back(f0);
                    ++pasFaits;
                    arretEvenement = true;
                    break;
                }
            }
            t = tNouveau;
            y = yNouveau;
            f0 = fNouveau;
            temps.push_back(t);
            etats.push_back(y);
            derivees.push_back(f0);
            ++pasFaits;
            refusConsecutifs = 0;
            ++pasStables;
            double exposant = 1.0 / (ordre + 1.0);
            double facteur = (mesure <= 0) ? 5.0 : 0.9 * std::pow(1.0 / mesure, exposant);
            double plafond = (methode == MethodeRaide::BDF) ? 2.0 : 5.0;
            facteur = std::min(plafond, std::max(0.2, facteur));
            // Bande morte autour de 1 : laisser le pas tranquille aide la
            // stabilite de la BDF et evite de recalculer pour rien.
            if (facteur > 1.0 && facteur < 1.2) facteur = 1.0;
            if (facteur < 1.0 && facteur > 0.9) facteur = 1.0;
            h *= facteur;
            if (h > hMax) h = hMax;
        } else {
            ++refusConsecutifs;
            pasStables = 0;
            double facteur = std::isfinite(mesure)
                                 ? 0.9 * std::pow(1.0 / mesure, 1.0 / (ordre + 1.0))
                                 : 0.25;
            h *= std::min(0.9, std::max(0.1, facteur));
            if (refusConsecutifs > 200)
                erreur("MATLAB:ode:UnableToMeetTolerances",
                       "Unable to meet integration tolerances without reducing the step size "
                       "below the smallest value allowed.");
        }
    }

    // Sortie : les pas internes, ou les instants demandes par interpolation
    // lineaire entre deux pas.
    std::vector<double> tSortie;
    std::vector<std::vector<double>> ySortie;
    if (pointsDemandes.empty()) {
        tSortie = temps;
        ySortie = etats;
    } else {
        for (double td : pointsDemandes) {
            std::size_t k = 0;
            while (k + 1 < temps.size() && (temps[k + 1] - td) * sens < 0) ++k;
            if (k + 1 >= temps.size()) {
                ySortie.push_back(etats.back());
            } else {
                double large = temps[k + 1] - temps[k];
                double theta = (large == 0.0) ? 0.0 : (td - temps[k]) / large;
                double h00 = (1 + 2 * theta) * (1 - theta) * (1 - theta);
                double h10 = theta * (1 - theta) * (1 - theta);
                double h01 = theta * theta * (3 - 2 * theta);
                double h11 = theta * theta * (theta - 1);
                std::vector<double> interp(p.n, 0.0);
                for (std::size_t i = 0; i < p.n; ++i)
                    interp[i] = h00 * etats[k][i] + h10 * large * derivees[k][i] +
                                h01 * etats[k + 1][i] + h11 * large * derivees[k + 1][i];
                ySortie.push_back(interp);
            }
            tSortie.push_back(td);
        }
    }
    Valeur Y = Valeur::matrice((int)tSortie.size(), (int)p.n);
    for (std::size_t i = 0; i < ySortie.size(); ++i)
        for (std::size_t j = 0; j < p.n; ++j)
            Y.re[i + j * tSortie.size()] = ySortie[i][j];
    if (nargout <= 1) {
        Valeur sol = Valeur::structureVide();
        sol.poserChamp("solver", Valeur::texte(nom));
        sol.poserChamp("x", Valeur::ligne(temps));
        Valeur Ycomplet = Valeur::matrice((int)p.n, (int)temps.size());
        for (std::size_t i = 0; i < temps.size(); ++i)
            for (std::size_t j = 0; j < p.n; ++j)
                Ycomplet.re[j + i * p.n] = etats[i][j];
        sol.poserChamp("y", Ycomplet);
        // Derivees aux memes instants : DEVAL s'en sert pour interpoler
        // par Hermite au lieu de relier les points par des cordes.
        Valeur YP = Valeur::matrice((int)p.n, (int)temps.size());
        for (std::size_t i = 0; i < temps.size(); ++i)
            for (std::size_t j = 0; j < p.n; ++j)
                YP.re[j + i * p.n] = derivees[i][j];
        Valeur donnees = Valeur::structureVide();
        donnees.poserChamp("yp", YP);
        sol.poserChamp("idata", donnees);
        if (!tEvenements.empty()) {
            sol.poserChamp("xe", Valeur::ligne(tEvenements));
            Valeur Ye = Valeur::matrice((int)p.n, (int)tEvenements.size());
            for (std::size_t i = 0; i < tEvenements.size(); ++i)
                for (std::size_t j = 0; j < p.n; ++j)
                    Ye.re[j + i * p.n] = yEvenements[i][j];
            sol.poserChamp("ye", Ye);
            sol.poserChamp("ie", Valeur::ligne(iEvenements));
        }
        return {sol};
    }
    std::vector<Valeur> sorties{Valeur::colonne(tSortie), Y};
    if (nargout >= 3) {
        sorties.push_back(Valeur::colonne(tEvenements));
        Valeur Ye = Valeur::matrice((int)tEvenements.size(), (int)p.n);
        for (std::size_t i = 0; i < tEvenements.size(); ++i)
            for (std::size_t j = 0; j < p.n; ++j)
                Ye.re[i + j * tEvenements.size()] = yEvenements[i][j];
        sorties.push_back(Ye);
        sorties.push_back(Valeur::colonne(iEvenements));
    }
    (void)arretEvenement;
    return sorties;
}

FONCTION(fnOde15s) {
    return resoudreEDORaide(it, args, nargout, MethodeRaide::BDF, "ode15s");
}
FONCTION(fnOde23s) {
    return resoudreEDORaide(it, args, nargout, MethodeRaide::Rosenbrock, "ode23s");
}
FONCTION(fnOde23t) {
    return resoudreEDORaide(it, args, nargout, MethodeRaide::Trapeze, "ode23t");
}
FONCTION(fnOde23tb) {
    return resoudreEDORaide(it, args, nargout, MethodeRaide::TrBdf2, "ode23tb");
}

FONCTION(fnOde45) { return resoudreEDO(it, args, nargout, false); }
FONCTION(fnOde23) { return resoudreEDO(it, args, nargout, true); }

// Noms canoniques des options des solveurs d'EDO. MATLAB accepte
// n'importe quelle casse ; on ramene donc chaque nom a sa forme
// officielle avant de le ranger, sans quoi odeset('reltol',...) serait
// silencieusement ignore par le solveur.
const std::vector<const char*>& nomsOptionsEDO() {
    static const std::vector<const char*> noms = {
        "RelTol", "AbsTol", "NormControl", "OutputFcn", "OutputSel", "Refine",
        "Stats", "InitialStep", "MaxStep", "Events", "Jacobian", "JPattern",
        "Vectorized", "Mass", "MStateDependence", "MvPattern", "MassSingular",
        "InitialSlope", "MaxOrder", "BDF", "NonNegative"};
    return noms;
}

std::string canoniserOptionEDO(const std::string& nom) {
    for (const char* candidat : nomsOptionsEDO()) {
        std::string c = candidat;
        if (c.size() != nom.size()) continue;
        bool egal = true;
        for (std::size_t k = 0; k < c.size() && egal; ++k)
            if (std::tolower((unsigned char)c[k]) != std::tolower((unsigned char)nom[k]))
                egal = false;
        if (egal) return c;
    }
    return nom;
}

FONCTION(fnOdeget) {
    INUTILISE
    exigerArguments(args, 2, 3, "odeget");
    std::string nom = canoniserOptionEDO(args[1].versTexte());
    if (args[0].estStructure() && args[0].aChamp(nom)) {
        Valeur v = args[0].champ(nom);
        if (!v.estVide()) return {v};
    }
    if (args.size() > 2) return {args[2]};
    return {Valeur::vide()};
}

FONCTION(fnOdeset) {
    INUTILISE
    Valeur o = Valeur::structureVide();
    std::size_t debut = 0;
    // odeset(anciennes, 'Nom', valeur, ...) part des anciennes options.
    if (!args.empty() && args[0].estStructure()) {
        o = args[0];
        debut = 1;
    }
    if (args.size() == debut && nargout == 0) {
        for (const char* nom : nomsOptionsEDO()) std::printf("%s\n", nom);
        return {};
    }
    for (std::size_t k = debut; k + 1 < args.size(); k += 2)
        o.poserChamp(canoniserOptionEDO(args[k].versTexte()), args[k + 1]);
    return {o};
}

FONCTION(fnOptimset) {
    INUTILISE
    Valeur o = Valeur::structureVide();
    for (std::size_t k = 0; k + 1 < args.size(); k += 2)
        o.poserChamp(args[k].versTexte(), args[k + 1]);
    return {o};
}

FONCTION(fnOptimget) {
    INUTILISE
    exigerArguments(args, 2, 3, "optimget");
    if (args[0].estStructure() && args[0].aChamp(args[1].versTexte()))
        return {args[0].champ(args[1].versTexte())};
    return {args.size() > 2 ? args[2] : Valeur::vide()};
}

FONCTION(fnLsqnonneg) {
    INUTILISE
    exigerArguments(args, 2, 3, "lsqnonneg");
    // Algorithme de Lawson-Hanson, version simple.
    const Valeur& A = args[0];
    const Valeur& b = args[1];
    int n = A.ncolonnes();
    Valeur x = Valeur::matrice(n, 1);
    for (int iteration = 0; iteration < 100; ++iteration) {
        Valeur residu = operationBinaire("-", b, produitMatrice(A, x));
        Valeur gradient = produitMatrice(transposer(A, true), residu);
        int meilleur = -1;
        double valeur = 1e-12;
        for (int k = 0; k < n; ++k)
            if (x.re[(std::size_t)k] == 0 && gradient.re[(std::size_t)k] > valeur) {
                valeur = gradient.re[(std::size_t)k];
                meilleur = k;
            }
        if (meilleur < 0) break;
        x.re[(std::size_t)meilleur] = 1e-8;
        Valeur solution = divisionGauche(A, b);
        for (int k = 0; k < n; ++k)
            x.re[(std::size_t)k] = std::max(0.0, solution.re[(std::size_t)k]);
    }
    return {x};
}

}  // namespace

void enregistrerOptimisation(Interpreteur& it) {
    it.enregistrer("fzero", fnFzero, "optimisation", "fzero  Zero d'une fonction scalaire.");
    it.enregistrer("fminbnd", fnFminbnd, "optimisation", "fminbnd  Minimum sur un intervalle.");
    it.enregistrer("fminsearch", fnFminsearch, "optimisation",
                   "fminsearch  Minimisation sans derivees (Nelder-Mead).");
    it.enregistrer("fminunc", fnFminunc, "optimisation", "fminunc  Minimisation sans contrainte.");
    it.enregistrer("fsolve", fnFsolve, "optimisation", "fsolve  Systeme d'equations non lineaires.");
    it.enregistrer("integral", fnIntegral, "optimisation", "integral  Quadrature adaptative.");
    it.enregistrer("quad", fnQuad, "optimisation", "quad  Quadrature de Simpson adaptative.");
    it.enregistrer("quadgk", fnQuadgk, "optimisation", "quadgk  Quadrature adaptative.");
    it.enregistrer("integral2", fnIntegral2, "optimisation", "integral2  Integrale double.");
    it.enregistrer("ode45", fnOde45, "optimisation", "ode45  Runge-Kutta Dormand-Prince 4(5).");
    it.enregistrer("ode23", fnOde23, "optimisation", "ode23  Runge-Kutta d'ordre 2(3).");
    it.enregistrer("ode113", fnOde45, "optimisation", "ode113  Solveur a pas variable.");
    it.enregistrer("odeset", fnOdeset, "optimisation", "odeset  Options des solveurs d'EDO.");
    it.enregistrer("ode15s", fnOde15s, "optimisation",
                   "ode15s  Solveur raide, BDF a pas et ordre variables.");
    it.enregistrer("ode23s", fnOde23s, "optimisation",
                   "ode23s  Solveur raide, Rosenbrock modifie (2,3).");
    it.enregistrer("ode23t", fnOde23t, "optimisation",
                   "ode23t  Solveur peu raide, regle des trapezes.");
    it.enregistrer("ode23tb", fnOde23tb, "optimisation",
                   "ode23tb  Solveur raide, trapeze puis BDF2.");
    it.enregistrer("odeget", fnOdeget, "optimisation", "odeget  Lit une option d'EDO.");
    it.enregistrer("deval", fnDeval, "optimisation", "deval  Evalue une solution d'EDO.");
    it.enregistrer("optimset", fnOptimset, "optimisation", "optimset  Options d'optimisation.");
    it.enregistrer("optimget", fnOptimget, "optimisation", "optimget  Lit une option.");
    it.enregistrer("lsqnonneg", fnLsqnonneg, "optimisation",
                   "lsqnonneg  Moindres carres a coefficients positifs.");
}

}  // namespace matlibre
