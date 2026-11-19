function [assignments, unassignedRows, unassignedColumns] = assignmunkres(costMatrix, costOfNonAssignment)
%ASSIGNMUNKRES Affectation optimale par l'algorithme de Munkres.
%   [ASSIGNMENTS,UNASSIGNEDROWS,UNASSIGNEDCOLUMNS] = ASSIGNMUNKRES(COUTS,C)
%   apparie les lignes de COUTS (les pistes) à ses colonnes (les
%   détections) en minimisant le coût total, comme MATLAB : laisser une
%   ligne ou une colonne seule coûte C. ASSIGNMENTS porte une ligne [ligne
%   colonne] par couple retenu ; les deux autres sorties, en colonne, les
%   lignes et les colonnes restées seules. Kuhn (1955), Munkres (1957) : la
%   solution est exacte, en temps cubique.
%
%   Exemple :
%      [a, l, c] = assignmunkres([1 2; 1.5 10], 20)   % [1 2; 2 1] : total 3.5
%
%   Voir aussi ASSIGNDETECTIONSTOTRACKS, TRACKASSIGN.
    [assignments, unassignedRows, unassignedColumns] = ...
        assignDetectionsToTracks(costMatrix, costOfNonAssignment);
end
