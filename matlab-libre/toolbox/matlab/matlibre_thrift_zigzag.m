function u = matlibre_thrift_zigzag(n)
%MATLIBRE_THRIFT_ZIGZAG Entier signé ramené aux entiers positifs.
%   U = MATLIBRE_THRIFT_ZIGZAG(N) rend 2*N pour N positif et -2*N-1 pour N
%   négatif : les petits nombres restent petits des deux côtés de zéro,
%   ce qu'un simple complément à deux ne donnerait pas — -1 y tiendrait
%   sur dix octets de varint.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_thrift_zigzag(0)       % 0
%      matlibre_thrift_zigzag(-1)      % 1
%      matlibre_thrift_zigzag(1)       % 2
%
%   Voir aussi MATLIBRE_THRIFT_VARINT, MATLIBRE_THRIFT_DEZIGZAG.
    n = double(n);
    if n >= 0
        u = 2 * n;
    else
        u = -2 * n - 1;
    end
end
