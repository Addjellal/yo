function [prix, interetsCourus] = prmat(reglement, echeance, emission, tauxCoupon, rendement, base)
%PRMAT Prix d'un titre dont l'intérêt est versé à l'échéance.
%   [P,I] = PRMAT(REGLEMENT,ECHEANCE,EMISSION,TAUX,RENDEMENT) rend le
%   prix pour cent de nominal et les intérêts courus. Le titre ne verse
%   rien avant l'échéance : capital et intérêt arrivent ensemble.
%
%   Exemple :
%      [p, i] = prmat('01-Feb-2024', '01-Aug-2024', '01-Jan-2024', 0.05, 0.06)
%
%   Voir aussi YLDMAT, PRDISC, BNDPRICE, ACRUBOND.
    if nargin < 6 || isempty(base)
        base = 0;
    end
    depuisEmission = yearfrac(emission, reglement, base);
    dureeTotale = yearfrac(emission, echeance, base);
    restant = yearfrac(reglement, echeance, base);
    interetsCourus = 100 .* tauxCoupon .* depuisEmission;
    valeurFinale = 100 .* (1 + tauxCoupon .* dureeTotale);
    prix = valeurFinale ./ (1 + rendement .* restant) - interetsCourus;
end
