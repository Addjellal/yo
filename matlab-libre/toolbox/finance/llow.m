function extrema = llow(bas, periode)
%LLOW Plus bas d'une fenêtre glissante.
%   B = LLOW(BAS,N) rend, pour chaque séance, le plus bas des N
%   dernières. N vaut 14 par défaut.
%
%   Exemple :
%      llow([5 3 4 1 2], 3)           % [5 3 3 1 1]
%
%   Voir aussi HHIGH, STOCHOSC, WILLPCTR.
    if nargin < 2 || isempty(periode), periode = 14; end
    series = matlibre_colonnes_marche(bas, {}, {'bas'});
    x = series{1};
    extrema = zeros(size(x));
    for k = 1:numel(x)
        extrema(k) = min(x(max(1, k - periode + 1):k));
    end
end
