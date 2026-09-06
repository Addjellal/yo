function carte = pink(m)
%PINK Carte de couleurs pastel, pour les images en sépia.
%   CARTE = PINK() rend une carte de 256 couleurs pastel, dans les tons
%   sépia. CARTE = PINK(M) en rend M.
%
%   Elle vaut sqrt((2*GRAY + HOT)/3). La racine est une correction de
%   gamma : elle relève les valeurs basses, si bien que la clarté perçue
%   croît à peu près linéairement le long de l'échelle, alors qu'elle
%   croîtrait trop lentement dans l'ombre sans elle.
%
%   D'où son usage sur les photographies en noir et blanc, qu'elle teinte
%   sans détruire l'ordre des niveaux : la carte reste monotone en clarté.
%
%   Exemple :
%      carte = pink(8);
%      carte(1, :)
%
%   Voir aussi GRAY, HOT, BONE, COPPER, COLORMAP.
    if nargin < 1 || isempty(m), m = 256; end
    carte = sqrt((2 * gray(m) + hot(m)) / 3);
end
