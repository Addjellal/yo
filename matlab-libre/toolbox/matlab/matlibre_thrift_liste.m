function octets = matlibre_thrift_liste(typeElement, elements)
%MATLIBRE_THRIFT_LISTE Écriture d'une liste en protocole compact.
%   OCTETS = MATLIBRE_THRIFT_LISTE(TYPE,ELEMENTS) rend l'en-tête de liste
%   — le nombre d'éléments et leur type — suivi des éléments, déjà
%   écrits. Au-delà de quatorze éléments, le nombre passe en varint après
%   l'en-tête.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      double(matlibre_thrift_liste(5, {matlibre_thrift_varint(2)}))
%
%   Voir aussi MATLIBRE_THRIFT_STRUCTURE, PARQUETWRITE.
    n = numel(elements);
    if n < 15
        octets = uint8(n * 16 + typeElement);
    else
        octets = [uint8(15 * 16 + typeElement), matlibre_thrift_varint(n)];
    end
    for k = 1:n
        octets = [octets, uint8(elements{k})];   %#ok<AGROW>
    end
end
