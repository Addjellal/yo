function [tauxZero, datesCourbe] = zbtprice(obligations, prix, reglement, composition)
%ZBTPRICE Courbe zéro-coupon reconstruite à partir de prix d'obligations.
%   [Z,D] = ZBTPRICE(OBLIGATIONS,PRIX,REGLEMENT) rend les taux
%   zéro-coupon implicites. OBLIGATIONS est une matrice dont chaque ligne
%   vaut [echeance taux face periode base regleFinMois] ; seules les deux
%   premières colonnes sont obligatoires.
%
%   Le marché ne cote pas de zéro-coupon à toutes les échéances : il faut
%   les extraire des obligations à coupons, de proche en proche. Le prix
%   de l'obligation la plus courte donne le facteur d'actualisation de
%   son échéance ; celui de la suivante s'en sert pour ses coupons
%   intermédiaires et ne laisse qu'une inconnue, et ainsi de suite.
%
%   Exemple :
%      obligations = [datenum('01-Feb-2025') 0.04; datenum('01-Feb-2026') 0.05];
%      [z, d] = zbtprice(obligations, [99.5; 100.2], '01-Feb-2024')
%
%   Voir aussi ZBTYIELD, PRBYZERO, DISC2ZERO, BNDPRICE.
    if nargin < 4 || isempty(composition)
        composition = 2;
    end
    reglementNum = matlibre_dates(reglement);
    prix = double(prix(:));
    [~, ordre] = sort(obligations(:, 1));
    obligations = obligations(ordre, :);
    prix = prix(ordre);
    datesCourbe = zeros(size(prix));
    tauxZero = zeros(size(prix));
    for k = 1:numel(prix)
        [montants, dates, courus] = matlibre_flux_obligation(obligations(k, :), reglementNum);
        brut = prix(k) + courus;
        datesCourbe(k) = dates(end);
        % L'inconnue est le taux de l'échéance ; les flux intermédiaires
        % sont actualisés avec la même interpolation que PRBYZERO, de
        % sorte que les deux fonctions soient exactement inverses.
        ecart = @(z) sum(montants(:) .* matlibre_interpoler_courbe(dates, ...
            [reshape(tauxZero(1:(k - 1)), [], 1); z], datesCourbe(1:k), reglementNum, ...
            composition, 0)) - brut;
        bas = -0.5;
        haut = 0.5;
        while ecart(haut) > 0 && haut < 50
            haut = haut * 2;
        end
        tauxZero(k) = fzero(ecart, [bas, haut]);
    end
end
