function fichier = zip(nomArchive, fichiers, racine)
%ZIP Fabrique une archive ZIP.
%   ZIP(ARCHIVE,FICHIERS) empaquette les fichiers donnés. FICHIERS peut
%   être un nom, une cellule de noms ou un motif.
%
%   L'archive est produite par la commande « zip » du système ; sans
%   elle, la fonction le dit clairement plutôt que d'écrire un fichier
%   incomplet.
    if nargin < 3, racine = pwd(); end
    if ischar(fichiers) || isstring(fichiers)
        fichiers = {char(fichiers)};
    end
    [~, ~] = system('zip --version');
    [codeVersion, ~] = system('zip --version');
    if codeVersion ~= 0
        error('MATLAB:zip:NoZipCommand', ...
              ['La commande « zip » est introuvable : impossible de fabriquer ' ...
               'l''archive %s.'], nomArchive);
    end
    liste = '';
    for k = 1:numel(fichiers)
        liste = [liste ' ' guillemets(fichiers{k})]; %#ok<AGROW>
    end
    commande = sprintf('cd %s && zip -q -j %s%s', guillemets(racine), ...
                       guillemets(nomArchive), liste);
    [code, message] = system(commande);
    if code ~= 0
        error('MATLAB:zip:Failed', 'La fabrication de l''archive a echoue : %s', message);
    end
    fichier = nomArchive;
end

function s = guillemets(chemin)
    s = ['''' strrep(char(chemin), '''', '''\''''') ''''];
end
