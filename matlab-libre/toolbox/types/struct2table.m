function t = struct2table(s, varargin)
%STRUCT2TABLE Convertit un tableau de structures en table.
%   Chaque champ devient une variable ; un tableau 1x1 dont les champs sont
%   des colonnes est accepté également.
    champs = fieldnames(s);
    n = numel(s);
    colonnes = cell(1, numel(champs));
    for j = 1:numel(champs)
        if n == 1
            colonnes{j} = s.(champs{j});
        else
            premier = s(1).(champs{j});
            if isnumeric(premier) && isscalar(premier)
                v = zeros(n, 1);
                for i = 1:n, v(i) = s(i).(champs{j}); end
            elseif islogical(premier) && isscalar(premier)
                v = false(n, 1);
                for i = 1:n, v(i) = s(i).(champs{j}); end
            else
                v = cell(n, 1);
                for i = 1:n, v{i} = s(i).(champs{j}); end
            end
            colonnes{j} = v;
        end
    end
    t = table(colonnes{:}, 'VariableNames', champs(:)', varargin{:});
end
