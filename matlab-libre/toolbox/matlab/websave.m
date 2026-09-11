function chemin = websave(nomFichier, url, varargin)
%WEBSAVE Enregistre le contenu d'une adresse dans un fichier.
%   F = WEBSAVE(FICHIER,URL) télécharge l'adresse et l'écrit dans
%   FICHIER ; F est le chemin complet du fichier écrit.
%
%   F = WEBSAVE(FICHIER,URL,NOM1,VAL1,...) ajoute des paramètres à la
%   requête, comme le fait MATLAB : websave(f, url, 'q', 'chat') demande
%   URL?q=chat.
%
%   F = WEBSAVE(...,OPTIONS) obéit en plus aux réglages de WEBOPTIONS :
%   délai, agent, authentification, en-têtes, autorité de certification.
%
%   Le téléchargement passe par curl, qui doit être installé. Aucune
%   donnée n'est envoyée que celles de l'appel.
%
%   Exemple :
%      f = websave(fullfile(tempdir, 'page.html'), 'https://example.com');
%
%   Voir aussi WEBREAD, WEBWRITE, WEBOPTIONS, URLREAD, FILEREAD.
    nomFichier = char(nomFichier);
    [reglages, paires] = matlibre_web_reglages(varargin);
    url = matlibre_web_requete(char(url), paires);
    methode = '';
    if isfield(reglages, 'RequestMethod') && ...
       ~any(strcmpi(reglages.RequestMethod, {'auto', ''}))
        methode = reglages.RequestMethod;
    end
    matlibre_web_curl(url, nomFichier, reglages, methode);
    chemin = nomFichier;
    if ~estAbsolu(chemin)
        chemin = fullfile(pwd(), chemin);
    end
end

function tf = estAbsolu(nom)
    tf = ~isempty(nom) && (nom(1) == '/' || nom(1) == '\' || ...
        (numel(nom) > 1 && nom(2) == ':'));
end
