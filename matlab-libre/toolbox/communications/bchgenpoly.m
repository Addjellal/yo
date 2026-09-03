function [genpoly, t] = bchgenpoly(n, k, prim, sortie)
%BCHGENPOLY Polynôme générateur d'un code BCH.
%   GENPOLY = BCHGENPOLY(N,K) rend le polynôme générateur du code BCH de
%   longueur N et de dimension K, sous forme d'un tableau GF(2) dont les
%   coefficients vont par puissances décroissantes — la convention de
%   MATLAB pour cette fonction.
%
%   N doit valoir 2^M - 1 pour un M entre 3 et 16, et K être une
%   dimension admissible pour cette longueur.
%
%   GENPOLY = BCHGENPOLY(N,K,PRIM) emploie le polynôme primitif PRIM.
%   [GENPOLY,T] = BCHGENPOLY(...) rend en outre la capacité de
%   correction : le code corrige T erreurs.
%   BCHGENPOLY(...,'double') rend les coefficients en nombres ordinaires
%   plutôt qu'en tableau de corps.
%
%   Le générateur est le plus petit commun multiple des polynômes
%   minimaux de alpha, alpha^2, ..., alpha^(2T) : annuler ces racines
%   force la distance minimale à 2T+1.
%
%   Exemple :
%      [g, t] = bchgenpoly(15, 5);
%      t                              % 3 : le code corrige trois erreurs
%      numel(g.x) - 1                 % 10 = 15 - 5
%
%   Voir aussi BCHENC, BCHDEC, RSGENPOLY, GFPRIMDF, GFROOTS.
    if nargin < 3, prim = []; end
    if nargin < 4, sortie = 'gf'; end
    m = round(log2(n + 1));
    if 2 ^ m - 1 ~= n || m < 3 || m > 16
        error('comm:bchgenpoly:Longueur', ...
              'La longueur doit valoir 2^m - 1, avec m entre trois et seize.');
    end
    if isempty(prim)
        prim = matlibre_gf_primitif(m);
    else
        prim = round(double(prim));
    end
    [genpoly, t] = matlibre_bch_generateur(n, k, m, prim);
    if strcmpi(char(sortie), 'double')
        return
    end
    genpoly = gf(genpoly, 1);
end
