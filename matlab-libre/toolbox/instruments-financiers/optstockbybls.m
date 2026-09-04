function prix = optstockbybls(courbe, actif, reglement, echeance, typeOption, exercice)
%OPTSTOCKBYBLS Prix d'options européennes sur action.
%   P = OPTSTOCKBYBLS(COURBE,ACTIF,REGLEMENT,ECHEANCE,TYPE,EXERCICE) rend
%   le prix de Black et Scholes, le taux étant lu sur la courbe et le
%   dividende sur le descripteur d'actif. TYPE vaut 'call' ou 'put', et
%   peut être un tableau de cellules.
%
%   Exemple :
%      c = intenvset('Rates', 0.05, 'StartDates', '01-Jan-2024', ...
%                    'EndDates', '01-Jan-2025', 'Compounding', -1);
%      s = stockspec(0.2, 100);
%      optstockbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 95)
%
%   Voir aussi OPTSTOCKSENSBYBLS, BLSPRICE, STOCKSPEC, INTENVSET.
    [prix, ~] = matlibre_options_actions(courbe, actif, reglement, echeance, ...
                                         typeOption, exercice);
end
