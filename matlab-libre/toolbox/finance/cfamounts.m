function [montants, dates, facteurs, drapeaux] = cfamounts(tauxCoupon, reglement, echeance, periode, base, regleFinMois, emission, premierCoupon, dernierCoupon, debut, valeurFaciale)
%CFAMOUNTS Échéancier complet d'une obligation.
%   [M,D,T,F] = CFAMOUNTS(TAUX,REGLEMENT,ECHEANCE) rend les montants, les
%   dates, les facteurs de temps en nombre de périodes depuis le
%   règlement, et un drapeau par flux.
%
%   Le premier élément est l'intérêt couru, compté négativement : c'est
%   ce que l'acheteur verse au vendeur en plus du prix coté. Les suivants
%   sont les coupons, et le dernier ajoute le remboursement du nominal.
%
%   Les drapeaux valent 0 pour l'intérêt couru, 1 pour un coupon
%   ordinaire, 3 pour le dernier flux.
%
%   Exemple :
%      [m, d] = cfamounts(0.05, '01-Feb-2024', '01-Feb-2027');
%      [m.' datestr(d.')]
%
%   Voir aussi CFDATES, BNDPRICE, BNDYIELD, ACRUBOND, CFPRICE.
    if nargin < 4  || isempty(periode),      periode = 2;      end
    if nargin < 5  || isempty(base),         base = 0;         end
    if nargin < 6  || isempty(regleFinMois), regleFinMois = 1; end
    if nargin < 11 || isempty(valeurFaciale), valeurFaciale = 100; end
    reglement = matlibre_dates(reglement);
    echeance = matlibre_dates(echeance);
    [datesCoupon, precedent] = matlibre_echeancier(reglement, echeance, periode, regleFinMois);
    if nargin >= 7 && ~isempty(emission)
        emission = matlibre_dates(emission);
        precedent = max(precedent, emission);
    end
    if nargin >= 8 && ~isempty(premierCoupon)
        premierCoupon = matlibre_dates(premierCoupon);
        datesCoupon = unique([premierCoupon; datesCoupon(datesCoupon > premierCoupon)]);
    end
    if nargin >= 9 && ~isempty(dernierCoupon)
        dernierCoupon = matlibre_dates(dernierCoupon);
        datesCoupon = unique([datesCoupon(datesCoupon < dernierCoupon); ...
                              dernierCoupon; echeance]);
    end
    if nargin >= 10 && ~isempty(debut)
        precedent = max(precedent, matlibre_dates(debut));
    end
    n = numel(datesCoupon);
    coupon = valeurFaciale * tauxCoupon / periode;
    montants = coupon * ones(1, n);
    montants(end) = montants(end) + valeurFaciale;
    if periode <= 0
        montants = valeurFaciale;
    end
    % Part de la période en cours déjà écoulée : c'est elle qui donne
    % l'intérêt couru, et son complément le premier facteur de temps.
    suivant = datesCoupon(1);
    complet = yearfrac(precedent, suivant, base);
    if complet > 0
        ecoule = yearfrac(precedent, reglement, base) / complet;
    else
        ecoule = 0;
    end
    couru = coupon * ecoule;
    facteurs = (1 - ecoule) + (0:(n - 1));
    montants = [-couru, montants];
    dates = [reglement; datesCoupon].';
    facteurs = [0, facteurs];
    drapeaux = [0, ones(1, n - 1), 3];
    if n == 1
        drapeaux = [0, 3];
    end
end
