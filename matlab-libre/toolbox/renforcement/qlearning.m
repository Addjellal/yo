function Q = qlearning(env, episodes, alpha, gamma, epsilon)
%QLEARNING Apprentissage Q tabulaire sur un environnement de grille.
%   Q = QLEARNING(ENV,EPISODES,ALPHA,GAMMA,EPSILON) apprend la table des
%   valeurs état-action par la règle
%
%      Q(s,a) <- Q(s,a) + ALPHA (r + GAMMA max_a' Q(s',a') - Q(s,a))
%
%   ALPHA est le pas d'apprentissage, GAMMA l'actualisation du futur, et
%   EPSILON la part d'exploration au hasard.
%
%   Le maximum sur les actions suivantes est ce qui fait de Q-learning une
%   méthode *hors politique* : il apprend la valeur de la meilleure
%   politique, quelle que soit celle qu'il suit pour explorer. SARSA, qui
%   emploie l'action réellement choisie, apprend la valeur de la politique
%   suivie — d'où des comportements différents près d'un danger.
%
%   La table part de zéro, ce qui est optimiste puisque chaque pas coûte :
%   toute action non essayée paraît meilleure que celles qu'on connaît, et
%   l'agent explore de lui-même. C'est pourquoi EPSILON peut rester petit.
%
%   Exemple :
%      env = gridworld(5, 5, [5 5], [2 3; 3 3]);
%      Q = qlearning(env, 500);
%      politique = greedyPolicy(Q);
%
%   Voir aussi SARSA, GREEDYPOLICY, GRIDWORLD, PASGRILLE.
    if nargin < 2, episodes = 500; end
    if nargin < 3, alpha = 0.5; end
    if nargin < 4, gamma = 0.95; end
    if nargin < 5, epsilon = 0.1; end
    Q = zeros(env.nEtats, env.nActions);
    arriveeEtat = (env.arrivee(1) - 1) * env.colonnes + env.arrivee(2);
    for e = 1:episodes
        etat = 1;
        for pas = 1:200
            if rand() < epsilon
                action = randi([1 env.nActions]);
            else
                [~, action] = max(Q(etat, :));
            end
            [suivant, recompense, fini] = pasGrille(env, etat, action);
            Q(etat, action) = Q(etat, action) + alpha * ...
                (recompense + gamma * max(Q(suivant, :)) - Q(etat, action));
            etat = suivant;
            if fini
                break;
            end
        end
    end
end
