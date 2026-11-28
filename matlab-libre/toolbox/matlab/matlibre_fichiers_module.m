function fichiers = matlibre_fichiers_module(dossier)
%MATLIBRE_FICHIERS_MODULE Les fichiers .m d'un module de toolbox.
%   F = MATLIBRE_FICHIERS_MODULE(DOSSIER) rend, comme DIR, les fichiers .m
%   du module DOSSIER et ceux de son sous-dossier « homonymes », où vivent
%   les fonctions dont le nom ne diffère d'une autre que par la casse
%   (addmf à côté de addMF) : sous Windows et macOS, deux tels fichiers ne
%   peuvent pas partager un dossier. Le chargeur met les deux au chemin.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi DIR, WHAT.
    fichiers = dir(fullfile(dossier, '*.m'));
    homonymes = fullfile(dossier, 'homonymes');
    if isfolder(homonymes)
        fichiers = [fichiers; dir(fullfile(homonymes, '*.m'))];
        % dans l'ordre de DIR, comme si tout partageait un dossier
        [~, ordre] = sort({fichiers.name});
        fichiers = fichiers(ordre);
    end
end
