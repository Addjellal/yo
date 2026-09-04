function dates = time2date(reglement, temps, composition, base, regleFinMois)
%TIME2DATE Date située à une durée donnée, comptée en périodes.
%   D = TIME2DATE(REGLEMENT,TEMPS,COMPOSITION,BASE) est l'inverse de
%   DATE2TIME : la date dont la durée depuis le règlement vaut TEMPS.
%
%   L'inversion n'est pas immédiate : une convention comme 30/360 ne
%   compte pas les jours linéairement. La date est donc cherchée par
%   dichotomie sur le nombre de jours, puis arrondie au jour.
%
%   Exemple :
%      datestr(time2date('01-Jan-2024', 4, 2, 0))     % 01-Jan-2026
%
%   Voir aussi DATE2TIME, YEARFRAC.
    if nargin < 3 || isempty(composition),  composition = 2;  end
    if nargin < 4 || isempty(base),         base = 0;         end
    if nargin < 5 || isempty(regleFinMois), regleFinMois = 1; end   %#ok<NASGU>
    debut = matlibre_dates(reglement);
    temps = double(temps(:));
    if composition > 0
        annees = temps / composition;
    else
        annees = temps;
    end
    dates = zeros(size(annees));
    for k = 1:numel(annees)
        cible = annees(k);
        bas = debut;
        haut = debut + max(ceil(cible * 400), 1) + 400;
        for iteration = 1:80
            milieu = (bas + haut) / 2;
            if yearfrac(debut, milieu, base) < cible
                bas = milieu;
            else
                haut = milieu;
            end
        end
        dates(k) = round((bas + haut) / 2);
    end
end
