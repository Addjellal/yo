function r = matlabroot()
%MATLABROOT Racine de l'installation de MatLibre.
%   C'est le dossier qui contient les toolboxes.
%
%   Exemple :
%      isfolder(matlabroot())      % 1 : la racine existe
%
%   Voir aussi PATH, WHICH, EXIST.
    r = matlibre_racine();
    if isempty(r)
        r = getenv('MATLIBRE_TOOLBOX');
    end
    if isempty(r)
        r = pwd();
    end
end
