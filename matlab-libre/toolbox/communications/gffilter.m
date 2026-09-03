function y = gffilter(b, a, x, p)
%GFFILTER Filtrage dans un corps de Galois.
%   Y = GFFILTER(B,A,X,P) filtre le signal X par le filtre de
%   coefficients B et A dans GF(P), P premier :
%
%      A(1) Y(n) = B(1)X(n) + ... + B(k)X(n-k+1)
%                  - A(2)Y(n-1) - ... - A(m)Y(n-m+1),
%
%   toutes les opérations se faisant modulo P. Les coefficients vont par
%   puissances croissantes, comme partout dans la famille GF.
%   Y = GFFILTER(B,A,X) travaille dans GF(2).
%
%   C'est le rouage des registres à décalage bouclés : un filtre à
%   réaction dans GF(2) engendre une suite pseudo-aléatoire, de période
%   maximale quand A est primitif.
%
%   Exemple :
%      % Registre de trois cellules, bouclé par 1+x+x^3 : la suite
%      % engendrée est de période sept.
%      y = gffilter(1, [1 1 0 1], [1 zeros(1, 13)]);
%      isequal(y(1:7), y(8:14))       % vrai
%
%   Voir aussi GFCONV, GFDECONV, GFPRIMDF, FILTER.
    if nargin < 4 || isempty(p), p = 2; end
    exigerPremier(p, 'gffilter');
    b = mod(double(b(:)).', p);
    a = mod(double(a(:)).', p);
    ligne = ~iscolumn(x);
    x = mod(double(x(:)).', p);
    if isempty(a) || a(1) == 0
        error('comm:gffilter:Pivot', ...
              'Le premier coefficient de A doit être non nul dans GF(%d).', p);
    end
    inverse = gfdiv(1, a(1), p);
    n = numel(x);
    y = zeros(1, n);
    for k = 1:n
        somme = 0;
        for j = 1:numel(b)
            if k - j + 1 >= 1
                somme = somme + b(j) * x(k - j + 1);
            end
        end
        for j = 2:numel(a)
            if k - j + 1 >= 1
                somme = somme - a(j) * y(k - j + 1);
            end
        end
        y(k) = mod(somme * inverse, p);
    end
    if ~ligne
        y = y(:);
    end
end
