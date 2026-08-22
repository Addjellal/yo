// Operations.h — opérateurs du langage.
//
// Les opérateurs élément par élément appliquent l'« expansion implicite »
// introduite par MATLAB R2016b : deux tailles sont compatibles dès que,
// pour chaque dimension, elles sont égales ou l'une vaut 1.
#pragma once

#include <functional>
#include <string>

#include "matlibre/Valeur.h"

namespace matlibre {

Valeur operationBinaire(const std::string& op, const Valeur& a, const Valeur& b);
Valeur operationUnaire(const std::string& op, const Valeur& a);
Valeur transposer(const Valeur& a, bool conjuguee);

// Briques réutilisées par la bibliothèque.
Dims dimsDiffusees(const Dims& a, const Dims& b);
Valeur diffuser(const Valeur& a, const Valeur& b,
                const std::function<double(double, double)>& f, Classe forcee,
                bool logique = false);
Valeur diffuserComplexe(
    const Valeur& a, const Valeur& b,
    const std::function<void(double, double, double, double, double&, double&)>& f);
Valeur appliquerReel(const Valeur& a, const std::function<double(double)>& f);
Classe classeResultat(const Valeur& a, const Valeur& b, const std::string& op);
Valeur concatener(const std::vector<Valeur>& elements, int dimension);
Valeur concatenerRangees(const std::vector<std::vector<Valeur>>& rangees);
Valeur celluleDepuisRangees(const std::vector<std::vector<Valeur>>& rangees);
Valeur reshaperVers(const Valeur& v, const Dims& d);
Valeur permuterDims(const Valeur& v, const std::vector<int>& ordre);
Valeur extraireElement(const Valeur& v, std::size_t k);
void poserElement(Valeur& v, std::size_t k, const Valeur& e);
Valeur valeurNulleDe(const Valeur& modele);

}  // namespace matlibre
