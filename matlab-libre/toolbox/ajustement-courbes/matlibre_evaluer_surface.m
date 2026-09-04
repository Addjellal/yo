function z = matlibre_evaluer_surface(interpolant, xy)
%MATLIBRE_EVALUER_SURFACE Évalue une surface interpolée ou lissée.
%   Z = MATLIBRE_EVALUER_SURFACE(I,XY) applique l'interpolant de surface.
%   Les méthodes 'linearinterp', 'nearestinterp' et 'cubicinterp' passent
%   par une triangulation des points ; 'lowess' et 'loess' ajustent un
%   plan ou une quadrique aux voisins les plus proches.
%
%   Exemple :
%      % appelée par SFIT
%
%   Voir aussi FIT, SFIT, GRIDDATA.
    xy = double(xy);
    if size(xy, 2) ~= 2
        xy = reshape(xy, [], 2);
    end
    switch interpolant.methode
        case {'linearinterp', 'nearestinterp', 'cubicinterp'}
            methodes = struct('linearinterp', 'linear', 'nearestinterp', 'nearest', ...
                              'cubicinterp', 'cubic');
            z = griddata(interpolant.xy(:, 1), interpolant.xy(:, 2), interpolant.z, ...
                         xy(:, 1), xy(:, 2), methodes.(interpolant.methode));
            manquants = isnan(z);
            if any(manquants)
                % Hors de l'enveloppe des points, la triangulation ne dit
                % rien : on prend la valeur du point le plus proche.
                z(manquants) = griddata(interpolant.xy(:, 1), interpolant.xy(:, 2), ...
                                        interpolant.z, xy(manquants, 1), ...
                                        xy(manquants, 2), 'nearest');
            end
        case {'lowess', 'loess'}
            degre = 1;
            if strcmp(interpolant.methode, 'loess')
                degre = 2;
            end
            z = matlibre_regression_locale_surface(interpolant.xy, interpolant.z, ...
                                                   xy, interpolant.span, degre);
        otherwise
            error('curvefit:sfit:Interpolant', ...
                  'Interpolant de surface inconnu : %s.', interpolant.methode);
    end
    z = z(:);
end
