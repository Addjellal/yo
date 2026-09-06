function carte = autumn(m)
%AUTUMN Carte de couleurs rouge - jaune.
%   CARTE = AUTUMN() rend une carte de 256 couleurs allant du rouge au
%   jaune. CARTE = AUTUMN(M) en rend M. Chaque ligne est un triplet
%   rouge-vert-bleu dans [0,1].
%
%   Le rouge reste à un, le vert monte de zéro à un, le bleu est nul. La
%   luminance croît donc de façon monotone d'un bout à l'autre : la carte
%   garde un ordre lisible même imprimée en niveaux de gris, ce qui n'est
%   pas le cas de toutes. Elle n'atteint ni le noir ni le blanc, si bien
%   que les deux extrêmes restent visibles sur un fond blanc.
%
%   Exemple :
%      carte = autumn(8);
%      size(carte)
%
%   Voir aussi SPRING, SUMMER, WINTER, COLORMAP, PARULA.
    if nargin < 1 || isempty(m), m = 256; end
    g = rampeCarte(m);
    carte = [ones(numel(g), 1), g, zeros(numel(g), 1)];
end
