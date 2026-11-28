// AlgebreLineaire.h — factorisations et solveurs.
//
// Tout est écrit ici, sans dépendance externe : LU avec pivot partiel, QR de
// Householder, Cholesky, SVD de Jacobi unilatérale, valeurs propres par
// Hessenberg + QR à décalage. Aucune ne délègue à LAPACK : c'est ce qui
// rend eig et svd lents sur les grandes matrices denses (voir
// documentation/audit-reprise.md).
#pragma once

#include <complex>
#include <vector>

#include "matlibre/Valeur.h"

namespace matlibre {

Valeur produitMatrice(const Valeur& a, const Valeur& b);
Valeur divisionGauche(const Valeur& a, const Valeur& b);   // a \ b
Valeur divisionDroite(const Valeur& a, const Valeur& b);   // a / b
Valeur puissanceMatrice(const Valeur& a, const Valeur& p);
Valeur inverseMatrice(const Valeur& a);
Valeur determinantMatrice(const Valeur& a);
// « [R,p] = chol(A) » : si « defaut » est fourni, une matrice qui n'est
// pas definie positive ne provoque pas d'erreur — on y range l'ordre du
// premier pivot fautif, et le facteur rendu est celui du bloc de tete.
Valeur cholesky(const Valeur& a, bool inferieure = false, int* defaut = nullptr);
void factorisationLU(const Valeur& a, Valeur& l, Valeur& u, Valeur& p);
// Avec « permutation », la factorisation pivote les colonnes : A(:,P) = Q*R,
// P rendu en indices à partir de zéro.
void factorisationQR(const Valeur& a, Valeur& q, Valeur& r, bool economique = false,
                     std::vector<int>* permutation = nullptr);
void decompositionSVD(const Valeur& a, Valeur& u, Valeur& s, Valeur& v, bool economique = false);
void valeursPropres(const Valeur& a, Valeur& valeurs, Valeur* vecteurs);
Valeur normeMatrice(const Valeur& a, const Valeur& type);
Valeur exponentielleMatrice(const Valeur& a);
Valeur racineMatrice(const Valeur& a);
Valeur logarithmeMatrice(const Valeur& a);
int rangMatrice(const Valeur& a, double tolerance = -1.0);
Valeur pseudoInverse(const Valeur& a, double tolerance = -1.0);
Valeur conditionnement(const Valeur& a);
Valeur traceMatrice(const Valeur& a);
Valeur noyau(const Valeur& a);
Valeur imageOrthonormale(const Valeur& a);
Valeur formeEchelonnee(const Valeur& a);
bool estSymetrique(const Valeur& a);
bool estHermitienne(const Valeur& a);

}  // namespace matlibre
