function code = encode(message, n, k, methode, G)
%ENCODE Codage en blocs linéaires.
%   CODE = ENCODE(MSG,N,K,'linear/fmt',G) multiplie chaque bloc de K bits
%   par la matrice génératrice, modulo 2.
%   CODE = ENCODE(MSG,N,K,'hamming/fmt') utilise le code de Hamming.
%
%   Exemple :
%      c = encode([1 0 1 1], 7, 4, 'hamming/fmt');
    if nargin < 4 || isempty(methode), methode = 'hamming/fmt'; end
    if strncmpi(methode, 'hamming', 7)
        m = n - k;
        [~, G] = hammgen(m);
    end
    message = message(:)';
    blocs = reshape(message, k, [])';
    code = mod(blocs * G, 2);
    code = reshape(code', 1, []);
end
