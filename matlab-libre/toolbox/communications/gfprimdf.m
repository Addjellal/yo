function polynome = gfprimdf(m, p)
%GFPRIMDF Polynôme primitif par défaut d'un corps de Galois.
%   POL = GFPRIMDF(M) rend le polynôme primitif de degré M que MatLibre
%   emploie par défaut pour GF(2^M) ; GFPRIMDF(M,P) le fait pour GF(P^M).
%   Les coefficients vont par puissances croissantes.
%
%   C'est le premier primitif dans l'ordre des codes croissants : 1+x
%   pour M = 1, puis 1+x+x^2, 1+x+x^3, 1+x+x^4, 1+x^2+x^5, 1+x+x^6,
%   1+x+x^7, 1+x^2+x^3+x^4+x^8.
%
%   MATLAB lit les siens dans une table, qui coïncide avec cette
%   recherche partout sauf au degré sept, où il retient 1+x^3+x^7 quand
%   celle-ci trouve d'abord 1+x+x^7 — les deux étant primitifs. Le choix
%   du polynôme change la représentation du corps : pour que deux calculs
%   se comparent, donnez-le explicitement plutôt que de vous fier au
%   défaut.
%
%   Exemple :
%      gfprimdf(3)                    % [1 1 0 1]
%      gfprimck(gfprimdf(8))          % 1
%
%   Voir aussi GFPRIMFD, GFPRIMCK, GFCOSETS.
    if nargin < 2 || isempty(p), p = 2; end
    polynome = gfprimfd(m, 'min', p);
end
