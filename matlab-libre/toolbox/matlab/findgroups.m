function [g, varargout] = findgroups(varargin)
%FINDGROUPS Numérote les groupes d'un tableau de classement.
%   G = FINDGROUPS(A) rend, pour chaque élément de A, le numéro de son
%   groupe : les valeurs distinctes de A sont numérotées dans l'ordre
%   croissant. Une valeur manquante donne NaN.
%
%   [G,ID] = FINDGROUPS(A) rend en outre la valeur qui définit chaque
%   groupe.
%
%   [G,ID1,ID2] = FINDGROUPS(A1,A2) croise deux classements.
%
%   Exemple :
%      [g, noms] = findgroups({'b','a','b'})   % g = [2 1 2]
%
%   Voir aussi SPLITAPPLY, UNIQUE, ACCUMARRAY, GROUPSUMMARY.
    if isempty(varargin)
        error('findgroups:Arguments', 'findgroups attend au moins un tableau.');
    end
    n = numel(varargin{1});
    cles = cell(n, 1);
    for i = 1:n
        morceaux = cell(1, numel(varargin));
        for k = 1:numel(varargin)
            morceaux{k} = char(texteDe(varargin{k}, i));
        end
        cles{i} = strjoin(morceaux, char(1));
    end
    manque = false(n, 1);
    for k = 1:numel(varargin)
        m = ismissing(varargin{k});
        manque = manque | m(:);
    end
    [distinctes, ~, position] = unique(cles(~manque));
    % Une catégorielle porte l'ordre de ses catégories : les groupes le
    % suivent, plutôt que l'ordre alphabétique des noms. C'est ce que
    % MATLAB fait, et c'est le seul ordre qui ait un sens pour des
    % modalités ordonnées comme « bas », « moyen », « haut ».
    if numel(varargin) == 1 && isa(varargin{1}, 'categorical')
        ordreCategories = cellstr(categories(varargin{1}));
        rang = zeros(numel(distinctes), 1);
        for k = 1:numel(distinctes)
            place = find(strcmp(ordreCategories, distinctes{k}), 1);
            if isempty(place)
                place = numel(ordreCategories) + k;
            end
            rang(k) = place;
        end
        [~, permutation] = sort(rang);
        inverse = zeros(size(permutation));
        inverse(permutation) = 1:numel(permutation);
        distinctes = distinctes(permutation);
        position = inverse(position);
    end
    g = NaN(n, 1);
    g(~manque) = position;
    if isrow(varargin{1})
        g = g';
    end
    for k = 1:min(numel(varargin), max(nargout - 1, 0))
        source = varargin{k};
        indices = zeros(numel(distinctes), 1);
        vus = false(numel(distinctes), 1);
        libres = find(~manque);
        for i = 1:numel(libres)
            j = position(i);
            if ~vus(j)
                vus(j) = true;
                indices(j) = libres(i);
            end
        end
        if iscell(source)
            varargout{k} = source(indices);   %#ok<AGROW>
        else
            varargout{k} = source(indices);   %#ok<AGROW>
        end
    end
end

function t = texteDe(a, i)
% Une clé lisible pour un élément, quel que soit son type. Les nombres
% passent par un format assez large pour ne pas confondre deux valeurs
% voisines.
    if iscell(a)
        t = char(string(a{i}));
    elseif isnumeric(a) || islogical(a)
        t = sprintf('%.17g', double(a(i)));
    else
        t = char(string(a(i)));
    end
end
