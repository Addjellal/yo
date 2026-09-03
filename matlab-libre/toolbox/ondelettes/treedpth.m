function profondeur = treedpth(arbre)
%TREEDPTH Profondeur d'un arbre de paquets d'ondelettes.
%   D = TREEDPTH(T) rend la profondeur du nœud le plus profond, c'est à
%   dire le nombre de scissions du chemin le plus long.
%
%   Exemple :
%      t = wpdec(1:64, 3, 'db2');
%      treedpth(t)                    % 3
%      treedpth(wpjoin(t, 1))         % 3 : l'autre branche est intacte
%
%   Voir aussi LEAVES, NTNODE, WPDEC, WPSPLT, WPJOIN.
    if isempty(arbre.noeuds)
        profondeur = 0;
        return
    end
    positions = ind2depo(arbre.ordre, arbre.noeuds);
    profondeur = max(positions(:, 1));
end
