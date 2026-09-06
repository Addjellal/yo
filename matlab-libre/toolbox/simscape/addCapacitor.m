function c = addCapacitor(c, n1, n2, C)
%ADDCAPACITOR Condensateur de C farads.
%   C = ADDCAPACITOR(C,N1,N2,VALEUR) ajoute un condensateur.
%
%   En régime continu établi, un condensateur est un circuit ouvert :
%   SOLVEDC le traite comme tel, et la tension à ses bornes vaut celle que
%   le reste du circuit y impose. C'est en transitoire qu'il fait quelque
%   chose, et SOLVETRANSIENT le remplace alors à chaque pas par une
%   conductance en parallèle avec une source de courant.
%
%   Exemple :
%      c = addCapacitor(c, 2, 0, 1e-6);
%      [t, v] = solveTransient(c, 0.01, 1e-5);
%
%   Voir aussi ADDINDUCTOR, ADDRESISTOR, SOLVETRANSIENT.
    c = addComponent(c, 'c', n1, n2, C);
end
