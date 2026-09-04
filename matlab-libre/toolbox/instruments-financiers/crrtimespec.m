function specification = crrtimespec(dateValorisation, echeance, nombrePeriodes)
%CRRTIMESPEC Découpage du temps d'un arbre binomial.
%   T = CRRTIMESPEC(VALORISATION,ECHEANCE,N) découpe l'intervalle en N
%   pas égaux et rend les dates et les durées de chaque niveau.
%
%   Exemple :
%      t = crrtimespec('01-Jan-2024', '01-Jan-2025', 50);
%
%   Voir aussi CRRTREE, CRRPRICE, STOCKSPEC, INTENVSET.
    dateValorisation = matlibre_dates(dateValorisation);
    echeance = matlibre_dates(echeance);
    nombrePeriodes = round(nombrePeriodes);
    duree = yearfrac(dateValorisation, echeance, 0);
    instants = (0:nombrePeriodes).' * duree / nombrePeriodes;
    dates = round(dateValorisation + instants * (echeance - dateValorisation) / duree);
    specification = struct('FinObj', 'BinTimeSpec', ...
                           'ValuationDate', dateValorisation, ...
                           'Maturity', echeance, ...
                           'NumPeriods', nombrePeriodes, ...
                           'Basis', 0, 'EndMonthRule', 1, ...
                           'tObs', instants.', 'dObs', dates.');
end
