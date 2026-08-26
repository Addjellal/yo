function varargout = pararrayfun(fonction, varargin)
%PARARRAYFUN Équivalent parallèle d'ARRAYFUN.
%   Chaque élément part sur un travailleur du pool ; les résultats
%   reviennent dans l'ordre des indices.
%
%   Exemple :
%      v = pararrayfun(@(x) x^2, 1:4)      % [1 4 9 16]
    options = {};
    entrees = varargin;
    k = 1;
    while k <= numel(entrees)
        if (ischar(entrees{k}) || isstring(entrees{k})) && k < numel(entrees) && ...
                any(strcmpi(char(entrees{k}), {'UniformOutput', 'ErrorHandler'}))
            options = [options, entrees(k:k + 1)]; %#ok<AGROW>
            entrees(k:k + 1) = [];
        else
            k = k + 1;
        end
    end
    uniforme = true;
    for k = 1:2:numel(options) - 1
        if strcmpi(char(options{k}), 'UniformOutput')
            uniforme = logical(options{k + 1});
        end
    end
    n = numel(entrees{1});
    futurs = cell(1, n);
    for i = 1:n
        arguments_ = cell(1, numel(entrees));
        for j = 1:numel(entrees)
            arguments_{j} = entrees{j}(i);
        end
        futurs{i} = parfeval(fonction, 1, arguments_{:});
    end
    resultats = cell(1, n);
    for i = 1:n
        resultats{i} = fetchOutputs(futurs{i});
    end
    if uniforme
        sortie = zeros(size(entrees{1}));
        for i = 1:n, sortie(i) = resultats{i}; end
    else
        sortie = reshape(resultats, size(entrees{1}));
    end
    varargout{1} = sortie;
end
