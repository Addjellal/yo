function extrema = hhigh(haut, periode)
%HHIGH Plus haut d'une fenêtre glissante.
%   H = HHIGH(HAUT,N) rend, pour chaque séance, le plus haut des N
%   dernières, celle du jour comprise. N vaut 14 par défaut.
%
%   Exemple :
%      hhigh([1 3 2 5 4], 3)          % [1 3 3 5 5]
%
%   Voir aussi LLOW, STOCHOSC, WILLPCTR.
    if nargin < 2 || isempty(periode), periode = 14; end
    series = matlibre_colonnes_marche(haut, {}, {'haut'});
    x = series{1};
    extrema = zeros(size(x));
    for k = 1:numel(x)
        extrema(k) = max(x(max(1, k - periode + 1):k));
    end
end
