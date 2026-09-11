function valeurs = matlibre_parquet_decoder(octets, physique, nombre, classe)
%MATLIBRE_PARQUET_DECODER Décodage « PLAIN » d'une colonne.
%   VALEURS = MATLIBRE_PARQUET_DECODER(OCTETS,PHYSIQUE,NOMBRE) rend les
%   NOMBRE valeurs écrites bout à bout dans OCTETS. C'est l'inverse exact
%   de MATLIBRE_PARQUET_ENCODER.
%
%   MATLIBRE_PARQUET_DECODER(...,CLASSE) dit comment relire les entiers :
%   les mêmes 32 ou 64 bits valent un nombre signé ou non selon ce que le
%   type converti annonçait, et s'en remettre au type physique seul
%   ramènerait un grand uint32 à sa borne signée.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      o = matlibre_parquet_encoder([1 2 3], 5);
%      matlibre_parquet_decoder(o, 5, 3)          % [1; 2; 3]
%
%   Voir aussi PARQUETREAD, MATLIBRE_PARQUET_ENCODER.
    octets = uint8(octets(:))';
    switch physique
        case 5
            valeurs = double(typecast(octets(1:8*nombre), 'double'))';
        case 4
            valeurs = single(typecast(octets(1:4*nombre), 'single'))';
        case 2
            if nargin >= 4 && strcmp(classe, 'uint64')
                valeurs = typecast(octets(1:8*nombre), 'uint64')';
            else
                valeurs = typecast(octets(1:8*nombre), 'int64')';
            end
        case 1
            if nargin >= 4 && strcmp(classe, 'uint32')
                valeurs = typecast(octets(1:4*nombre), 'uint32')';
            else
                valeurs = typecast(octets(1:4*nombre), 'int32')';
            end
        case 0
            valeurs = false(nombre, 1);
            for k = 1:nombre
                indice = floor((k - 1) / 8) + 1;
                valeurs(k) = bitand(octets(indice), uint8(2 ^ mod(k - 1, 8))) ~= 0;
            end
        case 6
            valeurs = strings(nombre, 1);
            position = 1;
            for k = 1:nombre
                n = double(typecast(octets(position:position+3), 'uint32'));
                position = position + 4;
                if n == 0
                    valeurs(k) = "";
                else
                    valeurs(k) = string(native2unicode(octets(position:position+n-1), 'UTF-8'));
                    position = position + n;
                end
            end
        otherwise
            error('MATLAB:parquet:TypeNonSupporte', ...
                  'Décodage PLAIN inconnu pour le type physique %d.', physique);
    end
end
