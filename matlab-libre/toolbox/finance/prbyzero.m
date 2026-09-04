function prix = prbyzero(obligations, reglement, tauxZero, datesZero, composition)
%PRBYZERO Prix d'obligations calculés sur une courbe zéro-coupon.
%   P = PRBYZERO(OBLIGATIONS,REGLEMENT,TAUXZERO,DATESZERO) actualise
%   chaque flux au taux zéro-coupon de sa propre date, interpolé sur la
%   courbe. C'est l'inverse de ZBTPRICE.
%
%   Actualiser tous les flux au même taux — le rendement à l'échéance —
%   n'est qu'une commodité de cotation ; c'est la courbe qui dit ce que
%   vaut chaque flux.
%
%   Exemple :
%      obligations = [datenum('01-Feb-2026') 0.05];
%      prbyzero(obligations, '01-Feb-2024', [0.03; 0.035], ...
%               [datenum('01-Feb-2025'); datenum('01-Feb-2026')])
%
%   Voir aussi ZBTPRICE, ZBTYIELD, BNDPRICE, BNDSPREAD.
    if nargin < 5 || isempty(composition)
        composition = 2;
    end
    reglementNum = matlibre_dates(reglement);
    n = size(obligations, 1);
    prix = zeros(n, 1);
    for k = 1:n
        [montants, dates, courus] = matlibre_flux_obligation(obligations(k, :), reglementNum);
        facteurs = matlibre_interpoler_courbe(dates, tauxZero, datesZero, ...
                                              reglementNum, composition, 0);
        prix(k) = sum(montants(:) .* facteurs(:)) - courus;
    end
end
