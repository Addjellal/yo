function [H, G, n, k] = hammgen(m)
%HAMMGEN Matrices d'un code de Hamming.
%   [H,G,N,K] = HAMMGEN(M) rend la matrice de contrôle H (M x N), la
%   matrice génératrice G (K x N), avec N = 2^M-1 et K = N-M.
%
%   Les colonnes de H sont toutes les combinaisons binaires non nulles :
%   c'est ce qui permet de localiser une erreur simple par son syndrome.
%
%   Exemple :
%      [H, G, n, k] = hammgen(3);   % n = 7, k = 4
    n = 2^m - 1;
    k = n - m;
    % Colonnes : d'abord les k colonnes non triviales, puis l'identité.
    colonnes = zeros(m, n);
    suivante = 1;
    identite = eye(m);
    poidsUn = false(1, n);
    for j = 1:n
        bits = de2bi(j, m);
        colonnes(:, j) = bits(:);
        poidsUn(j) = sum(bits) == 1;
    end
    ordre = [find(~poidsUn), find(poidsUn)];
    H = colonnes(:, ordre);
    P = H(:, 1:k);
    G = [eye(k), P'];
    H = [P, eye(m)];
    suivante = suivante;  %#ok<NASGU>
    identite = identite;  %#ok<NASGU>
end
