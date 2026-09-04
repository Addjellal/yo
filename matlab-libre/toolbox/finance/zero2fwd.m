function [tauxTerme, datesCourbe] = zero2fwd(tauxZero, datesCourbe, reglement, composition, base)
%ZERO2FWD Taux à terme implicites d'une courbe zéro-coupon.
%   [F,D] = ZERO2FWD(Z,DATES,REGLEMENT) rend, pour chaque intervalle de
%   la courbe, le taux qui s'applique de la date précédente à celle-ci.
%   Le premier taux à terme est le premier taux zéro-coupon.
%
%   Un taux à terme est ce que le marché fait payer aujourd'hui pour
%   emprunter plus tard : c'est le seul taux qui rende indifférent
%   d'emprunter longtemps ou d'emprunter court puis de renouveler.
%
%   Exemple :
%      [f, d] = zero2fwd([0.02 0.025 0.03], ...
%          {'01-Feb-2025','01-Feb-2026','01-Feb-2027'}, '01-Feb-2024')
%
%   Voir aussi FWD2ZERO, ZERO2DISC, DISC2ZERO, RATETIMES.
    if nargin < 4 || isempty(composition), composition = 2; end
    if nargin < 5 || isempty(base),        base = 0;        end
    datesCourbe = matlibre_dates(datesCourbe);
    datesCourbe = datesCourbe(:);
    reglementNum = matlibre_dates(reglement);
    annees = zeros(size(datesCourbe));
    for k = 1:numel(datesCourbe)
        annees(k) = yearfrac(reglementNum, datesCourbe(k), base);
    end
    facteurs = matlibre_taux_vers_escompte(tauxZero, annees, composition);
    precedents = [1; facteurs(1:end-1)];
    durees = [annees(1); diff(annees)];
    tauxTerme = matlibre_escompte_vers_taux(facteurs ./ precedents, durees, composition);
end
