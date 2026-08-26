function [rangees, indices] = dsort(p)
%DSORT Tri des pôles discrets par module décroissant.
%   [S,I] = DSORT(P) range les pôles du plus rapide au plus lent au sens
%   du temps discret : le module le plus grand vient en premier, puisque
%   c'est lui qui domine la réponse.
%
%   Exemple :
%      dsort([0.5; 0.9; 0.1])   % [0.9; 0.5; 0.1]
%
%   Voir aussi ESORT, POLE, DAMP.
    p = p(:);
    [~, indices] = sort(abs(p), 'descend');
    rangees = p(indices);
end
