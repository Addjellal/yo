function octets = matlibre_thrift_varint(n)
%MATLIBRE_THRIFT_VARINT Entier de longueur variable, sept bits à la fois.
%   OCTETS = MATLIBRE_THRIFT_VARINT(N) rend l'écriture de l'entier positif
%   N : sept bits de charge par octet, du poids faible au poids fort, le
%   bit de tête marquant qu'un octet suit.
%
%   C'est ce qui rend l'en-tête d'un fichier Parquet compact : les petits
%   nombres — et ils le sont presque tous — tiennent sur un octet.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      double(matlibre_thrift_varint(1))     % 1
%      double(matlibre_thrift_varint(300))   % [172 2]
%
%   Voir aussi PARQUETWRITE, PARQUETREAD, MATLIBRE_THRIFT_ZIGZAG.
    n = double(n);
    if n < 0 || n ~= floor(n)
        error('MATLAB:parquet:Varint', ...
              'Un varint code un entier positif ; %g n''en est pas un.', n);
    end
    octets = uint8([]);
    while true
        morceau = mod(n, 128);
        n = floor(n / 128);
        if n > 0
            octets(end+1) = uint8(morceau + 128);   %#ok<AGROW>
        else
            octets(end+1) = uint8(morceau);         %#ok<AGROW>
            break
        end
    end
    octets = uint8(octets);
end
