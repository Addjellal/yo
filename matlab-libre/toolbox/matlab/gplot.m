function [Xg, Yg] = gplot(A, coordonnees, style)
%GPLOT Dessine un graphe donné par sa matrice d'adjacence.
%   GPLOT(A,XY) trace une arête entre les nœuds I et J chaque fois que
%   A(I,J) n'est pas nul. XY porte les coordonnées des nœuds, une ligne
%   par nœud.
%
%   GPLOT(A,XY,STYLE) prend une chaîne de style, comme PLOT.
%
%   [X,Y] = GPLOT(A,XY) rend les coordonnées du tracé sans rien dessiner.
%   Elles portent des NaN entre les arêtes, ce qui permet de tout tracer
%   d'un seul PLOT : c'est la convention de MATLAB pour lever le crayon.
%
%   Exemples :
%      A = [0 1 1; 1 0 1; 1 1 0];         % le triangle
%      xy = [0 0; 1 0; 0.5 1];
%      gplot(A, xy, '-o');
%
%      % Un graphe en anneau, ses noeuds sur un cercle
%      n = 8;
%      A = diag(ones(n-1, 1), 1) + diag(ones(n-1, 1), -1);
%      t = linspace(0, 2*pi, n+1)';
%      gplot(A, [cos(t(1:n)), sin(t(1:n))], '-o');
%
%   Voir aussi PLOT, SPY, TRIMESH, GRAPH, DIGRAPH.
    if nargin < 3 || isempty(style)
        style = '-';
    end
    n = size(A, 1);
    Xg = [];
    Yg = [];
    for i = 1:n
        for j = i + 1:n
            if A(i, j) ~= 0 || A(j, i) ~= 0
                Xg = [Xg; coordonnees(i, 1); coordonnees(j, 1); NaN];   %#ok<AGROW>
                Yg = [Yg; coordonnees(i, 2); coordonnees(j, 2); NaN];   %#ok<AGROW>
            end
        end
    end
    if nargout == 0
        plot(Xg, Yg, style);
        clear Xg;
    end
end
