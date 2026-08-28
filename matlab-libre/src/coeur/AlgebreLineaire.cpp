#include "matlibre/AlgebreLineaire.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>

#include "matlibre/Creux.h"
#include "matlibre/Erreur.h"
#include "matlibre/Operations.h"

namespace matlibre {

using cplx = std::complex<double>;

// --------------------------------------------------------------- matrices

template <class T>
struct Mat {
    int l = 0, c = 0;
    std::vector<T> a;
    Mat() = default;
    Mat(int lignes, int colonnes) : l(lignes), c(colonnes), a((std::size_t)lignes * colonnes, T()) {}
    T& operator()(int i, int j) { return a[(std::size_t)i + (std::size_t)j * l]; }
    const T& operator()(int i, int j) const { return a[(std::size_t)i + (std::size_t)j * l]; }
};

static double module(double x) { return std::fabs(x); }
static double module(const cplx& x) { return std::abs(x); }
static double conjuger(double x) { return x; }
static cplx conjuger(const cplx& x) { return std::conj(x); }

static Mat<double> versReel(const Valeur& v) {
    Mat<double> m(v.nlignes(), v.ncolonnes());
    for (std::size_t k = 0; k < m.a.size() && k < v.re.size(); ++k) m.a[k] = v.re[k];
    return m;
}

static Mat<cplx> versComplexe(const Valeur& v) {
    Mat<cplx> m(v.nlignes(), v.ncolonnes());
    for (std::size_t k = 0; k < m.a.size(); ++k)
        m.a[k] = cplx(k < v.re.size() ? v.re[k] : 0.0, k < v.im.size() ? v.im[k] : 0.0);
    return m;
}

static Valeur depuis(const Mat<double>& m) {
    Valeur v;
    v.dims = {m.l, m.c};
    v.re = m.a;
    return v;
}

static Valeur depuis(const Mat<cplx>& m) {
    Valeur v;
    v.dims = {m.l, m.c};
    v.re.resize(m.a.size());
    v.im.resize(m.a.size());
    for (std::size_t k = 0; k < m.a.size(); ++k) {
        v.re[k] = m.a[k].real();
        v.im[k] = m.a[k].imag();
    }
    v.compacter();
    return v;
}

static void verifierMatrice2D(const Valeur& a, const char* nom) {
    if (a.dims.size() > 2)
        erreur("MATLAB:linalg:matrixMustBe2D",
               formater("Input %s must be 2-D.", nom));
}

// --------------------------------------------------------------- produit

template <class T>
static Mat<T> multiplier(const Mat<T>& a, const Mat<T>& b) {
    Mat<T> r(a.l, b.c);
    for (int j = 0; j < b.c; ++j)
        for (int k = 0; k < a.c; ++k) {
            T bv = b(k, j);
            if (module(bv) == 0.0) continue;
            for (int i = 0; i < a.l; ++i) r(i, j) += a(i, k) * bv;
        }
    return r;
}

Valeur produitMatrice(const Valeur& a, const Valeur& b) {
    verifierMatrice2D(a, "A");
    verifierMatrice2D(b, "B");
    if (a.estScalaire() || b.estScalaire()) return operationBinaire(".*", a, b);
    if (a.ncolonnes() != b.nlignes())
        erreur("MATLAB:innerdim",
               "Incorrect dimensions for matrix multiplication. Check that the number of "
               "columns in the first matrix matches the number of rows in the second "
               "matrix.");
    if (a.estComplexe() || b.estComplexe())
        return depuis(multiplier(versComplexe(a), versComplexe(b)));
    Valeur r = depuis(multiplier(versReel(a), versReel(b)));
    if (a.classe == Classe::Simple || b.classe == Classe::Simple) r.classe = Classe::Simple;
    return r;
}

// ------------------------------------------------------------------- LU

template <class T>
static bool luInterne(Mat<T>& a, std::vector<int>& perm, int& signe) {
    int n = a.l;
    perm.resize((std::size_t)n);
    for (int i = 0; i < n; ++i) perm[(std::size_t)i] = i;
    signe = 1;
    bool reguliere = true;
    for (int k = 0; k < std::min(n, a.c); ++k) {
        int pivot = k;
        double meilleur = module(a(k, k));
        for (int i = k + 1; i < n; ++i) {
            double m = module(a(i, k));
            if (m > meilleur) { meilleur = m; pivot = i; }
        }
        if (meilleur == 0.0) { reguliere = false; continue; }
        if (pivot != k) {
            for (int j = 0; j < a.c; ++j) std::swap(a(k, j), a(pivot, j));
            std::swap(perm[(std::size_t)k], perm[(std::size_t)pivot]);
            signe = -signe;
        }
        for (int i = k + 1; i < n; ++i) {
            T facteur = a(i, k) / a(k, k);
            a(i, k) = facteur;
            if (module(facteur) == 0.0) continue;
            for (int j = k + 1; j < a.c; ++j) a(i, j) -= facteur * a(k, j);
        }
    }
    return reguliere;
}

template <class T>
static Mat<T> resoudreLU(const Mat<T>& lu, const std::vector<int>& perm, const Mat<T>& b) {
    int n = lu.l;
    Mat<T> x(n, b.c);
    for (int j = 0; j < b.c; ++j) {
        std::vector<T> y((std::size_t)n);
        for (int i = 0; i < n; ++i) {
            T s = b(perm[(std::size_t)i], j);
            for (int k = 0; k < i; ++k) s -= lu(i, k) * y[(std::size_t)k];
            y[(std::size_t)i] = s;
        }
        for (int i = n - 1; i >= 0; --i) {
            T s = y[(std::size_t)i];
            for (int k = i + 1; k < n; ++k) s -= lu(i, k) * x(k, j);
            x(i, j) = s / lu(i, i);
        }
    }
    return x;
}

// Moindres carrés par QR de Householder (matrices rectangulaires).
template <class T>
static Mat<T> moindresCarres(Mat<T> a, Mat<T> b) {
    int m = a.l, n = a.c;
    for (int k = 0; k < std::min(m, n); ++k) {
        double normeCol = 0;
        for (int i = k; i < m; ++i) normeCol += module(a(i, k)) * module(a(i, k));
        normeCol = std::sqrt(normeCol);
        if (normeCol == 0) continue;
        T alpha = a(k, k);
        double ma = module(alpha);
        T signe = (ma == 0.0) ? T(1) : alpha / T(ma);
        T v0 = alpha + signe * T(normeCol);
        std::vector<T> v((std::size_t)(m - k));
        v[0] = v0;
        for (int i = k + 1; i < m; ++i) v[(std::size_t)(i - k)] = a(i, k);
        double vn = 0;
        for (auto& x : v) vn += module(x) * module(x);
        if (vn == 0) continue;
        auto appliquer = [&](Mat<T>& mat) {
            for (int j = 0; j < mat.c; ++j) {
                T s = T();
                for (int i = k; i < m; ++i) s += conjuger(v[(std::size_t)(i - k)]) * mat(i, j);
                s = s * T(2.0 / vn);
                for (int i = k; i < m; ++i) mat(i, j) -= v[(std::size_t)(i - k)] * s;
            }
        };
        appliquer(a);
        appliquer(b);
    }
    // Remontée sur le bloc triangulaire supérieur.
    int r = std::min(m, n);
    Mat<T> x(n, b.c);
    for (int j = 0; j < b.c; ++j) {
        for (int i = r - 1; i >= 0; --i) {
            T s = b(i, j);
            for (int k = i + 1; k < r; ++k) s -= a(i, k) * x(k, j);
            if (module(a(i, i)) < 1e-300) x(i, j) = T();
            else x(i, j) = s / a(i, i);
        }
    }
    return x;
}

Valeur divisionGauche(const Valeur& a, const Valeur& b) {
    if (a.estCreux()) return resoudreCreux(a, assurerDense(b));
    verifierMatrice2D(a, "A");
    verifierMatrice2D(b, "B");
    if (a.estScalaire()) return operationBinaire("./", b, a);
    if (a.nlignes() != b.nlignes())
        erreur("MATLAB:dimagree",
               "Matrix dimensions must agree.");
    bool complexe = a.estComplexe() || b.estComplexe();
    if (a.estCarree()) {
        if (complexe) {
            Mat<cplx> lu = versComplexe(a);
            std::vector<int> perm;
            int signe;
            if (luInterne(lu, perm, signe))
                return depuis(resoudreLU(lu, perm, versComplexe(b)));
        } else {
            Mat<double> lu = versReel(a);
            std::vector<int> perm;
            int signe;
            if (luInterne(lu, perm, signe))
                return depuis(resoudreLU(lu, perm, versReel(b)));
        }
        // Matrice singulière : on bascule sur les moindres carrés, qui
        // donnent la solution de norme minimale.
    }
    if (complexe) return depuis(moindresCarres(versComplexe(a), versComplexe(b)));
    return depuis(moindresCarres(versReel(a), versReel(b)));
}

Valeur divisionDroite(const Valeur& a, const Valeur& b) {
    if (b.estScalaire()) return operationBinaire("./", a, b);
    // A/B = (B' \ A')'
    Valeur r = divisionGauche(transposer(b, true), transposer(a, true));
    return transposer(r, true);
}

Valeur inverseMatrice(const Valeur& a) {
    verifierMatrice2D(a, "A");
    if (!a.estCarree()) erreur("MATLAB:square", "Matrix must be square.");
    int n = a.nlignes();
    Valeur id = Valeur::matrice(n, n);
    for (int i = 0; i < n; ++i) id.re[(std::size_t)i + (std::size_t)i * n] = 1.0;
    return divisionGauche(a, id);
}

Valeur determinantMatrice(const Valeur& a) {
    verifierMatrice2D(a, "A");
    if (!a.estCarree()) erreur("MATLAB:square", "Matrix must be square.");
    int n = a.nlignes();
    if (n == 0) return Valeur::scalaire(1.0);
    if (a.estComplexe()) {
        Mat<cplx> lu = versComplexe(a);
        std::vector<int> perm;
        int signe;
        luInterne(lu, perm, signe);
        cplx d = cplx((double)signe, 0.0);
        for (int i = 0; i < n; ++i) d *= lu(i, i);
        return Valeur::complexe(d.real(), d.imag());
    }
    Mat<double> lu = versReel(a);
    std::vector<int> perm;
    int signe;
    luInterne(lu, perm, signe);
    double d = signe;
    for (int i = 0; i < n; ++i) d *= lu(i, i);
    return Valeur::scalaire(d);
}

void factorisationLU(const Valeur& a, Valeur& l, Valeur& u, Valeur& p) {
    int n = a.nlignes(), m = a.ncolonnes();
    Mat<double> lu = versReel(a);
    std::vector<int> perm;
    int signe;
    luInterne(lu, perm, signe);
    Valeur L = Valeur::matrice(n, std::min(n, m));
    Valeur U = Valeur::matrice(std::min(n, m), m);
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < m; ++j) {
            double v = lu(i, j);
            if (i > j) {
                if (j < L.ncolonnes()) L.re[(std::size_t)i + (std::size_t)j * n] = v;
            } else {
                if (i < U.nlignes()) U.re[(std::size_t)i + (std::size_t)j * U.nlignes()] = v;
            }
        }
    for (int i = 0; i < std::min(n, m); ++i) L.re[(std::size_t)i + (std::size_t)i * n] = 1.0;
    Valeur P = Valeur::matrice(n, n);
    for (int i = 0; i < n; ++i) P.re[(std::size_t)i + (std::size_t)perm[(std::size_t)i] * n] = 1.0;
    l = L;
    u = U;
    p = P;
}

// -------------------------------------------------------------------- QR

void factorisationQR(const Valeur& a, Valeur& q, Valeur& r, bool economique) {
    int m = a.nlignes(), n = a.ncolonnes();
    Mat<double> R = versReel(a);
    Mat<double> Q(m, m);
    for (int i = 0; i < m; ++i) Q(i, i) = 1.0;
    for (int k = 0; k < std::min(m - 1, n); ++k) {
        double normeCol = 0;
        for (int i = k; i < m; ++i) normeCol += R(i, k) * R(i, k);
        normeCol = std::sqrt(normeCol);
        if (normeCol == 0) continue;
        double alpha = (R(k, k) >= 0) ? -normeCol : normeCol;
        std::vector<double> v((std::size_t)(m - k), 0.0);
        v[0] = R(k, k) - alpha;
        for (int i = k + 1; i < m; ++i) v[(std::size_t)(i - k)] = R(i, k);
        double vn = 0;
        for (double x : v) vn += x * x;
        if (vn == 0) continue;
        for (int j = 0; j < n; ++j) {
            double s = 0;
            for (int i = k; i < m; ++i) s += v[(std::size_t)(i - k)] * R(i, j);
            s = 2 * s / vn;
            for (int i = k; i < m; ++i) R(i, j) -= v[(std::size_t)(i - k)] * s;
        }
        for (int j = 0; j < m; ++j) {
            double s = 0;
            for (int i = k; i < m; ++i) s += v[(std::size_t)(i - k)] * Q(j, i);
            s = 2 * s / vn;
            for (int i = k; i < m; ++i) Q(j, i) -= v[(std::size_t)(i - k)] * s;
        }
    }
    for (int j = 0; j < n; ++j)
        for (int i = j + 1; i < m; ++i) R(i, j) = 0.0;
    if (economique && m > n) {
        Mat<double> Qe(m, n), Re(n, n);
        for (int j = 0; j < n; ++j)
            for (int i = 0; i < m; ++i) Qe(i, j) = Q(i, j);
        for (int j = 0; j < n; ++j)
            for (int i = 0; i < n; ++i) Re(i, j) = R(i, j);
        q = depuis(Qe);
        r = depuis(Re);
        return;
    }
    q = depuis(Q);
    r = depuis(R);
}

// -------------------------------------------------------------- Cholesky

Valeur cholesky(const Valeur& a, bool inferieure) {
    if (!a.estCarree()) erreur("MATLAB:square", "Matrix must be square.");
    int n = a.nlignes();
    Mat<double> A = versReel(a);
    Mat<double> L(n, n);
    for (int j = 0; j < n; ++j) {
        double s = A(j, j);
        for (int k = 0; k < j; ++k) s -= L(j, k) * L(j, k);
        if (s <= 0)
            erreur("MATLAB:posdef", "Matrix must be positive definite.");
        L(j, j) = std::sqrt(s);
        for (int i = j + 1; i < n; ++i) {
            double t = A(i, j);
            for (int k = 0; k < j; ++k) t -= L(i, k) * L(j, k);
            L(i, j) = t / L(j, j);
        }
    }
    if (inferieure) return depuis(L);
    Mat<double> R(n, n);
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j) R(i, j) = L(j, i);
    return depuis(R);
}

// -------------------------------------------------------------------- SVD

// Jacobi unilatérale : robuste, sans dépendance, précision suffisante pour
// les usages courants (rang, pseudo-inverse, norme 2, conditionnement).
static void svdJacobi(Mat<double> A, Mat<double>& U, std::vector<double>& s, Mat<double>& V) {
    int m = A.l, n = A.c;
    bool transposee = false;
    if (m < n) {
        Mat<double> At(n, m);
        for (int i = 0; i < m; ++i)
            for (int j = 0; j < n; ++j) At(j, i) = A(i, j);
        A = At;
        std::swap(m, n);
        transposee = true;
    }
    V = Mat<double>(n, n);
    for (int i = 0; i < n; ++i) V(i, i) = 1.0;
    const double eps = 1e-15;
    for (int balayage = 0; balayage < 60; ++balayage) {
        double horsDiag = 0;
        for (int p = 0; p < n - 1; ++p) {
            for (int q = p + 1; q < n; ++q) {
                double alpha = 0, beta = 0, gamma = 0;
                for (int i = 0; i < m; ++i) {
                    alpha += A(i, p) * A(i, p);
                    beta += A(i, q) * A(i, q);
                    gamma += A(i, p) * A(i, q);
                }
                if (std::fabs(gamma) < eps * std::sqrt(alpha * beta) || gamma == 0.0) continue;
                horsDiag = std::max(horsDiag, std::fabs(gamma) / std::sqrt(alpha * beta));
                double zeta = (beta - alpha) / (2.0 * gamma);
                double t = (zeta >= 0 ? 1.0 : -1.0) /
                           (std::fabs(zeta) + std::sqrt(1.0 + zeta * zeta));
                double c = 1.0 / std::sqrt(1.0 + t * t);
                double si = c * t;
                for (int i = 0; i < m; ++i) {
                    double ap = A(i, p), aq = A(i, q);
                    A(i, p) = c * ap - si * aq;
                    A(i, q) = si * ap + c * aq;
                }
                for (int i = 0; i < n; ++i) {
                    double vp = V(i, p), vq = V(i, q);
                    V(i, p) = c * vp - si * vq;
                    V(i, q) = si * vp + c * vq;
                }
            }
        }
        if (horsDiag < 1e-14) break;
    }
    s.assign((std::size_t)n, 0.0);
    U = Mat<double>(m, n);
    for (int j = 0; j < n; ++j) {
        double norme = 0;
        for (int i = 0; i < m; ++i) norme += A(i, j) * A(i, j);
        norme = std::sqrt(norme);
        s[(std::size_t)j] = norme;
        if (norme > 0)
            for (int i = 0; i < m; ++i) U(i, j) = A(i, j) / norme;
    }
    // Tri décroissant.
    std::vector<int> ordre((std::size_t)n);
    for (int i = 0; i < n; ++i) ordre[(std::size_t)i] = i;
    std::sort(ordre.begin(), ordre.end(),
              [&](int x, int y) { return s[(std::size_t)x] > s[(std::size_t)y]; });
    Mat<double> U2(m, n), V2(n, n);
    std::vector<double> s2((std::size_t)n);
    for (int j = 0; j < n; ++j) {
        int o = ordre[(std::size_t)j];
        s2[(std::size_t)j] = s[(std::size_t)o];
        for (int i = 0; i < m; ++i) U2(i, j) = U(i, o);
        for (int i = 0; i < n; ++i) V2(i, j) = V(i, o);
    }
    U = U2;
    V = V2;
    s = s2;
    if (transposee) std::swap(U, V);
}

// Plongement reel d'une matrice complexe : a X + iY on associe le bloc
// reel [X -Y ; Y X], qui represente la meme application lineaire sur R^2n.
// Ses valeurs singulieres sont celles de X + iY, chacune presente deux
// fois, et sa pseudo-inverse a la meme forme de bloc. Cela donne une SVD
// complexe correcte sans ecrire un Jacobi complexe.
static Mat<double> plongementReel(const Valeur& a) {
    int m = a.nlignes(), n = a.ncolonnes();
    Mat<double> t(2 * m, 2 * n);
    for (int i = 0; i < m; ++i)
        for (int j = 0; j < n; ++j) {
            double x = a.re[(std::size_t)i + (std::size_t)j * m];
            double y = a.im.empty() ? 0.0 : a.im[(std::size_t)i + (std::size_t)j * m];
            t(i, j) = x;
            t(i, n + j) = -y;
            t(m + i, j) = y;
            t(m + i, n + j) = x;
        }
    return t;
}

// Valeurs singulieres d'une matrice, reelle ou complexe.
static std::vector<double> valeursSingulieres(const Valeur& a) {
    Mat<double> U, V;
    std::vector<double> s;
    if (a.estComplexe()) {
        svdJacobi(plongementReel(a), U, s, V);
        std::vector<double> moitie;
        for (std::size_t k = 0; k + 1 < s.size(); k += 2) moitie.push_back(s[k]);
        if (s.size() % 2 == 1) moitie.push_back(s.back());
        return moitie;
    }
    svdJacobi(versReel(a), U, s, V);
    return s;
}

void decompositionSVD(const Valeur& a, Valeur& u, Valeur& s, Valeur& v, bool economique) {
    int m = a.nlignes(), n = a.ncolonnes();
    if (a.estComplexe()) {
        // Les vecteurs singuliers du plongement viennent par paires
        // [ur ; ui] et [-ui ; ur] : chacune porte le meme vecteur
        // complexe ur + i ui, a une phase pres. On en prend un sur deux.
        Mat<double> Ut, Vt;
        std::vector<double> st;
        svdJacobi(plongementReel(a), Ut, st, Vt);
        int rang = std::min(m, n);
        Valeur uc, vc;
        uc.dims = {m, rang};
        uc.re.assign((std::size_t)m * rang, 0.0);
        uc.im.assign((std::size_t)m * rang, 0.0);
        vc.dims = {n, rang};
        vc.re.assign((std::size_t)n * rang, 0.0);
        vc.im.assign((std::size_t)n * rang, 0.0);
        Valeur S = economique ? Valeur::matrice(rang, rang) : Valeur::matrice(m, n);
        int lignesS = economique ? rang : m;
        for (int k = 0; k < rang; ++k) {
            int colonne = 2 * k;
            if (colonne >= (int)st.size()) break;
            S.re[(std::size_t)k + (std::size_t)k * lignesS] = st[(std::size_t)colonne];
            for (int i = 0; i < m; ++i) {
                uc.re[(std::size_t)i + (std::size_t)k * m] = Ut(i, colonne);
                uc.im[(std::size_t)i + (std::size_t)k * m] = Ut(m + i, colonne);
            }
            for (int i = 0; i < n; ++i) {
                vc.re[(std::size_t)i + (std::size_t)k * n] = Vt(i, colonne);
                vc.im[(std::size_t)i + (std::size_t)k * n] = Vt(n + i, colonne);
            }
        }
        uc.compacter();
        vc.compacter();
        u = uc;
        v = vc;
        s = S;
        return;
    }
    Mat<double> U, V;
    std::vector<double> sv;
    svdJacobi(versReel(a), U, sv, V);
    int r = (int)sv.size();
    if (economique) {
        u = depuis(U);
        v = depuis(V);
        Valeur S = Valeur::matrice(r, r);
        for (int i = 0; i < r; ++i) S.re[(std::size_t)i + (std::size_t)i * r] = sv[(std::size_t)i];
        s = S;
        return;
    }
    // Compléter U (m x m) et V (n x n) par une base orthonormale.
    Mat<double> Uc(m, m), Vc(n, n);
    for (int j = 0; j < std::min(U.c, m); ++j)
        for (int i = 0; i < m; ++i) Uc(i, j) = U(i, j);
    for (int j = 0; j < std::min(V.c, n); ++j)
        for (int i = 0; i < n; ++i) Vc(i, j) = V(i, j);
    auto completer = [](Mat<double>& M, int rangConnu) {
        int taille = M.l;
        for (int j = rangConnu; j < taille; ++j) {
            std::vector<double> e((std::size_t)taille, 0.0);
            for (int essai = 0; essai < taille; ++essai) {
                std::fill(e.begin(), e.end(), 0.0);
                e[(std::size_t)essai] = 1.0;
                for (int k = 0; k < j; ++k) {
                    double d = 0;
                    for (int i = 0; i < taille; ++i) d += M(i, k) * e[(std::size_t)i];
                    for (int i = 0; i < taille; ++i) e[(std::size_t)i] -= d * M(i, k);
                }
                double nn = 0;
                for (double x : e) nn += x * x;
                if (nn > 1e-12) {
                    nn = std::sqrt(nn);
                    for (int i = 0; i < taille; ++i) M(i, j) = e[(std::size_t)i] / nn;
                    break;
                }
            }
        }
    };
    completer(Uc, std::min(U.c, m));
    completer(Vc, std::min(V.c, n));
    Valeur S = Valeur::matrice(m, n);
    for (int i = 0; i < std::min({m, n, r}); ++i)
        S.re[(std::size_t)i + (std::size_t)i * m] = sv[(std::size_t)i];
    u = depuis(Uc);
    v = depuis(Vc);
    s = S;
}

// -------------------------------------------------------- valeurs propres

bool estSymetrique(const Valeur& a) {
    if (!a.estCarree()) return false;
    int n = a.nlignes();
    for (int i = 0; i < n; ++i)
        for (int j = i + 1; j < n; ++j) {
            double x = a.re[(std::size_t)i + (std::size_t)j * n];
            double y = a.re[(std::size_t)j + (std::size_t)i * n];
            if (std::fabs(x - y) > 1e-12 * (std::fabs(x) + std::fabs(y) + 1e-300)) return false;
            if (!a.im.empty()) {
                double xi = a.im[(std::size_t)i + (std::size_t)j * n];
                double yi = a.im[(std::size_t)j + (std::size_t)i * n];
                if (std::fabs(xi + yi) > 1e-12) return false;
            }
        }
    return true;
}

// Jacobi cyclique pour les matrices symétriques réelles.
static void jacobiSymetrique(Mat<double> A, std::vector<double>& valeurs, Mat<double>& vecteurs) {
    int n = A.l;
    vecteurs = Mat<double>(n, n);
    for (int i = 0; i < n; ++i) vecteurs(i, i) = 1.0;
    for (int balayage = 0; balayage < 100; ++balayage) {
        double somme = 0;
        for (int p = 0; p < n - 1; ++p)
            for (int q = p + 1; q < n; ++q) somme += A(p, q) * A(p, q);
        if (somme < 1e-30) break;
        for (int p = 0; p < n - 1; ++p) {
            for (int q = p + 1; q < n; ++q) {
                if (std::fabs(A(p, q)) < 1e-300) continue;
                double theta = (A(q, q) - A(p, p)) / (2.0 * A(p, q));
                double t = (theta >= 0 ? 1.0 : -1.0) /
                           (std::fabs(theta) + std::sqrt(theta * theta + 1.0));
                double c = 1.0 / std::sqrt(t * t + 1.0);
                double s = t * c;
                for (int k = 0; k < n; ++k) {
                    double akp = A(k, p), akq = A(k, q);
                    A(k, p) = c * akp - s * akq;
                    A(k, q) = s * akp + c * akq;
                }
                for (int k = 0; k < n; ++k) {
                    double apk = A(p, k), aqk = A(q, k);
                    A(p, k) = c * apk - s * aqk;
                    A(q, k) = s * apk + c * aqk;
                }
                for (int k = 0; k < n; ++k) {
                    double vkp = vecteurs(k, p), vkq = vecteurs(k, q);
                    vecteurs(k, p) = c * vkp - s * vkq;
                    vecteurs(k, q) = s * vkp + c * vkq;
                }
            }
        }
    }
    valeurs.assign((std::size_t)n, 0.0);
    for (int i = 0; i < n; ++i) valeurs[(std::size_t)i] = A(i, i);
    // MATLAB rend les valeurs propres symétriques en ordre croissant.
    std::vector<int> ordre((std::size_t)n);
    for (int i = 0; i < n; ++i) ordre[(std::size_t)i] = i;
    std::sort(ordre.begin(), ordre.end(),
              [&](int x, int y) { return valeurs[(std::size_t)x] < valeurs[(std::size_t)y]; });
    std::vector<double> v2((std::size_t)n);
    Mat<double> V2(n, n);
    for (int j = 0; j < n; ++j) {
        v2[(std::size_t)j] = valeurs[(std::size_t)ordre[(std::size_t)j]];
        for (int i = 0; i < n; ++i) V2(i, j) = vecteurs(i, ordre[(std::size_t)j]);
    }
    valeurs = v2;
    vecteurs = V2;
}

// Réduction de Hessenberg puis QR à décalage implicite (Francis).
static void hessenberg(Mat<double>& A) {
    int n = A.l;
    for (int k = 1; k < n - 1; ++k) {
        double norme = 0;
        for (int i = k; i < n; ++i) norme += A(i, k - 1) * A(i, k - 1);
        norme = std::sqrt(norme);
        if (norme == 0) continue;
        double alpha = (A(k, k - 1) >= 0) ? -norme : norme;
        std::vector<double> v((std::size_t)(n - k), 0.0);
        v[0] = A(k, k - 1) - alpha;
        for (int i = k + 1; i < n; ++i) v[(std::size_t)(i - k)] = A(i, k - 1);
        double vn = 0;
        for (double x : v) vn += x * x;
        if (vn == 0) continue;
        for (int j = 0; j < n; ++j) {
            double s = 0;
            for (int i = k; i < n; ++i) s += v[(std::size_t)(i - k)] * A(i, j);
            s = 2 * s / vn;
            for (int i = k; i < n; ++i) A(i, j) -= v[(std::size_t)(i - k)] * s;
        }
        for (int i = 0; i < n; ++i) {
            double s = 0;
            for (int j = k; j < n; ++j) s += A(i, j) * v[(std::size_t)(j - k)];
            s = 2 * s / vn;
            for (int j = k; j < n; ++j) A(i, j) -= s * v[(std::size_t)(j - k)];
        }
    }
}

// Equilibrage de Parlett et Reinsch : une similitude diagonale par
// puissances de deux rapproche les normes de chaque ligne et de sa
// colonne. Les valeurs propres sont inchangees — la transformation est
// une similitude — mais le conditionnement du QR s'ameliore
// spectaculairement. Sans cela, la matrice compagnon d'un polynome dont
// le coefficient de tete est mille fois plus petit que les autres donne
// des racines fausses.
static void equilibrer(Mat<double>& A) {
    int n = A.l;
    const double base = 2.0;
    bool stable = false;
    int tours = 0;
    while (!stable && tours < 100) {
        stable = true;
        ++tours;
        for (int i = 0; i < n; ++i) {
            double colonne = 0, ligne = 0;
            for (int j = 0; j < n; ++j)
                if (j != i) {
                    colonne += std::fabs(A(j, i));
                    ligne += std::fabs(A(i, j));
                }
            if (colonne == 0 || ligne == 0) continue;
            double g = ligne / base;
            double facteur = 1.0;
            double c = colonne;
            double somme = colonne + ligne;
            while (c < g) {
                facteur *= base;
                c *= base * base;
            }
            g = ligne * base;
            while (c > g) {
                facteur /= base;
                c /= base * base;
            }
            if ((c + ligne / facteur) < 0.95 * somme) {
                stable = false;
                double inverse = 1.0 / facteur;
                for (int j = 0; j < n; ++j) A(i, j) *= inverse;
                for (int j = 0; j < n; ++j) A(j, i) *= facteur;
            }
        }
    }
}

static bool qrValeursPropres(Mat<double> H, std::vector<cplx>& valeurs) {
    int n = H.l;
    valeurs.assign((std::size_t)n, cplx(0, 0));
    int haut = n - 1;
    int iterations = 0;
    int depuisDeflation = 0;
    while (haut >= 0 && iterations < 100 * n + 1000) {
        ++iterations;
        ++depuisDeflation;
        // Chercher un sous-diagonal négligeable.
        int bas = haut;
        while (bas > 0) {
            double s = std::fabs(H(bas - 1, bas - 1)) + std::fabs(H(bas, bas));
            if (s == 0) s = 1;
            if (std::fabs(H(bas, bas - 1)) < 1e-14 * s) { H(bas, bas - 1) = 0; break; }
            --bas;
        }
        if (bas == haut) {
            valeurs[(std::size_t)haut] = cplx(H(haut, haut), 0.0);
            --haut;
            depuisDeflation = 0;
            continue;
        }
        if (bas == haut - 1) {
            double a = H(haut - 1, haut - 1), b = H(haut - 1, haut);
            double c = H(haut, haut - 1), d = H(haut, haut);
            double tr = a + d, det = a * d - b * c;
            double disc = tr * tr / 4 - det;
            if (disc >= 0) {
                double r = std::sqrt(disc);
                valeurs[(std::size_t)(haut - 1)] = cplx(tr / 2 + r, 0);
                valeurs[(std::size_t)haut] = cplx(tr / 2 - r, 0);
            } else {
                double r = std::sqrt(-disc);
                valeurs[(std::size_t)(haut - 1)] = cplx(tr / 2, r);
                valeurs[(std::size_t)haut] = cplx(tr / 2, -r);
            }
            haut -= 2;
            depuisDeflation = 0;
            continue;
        }
        // Décalage de Wilkinson.
        double a = H(haut - 1, haut - 1), b = H(haut - 1, haut);
        double c = H(haut, haut - 1), d = H(haut, haut);
        double tr = a + d, det = a * d - b * c;
        double disc = tr * tr / 4 - det;
        double mu;
        if (disc >= 0) {
            double r1 = tr / 2 + std::sqrt(disc), r2 = tr / 2 - std::sqrt(disc);
            mu = (std::fabs(r1 - d) < std::fabs(r2 - d)) ? r1 : r2;
        } else {
            mu = d;
        }
        // Décalage exceptionnel : sur une matrice de permutation, le
        // décalage de Wilkinson vaut zéro et l'itération QR reste sur
        // place indéfiniment. Un décalage arbitraire tiré des
        // sous-diagonales casse la symétrie et relance la convergence.
        // C'est la parade d'EISPACK, appliquée tous les dix tours sans
        // déflation.
        if (depuisDeflation > 0 && depuisDeflation % 10 == 0) {
            double s = std::fabs(H(haut, haut - 1));
            if (haut >= 2) s += std::fabs(H(haut - 1, haut - 2));
            if (s == 0) s = 1.0;
            mu = d + 0.75 * s * (1.0 + 0.1 * (double)(depuisDeflation / 10));
        }
        for (int i = bas; i <= haut; ++i) H(i, i) -= mu;
        // QR de Givens sur le bloc actif.
        std::vector<double> cs, sn;
        for (int k = bas; k < haut; ++k) {
            double x = H(k, k), y = H(k + 1, k);
            double r = std::hypot(x, y);
            double co = (r == 0) ? 1 : x / r, si = (r == 0) ? 0 : y / r;
            cs.push_back(co);
            sn.push_back(si);
            for (int j = k; j < n; ++j) {
                double h1 = H(k, j), h2 = H(k + 1, j);
                H(k, j) = co * h1 + si * h2;
                H(k + 1, j) = -si * h1 + co * h2;
            }
        }
        for (int k = bas; k < haut; ++k) {
            double co = cs[(std::size_t)(k - bas)], si = sn[(std::size_t)(k - bas)];
            for (int i = 0; i <= std::min(haut, k + 2); ++i) {
                double h1 = H(i, k), h2 = H(i, k + 1);
                H(i, k) = co * h1 + si * h2;
                H(i, k + 1) = -si * h1 + co * h2;
            }
        }
        for (int i = bas; i <= haut; ++i) H(i, i) += mu;
    }
    return haut < 0;
}

// QR décalé en arithmétique complexe. Le décalage de Wilkinson y est
// complexe, donc la convergence est cubique même quand les valeurs
// propres sont complexes conjuguées : le QR réel, lui, ne peut décaler
// que par un réel et reste parfois sur place. On ne s'en sert qu'en
// second recours, quand le QR réel n'a pas convergé, car l'arithmétique
// complexe coûte quatre fois plus cher.
static void qrValeursPropresComplexe(Mat<cplx> H, std::vector<cplx>& valeurs) {
    int n = H.l;
    valeurs.assign((std::size_t)n, cplx(0, 0));
    int haut = n - 1;
    int iterations = 0;
    int depuisDeflation = 0;
    while (haut >= 0 && iterations < 200 * n + 2000) {
        ++iterations;
        ++depuisDeflation;
        int bas = haut;
        while (bas > 0) {
            double s = std::abs(H(bas - 1, bas - 1)) + std::abs(H(bas, bas));
            if (s == 0) s = 1;
            if (std::abs(H(bas, bas - 1)) < 1e-15 * s) {
                H(bas, bas - 1) = cplx(0, 0);
                break;
            }
            --bas;
        }
        if (bas == haut) {
            valeurs[(std::size_t)haut] = H(haut, haut);
            --haut;
            depuisDeflation = 0;
            continue;
        }
        cplx a = H(haut - 1, haut - 1), b = H(haut - 1, haut);
        cplx c = H(haut, haut - 1), d = H(haut, haut);
        cplx trace = a + d, det = a * d - b * c;
        cplx racine = std::sqrt(trace * trace / 4.0 - det);
        cplx r1 = trace / 2.0 + racine, r2 = trace / 2.0 - racine;
        cplx mu = (std::abs(r1 - d) < std::abs(r2 - d)) ? r1 : r2;
        if (depuisDeflation % 15 == 0)
            mu = d + cplx(0.75 * std::abs(H(haut, haut - 1)), 0.25 * std::abs(H(haut, haut - 1)));
        for (int i = bas; i <= haut; ++i) H(i, i) -= mu;
        // Rotations de Givens complexes : G = [c s ; -conj(s) c] avec c réel.
        std::vector<double> cs;
        std::vector<cplx> sn;
        for (int k = bas; k < haut; ++k) {
            cplx x = H(k, k), y = H(k + 1, k);
            double nx = std::abs(x), ny = std::abs(y);
            double r = std::hypot(nx, ny);
            double co;
            cplx si;
            if (r == 0) {
                co = 1.0;
                si = cplx(0, 0);
            } else if (nx == 0) {
                co = 0.0;
                si = cplx(1, 0);
            } else {
                co = nx / r;
                si = (x / nx) * std::conj(y) / r;
            }
            cs.push_back(co);
            sn.push_back(si);
            for (int j = k; j < n; ++j) {
                cplx h1 = H(k, j), h2 = H(k + 1, j);
                H(k, j) = co * h1 + si * h2;
                H(k + 1, j) = -std::conj(si) * h1 + co * h2;
            }
        }
        for (int k = bas; k < haut; ++k) {
            double co = cs[(std::size_t)(k - bas)];
            cplx si = sn[(std::size_t)(k - bas)];
            for (int i = 0; i <= std::min(haut, k + 2); ++i) {
                cplx h1 = H(i, k), h2 = H(i, k + 1);
                H(i, k) = co * h1 + std::conj(si) * h2;
                H(i, k + 1) = -si * h1 + co * h2;
            }
        }
        for (int i = bas; i <= haut; ++i) H(i, i) += mu;
    }
    for (int i = 0; i <= haut; ++i) valeurs[(std::size_t)i] = H(i, i);
}

void valeursPropres(const Valeur& a, Valeur& valeurs, Valeur* vecteurs) {
    if (!a.estCarree()) erreur("MATLAB:square", "Matrix must be square.");
    int n = a.nlignes();
    if (n == 0) {
        valeurs = Valeur::vide();
        if (vecteurs) *vecteurs = Valeur::vide();
        return;
    }
    if (!a.estComplexe() && estSymetrique(a)) {
        std::vector<double> vals;
        Mat<double> vecs;
        jacobiSymetrique(versReel(a), vals, vecs);
        if (vecteurs) {
            *vecteurs = depuis(vecs);
            Valeur D = Valeur::matrice(n, n);
            for (int i = 0; i < n; ++i)
                D.re[(std::size_t)i + (std::size_t)i * n] = vals[(std::size_t)i];
            valeurs = D;
        } else {
            valeurs = Valeur::colonne(vals);
        }
        return;
    }
    Mat<double> H = versReel(a);
    equilibrer(H);
    hessenberg(H);
    std::vector<cplx> vals;
    if (!qrValeursPropres(H, vals)) {
        // Le QR réel n'a pas convergé : on recommence en complexe, où le
        // décalage peut suivre une paire conjuguée.
        Mat<cplx> Hc(H.l, H.c);
        for (int i = 0; i < H.l; ++i)
            for (int j = 0; j < H.c; ++j) Hc(i, j) = cplx(H(i, j), 0.0);
        qrValeursPropresComplexe(Hc, vals);
    }
    Valeur lambda;
    lambda.dims = {n, 1};
    lambda.re.resize((std::size_t)n);
    lambda.im.resize((std::size_t)n);
    for (int i = 0; i < n; ++i) {
        lambda.re[(std::size_t)i] = vals[(std::size_t)i].real();
        lambda.im[(std::size_t)i] = vals[(std::size_t)i].imag();
    }
    lambda.compacter();
    if (!vecteurs) {
        valeurs = lambda;
        return;
    }
    // Vecteurs propres par itération inverse sur (A - lambda I).
    Valeur V;
    V.dims = {n, n};
    V.re.assign((std::size_t)n * n, 0.0);
    V.im.assign((std::size_t)n * n, 0.0);
    for (int k = 0; k < n; ++k) {
        cplx mu = vals[(std::size_t)k] + cplx(1e-10, 1e-12);
        Mat<cplx> M = versComplexe(a);
        for (int i = 0; i < n; ++i) M(i, i) -= mu;
        std::vector<int> perm;
        int signe;
        Mat<cplx> lu = M;
        luInterne(lu, perm, signe);
        Mat<cplx> x(n, 1);
        for (int i = 0; i < n; ++i) x(i, 0) = cplx(1.0 / std::sqrt((double)n), 0);
        for (int it = 0; it < 12; ++it) {
            Mat<cplx> y = resoudreLU(lu, perm, x);
            double norme = 0;
            for (int i = 0; i < n; ++i) norme += std::norm(y(i, 0));
            norme = std::sqrt(norme);
            if (!std::isfinite(norme) || norme == 0) break;
            for (int i = 0; i < n; ++i) y(i, 0) /= norme;
            x = y;
        }
        // Phase : la plus grande composante devient réelle positive.
        int imax = 0;
        double vmax = 0;
        for (int i = 0; i < n; ++i)
            if (std::abs(x(i, 0)) > vmax) { vmax = std::abs(x(i, 0)); imax = i; }
        if (vmax > 0) {
            cplx phase = std::abs(x(imax, 0)) / x(imax, 0);
            for (int i = 0; i < n; ++i) x(i, 0) *= phase;
        }
        for (int i = 0; i < n; ++i) {
            V.re[(std::size_t)i + (std::size_t)k * n] = x(i, 0).real();
            V.im[(std::size_t)i + (std::size_t)k * n] = x(i, 0).imag();
        }
    }
    V.compacter();
    Valeur D;
    D.dims = {n, n};
    D.re.assign((std::size_t)n * n, 0.0);
    D.im.assign((std::size_t)n * n, 0.0);
    for (int i = 0; i < n; ++i) {
        D.re[(std::size_t)i + (std::size_t)i * n] = vals[(std::size_t)i].real();
        D.im[(std::size_t)i + (std::size_t)i * n] = vals[(std::size_t)i].imag();
    }
    D.compacter();
    *vecteurs = V;
    valeurs = D;
}

// ------------------------------------------------------------------ normes

Valeur normeMatrice(const Valeur& a, const Valeur& type) {
    std::string t = "2";
    if (!type.estVide()) {
        if (type.estTexte() || type.estChaine()) t = type.versTexte();
        else t = formater("%g", type.scal());
    }
    int m = a.nlignes(), n = a.ncolonnes();
    auto valeurAbs = [&](std::size_t k) {
        double r = k < a.re.size() ? a.re[k] : 0.0;
        double i = k < a.im.size() ? a.im[k] : 0.0;
        return std::hypot(r, i);
    };
    bool vecteur = a.estVecteur() || a.estScalaire();
    if (t == "fro" || (vecteur && t == "2")) {
        double s = 0;
        for (std::size_t k = 0; k < a.nelem(); ++k) s += valeurAbs(k) * valeurAbs(k);
        return Valeur::scalaire(std::sqrt(s));
    }
    if (vecteur) {
        if (t == "inf" || t == "Inf") {
            double s = 0;
            for (std::size_t k = 0; k < a.nelem(); ++k) s = std::max(s, valeurAbs(k));
            return Valeur::scalaire(s);
        }
        if (t == "-inf" || t == "-Inf") {
            double s = INFINITY;
            for (std::size_t k = 0; k < a.nelem(); ++k) s = std::min(s, valeurAbs(k));
            return Valeur::scalaire(s);
        }
        double p = std::atof(t.c_str());
        double s = 0;
        for (std::size_t k = 0; k < a.nelem(); ++k) s += std::pow(valeurAbs(k), p);
        return Valeur::scalaire(std::pow(s, 1.0 / p));
    }
    if (t == "1") {
        double meilleur = 0;
        for (int j = 0; j < n; ++j) {
            double s = 0;
            for (int i = 0; i < m; ++i) s += valeurAbs((std::size_t)i + (std::size_t)j * m);
            meilleur = std::max(meilleur, s);
        }
        return Valeur::scalaire(meilleur);
    }
    if (t == "inf" || t == "Inf") {
        double meilleur = 0;
        for (int i = 0; i < m; ++i) {
            double s = 0;
            for (int j = 0; j < n; ++j) s += valeurAbs((std::size_t)i + (std::size_t)j * m);
            meilleur = std::max(meilleur, s);
        }
        return Valeur::scalaire(meilleur);
    }
    std::vector<double> valeurs = valeursSingulieres(a);
    return Valeur::scalaire(valeurs.empty() ? 0.0 : valeurs[0]);
}

int rangMatrice(const Valeur& a, double tolerance) {
    if (a.estVide()) return 0;
    std::vector<double> s = valeursSingulieres(a);
    double tol = tolerance;
    if (tol < 0) {
        double smax = s.empty() ? 0 : s[0];
        tol = std::max(a.nlignes(), a.ncolonnes()) * smax * 2.220446049250313e-16;
    }
    int r = 0;
    for (double x : s)
        if (x > tol) ++r;
    return r;
}

Valeur pseudoInverse(const Valeur& a, double tolerance) {
    if (a.estComplexe()) {
        // La pseudo-inverse du plongement est le plongement de la
        // pseudo-inverse : il suffit d'en relire les deux blocs.
        int m = a.nlignes(), n = a.ncolonnes();
        Valeur tilde = depuis(plongementReel(a));
        Valeur pt = pseudoInverse(tilde, tolerance);
        Valeur p;
        p.dims = {n, m};
        p.re.assign((std::size_t)n * m, 0.0);
        p.im.assign((std::size_t)n * m, 0.0);
        for (int i = 0; i < n; ++i)
            for (int j = 0; j < m; ++j) {
                p.re[(std::size_t)i + (std::size_t)j * n] =
                    pt.re[(std::size_t)i + (std::size_t)j * (2 * n)];
                p.im[(std::size_t)i + (std::size_t)j * n] =
                    pt.re[(std::size_t)(n + i) + (std::size_t)j * (2 * n)];
            }
        p.compacter();
        return p;
    }
    Mat<double> U, V;
    std::vector<double> s;
    svdJacobi(versReel(a), U, s, V);
    double tol = tolerance;
    if (tol < 0) {
        double smax = s.empty() ? 0 : s[0];
        tol = std::max(a.nlignes(), a.ncolonnes()) * smax * 2.220446049250313e-16;
    }
    int m = a.nlignes(), n = a.ncolonnes();
    Mat<double> P(n, m);
    for (std::size_t k = 0; k < s.size(); ++k) {
        if (s[k] <= tol) continue;
        for (int i = 0; i < n; ++i)
            for (int j = 0; j < m; ++j)
                P(i, j) += V(i, (int)k) * U(j, (int)k) / s[k];
    }
    return depuis(P);
}

Valeur conditionnement(const Valeur& a) {
    if (a.estVide()) return Valeur::scalaire(0);
    std::vector<double> s = valeursSingulieres(a);
    if (s.empty()) return Valeur::scalaire(0);
    double smin = s.back();
    if (smin == 0) return Valeur::scalaire(INFINITY);
    return Valeur::scalaire(s.front() / smin);
}

Valeur traceMatrice(const Valeur& a) {
    int n = std::min(a.nlignes(), a.ncolonnes());
    double sr = 0, si = 0;
    for (int i = 0; i < n; ++i) {
        sr += a.re[(std::size_t)i + (std::size_t)i * a.nlignes()];
        if (!a.im.empty()) si += a.im[(std::size_t)i + (std::size_t)i * a.nlignes()];
    }
    return si == 0 ? Valeur::scalaire(sr) : Valeur::complexe(sr, si);
}

Valeur puissanceMatrice(const Valeur& a, const Valeur& p) {
    if (!a.estCarree()) erreur("MATLAB:square", "Matrix must be square.");
    if (!p.estScalaire())
        erreur("MATLAB:mpower:notScalar", "Exponent must be a scalar.");
    double e = p.scal();
    int n = a.nlignes();
    if (e == std::floor(e) && std::fabs(e) < 1e6) {
        long long k = (long long)e;
        bool inverse = k < 0;
        if (inverse) k = -k;
        Valeur r = Valeur::matrice(n, n);
        for (int i = 0; i < n; ++i) r.re[(std::size_t)i + (std::size_t)i * n] = 1.0;
        Valeur base = a;
        while (k > 0) {
            if (k & 1) r = produitMatrice(r, base);
            base = produitMatrice(base, base);
            k >>= 1;
        }
        return inverse ? inverseMatrice(r) : r;
    }
    // Exposant non entier : par diagonalisation.
    Valeur V, D;
    valeursPropres(a, D, &V);
    int m = D.nlignes();
    Valeur Dp = D;
    Dp.assurerImaginaire();
    for (int i = 0; i < m; ++i) {
        std::size_t k = (std::size_t)i + (std::size_t)i * m;
        cplx z = std::pow(cplx(D.re[k], D.im.empty() ? 0 : D.im[k]), cplx(e, 0));
        Dp.re[k] = z.real();
        Dp.im[k] = z.imag();
    }
    Valeur r = produitMatrice(produitMatrice(V, Dp), inverseMatrice(V));
    r.compacter();
    return r;
}

Valeur exponentielleMatrice(const Valeur& a) {
    if (!a.estCarree()) erreur("MATLAB:square", "Matrix must be square.");
    int n = a.nlignes();
    // Mise à l'échelle et mise au carré, approximant de Padé (6,6).
    double normeMax = 0;
    for (int i = 0; i < n; ++i) {
        double s = 0;
        for (int j = 0; j < n; ++j) s += std::fabs(a.re[(std::size_t)i + (std::size_t)j * n]);
        normeMax = std::max(normeMax, s);
    }
    int j = std::max(0, (int)std::ceil(std::log2(std::max(normeMax, 1e-300))) + 1);
    Valeur A = operationBinaire("./", a, Valeur::scalaire(std::pow(2.0, j)));
    Valeur I = Valeur::matrice(n, n);
    for (int i = 0; i < n; ++i) I.re[(std::size_t)i + (std::size_t)i * n] = 1.0;
    Valeur X = A, N = I, D = I;
    double c = 1.0;
    const int q = 6;
    for (int k = 1; k <= q; ++k) {
        c = c * (q - k + 1.0) / (k * (2.0 * q - k + 1.0));
        Valeur cX = operationBinaire(".*", X, Valeur::scalaire(c));
        N = operationBinaire("+", N, cX);
        D = operationBinaire(k % 2 == 0 ? "+" : "-", D, cX);
        if (k < q) X = produitMatrice(X, A);
    }
    Valeur F = divisionGauche(D, N);
    for (int k = 0; k < j; ++k) F = produitMatrice(F, F);
    return F;
}

Valeur racineMatrice(const Valeur& a) { return puissanceMatrice(a, Valeur::scalaire(0.5)); }

Valeur logarithmeMatrice(const Valeur& a) {
    Valeur V, D;
    valeursPropres(a, D, &V);
    int m = D.nlignes();
    Valeur Dl = D;
    Dl.assurerImaginaire();
    for (int i = 0; i < m; ++i) {
        std::size_t k = (std::size_t)i + (std::size_t)i * m;
        cplx z = std::log(cplx(D.re[k], D.im.empty() ? 0 : D.im[k]));
        Dl.re[k] = z.real();
        Dl.im[k] = z.imag();
    }
    Valeur r = produitMatrice(produitMatrice(V, Dl), inverseMatrice(V));
    r.compacter();
    return r;
}

Valeur formeEchelonnee(const Valeur& a) {
    int m = a.nlignes(), n = a.ncolonnes();
    Mat<double> A = versReel(a);
    int ligne = 0;
    double tol = std::max(m, n) * 2.220446049250313e-16;
    double maxAbs = 0;
    for (double x : A.a) maxAbs = std::max(maxAbs, std::fabs(x));
    tol *= std::max(maxAbs, 1.0);
    for (int col = 0; col < n && ligne < m; ++col) {
        int pivot = ligne;
        for (int i = ligne; i < m; ++i)
            if (std::fabs(A(i, col)) > std::fabs(A(pivot, col))) pivot = i;
        if (std::fabs(A(pivot, col)) <= tol) {
            for (int i = ligne; i < m; ++i) A(i, col) = 0;
            continue;
        }
        for (int j = 0; j < n; ++j) std::swap(A(ligne, j), A(pivot, j));
        double p = A(ligne, col);
        for (int j = 0; j < n; ++j) A(ligne, j) /= p;
        for (int i = 0; i < m; ++i) {
            if (i == ligne) continue;
            double f = A(i, col);
            if (f == 0) continue;
            for (int j = 0; j < n; ++j) A(i, j) -= f * A(ligne, j);
        }
        ++ligne;
    }
    return depuis(A);
}

Valeur noyau(const Valeur& a) {
    Mat<double> U, V;
    std::vector<double> s;
    svdJacobi(versReel(a), U, s, V);
    int n = a.ncolonnes();
    double smax = s.empty() ? 0 : s[0];
    double tol = std::max(a.nlignes(), n) * smax * 2.220446049250313e-16;
    std::vector<int> colonnes;
    for (int k = 0; k < (int)s.size(); ++k)
        if (s[(std::size_t)k] <= tol) colonnes.push_back(k);
    for (int k = (int)s.size(); k < n; ++k) colonnes.push_back(k);
    Mat<double> N(n, (int)colonnes.size());
    for (std::size_t j = 0; j < colonnes.size(); ++j)
        for (int i = 0; i < n; ++i)
            if (colonnes[j] < V.c) N(i, (int)j) = V(i, colonnes[j]);
    return depuis(N);
}

Valeur imageOrthonormale(const Valeur& a) {
    Mat<double> U, V;
    std::vector<double> s;
    svdJacobi(versReel(a), U, s, V);
    double smax = s.empty() ? 0 : s[0];
    double tol = std::max(a.nlignes(), a.ncolonnes()) * smax * 2.220446049250313e-16;
    int r = 0;
    for (double x : s)
        if (x > tol) ++r;
    Mat<double> B(a.nlignes(), r);
    for (int j = 0; j < r; ++j)
        for (int i = 0; i < a.nlignes(); ++i) B(i, j) = U(i, j);
    return depuis(B);
}

}  // namespace matlibre
