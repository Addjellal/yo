function [prix, primeCourue] = cdsprice(donneesTaux, probabilites, reglement, echeance, ecartContrat, recuperation, frequence, base, nominal)
%CDSPRICE Prix d'un contrat de protection contre le défaut.
%   [P,C] = CDSPRICE(TAUX,PROBABILITES,REGLEMENT,ECHEANCE,ECARTCONTRAT)
%   rend la valeur du contrat pour l'acheteur de protection, et la prime
%   courue depuis la dernière échéance. ECARTCONTRAT est en points de
%   base.
%
%   Un contrat conclu à un écart inférieur à celui du marché vaut
%   quelque chose : l'acheteur paie moins que ce que la protection vaut
%   aujourd'hui. Le prix est cet écart, multiplié par la valeur actuelle
%   d'une prime unitaire.
%
%   Exemple :
%      cdsprice(taux, probabilites, '01-Jan-2024', '01-Jan-2029', 100)
%
%   Voir aussi CDSSPREAD, CDSBOOTSTRAP.
    if nargin < 6 || isempty(recuperation), recuperation = 0.4; end
    if nargin < 7 || isempty(frequence),    frequence = 4;      end
    if nargin < 8 || isempty(base),         base = 2;           end
    if nargin < 9 || isempty(nominal),      nominal = 10000000; end
    reglement = matlibre_dates(reglement);
    courbe = matlibre_cds_courbe(donneesTaux, reglement);
    [hasard, datesHasard] = matlibre_cds_hasard(probabilites, reglement);
    echeance = matlibre_dates(echeance);
    echeance = echeance(:);
    ecartContrat = double(ecartContrat(:));
    prix = zeros(numel(echeance), 1);
    primeCourue = zeros(numel(echeance), 1);
    for k = 1:numel(echeance)
        [annuite, protection] = matlibre_cds_branches(courbe, reglement, echeance(k), ...
            hasard, datesHasard, recuperation, frequence, base);
        contrat = ecartContrat(min(k, numel(ecartContrat))) / 10000;
        prix(k) = nominal * (protection - contrat * annuite);
        primeCourue(k) = 0;
    end
end
