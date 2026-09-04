function risque = portvrisk(rendementAttendu, ecartType, probabilite, valeur)
%PORTVRISK Valeur en risque d'un portefeuille, sous hypothèse gaussienne.
%   R = PORTVRISK(MOYENNE,ECART,PROBABILITE,VALEUR) rend la perte que le
%   portefeuille ne dépassera qu'avec la probabilité donnée.
%
%   PROBABILITE vaut 0,05 par défaut, VALEUR vaut 1 : le résultat est
%   alors une perte relative.
%
%   Le calcul suppose les rendements gaussiens, ce que les marchés
%   démentent régulièrement : les grandes pertes y sont plus fréquentes
%   que la loi normale ne le prévoit.
%
%   Exemple :
%      portvrisk(0.01, 0.05, 0.05, 100000)
%
%   Voir aussi VALUEATRISK, EXPECTEDSHORTFALL, PORTSTATS.
    if nargin < 3 || isempty(probabilite), probabilite = 0.05; end
    if nargin < 4 || isempty(valeur),      valeur = 1;         end
    quantile = norminv(probabilite);
    risque = max(-(rendementAttendu + quantile .* ecartType), 0) .* valeur;
end
