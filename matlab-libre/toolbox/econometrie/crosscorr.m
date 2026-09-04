function [correlations, retards, bornes] = crosscorr(x, y, retardMaximal, nombreEcartsTypes)
%CROSSCORR Corrélation croisée de deux séries.
%   [XCF,LAGS] = CROSSCORR(X,Y) rend la corrélation croisée pour des
%   retards allant de -20 à 20, ou de -(N-1) à N-1 si la série est plus
%   courte. XCF(k) mesure la liaison entre X(t) et Y(t+LAGS(k)) : un pic
%   à un retard positif dit que X précède Y.
%
%   CROSSCORR(X,Y,NUMLAGS) borne le retard, CROSSCORR(X,Y,NUMLAGS,NUMSTD)
%   règle les bornes de confiance, rendues en troisième sortie et
%   valant NUMSTD sur racine de N (deux par défaut).
%
%   Sans sortie demandée, la corrélation est tracée avec ses bornes.
%
%   Exemple :
%      x = randn(1, 200);
%      y = [0 0 0 x(1:end-3)];        % y suit x de trois pas
%      [xcf, lags] = crosscorr(x, y);
%      [~, k] = max(xcf);
%      lags(k)                        % 3
%
%   Voir aussi AUTOCORR, PARCORR, XCORR, LAGMATRIX.
    x = double(x(:));
    y = double(y(:));
    n = numel(x);
    if numel(y) ~= n
        error('econ:crosscorr:Tailles', ...
              'Les deux séries doivent avoir la même longueur.');
    end
    if nargin < 3 || isempty(retardMaximal)
        retardMaximal = min(20, n - 1);
    end
    if nargin < 4 || isempty(nombreEcartsTypes), nombreEcartsTypes = 2; end
    retardMaximal = min(round(retardMaximal), n - 1);
    retards = (-retardMaximal:retardMaximal).';
    xCentre = x - mean(x);
    yCentre = y - mean(y);
    normalisation = sqrt(sum(xCentre .^ 2) * sum(yCentre .^ 2));
    correlations = zeros(numel(retards), 1);
    for k = 1:numel(retards)
        d = retards(k);
        if d >= 0
            produit = sum(xCentre(1:(n - d)) .* yCentre((1 + d):n));
        else
            produit = sum(xCentre((1 - d):n) .* yCentre(1:(n + d)));
        end
        if normalisation > 0
            correlations(k) = produit / normalisation;
        end
    end
    bornes = nombreEcartsTypes / sqrt(n) * [1; -1];
    if nargout == 0
        stem(retards, correlations, 'filled');
        hold on;
        plot(retards([1 end]), [bornes(1) bornes(1)], 'r--');
        plot(retards([1 end]), [bornes(2) bornes(2)], 'r--');
        hold off;
        xlabel('Retard');
        ylabel('Corrélation croisée');
        title('Corrélation croisée');
        clear correlations retards bornes
    end
end
