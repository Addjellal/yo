function [mots, effectifs] = wordFrequency(liste)
%WORDFREQUENCY Fréquences des mots, par ordre décroissant.
    mots = {};
    effectifs = [];
    for k = 1:numel(liste)
        j = find(strcmp(mots, liste{k}), 1);
        if isempty(j)
            mots{end+1} = liste{k};
            effectifs(end+1) = 1;
        else
            effectifs(j) = effectifs(j) + 1;
        end
    end
    [effectifs, ordre] = sort(effectifs, 'descend');
    mots = mots(ordre);
end
