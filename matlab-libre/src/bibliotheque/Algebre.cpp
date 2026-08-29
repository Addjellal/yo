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
    return {conditionnement(args[0])};
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
    bool inferieure = args.size() > 1 && args[1].versTexte() == "lower";
    return {cholesky(args[0], inferieure)};
}

FONCTION(fnEig) {
    INUTILISE
    exigerArguments(args, 1, 2, "eig");
    Valeur valeurs, vecteurs;
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
    it.enregistrer("cond", fnCond, "algebre", "cond  Conditionnement en norme 2.");
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
