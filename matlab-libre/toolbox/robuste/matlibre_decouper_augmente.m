function [A, B1, B2, C1, C2, D11, D12, D21, D22] = ...
    matlibre_decouper_augmente(P, nmes, ncom)
%MATLIBRE_DECOUPER_AUGMENTE Découpe un modèle augmenté en ses neuf blocs.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   Toute synthèse — H2, H-infini, LQG écrite en modèle augmenté — a
%   besoin du même découpage :
%
%      P = [ A  | B1  B2  ]
%          [ C1 | D11 D12 ]
%          [ C2 | D21 D22 ]
%
%   où les NCOM dernières entrées sont les commandes et les NMES
%   dernières sorties les mesures. Le reste est exogène.
    P = ss(P);
    A = P.A;
    B = P.B;
    C = P.C;
    D = P.D;
    nu = size(B, 2);
    ny = size(C, 1);
    if ncom > nu || nmes > ny || ncom < 0 || nmes < 0
        error('robust:decouper:BadPartition', ...
              'NMES and NCOM must fit the size of P.');
    end
    nw = nu - ncom;
    nz = ny - nmes;
    B1 = B(:, 1:nw);
    B2 = B(:, nw + 1:end);
    C1 = C(1:nz, :);
    C2 = C(nz + 1:end, :);
    D11 = D(1:nz, 1:nw);
    D12 = D(1:nz, nw + 1:end);
    D21 = D(nz + 1:end, 1:nw);
    D22 = D(nz + 1:end, nw + 1:end);
end
