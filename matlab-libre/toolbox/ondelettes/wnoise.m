function [x, xbruite] = wnoise(fonction, puissance, rapport, germe)
%WNOISE Signaux d'essai de Donoho et Johnstone.
%   [X,XN] = WNOISE(FUN,N) rend l'un des quatre signaux de référence sur
%   2^N points, et sa version bruitée. FUN vaut 1 ou 'blocks', 2 ou
%   'bumps', 3 ou 'heavysine', 4 ou 'doppler'.
%
%   [X,XN] = WNOISE(FUN,N,RAPPORT) fixe le rapport signal sur bruit :
%   le bruit a pour écart type l'écart type du signal divisé par
%   RAPPORT.
%
%   Ce sont les quatre signaux sur lesquels se comparent, depuis 1994,
%   toutes les méthodes de débruitage par ondelettes : marches, pointes,
%   sinusoïde à sauts, et chirp amorti.
%
%   Exemple :
%      [x, xn] = wnoise('doppler', 10, 7);
    if nargin < 3 || isempty(rapport), rapport = 1; end
    n = 2 ^ puissance;
    t = (1:n) / n;
    if ischar(fonction) || isstring(fonction)
        nom = lower(char(fonction));
    else
        noms = {'blocks', 'bumps', 'heavysine', 'doppler'};
        nom = noms{min(max(round(fonction), 1), 4)};
    end
    switch nom
        case 'blocks'
            positions = [0.1 0.13 0.15 0.23 0.25 0.4 0.44 0.65 0.76 0.78 0.81];
            hauteurs = [4 -5 3 -4 5 -4.2 2.1 4.3 -3.1 2.1 -4.2];
            x = zeros(1, n);
            for k = 1:numel(positions)
                x = x + hauteurs(k) * (1 + sign(t - positions(k))) / 2;
            end
        case 'bumps'
            positions = [0.1 0.13 0.15 0.23 0.25 0.4 0.44 0.65 0.76 0.78 0.81];
            hauteurs = [4 5 3 4 5 4.2 2.1 4.3 3.1 5.1 4.2];
            largeurs = [0.005 0.005 0.006 0.01 0.01 0.03 0.01 0.01 0.005 0.008 0.005];
            x = zeros(1, n);
            for k = 1:numel(positions)
                x = x + hauteurs(k) * (1 + abs(t - positions(k)) / largeurs(k)) .^ (-4);
            end
        case 'heavysine'
            x = 4 * sin(4 * pi * t) - sign(t - 0.3) - sign(0.72 - t);
        case 'doppler'
            epsilon = 0.05;
            x = sqrt(t .* (1 - t)) .* sin(2 * pi * (1 + epsilon) ./ (t + epsilon));
        otherwise
            error('wavelet:wnoise:UnknownSignal', 'Signal inconnu : %s.', nom);
    end
    if nargout > 1
        if nargin >= 4 && ~isempty(germe)
            randn('seed', germe);
        end
        sigma = std(x) / rapport;
        xbruite = x + sigma * randn(1, n);
    end
end
