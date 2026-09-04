function [tauxZero, datesCourbe] = disc2zero(facteurs, datesCourbe, reglement, composition, base)
%DISC2ZERO Taux zéro-coupon déduits des facteurs d'actualisation.
%   [Z,D] = DISC2ZERO(FACTEURS,DATES,REGLEMENT) convertit chaque facteur
%   d'actualisation en le taux annuel qui le produirait. COMPOSITION vaut
%   2 par défaut ; -1 demande la composition continue.
%
%   Un facteur d'actualisation dit ce que vaut aujourd'hui un euro reçu
%   plus tard ; le taux zéro-coupon dit la même chose sous forme de taux.
%   Passer de l'un à l'autre ne fait que changer d'unité.
%
%   Exemple :
%      [z, d] = disc2zero([0.99 0.97 0.94], ...
%          {'01-Feb-2025','01-Feb-2026','01-Feb-2027'}, '01-Feb-2024')
%
%   Voir aussi ZERO2DISC, ZERO2FWD, ZERO2PYLD, ZBTPRICE.
    if nargin < 4 || isempty(composition), composition = 2; end
    if nargin < 5 || isempty(base),        base = 0;        end
    datesCourbe = matlibre_dates(datesCourbe);
    datesCourbe = datesCourbe(:);
    annees = zeros(size(datesCourbe));
    for k = 1:numel(datesCourbe)
        annees(k) = yearfrac(reglement, datesCourbe(k), base);
    end
    tauxZero = matlibre_escompte_vers_taux(facteurs, annees, composition);
end
