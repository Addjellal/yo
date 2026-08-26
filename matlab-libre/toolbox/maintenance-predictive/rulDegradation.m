function rul = rulDegradation(indicateur, seuil)
%RULDEGRADATION Durée de vie restante par extrapolation linéaire.
%   RUL = RULDEGRADATION(INDICATEUR,SEUIL) rend le nombre de cycles avant
%   que la tendance n'atteigne le seuil.
    n = numel(indicateur);
    t = (1:n).';
    p = polyfit(t, indicateur(:), 1);
    if p(1) <= 0
        rul = inf;
        return;
    end
    tSeuil = (seuil - p(2)) / p(1);
    rul = max(0, tSeuil - n);
end
