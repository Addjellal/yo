function [interpolant, coefficients] = matlibre_fit_interpolant(modele, x, y, poids, options)
%MATLIBRE_FIT_INTERPOLANT Construit un interpolant ou une spline de lissage.
%   [I,C] = MATLIBRE_FIT_INTERPOLANT(MODELE,X,Y,POIDS,OPTIONS) rend la
%   description de la courbe et le vecteur de coefficients, vide pour un
%   interpolant : une courbe qui passe par tous les points n'a pas de
%   paramètre à ajuster.
%
%   Exemple :
%      i = matlibre_fit_interpolant(fittype('cubicinterp'), (1:5)', (1:5)'.^2, ones(5,1), fitoptions());
%
%   Voir aussi FIT, CSAPS.
    coefficients = [];
    genre = lower(modele.Type);
    switch genre
        case {'linearinterp', 'nearestinterp', 'pchipinterp'}
            methodes = struct('linearinterp', 'linear', 'nearestinterp', 'nearest', ...
                              'pchipinterp', 'pchip');
            interpolant = struct('genre', 'interp1', 'methode', methodes.(genre), ...
                                 'x', x, 'y', y);
        case {'cubicinterp', 'splineinterp'}
            interpolant = struct('genre', 'pp', 'pp', spline(x, y));
        case 'smoothingspline'
            [pp, parametre] = csaps(x, y, options.SmoothingParam, [], poids);
            interpolant = struct('genre', 'pp', 'pp', pp);
            coefficients = parametre;
        case {'lowess', 'loess'}
            degre = 1;
            if strcmp(genre, 'loess')
                degre = 2;
            end
            interpolant = struct('genre', 'local', 'x', x, 'y', y, ...
                                 'span', options.Span, 'degre', degre);
        otherwise
            error('curvefit:fit:Interpolant', 'Interpolant inconnu : %s.', genre);
    end
end
