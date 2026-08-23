function identifiant = matlab.addons.toolbox.installToolbox(source, varargin)
%MATLAB.ADDONS.TOOLBOX.INSTALLTOOLBOX Installe une toolbox.
%   ID = ...INSTALLTOOLBOX(DOSSIER) copie le dossier donné dans la racine
%   des toolboxes et l'ajoute au chemin de recherche. Le dossier doit
%   contenir un fichier Contents.m, comme toute toolbox MATLAB.
%
%   Exemple :
%      matlab.addons.toolbox.installToolbox('/tmp/maToolbox');
    if ~isfolder(source)
        error('MATLAB:addons:NotAFolder', ...
              'The toolbox source ''%s'' is not a folder.', source);
    end
    if ~isfile(fullfile(source, 'Contents.m'))
        error('MATLAB:addons:NoContents', ...
              'A toolbox must contain a Contents.m file.');
    end
    racine = matlibre_racine_toolbox();
    [~, nom] = fileparts(strip_separateur(source));
    cible = fullfile(racine, nom);
    if isfolder(cible)
        error('MATLAB:addons:AlreadyInstalled', ...
              'A toolbox named ''%s'' is already installed.', nom);
    end
    copyfile(source, cible);
    addpath(cible);
    rehash;
    identifiant = nom;
end

function chemin = strip_separateur(chemin)
    chemin = char(chemin);
    while ~isempty(chemin) && (chemin(end) == '/' || chemin(end) == '\')
        chemin(end) = [];
    end
end
