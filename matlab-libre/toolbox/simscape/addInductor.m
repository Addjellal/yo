function c = addInductor(c, n1, n2, L)
%ADDINDUCTOR Bobine de L henrys.
%   C = ADDINDUCTOR(C,N1,N2,VALEUR) ajoute une bobine.
%
%   En régime continu établi, une bobine est un court-circuit : SOLVEDC
%   la traite comme tel, et le courant qui la traverse est celui que le
%   reste du circuit impose. C'est le dual du condensateur, et les deux
%   ensemble donnent le second ordre — donc les oscillations.
%
%   Exemple :
%      c = circuit('RL');
%      c = addVoltageSource(c, 1, 0, 5);
%      c = addInductor(c, 1, 2, 1e-3);
%      c = addResistor(c, 2, 0, 100);
%      [t, v] = solveTransient(c, 1e-4, 1e-7);
%
%   Voir aussi ADDCAPACITOR, ADDRESISTOR, SOLVETRANSIENT.
    c = addComponent(c, 'l', n1, n2, L);
end
