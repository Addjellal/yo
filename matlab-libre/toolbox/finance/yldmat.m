function rendement = yldmat(reglement, echeance, emission, tauxCoupon, prix, base)
%YLDMAT Rendement d'un titre dont l'intérêt est versé à l'échéance.
%   R = YLDMAT(REGLEMENT,ECHEANCE,EMISSION,TAUX,PRIX) est l'inverse de
%   PRMAT : le rendement qui rend le prix observé.
%
%   Exemple :
%      yldmat('01-Feb-2024', '01-Aug-2024', '01-Jan-2024', 0.05, 99.2)
%
%   Voir aussi PRMAT, YLDDISC, BNDYIELD.
    if nargin < 6 || isempty(base)
        base = 0;
    end
    depuisEmission = yearfrac(emission, reglement, base);
    dureeTotale = yearfrac(emission, echeance, base);
    restant = yearfrac(reglement, echeance, base);
    interetsCourus = 100 .* tauxCoupon .* depuisEmission;
    valeurFinale = 100 .* (1 + tauxCoupon .* dureeTotale);
    rendement = (valeurFinale ./ (prix + interetsCourus) - 1) ./ restant;
end
