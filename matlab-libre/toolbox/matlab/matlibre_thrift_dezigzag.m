function n = matlibre_thrift_dezigzag(u)
%MATLIBRE_THRIFT_DEZIGZAG Retour du codage en zigzag.
%   N = MATLIBRE_THRIFT_DEZIGZAG(U) annule MATLIBRE_THRIFT_ZIGZAG.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_thrift_dezigzag(matlibre_thrift_zigzag(-7))   % -7
%
%   Voir aussi MATLIBRE_THRIFT_ZIGZAG, MATLIBRE_THRIFT_VARINT.
    u = double(u);
    if mod(u, 2) == 0
        n = u / 2;
    else
        n = -(u + 1) / 2;
    end
end
