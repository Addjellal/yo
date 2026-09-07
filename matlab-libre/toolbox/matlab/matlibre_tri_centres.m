function C = matlibre_tri_centres(tr, elements, sorte)
%MATLIBRE_TRI_CENTRES Centre circonscrit ou inscrit de chaque triangle.
%   Le centre circonscrit est équidistant des trois sommets : il se
%   trouve en résolvant les deux équations de médiatrice. Le centre
%   inscrit est équidistant des trois côtés : c'est le barycentre des
%   sommets pondérés par les longueurs des côtés opposés.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      tr = triangulation([1 2 3], [0 0; 1 0; 0 1]);
%      c = matlibre_tri_centres(tr, 1, 'circonscrit');
%      max(abs(c - [0.5 0.5])) < 1e-12
%
%   Voir aussi TRIANGULATION, CIRCUMCENTER, INCENTER.
    elements = elements(:);
    P = tr.Points;
    T = tr.ConnectivityList;
    C = zeros(numel(elements), size(P, 2));
    for k = 1:numel(elements)
        s = T(elements(k), 1:3);
        a = P(s(1), :); b = P(s(2), :); c = P(s(3), :);
        if strcmp(sorte, 'inscrit')
            la = norm(b - c); lb = norm(c - a); lc = norm(a - b);
            somme = la + lb + lc;
            C(k, :) = (la * a + lb * b + lc * c) / somme;
        else
            % Le centre circonscrit verifie |x-a|^2 = |x-b|^2 = |x-c|^2 ;
            % en developpant, les termes quadratiques s'en vont et il
            % reste deux equations lineaires.
            M = [2 * (b - a); 2 * (c - a)];
            second = [sum(b.^2) - sum(a.^2); sum(c.^2) - sum(a.^2)];
            if size(P, 2) == 3
                % En trois dimensions, la troisieme equation est que le
                % centre reste dans le plan du triangle.
                n = cross(b - a, c - a);
                M = [M; n];
                second = [second; dot(n, a)];
            end
            C(k, :) = (M \ second)';
        end
    end
end
