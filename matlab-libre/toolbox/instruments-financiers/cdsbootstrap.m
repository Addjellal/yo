function [probabilites, hasards] = cdsbootstrap(donneesTaux, donneesMarche, reglement, recuperation, frequence, base)
%CDSBOOTSTRAP Probabilités de défaut déduites d'écarts de crédit cotés.
%   [PROB,HASARD] = CDSBOOTSTRAP(TAUX,MARCHE,REGLEMENT) rend, pour chaque
%   échéance cotée, la date et la probabilité de défaut cumulée, ainsi
%   que le taux de hasard de l'intervalle.
%
%   TAUX est une matrice [dates taux] décrivant la courbe sans risque ;
%   MARCHE une matrice [échéance écart], l'écart étant en points de base.
%
%   Le marché ne cote pas de probabilité de défaut : il cote le prix
%   d'une protection. Comme pour une courbe de taux, on remonte de proche
%   en proche : l'écart le plus court donne le taux de hasard de la
%   première période, celui d'après ne laisse qu'une inconnue, et ainsi
%   de suite.
%
%   RECUPERATION vaut 0,4 par défaut, FREQUENCE 4 et BASE 2.
%
%   Exemple :
%      taux = [datenum('01-Jan-2029') 0.03];
%      marche = [datenum('01-Jan-2029') 150];
%      [p, h] = cdsbootstrap(taux, marche, '01-Jan-2024')
%
%   Voir aussi CDSPRICE, CDSSPREAD, ZBTPRICE.
    if nargin < 4 || isempty(recuperation), recuperation = 0.4; end
    if nargin < 5 || isempty(frequence),    frequence = 4;      end
    if nargin < 6 || isempty(base),         base = 2;           end
    reglement = matlibre_dates(reglement);
    courbe = matlibre_cds_courbe(donneesTaux, reglement);
    donneesMarche = double(donneesMarche);
    [~, ordre] = sort(donneesMarche(:, 1));
    donneesMarche = donneesMarche(ordre, :);
    n = size(donneesMarche, 1);
    hasards = zeros(n, 2);
    probabilites = zeros(n, 2);
    datesHasard = donneesMarche(:, 1);
    valeurs = zeros(n, 1);
    for k = 1:n
        ecart = donneesMarche(k, 2) / 10000;
        cible = @(h) matlibre_cds_ecart(courbe, reglement, donneesMarche(k, 1), ...
            [reshape(valeurs(1:(k - 1)), [], 1); h], datesHasard(1:k), ...
            recuperation, frequence, base) - ecart;
        bas = 1e-8;
        haut = 1;
        while cible(haut) < 0 && haut < 100
            haut = haut * 2;
        end
        valeurs(k) = fzero(cible, [bas, haut]);
        hasards(k, :) = [donneesMarche(k, 1), valeurs(k)];
        survie = matlibre_cds_survie(reglement, donneesMarche(k, 1), ...
                                     valeurs(1:k), datesHasard(1:k));
        probabilites(k, :) = [donneesMarche(k, 1), 1 - survie];
    end
end
