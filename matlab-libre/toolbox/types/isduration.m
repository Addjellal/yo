function r = isduration(x)
%ISDURATION Vrai pour un objet duration.
%   R = ISDURATION(X) rend vrai si X est de classe duration, faux
%   sinon — y compris pour un tableau vide de cette classe.
%
%   Le test porte sur la classe, non sur le contenu : c'est le seul moyen
%   de distinguer un duration d'un tableau numérique qui en porterait les
%   valeurs. Les deux se ressemblent à l'affichage et se comportent tout
%   autrement.
%
%   Exemple :
%      isduration(hours(3))                % true
%      isduration(calmonths(3))            % false : duree de calendrier
%
%   Voir aussi ISCALENDARDURATION, ISDATETIME, DURATION.
    r = isa(x, 'duration');
end
