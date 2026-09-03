function [genpoly, t] = rsgenpoly(n, k, prim, b, sortie)
%RSGENPOLY Polynôme générateur d'un code de Reed-Solomon.
%   GENPOLY = RSGENPOLY(N,K) rend le générateur du code RS(N,K), tableau
%   de corps GF(2^M) dont les coefficients vont par puissances
%   décroissantes. N doit valoir 2^M - 1.
%
%   GENPOLY = RSGENPOLY(N,K,PRIM) emploie le polynôme primitif PRIM,
%   RSGENPOLY(N,K,PRIM,B) part de alpha^B au lieu d'alpha.
%   [GENPOLY,T] = RSGENPOLY(...) rend la capacité de correction,
%   (N-K)/2 arrondi vers le bas.
%   RSGENPOLY(...,'double') rend des nombres ordinaires.
%
%   Le générateur est le produit des (x - alpha^(B+i)) pour i allant de
%   zéro à N-K-1. Un code de Reed-Solomon corrige des symboles entiers,
%   non des bits : c'est ce qui le rend bon contre les rafales.
%
%   Exemple :
%      [g, t] = rsgenpoly(15, 11);
%      t                              % 2
%      numel(g.x) - 1                 % 4 = 15 - 11
%
%   Voir aussi RSENC, RSDEC, BCHGENPOLY, GF.
    if nargin < 3, prim = []; end
    if nargin < 4 || isempty(b), b = 1; end
    if nargin < 5, sortie = 'gf'; end
    m = round(log2(n + 1));
    if 2 ^ m - 1 ~= n || m < 2 || m > 16
        error('comm:rsgenpoly:Longueur', ...
              'La longueur doit valoir 2^m - 1, avec m entre deux et seize.');
    end
    if k < 1 || k >= n
        error('comm:rsgenpoly:Dimension', ...
              'La dimension doit rester entre un et %d.', n - 1);
    end
    if mod(n - k, 2) ~= 0
        error('comm:rsgenpoly:Parite', ...
              'La redondance N-K doit être paire.');
    end
    if isempty(prim)
        prim = matlibre_gf_primitif(m);
    else
        prim = round(double(prim));
    end
    coefficients = matlibre_rs_generateur(n, k, m, prim, b);
    t = (n - k) / 2;
    if strcmpi(char(sortie), 'double')
        genpoly = coefficients;
        return
    end
    genpoly = gf(coefficients, m, prim);
end
