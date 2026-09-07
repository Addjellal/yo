function H = bubblechart(varargin)
%BUBBLECHART Nuage de points dont la taille porte une troisième variable.
%   BUBBLECHART(X,Y,TAILLES) dessine un disque en chaque point, dont
%   l'aire suit TAILLES. BUBBLECHART(X,Y,TAILLES,COULEUR) donne les
%   couleurs. Les propriétés de SCATTER sont acceptées.
%   H = BUBBLECHART(...) rend la poignée.
%
%   L'aire, non le rayon : l'œil compare des surfaces, et coder la donnée
%   dans le rayon la ferait paraître quadratique. C'est la faute la plus
%   commune des graphiques à bulles, et la raison pour laquelle cette
%   fonction existe à côté de SCATTER, qui prend une aire en points carrés
%   sans rien normaliser.
%
%   Les tailles sont ramenées à une plage lisible : la plus petite donnée
%   devient un petit disque, la plus grande un gros, et les autres entre
%   les deux proportionnellement à la donnée.
%
%   Exemple :
%      figure();
%      bubblechart(1:5, rand(1, 5), [1 4 9 16 25]);
%      close all;
%
%   Voir aussi SCATTER, BUBBLELEGEND, SWARMCHART, PLOT.
    entrees = varargin;
    while numel(entrees) >= 4 && (ischar(entrees{end - 1}) || isstring(entrees{end - 1}))
        entrees = entrees(1:end - 2);
    end
    if numel(entrees) < 3
        error('MATLAB:bubblechart:Arguments', ...
              'BUBBLECHART attend X, Y et les tailles.');
    end
    x = double(entrees{1}(:));
    y = double(entrees{2}(:));
    tailles = double(entrees{3}(:));
    % L'aire suit la donnee : on la ramene entre deux aires lisibles.
    minimum = min(tailles);
    maximum = max(tailles);
    if maximum > minimum
        aires = 20 + 380 * (tailles - minimum) / (maximum - minimum);
    else
        aires = 100 * ones(size(tailles));
    end
    reste = entrees(4:end);
    H = scatter(x, y, aires, reste{:});
end
