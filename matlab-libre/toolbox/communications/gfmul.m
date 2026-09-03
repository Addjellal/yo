function c = gfmul(a, b, p)
%GFMUL Produit terme à terme dans un corps de Galois.
%   C = GFMUL(A,B,P) multiplie élément par élément dans GF(P), P premier.
%   C = GFMUL(A,B) le fait dans GF(2), où c'est le et logique.
%
%   Ce n'est pas le produit de polynômes : celui-là est GFCONV.
%
%   Exemple :
%      gfmul([2 3 4], [3 3 3], 5)     % [1 4 2]
%      gfmul([1 0 1], [1 1 0])        % [1 0 0]
%
%   Voir aussi GFDIV, GFCONV, GFADD, GFDECONV.
    if nargin < 3 || isempty(p), p = 2; end
    exigerPremier(p, 'gfmul');
    [a, b] = alignerTermes(a, b);
    c = mod(a .* b, p);
end
