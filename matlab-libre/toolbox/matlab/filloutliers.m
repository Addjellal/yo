function [b, marque, seuilBas, seuilHaut, centre] = filloutliers(a, remplacement, ...
                                                                 varargin)
%FILLOUTLIERS Remplace les valeurs aberrantes.
%   B = FILLOUTLIERS(A,REMPLACEMENT) repère les aberrantes comme
%   ISOUTLIER, puis les remplace. REMPLACEMENT vaut :
%      'center'    le centre employé par le critère
%      'clip'      le seuil le plus proche
%      'previous'  la dernière valeur acceptable
%      'next'      la prochaine
%      'nearest'   la plus proche des deux
%      'linear'    l'interpolation entre les deux voisines
%      'spline', 'pchip'
%      une valeur numérique
%
%   B = FILLOUTLIERS(A,REMPLACEMENT,METHODE,...) choisit le critère de
%   détection, comme ISOUTLIER.
%
%   [B,M,BAS,HAUT,CENTRE] = FILLOUTLIERS(...) rend en outre le masque et
%   les seuils.
%
%   Remplacer plutôt que retirer garde la longueur du signal, et donc
%   l'alignement avec le temps : c'est ce qu'on veut sur une série
%   mesurée, où retirer un point décalerait tout ce qui suit.
%
%   Exemple :
%      filloutliers([1 2 3 100 5], 'linear')     % [1 2 3 4 5]
%      filloutliers([1 2 3 100 5], 'clip')
%
%   Voir aussi ISOUTLIER, RMOUTLIERS, FILLMISSING.
    [marque, seuilBas, seuilHaut, centre] = isoutlier(a, varargin{:});
    b = double(a);
    if ~any(marque(:))
        return
    end
    if isvector(b)
        b = remplacer(b(:), marque(:), remplacement, seuilBas, seuilHaut, centre);
        b = reshape(b, size(a));
        return
    end
    for c = 1:size(b, 2)
        b(:, c) = remplacer(b(:, c), marque(:, c), remplacement, ...
                            seuilBas(c), seuilHaut(c), centre(c));
    end
end

function v = remplacer(v, marque, remplacement, seuilBas, seuilHaut, centre)
    if isnumeric(remplacement)
        v(marque) = remplacement;
        return
    end
    switch lower(char(remplacement))
        case 'center'
            v(marque) = centre;
        case 'clip'
            trop = marque & v > seuilHaut;
            pas = marque & v < seuilBas;
            v(trop) = seuilHaut;
            v(pas) = seuilBas;
        case {'previous', 'next', 'nearest', 'linear', 'spline', 'pchip'}
            % Les aberrantes deviennent des manquantes, et FILLMISSING
            % fait le reste : c'est exactement le même problème une fois
            % la détection faite.
            troue = v;
            troue(marque) = NaN;
            v = fillmissing(troue, lower(char(remplacement)));
        otherwise
            error('MATLAB:filloutliers:Remplacement', ...
                  'Remplacement inconnu : %s.', char(remplacement));
    end
end
