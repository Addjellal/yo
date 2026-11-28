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
static double partieReelle(double x) { return x; }
static double partieReelle(const cplx& x) { return x.real(); }
// La phase d'un nombre : x/|x|, le signe pour un réel, 1 pour zéro.
static double phase(double x) { return x < 0 ? -1.0 : 1.0; }
static cplx phase(const cplx& x) {
    double r = std::abs(x);
    return r == 0 ? cplx(1.0, 0.0) : x / r;
}

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

// ---------------------------------------------------------------- LAPACK
//
// Quand la construction a trouvé LAPACK et BLAS (option CMake
// MATLIBRE_LAPACK, qui définit MATLIBRE_AVEC_LAPACK), le produit
// matriciel, la résolution d'un système carré, la SVD et les valeurs
// propres passent par eux : ce sont les routines dont MATLAB se sert,
// par blocs, sur un BLAS optimisé — eig d'une matrice 300 x 300 passe
// d'un tiers de seconde à quelques millisecondes. Sans eux, les
// algorithmes écrits plus bas font le même calcul, et restent le repli.
//
// Les prototypes sont ceux de l'interface Fortran — arguments par
// adresse, entiers sur 32 bits, et la longueur des arguments caractère
// passée en fin d'appel, comme gfortran l'attend — : aucun en-tête n'est
// à trouver.
#ifdef MATLIBRE_AVEC_LAPACK
namespace {
using flen = std::size_t;
extern "C" {
void dgemm_(const char*, const char*, const int*, const int*, const int*, const double*,
            const double*, const int*, const double*, const int*, const double*, double*,
            const int*, flen, flen);
void zgemm_(const char*, const char*, const int*, const int*, const int*, const cplx*,
            const cplx*, const int*, const cplx*, const int*, const cplx*, cplx*, const int*,
            flen, flen);
void dgesv_(const int*, const int*, double*, const int*, int*, double*, const int*, int*);
void zgesv_(const int*, const int*, cplx*, const int*, int*, cplx*, const int*, int*);
void dsyevd_(const char*, const char*, const int*, double*, const int*, double*, double*,
             const int*, int*, const int*, int*, flen, flen);
void zheevd_(const char*, const char*, const int*, cplx*, const int*, double*, cplx*,
             const int*, double*, const int*, int*, const int*, int*, flen, flen);
void dgeev_(const char*, const char*, const int*, double*, const int*, double*, double*,
            double*, const int*, double*, const int*, double*, const int*, int*, flen, flen);
void zgeev_(const char*, const char*, const int*, cplx*, const int*, cplx*, cplx*, const int*,
            cplx*, const int*, cplx*, const int*, double*, int*, flen, flen);
void dgesdd_(const char*, const int*, const int*, double*, const int*, double*, double*,
             const int*, double*, const int*, double*, const int*, int*, int*, flen);
void zgesdd_(const char*, const int*, const int*, cplx*, const int*, double*, cplx*,
             const int*, cplx*, const int*, cplx*, const int*, double*, int*, int*, flen);
}

void lapackProduit(const Mat<double>& a, const Mat<double>& b, Mat<double>& r) {
    r = Mat<double>(a.l, b.c);
    if (a.l == 0 || b.c == 0 || a.c == 0) return;
    const char n = 'N';
    const double un = 1.0, zero = 0.0;
    dgemm_(&n, &n, &a.l, &b.c, &a.c, &un, a.a.data(), &a.l, b.a.data(), &b.l, &zero,
           r.a.data(), &r.l, 1, 1);
}

void lapackProduit(const Mat<cplx>& a, const Mat<cplx>& b, Mat<cplx>& r) {
    r = Mat<cplx>(a.l, b.c);
    if (a.l == 0 || b.c == 0 || a.c == 0) return;
    const char n = 'N';
    const cplx un(1.0, 0.0), zero(0.0, 0.0);
    zgemm_(&n, &n, &a.l, &b.c, &a.c, &un, a.a.data(), &a.l, b.a.data(), &b.l, &zero,
           r.a.data(), &r.l, 1, 1);
}

// A X = B par LU à pivot partiel. Faux quand A est singulière (un pivot
// exactement nul, la même règle que luInterne) : l'appelant passe alors
// aux moindres carrés.
bool lapackResoudre(Mat<double> a, Mat<double>& b) {
    std::vector<int> pivots((std::size_t)std::max(1, a.l));
    int info = 0;
    dgesv_(&a.l, &b.c, a.a.data(), &a.l, pivots.data(), b.a.data(), &b.l, &info);
    return info == 0;
}

bool lapackResoudre(Mat<cplx> a, Mat<cplx>& b) {
    std::vector<int> pivots((std::size_t)std::max(1, a.l));
    int info = 0;
    zgesv_(&a.l, &b.c, a.a.data(), &a.l, pivots.data(), b.a.data(), &b.l, &info);
    return info == 0;
}

// Valeurs propres d'une matrice symétrique, croissantes, et ses vecteurs
// propres orthonormés quand VECTEURS n'est pas nul.
bool lapackSymetrique(Mat<double> a, std::vector<double>& valeurs, Mat<double>* vecteurs) {
    const char job = vecteurs ? 'V' : 'N', uplo = 'L';
    const int n = a.l;
    valeurs.assign((std::size_t)n, 0.0);
    int info = 0, lwork = -1, liwork = -1, iw = 0;
    double w = 0;
    dsyevd_(&job, &uplo, &n, a.a.data(), &n, valeurs.data(), &w, &lwork, &iw, &liwork, &info,
            1, 1);
    lwork = std::max(1, (int)w);
    liwork = std::max(1, iw);
    std::vector<double> travail((std::size_t)lwork);
    std::vector<int> itravail((std::size_t)liwork);
    dsyevd_(&job, &uplo, &n, a.a.data(), &n, valeurs.data(), travail.data(), &lwork,
            itravail.data(), &liwork, &info, 1, 1);
    if (info != 0) return false;
    if (vecteurs) *vecteurs = std::move(a);
    return true;
}

bool lapackHermitien(Mat<cplx> a, std::vector<double>& valeurs, Mat<cplx>* vecteurs) {
    const char job = vecteurs ? 'V' : 'N', uplo = 'L';
    const int n = a.l;
    valeurs.assign((std::size_t)n, 0.0);
    int info = 0, lwork = -1, lrwork = -1, liwork = -1, iw = 0;
    cplx w;
    double rw = 0;
    zheevd_(&job, &uplo, &n, a.a.data(), &n, valeurs.data(), &w, &lwork, &rw, &lrwork, &iw,
            &liwork, &info, 1, 1);
    lwork = std::max(1, (int)w.real());
    lrwork = std::max(1, (int)rw);
    liwork = std::max(1, iw);
    std::vector<cplx> travail((std::size_t)lwork);
    std::vector<double> rtravail((std::size_t)lrwork);
    std::vector<int> itravail((std::size_t)liwork);
    zheevd_(&job, &uplo, &n, a.a.data(), &n, valeurs.data(), travail.data(), &lwork,
            rtravail.data(), &lrwork, itravail.data(), &liwork, &info, 1, 1);
    if (info != 0) return false;
    if (vecteurs) *vecteurs = std::move(a);
    return true;
}

// Cas général, réel : équilibrage, Hessenberg et QR (dgeev). Une paire
// conjuguée de vecteurs arrive en deux colonnes, la partie réelle puis la
// partie imaginaire ; on les rend complexes. LAPACK norme chaque vecteur à
// 1, sa plus grande composante réelle : la convention de MATLAB.
bool lapackGeneral(Mat<double> a, std::vector<cplx>& valeurs, Mat<cplx>* vecteurs) {
    const char jobvl = 'N', jobvr = vecteurs ? 'V' : 'N';
    const int n = a.l, un = 1;
    std::vector<double> wr((std::size_t)n), wi((std::size_t)n);
    Mat<double> vr(vecteurs ? n : 1, vecteurs ? n : 1);
    const int ldvr = vr.l;
    int info = 0, lwork = -1;
    double w = 0, vl = 0;
    dgeev_(&jobvl, &jobvr, &n, a.a.data(), &n, wr.data(), wi.data(), &vl, &un, vr.a.data(),
           &ldvr, &w, &lwork, &info, 1, 1);
    lwork = std::max(1, (int)w);
    std::vector<double> travail((std::size_t)lwork);
    dgeev_(&jobvl, &jobvr, &n, a.a.data(), &n, wr.data(), wi.data(), &vl, &un, vr.a.data(),
           &ldvr, travail.data(), &lwork, &info, 1, 1);
    if (info != 0) return false;
    valeurs.resize((std::size_t)n);
    for (int k = 0; k < n; ++k) valeurs[(std::size_t)k] = cplx(wr[(std::size_t)k], wi[(std::size_t)k]);
    if (vecteurs) {
        *vecteurs = Mat<cplx>(n, n);
        for (int k = 0; k < n; ++k) {
            if (wi[(std::size_t)k] != 0.0 && k + 1 < n) {
                for (int i = 0; i < n; ++i) {
                    (*vecteurs)(i, k) = cplx(vr(i, k), vr(i, k + 1));
                    (*vecteurs)(i, k + 1) = cplx(vr(i, k), -vr(i, k + 1));
                }
                ++k;
            } else {
                for (int i = 0; i < n; ++i) (*vecteurs)(i, k) = cplx(vr(i, k), 0.0);
            }
        }
    }
    return true;
}

bool lapackGeneral(Mat<cplx> a, std::vector<cplx>& valeurs, Mat<cplx>* vecteurs) {
    const char jobvl = 'N', jobvr = vecteurs ? 'V' : 'N';
    const int n = a.l, un = 1;
    valeurs.assign((std::size_t)n, cplx());
    Mat<cplx> vr(vecteurs ? n : 1, vecteurs ? n : 1);
    const int ldvr = vr.l;
    int info = 0, lwork = -1;
    cplx w, vl;
    std::vector<double> rtravail((std::size_t)std::max(1, 2 * n));
    zgeev_(&jobvl, &jobvr, &n, a.a.data(), &n, valeurs.data(), &vl, &un, vr.a.data(), &ldvr,
           &w, &lwork, rtravail.data(), &info, 1, 1);
    lwork = std::max(1, (int)w.real());
    std::vector<cplx> travail((std::size_t)lwork);
    zgeev_(&jobvl, &jobvr, &n, a.a.data(), &n, valeurs.data(), &vl, &un, vr.a.data(), &ldvr,
           travail.data(), &lwork, rtravail.data(), &info, 1, 1);
    if (info != 0) return false;
    if (vecteurs) *vecteurs = std::move(vr);
    return true;
}

// SVD par diviser pour régner (dgesdd). JOB : 'N' les valeurs seules, 'S'
// la forme économique, 'A' la forme complète. V est rendue, non V'.
bool lapackSVD(Mat<double> a, char job, std::vector<double>& s, Mat<double>& U,
               Mat<double>& V) {
    const int m = a.l, n = a.c, r = std::min(m, n);
    s.assign((std::size_t)r, 0.0);
    const int ucol = job == 'A' ? m : job == 'S' ? r : 1;
    const int vtl = job == 'A' ? n : job == 'S' ? r : 1;
    U = Mat<double>(job == 'N' ? 1 : m, ucol);
    Mat<double> VT(vtl, job == 'N' ? 1 : n);
    const int ldu = U.l, ldvt = VT.l;
    std::vector<int> iw((std::size_t)std::max(1, 8 * r));
    int info = 0, lwork = -1;
    double w = 0;
    dgesdd_(&job, &m, &n, a.a.data(), &m, s.data(), U.a.data(), &ldu, VT.a.data(), &ldvt, &w,
            &lwork, iw.data(), &info, 1);
    lwork = std::max(1, (int)w);
    std::vector<double> travail((std::size_t)lwork);
    dgesdd_(&job, &m, &n, a.a.data(), &m, s.data(), U.a.data(), &ldu, VT.a.data(), &ldvt,
            travail.data(), &lwork, iw.data(), &info, 1);
    if (info != 0) return false;
    if (job != 'N') {
        V = Mat<double>(n, vtl);
        for (int i = 0; i < vtl; ++i)
            for (int j = 0; j < n; ++j) V(j, i) = VT(i, j);
    }
    return true;
}

bool lapackSVD(Mat<cplx> a, char job, std::vector<double>& s, Mat<cplx>& U, Mat<cplx>& V) {
    const int m = a.l, n = a.c, r = std::min(m, n);
    s.assign((std::size_t)r, 0.0);
    const int ucol = job == 'A' ? m : job == 'S' ? r : 1;
    const int vtl = job == 'A' ? n : job == 'S' ? r : 1;
    U = Mat<cplx>(job == 'N' ? 1 : m, ucol);
    Mat<cplx> VT(vtl, job == 'N' ? 1 : n);
    const int ldu = U.l, ldvt = VT.l;
    std::vector<int> iw((std::size_t)std::max(1, 8 * r));
    const std::size_t lrw =
        job == 'N' ? (std::size_t)std::max(1, 7 * r)
                   : (std::size_t)std::max(1, r * std::max(5 * r + 7, 2 * std::max(m, n) + 2 * r + 1));
    std::vector<double> rtravail(lrw);
    int info = 0, lwork = -1;
    cplx w;
    zgesdd_(&job, &m, &n, a.a.data(), &m, s.data(), U.a.data(), &ldu, VT.a.data(), &ldvt, &w,
            &lwork, rtravail.data(), iw.data(), &info, 1);
    lwork = std::max(1, (int)w.real());
    std::vector<cplx> travail((std::size_t)lwork);
    zgesdd_(&job, &m, &n, a.a.data(), &m, s.data(), U.a.data(), &ldu, VT.a.data(), &ldvt,
            travail.data(), &lwork, rtravail.data(), iw.data(), &info, 1);
    if (info != 0) return false;
    if (job != 'N') {
        V = Mat<cplx>(n, vtl);
        for (int i = 0; i < vtl; ++i)
            for (int j = 0; j < n; ++j) V(j, i) = std::conj(VT(i, j));
    }
    return true;
}
}  // namespace
#endif

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
#ifdef MATLIBRE_AVEC_LAPACK
    if (a.estComplexe() || b.estComplexe()) {
        Mat<cplx> r;
        lapackProduit(versComplexe(a), versComplexe(b), r);
        return depuis(r);
    }
    Mat<double> produit;
    lapackProduit(versReel(a), versReel(b), produit);
    Valeur r = depuis(produit);
#else
    if (a.estComplexe() || b.estComplexe())
        return depuis(multiplier(versComplexe(a), versComplexe(b)));
    Valeur r = depuis(multiplier(versReel(a), versReel(b)));
#endif
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
#ifdef MATLIBRE_AVEC_LAPACK
        if (complexe) {
            Mat<cplx> x = versComplexe(b);
            if (lapackResoudre(versComplexe(a), x)) return depuis(x);
        } else {
            Mat<double> x = versReel(b);
            if (lapackResoudre(versReel(a), x)) return depuis(x);
        }
#else
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
#endif
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

template <class T>
static void luEnFacteurs(Mat<T> lu, Valeur& l, Valeur& u, Valeur& p) {
    int n = lu.l, m = lu.c;
    std::vector<int> perm;
    int signe;
    luInterne(lu, perm, signe);
    int k = std::min(n, m);
    Mat<T> L(n, k), U(k, m);
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < m; ++j) {
            if (i > j) {
                if (j < k) L(i, j) = lu(i, j);
            } else if (i < k) {
                U(i, j) = lu(i, j);
            }
        }
    for (int i = 0; i < k; ++i) L(i, i) = T(1.0);
    Valeur P = Valeur::matrice(n, n);
    for (int i = 0; i < n; ++i) P.re[(std::size_t)i + (std::size_t)perm[(std::size_t)i] * n] = 1.0;
    l = depuis(L);
    u = depuis(U);
    p = P;
}

void factorisationLU(const Valeur& a, Valeur& l, Valeur& u, Valeur& p) {
    if (a.estComplexe())
        luEnFacteurs(versComplexe(a), l, u, p);
    else
        luEnFacteurs(versReel(a), l, u, p);
}

// -------------------------------------------------------------------- QR

// Factorisation de Householder, à la manière de LAPACK (xGEQRF, xGEQP3) :
// chaque réflecteur H = I - tau v v' (v(0) = 1) annule une colonne sous la
// diagonale et y laisse un réel, et une colonne déjà nulle sous la
// diagonale n'est pas réfléchie — d'où les signes de MATLAB : qr([2;0])
// rend R = [2;0], non [-2;0].
//
// Avec pivotage, on prend à chaque pas la colonne restante de plus grande
// norme (la première en cas d'égalité) : les éléments diagonaux de R
// décroissent en module, et le rang se lit sur eux.
//
// Q n'est formé qu'à la fin, depuis les réflecteurs, et seulement sur les
// colonnes demandées : la forme économique d'une matrice de cent mille
// lignes coûte cent mille fois n nombres, non cent mille au carré.
template <class T>
static void householderQR(Mat<T>& R, Mat<T>& Q, bool economique, std::vector<int>* permutation) {
    const int m = R.l, n = R.c;
    const int k = std::min(m, n);
    std::vector<std::vector<T>> vecteurs((std::size_t)k);
    std::vector<T> taus((std::size_t)k, T(0));
    if (permutation) {
        permutation->resize((std::size_t)n);
        for (int j = 0; j < n; ++j) (*permutation)[(std::size_t)j] = j;
    }
    for (int p = 0; p < k; ++p) {
        if (permutation) {
            // La colonne restante de plus grande norme vient en tête.
            int meilleure = p;
            double normeMax = -1;
            for (int j = p; j < n; ++j) {
                double s = 0;
                for (int i = p; i < m; ++i) {
                    double x = module(R(i, j));
                    s += x * x;
                }
                if (s > normeMax) {
                    normeMax = s;
                    meilleure = j;
                }
            }
            if (meilleure != p) {
                for (int i = 0; i < m; ++i) std::swap(R(i, p), R(i, meilleure));
                std::swap((*permutation)[(std::size_t)p], (*permutation)[(std::size_t)meilleure]);
            }
        }
        T alpha = R(p, p);
        double xnorme = 0;
        for (int i = p + 1; i < m; ++i) {
            double x = module(R(i, p));
            xnorme += x * x;
        }
        xnorme = std::sqrt(xnorme);
        if (xnorme == 0 && std::imag(std::complex<double>(alpha)) == 0) continue;  // tau = 0
        double reAlpha = std::real(std::complex<double>(alpha));
        double beta = -std::copysign(std::hypot(module(alpha), xnorme), reAlpha);
        T tau = (T(beta) - alpha) / T(beta);
        T echelle = T(1) / (alpha - T(beta));
        std::vector<T> v((std::size_t)(m - p));
        v[0] = T(1);
        for (int i = p + 1; i < m; ++i) v[(std::size_t)(i - p)] = R(i, p) * echelle;
        R(p, p) = T(beta);
        for (int i = p + 1; i < m; ++i) R(i, p) = T(0);
        // H' = I - conj(tau) v v' appliqué aux colonnes suivantes.
        T tauConj = conjuger(tau);
        for (int j = p + 1; j < n; ++j) {
            T w = T(0);
            for (int i = p; i < m; ++i) w += conjuger(v[(std::size_t)(i - p)]) * R(i, j);
            w *= tauConj;
            for (int i = p; i < m; ++i) R(i, j) -= v[(std::size_t)(i - p)] * w;
        }
        vecteurs[(std::size_t)p] = std::move(v);
        taus[(std::size_t)p] = tau;
    }
    // Q = H0 H1 ... appliqué aux premières colonnes de l'identité.
    const int colonnesQ = (economique && m > n) ? n : m;
    Q = Mat<T>(m, colonnesQ);
    for (int i = 0; i < std::min(m, colonnesQ); ++i) Q(i, i) = T(1);
    for (int p = k - 1; p >= 0; --p) {
        const std::vector<T>& v = vecteurs[(std::size_t)p];
        T tau = taus[(std::size_t)p];
        if (v.empty() || tau == T(0)) continue;
        for (int j = 0; j < colonnesQ; ++j) {
            T w = T(0);
            for (int i = p; i < m; ++i) w += conjuger(v[(std::size_t)(i - p)]) * Q(i, j);
            w *= tau;
            if (w == T(0)) continue;
            for (int i = p; i < m; ++i) Q(i, j) -= v[(std::size_t)(i - p)] * w;
        }
    }
    if (economique && m > n) {
        Mat<T> Re(n, n);
        for (int j = 0; j < n; ++j)
            for (int i = 0; i <= std::min(j, n - 1); ++i) Re(i, j) = R(i, j);
        R = std::move(Re);
    } else {
        for (int j = 0; j < n; ++j)
            for (int i = j + 1; i < m; ++i) R(i, j) = T(0);
    }
}

void factorisationQR(const Valeur& a, Valeur& q, Valeur& r, bool economique,
                     std::vector<int>* permutation) {
    verifierMatrice2D(a, "A");
    if (a.estComplexe()) {
        Mat<cplx> R = versComplexe(a), Q;
        householderQR(R, Q, economique, permutation);
        q = depuis(Q);
        r = depuis(R);
        return;
    }
    Mat<double> R = versReel(a), Q;
    householderQR(R, Q, economique, permutation);
    q = depuis(Q);
    r = depuis(R);
}

// -------------------------------------------------------------- Cholesky

// Cholesky d'une matrice symétrique, ou hermitienne, définie positive.
// Comme MATLAB, seul le triangle supérieur est lu — l'inférieur avec
// 'lower' — : la matrice est supposée hermitienne, non vérifiée.
template <class T>
static Valeur choleskyInterne(const Mat<T>& A, bool inferieure, int* defaut) {
    int n = A.l;
    Mat<T> L(n, n);
    // Ordre atteint sans rencontrer de pivot negatif : « [R,p] = chol(A) »
    // rend le facteur de ce bloc de tete et p = ordre+1, au lieu d'une
    // erreur. C'est ainsi que MATLAB fait tester la definie positivite
    // sans avoir a l'attraper.
    int ordre = n;
    for (int j = 0; j < n; ++j) {
        double s = partieReelle(A(j, j));
        for (int k = 0; k < j; ++k) s -= module(L(j, k)) * module(L(j, k));
        if (!(s > 0)) {
            if (!defaut) erreur("MATLAB:posdef", "Matrix must be positive definite.");
            ordre = j;
            break;
        }
        L(j, j) = T(std::sqrt(s));
        for (int i = j + 1; i < n; ++i) {
            T t = inferieure ? A(i, j) : conjuger(A(j, i));
            for (int k = 0; k < j; ++k) t -= L(i, k) * conjuger(L(j, k));
            L(i, j) = t / L(j, j);
        }
    }
    if (defaut) *defaut = (ordre == n) ? 0 : ordre + 1;
    Mat<T> B(ordre, ordre);
    for (int i = 0; i < ordre; ++i)
        for (int j = 0; j < ordre; ++j) B(i, j) = inferieure ? L(i, j) : conjuger(L(j, i));
    return depuis(B);
}

Valeur cholesky(const Valeur& a, bool inferieure, int* defaut) {
    if (!a.estCarree()) erreur("MATLAB:square", "Matrix must be square.");
    if (a.estComplexe()) return choleskyInterne(versComplexe(a), inferieure, defaut);
    return choleskyInterne(versReel(a), inferieure, defaut);
}

// -------------------------------------------------------------------- SVD

// Jacobi unilatérale : robuste, sans dépendance, précision suffisante pour
// les usages courants (rang, pseudo-inverse, norme 2, conditionnement).
// Jacobi à un côté (Hestenes) : des rotations de colonnes rendent les
// colonnes de A orthogonales deux à deux ; leurs normes sont les valeurs
// singulières. En complexe, chaque rotation porte la phase du produit
// scalaire des deux colonnes : la même formule que le réel, à la phase près.
template <class T>
static void svdJacobi(Mat<T> A, Mat<T>& U, std::vector<double>& s, Mat<T>& V) {
    int m = A.l, n = A.c;
    bool transposee = false;
    if (m < n) {
        // SVD de A^H = V S U^H : on échange U et V à la fin.
        Mat<T> At(n, m);
        for (int i = 0; i < m; ++i)
            for (int j = 0; j < n; ++j) At(j, i) = conjuger(A(i, j));
        A = At;
        std::swap(m, n);
        transposee = true;
    }
    V = Mat<T>(n, n);
    for (int i = 0; i < n; ++i) V(i, i) = T(1.0);
    const double eps = 1e-15;
    for (int balayage = 0; balayage < 60; ++balayage) {
        double horsDiag = 0;
        for (int p = 0; p < n - 1; ++p) {
            for (int q = p + 1; q < n; ++q) {
                double alpha = 0, beta = 0;
                T gamma = T(0.0);
                for (int i = 0; i < m; ++i) {
                    alpha += module(A(i, p)) * module(A(i, p));
                    beta += module(A(i, q)) * module(A(i, q));
                    gamma += conjuger(A(i, p)) * A(i, q);
                }
                double g = module(gamma);
                if (g < eps * std::sqrt(alpha * beta) || g == 0.0) continue;
                horsDiag = std::max(horsDiag, g / std::sqrt(alpha * beta));
                T ph = phase(gamma);
                double zeta = (beta - alpha) / (2.0 * g);
                double t = (zeta >= 0 ? 1.0 : -1.0) /
                           (std::fabs(zeta) + std::sqrt(1.0 + zeta * zeta));
                double c = 1.0 / std::sqrt(1.0 + t * t);
                double si = c * t;
                for (int i = 0; i < m; ++i) {
                    T ap = A(i, p), aq = A(i, q);
                    A(i, p) = c * ap - si * conjuger(ph) * aq;
                    A(i, q) = si * ph * ap + c * aq;
                }
                for (int i = 0; i < n; ++i) {
                    T vp = V(i, p), vq = V(i, q);
                    V(i, p) = c * vp - si * conjuger(ph) * vq;
                    V(i, q) = si * ph * vp + c * vq;
                }
            }
        }
        if (horsDiag < 1e-14) break;
    }
    s.assign((std::size_t)n, 0.0);
    U = Mat<T>(m, n);
    for (int j = 0; j < n; ++j) {
        double norme = 0;
        for (int i = 0; i < m; ++i) norme += module(A(i, j)) * module(A(i, j));
        norme = std::sqrt(norme);
        s[(std::size_t)j] = norme;
        if (norme > 0)
            for (int i = 0; i < m; ++i) U(i, j) = A(i, j) / norme;
    }
    // Les colonnes de U des valeurs singulières nulles — ou noyées dans les
    // erreurs d'arrondi — ne se déduisent pas de A : on les prend dans le
    // complément orthogonal des autres, pour que U soit orthonormale.
    double plusGrande = 0;
    for (double x : s) plusGrande = std::max(plusGrande, x);
    const double seuil = std::max(m, n) * 2.220446049250313e-16 * plusGrande;
    std::vector<bool> valide((std::size_t)n);
    for (int j = 0; j < n; ++j) valide[(std::size_t)j] = s[(std::size_t)j] > seuil;
    for (int j = 0; j < n; ++j) {
        if (valide[(std::size_t)j]) continue;
        std::vector<T> e((std::size_t)m);
        for (int essai = 0; essai < m; ++essai) {
            std::fill(e.begin(), e.end(), T(0.0));
            e[(std::size_t)essai] = T(1.0);
            for (int passe = 0; passe < 2; ++passe)
                for (int k = 0; k < n; ++k) {
                    if (!valide[(std::size_t)k]) continue;
                    T d = T(0.0);
                    for (int i = 0; i < m; ++i) d += conjuger(U(i, k)) * e[(std::size_t)i];
                    for (int i = 0; i < m; ++i) e[(std::size_t)i] -= d * U(i, k);
                }
            double nn = 0;
            for (const T& x : e) nn += module(x) * module(x);
            // l'un des vecteurs de base garde au moins 1/m de sa norme
            if (nn > 0.5 / m) {
                nn = std::sqrt(nn);
                for (int i = 0; i < m; ++i) U(i, j) = e[(std::size_t)i] / nn;
                valide[(std::size_t)j] = true;
                break;
            }
        }
    }
    // Tri décroissant.
    std::vector<int> ordre((std::size_t)n);
    for (int i = 0; i < n; ++i) ordre[(std::size_t)i] = i;
    std::sort(ordre.begin(), ordre.end(),
              [&](int x, int y) { return s[(std::size_t)x] > s[(std::size_t)y]; });
    Mat<T> U2(m, n), V2(n, n);
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

// Complète les colonnes rangConnu.. d'une matrice carrée dont les
// premières sont orthonormales, par Gram-Schmidt sur la base canonique.
template <class T>
static void completerOrthonormale(Mat<T>& M, int rangConnu) {
    int taille = M.l;
    for (int j = rangConnu; j < taille; ++j) {
        std::vector<T> e((std::size_t)taille, T(0.0));
        for (int essai = 0; essai < taille; ++essai) {
            std::fill(e.begin(), e.end(), T(0.0));
            e[(std::size_t)essai] = T(1.0);
            for (int passe = 0; passe < 2; ++passe)
                for (int k = 0; k < j; ++k) {
                    T d = T(0.0);
                    for (int i = 0; i < taille; ++i) d += conjuger(M(i, k)) * e[(std::size_t)i];
                    for (int i = 0; i < taille; ++i) e[(std::size_t)i] -= d * M(i, k);
                }
            double nn = 0;
            for (const T& x : e) nn += module(x) * module(x);
            if (nn > 1e-12) {
                nn = std::sqrt(nn);
                for (int i = 0; i < taille; ++i) M(i, j) = e[(std::size_t)i] / nn;
                break;
            }
        }
    }
}

// La SVD complète ou économique, pour un type de coefficients.
template <class T>
static void svdEnFacteurs(const Mat<T>& A, int m, int n, bool economique, Valeur& u, Valeur& s,
                          Valeur& v) {
    Mat<T> U, V;
    std::vector<double> sv;
#ifdef MATLIBRE_AVEC_LAPACK
    if (lapackSVD(A, economique ? 'S' : 'A', sv, U, V)) {
        const int r = (int)sv.size();
        Valeur S = economique ? Valeur::matrice(r, r) : Valeur::matrice(m, n);
        const int ls = economique ? r : m;
        for (int i = 0; i < r; ++i)
            S.re[(std::size_t)i + (std::size_t)i * ls] = sv[(std::size_t)i];
        u = depuis(U);
        v = depuis(V);
        s = S;
        return;
    }
#endif
    svdJacobi(A, U, sv, V);
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
    Mat<T> Uc(m, m), Vc(n, n);
    for (int j = 0; j < std::min(U.c, m); ++j)
        for (int i = 0; i < m; ++i) Uc(i, j) = U(i, j);
    for (int j = 0; j < std::min(V.c, n); ++j)
        for (int i = 0; i < n; ++i) Vc(i, j) = V(i, j);
    completerOrthonormale(Uc, std::min(U.c, m));
    completerOrthonormale(Vc, std::min(V.c, n));
    Valeur S = Valeur::matrice(m, n);
    for (int i = 0; i < std::min({m, n, r}); ++i)
        S.re[(std::size_t)i + (std::size_t)i * m] = sv[(std::size_t)i];
    u = depuis(Uc);
    v = depuis(Vc);
    s = S;
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
    std::vector<double> s;
#ifdef MATLIBRE_AVEC_LAPACK
    if (a.estComplexe()) {
        Mat<cplx> U, V;
        if (lapackSVD(versComplexe(a), 'N', s, U, V)) return s;
    } else {
        Mat<double> U, V;
        if (lapackSVD(versReel(a), 'N', s, U, V)) return s;
    }
#endif
    if (a.estComplexe()) {
        Mat<cplx> U, V;
        svdJacobi(versComplexe(a), U, s, V);
        return s;
    }
    Mat<double> U, V;
    svdJacobi(versReel(a), U, s, V);
    return s;
}

void decompositionSVD(const Valeur& a, Valeur& u, Valeur& s, Valeur& v, bool economique) {
    int m = a.nlignes(), n = a.ncolonnes();
    if (a.estComplexe())
        svdEnFacteurs(versComplexe(a), m, n, economique, u, s, v);
    else
        svdEnFacteurs(versReel(a), m, n, economique, u, s, v);
}

// -------------------------------------------------------- valeurs propres

// A == A.' : la symétrie simple, sans conjugaison, comme ISSYMMETRIC.
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
                if (std::fabs(xi - yi) > 1e-12 * (std::fabs(xi) + std::fabs(yi) + 1e-300))
                    return false;
            }
        }
    return true;
}

// A == A' : hermitienne — partie réelle symétrique, partie imaginaire
// antisymétrique, diagonale réelle. Pour une matrice réelle, c'est la
// symétrie.
bool estHermitienne(const Valeur& a) {
    if (!a.estCarree()) return false;
    int n = a.nlignes();
    for (int i = 0; i < n; ++i) {
        if (!a.im.empty()) {
            double d = a.im[(std::size_t)i + (std::size_t)i * n];
            double r = a.re[(std::size_t)i + (std::size_t)i * n];
            if (std::fabs(d) > 1e-12 * (std::fabs(r) + 1e-300)) return false;
        }
        for (int j = i + 1; j < n; ++j) {
            double x = a.re[(std::size_t)i + (std::size_t)j * n];
            double y = a.re[(std::size_t)j + (std::size_t)i * n];
            if (std::fabs(x - y) > 1e-12 * (std::fabs(x) + std::fabs(y) + 1e-300)) return false;
            if (!a.im.empty()) {
                double xi = a.im[(std::size_t)i + (std::size_t)j * n];
                double yi = a.im[(std::size_t)j + (std::size_t)i * n];
                if (std::fabs(xi + yi) > 1e-12 * (std::fabs(xi) + std::fabs(yi) + 1e-300))
                    return false;
            }
        }
    }
    return true;
}

// Jacobi cyclique pour les matrices symétriques réelles.
static void jacobiSymetrique(Mat<double> A, std::vector<double>& valeurs, Mat<double>& vecteurs) {
    int n = A.l;
    vecteurs = Mat<double>(n, n);
    for (int i = 0; i < n; ++i) vecteurs(i, i) = 1.0;
    // Le critère d'arrêt est relatif à la norme de A, invariante au fil
    // des rotations : un seuil absolu arrêterait tout de suite sur une
    // matrice de l'ordre de 1e-20, rendant sa diagonale pour spectre.
    double normeCarree = 0;
    for (double x : A.a) normeCarree += x * x;
    for (int balayage = 0; balayage < 100; ++balayage) {
        double somme = 0;
        for (int p = 0; p < n - 1; ++p)
            for (int q = p + 1; q < n; ++q) somme += A(p, q) * A(p, q);
        if (somme <= 1e-32 * normeCarree) break;
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

// Jacobi pour une matrice hermitienne : chaque rotation commence par
// rendre réel le terme hors diagonale — une phase sur la ligne et la
// colonne q, similitude unitaire —, puis tourne comme dans le cas
// symétrique réel. Les valeurs propres sont réelles, rendues croissantes.
static void jacobiHermitien(Mat<cplx> A, std::vector<double>& valeurs, Mat<cplx>& vecteurs) {
    int n = A.l;
    vecteurs = Mat<cplx>(n, n);
    for (int i = 0; i < n; ++i) vecteurs(i, i) = cplx(1.0, 0.0);
    double normeCarree = 0;
    for (const cplx& x : A.a) normeCarree += std::norm(x);
    for (int balayage = 0; balayage < 100; ++balayage) {
        double somme = 0;
        for (int p = 0; p < n - 1; ++p)
            for (int q = p + 1; q < n; ++q) somme += std::norm(A(p, q));
        if (somme <= 1e-32 * normeCarree) break;
        for (int p = 0; p < n - 1; ++p) {
            for (int q = p + 1; q < n; ++q) {
                double g = std::abs(A(p, q));
                if (g < 1e-300) continue;
                cplx ph = A(p, q) / g;
                for (int k = 0; k < n; ++k) A(k, q) *= std::conj(ph);
                for (int k = 0; k < n; ++k) A(q, k) *= ph;
                for (int k = 0; k < n; ++k) vecteurs(k, q) *= std::conj(ph);
                double theta = (A(q, q).real() - A(p, p).real()) / (2.0 * g);
                double t = (theta >= 0 ? 1.0 : -1.0) /
                           (std::fabs(theta) + std::sqrt(theta * theta + 1.0));
                double c = 1.0 / std::sqrt(t * t + 1.0);
                double si = t * c;
                for (int k = 0; k < n; ++k) {
                    cplx akp = A(k, p), akq = A(k, q);
                    A(k, p) = c * akp - si * akq;
                    A(k, q) = si * akp + c * akq;
                }
                for (int k = 0; k < n; ++k) {
                    cplx apk = A(p, k), aqk = A(q, k);
                    A(p, k) = c * apk - si * aqk;
                    A(q, k) = si * apk + c * aqk;
                }
                for (int k = 0; k < n; ++k) {
                    cplx vkp = vecteurs(k, p), vkq = vecteurs(k, q);
                    vecteurs(k, p) = c * vkp - si * vkq;
                    vecteurs(k, q) = si * vkp + c * vkq;
                }
            }
        }
    }
    valeurs.assign((std::size_t)n, 0.0);
    for (int i = 0; i < n; ++i) valeurs[(std::size_t)i] = A(i, i).real();
    std::vector<int> ordre((std::size_t)n);
    for (int i = 0; i < n; ++i) ordre[(std::size_t)i] = i;
    std::sort(ordre.begin(), ordre.end(),
              [&](int x, int y) { return valeurs[(std::size_t)x] < valeurs[(std::size_t)y]; });
    std::vector<double> v2((std::size_t)n);
    Mat<cplx> V2(n, n);
    for (int j = 0; j < n; ++j) {
        v2[(std::size_t)j] = valeurs[(std::size_t)ordre[(std::size_t)j]];
        for (int i = 0; i < n; ++i) V2(i, j) = vecteurs(i, ordre[(std::size_t)j]);
    }
    valeurs = v2;
    vecteurs = V2;
}

// Réduction de Hessenberg complexe, par réflexions de Householder
// H = I - 2 v v^H / (v^H v), appliquées des deux côtés.
static void hessenbergComplexe(Mat<cplx>& A) {
    int n = A.l;
    for (int k = 1; k < n - 1; ++k) {
        double norme = 0;
        for (int i = k; i < n; ++i) norme += std::norm(A(i, k - 1));
        norme = std::sqrt(norme);
        if (norme == 0) continue;
        cplx x0 = A(k, k - 1);
        cplx alpha = -phase(x0) * norme;
        std::vector<cplx> v((std::size_t)(n - k));
        v[0] = x0 - alpha;
        for (int i = k + 1; i < n; ++i) v[(std::size_t)(i - k)] = A(i, k - 1);
        double vn = 0;
        for (const cplx& x : v) vn += std::norm(x);
        if (vn == 0) continue;
        for (int j = 0; j < n; ++j) {
            cplx somme(0.0, 0.0);
            for (int i = k; i < n; ++i) somme += std::conj(v[(std::size_t)(i - k)]) * A(i, j);
            somme *= 2.0 / vn;
            for (int i = k; i < n; ++i) A(i, j) -= v[(std::size_t)(i - k)] * somme;
        }
        for (int i = 0; i < n; ++i) {
            cplx somme(0.0, 0.0);
            for (int j = k; j < n; ++j) somme += A(i, j) * v[(std::size_t)(j - k)];
            somme *= 2.0 / vn;
            for (int j = k; j < n; ++j) A(i, j) -= somme * std::conj(v[(std::size_t)(j - k)]);
        }
    }
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
template <class T>
static void equilibrer(Mat<T>& A) {
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
                    colonne += module(A(j, i));
                    ligne += module(A(i, j));
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

#ifdef MATLIBRE_AVEC_LAPACK
// Les quatre cas de MATLAB : symétrique réelle, hermitienne, générale
// réelle, générale complexe. Faux si LAPACK n'a pas convergé : les
// algorithmes écrits à la main prennent alors le relais.
static Valeur diagonale(const std::vector<double>& v) {
    const int n = (int)v.size();
    Valeur D = Valeur::matrice(n, n);
    for (int i = 0; i < n; ++i) D.re[(std::size_t)i + (std::size_t)i * n] = v[(std::size_t)i];
    return D;
}

static Valeur diagonale(const std::vector<cplx>& v) {
    const int n = (int)v.size();
    Valeur D;
    D.dims = {n, n};
    D.re.assign((std::size_t)n * n, 0.0);
    D.im.assign((std::size_t)n * n, 0.0);
    for (int i = 0; i < n; ++i) {
        D.re[(std::size_t)i + (std::size_t)i * n] = v[(std::size_t)i].real();
        D.im[(std::size_t)i + (std::size_t)i * n] = v[(std::size_t)i].imag();
    }
    D.compacter();
    return D;
}

static bool valeursPropresLapack(const Valeur& a, Valeur& valeurs, Valeur* vecteurs) {
    if (a.estComplexe() && estHermitienne(a)) {
        std::vector<double> vals;
        Mat<cplx> vecs;
        if (!lapackHermitien(versComplexe(a), vals, vecteurs ? &vecs : nullptr)) return false;
        if (vecteurs) *vecteurs = depuis(vecs);
        valeurs = vecteurs ? diagonale(vals) : Valeur::colonne(vals);
        return true;
    }
    if (!a.estComplexe() && estSymetrique(a)) {
        std::vector<double> vals;
        Mat<double> vecs;
        if (!lapackSymetrique(versReel(a), vals, vecteurs ? &vecs : nullptr)) return false;
        if (vecteurs) *vecteurs = depuis(vecs);
        valeurs = vecteurs ? diagonale(vals) : Valeur::colonne(vals);
        return true;
    }
    std::vector<cplx> vals;
    Mat<cplx> vecs;
    const bool ok = a.estComplexe()
                        ? lapackGeneral(versComplexe(a), vals, vecteurs ? &vecs : nullptr)
                        : lapackGeneral(versReel(a), vals, vecteurs ? &vecs : nullptr);
    if (!ok) return false;
    if (vecteurs) {
        *vecteurs = depuis(vecs);
        valeurs = diagonale(vals);
        return true;
    }
    Valeur lambda;
    lambda.dims = {(int)vals.size(), 1};
    lambda.re.resize(vals.size());
    lambda.im.resize(vals.size());
    for (std::size_t i = 0; i < vals.size(); ++i) {
        lambda.re[i] = vals[i].real();
        lambda.im[i] = vals[i].imag();
    }
    lambda.compacter();
    valeurs = lambda;
    return true;
}
#endif

void valeursPropres(const Valeur& a, Valeur& valeurs, Valeur* vecteurs) {
    if (!a.estCarree()) erreur("MATLAB:square", "Matrix must be square.");
    int n = a.nlignes();
    if (n == 0) {
        valeurs = Valeur::vide();
        if (vecteurs) *vecteurs = Valeur::vide();
        return;
    }
#ifdef MATLIBRE_AVEC_LAPACK
    if (valeursPropresLapack(a, valeurs, vecteurs)) return;
#endif
    if (a.estComplexe() && estHermitienne(a)) {
        std::vector<double> vals;
        Mat<cplx> vecs;
        jacobiHermitien(versComplexe(a), vals, vecs);
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
    std::vector<cplx> vals;
    if (a.estComplexe()) {
        // Une matrice complexe garde sa partie imaginaire : Hessenberg et
        // QR se font en arithmétique complexe.
        Mat<cplx> Hc = versComplexe(a);
        equilibrer(Hc);
        hessenbergComplexe(Hc);
        qrValeursPropresComplexe(Hc, vals);
    } else {
        Mat<double> H = versReel(a);
        equilibrer(H);
        hessenberg(H);
        if (!qrValeursPropres(H, vals)) {
            // Le QR réel n'a pas convergé : on recommence en complexe, où le
            // décalage peut suivre une paire conjuguée.
            Mat<cplx> Hc(H.l, H.c);
            for (int i = 0; i < H.l; ++i)
                for (int j = 0; j < H.c; ++j) Hc(i, j) = cplx(H(i, j), 0.0);
            qrValeursPropresComplexe(Hc, vals);
        }
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
    // Un type inconnu ne doit pas se replier en silence sur la norme 2 ou
    // sur « inf » : « norm(v, 'frobenius') » rendait alors un nombre
    // vraisemblable et faux. Seuls comptent les noms que MATLAB accepte,
    // et pour un vecteur, tout exposant fini.
    {
        bool nomConnu = t == "fro" || t == "inf" || t == "Inf" || t == "-inf" ||
                        t == "-Inf";
        if (!nomConnu) {
            const char* debut = t.c_str();
            char* fin = nullptr;
            double p = std::strtod(debut, &fin);
            bool nombreEntier = fin && *fin == '\0' && fin != debut && std::isfinite(p);
            bool vecteur = a.estVecteur() || a.estScalaire();
            if (!nombreEntier)
                erreur("MATLAB:norm:unknownNormType",
                       "The only matrix norms available are 1, 2, inf, and 'fro'.");
            if (!vecteur && p != 1.0 && p != 2.0)
                erreur("MATLAB:norm:unknownNormType",
                       "The only matrix norms available are 1, 2, inf, and 'fro'.");
            if (vecteur && p <= 0.0)
                erreur("MATLAB:norm:unknownNormType",
                       "The norm exponent must be positive.");
        }
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

static Valeur identiteCarree(int n) {
    Valeur I = Valeur::matrice(n, n);
    for (int i = 0; i < n; ++i) I.re[(std::size_t)i + (std::size_t)i * n] = 1.0;
    return I;
}

static double ecartMaximal(const Valeur& a) {
    double e = 0;
    for (std::size_t i = 0; i < a.re.size(); ++i) {
        double re = a.re[i];
        double im = a.im.empty() ? 0.0 : a.im[i];
        e = std::max(e, std::hypot(re, im));
    }
    return e;
}

// Racine carrée principale par l'itération de Denman et Beavers.
//
// La décomposition en éléments propres ne convient pas : une matrice
// défective — dont une valeur propre est multiple sans autant de vecteurs
// propres — n'a pas de base de vecteurs propres, et le produit V D V^-1
// rend alors n'importe quoi. L'itération, elle, n'emploie que des
// inversions, et converge quadratiquement pour toute matrice sans valeur
// propre sur le demi-axe réel négatif.
static Valeur racinePrincipale(const Valeur& a, bool& ok) {
    int n = a.nlignes();
    Valeur Y = a;
    Valeur Z = identiteCarree(n);
    ok = false;
    for (int k = 0; k < 60; ++k) {
        Valeur Ys = operationBinaire("+", Y, inverseMatrice(Z));
        Valeur Zs = operationBinaire("+", Z, inverseMatrice(Y));
        Y = operationBinaire(".*", Ys, Valeur::scalaire(0.5));
        Z = operationBinaire(".*", Zs, Valeur::scalaire(0.5));
        // Le critère d'arrêt : Y Z doit tendre vers l'identité.
        Valeur ecart = operationBinaire("-", produitMatrice(Y, Z), identiteCarree(n));
        if (ecartMaximal(ecart) < 1e-14) { ok = true; break; }
    }
    return Y;
}

Valeur racineMatrice(const Valeur& a) {
    if (!a.estCarree()) erreur("MATLAB:square", "Matrix must be square.");
    bool ok = false;
    Valeur r = racinePrincipale(a, ok);
    if (ok) {
        r.compacter();
        return r;
    }
    // L'itération n'a pas convergé — valeur propre sur le demi-axe réel
    // négatif, ou matrice singulière : on retombe sur la voie spectrale,
    // qui traite ces cas au prix de la précision sur les défectives.
    return puissanceMatrice(a, Valeur::scalaire(0.5));
}

Valeur logarithmeMatrice(const Valeur& a) {
    if (!a.estCarree()) erreur("MATLAB:square", "Matrix must be square.");
    int n = a.nlignes();
    // Mise à l'échelle inverse : on prend des racines carrées jusqu'à
    // approcher l'identité, où la série du logarithme converge vite, puis
    // on remultiplie par deux puissance le nombre de racines prises.
    //
    // Là encore, passer par les éléments propres serait faux sur une
    // matrice défective : le logarithme d'un bloc de Jordan n'est pas
    // diagonal, et la voie spectrale le rendait pourtant tel.
    Valeur X = a;
    int racines = 0;
    bool utilisable = true;
    for (; racines < 40; ++racines) {
        double ecart = 0;
        for (int i = 0; i < n; ++i)
            for (int j = 0; j < n; ++j) {
                std::size_t k = (std::size_t)i + (std::size_t)j * n;
                double re = X.re[k] - (i == j ? 1.0 : 0.0);
                double im = X.im.empty() ? 0.0 : X.im[k];
                ecart += re * re + im * im;
            }
        if (std::sqrt(ecart) < 0.25) break;
        bool ok = false;
        Valeur suivant = racinePrincipale(X, ok);
        if (!ok) { utilisable = false; break; }
        X = suivant;
    }
    if (!utilisable || racines >= 40) {
        // Voie spectrale de secours, pour ce que l'itération ne sait pas
        // traiter : une valeur propre réelle négative, par exemple.
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
    // log(X) = 2 atanh((X-I)(X+I)^-1), développé en série impaire : elle
    // converge d'autant plus vite que X est proche de l'identité, ce que
    // les racines carrées ont assuré.
    Valeur I = identiteCarree(n);
    Valeur T = produitMatrice(operationBinaire("-", X, I),
                              inverseMatrice(operationBinaire("+", X, I)));
    Valeur T2 = produitMatrice(T, T);
    Valeur somme = T;
    Valeur terme = T;
    for (int k = 1; k < 60; ++k) {
        terme = produitMatrice(terme, T2);
        double poids = 1.0 / (2.0 * k + 1.0);
        Valeur ajout = operationBinaire(".*", terme, Valeur::scalaire(poids));
        double norme = ecartMaximal(ajout);
        somme = operationBinaire("+", somme, ajout);
        if (norme < 1e-18) break;
    }
    Valeur r = operationBinaire(".*", somme,
                                Valeur::scalaire(2.0 * std::pow(2.0, (double)racines)));
    r.compacter();
    return r;
}

template <class T>
static Valeur formeEchelonneeInterne(Mat<T> A) {
    int m = A.l, n = A.c;
    int ligne = 0;
    double tol = std::max(m, n) * 2.220446049250313e-16;
    double maxAbs = 0;
    for (const T& x : A.a) maxAbs = std::max(maxAbs, module(x));
    tol *= std::max(maxAbs, 1.0);
    for (int col = 0; col < n && ligne < m; ++col) {
        int pivot = ligne;
        for (int i = ligne; i < m; ++i)
            if (module(A(i, col)) > module(A(pivot, col))) pivot = i;
        if (module(A(pivot, col)) <= tol) {
            for (int i = ligne; i < m; ++i) A(i, col) = T(0.0);
            continue;
        }
        for (int j = 0; j < n; ++j) std::swap(A(ligne, j), A(pivot, j));
        T p = A(ligne, col);
        for (int j = 0; j < n; ++j) A(ligne, j) /= p;
        for (int i = 0; i < m; ++i) {
            if (i == ligne) continue;
            T f = A(i, col);
            if (module(f) == 0.0) continue;
            for (int j = 0; j < n; ++j) A(i, j) -= f * A(ligne, j);
        }
        ++ligne;
    }
    return depuis(A);
}

Valeur formeEchelonnee(const Valeur& a) {
    if (a.estComplexe()) return formeEchelonneeInterne(versComplexe(a));
    return formeEchelonneeInterne(versReel(a));
}

template <class T>
static Valeur noyauInterne(const Mat<T>& A) {
    Mat<T> U, V;
    std::vector<double> s;
    svdJacobi(A, U, s, V);
    int n = A.c;
    double smax = s.empty() ? 0 : s[0];
    double tol = std::max(A.l, n) * smax * 2.220446049250313e-16;
    std::vector<int> colonnes;
    for (int k = 0; k < (int)s.size(); ++k)
        if (s[(std::size_t)k] <= tol) colonnes.push_back(k);
    // Une matrice plus large que haute : V n'a que min(m,n) colonnes
    // calculées ; le reste du noyau est le complément orthogonal.
    Mat<T> Vc(n, n);
    for (int j = 0; j < std::min(V.c, n); ++j)
        for (int i = 0; i < n; ++i) Vc(i, j) = V(i, j);
    completerOrthonormale(Vc, std::min(V.c, n));
    for (int k = (int)s.size(); k < n; ++k) colonnes.push_back(k);
    Mat<T> N(n, (int)colonnes.size());
    for (std::size_t j = 0; j < colonnes.size(); ++j)
        for (int i = 0; i < n; ++i) N(i, (int)j) = Vc(i, colonnes[j]);
    return depuis(N);
}

Valeur noyau(const Valeur& a) {
    if (a.estComplexe()) return noyauInterne(versComplexe(a));
    return noyauInterne(versReel(a));
}

template <class T>
static Valeur imageInterne(const Mat<T>& A) {
    Mat<T> U, V;
    std::vector<double> s;
    svdJacobi(A, U, s, V);
    double smax = s.empty() ? 0 : s[0];
    double tol = std::max(A.l, A.c) * smax * 2.220446049250313e-16;
    int r = 0;
    for (double x : s)
        if (x > tol) ++r;
    Mat<T> B(A.l, r);
    for (int j = 0; j < r; ++j)
        for (int i = 0; i < A.l; ++i) B(i, j) = U(i, j);
    return depuis(B);
}

Valeur imageOrthonormale(const Valeur& a) {
    if (a.estComplexe()) return imageInterne(versComplexe(a));
    return imageInterne(versReel(a));
}

}  // namespace matlibre
