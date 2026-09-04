function [capital, interets, solde, versement] = amortize(taux, periodes, valeurActuelle, valeurFuture, terme)
%AMORTIZE Tableau d'amortissement d'un emprunt.
%   [C,I,S,V] = AMORTIZE(TAUX,N,PV) rend, période par période, la part de
%   capital remboursée, la part d'intérêt payée et le solde restant dû,
%   ainsi que le versement constant.
%
%   La somme des deux parts est le versement, à chaque période. La part
%   d'intérêt est le taux appliqué au solde de la période précédente :
%   elle décroît à mesure que le capital est remboursé, et la part de
%   capital croît d'autant.
%
%   Exemple :
%      [c, i, s, v] = amortize(0.06 / 12, 12, 10000);
%      sum(c)                       % 10000 : tout le capital
%
%   Voir aussi PAYPER, ANNURATE, ANNUTERM, PAYODD.
    if nargin < 4 || isempty(valeurFuture), valeurFuture = 0; end
    if nargin < 5 || isempty(terme),        terme = 0;        end
    periodes = round(periodes);
    versement = payper(taux, periodes, valeurActuelle, valeurFuture, terme);
    capital = zeros(1, periodes);
    interets = zeros(1, periodes);
    solde = zeros(1, periodes);
    reste = valeurActuelle;
    for k = 1:periodes
        if terme && k == 1
            interets(k) = 0;
        else
            interets(k) = reste * taux;
        end
        capital(k) = versement - interets(k);
        reste = reste - capital(k);
        solde(k) = reste;
    end
end
