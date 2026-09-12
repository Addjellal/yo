function matlibre_sl_pointe(arrivee, couleur)
%MATLIBRE_SL_POINTE Pointe de flèche à l'entrée d'un bloc.
%   MATLIBRE_SL_POINTE(ARRIVEE) pose un petit triangle plein pointant
%   vers la droite au point donné.
%
%   Sans elle, un schéma-bloc ne dit pas dans quel sens l'information
%   circule — et c'est précisément ce qu'un schéma-bloc sert à dire.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      figure;
%      matlibre_sl_pointe([1 1]);
%
%   Voir aussi MATLIBRE_SL_FIL, OPEN_SYSTEM.
    if nargin < 2
        couleur = [0.15 0.15 0.15];
    end
    longueur = 0.22;
    demiLargeur = 0.11;
    patch([arrivee(1) - longueur, arrivee(1) - longueur, arrivee(1)], ...
          [arrivee(2) - demiLargeur, arrivee(2) + demiLargeur, arrivee(2)], ...
          couleur, 'EdgeColor', couleur);
end
