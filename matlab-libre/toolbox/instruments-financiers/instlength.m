function nombre = instlength(jeu)
%INSTLENGTH Nombre d'instruments d'un jeu.
%   Exemple :
%      instlength(instadd('Bond', [0.05; 0.04], '01-Jan-2024', '01-Jan-2029'))
%
%   Voir aussi INSTADD, INSTTYPES, INSTDISP.
    nombre = jeu.Nombre;
end
