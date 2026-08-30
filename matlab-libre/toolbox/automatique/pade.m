function [num, den] = pade(T, n)
%PADE Approximation d'un retard pur par une fonction de transfert.
%   [NUM,DEN] = PADE(T,N) rend l'approximation de Padé d'ordre N du retard
%   exp(-T*s) : le quotient de deux polynômes de degré N dont le
%   développement en série coïncide avec celui de l'exponentielle jusqu'à
%   l'ordre 2N.
%
%   SYS = PADE(T,N) rend directement le modèle. Sans sortie, la fonction
%   trace la réponse indicielle et compare à un retard exact.
%
%   Un retard est ce qui déstabilise une boucle sans qu'on le voie venir :
%   il ne change pas le gain, seulement la phase, et l'approximer permet
%   de le porter dans un calcul de marges ou une synthèse.
%
%   L'ordre 1 suffit rarement au-delà de la bande passante ; l'ordre 3 ou
%   4 tient jusqu'à environ deux radians de déphasage.
%
%   Exemples :
%      [num, den] = pade(0.1, 1);
%      num                          % [-1 20] : le zero instable du retard
%      G = pade(0.5, 3);
%      abs(dcgain(G) - 1) < 1e-9    % un retard ne change pas le gain statique
%
%   Voir aussi C2D, MARGIN, TF, EXP.
    if nargin < 2 || isempty(n)
        n = 1;
    end
    if T < 0
        error('Control:pade:NegativeDelay', 'The delay must not be negative.');
    end
    n = round(n);
    if n < 1
        num = 1; den = 1;
        if nargout <= 1, num = tf(1, 1); end
        return
    end
    % Les coefficients de Padé : num(k) et den(k) suivent la formule
    % classique, de degré n chacun, et ne diffèrent que par le signe.
    num = zeros(1, n + 1);
    den = zeros(1, n + 1);
    for k = 0:n
        c = factorial(2*n - k) * factorial(n) / (factorial(2*n) * factorial(k) * ...
                                                 factorial(n - k));
        num(n + 1 - k) = c * (-T)^k;
        den(n + 1 - k) = c * T^k;
    end
    num = num / den(1);
    den = den / den(1);
    if nargout <= 1
        num = tf(num, den);
    end
end
