function H = probplot(loi, y, varargin)
%PROBPLOT Diagramme de probabilité pour une loi quelconque.
%   PROBPLOT(Y) place les observations de Y en regard des quantiles de la
%   loi normale, comme NORMPLOT.
%
%   PROBPLOT(LOI,Y) emploie une autre loi de référence. LOI est un nom :
%   'normal', 'lognormal', 'exponential', 'weibull', 'extreme value',
%   'rayleigh', 'logistic', 'uniform'. Les points s'alignent si Y suit
%   cette loi.
%
%   PROBPLOT(LOI,Y,CENSURE,FREQUENCE) accepte les arguments de MATLAB
%   pour les données censurées et pondérées ; MatLibre les reçoit et
%   n'en tient pas compte.
%
%   H = PROBPLOT(...) rend les poignées des traits.
%
%   La droite est celle qui passe par les premier et troisième
%   quartiles : elle représente la loi ajustée sans être influencée par
%   les extrêmes, ce qui laisse voir les écarts en bout de queue.
%
%   Les positions de tracé sont celles de MATLAB, (i-0.5)/n : elles
%   évitent que la plus grande observation soit placée à la probabilité
%   un, qui n'a pas de quantile fini.
%
%   Exemples :
%      probplot(randn(200, 1));
%      probplot('exponential', exprnd(2, 200, 1));   % aligne
%      probplot('weibull', wblrnd(1, 2, 200, 1));    % aligne aussi
%      probplot('normal', exprnd(1, 200, 1));        % ne s'aligne pas
%
%   Voir aussi NORMPLOT, HISTFIT, ECDF, LILLIETEST, KSTEST.
    if nargin == 1
        y = loi;
        loi = 'normal';
    elseif ~(ischar(loi) || isstring(loi))
        varargin = [{y}, varargin];
        y = loi;
        loi = 'normal';
    end
    nom = lower(char(loi));
    if isvector(y)
        colonnes = {y(:)};
    else
        colonnes = cell(size(y, 2), 1);
        for j = 1:size(y, 2)
            colonnes{j} = y(:, j);
        end
    end

    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    hold('on');
    H = [];
    for j = 1:numel(colonnes)
        v = sort(colonnes{j}(~isnan(colonnes{j})));
        n = numel(v);
        if n < 2
            continue;
        end
        probabilites = ((1:n)' - 0.5) / n;
        [abscisses, quantiles] = transformer(nom, v, probabilites);
        H(end + 1) = plot(abscisses, quantiles, '+');    %#ok<AGROW>
        % La droite des quartiles : deux points suffisent à la définir.
        q = [0.25; 0.75];
        [xq, yq] = transformer(nom, [prctile(v, 25); prctile(v, 75)], q);
        if xq(2) ~= xq(1)
            pente = (yq(2) - yq(1)) / (xq(2) - xq(1));
            bornes = [min(abscisses), max(abscisses)];
            H(end + 1) = plot(bornes, yq(1) + pente * (bornes - xq(1)), 'r--');  %#ok<AGROW>
        end
    end
    if ~aEffacer
        hold('off');
    end
    xlabel('donnees');
    ylabel('probabilite');
    title(sprintf('Diagramme de probabilite : %s', nom));
    % Les graduations en probabilité, aux valeurs usuelles.
    reperes = [0.01 0.05 0.10 0.25 0.50 0.75 0.90 0.95 0.99];
    [~, positions] = transformer(nom, ones(numel(reperes), 1), reperes(:));
    etiquettes = cell(numel(reperes), 1);
    for i = 1:numel(reperes)
        etiquettes{i} = num2str(reperes(i));
    end
    yticks(positions');
    yticklabels(etiquettes);
    if nargout == 0
        clear H;
    end
end

function [abscisses, quantiles] = transformer(nom, v, probabilites)
%TRANSFORMER Les deux axes du diagramme, selon la loi de référence.
%   L'abscisse est l'observation, éventuellement transformée pour que la
%   loi devienne une loi de position et d'échelle ; l'ordonnée est le
%   quantile de cette loi réduite.
    switch nom
        case {'normal', 'norm'}
            abscisses = v;
            quantiles = norminv(probabilites);
        case {'lognormal', 'logn'}
            abscisses = log(max(v, realmin));
            quantiles = norminv(probabilites);
        case {'exponential', 'exp'}
            abscisses = v;
            quantiles = -log(1 - probabilites);
        case {'weibull', 'wbl'}
            abscisses = log(max(v, realmin));
            quantiles = log(-log(1 - probabilites));
        case {'extreme value', 'ev'}
            abscisses = v;
            quantiles = log(-log(1 - probabilites));
        case {'rayleigh', 'rayl'}
            abscisses = v;
            quantiles = sqrt(-2 * log(1 - probabilites));
        case 'logistic'
            abscisses = v;
            quantiles = log(probabilites ./ (1 - probabilites));
        case {'uniform', 'unif'}
            abscisses = v;
            quantiles = probabilites;
        otherwise
            error('stats:probplot:BadDistribution', ...
                  'Unknown distribution ''%s''.', nom);
    end
end
