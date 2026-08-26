function [rangees, indices] = esort(p)
%ESORT Tri des pôles continus par partie réelle décroissante.
%   [S,I] = ESORT(P) range les pôles du moins stable au plus stable : la
%   partie réelle la plus grande vient en premier.
%
%   Exemple :
%      esort([-3; -1; -2])   % [-1; -2; -3]
%
%   Voir aussi DSORT, POLE, DAMP.
    p = p(:);
    [~, indices] = sort(real(p), 'descend');
    rangees = p(indices);
end
