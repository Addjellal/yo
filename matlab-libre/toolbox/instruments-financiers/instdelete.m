function jeu = instdelete(jeu, varargin)
%INSTDELETE Retire des instruments d'un jeu.
%   J = INSTDELETE(JEU,'Index',I) retire les instruments de numéros
%   donnés ; 'Type' retire tout un type ; 'FieldName' et 'Data' retirent
%   ceux qui répondent au critère.
%
%   Exemple :
%      jeu = instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029');
%      jeu = instadd(jeu, 'Bond', 0.06, '01-Jan-2024', '01-Jan-2034');
%      jeu = instdelete(jeu, 'Index', 2);
%
%   Voir aussi INSTADD, INSTSELECT.
    aRetirer = matlibre_jeu_filtrer(jeu, varargin);
    garde = setdiff((1:jeu.Nombre).', aRetirer(:));
    jeu = matlibre_jeu_extraire(jeu, garde);
end
