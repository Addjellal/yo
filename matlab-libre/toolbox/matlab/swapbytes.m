function y = swapbytes(x)
%SWAPBYTES Inverse l'ordre des octets.
%   Y = SWAPBYTES(X) rend X avec, pour chaque élément, les octets pris à
%   l'envers : c'est le passage d'un boutisme à l'autre. X doit être d'un
%   type entier ou flottant de taille connue ; la classe est conservée.
%
%   Exemple :
%      swapbytes(uint16(1))    % 256
%
%   Voir aussi TYPECAST, CAST, CLASS.
    cl = class(x);
    switch cl
        case {'int8', 'uint8', 'logical', 'char'}
            y = x;
            return;
        case {'int16', 'uint16'}
            largeur = 2;
        case {'int32', 'uint32', 'single'}
            largeur = 4;
        case {'int64', 'uint64', 'double'}
            largeur = 8;
        otherwise
            error('swapbytes:Classe', ...
                  'swapbytes ne sait pas traiter la classe %s.', cl);
    end
    forme = size(x);
    octets = typecast(x(:), 'uint8');
    octets = reshape(octets, largeur, []);
    octets = octets(largeur:-1:1, :);
    y = typecast(octets(:), cl);
    y = reshape(y, forme);
end
