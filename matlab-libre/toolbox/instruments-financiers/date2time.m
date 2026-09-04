function [temps, facteurs, composition] = date2time(reglement, echeance, composition, base, regleFinMois)
%DATE2TIME Durée entre deux dates, comptée en périodes.
%   [T,F] = DATE2TIME(REGLEMENT,ECHEANCE,COMPOSITION,BASE) rend la durée
%   en nombre de périodes de composition, et les facteurs
%   d'actualisation qu'un taux unitaire y produirait.
%
%   COMPOSITION vaut le nombre de capitalisations par an — 2 par défaut —,
%   -1 pour la composition continue, 0 pour un intérêt simple. BASE est
%   une convention de comptage, au sens de YEARFRAC.
%
%   Exemple :
%      date2time('01-Jan-2024', '01-Jan-2026', 2, 0)     % 4 semestres
%
%   Voir aussi TIME2DATE, YEARFRAC, INTENVSET.
    if nargin < 3 || isempty(composition),  composition = 2;  end
    if nargin < 4 || isempty(base),         base = 0;         end
    if nargin < 5 || isempty(regleFinMois), regleFinMois = 1; end   %#ok<NASGU>
    annees = yearfrac(reglement, echeance, base);
    if composition > 0
        temps = composition * annees;
    else
        temps = annees;
    end
    facteurs = matlibre_escompte(1, annees, composition);
end
