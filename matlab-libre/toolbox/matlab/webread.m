function contenu = webread(url, varargin)
%WEBREAD Lit le contenu d'une adresse.
%   C = WEBREAD(URL) télécharge l'adresse et rend son contenu. Un
%   document JSON est décodé en structure ou en tableau de cellules ; un
%   fichier délimité est lu comme une matrice ; le reste est rendu tel
%   quel, en texte.
%
%   C = WEBREAD(URL,NOM1,VAL1,...) ajoute des paramètres à la requête.
%
%   Le téléchargement passe par curl, qui doit être installé. Aucune
%   donnée n'est envoyée que celles de l'appel.
%
%   Exemple :
%      s = webread('https://example.com');
%
%   Voir aussi WEBSAVE, JSONDECODE, URLREAD.
    fichier = [tempname() '.telechargement'];
    try
        websave(fichier, url, varargin{:});
        texte = fileread(fichier);
    catch erreurLecture
        effacer(fichier);
        rethrow(erreurLecture);
    end
    effacer(fichier);
    contenu = interpreter(texte, char(url));
end

function c = interpreter(texte, url)
% Ce que MATLAB fait du contenu dépend de son type ; sans en-tête à
% notre disposition, on se règle sur l'extension et sur la forme du
% texte lui-même.
    coupe = strtrim(texte);
    [~, ~, ext] = fileparts(strtok(url, '?'));
    if strcmpi(ext, '.json') || (~isempty(coupe) && any(coupe(1) == '{['))
        try
            c = jsondecode(coupe);
            return;
        catch
            % Ce n'était pas du JSON : le texte reste du texte.
        end
    end
    if any(strcmpi(ext, {'.csv', '.tsv', '.txt'}))
        f = [tempname() ext];
        fid = fopen(f, 'w');
        if fid >= 0
            fprintf(fid, '%s', texte);
            fclose(fid);
            try
                c = readmatrix(f);
                delete(f);
                return;
            catch
                delete(f);
            end
        end
    end
    c = texte;
end

function effacer(f)
    if isfile(f)
        delete(f);
    end
end
