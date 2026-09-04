function ecart = bndspread(prix, tauxCoupon, reglement, echeance, tauxZero, datesZero, periode, base, regleFinMois, composition)
%BNDSPREAD Écart de taux d'une obligation par rapport à une courbe.
%   E = BNDSPREAD(PRIX,TAUX,REGLEMENT,ECHEANCE,TAUXZERO,DATESZERO) rend,
%   en points de base, l'écart constant qu'il faut ajouter à toute la
%   courbe zéro-coupon pour que le prix calculé soit le prix observé.
%
%   C'est la mesure du risque de crédit d'un émetteur : l'écart dit ce
%   que le marché exige au-delà du taux sans risque, à chaque échéance.
%
%   Exemple :
%      bndspread(97, 0.05, '01-Feb-2024', '01-Feb-2029', ...
%                [0.03; 0.035], [datenum('01-Feb-2026'); datenum('01-Feb-2029')])
%
%   Voir aussi PRBYZERO, ZBTPRICE, BNDYIELD, BNDPRICE.
    if nargin < 7  || isempty(periode),      periode = 2;      end
    if nargin < 8  || isempty(base),         base = 0;         end
    if nargin < 9  || isempty(regleFinMois), regleFinMois = 1; end
    if nargin < 10 || isempty(composition),  composition = 2;  end
    reglementNum = matlibre_dates(reglement);
    [montants, dates, courus] = matlibre_flux_obligation( ...
        [matlibre_dates(echeance), tauxCoupon, 100, periode, base, regleFinMois], ...
        reglementNum);
    brut = prix + courus;
    calculer = @(s) sum(montants(:) .* matlibre_interpoler_courbe(dates, ...
        double(tauxZero(:)) + s, datesZero, reglementNum, composition, base)) - brut;
    bas = -0.5;
    haut = 0.5;
    while calculer(haut) > 0 && haut < 50
        haut = haut * 2;
    end
    while calculer(bas) < 0 && bas > -0.99
        bas = bas - 0.1;
    end
    ecart = fzero(calculer, [bas, haut]) * 10000;
end
