function [x, y, z] = gensurf(fis, entrees, sortie, points)
%GENSURF Surface de réponse d'un système flou.
%   GENSURF(FIS) trace la sortie du système sur une grille de ses deux
%   premières entrées ; les autres restent au milieu de leur intervalle.
%   Un système à une seule entrée donne une courbe.
%
%   GENSURF(FIS,[I J]) choisit les deux entrées, GENSURF(FIS,[I J],K) la
%   sortie, GENSURF(FIS,[I J],K,N) le nombre de points de la grille
%   (quinze par défaut).
%
%   [X,Y,Z] = GENSURF(...) rend la grille et la surface au lieu de les
%   tracer.
%
%   La surface est ce qu'on regarde pour juger un système : elle montre
%   d'un coup les paliers, les sauts et les zones où aucune règle ne
%   s'applique.
%
%   Exemple :
%      fis = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
%      fis = addInput(fis, [0 10], 'Name', 'b', 'NumMFs', 2);
%      fis = addOutput(fis, [0 1], 'Name', 'c', 'NumMFs', 2);
%      fis = addRule(fis, [1 1 1 1 1; 2 2 2 1 1]);
%      [x, y, z] = gensurf(fis);
%      size(z)                        % 15x15
%
%   Voir aussi EVALFIS, PLOTFIS, PLOTMF, GENSURFOPTIONS.
    if nargin < 2 || isempty(entrees), entrees = [1 2]; end
    if nargin < 3 || isempty(sortie), sortie = 1; end
    if nargin < 4 || isempty(points), points = 15; end
    if isstruct(entrees)
        % Forme à options : GENSURF(FIS,OPTIONS).
        options = entrees;
        entrees = [1 2];
        if isfield(options, 'InputIndex') && ~isempty(options.InputIndex)
            entrees = options.InputIndex;
        end
        if isfield(options, 'OutputIndex') && ~isempty(options.OutputIndex)
            sortie = options.OutputIndex;
        end
        if isfield(options, 'NumGridPoints') && ~isempty(options.NumGridPoints)
            points = options.NumGridPoints;
        end
    end
    n = numel(fis.entrees);
    if n < 1
        error('fuzzy:gensurf:Entrees', 'Le système n''a aucune entrée.');
    end
    points = round(points);
    if n < 2 || numel(entrees) < 2
        plage = linspace(fis.entrees{1}.intervalle(1), ...
                         fis.entrees{1}.intervalle(2), points)';
        z = zeros(points, 1);
        for k = 1:points
            r = evalfis(fis, plage(k));
            z(k) = r(sortie);
        end
        x = plage;
        y = z;
        if nargout == 0
            plot(x, z);
            xlabel(fis.entrees{1}.nom);
            ylabel(fis.sorties{sortie}.nom);
            clear x y z
        end
        return
    end
    premiere = fis.entrees{entrees(1)}.intervalle;
    seconde = fis.entrees{entrees(2)}.intervalle;
    [x, y] = meshgrid(linspace(premiere(1), premiere(2), points), ...
                      linspace(seconde(1), seconde(2), points));
    z = zeros(size(x));
    % Les entrées qu'on ne balaie pas restent au milieu de leur
    % intervalle : la coupe est celle qui passe par le centre du domaine.
    modele = zeros(1, n);
    for j = 1:n
        modele(j) = mean(fis.entrees{j}.intervalle);
    end
    for i = 1:numel(x)
        v = modele;
        v(entrees(1)) = x(i);
        v(entrees(2)) = y(i);
        r = evalfis(fis, v);
        z(i) = r(sortie);
    end
    if nargout == 0
        surf(x, y, z);
        xlabel(fis.entrees{entrees(1)}.nom);
        ylabel(fis.entrees{entrees(2)}.nom);
        zlabel(fis.sorties{sortie}.nom);
        clear x y z
    end
end
