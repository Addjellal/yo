function y = pdf(nom, x, varargin)
%PDF Densité ou probabilité d'une loi nommée.
%   Y = PDF('name', X, A, B, C) appelle la fonction de densité de la loi
%   nommée. Les noms suivent MATLAB : 'Normal', 'Poisson', 'Weibull',
%   'Chisquare', 'Discrete Uniform'…, avec leurs abréviations.
%
%   Y = PDF(GM,X) rend la densité d'un mélange gaussien ajusté par
%   FITGMDIST ou décrit par GMDISTRIBUTION.
%
%   Exemple :  pdf('Normal', 0, 0, 1)   % 0.3989
    if isstruct(nom) && isfield(nom, 'type') && strcmp(nom.type, 'melange-gaussien')
        [~, ~, y] = clusterMelange(nom, x);
        return
    end
    y = feval([statPrefixeLoi(nom) 'pdf'], x, varargin{:});
end
