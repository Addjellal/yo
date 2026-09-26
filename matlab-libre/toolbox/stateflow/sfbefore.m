function vrai = sfbefore(contexte, n, unite)
%SFBEFORE Vrai avant N réveils — ou N secondes — passés dans l'état.
%   VRAI = SFBEFORE(CONTEXTE,N) vaut vrai tant que l'état dont on essaie
%   la transition est actif depuis moins de N réveils : before(N, tick) de
%   Stateflow. SFBEFORE(CONTEXTE,N,'sec') compte en secondes.
%
%   Exemple :
%      m = sfchart('fenetre');
%      m = sfstate(m, 'ouverte');
%      m = sfstate(m, 'vue');
%      m = sftransition(m, 'ouverte', 'vue', @(c, u) u == 1 && sfbefore(c, 2));
%      sfrun(m, [0 0 1])          % ouverte, ouverte, ouverte : trop tard
%
%   Voir aussi SFAFTER, SFAT, SFEVERY.
    if nargin < 3
        unite = 'tick';
    end
    vrai = ~sfafter(contexte, n, unite);
end
