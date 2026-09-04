function K = matlibre_noyau_plaque(x, y, xq, yq)
%MATLIBRE_NOYAU_PLAQUE Noyau radial de la plaque mince.
%   K = MATLIBRE_NOYAU_PLAQUE(X,Y,XQ,YQ) rend la matrice des r²log(r)
%   entre les points demandés et les points de données. La valeur en zéro
%   est zéro, prolongée par continuité.
%
%   Exemple :
%      matlibre_noyau_plaque(0, 0, 1, 0)      % 0, car log(1) est nul
%
%   Voir aussi MATLIBRE_PLAQUE_MINCE.
    x = x(:).';
    y = y(:).';
    xq = xq(:);
    yq = yq(:);
    carres = (xq - x) .^ 2 + (yq - y) .^ 2;
    K = zeros(size(carres));
    positifs = carres > 0;
    K(positifs) = carres(positifs) .* log(sqrt(carres(positifs)));
end
