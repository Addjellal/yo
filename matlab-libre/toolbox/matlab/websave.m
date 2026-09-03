function chemin = websave(nomFichier, url, varargin)
%WEBSAVE Enregistre le contenu d'une adresse dans un fichier.
%   F = WEBSAVE(FICHIER,URL) télécharge l'adresse et l'écrit dans
%   FICHIER ; F est le chemin complet du fichier écrit.
%
%   F = WEBSAVE(FICHIER,URL,NOM1,VAL1,...) ajoute des paramètres à la
%   requête, comme le fait MATLAB : websave(f, url, 'q', 'chat') demande
%   URL?q=chat.
%
%   Le téléchargement passe par curl, qui doit être installé. Aucune
%   donnée n'est envoyée que celles de l'appel.
%
%   Exemple :
%      f = websave(fullfile(tempdir, 'page.html'), 'https://example.com');
%
%   Voir aussi WEBREAD, URLREAD, FILEREAD.
    nomFichier = char(nomFichier);
    url = construireUrl(char(url), varargin);
    commande = sprintf('curl -sS -L -f -o %s %s', citer(nomFichier), citer(url));
    [etat, sortie] = system(commande);
    if etat ~= 0
        error('MATLAB:webservices:CopyContentToDataStreamError', ...
              'Le téléchargement de %s a échoué : %s', url, strtrim(sortie));
    end
    chemin = nomFichier;
    if ~estAbsolu(chemin)
        chemin = fullfile(pwd(), chemin);
    end
end

function u = construireUrl(u, paires)
    if isempty(paires)
        return;
    end
    morceaux = cell(1, floor(numel(paires) / 2));
    for k = 1:2:numel(paires) - 1
        morceaux{(k + 1) / 2} = sprintf('%s=%s', char(paires{k}), ...
                                        encoder(char(string(paires{k+1}))));
    end
    if any(u == '?')
        u = [u '&' strjoin(morceaux, '&')];
    else
        u = [u '?' strjoin(morceaux, '&')];
    end
end

function t = encoder(t)
% Un encodage d'URL minimal : ce qui n'est ni lettre, ni chiffre, ni
% l'un des caractères sûrs passe en %XX.
    sortie = '';
    for k = 1:numel(t)
        c = t(k);
        if isletter(c) || (c >= '0' && c <= '9') || any(c == '-_.~')
            sortie(end+1) = c;   %#ok<AGROW>
        else
            sortie = [sortie sprintf('%%%02X', double(c))];   %#ok<AGROW>
        end
    end
    t = sortie;
end

function t = citer(t)
    t = ['"' strrep(t, '"', '\"') '"'];
end

function tf = estAbsolu(nom)
    tf = ~isempty(nom) && (nom(1) == '/' || nom(1) == '\' || ...
        (numel(nom) > 1 && nom(2) == ':'));
end
