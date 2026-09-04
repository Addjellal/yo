function y = matlibre_bspline_valeurs(noeuds, ordre, coefs, x)
%MATLIBRE_BSPLINE_VALEURS Évalue une spline donnée en B-forme.
%   Y = MATLIBRE_BSPLINE_VALEURS(NOEUDS,ORDRE,COEFS,X) combine les
%   B-splines de la base par les coefficients donnés.
%
%   Exemple :
%      matlibre_bspline_valeurs([0 0 0 1 2 2 2], 3, [1 1 1 1], 0.5)      % 1
%
%   Voir aussi FNVAL, SPAP2, MATLIBRE_BASE_BSPLINE.
    N = matlibre_base_bspline(noeuds, ordre, x);
    y = N * double(coefs(:));
    y = reshape(y, size(x));
end
