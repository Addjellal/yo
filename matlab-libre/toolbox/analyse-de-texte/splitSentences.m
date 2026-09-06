function phrases = splitSentences(texte)
%SPLITSENTENCES Découpe un texte en phrases.
%   PHRASES = SPLITSENTENCES(TEXTE) rend une cellule de phrases, coupées
%   sur les points, points d'interrogation et points d'exclamation.
%
%   Le découpage est syntaxique, non sémantique : un point d'abréviation
%   — « M. Dupont », « etc. » — coupe une phrase en deux, et aucune règle
%   simple ne distingue les deux emplois du point. Les découpeurs sérieux
%   emploient une liste d'abréviations, voire un modèle appris.
%
%   Exemple :
%      splitSentences('Bonjour. Ça va ? Oui !')   % trois phrases
%
%   Voir aussi TOKENIZEDDOCUMENT, WORDFREQUENCY.
    texte = char(texte);
    phrases = {};
    courante = '';
    for k = 1:numel(texte)
        c = texte(k);
        courante = [courante c];
        if c == '.' || c == '!' || c == '?'
            p = strtrim(courante);
            if ~isempty(p)
                phrases{end+1} = p;
            end
            courante = '';
        end
    end
    reste = strtrim(courante);
    if ~isempty(reste)
        phrases{end+1} = reste;
    end
end
