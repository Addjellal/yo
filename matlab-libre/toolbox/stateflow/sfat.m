function vrai = sfat(contexte, n, unite)
%SFAT Vrai au N-ième réveil — ou à la N-ième seconde — passé dans l'état.
%   VRAI = SFAT(CONTEXTE,N) vaut vrai au réveil où l'état dont on essaie
%   la transition est actif depuis exactement N réveils : at(N, tick) de
%   Stateflow. SFAT(CONTEXTE,N,'sec') compte en secondes, à la moitié
%   d'un millionième près.
%
%   Exemple :
%      m = sfchart('impulsion');
%      m = sfstate(m, 'bas');
%      m = sfstate(m, 'haut');
%      m = sftransition(m, 'bas', 'haut', @(c, u) sfat(c, 2));
%      sfrun(m, zeros(1, 3))       % bas, haut, haut
%
%   Voir aussi SFAFTER, SFBEFORE, SFEVERY.
    if nargin < 3
        unite = 'tick';
    end
    if strcmpi(unite, 'tick')
        vrai = sfafter(contexte, n, unite) && ~sfafter(contexte, n + 1, unite);
    else
        vrai = sfafter(contexte, n - 5e-7, unite) && ~sfafter(contexte, n + 5e-7, unite);
    end
end
