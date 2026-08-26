function Q = qlearning(env, episodes, alpha, gamma, epsilon)
%QLEARNING Apprentissage Q tabulaire sur un environnement de grille.
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
