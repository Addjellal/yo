function [effectifs, vocabulaire] = bagOfWords(documents)
%BAGOFWORDS Matrice d'effectifs mot par document.
%   [C,V] = BAGOFWORDS(DOCS) où DOCS est une cellule de cellules de mots.
%   C(i,j) compte les occurrences du mot V{j} dans le document i.
    vocabulaire = {};
    for d = 1:numel(documents)
        mots = documents{d};
        for k = 1:numel(mots)
            if ~any(strcmp(vocabulaire, mots{k}))
                vocabulaire{end+1} = mots{k};
            end
        end
    end
    vocabulaire = sort(vocabulaire);
    effectifs = zeros(numel(documents), numel(vocabulaire));
    for d = 1:numel(documents)
        mots = documents{d};
        for k = 1:numel(mots)
            j = find(strcmp(vocabulaire, mots{k}), 1);
            effectifs(d, j) = effectifs(d, j) + 1;
        end
    end
end
