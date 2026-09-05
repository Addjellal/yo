function code = encode(message, n, k, methode, G)
%ENCODE Codage en blocs linéaires.
%   CODE = ENCODE(MSG,N,K,'linear/fmt',G) multiplie chaque bloc de K bits
%   par la matrice génératrice, modulo 2.
%   CODE = ENCODE(MSG,N,K,'hamming/fmt') utilise le code de Hamming.
%
%   La forme de la sortie suit celle de l'entrée, comme dans MATLAB : une
%   matrice de K colonnes — un mot par ligne — rend une matrice de N
%   colonnes ; un vecteur rend un vecteur de même orientation.
%
%   Exemple :
%      c = encode([1 0 1 1], 7, 4, 'hamming/fmt');
%      C = encode([1 0 1 1; 0 1 1 0], 7, 4, 'hamming/binary');   % 2 x 7
%
%   Voir aussi DECODE, HAMMGEN, GEN2PAR.
    if nargin < 4 || isempty(methode), methode = 'hamming/fmt'; end
    if strncmpi(methode, 'hamming', 7)
        m = n - k;
        [~, G] = hammgen(m);
    end
    enMatrice = ~isvector(message) && size(message, 2) == k;
    if enMatrice
        blocs = message;
    else
        colonne = iscolumn(message) && numel(message) > 1;
        blocs = reshape(message(:)', k, [])';
    end
    code = mod(blocs * G, 2);
    if enMatrice
        return
    end
    code = reshape(code', 1, []);
    if colonne
        code = code';
    end
end
