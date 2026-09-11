function classe = matlibre_parquet_classe(physique, converti)
%MATLIBRE_PARQUET_CLASSE Classe MATLAB d'une colonne Parquet.
%   CLASSE = MATLIBRE_PARQUET_CLASSE(PHYSIQUE,CONVERTI) rend le nom de la
%   classe à restituer. Le type converti l'emporte quand il est présent :
%   c'est lui qui distingue un int8 d'un int32, que Parquet range tous
%   deux en INT32.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_parquet_classe(1, 15)  % 'int8'
%      matlibre_parquet_classe(5, -1)  % 'double'
%
%   Voir aussi PARQUETREAD, MATLIBRE_PARQUET_TYPES.
    if nargin < 2 || isempty(converti)
        converti = -1;
    end
    switch converti
        case 0,  classe = 'string';  return
        case 11, classe = 'uint8';   return
        case 12, classe = 'uint16';  return
        case 13, classe = 'uint32';  return
        case 14, classe = 'uint64';  return
        case 15, classe = 'int8';    return
        case 16, classe = 'int16';   return
        case 17, classe = 'int32';   return
        case 18, classe = 'int64';   return
    end
    switch physique
        case 0, classe = 'logical';
        case 1, classe = 'int32';
        case 2, classe = 'int64';
        case 4, classe = 'single';
        case 5, classe = 'double';
        case 6, classe = 'string';
        otherwise
            error('MATLAB:parquet:TypeNonSupporte', ...
                  'Type physique Parquet non pris en charge : %d.', physique);
    end
end
