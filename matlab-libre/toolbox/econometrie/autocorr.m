function [rho, retards, bornes] = autocorr(y, nRetards, nEcarts)
%AUTOCORR Fonction d'autocorrélation empirique.
%   [RHO,RETARDS] = AUTOCORR(Y) rend l'autocorrélation de Y aux retards
%   zéro à vingt. RHO(1) vaut toujours un.
%   [RHO,RETARDS] = AUTOCORR(Y,N) va jusqu'au retard N.
%   [RHO,RETARDS,BORNES] = AUTOCORR(...) rend en outre les bornes de
%   confiance sous l'hypothèse d'un bruit blanc : plus ou moins deux
%   écarts types, soit 2/racine(N).
%   AUTOCORR(Y,N,K) emploie K écarts types au lieu de deux.
%
%   Les bornes ne disent pas que la série est un bruit blanc : elles
%   disent où tomberaient les autocorrélations si elle l'était. Une seule
%   valeur qui dépasse ne prouve rien — sur vingt retards, une par
%   hasard est attendue. C'est le nombre de dépassements qui compte, et
%   LBQTEST le teste proprement.
%
%   Exemple :
%      [r, ~, b] = autocorr(randn(500, 1), 20);
%      sum(abs(r(2:end)) > b(1))       % quelques-unes au plus
%
%   Voir aussi PARCORR, LBQTEST, CROSSCORR.
    y = y(:);
    n = numel(y);
    if nargin < 2 || isempty(nRetards)
        nRetards = min(20, n - 1);
    end
    if nargin < 3 || isempty(nEcarts)
        nEcarts = 2;
    end
    m = mean(y);
    denominateur = sum((y - m) .^ 2);
    rho = zeros(nRetards + 1, 1);
    for k = 0:nRetards
        rho(k + 1) = sum((y(1:n-k) - m) .* (y(1+k:n) - m)) / denominateur;
    end
    retards = (0:nRetards).';
    if nargout > 2
        % Sous l'hypothèse d'un bruit blanc, l'autocorrélation empirique
        % à un retard non nul est approximativement normale de variance
        % 1/N : les bornes en découlent directement.
        bornes = [nEcarts; -nEcarts] / sqrt(n);
    end
end
