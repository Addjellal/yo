function c = seqrcomplement(s)
%SEQRCOMPLEMENT Brin complémentaire inverse.
%   C = SEQRCOMPLEMENT(S) rend le complément lu à l'envers : c'est le brin
%   qui fait face dans la double hélice, les deux brins étant
%   antiparallèles.
%
%   Une séquence égale à son complément inverse est un palindrome
%   biologique. Ce n'est pas une curiosité : les enzymes de restriction
%   reconnaissent presque toutes des sites palindromiques, parce qu'elles
%   agissent en dimère symétrique.
%
%   Exemple :
%      seqrcomplement('GAATTC')        % 'GAATTC' : le site d'EcoRI
%      seqrcomplement(seqrcomplement('ACGTTG'))    % la sequence de depart
%
%   Voir aussi SEQCOMPLEMENT, GCCONTENT.
    c = seqcomplement(s);
    c = c(end:-1:1);
end
