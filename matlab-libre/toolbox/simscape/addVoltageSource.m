function c = addVoltageSource(c, n1, n2, V)
%ADDVOLTAGESOURCE Source de tension idéale de V volts.
%   C = ADDVOLTAGESOURCE(C,N1,N2,V) impose V volts entre les deux nœuds,
%   N1 au potentiel le plus haut. La source est idéale : sa résistance
%   interne est nulle, et elle débite ce qu'il faut.
%
%   Une source de tension ajoute une inconnue au système — son courant —
%   et une équation : c'est ce que « modifiée » veut dire dans « analyse
%   nodale modifiée ». SOLVEDC rend ce courant en second résultat.
%
%   Le signe du courant rendu est celui qui entre par la borne moins :
%   il est donc négatif quand la source débite.
%
%   Exemple :
%      c = addVoltageSource(c, 1, 0, 10);
%      [v, i] = solveDC(c);
%      abs(i(1))                       % le courant debite
%
%   Voir aussi ADDCURRENTSOURCE, SOLVEDC, SOLVETRANSIENT.
    c = addComponent(c, 'v', n1, n2, V);
end
