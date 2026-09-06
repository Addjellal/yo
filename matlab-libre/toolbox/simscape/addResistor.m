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
%      c = circuit('diviseur');
%      c = addVoltageSource(c, 1, 0, 10);
%      c = addResistor(c, 1, 2, 1000);
%      c = addResistor(c, 2, 0, 2000);
%      v = solveDC(c);
%      abs(v(2) - 20 / 3) < 1e-9        % 1 : le pont diviseur
%
%   Voir aussi ADDCAPACITOR, ADDINDUCTOR, SOLVEDC.
    c = addComponent(c, 'r', n1, n2, R);
end
