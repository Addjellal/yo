function oui = estEntree(genre)
%ESTENTREE Le mot-clé désigne-t-il une entrée ?
%   Accepte 'input' et 'in' pour une entrée, 'output' et 'out' pour une
%   sortie ; toute autre valeur est refusée.
    mot = lower(char(genre));
    if any(strcmp(mot, {'input', 'in'}))
        oui = true;
    elseif any(strcmp(mot, {'output', 'out'}))
        oui = false;
    else
        error('fuzzy:estEntree:BadType', ...
              'Le type doit être ''input'' ou ''output''.');
    end
end
