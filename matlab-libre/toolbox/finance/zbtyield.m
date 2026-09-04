function [tauxZero, datesCourbe] = zbtyield(obligations, rendements, reglement, composition)
%ZBTYIELD Courbe zéro-coupon reconstruite à partir de rendements.
%   Même chose que ZBTPRICE, les obligations étant données par leur
%   rendement à l'échéance plutôt que par leur prix.
%
%   Exemple :
%      obligations = [datenum('01-Feb-2025') 0.04; datenum('01-Feb-2026') 0.05];
%      [z, d] = zbtyield(obligations, [0.042; 0.048], '01-Feb-2024')
%
%   Voir aussi ZBTPRICE, PRBYZERO, BNDPRICE.
    if nargin < 4 || isempty(composition)
        composition = 2;
    end
    reglementNum = matlibre_dates(reglement);
    rendements = double(rendements(:));
    prix = zeros(size(rendements));
    for k = 1:numel(rendements)
        ligne = obligations(k, :);
        tauxCoupon = 0;
        if numel(ligne) >= 2, tauxCoupon = ligne(2); end
        valeurFaciale = 100;
        if numel(ligne) >= 3 && ~isnan(ligne(3)), valeurFaciale = ligne(3); end
        periode = 2;
        if numel(ligne) >= 4 && ~isnan(ligne(4)), periode = ligne(4); end
        base = 0;
        if numel(ligne) >= 5 && ~isnan(ligne(5)), base = ligne(5); end
        regleFinMois = 1;
        if numel(ligne) >= 6 && ~isnan(ligne(6)), regleFinMois = ligne(6); end
        prix(k) = bndprice(rendements(k), tauxCoupon, reglementNum, ligne(1), ...
                           periode, base, regleFinMois, [], [], [], [], valeurFaciale);
    end
    [tauxZero, datesCourbe] = zbtprice(obligations, prix, reglementNum, composition);
end
