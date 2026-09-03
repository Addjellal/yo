function nombre = ntnode(arbre)
%NTNODE Nombre de nœuds terminaux d'un arbre.
%   N = NTNODE(T) compte les feuilles. Pour un arbre complet de
%   profondeur D et d'ordre ORD, c'est ORD^D ; un arbre élagué en compte
%   moins.
%
%   Exemple :
%      ntnode(wpdec(1:64, 3, 'db2'))  % 8
%      ntnode(wpdec2(magic(16), 2, 'haar'))   % 16
%
%   Voir aussi LEAVES, TNODES, TREEDPTH, BESTTREE.
    nombre = numel(leaves(arbre));
end
