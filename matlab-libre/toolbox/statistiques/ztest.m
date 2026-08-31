function [h, p, ci, zvaleur] = ztest(x, m, sigma, varargin)
%ZTEST Test sur la moyenne, l'écart type étant connu.
%   H = ZTEST(X,M,SIGMA) teste l'hypothèse « la moyenne de X vaut M »
%   quand l'écart type de la population, SIGMA, est connu — non estimé
%   sur l'échantillon. H vaut 1 si l'hypothèse est rejetée au seuil de
%   5 pour cent, 0 sinon.
%
%   [H,P] = ZTEST(...) rend la probabilité critique.
%   [H,P,CI] = ZTEST(...) rend l'intervalle de confiance de la moyenne.
%   [H,P,CI,Z] = ZTEST(...) rend la statistique du test,
%
%      Z = (moyenne(X) - M) / (SIGMA / racine(N))
%
%   ZTEST(...,'Alpha',A) change le seuil.
%   ZTEST(...,'Tail',T) choisit le côté testé : 'both' (défaut), 'right'
%   pour l'hypothèse « la moyenne dépasse M », 'left' pour l'inverse.
%
%   Quand SIGMA n'est pas connu — le cas ordinaire —, c'est TTEST qu'il
%   faut employer : il l'estime, et paie cette estimation par une loi de
%   Student au lieu d'une normale.
%
%   Exemples :
%      x = [102 100 104 99 101];
%      [h, p] = ztest(x, 100, 2)         % l'ecart type est connu : 2
%      ztest(x, 100, 2, 'Tail', 'right')
%
%   Voir aussi TTEST, TTEST2, VARTEST, SIGNTEST, NORMCDF.
    alpha = 0.05;
    cote = 'both';
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        if strcmp(nom, 'alpha')
            alpha = varargin{k + 1};
        elseif strcmp(nom, 'tail')
            cote = lower(char(varargin{k + 1}));
        elseif strcmp(nom, 'dim')
            % accepté et sans effet : MatLibre traite l'échantillon entier
        else
            error('stats:ztest:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    x = x(:);
    x = x(~isnan(x));
    n = numel(x);
    if n == 0 || sigma <= 0
        error('stats:ztest:NotEnoughData', ...
              'ZTEST needs data and a positive standard deviation.');
    end
    erreurType = sigma / sqrt(n);
    zvaleur = (mean(x) - m) / erreurType;
    switch cote
        case 'both'
            p = 2 * (1 - normcdf(abs(zvaleur)));
            marge = norminv(1 - alpha / 2) * erreurType;
            ci = [mean(x) - marge, mean(x) + marge];
        case 'right'
            p = 1 - normcdf(zvaleur);
            ci = [mean(x) - norminv(1 - alpha) * erreurType, Inf];
        case 'left'
            p = normcdf(zvaleur);
            ci = [-Inf, mean(x) + norminv(1 - alpha) * erreurType];
        otherwise
            error('stats:ztest:BadTail', ...
                  'The tail must be ''both'', ''right'' or ''left''.');
    end
    h = double(p < alpha);
end
