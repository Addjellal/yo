function Q = sarsa(env, episodes, alpha, gamma, epsilon)
%SARSA Apprentissage SARSA sur un environnement de grille.
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
