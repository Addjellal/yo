function a = matlibre_poly_aire_signee(C)
%MATLIBRE_POLY_AIRE_SIGNEE Aire d'un contour, signe du sens de parcours compris.
%   La formule du lacet rend une aire positive pour un contour parcouru
%   dans le sens direct et négative dans l'autre. C'est ce signe qui
%   distingue un plein d'un trou, sans rien avoir à ajouter à la
%   structure.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_poly_aire_signee([0 0; 1 0; 1 1; 0 1])   % +1
%      matlibre_poly_aire_signee([0 0; 0 1; 1 1; 1 0])   % -1
%
%   Voir aussi POLYAREA, POLYSHAPE.
    x = C(:, 1);
    y = C(:, 2);
    a = sum(x .* y([2:end 1]) - x([2:end 1]) .* y) / 2;
end
