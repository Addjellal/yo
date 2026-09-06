function c = addCurrentSource(c, n1, n2, I)
%ADDCURRENTSOURCE Source de courant idéale, de n1 vers n2.
%   C = ADDCURRENTSOURCE(C,N1,N2,I) fait circuler I ampères de N1 vers N2
%   à l'intérieur de la source, donc de N2 vers N1 dans le circuit
%   extérieur. Elle est idéale : sa résistance interne est infinie, et la
%   tension à ses bornes est celle que le circuit impose.
%
%   Une source de courant n'ajoute pas d'inconnue : elle entre directement
%   dans la loi des nœuds, contrairement à une source de tension.
%
%   Exemple :
%      c = addCurrentSource(c, 0, 1, 0.005);
%      c = addResistor(c, 1, 0, 1000);
%      solveDC(c)                      % 5 V : R I
%
%   Voir aussi ADDVOLTAGESOURCE, SOLVEDC.
    c = addComponent(c, 'i', n1, n2, I);
end
