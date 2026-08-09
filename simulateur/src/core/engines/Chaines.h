// Où trouver les compilateurs.
//
// Un simulateur qui exécute six architectures mais qui exige d'installer
// trois chaînes de compilation à la main n'est pas autosuffisant. Proteus
// pèse un gigaoctet et ne demande rien : c'est la bonne référence.
//
// La règle est donc simple, et cherchée dans cet ordre :
//
//   1. À CÔTÉ DE L'EXÉCUTABLE, dans « chaines/<famille>/bin ». C'est ce que
//      le paquet portable emporte, et c'est ce qui fait qu'il fonctionne sur
//      une machine où rien n'est installé.
//   2. Dans le PATH, pour la machine du développeur qui a déjà tout.
//
// Aucune de ces chaînes n'est stockée dans le dépôt : elles se téléchargent
// une fois, par « outils/chaines.ps1 » ou « outils/chaines.sh », et se
// rangent où le paquet les cherchera.
#pragma once

#include <string>

namespace coeur {
namespace chaines {

// Le dossier où vit l'exécutable en cours.
std::string dossier_executable();

// Le chemin complet d'un outil de la famille donnée (« avr », « arm »,
// « xtensa »), prêt à être passé à un interpréteur de commandes — guillemets
// compris s'il contient des espaces. Rend une chaîne vide si l'outil est
// introuvable, à côté de l'exécutable comme dans le PATH.
std::string outil(const std::string& famille, const std::string& nom);

// Un compte rendu lisible de ce qui a été trouvé, pour la fenêtre « À propos »
// et pour le diagnostic : c'est la première question qu'on se pose quand une
// compilation échoue.
std::string etat();

}  // namespace chaines
}  // namespace coeur
