function reponse = webwrite(url, varargin)
%WEBWRITE Envoie des données à une adresse et rend sa réponse.
%   R = WEBWRITE(URL,NOM1,VAL1,...) envoie les couples en corps de
%   requête, encodés comme un formulaire, et rend la réponse décodée.
%
%   R = WEBWRITE(URL,DONNEES) envoie DONNEES : un texte part tel quel,
%   une structure ou une cellule part en JSON.
%
%   R = WEBWRITE(...,OPTIONS) obéit aux réglages de WEBOPTIONS.
%   'RequestMethod' choisit la méthode — POST par défaut, mais aussi PUT
%   ou DELETE ; 'MediaType' déclare le type envoyé ; 'ContentType' dit
%   comment lire la réponse.
%
%   L'envoi passe par curl, qui doit être installé. Rien n'est envoyé
%   que ce que l'appel contient.
%
%   Exemple :
%      o = weboptions('MediaType', 'application/json', 'RequestMethod', 'put');
%      strcmp(o.MediaType, 'application/json')   % 1 : le type declare
%      % r = webwrite('https://exemple.test/api', struct('a', 1), o);
%
%   Voir aussi WEBREAD, WEBSAVE, WEBOPTIONS, JSONENCODE.
    [reglages, donnees] = matlibre_web_reglages(varargin);
    [corps, typeMedia] = matlibre_web_corps(donnees, reglages);

    methode = 'POST';
    if isfield(reglages, 'RequestMethod') && ...
       ~any(strcmpi(reglages.RequestMethod, {'auto', ''}))
        methode = upper(char(reglages.RequestMethod));
    end

    fichierCorps = [tempname() '.corps'];
    identifiant = fopen(fichierCorps, 'w');
    if identifiant < 0
        error('MATLAB:webservices:CannotWriteBody', ...
              'Impossible d''écrire le corps de la requête.');
    end
    fwrite(identifiant, corps, 'char');
    fclose(identifiant);

    fichierReponse = [tempname() '.reponse'];
    try
        matlibre_web_curl(char(url), fichierReponse, reglages, methode, ...
                          fichierCorps, typeMedia);
        texte = fileread(fichierReponse);
    catch erreurEnvoi
        effacer(fichierCorps);
        effacer(fichierReponse);
        rethrow(erreurEnvoi);
    end
    effacer(fichierCorps);
    effacer(fichierReponse);
    reponse = matlibre_web_contenu(texte, char(url), reglages.ContentType);
end

function effacer(f)
    if isfile(f)
        delete(f);
    end
end
