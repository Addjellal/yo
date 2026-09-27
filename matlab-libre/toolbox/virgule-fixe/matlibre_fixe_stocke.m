function q = matlibre_fixe_stocke(Q, T)
%MATLIBRE_FIXE_STOCKE Les entiers stockés, dans le plus petit entier de MATLAB.
%   Q = MATLIBRE_FIXE_STOCKE(Q,T) : int8 à int64 pour un type signé de 8 à
%   64 bits, uint8 à uint64 sinon ; au-delà de 64 bits, des doubles.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi STOREDINTEGER.
    tailles = [8 16 32 64];
    k = find(T.WordLength <= tailles, 1);
    if isempty(k)
        q = Q;
        return
    end
    prefixe = 'uint';
    if T.Signed
        prefixe = 'int';
    end
    q = cast(Q, sprintf('%s%d', prefixe, tailles(k)));
end
