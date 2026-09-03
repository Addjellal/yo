function verdict = iscatastrophic(trellis)
%ISCATASTROPHIC Le codeur convolutif est-il catastrophique.
%   OK = ISCATASTROPHIC(TRELLIS) est vrai quand le codeur peut produire
%   une suite de sortie de poids fini à partir d'une suite d'entrée de
%   poids infini : une poignée d'erreurs de canal donne alors une
%   infinité d'erreurs après décodage. Un tel codeur est inutilisable.
%
%   Le critère est structurel : le codeur est catastrophique quand le
%   graphe des états comporte un cycle, hors de l'état zéro, dont toutes
%   les sorties sont nulles et dont au moins une entrée ne l'est pas.
%
%   Exemple :
%      iscatastrophic(poly2trellis(3, [7 5]))   % faux : bon codeur
%      iscatastrophic(poly2trellis(3, [6 5]))   % vrai : catastrophique
%
%   Voir aussi POLY2TRELLIS, ISTRELLIS, DISTSPEC, CONVENC.
    [ok, message] = istrellis(trellis);
    if ~ok
        error('comm:iscatastrophic:Treillis', '%s', message);
    end
    etats = trellis.numStates;
    entrees = trellis.numInputSymbols;
    % On ne garde que les transitions de sortie nulle : le codeur est
    % catastrophique s'il y a un cycle parmi elles, hors de l'état zéro.
    adjacence = false(etats, etats);
    for etat = 1:etats
        for symbole = 1:entrees
            if trellis.outputs(etat, symbole) == 0
                suivant = trellis.nextStates(etat, symbole) + 1;
                % L'état zéro bouclant sur lui-même par l'entrée nulle
                % n'a rien de catastrophique : c'est le repos.
                if etat == 1 && suivant == 1 && symbole == 1
                    continue
                end
                adjacence(etat, suivant) = true;
            end
        end
    end
    % Fermeture transitive : un état qui se rejoint lui-même est sur un
    % cycle.
    atteint = adjacence;
    for k = 1:etats
        atteint = atteint | (atteint * adjacence ~= 0);
    end
    verdict = any(diag(atteint));
end
