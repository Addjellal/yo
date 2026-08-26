function y = pdf(nom, x, varargin)
%PDF Densité ou probabilité d'une loi nommée.
%   Y = PDF('name', X, A, B, C) appelle la fonction de densité de la loi
%   nommée. Les noms suivent MATLAB : 'Normal', 'Poisson', 'Weibull',
%   'Chisquare', 'Discrete Uniform'…, avec leurs abréviations.
%
%   Exemple :  pdf('Normal', 0, 0, 1)   % 0.3989
    y = feval([statPrefixeLoi(nom) 'pdf'], x, varargin{:});
end
