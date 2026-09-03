function [arbre, coefficients] = wpjoin(arbre, noeud)
%WPJOIN Réunit les descendants d'un nœud d'un arbre de paquets.
%   T = WPJOIN(T,N) supprime tout ce qui pend sous le nœud N : celui-ci
%   redevient une feuille, et ses coefficients sont recalculés de ses
%   descendants pour rester cohérents.
%
%   [T,C] = WPJOIN(T,N) rend aussi ces coefficients.
%
%   C'est l'opération inverse de WPSPLT : les deux servent à façonner un
%   arbre à la main, ou à élaguer celui que BESTTREE a choisi.
%
%   Exemple :
%      t = wpdec(1:64, 3, 'db2');
%      t = wpjoin(t, 1);              % la branche basse est refermée
%      leaves(t)'                     % 1 11 12 13 14 : l'autre branche
%                                     % garde sa profondeur
%
%   Voir aussi WPSPLT, WPDEC, LEAVES, BESTTREE.
    indice = indiceDeNoeud(arbre, noeud);
    if ~any(arbre.noeuds == indice)
        error('wavelet:wpjoin:Absent', ...
              'Le nœud %d n''est pas dans l''arbre.', indice);
    end
    % Les coefficients du nœud sont ceux que ses descendants
    % reconstruisent : refermer une branche ne doit rien perdre.
    coefficients = recomposer(arbre, indice);
    arbre = poserNoeud(arbre, indice, coefficients);
    aRetirer = descendants(arbre, indice);
    arbre.noeuds = setdiff(arbre.noeuds, aRetirer);
    arbre.profondeur = treedpth(arbre);
    if nargout < 2
        clear coefficients
    end
end

function donnees = recomposer(arbre, indice)
    premier = arbre.ordre * indice + 1;
    if ~any(arbre.noeuds == premier)
        donnees = lireNoeud(arbre, indice);
        return
    end
    enfants = cell(1, arbre.ordre);
    for k = 1:arbre.ordre
        enfants{k} = recomposer(arbre, arbre.ordre * indice + k);
    end
    if arbre.dimension == 1
        donnees = idwt(enfants{1}, enfants{2}, arbre.nom);
    else
        donnees = idwt2(enfants{1}, enfants{2}, enfants{3}, enfants{4}, arbre.nom);
    end
end

function liste = descendants(arbre, indice)
%DESCENDANTS Tous les nœuds sous un nœud donné, lui exclu.
    liste = [];
    pile = indice;
    while ~isempty(pile)
        courant = pile(end);
        pile(end) = [];
        for k = 1:arbre.ordre
            fils = arbre.ordre * courant + k;
            if any(arbre.noeuds == fils)
                liste(end + 1) = fils;   %#ok<AGROW>
                pile(end + 1) = fils;    %#ok<AGROW>
            end
        end
    end
end
