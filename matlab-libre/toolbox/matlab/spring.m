function carte = spring(m)
%SPRING Carte de couleurs magenta - jaune.
%   CARTE = SPRING() rend une carte de 256 couleurs allant du magenta au
%   jaune. CARTE = SPRING(M) en rend M.
%
%   Le rouge reste à un, le vert monte de zéro à un et le bleu descend de
%   un à zéro : la carte parcourt le bord du cube des couleurs à rouge
%   maximal. Comme COOL, elle varie surtout en teinte, la luminance
%   augmentant peu ; elle sert quand on veut du contraste coloré sans
%   éclaircir le fond.
%
%   Exemple :
%      carte = spring(8);
%      carte(end, :)
%
%   Voir aussi AUTUMN, SUMMER, WINTER, COLORMAP.
    if nargin < 1 || isempty(m), m = 256; end
    g = rampeCarte(m);
    carte = [ones(numel(g), 1), g, 1 - g];
end
