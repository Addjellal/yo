function c = matlibre_web_contenu(texte, url, typeVoulu)
%MATLIBRE_WEB_CONTENU Interprétation du corps d'une réponse web.
%   C = MATLIBRE_WEB_CONTENU(TEXTE,URL) rend le contenu décodé : un
%   document JSON devient structure ou cellule, un fichier délimité
%   (.csv, .tsv) fait de nombres devient une matrice, le reste — un .txt
%   compris — reste du texte.
%
%   C = MATLIBRE_WEB_CONTENU(TEXTE,URL,TYPE) impose l'interprétation :
%   'auto' devine, 'json' décode, 'text' et 'raw' rendent le texte tel
%   quel.
%
%   Sans en-tête à notre disposition, « deviner » se règle sur
%   l'extension de l'adresse et sur la forme du texte lui-même : c'est
%   moins sûr qu'un Content-Type, et c'est pourquoi 'ContentType' existe.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_web_contenu('{"a":1}', 'http://x/y.json').a   % 1
%
%   Voir aussi WEBREAD, WEBWRITE, WEBSAVE, JSONDECODE.
    if nargin < 3 || isempty(typeVoulu)
        typeVoulu = 'auto';
    end
    typeVoulu = lower(char(typeVoulu));
    coupe = strtrim(texte);
    if any(strcmp(typeVoulu, {'text', 'raw', 'binary'}))
        c = texte;
        return;
    end
    [~, ~, ext] = fileparts(strtok(char(url), '?'));
    if strcmp(typeVoulu, 'json') || strcmpi(ext, '.json') || ...
       (strcmp(typeVoulu, 'auto') && ~isempty(coupe) && any(coupe(1) == '{['))
        try
            c = jsondecode(coupe);
            return;
        catch erreurJson
            if strcmp(typeVoulu, 'json')
                rethrow(erreurJson);
            end
            % Ce n'était pas du JSON : le texte reste du texte.
        end
    end
    % Un .txt est du texte (text/plain, que MATLAB rend en caractères) : lu
    % par READMATRIX, un texte qui n'était pas fait de nombres devenait []
    % sans rien dire. Un fichier délimité dont rien ne se lit en nombres
    % reste du texte, pour la même raison.
    if strcmp(typeVoulu, 'auto') && any(strcmpi(ext, {'.csv', '.tsv'}))
        f = [tempname() ext];
        fid = fopen(f, 'w');
        if fid >= 0
            fprintf(fid, '%s', texte);
            fclose(fid);
            try
                c = readmatrix(f);
                delete(f);
                if ~isempty(c) && ~all(isnan(c(:)))
                    return;
                end
            catch
                delete(f);
            end
        end
    end
    c = texte;
end
