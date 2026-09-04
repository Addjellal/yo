function [transformation, recale, erreur] = pcregistericp(mobile, fixe, varargin)
%PCREGISTERICP Recale deux nuages de points, par plus proches voisins.
%   [T,Q,E] = PCREGISTERICP(MOBILE,FIXE) cherche la transformation rigide
%   qui superpose le premier nuage au second, et rend le nuage déplacé
%   ainsi que l'erreur quadratique moyenne restante.
%
%   L'algorithme alterne deux étapes évidentes prises séparément : à
%   correspondances données, la transformation optimale se calcule d'un
%   coup par décomposition en valeurs singulières ; à transformation
%   donnée, les correspondances sont les plus proches voisins. Répéter
%   les deux fait décroître l'erreur à chaque tour, ce qui garantit la
%   convergence — vers un minimum local, non forcément le bon.
%
%   PCREGISTERICP(...,'MaxIterations',N) borne le nombre de tours (vingt),
%   'Tolerance',[T R] les seuils d'arrêt en translation et en rotation,
%   'InitialTransform',T0 part d'une pose donnée.
%
%   Exemple :
%      a = pointCloud(rand(300, 3));
%      T = [rotz(10), [0.1; 0.05; 0]; 0 0 0 1];
%      b = pctransform(a, T);
%      Trouve = pcregistericp(b, a);
%
%   Voir aussi PCTRANSFORM, PCMERGE, POINTCLOUD.
    iterations = 20;
    tolerance = [0.01, 0.009];
    depart = eye(4);
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'maxiterations',    iterations = round(varargin{k+1});
            case 'tolerance',        tolerance = double(varargin{k+1});
            case 'initialtransform', depart = matlibre_transformation_rigide(varargin{k+1});
            case {'metric', 'extrapolate', 'inlierratio'}   % variantes non traitées
            otherwise
                error('vision:pcregistericp:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    source = matlibre_nuage_points(mobile);
    cible = matlibre_nuage_points(fixe);
    if isempty(source) || isempty(cible)
        error('vision:pcregistericp:Vide', 'Les deux nuages doivent être non vides.');
    end
    M = depart;
    normesCible = sum(cible .^ 2, 2);
    for tour = 1:iterations
        deplaces = source * M(1:3, 1:3).' + repmat(M(1:3, 4).', size(source, 1), 1);
        carres = repmat(sum(deplaces .^ 2, 2), 1, size(cible, 1)) + ...
                 repmat(normesCible.', size(deplaces, 1), 1) - 2 * (deplaces * cible.');
        [~, plusProches] = min(max(carres, 0), [], 2);
        correspondants = cible(plusProches, :);
        increment = matlibre_pose_optimale(deplaces, correspondants);
        M = increment * M;
        translation = norm(increment(1:3, 4));
        rotation = acos(min(max((trace(increment(1:3, 1:3)) - 1) / 2, -1), 1));
        if translation < tolerance(1) && rotation < tolerance(min(2, numel(tolerance)))
            break
        end
    end
    transformation = M;
    finaux = source * M(1:3, 1:3).' + repmat(M(1:3, 4).', size(source, 1), 1);
    recale = matlibre_nuage_copier(mobile, finaux);
    carres = repmat(sum(finaux .^ 2, 2), 1, size(cible, 1)) + ...
             repmat(normesCible.', size(finaux, 1), 1) - 2 * (finaux * cible.');
    erreur = sqrt(mean(min(max(carres, 0), [], 2)));
end
