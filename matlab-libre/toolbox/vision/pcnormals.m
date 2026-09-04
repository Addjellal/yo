function normales = pcnormals(entree, voisins)
%PCNORMALS Normales estimées en chaque point d'un nuage.
%   N = PCNORMALS(P) rend, pour chaque point, la direction perpendiculaire
%   à la surface locale. PCNORMALS(P,K) prend K voisins (six par défaut).
%
%   La normale est le vecteur propre associé à la plus petite valeur
%   propre de la covariance des voisins : la direction dans laquelle le
%   voisinage s'étend le moins est celle qui sort de la surface.
%
%   Le signe reste indéterminé — rien, dans un nuage, ne dit quel côté
%   est l'extérieur.
%
%   Exemple :
%      p = pointCloud([rand(500,2), zeros(500,1)]);
%      n = pcnormals(p);            % toutes selon z
%
%   Voir aussi PCFITPLANE, POINTCLOUD, PCDENOISE.
    if nargin < 2 || isempty(voisins)
        voisins = 6;
    end
    points = matlibre_nuage_points(entree);
    n = size(points, 1);
    voisins = min(max(round(voisins), 3), max(n - 1, 3));
    normales = zeros(n, 3);
    normes = sum(points .^ 2, 2);
    bloc = max(min(1024, floor(4e6 / max(n, 1))), 1);
    for debut = 1:bloc:n
        fin = min(debut + bloc - 1, n);
        morceau = points(debut:fin, :);
        carres = repmat(sum(morceau .^ 2, 2), 1, n) + repmat(normes.', fin - debut + 1, 1) ...
                 - 2 * (morceau * points.');
        [~, ordre] = sort(max(carres, 0), 2);
        for k = 1:(fin - debut + 1)
            proches = points(ordre(k, 1:(voisins + 1)), :);
            centres = proches - repmat(mean(proches, 1), size(proches, 1), 1);
            [vecteurs, valeurs] = eig(centres.' * centres);
            [~, rang] = min(real(diag(valeurs)));
            normales(debut + k - 1, :) = real(vecteurs(:, rang)).';
        end
    end
end
