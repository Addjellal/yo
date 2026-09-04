function [facteurs, datesCourbe] = zero2disc(tauxZero, datesCourbe, reglement, composition, base)
%ZERO2DISC Facteurs d'actualisation déduits des taux zéro-coupon.
%   C'est l'inverse de DISC2ZERO.
%
%   Exemple :
%      [f, d] = zero2disc([0.02 0.025 0.03], ...
%          {'01-Feb-2025','01-Feb-2026','01-Feb-2027'}, '01-Feb-2024')
%
%   Voir aussi DISC2ZERO, ZERO2FWD, PRBYZERO.
    if nargin < 4 || isempty(composition), composition = 2; end
    if nargin < 5 || isempty(base),        base = 0;        end
    datesCourbe = matlibre_dates(datesCourbe);
    datesCourbe = datesCourbe(:);
    annees = zeros(size(datesCourbe));
    for k = 1:numel(datesCourbe)
        annees(k) = yearfrac(reglement, datesCourbe(k), base);
    end
    facteurs = matlibre_taux_vers_escompte(tauxZero, annees, composition);
end
