function [h, p, statistique] = kstest2(x1, x2, varargin)
%KSTEST2 Kolmogorov-Smirnov à deux échantillons.
%   H = KSTEST2(X1,X2) teste l'hypothèse « X1 et X2 sont tirés de la même
%   loi ». La statistique est la plus grande distance verticale entre
%   leurs deux répartitions empiriques :
%
%      D = max |F1(x) - F2(x)|
%
%   H vaut 1 si l'hypothèse est rejetée au seuil de 5 pour cent.
%
%   [H,P] = KSTEST2(...) rend la probabilité critique, calculée par la
%   série asymptotique de Kolmogorov avec l'effectif effectif
%   n1*n2/(n1+n2).
%   [H,P,D] = KSTEST2(...) rend la statistique elle-même.
%
%   KSTEST2(...,'Alpha',A) change le seuil.
%   KSTEST2(...,'Tail',T) choisit le côté : 'unequal' (défaut) pour une
%   différence quelconque, 'larger' pour « F1 est au-dessus de F2 »,
%   'smaller' pour l'inverse.
%
%   Le test ne suppose rien sur la forme des lois, et détecte aussi bien
%   un décalage qu'un changement de dispersion ou de forme. C'est ce qui
%   fait sa souplesse et sa faiblesse : il est moins puissant qu'un test
%   dirigé vers un écart précis.
%
%   Exemples :
%      kstest2(randn(100,1), randn(100,1))          % 0 : meme loi
%      kstest2(randn(100,1), randn(100,1) + 2)      % 1 : decalees
%      kstest2(randn(100,1), randn(100,1) * 3)      % 1 : dispersions
%
%   Voir aussi KSTEST, ECDF, RANKSUM, TTEST2, LILLIETEST.
    alpha = 0.05;
    cote = 'unequal';
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        if strcmp(nom, 'alpha')
            alpha = varargin{k + 1};
        elseif strcmp(nom, 'tail')
            cote = lower(char(varargin{k + 1}));
        else
            error('stats:kstest2:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    x1 = x1(:);
    x2 = x2(:);
    x1 = sort(x1(~isnan(x1)));
    x2 = sort(x2(~isnan(x2)));
    n1 = numel(x1);
    n2 = numel(x2);
    if n1 == 0 || n2 == 0
        error('stats:kstest2:NotEnoughData', 'Both samples must be non-empty.');
    end
    % Les deux répartitions évaluées aux mêmes abscisses : l'union des
    % observations. La plus grande distance est atteinte en l'un de ces
    % points, les répartitions étant constantes entre eux.
    points = sort([x1; x2]);
    F1 = zeros(numel(points), 1);
    F2 = zeros(numel(points), 1);
    for i = 1:numel(points)
        F1(i) = sum(x1 <= points(i)) / n1;
        F2(i) = sum(x2 <= points(i)) / n2;
    end
    switch cote
        case {'unequal', 'both'}
            statistique = max(abs(F1 - F2));
        case 'larger'
            statistique = max(F1 - F2);
        case 'smaller'
            statistique = max(F2 - F1);
        otherwise
            error('stats:kstest2:BadTail', ...
                  'The tail must be ''unequal'', ''larger'' or ''smaller''.');
    end
    statistique = max(statistique, 0);
    ne = n1 * n2 / (n1 + n2);
    lambda = max(0, (sqrt(ne) + 0.12 + 0.11 / sqrt(ne)) * statistique);
    if strcmp(cote, 'unequal') || strcmp(cote, 'both')
        p = matlibre_kolmogorov_queue(lambda);
    else
        % Test unilatéral : la loi limite est exp(-2 lambda^2).
        p = exp(-2 * lambda ^ 2);
    end
    p = max(0, min(1, p));
    h = double(p < alpha);
end
