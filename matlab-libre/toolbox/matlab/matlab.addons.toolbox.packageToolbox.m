function fichier = matlab.addons.toolbox.packageToolbox(dossier, nomArchive)
%MATLAB.ADDONS.TOOLBOX.PACKAGETOOLBOX Empaquette une toolbox.
%   F = ...PACKAGETOOLBOX(DOSSIER,NOM) fabrique une archive du dossier.
%   MATLAB produit un .mltbx ; ici c'est une archive ZIP, lisible partout
%   et réinstallable par installToolbox après décompression.
    if nargin < 2 || isempty(nomArchive)
        [~, nom] = fileparts(dossier);
        nomArchive = [nom '.zip'];
    end
    if ~isfolder(dossier)
        error('MATLAB:addons:NotAFolder', 'The toolbox source is not a folder.');
    end
    fichiers = dir(fullfile(dossier, '*.m'));
    liste = cell(1, numel(fichiers));
    for k = 1:numel(fichiers)
        liste{k} = fullfile(dossier, fichiers(k).name);
    end
    zip(nomArchive, liste);
    fichier = nomArchive;
end
