function oui = estEntree(genre)
%ESTENTREE Le mot-clé désigne-t-il une entrée ?
%   Accepte 'input' et 'in' pour une entrée, 'output' et 'out' pour une
%   sortie ; toute autre valeur est refusée.
%
%   Exemple :
%      estEntree('input')          % 1
%      estEntree('output')         % 0
%
%   Voir aussi VARIABLESDE, TROUVERVARIABLE, ADDINPUT.
    mot = lower(char(genre));
    if any(strcmp(mot, {'input', 'in'}))
        oui = true;
    elseif any(strcmp(mot, {'output', 'out'}))
        oui = false;
    else
        error('fuzzy:estEntree:BadType', ...
              'Type must be ''input'' or ''output''.');
    end
end
