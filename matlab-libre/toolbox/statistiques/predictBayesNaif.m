function [etiquettes, scores] = predictBayesNaif(modele, X)
%PREDICTBAYESNAIF Prédiction d'un classifieur bayésien naïf.
%   Employer PREDICT ; cette fonction est le rouage qu'il appelle.
    X = double(X);
    n = size(X, 1);
    k = numel(modele.Classes);
    logScores = zeros(n, k);
    for c = 1:k
        logScores(:, c) = log(max(modele.Prior(c), eps));
        switch modele.Distribution
            case 'normal'
                mu = repmat(modele.Mu(c, :), n, 1);
                sigma = repmat(modele.Sigma(c, :), n, 1);
                logScores(:, c) = logScores(:, c) + ...
                    sum(-0.5 * log(2 * pi * sigma .^ 2) - ...
                        (X - mu) .^ 2 ./ (2 * sigma .^ 2), 2);
            case 'kernel'
                bloc = modele.Echantillons{c};
                for j = 1:size(X, 2)
                    densite = ksdensity(bloc(:, j), X(:, j));
                    logScores(:, c) = logScores(:, c) + log(max(densite(:), eps));
                end
            case 'mn'
                logScores(:, c) = logScores(:, c) + ...
                    X * log(max(modele.Frequences(c, :), eps)).';
            otherwise
                error('stats:fitcnb:Distribution', ...
                      'Loi inconnue : %s.', modele.Distribution);
        end
    end
    % Les scores rendus sont des probabilités a posteriori, calculées
    % sans quitter les logarithmes.
    maximum = max(logScores, [], 2);
    exponentielles = exp(logScores - repmat(maximum, 1, k));
    scores = exponentielles ./ repmat(sum(exponentielles, 2), 1, k);
    [~, choix] = max(scores, [], 2);
    etiquettes = modele.Classes(choix);
end
