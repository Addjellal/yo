function sortie = normalizeWords(mots)
%NORMALIZEWORDS Racinisation : retire les suffixes les plus courants.
%   SORTIE = NORMALIZEWORDS(MOTS) ramène chaque mot à une racine
%   approchée, en retirant les suffixes usuels.
%
%   Le but est de reconnaître « chante », « chantes » et « chantant »
%   comme un même terme, pour ne pas les compter séparément. La racine
%   obtenue n'est pas un mot : c'est une clé de regroupement, et il ne
%   faut pas l'afficher à un lecteur.
%
%   La racinisation par suffixes se trompe : elle rapproche des mots sans
%   rapport et sépare des formes irrégulières. La lemmatisation, qui
%   consulte un dictionnaire, fait mieux mais demande ce dictionnaire.
%
%   Exemple :
%      normalizeWords({'chantes', 'chantant', 'chante'})
%
%   Voir aussi TOKENIZEDDOCUMENT, REMOVESTOPWORDS.
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
