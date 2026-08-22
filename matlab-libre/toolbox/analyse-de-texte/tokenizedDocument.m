function mots = tokenizedDocument(texte)
%TOKENIZEDDOCUMENT Découpe un texte en mots, en minuscules.
%   MOTS = TOKENIZEDDOCUMENT(TEXTE) rend une cellule de mots : la
%   ponctuation est retirée, la casse normalisée.
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
