function [arbre, entropies, entropiesInitiales] = besttree(arbre)
%BESTTREE Meilleur arbre de paquets au sens de l'entropie.
%   T = BESTTREE(T) élague l'arbre : un nœud garde ses enfants si leur
%   entropie totale est plus petite que la sienne, sinon ils sont
%   supprimés. La base retenue est celle qui concentre le plus l'énergie
%   du signal, ce qui est exactement ce qu'on veut pour comprimer ou
%   débruiter.
%
%   La recherche remonte des feuilles vers la racine : chaque nœud est
%   comparé au meilleur de ses descendants, si bien que le résultat est
%   optimal sur tout l'arbre, non seulement de proche en proche.
%
%   [T,E,E0] = BESTTREE(T) rend aussi l'entropie retenue et l'entropie
%   propre de chaque nœud, indexées comme « donnees ».
%
%   Le critère est celui que WPDEC a enregistré ; WENTROPY les décrit.
%
%   Exemple :
%      t = wpdec(sin((1:256) / 3), 4, 'db2');
%      meilleur = besttree(t);
%      ntnode(meilleur) <= ntnode(t)  % vrai : l'arbre est élagué
%
%   Voir aussi WENTROPY, WPDEC, WPDEC2, LEAVES, WPJOIN.
    if ~isfield(arbre, 'type') || ~strcmp(arbre.type, 'wptree')
        error('wavelet:besttree:Arbre', 'BESTTREE attend un arbre de paquets.');
    end
    maximum = max(arbre.noeuds);
    entropiesInitiales = inf(1, maximum + 1);
    for k = 1:numel(arbre.noeuds)
        indice = arbre.noeuds(k);
        donnees = lireNoeud(arbre, indice);
        entropiesInitiales(indice + 1) = wentropy(donnees, arbre.entropie, arbre.parametre);
    end
    entropies = entropiesInitiales;
    aGarder = false(1, maximum + 1);
    % Remontée des feuilles vers la racine : les indices décroissants
    % suivent l'ordre de profondeur, un enfant portant toujours un indice
    % plus grand que son parent.
    for indice = maximum:-1:0
        if ~any(arbre.noeuds == indice)
            continue
        end
        premier = arbre.ordre * indice + 1;
        if premier > maximum || ~any(arbre.noeuds == premier)
            continue                       % feuille : rien à comparer
        end
        total = 0;
        for k = 1:arbre.ordre
            total = total + entropies(arbre.ordre * indice + k + 1);
        end
        if total < entropies(indice + 1)
            entropies(indice + 1) = total;
            aGarder(indice + 1) = true;
        end
    end
    % Descente : on ne suit que les branches retenues.
    aSupprimer = [];
    pile = 0;
    while ~isempty(pile)
        courant = pile(end);
        pile(end) = [];
        premier = arbre.ordre * courant + 1;
        if premier > maximum || ~any(arbre.noeuds == premier)
            continue
        end
        if aGarder(courant + 1)
            for k = 1:arbre.ordre
                pile(end + 1) = arbre.ordre * courant + k;   %#ok<AGROW>
            end
        else
            aSupprimer = [aSupprimer, sousArbre(arbre, courant)];   %#ok<AGROW>
        end
    end
    arbre.noeuds = setdiff(arbre.noeuds, aSupprimer);
    arbre.profondeur = treedpth(arbre);
end

function liste = sousArbre(arbre, indice)
%SOUSARBRE Tous les nœuds strictement sous un nœud donné.
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
