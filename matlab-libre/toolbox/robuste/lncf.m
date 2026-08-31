function [M, N] = lncf(sys)
%LNCF Facteurs premiers normalisés à gauche.
%   [M,N] = LNCF(SYS) factorise SYS en M^-1 N, où M et N sont stables et
%   où [M N] est intérieure :
%
%      M M~ + N N~ = I
%
%   Cette factorisation existe pour tout modèle, stable ou non, et c'est
%   ce qui la rend précieuse : elle donne des objets stables à manier là
%   où le modèle lui-même n'en est pas un. La distance de graphe, la
%   marge des facteurs premiers, la réduction d'un modèle instable en
%   dépendent toutes.
%
%   Les facteurs se construisent à partir de la solution Z de l'équation
%   de Riccati du filtre :
%
%      A Z + Z A' - Z C' R^-1 C Z + B S^-1 B' = 0
%      H = -(Z C' + B D') R^-1
%
%   avec R = I + D D' et S = I + D' D. Les facteurs valent alors
%
%      M = [A + H C,  H     ;  R^-1/2 C,  R^-1/2   ]
%      N = [A + H C,  B + H D ;  R^-1/2 C,  R^-1/2 D]
%
%   Le controle de la normalisation se fait sur l'axe imaginaire, non par
%   une norme : M~ est le systeme conjugue M(-s), qui est antistable, et
%   la norme infinie du produit vaut donc l'infini alors que l'identite,
%   elle, est vraie.
%
%   Exemples :
%      G = ss(1, 1, 1, 0);           % instable
%      [M, N] = lncf(G);
%      max(real(pole(M)))            % negatif : le facteur est stable
%
%      w = logspace(-2, 2, 20);
%      Hm = freqresp(M, w);  Hn = freqresp(N, w);
%      max(abs(Hm .* conj(Hm) + Hn .* conj(Hn) - 1))    % nul : normalisee
%
%   Voir aussi NCFMR, NCFMARGIN, NCFSYN, GAPMETRIC, HINFSYN.
    G = ss(sys);
    A = G.A;
    B = G.B;
    C = G.C;
    D = G.D;
    n = size(A, 1);
    if n == 0
        M = ss(eye(size(D, 1)));
        N = ss(D);
        return;
    end
    % Avec un terme direct, la normalisation demande le facteur
    % R = I + D D' ; on s'y ramene par le changement usuel.
    R = eye(size(D, 1)) + D * D';
    S = eye(size(D, 2)) + D' * D;
    Ac = A - B / S * D' * C;
    % MATLIBRE_RICCATI resout A'X + XA + XSX + Q = 0 : le terme
    % quadratique y est ajoute, alors que l'equation du filtre le
    % soustrait. D'ou le signe moins, sans lequel la solution rendue
    % n'est pas stabilisante et les facteurs sortent instables.
    Z = matlibre_riccati(Ac', -(C' / R * C), B / S * B');
    H = -(Z * C' + B * D') / R;
    racineR = matlibre_racine_carree(inv(R));
    M = ss(A + H * C, H, racineR * C, racineR, G.Ts);
    N = ss(A + H * C, B + H * D, racineR * C, racineR * D, G.Ts);
end
