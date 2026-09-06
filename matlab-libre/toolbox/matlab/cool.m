function carte = cool(m)
%COOL Carte de couleurs cyan - magenta.
%   CARTE = COOL() rend une carte de 256 couleurs allant du cyan au
%   magenta. CARTE = COOL(M) en rend M.
%
%   Le rouge monte de zéro à un, le vert descend de un à zéro, le bleu
%   reste à un. La somme des trois canaux est constante : la carte varie
%   presque uniquement en teinte, et très peu en luminance. C'est ce qui
%   la rend agréable à l'écran et impropre à l'impression en niveaux de
%   gris, où elle s'aplatit ; elle est également difficile à lire pour
%   une vision déficiente au rouge et au vert.
%
%   Exemple :
%      carte = cool(8);
%      sum(carte(1, :)) - sum(carte(end, :))
%
%   Voir aussi AUTUMN, WINTER, COLORMAP, PARULA.
    if nargin < 1 || isempty(m), m = 256; end
    r = rampeCarte(m);
    carte = [r, 1 - r, ones(numel(r), 1)];
end
