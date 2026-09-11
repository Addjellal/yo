function [physique, converti, lecteur] = matlibre_parquet_types(classe)
%MATLIBRE_PARQUET_TYPES Correspondance entre classes MATLAB et types Parquet.
%   [P,C,L] = MATLIBRE_PARQUET_TYPES(CLASSE) rend le type physique
%   Parquet, le type converti qui le précise, et le nom de la classe à
%   restituer à la lecture.
%
%   Parquet n'a que quatre types numériques physiques : INT32, INT64,
%   FLOAT et DOUBLE. Les entiers plus étroits s'y rangent en INT32, et
%   c'est le type converti — INT_8, UINT_16, ... — qui garde la largeur
%   d'origine. Sans lui, un int8 reviendrait en int32 : le fichier serait
%   valide, l'aller-retour ne le serait pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [p, c] = matlibre_parquet_types('int8');
%      p == 1 && c == 15               % INT32, converti en INT_8
%
%   Voir aussi PARQUETWRITE, PARQUETREAD.
    converti = -1;
    lecteur = classe;
    switch classe
        case 'double',  physique = 5;
        case 'single',  physique = 4;
        case 'logical', physique = 0;
        case 'int64',   physique = 2; converti = 18;
        case 'uint64',  physique = 2; converti = 14;
        case 'int32',   physique = 1; converti = 17;
        case 'uint32',  physique = 1; converti = 13;
        case 'int16',   physique = 1; converti = 16;
        case 'uint16',  physique = 1; converti = 12;
        case 'int8',    physique = 1; converti = 15;
        case 'uint8',   physique = 1; converti = 11;
        case {'char', 'string', 'cell', 'categorical'}
            physique = 6; converti = 0; lecteur = 'string';
        otherwise
            error('MATLAB:parquet:TypeNonSupporte', ...
                  'Parquet ne sait pas porter une colonne de classe %s.', classe);
    end
end
