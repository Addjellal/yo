function [jeuChoisi, indices] = instselect(jeu, varargin)
%INSTSELECT Sous-jeu d'instruments répondant à un critère.
%   [J,I] = INSTSELECT(JEU,'FieldName',N,'Data',D) garde les instruments
%   dont le champ N vaut D. INSTSELECT(JEU,'Type',T) garde ceux d'un
%   type ; INSTSELECT(JEU,'Index',I) ceux de numéros donnés.
%
%   Exemple :
%      jeu = instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029');
%      jeu = instadd(jeu, 'Bond', 0.06, '01-Jan-2024', '01-Jan-2034');
%      [court, rangs] = instselect(jeu, 'FieldName', 'CouponRate', 'Data', 0.05);
%
%   Voir aussi INSTGET, INSTDELETE, INSTFIELDS.
    [indices, garder] = matlibre_jeu_filtrer(jeu, varargin);
    jeuChoisi = matlibre_jeu_extraire(jeu, indices);
    if ~garder
        indices = indices(:);
    end
end
