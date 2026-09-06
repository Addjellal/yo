function M = tfidf(effectifs)
%TFIDF Pondération terme-fréquence / fréquence inverse de document.
%   M = TFIDF(C) où C est la matrice rendue par BAGOFWORDS : une ligne par
%   document, une colonne par mot du vocabulaire.
%
%   Le poids d'un mot dans un document est son effectif multiplié par le
%   logarithme de l'inverse de la proportion de documents qui le
%   contiennent. Un mot présent dans tous les documents reçoit donc un
%   poids nul : il ne distingue rien.
%
%   C'est ce qui fait la valeur de la pondération : elle décide de ce qui
%   est spécifique d'après le corpus lui-même, sans liste de mots vides
%   décidée à l'avance. Un terme technique rare dans le corpus général
%   mais fréquent dans un document le caractérise ; un article, non.
%
%   Exemple :
%      [c, v] = bagOfWords({{'chat','chien'}, {'chat','oiseau'}});
%      m = tfidf(c);
%      m(:, strcmp(v, 'chat'))         % 0 : present partout
%
%   Voir aussi BAGOFWORDS, WORDFREQUENCY.
    [n, v] = size(effectifs);
    df = sum(effectifs > 0, 1);
    idf = log(n ./ max(df, 1));
    M = zeros(n, v);
    for i = 1:n
        total = sum(effectifs(i, :));
        if total == 0
            continue;
        end
        M(i, :) = (effectifs(i, :) / total) .* idf;
    end
end
