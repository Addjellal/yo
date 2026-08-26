function sortie = normalizeWords(mots)
%NORMALIZEWORDS Racinisation : retire les suffixes les plus courants.
    suffixes = {'ements', 'ement', 'ations', 'ation', 'ities', 'ing', ...
                'ers', 'es', 'er', 'ed', 'ly', 's'};
    sortie = cell(size(mots));
    for k = 1:numel(mots)
        m = mots{k};
        for s = 1:numel(suffixes)
            suffixe = suffixes{s};
            if numel(m) > numel(suffixe) + 2 && endsWith(m, suffixe)
                m = m(1:end-numel(suffixe));
                break;
            end
        end
        sortie{k} = m;
    end
end
