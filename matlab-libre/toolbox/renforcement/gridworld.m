function env = gridworld(lignes, colonnes, arrivee, obstacles)
%GRIDWORLD Environnement de grille : quatre actions, récompense -1 par pas.
    if nargin < 4
        obstacles = [];
    end
    env = struct();
    env.lignes = lignes;
    env.colonnes = colonnes;
    env.arrivee = arrivee;
    env.obstacles = obstacles;
    env.nEtats = lignes * colonnes;
    env.nActions = 4;
end
