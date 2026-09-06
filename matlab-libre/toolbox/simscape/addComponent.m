function c = addComponent(c, type, n1, n2, valeur)
%ADDCOMPONENT Ajoute un composant entre deux nœuds.
%   C = ADDCOMPONENT(C,TYPE,N1,N2,VALEUR) est la forme générale dont
%   dérivent ADDRESISTOR, ADDCAPACITOR, ADDINDUCTOR, ADDVOLTAGESOURCE et
%   ADDCURRENTSOURCE. TYPE vaut 'r', 'c', 'l', 'v' ou 'i'.
%
%   Le circuit retient au passage le plus grand numéro de nœud employé :
%   c'est ainsi qu'il connaît sa taille, sans qu'on ait à la déclarer.
%
%   Exemple :
%      c = addComponent(c, 'r', 1, 2, 1000);   % equivaut a addResistor
%
%   Voir aussi ADDRESISTOR, ADDCAPACITOR, ADDINDUCTOR, CIRCUIT.
    comp = struct();
    comp.type = lower(char(type));
    comp.n1 = n1;
    comp.n2 = n2;
    comp.valeur = valeur;
    c.composants{end+1} = comp;
    c.noeuds = max([c.noeuds, n1, n2]);
end
