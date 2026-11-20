function mots = tokenizedDocument(texte)
%TOKENIZEDDOCUMENT Découpe un texte en mots, en minuscules.
%   MOTS = TOKENIZEDDOCUMENT(TEXTE) rend une cellule de mots : la
%   ponctuation est retirée, la casse normalisée.
%
%   Découper un texte en mots paraît trivial et ne l'est pas : les
%   apostrophes, les traits d'union et les abréviations font des cas
%   particuliers dans toutes les langues. Le découpage employé ici est
%   simple — tout ce qui n'est pas alphanumérique sépare — ce qui suffit
%   pour compter des mots mais coupe « aujourd'hui » en deux.
%
%   Normaliser la casse est ce qui permet de reconnaître « Le » et « le »
%   comme le même mot. C'est presque toujours souhaitable, sauf quand la
%   majuscule porte une information — un nom propre.
%
%   DOCS = TOKENIZEDDOCUMENT(TEXTES), où TEXTES est un tableau de chaînes
%   ou une cellule de textes, rend, comme MATLAB, un document par texte :
%   une cellule de même taille dont chaque case est la cellule des mots
%   d'un texte, celle que prend BAGOFWORDS.
%
%   Exemples :
%      tokenizedDocument('Le chat, le chien !')   % {'le','chat','le','chien'}
%      docs = tokenizedDocument(["Le chat dort.", "Le chien court."]);
%      [c, v] = bagOfWords(docs)                  % deux lignes, une par texte
%
%   Voir aussi BAGOFWORDS, REMOVESTOPWORDS, NORMALIZEWORDS, SPLITSENTENCES.
    if iscell(texte) || (isstring(texte) && ~isscalar(texte))
        mots = cell(size(texte));
        for k = 1:numel(texte)
            mots{k} = tokenizedDocument(char(texte(k)));
        end
        return
    end
    if ischar(texte) && size(texte, 1) > 1
        error('textanalytics:tokenizedDocument:Matrice', ...
              'Un texte par ligne de caractères : passer un tableau de chaînes ou une cellule.');
    end
    texte = lower(char(texte));
    propre = regexprep(texte, '[^a-z0-9àâçéèêëîïôûùüÿñæœ'']', ' ');
    morceaux = strsplit(strtrim(propre), ' ');
    mots = {};
    for k = 1:numel(morceaux)
        m = strtrim(morceaux{k});
        if ~isempty(m)
            mots{end+1} = m;
        end
    end
end
