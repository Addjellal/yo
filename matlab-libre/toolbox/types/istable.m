function r = istable(x)
%ISTABLE Vrai pour une table.
%   R = ISTABLE(X) rend vrai si X est de classe table, faux
%   sinon — y compris pour un tableau vide de cette classe.
%
%   Le test porte sur la classe, non sur le contenu : c'est le seul moyen
%   de distinguer un table d'un tableau numérique qui en porterait les
%   valeurs. Les deux se ressemblent à l'affichage et se comportent tout
%   autrement.
%
%   Exemple :
%      istable(table([1;2], [3;4]))        % true
%      istable(timetable(seconds(1:2).', [3;4]))   % false : une timetable
%
%   Voir aussi ISTIMETABLE, TABLE, ISCATEGORICAL.
    r = isa(x, 'table');
end
