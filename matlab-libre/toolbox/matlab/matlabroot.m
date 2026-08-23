function r = matlabroot()
%MATLABROOT Racine de l'installation de MatLibre.
%   C'est le dossier qui contient les toolboxes.
    r = matlibre_racine();
    if isempty(r)
        r = getenv('MATLIBRE_TOOLBOX');
    end
    if isempty(r)
        r = pwd();
    end
end
