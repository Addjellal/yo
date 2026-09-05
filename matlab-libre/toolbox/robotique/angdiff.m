function d = angdiff(a, b)
%ANGDIFF Différence de deux angles, ramenée dans [-pi, pi].
%   D = ANGDIFF(A,B) rend B - A ramené dans [-pi, pi].
%   D = ANGDIFF(A) rend les différences successives des éléments de A.
%
%   Soustraire deux angles sans précaution donne des résultats faux dès
%   qu'on franchit pi : la différence entre 3.1 et -3.1 radians vaut 0.08
%   radian, non 6.2. Le repliement est donc la seule opération correcte,
%   et c'est tout ce que fait cette fonction.
%
%   Exemple :
%      angdiff(3.1, -3.1)              % 0.0832, non -6.2
%      angdiff([0 pi/2 pi])            % [pi/2 pi/2]
%
%   Voir aussi WRAPTOPI, MOD.
    if nargin < 2
        a = double(a);
        d = matlibre_rob_replier(diff(a));
        return
    end
    d = matlibre_rob_replier(double(b) - double(a));
end
