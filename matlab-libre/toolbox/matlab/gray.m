function carte = gray(m)
%GRAY Carte de couleurs en niveaux de gris.
%   CARTE = GRAY(M) rend une matrice M x 3 allant du noir au blanc.
%   M vaut 256 par défaut.
%
%   Exemple :
%      carte = gray(4)   % [0 0 0; 1/3 1/3 1/3; 2/3 2/3 2/3; 1 1 1]
    if nargin < 1 || isempty(m), m = 256; end
    g = rampeCarte(m);
    carte = [g g g];
end
