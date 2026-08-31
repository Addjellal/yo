function H = histfit(x, nombreClasses, loi)
%HISTFIT Histogramme et densité ajustée.
%   HISTFIT(X) trace l'histogramme de X et, par-dessus, la densité de la
%   loi normale ajustée sur les mêmes données. C'est le moyen le plus
%   court de juger de l'œil si une loi convient.
%
%   HISTFIT(X,NBINS) fixe le nombre de classes. Sans lui, MatLibre en
%   prend la racine carrée du nombre d'observations, comme MATLAB.
%
%   HISTFIT(X,NBINS,LOI) ajuste une autre loi : 'normal' (défaut),
%   'lognormal', 'exponential', 'weibull', 'gamma', 'rayleigh', 'kernel'
%   pour une densité estimée par noyau.
%
%   H = HISTFIT(...) rend les poignées : l'histogramme d'abord, la courbe
%   ensuite.
%
%   La densité est mise à l'échelle de l'histogramme — multipliée par le
%   nombre d'observations et par la largeur des classes — de sorte que
%   les deux se superposent.
%
%   Exemples :
%      histfit(randn(500, 1));
%      histfit(exprnd(2, 500, 1), 20, 'exponential');
%      histfit(wblrnd(1, 2, 500, 1), 20, 'weibull');
%      histfit(randn(300, 1), 15, 'kernel');
%
%   Voir aussi HISTOGRAM, NORMPLOT, PROBPLOT, KSDENSITY, NORMFIT.
    x = x(:);
    x = x(~isnan(x));
    n = numel(x);
    if n < 2
        error('stats:histfit:NotEnoughData', 'HISTFIT needs at least two values.');
    end
    if nargin < 2 || isempty(nombreClasses)
        nombreClasses = ceil(sqrt(n));
    end
    if nargin < 3 || isempty(loi)
        loi = 'normal';
    end
    nom = lower(char(loi));

    [effectifs, bords] = histcounts(x, nombreClasses);
    centres = (bords(1:end - 1) + bords(2:end)) / 2;
    largeur = bords(2) - bords(1);

    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    H = bar(centres, effectifs);
    hold('on');
    t = linspace(min(bords), max(bords), 200)';
    densite = ajuster(nom, x, t);
    H(end + 1) = plot(t, densite * n * largeur, 'r', 'LineWidth', 2);
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end

function densite = ajuster(nom, x, t)
%AJUSTER La densité de la loi nommée, ajustée sur X, évaluée en T.
    switch nom
        case {'normal', 'norm'}
            [m, s] = normfit(x);
            densite = normpdf(t, m, s);
        case {'lognormal', 'logn'}
            positifs = x(x > 0);
            m = mean(log(positifs));
            s = std(log(positifs));
            densite = zeros(size(t));
            garde = t > 0;
            densite(garde) = lognpdf(t(garde), m, s);
        case {'exponential', 'exp'}
            densite = exppdf(t, mean(x));
        case {'weibull', 'wbl'}
            parametres = wblfit(x(x > 0));
            densite = zeros(size(t));
            garde = t > 0;
            densite(garde) = wblpdf(t(garde), parametres(1), parametres(2));
        case {'gamma', 'gam'}
            parametres = gamfit(x(x > 0));
            densite = zeros(size(t));
            garde = t > 0;
            densite(garde) = gampdf(t(garde), parametres(1), parametres(2));
        case {'rayleigh', 'rayl'}
            parametre = raylfit(x(x > 0));
            densite = zeros(size(t));
            garde = t > 0;
            densite(garde) = raylpdf(t(garde), parametre);
        case 'kernel'
            densite = ksdensity(x, t);
            densite = densite(:);
        otherwise
            error('stats:histfit:BadDistribution', ...
                  'Unknown distribution ''%s''.', nom);
    end
    densite = densite(:);
end
