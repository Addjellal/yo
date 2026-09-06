function [effectifs, vocabulaire] = bagOfWords(documents)
%BAGOFWORDS Matrice d'effectifs mot par document.
%   [C,V] = BAGOFWORDS(DOCS) où DOCS est une cellule de cellules de mots.
%   C(i,j) compte les occurrences du mot V{j} dans le document i.
%
%   Le sac de mots jette l'ordre : « le chien mord l'homme » et « l'homme
%   mord le chien » y sont indistinguables. C'est une perte considérable,
%   assumée parce qu'elle ramène un texte à un vecteur — et qu'à partir de
%   là toute la statistique s'applique.
%
%   La matrice est très creuse : chaque document n'emploie qu'une petite
%   part du vocabulaire. Sur un vrai corpus, elle se range en creux.
%
%   La somme d'une ligne est le nombre de mots du document ; la somme
%   d'une colonne, le nombre total d'occurrences du mot.
%
%   Exemple :
%      [c, v] = bagOfWords({{'chat','chien','chat'}, {'chat','oiseau'}});
%      sum(c, 2)                       % [3; 2] : la longueur des documents
%
%   Voir aussi TFIDF, TOKENIZEDDOCUMENT, WORDFREQUENCY.
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
