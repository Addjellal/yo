// Creux.h — matrices creuses au format colonnes comprimées.
//
// Le stockage est celui de MATLAB et de SuiteSparse : pour chaque colonne,
// l'indice de ligne et la valeur de ses éléments non nuls. Les fonctions
// qui savent en tirer parti sont recensées dans « natifsCreux » ; toutes
// les autres reçoivent une copie dense, ce qui garantit qu'aucun résultat
// ne change selon le stockage.
#pragma once

#include <string>

#include "matlibre/Valeur.h"

namespace matlibre {

Valeur creuxDepuisDense(const Valeur& dense, double tolerance = 0.0);
Valeur denseDepuisCreux(const Valeur& creux);
Valeur creuxDepuisTriplets(const Valeur& lignes, const Valeur& colonnes,
                           const Valeur& valeurs, int m, int n);
Valeur creuxVide(int m, int n);
double elementCreux(const Valeur& s, int i, int j);
std::size_t nombreNonNuls(const Valeur& s);
Valeur produitCreux(const Valeur& a, const Valeur& b);
Valeur sommeCreuse(const Valeur& a, const Valeur& b, double signe);
Valeur produitElementCreux(const Valeur& a, const Valeur& b);
Valeur transposeeCreuse(const Valeur& a);
Valeur resoudreCreux(const Valeur& a, const Valeur& b);
Valeur assurerDense(const Valeur& v);
std::string rendreCreux(const Valeur& s);

}  // namespace matlibre
