function [p, h, statistiques] = signtest(x, y, alpha)
%SIGNTEST Test du signe sur la médiane.
%   P = SIGNTEST(X) teste l'hypothèse « la médiane de X est nulle » en ne
%   regardant que le signe des observations : combien sont positives,
%   combien négatives. Sous l'hypothèse, ce nombre suit une loi binomiale
%   de paramètre un demi.
%
%   P = SIGNTEST(X,Y) teste que la médiane de X-Y est nulle, sur
%   échantillons appariés. Si Y est un scalaire, il teste que la médiane
%   de X vaut Y.
%
%   [P,H] = SIGNTEST(...) rend aussi la décision : H vaut 1 quand
%   l'hypothèse est rejetée au seuil ALPHA, 0.05 par défaut.
%   [P,H,STATS] = SIGNTEST(...) rend le nombre d'observations positives.
%
%   C'est le test le moins exigeant de tous : il ne suppose rien sur la
%   forme de la loi, pas même la symétrie que demande SIGNRANK. En
%   contrepartie, il détecte moins bien un écart réel, puisqu'il jette
%   l'amplitude des observations pour n'en garder que le signe.
%
%   Les observations nulles sont écartées, comme le veut la convention.
%
%   Exemples :
%      signtest([-2 -1 1 2])            % 1 : deux de chaque cote
%      signtest([1 2 3 4 5 6 7 8])      % 0.0078 : toutes positives
%      signtest([10 11 12], 11)         % teste la mediane 11
%
%   Voir aussi SIGNRANK, TTEST, RANKSUM, MEDIAN, BINOCDF.
    if nargin < 2 || isempty(y)
        y = zeros(size(x));
    end
    if nargin < 3 || isempty(alpha)
        alpha = 0.05;
    end
    x = x(:);
    if isscalar(y)
        d = x - y;
    else
        y = y(:);
        if numel(y) ~= numel(x)
            error('stats:signtest:InputSizeMismatch', ...
                  'X and Y must have the same number of elements.');
        end
        d = x - y;
    end
    d = d(~isnan(d));
    d = d(d ~= 0);
    n = numel(d);
    if n == 0
        p = 1;
        h = false;
        statistiques = struct('sign', 0, 'zval', 0, 'n', 0);
        return;
    end
    positives = sum(d > 0);
    % Test bilatéral exact : deux fois la queue la plus petite, plafonné
    % à un.
    if positives < n / 2
        p = 2 * binocdf(positives, n, 0.5);
    elseif positives > n / 2
        p = 2 * (1 - binocdf(positives - 1, n, 0.5));
    else
        p = 1;
    end
    p = min(1, p);
    h = p < alpha;
    z = (positives - n / 2) / sqrt(n / 4);
    statistiques = struct('sign', positives, 'zval', z, 'n', n);
end
