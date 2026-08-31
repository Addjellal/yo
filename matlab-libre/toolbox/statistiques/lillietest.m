function [h, p, statistique, critique] = lillietest(x, varargin)
%LILLIETEST Test de normalité de Lilliefors.
%   H = LILLIETEST(X) teste l'hypothèse « X suit une loi normale, de
%   moyenne et de variance quelconques ». C'est le test de
%   Kolmogorov-Smirnov appliqué après avoir estimé ces deux paramètres
%   sur l'échantillon lui-même.
%
%   Cette estimation change tout : la statistique est plus petite qu'elle
%   ne le serait avec les vrais paramètres, puisque la normale ajustée
%   colle par construction aux données. Employer la table de
%   Kolmogorov-Smirnov ordinaire ferait donc conclure à la normalité
%   beaucoup trop souvent. Lilliefors a établi la bonne loi ; MatLibre la
%   retrouve par simulation, avec un germe fixé.
%
%   [H,P] = LILLIETEST(...) rend la probabilité critique.
%   [H,P,D] = LILLIETEST(...) rend la statistique de Kolmogorov-Smirnov.
%   [H,P,D,CV] = LILLIETEST(...) rend la valeur critique.
%
%   LILLIETEST(...,'Alpha',A) change le seuil, 0.05 par défaut.
%   LILLIETEST(...,'Distr',D) change la loi testée : 'norm' (défaut),
%   'exp' pour l'exponentielle, 'ev' pour la loi des valeurs extrêmes.
%
%   Exemples :
%      lillietest(randn(200, 1))         % 0 : normal
%      lillietest(exprnd(1, 200, 1))     % 1 : ce n'est pas normal
%      lillietest(exprnd(1, 200, 1), 'Distr', 'exp')   % 0 : c'est exponentiel
%
%   Voir aussi KSTEST, KSTEST2, JBTEST, CHI2GOF, NORMFIT.
    alpha = 0.05;
    loi = 'norm';
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        if strcmp(nom, 'alpha')
            alpha = varargin{k + 1};
        elseif strcmp(nom, 'distr') || strcmp(nom, 'distribution')
            loi = lower(char(varargin{k + 1}));
        elseif strcmp(nom, 'mctol')
            % accepté et sans effet : le nombre de tirages est fixe
        else
            error('stats:lillietest:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    x = x(:);
    x = x(~isnan(x));
    n = numel(x);
    if n < 4
        error('stats:lillietest:NotEnoughData', ...
              'LILLIETEST needs at least four values.');
    end
    statistique = distanceLilliefors(x, loi);
    etat = rng();
    rng(20240119);
    tirages = 5000;
    simulees = zeros(tirages, 1);
    for i = 1:tirages
        switch loi
            case 'norm'
                z = randn(n, 1);
            case 'exp'
                z = exprnd(1, n, 1);
            case 'ev'
                z = evrnd(0, 1, n, 1);
            otherwise
                rng(etat);
                error('stats:lillietest:BadDistr', ...
                      'The distribution must be ''norm'', ''exp'' or ''ev''.');
        end
        simulees(i) = distanceLilliefors(z, loi);
    end
    rng(etat);
    p = sum(simulees >= statistique) / tirages;
    p = max(p, 1 / tirages);
    critique = prctile(simulees, 100 * (1 - alpha));
    h = double(statistique > critique);
end

function d = distanceLilliefors(x, loi)
%DISTANCELILLIEFORS La distance de Kolmogorov à la loi ajustée.
    x = sort(x(:));
    n = numel(x);
    switch loi
        case 'norm'
            m = mean(x);
            s = std(x);
            if s == 0
                d = 0;
                return;
            end
            F = normcdf((x - m) / s);
        case 'exp'
            m = mean(x);
            if m <= 0
                d = 0;
                return;
            end
            F = expcdf(x, m);
        case 'ev'
            parametres = evfitSimple(x);
            F = evcdf(x, parametres(1), parametres(2));
        otherwise
            error('stats:lillietest:BadDistr', 'Unknown distribution.');
    end
    % La répartition empirique saute en chaque point : la distance se
    % mesure des deux côtés du saut.
    dessus = (1:n)' / n - F;
    dessous = F - (0:n - 1)' / n;
    d = max(max(dessus), max(dessous));
end

function parametres = evfitSimple(x)
%EVFITSIMPLE Ajustement rapide d'une loi des valeurs extrêmes.
%   Les moments suffisent ici : l'écart type d'une loi de Gumbel vaut
%   sigma*pi/racine(6), et sa moyenne mu - gamma*sigma.
    sigma = std(x) * sqrt(6) / pi;
    if sigma <= 0
        sigma = 1;
    end
    mu = mean(x) + 0.5772156649015329 * sigma;
    parametres = [mu, sigma];
end
