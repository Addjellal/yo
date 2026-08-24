function t = instants(x, Fs)
%INSTANTS Vecteur des instants d'échantillonnage, à la forme de X.
%   T = INSTANTS(X,FS) rend (0:n-1)'/FS répété autant de fois que X a de
%   colonnes. Les fonctions de modulation analogique s'en servent toutes.
    if isrow(x) && size(x, 1) == 1
        t = (0:numel(x) - 1) / Fs;
    else
        t = repmat((0:size(x, 1) - 1)' / Fs, 1, size(x, 2));
    end
end
