function prix = matlibre_prix_instrument(courbe, type, v)
%MATLIBRE_PRIX_INSTRUMENT Valorise un instrument sur une courbe de taux.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    switch type
        case 'bond'
            prix = bondbyzero(courbe, v.CouponRate, v.Settle, v.Maturity, ...
                              defaut(v, 'Period', 2), defaut(v, 'Basis', courbe.Basis), ...
                              defaut(v, 'EndMonthRule', 1), [], [], [], [], ...
                              defaut(v, 'Face', 100));
        case 'cashflow'
            montants = v.CFlowAmounts;
            dates = v.CFlowDates;
            garde = ~isnan(montants) & ~isnan(dates);
            prix = cfbyzero(courbe, montants(garde), dates(garde), v.Settle, ...
                            defaut(v, 'Basis', courbe.Basis));
        case 'fixed'
            prix = fixedbyzero(courbe, v.CouponRate, v.Settle, v.Maturity, ...
                               defaut(v, 'Reset', 1), defaut(v, 'Basis', courbe.Basis), ...
                               defaut(v, 'Principal', 100), defaut(v, 'EndMonthRule', 1));
        case 'float'
            prix = floatbyzero(courbe, v.Spread, v.Settle, v.Maturity, ...
                               defaut(v, 'Reset', 1), defaut(v, 'Basis', courbe.Basis), ...
                               defaut(v, 'Principal', 100), defaut(v, 'EndMonthRule', 1));
        case 'swap'
            taux = v.LegRate;
            if numel(taux) == 1
                taux = [taux 0];
            end
            prix = swapbyzero(courbe, taux, v.Settle, v.Maturity, ...
                              defaut(v, 'LegReset', [1 1]), ...
                              defaut(v, 'Basis', courbe.Basis), ...
                              defaut(v, 'Principal', 100), defaut(v, 'EndMonthRule', 1));
        case 'cap'
            prix = NaN;
        case 'floor'
            prix = NaN;
        otherwise
            prix = NaN;
    end
end

function valeur = defaut(v, nom, parDefaut)
    valeur = parDefaut;
    if isfield(v, nom)
        brut = v.(nom);
        brut = brut(~isnan(brut));
        if ~isempty(brut)
            valeur = brut;
        end
    end
end
