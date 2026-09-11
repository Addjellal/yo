function [valeur, position] = matlibre_thrift_lire(octets, position, type)
%MATLIBRE_THRIFT_LIRE Lecture d'une valeur en protocole compact.
%   [V,P] = MATLIBRE_THRIFT_LIRE(OCTETS,POSITION,TYPE) rend la valeur lue
%   et la position qui suit. Une structure devient une structure MATLAB
%   dont les champs se nomment c1, c2, ... d'après les identifiants du
%   protocole : le protocole ne transporte pas les noms, seulement les
%   numéros, et inventer des noms serait leur prêter un sens qu'ils
%   n'ont pas ici.
%
%   TYPE omis vaut 12, celui d'une structure.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      o = matlibre_thrift_structure({{1, 5, matlibre_thrift_varint(2)}});
%      s = matlibre_thrift_lire(o, 1);
%      s.c1                            % 1
%
%   Voir aussi PARQUETREAD, MATLIBRE_THRIFT_STRUCTURE.
    if nargin < 3
        type = 12;
    end
    switch type
        case 1
            valeur = true;
        case 2
            valeur = false;
        case 3
            brut = double(octets(position));
            position = position + 1;
            if brut > 127, brut = brut - 256; end
            valeur = brut;
        case {4, 5, 6}
            [u, position] = lireVarint(octets, position);
            valeur = matlibre_thrift_dezigzag(u);
        case 7
            valeur = typecast(uint8(octets(position:position+7)), 'double');
            position = position + 8;
        case 8
            [n, position] = lireVarint(octets, position);
            valeur = uint8(octets(position:position+n-1));
            position = position + n;
        case {9, 10}
            entete = double(octets(position));
            position = position + 1;
            typeElement = mod(entete, 16);
            n = floor(entete / 16);
            if n == 15
                [n, position] = lireVarint(octets, position);
            end
            valeur = cell(1, n);
            for k = 1:n
                if typeElement == 1 || typeElement == 2
                    % Dans une liste, un booléen occupe son propre octet.
                    valeur{k} = double(octets(position)) == 1;
                    position = position + 1;
                else
                    [valeur{k}, position] = matlibre_thrift_lire(octets, position, typeElement);
                end
            end
        case 12
            valeur = struct();
            precedent = 0;
            while true
                entete = double(octets(position));
                position = position + 1;
                if entete == 0
                    break
                end
                typeChamp = mod(entete, 16);
                ecart = floor(entete / 16);
                if ecart == 0
                    [u, position] = lireVarint(octets, position);
                    identifiant = matlibre_thrift_dezigzag(u);
                else
                    identifiant = precedent + ecart;
                end
                precedent = identifiant;
                [v, position] = matlibre_thrift_lire(octets, position, typeChamp);
                valeur.(sprintf('c%d', identifiant)) = v;
            end
        otherwise
            error('MATLAB:parquet:Thrift', ...
                  'Type de protocole compact inconnu : %d.', type);
    end
end

function [n, position] = lireVarint(octets, position)
    n = 0;
    facteur = 1;
    while true
        b = double(octets(position));
        position = position + 1;
        n = n + mod(b, 128) * facteur;
        if b < 128
            break
        end
        facteur = facteur * 128;
    end
end
