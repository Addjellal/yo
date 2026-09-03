function [noeuds, tailles] = leaves(arbre, ordreSortie)
%LEAVES Nœuds terminaux d'un arbre de paquets d'ondelettes.
%   N = LEAVES(T) rend, en colonne et par indice croissant, les nœuds que
%   l'arbre ne scinde pas : ce sont eux qui portent la décomposition.
%
%   N = LEAVES(T,'dp') les rend sous la forme [profondeur position].
%   N = LEAVES(T,'sort') les trie par profondeur puis par position, ce
%   qui revient au même que par indice.
%   N = LEAVES(T,'sortdp') combine les deux.
%
%   [N,TAILLES] = LEAVES(T) rend aussi la taille des coefficients de
%   chaque feuille.
%
%   Exemple :
%      t = wpdec(1:64, 3, 'db2');
%      leaves(t)'                     % 7 8 9 10 11 12 13 14
%      leaves(t, 'dp')                % huit lignes [3 0] .. [3 7]
%
%   Voir aussi TNODES, NTNODE, TREEDPTH, WPDEC, BESTTREE.
    if nargin < 2, ordreSortie = ''; end
    noeuds = [];
    for k = 1:numel(arbre.noeuds)
        indice = arbre.noeuds(k);
        premierFils = arbre.ordre * indice + 1;
        if ~any(arbre.noeuds == premierFils)
            noeuds(end + 1) = indice;   %#ok<AGROW>
        end
    end
    noeuds = sort(noeuds(:));
    if nargout > 1
        tailles = zeros(numel(noeuds), 2);
        for k = 1:numel(noeuds)
            tailles(k, :) = tailleDe(lireNoeud(arbre, noeuds(k)));
        end
    end
    if ~isempty(ordreSortie) && ~isempty(strfind(lower(char(ordreSortie)), 'dp'))
        noeuds = ind2depo(arbre.ordre, noeuds);
    end
end

function t = tailleDe(donnees)
    if isempty(donnees)
        t = [0 0];
    else
        t = size(donnees);
    end
end
