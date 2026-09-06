function carte = winter(m)
%WINTER Carte de couleurs bleu - vert.
%   CARTE = WINTER() rend une carte de 256 couleurs allant du bleu au
%   vert. CARTE = WINTER(M) en rend M.
%
%   Le rouge est nul, le vert monte de zéro à un, le bleu descend de un à
%   0,5 sans jamais s'annuler. La carte reste donc froide d'un bout à
%   l'autre, et le bleu résiduel empêche le vert pur en fin d'échelle.
%
%   L'absence de rouge la rend lisible pour la forme la plus répandue de
%   déficience de la vision des couleurs, qui confond le rouge et le vert :
%   c'est ce qui la distingue des cartes arc-en-ciel.
%
%   Exemple :
%      carte = winter(8);
%      all(carte(:, 1) == 0)
%
%   Voir aussi AUTUMN, SPRING, SUMMER, COLORMAP, PARULA.
    if nargin < 1 || isempty(m), m = 256; end
    g = rampeCarte(m);
    carte = [zeros(numel(g), 1), g, 1 - g / 2];
end
