function fichiers = matlibre_fichiers_module(dossier)
%MATLIBRE_FICHIERS_MODULE Les fichiers .m d'un module de toolbox.
%   F = MATLIBRE_FICHIERS_MODULE(DOSSIER) rend, comme DIR, les fichiers .m
%   du dossier DOSSIER et de ses sous-dossiers ordinaires, rangés par nom
%   quel que soit leur dossier ; le champ « folder » dit où vit chacun.
%
%   Les sous-dossiers ordinaires sont ceux que garde GENPATH : ni
%   « @classe », ni « +paquet », ni « private ». Ce sont ceux que MatLibre
%   met sur le chemin de recherche avec le module, au démarrage. Deux
%   fonctions dont le nom ne diffère que par la casse ne tiennent pas dans
%   un même dossier sous Windows ni sous macOS : l'ancienne forme vit dans
%   un sous-dossier, comme flou/ancien, et les outils qui parcourent les
%   toolboxes doivent l'y trouver.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      f = matlibre_fichiers_module(fullfile(matlibre_racine(), 'flou'));
%      any(strcmp({f.name}, 'addmf.m'))      % 1 : il vit dans flou/ancien
%
%   Voir aussi GENPATH, DIR, WHICH.
    fichiers = dir(fullfile(dossier, '*.m'));
    sousDossiers = strsplit(genpath(dossier), pathsep);
    % GENPATH met le dossier lui-même en tête, et finit par un séparateur.
    for k = 2:numel(sousDossiers)
        if isempty(sousDossiers{k})
            continue
        end
        fichiers = [fichiers; dir(fullfile(sousDossiers{k}, '*.m'))];   %#ok<AGROW>
    end
    if isempty(fichiers)
        return
    end
    [~, ordre] = sort({fichiers.name});
    fichiers = fichiers(ordre);
end
