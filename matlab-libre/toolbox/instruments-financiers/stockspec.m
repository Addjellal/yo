function specification = stockspec(volatilite, cours, typeDividende, montants, datesDetachement)
%STOCKSPEC Décrit un actif sous-jacent.
%   S = STOCKSPEC(VOLATILITE,COURS) décrit une action sans dividende.
%   STOCKSPEC(...,TYPE,MONTANTS,DATES) ajoute des dividendes : TYPE vaut
%   'continuous' pour un taux continu, 'cash' pour des montants versés à
%   des dates données, 'constant' pour un rendement discret.
%
%   Exemple :
%      s = stockspec(0.2, 100);
%      s = stockspec(0.2, 100, 'continuous', 0.03);
%
%   Voir aussi INTENVSET, OPTSTOCKBYBLS, CRRTREE.
    specification = struct('FinObj', 'StockSpec', ...
                           'Sigma', double(volatilite(:)), ...
                           'AssetPrice', double(cours(:)), ...
                           'DividendType', {{}}, ...
                           'DividendAmounts', [], ...
                           'ExDividendDates', []);
    if nargin >= 3 && ~isempty(typeDividende)
        if ischar(typeDividende) || isstring(typeDividende)
            specification.DividendType = {lower(char(typeDividende))};
        else
            specification.DividendType = lower(typeDividende);
        end
    end
    if nargin >= 4 && ~isempty(montants)
        specification.DividendAmounts = double(montants(:));
    end
    if nargin >= 5 && ~isempty(datesDetachement)
        specification.ExDividendDates = matlibre_dates(datesDetachement);
    end
end
