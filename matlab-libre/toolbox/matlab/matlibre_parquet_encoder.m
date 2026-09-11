function octets = matlibre_parquet_encoder(colonne, physique)
%MATLIBRE_PARQUET_ENCODER Encodage « PLAIN » d'une colonne.
%   OCTETS = MATLIBRE_PARQUET_ENCODER(COLONNE,PHYSIQUE) rend les valeurs
%   écrites bout à bout, sans compression ni dictionnaire : c'est
%   l'encodage PLAIN, que toute implémentation de Parquet sait lire.
%
%   Les nombres partent en petit-boutien ; les booléens sont tassés à
%   raison de huit par octet, bit de poids faible d'abord ; une chaîne
%   est précédée de sa longueur sur quatre octets.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      numel(matlibre_parquet_encoder([1 2 3], 5))    % 24 : trois doubles
%
%   Voir aussi PARQUETWRITE, MATLIBRE_PARQUET_DECODER.
    switch physique
        case 5
            octets = typecast(double(colonne(:))', 'uint8');
        case 4
            octets = typecast(single(colonne(:))', 'uint8');
        case 2
            % Parquet range aussi les entiers non signés dans INT64 ; ce
            % sont les mêmes 64 bits, et c'est le type converti qui dit
            % comment les relire. Passer par int64 les saturerait.
            if isa(colonne, 'uint64')
                octets = typecast(uint64(colonne(:))', 'uint8');
            else
                octets = typecast(int64(colonne(:))', 'uint8');
            end
        case 1
            if isa(colonne, 'uint32')
                octets = typecast(uint32(colonne(:))', 'uint8');
            else
                octets = typecast(int32(colonne(:))', 'uint8');
            end
        case 0
            bits = logical(colonne(:))';
            n = numel(bits);
            nbOctets = ceil(n / 8);
            octets = zeros(1, nbOctets, 'uint8');
            for k = 1:n
                if bits(k)
                    indice = floor((k - 1) / 8) + 1;
                    octets(indice) = bitor(octets(indice), uint8(2 ^ mod(k - 1, 8)));
                end
            end
        case 6
            morceaux = {};
            textes = matlibre_parquet_textes(colonne);
            for k = 1:numel(textes)
                corps = uint8(unicode2native(textes{k}, 'UTF-8'));
                morceaux{end+1} = [typecast(uint32(numel(corps)), 'uint8'), corps];   %#ok<AGROW>
            end
            octets = uint8([morceaux{:}]);
        otherwise
            error('MATLAB:parquet:TypeNonSupporte', ...
                  'Encodage PLAIN inconnu pour le type physique %d.', physique);
    end
    octets = uint8(octets);
end
