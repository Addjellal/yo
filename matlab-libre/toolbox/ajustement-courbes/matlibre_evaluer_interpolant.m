function y = matlibre_evaluer_interpolant(interpolant, x)
%MATLIBRE_EVALUER_INTERPOLANT Évalue une courbe interpolée ou lissée.
%   Y = MATLIBRE_EVALUER_INTERPOLANT(I,X) applique l'interpolant construit
%   par l'ajustement. Hors de l'intervalle des données, la valeur est
%   prolongée plutôt que rendue non définie, comme le fait MATLAB pour les
%   splines.
%
%   Exemple :
%      % appelée par CFIT
%
%   Voir aussi FIT, CFIT, PPVAL.
    x = x(:);
    switch interpolant.genre
        case 'interp1'
            y = interp1(interpolant.x, interpolant.y, x, interpolant.methode, 'extrap');
        case 'pp'
            y = ppval(interpolant.pp, x);
        case 'local'
            y = matlibre_regression_locale(interpolant.x, interpolant.y, x, ...
                                           interpolant.span, interpolant.degre);
        otherwise
            error('curvefit:cfit:Interpolant', 'Interpolant inconnu.');
    end
    y = y(:);
end
