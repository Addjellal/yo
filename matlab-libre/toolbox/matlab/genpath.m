function p = genpath(dossier)
%GENPATH Chemin d'un dossier et de tous ses sous-dossiers.
%   P = GENPATH(D) rend, séparés par PATHSEP, D et tous ses
%   sous-dossiers. Les dossiers que MATLAB réserve — ceux dont le nom
%   commence par un point, par « @ » ou par « + », et « private » — n'y
%   figurent pas : ils ne s'ajoutent pas au chemin de recherche.
%
%   Sans argument, GENPATH part du dossier courant.
%
%   Exemple :
%      addpath(genpath(fullfile(matlabroot, 'toolbox', 'monlot')));
%
%   Voir aussi PATH, ADDPATH, PATHSEP, DIR.
    if nargin < 1
        dossier = pwd();
    end
    dossier = char(dossier);
    if ~isfolder(dossier)
        p = '';
        return;
    end
    liste = {dossier};
    liste = [liste, sousDossiers(dossier)];
    p = strjoin(liste, pathsep());
    p = [p pathsep()];
end

function liste = sousDossiers(dossier)
    liste = {};
    entrees = dir(dossier);
    for k = 1:numel(entrees)
        e = entrees(k);
        if ~e.isdir
            continue;
        end
        nom = e.name;
        if strcmp(nom, '.') || strcmp(nom, '..')
            continue;
        end
        if nom(1) == '.' || nom(1) == '@' || nom(1) == '+' || strcmp(nom, 'private')
            continue;
        end
        chemin = fullfile(dossier, nom);
        liste{end+1} = chemin;            %#ok<AGROW>
        liste = [liste, sousDossiers(chemin)];   %#ok<AGROW>
    end
end
