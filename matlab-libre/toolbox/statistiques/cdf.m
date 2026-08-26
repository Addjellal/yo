function p = cdf(nom, x, varargin)
%CDF Fonction de répartition d'une loi nommée.
%   P = CDF('name', X, A, B, C).
%
%   Exemple :  cdf('Poisson', 2, 1)   % 0.9197
    p = feval([statPrefixeLoi(nom) 'cdf'], x, varargin{:});
end
