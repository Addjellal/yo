function [tauxZero, datesCourbe] = pyld2zero(tauxPair, datesCourbe, reglement, composition, base)
%PYLD2ZERO Courbe zéro-coupon reconstruite à partir des taux au pair.
%   C'est l'inverse de ZERO2PYLD, obtenu de proche en proche : le facteur
%   d'actualisation d'une échéance se déduit de ceux des échéances plus
%   courtes, déjà connus, et du taux au pair de l'échéance.
%
%   Exemple :
%      [z, d] = pyld2zero([0.02 0.025 0.03], ...
%          {'01-Aug-2024','01-Feb-2025','01-Aug-2025'}, '01-Feb-2024')
%
%   Voir aussi ZERO2PYLD, ZBTYIELD, DISC2ZERO.
    if nargin < 4 || isempty(composition), composition = 2; end
    if nargin < 5 || isempty(base),        base = 0;        end
    tauxPair = double(tauxPair(:));
    n = numel(tauxPair);
    facteurs = zeros(n, 1);
    cumul = 0;
    for k = 1:n
        coupon = tauxPair(k) / composition;
        facteurs(k) = (1 - coupon * cumul) / (1 + coupon);
        cumul = cumul + facteurs(k);
    end
    [tauxZero, datesCourbe] = disc2zero(facteurs, datesCourbe, reglement, composition, base);
end
