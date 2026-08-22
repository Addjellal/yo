function r = matlabroot()
%MATLABROOT Racine de l'installation de MatLibre.
    r = getenv('MATLIBRE_TOOLBOX');
    if isempty(r)
        r = pwd();
    end
end
