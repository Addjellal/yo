function gradients = matlibre_retropropager(sortie)
%MATLIBRE_RETROPROPAGER Remonte la bande et accumule les dérivées.
%   G = MATLIBRE_RETROPROPAGER(SORTIE) rend un tableau de cellules qui
%   donne, pour chaque nœud de la bande, la dérivée du nœud SORTIE par
%   rapport à lui.
%
%   Les nœuds ayant été inscrits dans l'ordre du calcul, les parcourir en
%   sens inverse suffit : quand on arrive à un nœud, toutes les
%   contributions qui lui reviennent ont déjà été ajoutées.
%
%   Exemple :
%      matlibre_bande('ouvrir');
%      x = dlarray(3);
%      y = x * x;
%      g = matlibre_retropropager(y.Noeud);
%      g{x.Noeud}      % 6
%
%   Voir aussi DLGRADIENT, MATLIBRE_GRADIENT_OPERATION.
    noeuds = matlibre_bande('lire');
    gradients = cell(1, numel(noeuds));
    gradients{sortie} = 1;
    for k = sortie:-1:1
        courant = gradients{k};
        if isempty(courant)
            continue
        end
        noeud = noeuds{k};
        if isempty(noeud.parents)
            continue
        end
        contributions = matlibre_gradient_operation(noeud, courant);
        for j = 1:numel(noeud.parents)
            parent = noeud.parents(j);
            if parent == 0 || j > numel(contributions) || isempty(contributions{j})
                continue
            end
            if isempty(gradients{parent})
                gradients{parent} = contributions{j};
            else
                gradients{parent} = gradients{parent} + contributions{j};
            end
        end
    end
end
