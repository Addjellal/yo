// Installation.h — trouver les toolboxes, et les mettre sur le chemin.
//
// Les fonctions de toolbox sont des fichiers .m : sans ce dossier sur le
// chemin de recherche, l'interpréteur n'a que ses fonctions natives. La
// console et le bureau doivent donc le chercher de la même façon — c'est
// ici, en un seul endroit, que la règle est écrite.
#pragma once

#include <string>

namespace matlibre {

class Interpreteur;

// Racine des toolboxes, cherchée à côté de l'exécutable : arborescence
// installée (<préfixe>/share/matlibre) comme arbre de construction
// (build/bin/matlibre, toolbox deux crans plus haut). La variable
// d'environnement MATLIBRE_TOOLBOX l'emporte quand rien n'est trouvé.
// Rend une chaîne vide quand il n'y a rien.
std::string racineToolboxes(const std::string& executable);

// Ajoute la racine et chacun de ses sous-dossiers au chemin de recherche,
// dans l'ordre où MATLAB les résoudrait. Ne fait rien sur une racine vide.
void chargerToolboxes(Interpreteur& it, const std::string& racine);

}  // namespace matlibre
