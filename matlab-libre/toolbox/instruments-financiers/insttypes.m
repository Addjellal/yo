function types = insttypes(jeu)
%INSTTYPES Types d'instruments présents dans un jeu.
%   Exemple :
%      insttypes(instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029'))
%
%   Voir aussi INSTADD, INSTFIELDS, INSTLENGTH.
    types = jeu.Type(:);
end
