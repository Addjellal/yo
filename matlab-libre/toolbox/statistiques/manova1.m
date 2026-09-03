function [d, p, stats] = manova1(X, groupe, alpha)
%MANOVA1 Analyse de variance multivariée à un facteur.
%   D = MANOVA1(X,GROUPE) teste si les vecteurs moyens des groupes sont
%   égaux. X porte une variable par colonne, GROUPE le groupe de chaque
%   ligne. D est la dimension de l'espace où les moyennes diffèrent :
%   0 si elles sont toutes confondues, 1 si elles s'alignent sur une
%   droite, et ainsi de suite.
%
%   [D,P] = MANOVA1(...) rend les p-valeurs des tests successifs, la
%   K-ième jugeant l'hypothèse « la dimension vaut au plus K-1 ».
%   [D,P,STATS] = MANOVA1(...) rend les matrices de dispersion, le
%   lambda de Wilks, les valeurs et vecteurs propres canoniques.
%
%   Le test est celui de Wilks, dont la statistique est le rapport des
%   déterminants de la dispersion intra-groupe et de la dispersion
%   totale, avec l'approximation de Bartlett en khi-deux.
%
%   Exemple :
%      rng(1);
%      X = [randn(20, 2); randn(20, 2) + 2];
%      g = [ones(20, 1); 2 * ones(20, 1)];
%      [d, p] = manova1(X, g);
%
%   Voir aussi ANOVA1, ANOVAN, CANONCORR, MVNPDF.
    if nargin < 3 || isempty(alpha)
        alpha = 0.05;
    end
    X = double(X);
    [n, p0] = size(X);
    if iscell(groupe) || ischar(groupe) || isstring(groupe)
        [~, ~, indices] = unique(cellstr(groupe));
    else
        [~, ~, indices] = unique(double(groupe(:)));
    end
    k = max(indices);
    if k < 2
        error('stats:manova1:Groupes', 'Il faut au moins deux groupes.');
    end
    moyenneTotale = mean(X, 1);
    W = zeros(p0);          % dispersion intra-groupe
    B = zeros(p0);          % dispersion inter-groupes
    for c = 1:k
        bloc = X(indices == c, :);
        nc = size(bloc, 1);
        moyenne = mean(bloc, 1);
        ecarts = bloc - repmat(moyenne, nc, 1);
        W = W + ecarts.' * ecarts;
        difference = (moyenne - moyenneTotale).';
        B = B + nc * (difference * difference.');
    end
    T = W + B;
    ddlIntra = n - k;
    ddlInter = k - 1;
    % Les valeurs propres de W^-1 B mesurent la séparation dans chaque
    % direction canonique.
    [vecteurs, valeurs] = eig(B, W);
    valeurs = real(diag(valeurs));
    [valeurs, ordre] = sort(valeurs, 'descend');
    vecteurs = real(vecteurs(:, ordre));
    nombreTests = min(ddlInter, p0);
    p = zeros(nombreTests, 1);
    for s = 0:(nombreTests - 1)
        % Lambda de Wilks partiel : on retire les s premières directions.
        lambda = prod(1 ./ (1 + valeurs((s + 1):end)));
        facteur = ddlIntra + ddlInter - (p0 + ddlInter + 1) / 2;
        statistique = -facteur * log(max(lambda, realmin));
        ddl = (p0 - s) * (ddlInter - s);
        if ddl <= 0
            p(s + 1) = NaN;
        else
            p(s + 1) = 1 - chi2cdf(statistique, ddl);
        end
    end
    d = 0;
    for s = 1:numel(p)
        if p(s) <= alpha
            d = s;
        else
            break;
        end
    end
    lambdaGlobal = det(W) / max(det(T), realmin);
    stats = struct('W', W, 'B', B, 'T', T, 'dfW', ddlIntra, 'dfB', ddlInter, ...
                   'lambda', lambdaGlobal, 'eigenval', valeurs, ...
                   'eigenvec', vecteurs, 'canon', (X - repmat(moyenneTotale, n, 1)) * vecteurs, ...
                   'gmeans', zeros(k, p0), 'nlevels', k);
    for c = 1:k
        stats.gmeans(c, :) = mean(X(indices == c, :), 1);
    end
end
