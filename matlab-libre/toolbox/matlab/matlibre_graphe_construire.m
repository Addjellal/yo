function [arcs, poids, noms, nombre] = matlibre_graphe_construire(arguments, oriente)
%MATLIBRE_GRAPHE_CONSTRUIRE Lit les arguments de GRAPH et de DIGRAPH.
%   Les deux classes acceptent les mêmes formes : deux listes de nœuds,
%   avec ou sans poids, ou une matrice d'adjacence. Le seul écart tient à
%   l'orientation : sur un graphe non orienté, une matrice d'adjacence ne
%   donne qu'une arête par couple, la moitié supérieure suffisant.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [a, p, n, m] = matlibre_graphe_construire({[1 2], [2 3]}, false);
%      m                               % 3
%
%   Voir aussi GRAPH, DIGRAPH.
    arcs = zeros(0, 2);
    poids = zeros(0, 1);
    noms = {};
    nombre = 0;
    if isempty(arguments)
        return
    end
    premier = arguments{1};
    if numel(arguments) == 1 || (numel(arguments) >= 2 && ~isnumeric(arguments{2}) ...
                                 && ~iscell(arguments{2}) && ~ischar(arguments{2}))
        % Une matrice d'adjacence.
        A = double(premier);
        if size(A, 1) ~= size(A, 2)
            error('MATLAB:graph:NotSquare', ...
                  'Une matrice d''adjacence doit être carrée.');
        end
        nombre = size(A, 1);
        for i = 1:nombre
            for j = 1:nombre
                if A(i, j) == 0, continue, end
                if ~oriente && j < i, continue, end
                arcs(end + 1, :) = [i j];      %#ok<AGROW>
                poids(end + 1, 1) = A(i, j);   %#ok<AGROW>
            end
        end
        if numel(arguments) >= 2 && (iscell(arguments{2}) || ischar(arguments{2}))
            noms = cellstr(arguments{2});
        end
        return
    end
    s = arguments{1};
    t = arguments{2};
    if numel(arguments) >= 4
        noms = cellstr(arguments{4});
    elseif numel(arguments) == 3 && (iscell(arguments{3}) || ischar(arguments{3}))
        noms = cellstr(arguments{3});
    end
    if ~isnumeric(s) || ~isnumeric(t)
        if isempty(noms)
            noms = unique([cellstr(s(:)); cellstr(t(:))], 'stable');
        end
        s = nomsVersIndices(cellstr(s), noms);
        t = nomsVersIndices(cellstr(t), noms);
    end
    s = double(s(:));
    t = double(t(:));
    if numel(s) ~= numel(t)
        error('MATLAB:graph:SizeMismatch', ...
              'Les deux listes de nœuds doivent être de même longueur.');
    end
    arcs = [s, t];
    if numel(arguments) >= 3 && isnumeric(arguments{3}) && ~isempty(arguments{3})
        p = double(arguments{3}(:));
        if isscalar(p), p = repmat(p, numel(s), 1); end
        poids = p;
    else
        poids = ones(numel(s), 1);
    end
    nombre = max([0; s; t]);
    if ~isempty(noms)
        nombre = max(nombre, numel(noms));
    end
end

function indices = nomsVersIndices(liste, noms)
    indices = zeros(numel(liste), 1);
    for k = 1:numel(liste)
        j = find(strcmp(noms, liste{k}), 1);
        if isempty(j)
            error('MATLAB:graph:UnknownNode', 'Nœud inconnu : %s.', liste{k});
        end
        indices(k) = j;
    end
end
