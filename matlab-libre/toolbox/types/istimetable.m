function r = istimetable(x)
%ISTIMETABLE Vrai pour une timetable.
%   R = ISTIMETABLE(X) rend vrai si X est de classe timetable, faux
%   sinon — y compris pour un tableau vide de cette classe.
%
%   Le test porte sur la classe, non sur le contenu : c'est le seul moyen
%   de distinguer un timetable d'un tableau numérique qui en porterait les
%   valeurs. Les deux se ressemblent à l'affichage et se comportent tout
%   autrement.
%
%   Exemple :
%      istimetable(timetable(seconds(1:2).', [3;4]))   % true
%      istimetable(table([1;2]))                       % false
%
%   Voir aussi ISTABLE, TIMETABLE.
    r = isa(x, 'timetable');
end
