function [breaks, coefs, l, k, d] = unmkpp(pp)
%UNMKPP Les éléments d'un polynôme par morceaux.
%   [BREAKS,COEFS,L,K,D] = UNMKPP(PP) rend les points de rupture, les
%   coefficients, le nombre de morceaux, l'ordre et la dimension du
%   polynôme par morceaux PP, l'inverse de MKPP.
%
%   Exemple :
%      [b, c, l, k] = unmkpp(spline(0:3, [0 1 8 27]))   % 4 points, 3 morceaux d'ordre 4
%
%   Voir aussi MKPP, PPVAL, SPLINE.
    if ~isstruct(pp) || ~isfield(pp, 'form') || ~strcmp(pp.form, 'pp')
        error('MATLAB:unmkpp:NotPP', 'L''argument est un polynôme par morceaux, de MKPP.');
    end
    breaks = pp.breaks;
    coefs = pp.coefs;
    l = numel(breaks) - 1;
    k = size(coefs, 2);
    if isfield(pp, 'dim')
        d = pp.dim;
    else
        d = 1;
    end
end
