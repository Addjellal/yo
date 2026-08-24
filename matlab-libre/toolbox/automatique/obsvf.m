function [Abar, Bbar, Cbar, T, k] = obsvf(A, B, C, tolerance)
%OBSVF Forme échelonnée d'observabilité.
%   [ABAR,BBAR,CBAR,T,K] = OBSVF(A,B,C) rend une base orthonormée dans
%   laquelle la partie non observable se sépare :
%
%      Abar = T A T' = [ Ano  A12 ]      Cbar = C T' = [ 0  Co ]
%                      [  0   Ao  ]
%
%   C'est le dual exact de CTRBF : la forme s'obtient en appliquant
%   CTRBF au triplet transposé (A', C', B') puis en retransposant.
%
%   Exemple :
%      [ab, bb, cb, t, k] = obsvf([1 0; 0 2], [1; 1], [1 0]);
%      sum(k)   % 1 : un seul mode est observable
%
%   Voir aussi CTRBF, OBSV, MINREAL.
    n = size(A, 1);
    if nargin < 2 || isempty(B), B = zeros(n, 0); end
    if nargin < 4 || isempty(tolerance), tolerance = []; end
    if isempty(tolerance)
        [Ac, Bc, Cc, T, k] = ctrbf(A', C', B');
    else
        [Ac, Bc, Cc, T, k] = ctrbf(A', C', B', tolerance);
    end
    Abar = Ac';
    Bbar = Cc';
    Cbar = Bc';
end
