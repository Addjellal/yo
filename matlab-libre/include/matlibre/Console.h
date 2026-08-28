// Console.h — la console de Windows lit les octets dans sa page de codes.
#pragma once

namespace matlibre {

// MatLibre écrit de l'UTF-8, sur toutes les plateformes. La console de
// Windows, elle, interprète les octets qu'on lui envoie dans sa page de
// codes OEM — 437 ou 850 selon la machine — où l'UTF-8 sort en charabia :
// « — » devient « ÔÇö », « « » devient « ┬« ».
//
// On bascule donc la console en UTF-8 le temps du programme. Le
// changement vaut pour la fenêtre entière, pas seulement pour le
// processus : on remet en partant ce qu'on a trouvé en arrivant, pour ne
// pas laisser l'invite de l'utilisateur dans un état qu'il n'a pas choisi.
//
// Ailleurs qu'à Windows, la classe ne fait rien : les terminaux d'Unix
// sont en UTF-8.
class ConsoleUtf8 {
public:
    ConsoleUtf8();
    ~ConsoleUtf8();
    ConsoleUtf8(const ConsoleUtf8&) = delete;
    ConsoleUtf8& operator=(const ConsoleUtf8&) = delete;

private:
    unsigned sortieInitiale = 0;
    unsigned entreeInitiale = 0;
};

}  // namespace matlibre
