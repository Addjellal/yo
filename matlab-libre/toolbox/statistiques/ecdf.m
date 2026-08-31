function [f, x, borneBasse, borneHaute] = ecdf(y, varargin)
%ECDF Fonction de répartition empirique.
%   [F,X] = ECDF(Y) rend la répartition empirique de l'échantillon Y :
%   F(k) est la proportion d'observations inférieures ou égales à X(k).
%   C'est l'escalier qui monte de 0 à 1, d'une marche de 1/N à chaque
%   observation distincte.
%
%   Le premier point est toujours (X(1), 0) avec X(1) la plus petite
%   observation : l'escalier part de zéro, comme le veut MATLAB, de sorte
%   que STAIRS(X,F) trace la marche complète.
%
%   [F,X,LO,UP] = ECDF(Y) rend en outre les bornes d'un intervalle de
%   confiance à 95 pour cent, calculé point par point par la formule de
%   Greenwood ramenée au cas sans censure.
%
%   ECDF(...,'alpha',A) change le niveau : A = 0.01 pour 99 pour cent.
%
%   ECDF(Y) sans sortie demandée trace directement l'escalier.
%
%   Exemples :
%      [f, x] = ecdf([3 1 4 1 5]);
%      [x, f]                  % l'escalier, points et hauteurs
%      ecdf(randn(200, 1));    % la courbe en S de la loi normale
%
%   Voir aussi CDF, NORMCDF, HISTCOUNTS, KSDENSITY, STAIRS, KSTEST.
    alpha = 0.05;
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        if strcmp(nom, 'alpha')
            alpha = varargin{k + 1};
        elseif strcmp(nom, 'function') || strcmp(nom, 'bounds') || ...
               strcmp(nom, 'censoring') || strcmp(nom, 'frequency')
            % acceptés et sans effet : MatLibre ne traite que la
            % répartition d'un échantillon complet
        else
            error('stats:ecdf:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    y = y(:);
    y = y(~isnan(y));
    if isempty(y)
        error('stats:ecdf:NotEnoughData', 'ECDF needs at least one observation.');
    end
    y = sort(y);
    n = numel(y);
    distincts = unique(y);
    distincts = distincts(:);
    f = zeros(numel(distincts) + 1, 1);
    x = zeros(numel(distincts) + 1, 1);
    x(1) = distincts(1);
    for i = 1:numel(distincts)
        x(i + 1) = distincts(i);
        f(i + 1) = sum(y <= distincts(i)) / n;
    end
    % Greenwood sans censure : la variance de F vaut F(1-F)/n.
    z = norminv(1 - alpha / 2);
    ecart = sqrt(f .* (1 - f) / n);
    borneBasse = max(0, f - z * ecart);
    borneHaute = min(1, f + z * ecart);
    if nargout == 0
        stairs(x, f);
        xlabel('x');
        ylabel('F(x)');
        title('Repartition empirique');
        clear f;
    end
end
