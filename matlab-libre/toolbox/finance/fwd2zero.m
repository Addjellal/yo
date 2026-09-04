function [tauxZero, datesCourbe] = fwd2zero(tauxTerme, datesCourbe, reglement, composition, base)
%FWD2ZERO Courbe zéro-coupon reconstruite à partir des taux à terme.
%   C'est l'inverse de ZERO2FWD : les facteurs d'actualisation de chaque
%   intervalle se multiplient, et le taux zéro-coupon se lit sur leur
%   produit.
%
%   Exemple :
%      [z, d] = fwd2zero([0.02 0.03 0.04], ...
%          {'01-Feb-2025','01-Feb-2026','01-Feb-2027'}, '01-Feb-2024')
%
%   Voir aussi ZERO2FWD, ZERO2DISC, RATETIMES.
    if nargin < 4 || isempty(composition), composition = 2; end
    if nargin < 5 || isempty(base),        base = 0;        end
    datesCourbe = matlibre_dates(datesCourbe);
    datesCourbe = datesCourbe(:);
    reglementNum = matlibre_dates(reglement);
    annees = zeros(size(datesCourbe));
    for k = 1:numel(datesCourbe)
        annees(k) = yearfrac(reglementNum, datesCourbe(k), base);
    end
    durees = [annees(1); diff(annees)];
    partiels = matlibre_taux_vers_escompte(tauxTerme, durees, composition);
    facteurs = cumprod(partiels);
    tauxZero = matlibre_escompte_vers_taux(facteurs, annees, composition);
end
