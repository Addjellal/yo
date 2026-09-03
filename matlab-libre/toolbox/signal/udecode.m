function y = udecode(u, n, v, saturation)
%UDECODE Reconstruit un signal à partir de ses codes entiers.
%   Y = UDECODE(U,N) est l'inverse d'UENCODE : il ramène les codes sur N
%   bits dans l'intervalle [-1, 1[.
%   Y = UDECODE(U,N,V) ramène dans [-V, V[.
%   Y = UDECODE(U,N,V,'wrap') fait boucler les codes hors bornes au lieu
%   de les saturer.
%
%   Exemple :
%      codes = uencode(-1:0.5:1, 3);
%      udecode(codes, 3)
%
%   Voir aussi UENCODE, QUANTIZ, CAST.
    if nargin < 3 || isempty(v), v = 1; end
    if nargin < 4, saturation = 'saturate'; end
    n = round(n);
    if n < 2 || n > 32
        error('signal:udecode:BitCount', 'N doit être entre 2 et 32.');
    end
    niveaux = 2 ^ n;
    codes = double(u);
    if isinteger(u) && ~contains(lower(class(u)), 'uint')
        codes = codes + niveaux / 2;
    end
    if strncmpi(char(saturation), 'w', 1)
        codes = mod(codes, niveaux);
    else
        codes = min(max(codes, 0), niveaux - 1);
    end
    pas = 2 * v / niveaux;
    y = codes * pas - v;
end
