function varargout = parcellfun(fonction, varargin)
%PARCELLFUN Équivalent parallèle de CELLFUN.
%   Chaque case part sur un travailleur du pool.
%
%   Exemple :
%      v = parcellfun(@numel, {'a', 'bb', 'ccc'})   % [1 2 3]
    entrees = varargin;
    uniforme = true;
    k = 1;
    while k <= numel(entrees)
        if (ischar(entrees{k}) || isstring(entrees{k})) && k < numel(entrees) && ...
                strcmpi(char(entrees{k}), 'UniformOutput')
            uniforme = logical(entrees{k + 1});
            entrees(k:k + 1) = [];
        else
            k = k + 1;
        end
    end
    n = numel(entrees{1});
    futurs = cell(1, n);
    for i = 1:n
        arguments_ = cell(1, numel(entrees));
        for j = 1:numel(entrees)
            arguments_{j} = entrees{j}{i};
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
