function r = isdatetime(x)
%ISDATETIME Vrai pour un tableau datetime.
%   R = ISDATETIME(X) rend vrai si X est de classe datetime, faux
%   sinon — y compris pour un tableau vide de cette classe.
%
%   Le test porte sur la classe, non sur le contenu : c'est le seul moyen
%   de distinguer un datetime d'un tableau numérique qui en porterait les
%   valeurs. Les deux se ressemblent à l'affichage et se comportent tout
%   autrement.
%
%   Exemple :
%      isdatetime(datetime('now'))         % true
%      isdatetime(now)                     % false : un nombre
%
%   Voir aussi ISDURATION, ISNAT, DATETIME.
    r = isa(x, 'datetime');
end
