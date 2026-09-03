function indices = indicesSymboles(seq, symboles, m)
%INDICESSYMBOLES Traduit une suite de symboles en indices de colonne.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isempty(symboles)
        indices = round(double(seq(:)).');
        if any(indices < 1) || any(indices > m)
            error('stats:hmm:Symbole', ...
                  'Les symboles doivent être des entiers de 1 à %d.', m);
        end
        return;
    end
    if ischar(symboles)
        symboles = num2cell(symboles);
    elseif isnumeric(symboles)
        symboles = num2cell(symboles);
    else
        symboles = cellstr(symboles);
    end
    if ischar(seq)
        seq = num2cell(seq);
    elseif isnumeric(seq)
        seq = num2cell(seq);
    else
        seq = cellstr(seq);
    end
    indices = zeros(1, numel(seq));
    for k = 1:numel(seq)
        trouve = 0;
        for j = 1:numel(symboles)
            if isequal(seq{k}, symboles{j})
                trouve = j;
                break;
            end
        end
        if trouve == 0
            error('stats:hmm:Symbole', 'Symbole inconnu à la position %d.', k);
        end
        indices(k) = trouve;
    end
end
