// FichierMat.h — lecture et écriture des fichiers MAT.
//
// Le format est celui que MathWorks documente publiquement : un en-tête de
// cent vingt-huit octets, puis des « éléments de données » étiquetés par
// un type et une longueur, dont l'un — miMATRIX — décrit un tableau avec
// sa classe, ses dimensions, son nom et ses valeurs. Rien n'est repris
// d'une implémentation existante : tout est écrit d'après la description
// du format.
//
// On lit le niveau 5, compressé ou non, et le niveau 4. On écrit le
// niveau 5 ; « save » le fait sans compresser, ce qui est exactement ce
// que MATLAB produit avec « -v6 » et que toutes ses versions relisent.
#pragma once

#include <string>
#include <vector>

#include "matlibre/Valeur.h"

namespace matlibre {

struct VariableMat {
    std::string nom;
    Valeur valeur;
    bool globale = false;
    // Ce que la lecture a du signaler sans pouvoir s'arreter : un objet de
    // classe MATLAB que MatLibre ne sait pas reconstruire, par exemple.
    // Vide quand tout s'est bien passe ; « load » l'affiche alors comme un
    // avertissement.
    std::string avertissement;
};

// Rend les variables du fichier, dans l'ordre où elles y sont écrites.
std::vector<VariableMat> lireMat(const std::string& chemin);

// N'en lit que l'inventaire : nom, dimensions et classe, sans charger les
// données. C'est ce que montre « whos -file ».
std::vector<VariableMat> inventaireMat(const std::string& chemin);

// Écrit un fichier MAT de niveau 5. « compresser » enveloppe chaque
// variable dans un flux zlib, comme le fait MATLAB depuis la version 7 ;
// sans lui, le fichier est celui de « -v6 ».
void ecrireMat(const std::string& chemin, const std::vector<VariableMat>& variables,
               bool compresser);

}  // namespace matlibre
