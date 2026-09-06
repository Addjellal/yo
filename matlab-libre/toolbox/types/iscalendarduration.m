function r = iscalendarduration(x)
%ISCALENDARDURATION Vrai pour un tableau calendarDuration.
%   R = ISCALENDARDURATION(X) rend vrai si X est de classe calendarDuration, faux
%   sinon — y compris pour un tableau vide de cette classe.
%
%   Le test porte sur la classe, non sur le contenu : c'est le seul moyen
%   de distinguer un calendarDuration d'un tableau numérique qui en porterait les
%   valeurs. Les deux se ressemblent à l'affichage et se comportent tout
%   autrement.
%
%   Exemple :
%      iscalendarduration(calmonths(3))    % true
%      iscalendarduration(days(3))         % false : une duree exacte
%
%   Voir aussi ISDURATION, ISDATETIME, CALENDARDURATION.
    r = isa(x, 'calendarDuration');
end
