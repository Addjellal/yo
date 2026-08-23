function t = array2table(a, varargin)
%ARRAY2TABLE Convertit une matrice en table, une colonne par variable.
%   T = ARRAY2TABLE(A) nomme les variables A1, A2, ...
%   T = ARRAY2TABLE(A,'VariableNames',NOMS) impose les noms,
%   T = ARRAY2TABLE(A,'RowNames',NOMS) nomme les lignes.
    noms = {}; lignes = {};
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'variablenames', noms = varargin{k + 1};
            case 'rownames',      lignes = varargin{k + 1};
        end
        k = k + 2;
    end
    m = size(a, 2);
    colonnes = cell(1, m);
    for j = 1:m
        colonnes{j} = a(:, j);
    end
    if isempty(noms)
        noms = cell(1, m);
        for j = 1:m, noms{j} = sprintf('A%d', j); end
    end
    if isempty(lignes)
        t = table(colonnes{:}, 'VariableNames', noms);
    else
        t = table(colonnes{:}, 'VariableNames', noms, 'RowNames', lignes);
    end
end
