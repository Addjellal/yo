function [phi, retards, bornes] = parcorr(y, nRetards, nEcarts)
%PARCORR Autocorrélation partielle, par les équations de Yule-Walker.
%   [PHI,RETARDS] = PARCORR(Y) rend l'autocorrélation partielle de Y.
%   [PHI,RETARDS,BORNES] = PARCORR(...) rend en outre les bornes de
%   confiance sous l'hypothèse d'un bruit blanc.
%
%   L'autocorrélation ordinaire mesure le lien entre y(t) et y(t-k), lien
%   qui passe en partie par les retards intermédiaires : un AR(1) a une
%   autocorrélation non nulle à tous les retards, alors qu'un seul compte
%   vraiment. L'autocorrélation partielle ôte cet effet indirect, si bien
%   qu'un AR(p) la voit s'annuler après le retard p — c'est ainsi qu'on
%   lit l'ordre d'un modèle autorégressif sur ses données.
%
%   Exemple :
%      y = filter(1, [1 -0.7], randn(500, 1));
%      p = parcorr(y, 10);
%      p(2)                            % voisin de 0.7
%      max(abs(p(3:end)))              % petit : l'ordre est un
%
%   Voir aussi AUTOCORR, ARFIT, ARIMA.
    if nargin < 2 || isempty(nRetards)
        nRetards = min(20, numel(y) - 1);
    end
    if nargin < 3 || isempty(nEcarts)
        nEcarts = 2;
    end
    rho = autocorr(y, nRetards);
    phi = zeros(nRetards + 1, 1);
    phi(1) = 1;
    for k = 1:nRetards
        R = zeros(k, k);
        for i = 1:k
            for j = 1:k
                R(i, j) = rho(abs(i - j) + 1);
            end
        end
        r = rho(2:k+1);
        solution = R \ r;
        phi(k + 1) = solution(end);
    end
    retards = (0:nRetards).';
    if nargout > 2
        bornes = [nEcarts; -nEcarts] / sqrt(numel(y));
    end
end
