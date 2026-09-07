function A = rectint(a, b)
%RECTINT Aire d'intersection de rectangles.
%   A = RECTINT(A,B) rend une matrice dont l'élément (I,J) est l'aire
%   commune au rectangle I de A et au rectangle J de B. Chaque rectangle
%   est une ligne [X Y LARGEUR HAUTEUR], le coin étant le plus bas à
%   gauche.
%
%   L'intersection de deux rectangles alignés sur les axes est un
%   rectangle, et son côté suivant chaque axe est le recouvrement des deux
%   intervalles : c'est ce qui rend le calcul immédiat, et nul dès que
%   l'un des deux recouvrements l'est.
%
%   Exemple :
%      rectint([0 0 2 2], [1 1 2 2])            % 1 : ils se recouvrent d'un carre
%      rectint([0 0 1 1], [3 3 1 1])            % 0 : disjoints
%
%   Voir aussi POLYAREA, INPOLYGON, RECTANGLE.
    a = double(a);
    b = double(b);
    if size(a, 2) ~= 4 || size(b, 2) ~= 4
        error('MATLAB:rectint:forme', ...
              'Chaque rectangle s''écrit [X Y LARGEUR HAUTEUR].');
    end
    A = zeros(size(a, 1), size(b, 1));
    for i = 1:size(a, 1)
        for j = 1:size(b, 1)
            largeur = recouvrement(a(i, 1), a(i, 1) + a(i, 3), ...
                                   b(j, 1), b(j, 1) + b(j, 3));
            hauteur = recouvrement(a(i, 2), a(i, 2) + a(i, 4), ...
                                   b(j, 2), b(j, 2) + b(j, 4));
            A(i, j) = largeur * hauteur;
        end
    end
end

function r = recouvrement(a1, a2, b1, b2)
% La longueur commune a deux intervalles, nulle s'ils sont disjoints.
    r = max(0, min(a2, b2) - max(a1, b1));
end
