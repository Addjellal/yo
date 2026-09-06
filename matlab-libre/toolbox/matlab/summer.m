function carte = summer(m)
%SUMMER Carte de couleurs vert - jaune.
%   CARTE = SUMMER() rend une carte de 256 couleurs allant du vert au
%   jaune. CARTE = SUMMER(M) en rend M.
%
%   Le rouge monte de zéro à un, le vert de 0,5 à un, le bleu reste à 0,4.
%   Le bleu constant, non nul, désature l'ensemble : aucune couleur n'est
%   pure, ce qui adoucit la carte et évite les teintes criardes des cartes
%   à canaux saturés.
%
%   La clarté croît de façon monotone, donc l'ordre des valeurs reste
%   lisible en niveaux de gris.
%
%   Exemple :
%      carte = summer(8);
%      carte(:, 3)'
%
%   Voir aussi AUTUMN, SPRING, WINTER, COLORMAP.
    if nargin < 1 || isempty(m), m = 256; end
    g = rampeCarte(m);
    carte = [g, 0.5 + g / 2, 0.4 * ones(numel(g), 1)];
end
