function phrases = splitSentences(texte)
%SPLITSENTENCES Découpe un texte en phrases.
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
