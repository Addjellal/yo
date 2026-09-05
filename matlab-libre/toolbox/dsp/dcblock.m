function y = dcblock(x, alpha)
%DCBLOCK Filtre coupe-continu du premier ordre.
%   Y = DCBLOCK(X) ôte la composante continue de X.
%   Y = DCBLOCK(X,ALPHA) règle le pôle, 0.995 par défaut.
%
%   Le filtre est y[n] = x[n] - x[n-1] + alpha y[n-1] : un zéro exactement
%   à la fréquence nulle, et un pôle juste à côté. Le zéro annule le
%   continu, le pôle rend tout le reste presque intact.
%
%   ALPHA décide de l'arbitrage, et il n'y en a qu'un : plus il approche
%   de un, plus l'encoche est étroite — donc moins le signal utile est
%   touché — mais plus le régime transitoire est long. Sa durée vaut
%   environ 1/(1-ALPHA) échantillons : 200 pour 0.995, 1000 pour 0.999.
%   Mesurer la moyenne avant que ce transitoire soit éteint donne un
%   résultat qui n'a rien à voir avec le régime établi.
%
%   Exemple :
%      x = 5 + sin(2 * pi * 0.05 * (0:999)');
%      y = dcblock(x, 0.99);
%      mean(y(500:end))                % voisin de zero
%      std(y(500:end)) / std(x)        % voisin de un : l'alternatif reste
%
%   Voir aussi FILTER, DETREND, HIGHPASS, BUTTER.
    if nargin < 2 || isempty(alpha)
        alpha = 0.995;
    end
    if alpha <= 0 || alpha >= 1
        error('dsp:dcblock:Alpha', ...
              'ALPHA doit être strictement entre zéro et un.');
    end
    y = filter([1 -1], [1 -alpha], x);
end
