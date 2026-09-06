function y = distributed(x)
%DISTRIBUTED Tableau distribué.
%   Y = DISTRIBUTED(X) marque un tableau comme distribué sur le pool. Sur
%   une seule machine, c'est l'identité.
%
%   Ce n'est pas décoratif pour autant : DISTRIBUTED et GATHER marquent
%   dans le code les endroits où les données passeraient d'une machine à
%   l'autre. Un programme écrit avec eux tourne sans changement sur un
%   vrai pool, et sa lecture dit où sont les communications — qui coûtent
%   toujours plus cher que le calcul.
%
%   Exemple :
%      d = distributed(magic(4));
%      isequal(gather(d), magic(4))    % true
%
%   Voir aussi GATHER, PARARRAYFUN, PARCELLFUN.
    y = x;
end
