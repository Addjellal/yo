function Q = sarsa(env, episodes, alpha, gamma, epsilon)
%SARSA Apprentissage SARSA sur un environnement de grille.
%   Q = SARSA(ENV,EPISODES,ALPHA,GAMMA,EPSILON) apprend par la règle
%
%      Q(s,a) <- Q(s,a) + ALPHA (r + GAMMA Q(s',a') - Q(s,a))
%
%   où a' est l'action réellement choisie au pas suivant, exploration
%   comprise. Le nom vient de ce quintuplet : état, action, récompense,
%   état, action.
%
%   C'est ce qui en fait une méthode *sur politique* : elle apprend la
%   valeur de la politique qu'elle suit, exploration incluse. Près d'un
%   précipice, un agent SARSA apprend donc à s'écarter du bord, parce
%   qu'il tient compte du risque de tomber en explorant ; un agent
%   Q-learning longe le bord, parce qu'il évalue la politique parfaite.
%
%   Aucune des deux n'a raison dans l'absolu : cela dépend de si l'agent
%   continuera d'explorer une fois déployé.
%
%   Exemple :
%      env = gridworld(5, 5, [5 5]);
%      Q = sarsa(env, 500);
%      politique = greedyPolicy(Q);
%
%   Voir aussi QLEARNING, GREEDYPOLICY, GRIDWORLD.
    if nargin < 2, episodes = 500; end
    if nargin < 3, alpha = 0.5; end
    if nargin < 4, gamma = 0.95; end
    if nargin < 5, epsilon = 0.1; end
    Q = zeros(env.nEtats, env.nActions);
    for e = 1:episodes
        etat = 1;
        action = choisir(Q, etat, epsilon, env.nActions);
        for pas = 1:200
            [suivant, recompense, fini] = pasGrille(env, etat, action);
            actionSuivante = choisir(Q, suivant, epsilon, env.nActions);
            Q(etat, action) = Q(etat, action) + alpha * ...
                (recompense + gamma * Q(suivant, actionSuivante) - Q(etat, action));
            etat = suivant;
            action = actionSuivante;
            if fini
                break;
            end
        end
    end
end

function a = choisir(Q, etat, epsilon, nActions)
    if rand() < epsilon
        a = randi([1 nActions]);
    else
        [~, a] = max(Q(etat, :));
    end
end
