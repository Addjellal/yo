function varargout = splitapply(f, varargin)
%SPLITAPPLY Applique une fonction groupe par groupe.
%   Y = SPLITAPPLY(F,X,G) découpe X suivant les numéros de groupe G —
%   ceux que rend FINDGROUPS — et applique F à chaque morceau. Les
%   résultats sont empilés dans Y, un par groupe.
%
%   Y = SPLITAPPLY(F,X1,X2,...,G) passe un morceau de chaque tableau.
%   [Y1,Y2,...] = SPLITAPPLY(...) récupère plusieurs sorties.
%
%   Exemple :
%      x = [1 2 3 4];  g = [1 1 2 2];
%      splitapply(@sum, x, g)     % [3; 7]
%
%   Voir aussi FINDGROUPS, ACCUMARRAY, ARRAYFUN, GROUPSUMMARY.
    if numel(varargin) < 2
        error('splitapply:Arguments', ...
              'splitapply attend au moins un tableau et les groupes.');
    end
    g = varargin{end};
    donnees = varargin(1:end-1);
    g = double(g(:));
    valides = ~isnan(g);
    ngroupes = 0;
    if any(valides)
        ngroupes = max(g(valides));
    end
    nsorties = max(nargout, 1);
    resultats = cell(nsorties, ngroupes);
    for k = 1:ngroupes
        choix = find(g == k);
        morceaux = cell(1, numel(donnees));
        for j = 1:numel(donnees)
            morceaux{j} = tranche(donnees{j}, choix);
        end
        sorties = cell(1, nsorties);
        [sorties{1:nsorties}] = feval(f, morceaux{:});
        resultats(:, k) = sorties(:);
    end
    varargout = cell(1, nsorties);
    for s = 1:nsorties
        varargout{s} = empiler(resultats(s, :));
    end
end

function m = tranche(x, choix)
% Le morceau d'un tableau : par lignes s'il en a plusieurs, sinon par
% éléments, comme le fait MATLAB.
    if istable(x) || istimetable(x)
        m = x(choix, :);
    elseif isvector(x) || isscalar(x)
        m = x(choix);
        if isrow(x)
            m = reshape(m, 1, []);
        end
    else
        m = x(choix, :);
    end
end

function y = empiler(morceaux)
% Un scalaire par groupe donne une colonne ; un vecteur par groupe donne
% une ligne par groupe ; le reste part en cellules.
    if isempty(morceaux)
        y = [];
        return;
    end
    scalaires = true;
    memeLargeur = true;
    largeur = numel(morceaux{1});
    for k = 1:numel(morceaux)
        v = morceaux{k};
        if ~(isnumeric(v) || islogical(v)) || ~isscalar(v)
            scalaires = false;
        end
        if ~(isnumeric(v) || islogical(v)) || numel(v) ~= largeur
            memeLargeur = false;
        end
    end
    if scalaires
        y = zeros(numel(morceaux), 1);
        for k = 1:numel(morceaux)
            y(k) = morceaux{k};
        end
    elseif memeLargeur
        y = zeros(numel(morceaux), largeur);
        for k = 1:numel(morceaux)
            v = morceaux{k};
            y(k, :) = v(:)';
        end
    else
        y = morceaux(:);
    end
end
