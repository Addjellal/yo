function ordre = ordreDeNom(nom, prefixe)
%ORDREDENOM Ordre lu dans le nom d'une ondelette.
%   ORDRE = ORDREDENOM('db4','db') rend 4. 'haar' vaut 'db1'.
%   Le nom est refusé s'il n'appartient pas à la famille demandée.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    nom = lower(strtrim(char(nom)));
    if strcmp(nom, 'haar') && strcmp(prefixe, 'db')
        ordre = 1;
        return
    end
    n = numel(prefixe);
    if numel(nom) <= n || ~strcmp(nom(1:n), prefixe)
        error('wavelet:ordreDeNom:Famille', ...
              '''%s'' n''appartient pas à la famille ''%s''.', nom, prefixe);
    end
    ordre = str2double(nom(n+1:end));
    if isnan(ordre) || ordre < 1 || ordre ~= round(ordre)
        error('wavelet:ordreDeNom:Ordre', ...
              '''%s'' ne porte pas d''ordre entier.', nom);
    end
end
