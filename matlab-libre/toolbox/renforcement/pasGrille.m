function [suivant, recompense, fini] = pasGrille(env, etat, action)
%PASGRILLE Transition de l'environnement de grille.
%   [SUIVANT,RECOMPENSE,FINI] = PASGRILLE(ENV,ETAT,ACTION) applique
%   l'action et rend le nouvel état, la récompense et si l'épisode se
%   termine.
%
%   ETAT et SUIVANT sont des numéros d'état, ARRIVEE et OBSTACLES des
%   couples [I J] : c'est la convention de GRIDWORLD.
%
%   Un mur ou un obstacle laisse l'agent où il était. Rien ne le signale
%   autrement que par le fait de ne pas bouger : c'est à l'agent de
%   l'apprendre, comme le reste.
%
%   Exemple :
%      env = gridworld(3, 3, [3 3]);
%      pasGrille(env, 1, 1)            % 1 : le mur du haut retient
%      [~, r, fini] = pasGrille(env, 6, 2);   % arrivee : r = 10, fini
%
%   Voir aussi GRIDWORLD, QLEARNING, SARSA.
    i = floor((etat - 1) / env.colonnes) + 1;
    j = mod(etat - 1, env.colonnes) + 1;
    switch action
        case 1, i = i - 1;
        case 2, i = i + 1;
        case 3, j = j - 1;
        case 4, j = j + 1;
    end
    i = min(max(i, 1), env.lignes);
    j = min(max(j, 1), env.colonnes);
    if ~isempty(env.obstacles)
        for k = 1:size(env.obstacles, 1)
            if env.obstacles(k,1) == i && env.obstacles(k,2) == j
                i = floor((etat - 1) / env.colonnes) + 1;
                j = mod(etat - 1, env.colonnes) + 1;
            end
        end
    end
    suivant = (i - 1) * env.colonnes + j;
    fini = (i == env.arrivee(1)) && (j == env.arrivee(2));
    if fini
        recompense = 10;
    else
        recompense = -1;
    end
end
