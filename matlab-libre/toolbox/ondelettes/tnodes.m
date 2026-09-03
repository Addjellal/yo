function [noeuds, tailles] = tnodes(arbre, ordreSortie)
%TNODES Nœuds terminaux d'un arbre — l'autre nom de LEAVES.
%   N = TNODES(T) rend les nœuds que l'arbre ne scinde pas.
%   N = TNODES(T,'deppos') les rend sous la forme [profondeur position].
%
%   C'est le nom d'origine ; LEAVES est le nom récent. Les deux rendent
%   la même chose.
%
%   Exemple :
%      t = wpdec(1:64, 2, 'haar');
%      tnodes(t)'                     % 3 4 5 6
%
%   Voir aussi LEAVES, NTNODE, TREEDPTH, WPDEC.
    if nargin < 2, ordreSortie = ''; end
    if ~isempty(ordreSortie) && ~isempty(strfind(lower(char(ordreSortie)), 'dep'))
        ordreSortie = 'dp';
    end
    if nargout > 1
        [noeuds, tailles] = leaves(arbre, ordreSortie);
    else
        noeuds = leaves(arbre, ordreSortie);
    end
end
