function c = addResistor(c, n1, n2, R)
%ADDRESISTOR Résistance de R ohms entre deux nœuds.
%   C = ADDRESISTOR(C,N1,N2,R) ajoute une résistance. Elle n'a pas de
%   sens : les deux nœuds jouent le même rôle.
%
%   En série les résistances s'ajoutent, en parallèle ce sont les
%   conductances : le solveur retrouve les deux règles sans qu'on ait à
%   les lui dire.
%
%   Exemple :
%      c = addResistor(c, 1, 2, 1000);
%
%   Voir aussi ADDCAPACITOR, ADDINDUCTOR, SOLVEDC.
    c = addComponent(c, 'r', n1, n2, R);
end
