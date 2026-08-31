function P = matlibre_augmente_ncf(G)
%MATLIBRE_AUGMENTE_NCF Le modèle augmenté du problème des facteurs premiers.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   NCFSYN s'en sert : maximiser la marge des facteurs premiers revient à
%   minimiser la norme H-infini des quatre transmittances de la boucle,
%
%      [ I ; K ] (I - G K)^-1 [ I  G ]
%
%   et cette matrice est exactement LFT(P,K) pour le modèle augmenté
%   construit ici. Les signaux sont
%
%      w = [w1 ; w2]   perturbation en sortie, perturbation en entrée
%      z = [y  ; u ]   la mesure et la commande
%
%   liés par
%
%      xpoint = A x + B (u + w2)
%      y      = w1 + C x + D (u + w2)
%      z1     = y,      z2 = u
%
%   Un calcul direct donne alors z = [I ; K] (I - GK)^-1 [I  G] w, ce que
%   l'on voulait. Le terme direct D11 n'est pas nul : il porte
%   l'identité qui fait passer w1 dans y, et c'est HINFSYN qui s'en
%   charge par son déplacement de boucle.
    G = ss(G);
    A = G.A;
    B = G.B;
    C = G.C;
    D = G.D;
    n = size(A, 1);
    ny = size(C, 1);
    nu = size(B, 2);
    B1 = [zeros(n, ny), B];
    B2 = B;
    C1 = [C; zeros(nu, n)];
    C2 = C;
    D11 = [eye(ny), D; zeros(nu, ny), zeros(nu, nu)];
    D12 = [D; eye(nu)];
    D21 = [eye(ny), D];
    D22 = D;
    P = ss(A, [B1, B2], [C1; C2], [D11, D12; D21, D22], G.Ts);
end
