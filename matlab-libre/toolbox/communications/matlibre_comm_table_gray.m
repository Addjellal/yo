function table = matlibre_comm_table_gray(M)
%MATLIBRE_COMM_TABLE_GRAY Codes de Gray des entiers de 0 à M-1.
%   T = MATLIBRE_COMM_TABLE_GRAY(M) rend T(k+1) = k XOR (k >> 1), le code
%   de Gray de k. Deux entiers consécutifs ont des codes qui ne diffèrent
%   que d'un bit.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi MATLIBRE_COMM_POSITION, MATLIBRE_COMM_SYMBOLE.
    k = 0:(M - 1);
    table = bitxor(k, bitshift(k, -1));
end
