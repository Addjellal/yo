function env = gridworld(lignes, colonnes, arrivee, obstacles)
%GRIDWORLD Environnement de grille : quatre actions, récompense -1 par pas.
%   ENV = GRIDWORLD(LIGNES,COLONNES,ARRIVEE,OBSTACLES) décrit une grille.
%   ARRIVEE est un couple [I J], et OBSTACLES une matrice de couples
%   [I J], une case par ligne — non des numéros d'état.
%
%   Les états, eux, sont numérotés : l'état de la case (I,J) vaut
%   (I-1)*COLONNES + J. C'est cette numérotation que la table Q emploie.
%
%   Chaque pas coûte un point, atteindre l'arrivée en rapporte dix. Ce
%   coût par pas est ce qui pousse l'agent à trouver un chemin court :
%   sans lui, tout chemin qui finit par arriver vaudrait autant.
%
%   Les actions : 1 vers le haut, 2 vers le bas, 3 vers la gauche, 4 vers
%   la droite. Un mur ou un obstacle laisse l'agent sur place.
%
%   Exemple :
%      env = gridworld(5, 5, [5 5], [2 3; 3 3]);
%      env.nEtats                      % 25
%      [suivant, r, fini] = pasGrille(env, 1, 4);
%
%   Voir aussi PASGRILLE, QLEARNING, SARSA, GREEDYPOLICY.
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
