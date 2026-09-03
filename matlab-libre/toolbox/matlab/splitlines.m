function morceaux = splitlines(texte)
%SPLITLINES Découpe du texte à chaque saut de ligne.
%   C = SPLITLINES(S) rend une ligne par ligne de S. Les trois fins de
%   ligne — LF, CR, CRLF — sont reconnues.
%
%   Exemple :
%      splitlines(sprintf('un\ndeux'))
%
%   Voir aussi SPLIT, STRSPLIT, JOIN.
    if ischar(texte)
        texte = strrep(texte, sprintf('\r\n'), sprintf('\n'));
        texte = strrep(texte, sprintf('\r'), sprintf('\n'));
    elseif isstring(texte) || iscell(texte)
        for k = 1:numel(texte)
            if iscell(texte)
                t = char(texte{k});
            else
                t = char(texte(k));
            end
            t = strrep(t, sprintf('\r\n'), sprintf('\n'));
            t = strrep(t, sprintf('\r'), sprintf('\n'));
            if iscell(texte)
                texte{k} = t;
            else
                texte(k) = t;
            end
        end
    end
    morceaux = split(texte, sprintf('\n'));
end
