function [donnees, noms, classes, indices] = instgetcell(jeu, varargin)
%INSTGETCELL Données d'un jeu d'instruments, rendues en cellules.
%   [D,N] = INSTGETCELL(JEU,'FieldList',F,'Type',T,'Index',I) rend, dans
%   D, une cellule par champ demandé, et leurs noms dans N.
%
%   Exemple :
%      jeu = instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029');
%      jeu = instadd(jeu, 'Bond', 0.06, '01-Jan-2024', '01-Jan-2034');
%      [d, n] = instgetcell(jeu, 'FieldList', {'CouponRate','Maturity'})
%
%   Voir aussi INSTGET, INSTFIELDS, INSTSELECT.
    [demandes, type, indices] = matlibre_jeu_options(jeu, varargin);
    if isempty(demandes)
        demandes = instfields(jeu, 'Type', type);
    end
    noms = demandes(:).';
    classes = cell(1, numel(noms));
    donnees = cell(1, numel(noms));
    for k = 1:numel(noms)
        [donnees{k}, classes{k}] = matlibre_jeu_colonne(jeu, noms{k}, indices);
    end
end
