function niveaux = matlibre_parquet_niveaux(octets, largeur, nombre)
%MATLIBRE_PARQUET_NIVEAUX Décode les niveaux de définition d'une page.
%   NIVEAUX = MATLIBRE_PARQUET_NIVEAUX(OCTETS,LARGEUR,NOMBRE) décode le
%   codage hybride « série ou groupes tassés » que Parquet emploie pour
%   les niveaux. Un en-tête en varint dit lequel : pair, c'est une valeur
%   répétée ; impair, ce sont des groupes de huit valeurs tassées à
%   LARGEUR bits, bits de poids faible d'abord.
%
%   Ces niveaux disent, colonne par colonne, quelles lignes portent une
%   valeur. Sans eux, on ne saurait pas où sont les trous, et les valeurs
%   présentes se retrouveraient décalées.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      % une série de quatre fois la valeur 1 : en-tête 8 (4 << 1), puis 1
%      matlibre_parquet_niveaux(uint8([8 1]), 1, 4)'   % [1 1 1 1]
%
%   Voir aussi PARQUETREAD, MATLIBRE_PARQUET_DECODER.
    octets = double(octets(:))';
    niveaux = zeros(nombre, 1);
    ecrit = 0;
    position = 1;
    nbOctetsValeur = ceil(largeur / 8);
    while ecrit < nombre
        if position > numel(octets)
            error('MATLAB:parquet:NiveauxTronques', ...
                  'Les niveaux de définition s''interrompent avant la fin de la page.');
        end
        [entete, position] = lireVarint(octets, position);
        if mod(entete, 2) == 0
            compte = entete / 2;
            valeur = 0;
            for i = 1:nbOctetsValeur
                valeur = valeur + octets(position) * 256 ^ (i - 1);
                position = position + 1;
            end
            compte = min(compte, nombre - ecrit);
            niveaux(ecrit + 1 : ecrit + compte) = valeur;
            ecrit = ecrit + compte;
        else
            groupes = (entete - 1) / 2;
            for g = 1:groupes
                bits = octets(position : position + largeur - 1);
                position = position + largeur;
                for j = 0:7
                    if ecrit >= nombre
                        break
                    end
                    valeur = 0;
                    for b = 0:largeur - 1
                        total = j * largeur + b;
                        octet = bits(floor(total / 8) + 1);
                        valeur = valeur + mod(floor(octet / 2 ^ mod(total, 8)), 2) * 2 ^ b;
                    end
                    ecrit = ecrit + 1;
                    niveaux(ecrit) = valeur;
                end
            end
        end
    end
end

function [n, position] = lireVarint(octets, position)
    n = 0;
    facteur = 1;
    while true
        b = octets(position);
        position = position + 1;
        n = n + mod(b, 128) * facteur;
        if b < 128
            break
        end
        facteur = facteur * 128;
    end
end
