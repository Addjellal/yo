function [num, den] = ss2tf(A, B, C, D, iu)
%SS2TF Modèle d'état vers fonction de transfert.
%   [NUM,DEN] = SS2TF(A,B,C,D) rend les coefficients de la transmittance
%   C(sI-A)^{-1}B + D, du degré le plus haut au plus bas. Le dénominateur
%   est le polynôme caractéristique de A.
%
%   [NUM,DEN] = SS2TF(A,B,C,D,IU) choisit l'entrée IU d'un modèle qui en
%   a plusieurs.
%
%   Exemples :
%      [num, den] = ss2tf(-1, 1, 1, 0);
%      num                                  % 0  1
%      den                                  % 1  1, soit 1/(s+1)
%      [n2, d2] = ss2tf([0 1; -2 -3], [0; 1], [1 0], 0);
%      max(abs(d2 - [1 3 2])) < 1e-12
%
%   Voir aussi TF2SS, SSDATA, TFDATA, TF, SS.
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
