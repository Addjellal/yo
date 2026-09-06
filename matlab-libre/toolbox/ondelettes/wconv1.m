function y = wconv1(x, f, forme)
%WCONV1 Convolution monodimensionnelle, orientation conservée.
%   Y = WCONV1(X,F) convole X par F et rend le résultat avec la même
%   orientation que X, ligne ou colonne. Y = WCONV1(X,F,FORME) choisit
%   'full' (par défaut), 'same' ou 'valid'.
%
%   C'est CONV muni de deux garanties que CONV n'offre pas : les entrées
%   sont converties en double, et l'orientation du résultat suit celle de
%   l'entrée. La seconde compte plus qu'il n'y paraît — un filtrage qui
%   rend une colonne là où l'appelant attend une ligne transforme
%   silencieusement une soustraction terme à terme en une matrice de
%   différences, et l'erreur ne se voit que bien plus loin.
%
%   'same' garde la longueur de X en centrant, 'valid' ne garde que les
%   points où les deux suites se recouvrent entièrement — les seuls que ne
%   contamine aucun effet de bord.
%
%   Exemple :
%      wconv1([1 2 3], [1 1], 'same')
%
%   Voir aussi CONV, WCONV2, WKEEP, DWT.
    if nargin < 3 || isempty(forme), forme = 'full'; end
    ligne = isrow(x);
    y = conv(double(x(:)).', double(f(:)).', forme);
    if ~ligne, y = y'; end
end
