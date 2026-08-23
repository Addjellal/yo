// Atelier.h — l'atelier : éditeur, console, explorateur, débogueur,
// profileur, concepteur d'applications et éditeur de schémas-blocs.
//
// L'interpréteur tourne sur son propre fil ; le serveur HTTP répond sur le
// fil principal. Les deux communiquent par une file de commandes et un
// tampon de sortie, tous deux protégés par un verrou. C'est ce découplage
// qui rend le débogueur utilisable : l'exécution peut rester arrêtée sans
// bloquer l'interface.
#pragma once

#include <string>

namespace matlibre {

class Interpreteur;

// Lance l'atelier sur le port donné et ne rend la main qu'à l'arrêt.
// « ouvrirNavigateur » demande au système d'ouvrir la page.
int lancerAtelier(int port, const std::string& racineWeb, bool ouvrirNavigateur);

// Cherche les fichiers de l'atelier : $MATLIBRE_IDE, puis les emplacements
// habituels autour de l'exécutable et du dossier courant.
std::string trouverRacineWeb(const std::string& cheminExecutable);

}  // namespace matlibre
