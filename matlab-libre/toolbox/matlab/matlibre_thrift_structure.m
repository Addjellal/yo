function octets = matlibre_thrift_structure(champs)
%MATLIBRE_THRIFT_STRUCTURE Écriture d'une structure en protocole compact.
%   OCTETS = MATLIBRE_THRIFT_STRUCTURE(CHAMPS) rend l'écriture d'une
%   structure. CHAMPS est une cellule de triplets {identifiant, type,
%   charge} donnés dans l'ordre croissant des identifiants : le protocole
%   ne code que l'écart au champ précédent, ce qui tient sur un demi-octet
%   tant que l'écart ne dépasse pas quinze.
%
%   La charge est déjà écrite : un entier y est un varint en zigzag, une
%   chaîne une longueur suivie de ses octets, une structure imbriquée ses
%   propres octets, terminaison comprise.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      o = matlibre_thrift_structure({{1, 5, matlibre_thrift_varint(2)}});
%      double(o)                       % [21 2 0] : champ 1, i32, valeur 1
%
%   Voir aussi PARQUETWRITE, MATLIBRE_THRIFT_VARINT.
    octets = uint8([]);
    precedent = 0;
    for k = 1:numel(champs)
        identifiant = champs{k}{1};
        type = champs{k}{2};
        charge = uint8(champs{k}{3});
        ecart = identifiant - precedent;
        if ecart >= 1 && ecart <= 15
            octets = [octets, uint8(ecart * 16 + type)];   %#ok<AGROW>
        else
            octets = [octets, uint8(type), ...
                      matlibre_thrift_varint(matlibre_thrift_zigzag(identifiant))];   %#ok<AGROW>
        end
        precedent = identifiant;
        octets = [octets, charge];   %#ok<AGROW>
    end
    octets = [octets, uint8(0)];
end
