function rendement = cfyield(flux, dates, prix, reglement, base, composition)
%CFYIELD Rendement d'une série de flux, à partir de son prix.
%   R = CFYIELD(FLUX,DATES,PRIX,REGLEMENT) rend le taux qui redonne le
%   prix observé : c'est l'inverse de CFPRICE.
%
%   Exemple :
%      d = {'01-Feb-2025','01-Feb-2026','01-Feb-2027'};
%      p = cfprice([5 5 105], d, '01-Feb-2024', 0.06);
%      cfyield([5 5 105], d, p, '01-Feb-2024')      % 0.06
%
%   Voir aussi CFPRICE, BNDYIELD, IRR.
    if nargin < 5 || isempty(base),        base = 0;        end
    if nargin < 6 || isempty(composition), composition = 2; end
    ecart = @(y) cfprice(flux, dates, reglement, y, base, composition) - prix;
    haut = 1;
    while ecart(haut) > 0 && haut < 1e4
        haut = haut * 2;
    end
    rendement = fzero(ecart, [-0.99, haut]);
end
