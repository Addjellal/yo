// Algebre.cpp — algèbre linéaire exposée au langage.
#include <algorithm>
#include <cmath>

#include "matlibre/AlgebreLineaire.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {
namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

FONCTION(fnInv) {
    INUTILISE
    exigerArguments(args, 1, 1, "inv");
    return {inverseMatrice(args[0])};
}
FONCTION(fnDet) {
    INUTILISE
    exigerArguments(args, 1, 1, "det");
    return {determinantMatrice(args[0])};
}
FONCTION(fnTrace) {
    INUTILISE
    exigerArguments(args, 1, 1, "trace");
    exigerNumerique(args[0], "trace");
    return {traceMatrice(args[0])};
}
FONCTION(fnRank) {
    INUTILISE
    exigerArguments(args, 1, 2, "rank");
    double tol = args.size() > 1 ? args[1].scal() : -1.0;
    return {Valeur::scalaire((double)rangMatrice(args[0], tol))};
}
FONCTION(fnPinv) {
    INUTILISE
    exigerArguments(args, 1, 2, "pinv");
    return {pseudoInverse(args[0], args.size() > 1 ? args[1].scal() : -1.0)};
}
FONCTION(fnCond) {
    INUTILISE
    exigerArguments(args, 1, 2, "cond");
    // COND(A) est le rapport des valeurs singulieres extremes. COND(A,P)
    // est ||A||_P * ||inv(A)||_P, qui n'est pas le meme nombre : pour la
    // matrice de Hilbert d'ordre six, 1,5e7 en norme 2 et 2,9e7 en norme 1.
    // Ignorer P rendait donc une valeur fausse en silence.
    if (args.size() < 2) return {conditionnement(args[0])};
    bool deux = false;
    if (args[1].estNumerique() && args[1].estScalaire())
        deux = args[1].scal() == 2.0;
    if (deux) return {conditionnement(args[0])};
    const Valeur& a = args[0];
    if (a.estVide()) return {Valeur::scalaire(0.0)};
    if (a.nlignes() != a.ncolonnes())
        erreur("MATLAB:square", "Matrix must be square.");
    Valeur na = normeMatrice(a, args[1]);
    double normeDirecte = na.nelem() ? na.re[0] : 0.0;
    if (normeDirecte == 0.0) return {Valeur::scalaire(INFINITY)};
    Valeur inv;
    try {
        inv = inverseMatrice(a);
    } catch (...) {
        return {Valeur::scalaire(INFINITY)};
    }
    Valeur ni = normeMatrice(inv, args[1]);
    double normeInverse = ni.nelem() ? ni.re[0] : 0.0;
    return {Valeur::scalaire(normeDirecte * normeInverse)};
}

FONCTION(fnRcond) {
    INUTILISE
    exigerArguments(args, 1, 1, "rcond");
    // Estimation en norme 1 : 1/(||A||_1 * ||A^-1||_1). Une matrice
    // singulière rend zéro, ce que le code appelant teste.
    const Valeur& a = args[0];
    if (a.nlignes() != a.ncolonnes())
        erreur("MATLAB:square", "Matrix must be square.");
    Valeur c = conditionnement(a);
    double valeur = c.nelem() ? c.re[0] : 0.0;
    if (!std::isfinite(valeur) || valeur == 0.0) return {Valeur::scalaire(0.0)};
    return {Valeur::scalaire(1.0 / valeur)};
}
FONCTION(fnNorm) {
    INUTILISE
    exigerArguments(args, 1, 2, "norm");
    // Un objet n'est pas une matrice. Faute de ce controle, « norm(sys) »
    // sur un modele LTI rendait 0 -- une norme fausse, et sans un mot.
    exigerNumerique(args[0], "norm");
    return {normeMatrice(args[0], args.size() > 1 ? args[1] : Valeur::vide())};
}
FONCTION(fnExpm) {
    INUTILISE
    exigerNumerique(args[0], "expm");
    return {exponentielleMatrice(args[0])};
}
FONCTION(fnLogm) {
    INUTILISE
    return {logarithmeMatrice(args[0])};
}
FONCTION(fnSqrtm) {
    INUTILISE
    return {racineMatrice(args[0])};
}
FONCTION(fnNull) {
    INUTILISE
    return {noyau(args[0])};
}
FONCTION(fnOrth) {
    INUTILISE
    return {imageOrthonormale(args[0])};
}
FONCTION(fnRref) {
    INUTILISE
    Valeur r = formeEchelonnee(args[0]);
    if (nargout <= 1) return {r};
    // MATLAB rend aussi les colonnes de pivot : la premiere colonne non
    // nulle de chaque ligne de la forme reduite. C'est ce qui donne le
    // rang, et les variables libres d'un systeme.
    int lignes = r.nlignes(), colonnes = r.ncolonnes();
    std::vector<double> pivots;
    for (int i = 0; i < lignes; ++i)
        for (int j = 0; j < colonnes; ++j)
            if (std::fabs(r.re[(std::size_t)i + (std::size_t)j * lignes]) > 1e-12) {
                pivots.push_back(j + 1);
                break;
            }
    return {r, Valeur::ligne(pivots)};
}

FONCTION(fnLu) {
    INUTILISE
    exigerArguments(args, 1, 1, "lu");
    Valeur l, u, p;
    factorisationLU(args[0], l, u, p);
    if (nargout <= 1) return {u};
    if (nargout == 2) return {produitMatrice(transposer(p, false), l), u};
    return {l, u, p};
}

FONCTION(fnQr) {
    INUTILISE
    exigerArguments(args, 1, 2, "qr");
    Valeur q, r;
    bool economique = args.size() > 1 && args[1].scal() == 0;
    factorisationQR(args[0], q, r, economique);
    if (nargout <= 1) return {r};
    return {q, r};
}

FONCTION(fnChol) {
    INUTILISE
    exigerArguments(args, 1, 2, "chol");
    exigerNumerique(args[0], "chol");
    bool inferieure = args.size() > 1 && args[1].versTexte() == "lower";
    if (nargout >= 2) {
        int defaut = 0;
        Valeur r = cholesky(args[0], inferieure, &defaut);
        return {r, Valeur::scalaire(defaut)};
    }
    return {cholesky(args[0], inferieure)};
}

// « eig(A,B) » : le probleme generalise A x = lambda B x. Le second
// argument etait accepte puis ignore, si bien que MANOVA1 et l'analyse
// discriminante travaillaient sur les valeurs propres de A seule.
//
// Quand B est symetrique definie positive — le cas des matrices de
// dispersion —, la reduction de Cholesky ramene au probleme ordinaire
// sans perdre la symetrie ; sinon on passe par B\A.
void valeursPropresGeneralisees(const Valeur& a, const Valeur& b, Valeur& valeurs,
                                Valeur* vecteurs) {
    if (a.nlignes() != a.ncolonnes() || b.nlignes() != b.ncolonnes() ||
        a.nlignes() != b.nlignes())
        erreur("MATLAB:eig:matrixDimensionMismatch",
               "Matrices must be square and of the same size.");
    int defaut = 0;
    Valeur L;
    if (estSymetrique(b)) {
        L = cholesky(b, true, &defaut);
    } else {
        defaut = 1;
    }
    if (defaut == 0) {
        // C = L^-1 A L^-T, dont les vecteurs propres v donnent x = L^-T v.
        Valeur Lt = transposer(L, true);
        Valeur C = divisionGauche(L, a);
        C = transposer(divisionGauche(L, transposer(C, true)), true);
        valeursPropres(C, valeurs, vecteurs);
        if (vecteurs) *vecteurs = divisionGauche(Lt, *vecteurs);
        return;
    }
    // B inversible et bien conditionnee : B\A est exact, et c'est ce qui
    // tournait deja. On ne le change pas.
    const int n = a.nlignes();
    const double condB = conditionnement(b).scal();
    if (std::isfinite(condB) && condB < 1e12) {
        Valeur C = divisionGauche(b, a);
        valeursPropres(C, valeurs, vecteurs);
        return;
    }
    // B singuliere -- c'est le cas du faisceau de Rosenbrock dont on tire
    // les zeros de transmission. « B\A » n'y a plus de sens, et rendait des
    // nombres quelconques sans rien dire. On decale et on inverse : si
    // (A - s B) est inversible, les valeurs propres mu de (A - s B)\B
    // donnent lambda = s + 1/mu, et mu nul dit une valeur propre infinie,
    // comme MATLAB la rend. Les vecteurs propres sont les memes.
    const double echelle = std::max({1.0, normeMatrice(a, Valeur::vide()).scal(),
                                     normeMatrice(b, Valeur::vide()).scal()});
    const double decalages[] = {0.6180339887, -1.3247179572, 2.2360679775,
                                -0.4142135624, 3.1415926536};
    for (double d : decalages) {
        const double sigma = d * echelle;
        Valeur decale = operationBinaire("-", a,
                                         operationBinaire("*", Valeur::scalaire(sigma), b));
        const double cond = conditionnement(decale).scal();
        if (!std::isfinite(cond) || cond > 1e12) continue;
        Valeur M = divisionGauche(decale, b);
        Valeur mu;
        valeursPropres(M, mu, vecteurs);
        const double seuil = 64.0 * 2.220446049250313e-16 * n *
                             std::max(1.0, normeMatrice(M, Valeur::vide()).scal());
        // Avec les vecteurs, les valeurs viennent en matrice diagonale ;
        // sans eux, en colonne. On lit la diagonale dans les deux cas, et
        // l'on rend la meme forme que la reponse ordinaire.
        const bool diagonale = vecteurs != nullptr;
        const bool complexe = !mu.im.empty();
        std::vector<double> lambdaRe((std::size_t)n, 0.0), lambdaIm((std::size_t)n, 0.0);
        bool aImag = false;
        for (int i = 0; i < n; ++i) {
            const std::size_t place = diagonale ? (std::size_t)i + (std::size_t)i * n
                                                : (std::size_t)i;
            const double re = mu.re[place];
            const double im = complexe ? mu.im[place] : 0.0;
            const double mod2 = re * re + im * im;
            if (std::sqrt(mod2) <= seuil) {
                lambdaRe[(std::size_t)i] = INFINITY;
                continue;
            }
            lambdaRe[(std::size_t)i] = sigma + re / mod2;
            lambdaIm[(std::size_t)i] = -im / mod2;
            if (lambdaIm[(std::size_t)i] != 0.0) aImag = true;
        }
        if (diagonale) {
            valeurs = Valeur::matrice(n, n);
            std::vector<double> im((std::size_t)n * n, 0.0);
            for (int i = 0; i < n; ++i) {
                valeurs.re[(std::size_t)i + (std::size_t)i * n] = lambdaRe[(std::size_t)i];
                im[(std::size_t)i + (std::size_t)i * n] = lambdaIm[(std::size_t)i];
            }
            if (aImag) valeurs.im = im;
        } else {
            valeurs = Valeur::matrice(n, 1);
            valeurs.re = lambdaRe;
            if (aImag) valeurs.im = lambdaIm;
        }
        return;
    }
    // Aucun decalage ne rend A - s B inversible : le faisceau est
    // singulier, det(A - lambda B) est nul pour tout lambda, et MATLAB rend
    // alors NaN. Rendre autre chose serait inventer.
    valeurs = Valeur::matrice(n, 1, NAN);
    if (vecteurs) *vecteurs = Valeur::matrice(n, n, NAN);
}

FONCTION(fnEig) {
    INUTILISE
    exigerArguments(args, 1, 2, "eig");
    Valeur valeurs, vecteurs;
    if (args.size() >= 2 && !args[1].estVide()) {
        if (nargout >= 2) {
            valeursPropresGeneralisees(args[0], args[1], valeurs, &vecteurs);
            return {vecteurs, valeurs};
        }
        valeursPropresGeneralisees(args[0], args[1], valeurs, nullptr);
        return {valeurs};
    }
    if (nargout >= 2) {
        valeursPropres(args[0], valeurs, &vecteurs);
        return {vecteurs, valeurs};
    }
    valeursPropres(args[0], valeurs, nullptr);
    return {valeurs};
}

FONCTION(fnSvd) {
    INUTILISE
    exigerArguments(args, 1, 2, "svd");
    Valeur u, s, v;
    bool economique = args.size() > 1;
    decompositionSVD(args[0], u, s, v, economique);
    if (nargout <= 1) {
        // svd(A) rend le vecteur des valeurs singulières.
        int n = std::min(s.nlignes(), s.ncolonnes());
        std::vector<double> d;
        for (int k = 0; k < n; ++k)
            d.push_back(s.re[(std::size_t)k + (std::size_t)k * s.nlignes()]);
        return {Valeur::colonne(d)};
    }
    return {u, s, v};
}

FONCTION(fnLinsolve) {
    INUTILISE
    exigerArguments(args, 2, 3, "linsolve");
    return {divisionGauche(args[0], args[1])};
}

FONCTION(fnIssymmetric) {
    INUTILISE
    return {Valeur::booleen(estSymetrique(args[0]))};
}

FONCTION(fnIsdiag) {
    INUTILISE
    exigerNumerique(args[0], "isdiag");
    const Valeur& v = args[0];
    int l = v.nlignes(), c = v.ncolonnes();
    for (int i = 0; i < l; ++i)
        for (int j = 0; j < c; ++j)
            if (i != j && v.re[(std::size_t)i + (std::size_t)j * l] != 0)
                return {Valeur::booleen(false)};
    return {Valeur::booleen(true)};
}

FONCTION(fnIstriu) {
    INUTILISE
    exigerNumerique(args[0], "istriu");
    const Valeur& v = args[0];
    int l = v.nlignes(), c = v.ncolonnes();
    for (int i = 0; i < l; ++i)
        for (int j = 0; j < c; ++j)
            if (i > j && v.re[(std::size_t)i + (std::size_t)j * l] != 0)
                return {Valeur::booleen(false)};
    return {Valeur::booleen(true)};
}

FONCTION(fnIstril) {
    INUTILISE
    exigerNumerique(args[0], "istril");
    const Valeur& v = args[0];
    int l = v.nlignes(), c = v.ncolonnes();
    for (int i = 0; i < l; ++i)
        for (int j = 0; j < c; ++j)
            if (i < j && v.re[(std::size_t)i + (std::size_t)j * l] != 0)
                return {Valeur::booleen(false)};
    return {Valeur::booleen(true)};
}

FONCTION(fnHilb) {
    INUTILISE
    int n = (int)argScalaire(args, 0, "hilb");
    Valeur r = Valeur::matrice(n, n);
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            r.re[(std::size_t)i + (std::size_t)j * n] = 1.0 / (i + j + 1);
    return {r};
}

FONCTION(fnVander) {
    INUTILISE
    exigerArguments(args, 1, 1, "vander");
    exigerNumerique(args[0], "vander");
    const Valeur& v = args[0];
    int n = (int)v.nelem();
    Valeur r = Valeur::matrice(n, n);
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            r.re[(std::size_t)i + (std::size_t)j * n] = std::pow(v.re[(std::size_t)i],
                                                                 n - 1 - j);
    return {r};
}

FONCTION(fnToeplitz) {
    INUTILISE
    exigerArguments(args, 1, 2, "toeplitz");
    exigerNumerique(args[0], "toeplitz");
    if (args.size() > 1) exigerNumerique(args[1], "toeplitz");
    const Valeur& c = args[0];
    const Valeur& r = args.size() > 1 ? args[1] : args[0];
    int m = (int)c.nelem(), n = (int)r.nelem();
    Valeur t = Valeur::matrice(m, n);
    for (int i = 0; i < m; ++i)
        for (int j = 0; j < n; ++j)
            t.re[(std::size_t)i + (std::size_t)j * m] =
                (i >= j) ? c.re[(std::size_t)(i - j)] : r.re[(std::size_t)(j - i)];
    return {t};
}

}  // namespace

void enregistrerAlgebre(Interpreteur& it) {
    it.enregistrer("inv", fnInv, "algebre", "inv  Inverse d'une matrice carree.");
    it.enregistrer("det", fnDet, "algebre", "det  Determinant.");
    it.enregistrer("trace", fnTrace, "algebre", "trace  Somme de la diagonale.");
    it.enregistrer("rank", fnRank, "algebre", "rank  Rang numerique.");
    it.enregistrer("pinv", fnPinv, "algebre", "pinv  Pseudo-inverse de Moore-Penrose.");
    it.enregistrer("cond", fnCond, "algebre", "cond  Conditionnement : norme 2 par defaut, COND(A,P) en norme P.");
    it.enregistrer("rcond", fnRcond, "algebre",
                   "rcond  Estimation de l'inverse du conditionnement.");
    it.enregistrer("norm", fnNorm, "algebre", "norm  Norme d'un vecteur ou d'une matrice.");
    it.enregistrer("expm", fnExpm, "algebre", "expm  Exponentielle de matrice.");
    it.enregistrer("logm", fnLogm, "algebre", "logm  Logarithme de matrice.");
    it.enregistrer("sqrtm", fnSqrtm, "algebre", "sqrtm  Racine carree de matrice.");
    it.enregistrer("null", fnNull, "algebre", "null  Base du noyau.");
    it.enregistrer("orth", fnOrth, "algebre", "orth  Base orthonormale de l'image.");
    it.enregistrer("rref", fnRref, "algebre", "rref  Forme echelonnee reduite.");
    it.enregistrer("lu", fnLu, "algebre", "lu  Factorisation LU avec pivot.");
    it.enregistrer("qr", fnQr, "algebre", "qr  Factorisation QR de Householder.");
    it.enregistrer("chol", fnChol, "algebre", "chol  Factorisation de Cholesky.");
    it.enregistrer("eig", fnEig, "algebre", "eig  Valeurs et vecteurs propres.");
    it.enregistrer("svd", fnSvd, "algebre", "svd  Decomposition en valeurs singulieres.");
    it.enregistrer("linsolve", fnLinsolve, "algebre", "linsolve  Resolution de systeme lineaire.");
    it.enregistrer("issymmetric", fnIssymmetric, "algebre", "issymmetric  Matrice symetrique ?");
    it.enregistrer("isdiag", fnIsdiag, "algebre", "isdiag  Matrice diagonale ?");
    it.enregistrer("istriu", fnIstriu, "algebre", "istriu  Triangulaire superieure ?");
    it.enregistrer("istril", fnIstril, "algebre", "istril  Triangulaire inferieure ?");
    it.enregistrer("hilb", fnHilb, "algebre", "hilb  Matrice de Hilbert.");
    it.enregistrer("vander", fnVander, "algebre", "vander  Matrice de Vandermonde.");
    it.enregistrer("toeplitz", fnToeplitz, "algebre", "toeplitz  Matrice de Toeplitz.");
}

}  // namespace matlibre
