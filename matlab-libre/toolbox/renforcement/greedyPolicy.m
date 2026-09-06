function politique = greedyPolicy(Q)
%GREEDYPOLICY Action de valeur maximale dans chaque état.
%   POLITIQUE = GREEDYPOLICY(Q) rend, pour chaque état, l'action de plus
%   grande valeur : c'est la politique qu'on déploie une fois
%   l'apprentissage fini, sans plus d'exploration.
%
%   Une politique gloutonne n'a de sens que sur une table Q apprise :
%   appliquée à une table nulle, elle rend partout la première action.
%
%   Exemple :
%      Q = qlearning(env, 500);
%      politique = greedyPolicy(Q);
%      politique(1)                    % l'action a prendre dans l'etat 1
%
%   Voir aussi QLEARNING, SARSA, PASGRILLE.
    [~, politique] = max(Q, [], 2);
end
