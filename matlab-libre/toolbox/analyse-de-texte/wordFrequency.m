function [mots, effectifs] = wordFrequency(liste)
%WORDFREQUENCY Fréquences des mots, par ordre décroissant.
%   [MOTS,EFFECTIFS] = WORDFREQUENCY(LISTE) compte les occurrences et rend
%   les mots du plus fréquent au moins fréquent.
%
%   La distribution des fréquences suit à peu près la loi de Zipf : le
%   k-ième mot le plus fréquent apparaît environ n/k fois. C'est pourquoi
%   les tout premiers mots — les mots vides — écrasent tous les autres, et
%   pourquoi une longue queue de mots n'apparaît qu'une seule fois.
%
%   Exemple :
%      [mots, n] = wordFrequency({'a','b','a','c','a','b'});
%      mots{1}                         % 'a', trois fois
%
%   Voir aussi BAGOFWORDS, TFIDF, REMOVESTOPWORDS.
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
