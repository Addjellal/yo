function [prix, flux, dates] = fixedbyzero(courbe, tauxCoupon, reglement, echeance, frequence, base, nominal, regleFinMois)
%FIXEDBYZERO Prix de la branche fixe d'un échange de taux.
%   P = FIXEDBYZERO(COURBE,TAUX,REGLEMENT,ECHEANCE,FREQUENCE) actualise
%   les intérêts d'une branche fixe. Le nominal n'est pas échangé : seuls
%   les intérêts comptent, ce qui distingue une branche d'échange d'une
%   obligation.
%
%   [P,FLUX,DATES] = FIXEDBYZERO(...) rend aussi les flux et leurs dates.
%
%   Exemple :
%      fixedbyzero(courbe, 0.04, '01-Jan-2024', '01-Jan-2029', 2)
%
%   Voir aussi FLOATBYZERO, SWAPBYZERO, BONDBYZERO.
    if nargin < 5 || isempty(frequence),    frequence = 1;    end
    if nargin < 6 || isempty(base),         base = courbe.Basis; end
    if nargin < 7 || isempty(nominal),      nominal = 100;    end
    if nargin < 8 || isempty(regleFinMois), regleFinMois = 1; end
    reglement = matlibre_dates(reglement);
    echeance = matlibre_dates(echeance);
    dates = matlibre_echeancier(reglement, echeance, frequence, regleFinMois).';
    precedent = reglement;
    flux = zeros(1, numel(dates));
    for k = 1:numel(dates)
        flux(k) = nominal * tauxCoupon * yearfrac(precedent, dates(k), base);
        precedent = dates(k);
    end
    facteurs = matlibre_courbe_escompte(courbe, dates);
    prix = sum(flux(:) .* facteurs(:));
end
