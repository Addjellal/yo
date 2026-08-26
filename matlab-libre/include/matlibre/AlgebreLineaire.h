// AlgebreLineaire.h — factorisations et solveurs.
//
// Tout est écrit ici, sans dépendance externe : LU avec pivot partiel, QR de
// Householder, Cholesky, SVD de Jacobi unilatérale, valeurs propres par
// Hessenberg + QR à décalage. Si LAPACK et BLAS sont trouvés à la
// compilation (option MATLIBRE_AVEC_LAPACK), les mêmes fonctions y
// délèguent les cas denses volumineux.
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
Valeur cholesky(const Valeur& a, bool inferieure = false);
void factorisationLU(const Valeur& a, Valeur& l, Valeur& u, Valeur& p);
void factorisationQR(const Valeur& a, Valeur& q, Valeur& r, bool economique = false);
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

}  // namespace matlibre
