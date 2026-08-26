function matlab.addons.toolbox.uninstallToolbox(identifiant)
%MATLAB.ADDONS.TOOLBOX.UNINSTALLTOOLBOX Retire une toolbox installée.
%   ...UNINSTALLTOOLBOX(ID) efface le dossier et le retire du chemin.
    racine = matlibre_racine_toolbox();
    cible = fullfile(racine, char(identifiant));
    if ~isfolder(cible)
        error('MATLAB:addons:NotInstalled', ...
              'No toolbox named ''%s'' is installed.', identifiant);
    end
    rmpath(cible);
    rmdir(cible, 's');
    rehash;
end
