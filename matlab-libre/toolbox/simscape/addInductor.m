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
%      c = addInductor(c, 2, 3, 1e-3);
%
%   Voir aussi ADDCAPACITOR, ADDRESISTOR, SOLVETRANSIENT.
    c = addComponent(c, 'l', n1, n2, L);
end
