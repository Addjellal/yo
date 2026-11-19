function matlab.addons.toolbox.uninstallToolbox(identifiant)
%MATLAB.ADDONS.TOOLBOX.UNINSTALLTOOLBOX Retire une toolbox installée.
%   ...UNINSTALLTOOLBOX(ID) efface le dossier et le retire du chemin, avec
%   les sous-dossiers que l'installation y avait mis.
%
%   Exemple :
%      % Desinstaller ce qui n'est pas installe ne fait rien de mal.
%      try
%          matlab.addons.toolbox.uninstallToolbox('inconnue');
%      catch
%      end
%
%   Voir aussi MATLAB.ADDONS.TOOLBOX.INSTALLTOOLBOX.
    racine = matlibre_racine_toolbox();
    cible = fullfile(racine, char(identifiant));
    if ~isfolder(cible)
        error('MATLAB:addons:NotInstalled', ...
              'No toolbox named ''%s'' is installed.', identifiant);
    end
    rmpath(genpath(cible));
    rmdir(cible, 's');
    rehash;
end
