function suivant = busdate(dates, sens, feries, weekend)
%BUSDATE Jour ouvré suivant ou précédent.
%   D = BUSDATE(DATE) rend le jour ouvré qui suit DATE. BUSDATE(DATE,-1)
%   rend celui qui précède ; BUSDATE(DATE,N) avance de N jours ouvrés, en
%   arrière si N est négatif.
%
%   BUSDATE(...,FERIES,WEEKEND) précise les jours chômés et la forme de
%   la semaine, comme ISBUSDAY.
%
%   Exemple :
%      datestr(busdate('03-Jul-2024'))    % 05-Jul-2024 : le 4 est ferie
%
%   Voir aussi ISBUSDAY, HOLIDAYS, LBUSDATE, FBUSDATE, DATEWRKDY.
    if nargin < 2 || isempty(sens)
        sens = 1;
    end
    numeros = floor(matlibre_dates(dates));
    if nargin < 3
        feries = holidays(min(numeros(:)) - 800, max(numeros(:)) + 800);
    end
    if nargin < 4
        weekend = [];
    end
    [numeros, sens] = matlibre_diffuser_dates(numeros, sens);
    suivant = zeros(size(numeros));
    for k = 1:numel(numeros)
        pas = sign(sens(k));
        if pas == 0
            pas = 1;
        end
        courant = numeros(k);
        restants = max(abs(round(sens(k))), 1);
        for compte = 1:restants
            courant = courant + pas;
            while ~isbusday(courant, feries, weekend)
                courant = courant + pas;
            end
        end
        suivant(k) = courant;
    end
end
