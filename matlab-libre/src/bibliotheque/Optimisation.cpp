// Optimisation.cpp — zéros, minimisation, quadrature, équations différentielles.
#include <algorithm>
#include <cmath>
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

// Dormand-Prince 4(5), le cœur de ode45.
std::vector<Valeur> resoudreEDO(Interpreteur& it, std::vector<Valeur>& args, int nargout,
                                bool ordreFaible) {
    exigerArguments(args, 3, 4, "ode45");
    Valeur f = args[0];
    const Valeur& intervalle = args[1];
    Valeur y = versDouble(args[2]);
    bool colonne = true;
    double t0 = intervalle.re[0];
    double tf = intervalle.re[intervalle.nelem() - 1];
    std::vector<double> pointsDemandes;
    if (intervalle.nelem() > 2)
        for (std::size_t k = 0; k < intervalle.nelem(); ++k)
            pointsDemandes.push_back(intervalle.re[k]);
    double tolRelative = lireOption(args, 3, "RelTol", 1e-6);
    double tolAbsolue = lireOption(args, 3, "AbsTol", 1e-9);

    auto derivee = [&](double t, const Valeur& etat) {
        std::vector<Valeur> a = {Valeur::scalaire(t), etat};
        auto r = it.appelerValeur(f, a, 1);
        if (r.empty()) erreur("MATLAB:ode45:BadFunction", "The ODE function returned nothing.");
        return versDouble(r[0]);
    };
    auto combiner = [](const Valeur& a, const Valeur& b, double coefficient) {
        Valeur r = a;
        for (std::size_t k = 0; k < r.re.size() && k < b.re.size(); ++k)
            r.re[k] += coefficient * b.re[k];
        return r;
    };

    static const double a2 = 1.0 / 5, a3 = 3.0 / 10, a4 = 4.0 / 5, a5 = 8.0 / 9;
    std::vector<double> temps = {t0};
    std::vector<Valeur> etats = {y};
    double h = (tf - t0) / 100.0;
    if (h == 0) h = 1e-3;
    double t = t0;
    int pas = 0;
    while ((tf - t) * (tf > t0 ? 1 : -1) > 0 && pas < 200000) {
        ++pas;
        if ((t + h - tf) * (tf > t0 ? 1 : -1) > 0) h = tf - t;
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
            erreurMax = std::max(erreurMax, std::fabs(estimation) / echelle);
        }
        if (erreurMax <= 1.0 || std::fabs(h) < 1e-14) {
            t += h;
            y = suivant;
            temps.push_back(t);
            etats.push_back(y);
        }
        double facteur = (erreurMax == 0) ? 5.0 : 0.9 * std::pow(1.0 / erreurMax, 0.2);
        facteur = std::min(5.0, std::max(0.1, facteur));
        h *= ordreFaible ? std::min(facteur, 2.0) : facteur;
    }

    // Sortie : soit les pas internes, soit les instants demandés.
    std::vector<double> tSortie;
    std::vector<Valeur> ySortie;
    if (pointsDemandes.empty()) {
        tSortie = temps;
        ySortie = etats;
    } else {
        for (double td : pointsDemandes) {
            std::size_t k = 0;
            while (k + 1 < temps.size() && temps[k + 1] < td) ++k;
            if (k + 1 >= temps.size()) {
                ySortie.push_back(etats.back());
            } else {
                double frac = (temps[k + 1] == temps[k])
                                  ? 0.0
                                  : (td - temps[k]) / (temps[k + 1] - temps[k]);
                Valeur interp = etats[k];
                for (std::size_t i = 0; i < interp.re.size(); ++i)
                    interp.re[i] = etats[k].re[i] +
                                   frac * (etats[k + 1].re[i] - etats[k].re[i]);
                ySortie.push_back(interp);
            }
            tSortie.push_back(td);
        }
    }
    std::size_t n = ySortie.empty() ? 0 : ySortie[0].nelem();
    Valeur Y = Valeur::matrice((int)tSortie.size(), (int)n);
    for (std::size_t i = 0; i < ySortie.size(); ++i)
        for (std::size_t j = 0; j < n; ++j)
            Y.re[i + j * tSortie.size()] = ySortie[i].re[j];
    (void)colonne;
    if (nargout <= 1) {
        Valeur sol = Valeur::structureVide();
        sol.poserChamp("x", Valeur::ligne(tSortie));
        sol.poserChamp("y", transposer(Y, false));
        return {sol};
    }
    return {Valeur::colonne(tSortie), Y};
}

FONCTION(fnOde45) { return resoudreEDO(it, args, nargout, false); }
FONCTION(fnOde23) { return resoudreEDO(it, args, nargout, true); }

FONCTION(fnOdeset) {
    INUTILISE
    Valeur o = Valeur::structureVide();
    for (std::size_t k = 0; k + 1 < args.size(); k += 2)
        o.poserChamp(args[k].versTexte(), args[k + 1]);
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
    it.enregistrer("optimset", fnOptimset, "optimisation", "optimset  Options d'optimisation.");
    it.enregistrer("optimget", fnOptimget, "optimisation", "optimget  Lit une option.");
    it.enregistrer("lsqnonneg", fnLsqnonneg, "optimisation",
                   "lsqnonneg  Moindres carres a coefficients positifs.");
}

}  // namespace matlibre
