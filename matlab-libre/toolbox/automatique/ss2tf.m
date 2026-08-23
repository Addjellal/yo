function [num, den] = ss2tf(A, B, C, D, iu)
%SS2TF Fonction de transfert d'un modèle d'état.
%   [NUM,DEN] = SS2TF(A,B,C,D) applique H(s) = C (sI - A)^-1 B + D par
%   l'algorithme de Leverrier-Faddeev : les matrices M_k de l'adjointe
%   se calculent par récurrence, en même temps que les coefficients du
%   dénominateur.
%
%   Avec den(s) = s^n + a1 s^(n-1) + ... + an, l'adjointe vaut
%   M_0 s^(n-1) + ... + M_(n-1) avec M_0 = I et M_k = A*M_(k-1) + a_k I.
%   Le numérateur est donc de degré n, et son terme de tête vaut D.
%
%   Exemple :
%      [n, d] = ss2tf(-1, 1, -1, 1);   % n = [1 0], d = [1 1] : s/(s+1)
%
%   SS2TF(A,B,C,D,IU) choisit l'entrée IU d'un modèle à plusieurs
%   entrées : seule la colonne IU de B et de D est retenue.
    if nargin >= 5 && ~isempty(iu)
        B = B(:, iu);
        if ~isempty(D), D = D(:, iu); end
    end
    n = size(A, 1);
    den = real(poly(eig(A)));
    if isempty(D), D = 0; end
    num = zeros(1, n + 1);
    num(1) = D * den(1);
    M = eye(n);
    for k = 1:n
        num(k + 1) = C * M * B + D * den(k + 1);
        M = A * M + den(k + 1) * eye(n);
    end
end
