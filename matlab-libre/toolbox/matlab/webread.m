function contenu = webread(url, varargin)
%WEBREAD Lit le contenu d'une adresse.
%   C = WEBREAD(URL) télécharge l'adresse et rend son contenu. Un
%   document JSON est décodé en structure ou en tableau de cellules ; un
%   fichier délimité est lu comme une matrice ; le reste est rendu tel
%   quel, en texte.
%
%   C = WEBREAD(URL,NOM1,VAL1,...) ajoute des paramètres à la requête.
%
%   C = WEBREAD(...,OPTIONS) obéit aux réglages de WEBOPTIONS ;
%   'ContentType' impose alors l'interprétation au lieu de la deviner.
%
%   Le téléchargement passe par curl, qui doit être installé. Aucune
%   donnée n'est envoyée que celles de l'appel.
%
%   Exemple :
%      s = webread('https://example.com');
%
%   Voir aussi WEBSAVE, WEBWRITE, WEBOPTIONS, JSONDECODE, URLREAD.
    [reglages, paires] = matlibre_web_reglages(varargin);
    fichier = [tempname() '.telechargement'];
    try
        websave(fichier, url, paires{:}, reglages);
        texte = fileread(fichier);
    catch erreurLecture
        effacer(fichier);
        rethrow(erreurLecture);
    end
    effacer(fichier);
    contenu = matlibre_web_contenu(texte, char(url), reglages.ContentType);
end

function effacer(f)
    if isfile(f)
        delete(f);
    end
end
