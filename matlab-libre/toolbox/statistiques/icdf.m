function x = icdf(nom, p, varargin)
%ICDF Quantile d'une loi nommée.
%   X = ICDF('name', P, A, B, C).
%
%   Exemple :  icdf('Normal', 0.975, 0, 1)   % 1.9600
    x = feval([statPrefixeLoi(nom) 'inv'], p, varargin{:});
end
