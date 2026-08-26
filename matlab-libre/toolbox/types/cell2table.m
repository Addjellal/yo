function t = cell2table(c, varargin)
%CELL2TABLE Convertit une cellule à deux dimensions en table.
%   Chaque colonne devient une variable : numérique si toutes ses cases le
%   sont, cellule de textes sinon.
    noms = {}; lignes = {};
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'variablenames', noms = varargin{k + 1};
            case 'rownames',      lignes = varargin{k + 1};
        end
        k = k + 2;
    end
    m = size(c, 2);
    colonnes = cell(1, m);
    for j = 1:m
        colonne = c(:, j);
        numerique = true;
        for i = 1:numel(colonne)
            if ~(isnumeric(colonne{i}) && isscalar(colonne{i})), numerique = false; break, end
        end
        if numerique
            v = zeros(numel(colonne), 1);
            for i = 1:numel(colonne), v(i) = colonne{i}; end
            colonnes{j} = v;
        else
            colonnes{j} = colonne;
        end
    end
    if isempty(noms)
        noms = cell(1, m);
        for j = 1:m, noms{j} = sprintf('Var%d', j); end
    end
    if isempty(lignes)
        t = table(colonnes{:}, 'VariableNames', noms);
    else
        t = table(colonnes{:}, 'VariableNames', noms, 'RowNames', lignes);
    end
end
