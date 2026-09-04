function [x, y, ordre] = matlibre_fit_trier(x, y)
%MATLIBRE_FIT_TRIER Range les points par abscisse croissante.
%   [X,Y,ORDRE] = MATLIBRE_FIT_TRIER(X,Y) trie les couples. Les splines et
%   les interpolants l'exigent ; pour les autres modèles, cela ne change
%   rien au résultat.
%
%   Exemple :
%      [x, y] = matlibre_fit_trier([2; 1], [4; 1]);
%
%   Voir aussi FIT.
    [x, ordre] = sort(x);
    y = y(ordre);
end
