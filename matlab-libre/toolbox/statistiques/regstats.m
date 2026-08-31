function sortie = regstats(y, X, modele, quoi)
%REGSTATS Régression linéaire et ses diagnostics.
%   S = REGSTATS(Y,X) ajuste Y = b0 + X*b par moindres carrés et rend une
%   structure portant tout ce qu'on demande d'ordinaire à une régression :
%
%      beta        les coefficients, le terme constant en tête ;
%      yhat        les valeurs ajustées ;
%      r           les résidus ;
%      mse         la variance résiduelle ;
%      rsquare     le coefficient de détermination ;
%      adjrsquare  le même, corrigé du nombre de variables ;
%      tstat       une sous-structure : erreurs types, t et p de chaque
%                  coefficient, plus leurs intervalles de confiance ;
%      fstat       le test global de nullité de tous les coefficients ;
%      covb        la covariance des coefficients ;
%      leverage    le levier de chaque observation — sa capacité à tirer
%                  la droite à elle ;
%      cookd       la distance de Cook : de combien l'ajustement change
%                  si l'on retire cette observation ;
%      dffits      l'effet de ce retrait sur la seule valeur ajustée ;
%      standres, studres  les résidus réduits, ordinaires et studentisés ;
%      dwstat      la statistique de Durbin-Watson, qui détecte
%                  l'autocorrélation des résidus.
%
%   S = REGSTATS(Y,X,MODELE) choisit la forme du modèle : 'linear'
%   (défaut), 'interaction' pour ajouter les produits croisés,
%   'quadratic' pour y ajouter les carrés, 'purequadratic' pour les
%   carrés sans les croisements.
%
%   S = REGSTATS(Y,X,MODELE,QUOI) où QUOI est un tableau de cellules de
%   noms ne calcule que ceux-là. Un seul nom, donné comme chaîne, rend
%   directement la valeur au lieu d'une structure.
%
%   Un levier proche de un, une distance de Cook supérieure à 4/N :
%   ce sont les observations à regarder de près avant de conclure.
%
%   Exemples :
%      x = (1:20)';
%      y = 2 * x + 1 + randn(20, 1);
%      s = regstats(y, x);
%      s.beta                       % proche de [1 ; 2]
%      s.rsquare
%      find(s.cookd > 4 / 20)       % les observations influentes
%
%      regstats(y, x, 'linear', 'rsquare')
%
%   Voir aussi REGRESS, FITLM, ROBUSTFIT, POLYFIT, ANOVA1.
    if nargin < 3 || isempty(modele)
        modele = 'linear';
    end
    if nargin < 4
        quoi = {};
    end
    y = y(:);
    if isvector(X) && numel(X) == numel(y)
        X = X(:);
    end
    A = matriceDuModele(X, lower(char(modele)));
    n = numel(y);
    p = size(A, 2);
    beta = A \ y;
    yhat = A * beta;
    r = y - yhat;
    ddl = n - p;
    mse = sum(r .^ 2) / max(ddl, 1);
    sct = sum((y - mean(y)) .^ 2);
    scr = sum(r .^ 2);
    if sct == 0
        rsquare = 1;
    else
        rsquare = 1 - scr / sct;
    end
    adjrsquare = 1 - (1 - rsquare) * (n - 1) / max(ddl, 1);
    covb = mse * inv(A' * A);
    erreurs = sqrt(abs(diag(covb)));
    t = beta ./ max(erreurs, eps);
    pValeurs = 2 * (1 - tcdf(abs(t), max(ddl, 1)));
    marge = tinv(0.975, max(ddl, 1)) * erreurs;
    % Le levier : la diagonale de la matrice chapeau, calculee par la
    % factorisation QR — on ne forme jamais la matrice n x n.
    [Q, ~] = qr(A, 0);
    levier = sum(Q .^ 2, 2);
    standres = r ./ max(sqrt(mse * (1 - levier)), eps);
    % Le residu studentise : la variance est reestimee sans l'observation.
    studres = zeros(n, 1);
    for i = 1:n
        variance = (scr - r(i) ^ 2 / max(1 - levier(i), eps)) / max(ddl - 1, 1);
        studres(i) = r(i) / max(sqrt(variance * (1 - levier(i))), eps);
    end
    cookd = (standres .^ 2 / p) .* (levier ./ max(1 - levier, eps));
    dffits = studres .* sqrt(levier ./ max(1 - levier, eps));
    F = (rsquare / max(p - 1, 1)) / ((1 - rsquare) / max(ddl, 1));
    dwstat = sum(diff(r) .^ 2) / max(scr, eps);

    sortie = struct('source', 'regstats', 'Q', Q, 'beta', beta, 'yhat', yhat, ...
                    'r', r, 'mse', mse, 'rsquare', rsquare, ...
                    'adjrsquare', adjrsquare, 'covb', covb, ...
                    'leverage', levier, 'hatdiag', levier, ...
                    'standres', standres, 'studres', studres, ...
                    'cookd', cookd, 'dffits', dffits, 'dwstat', dwstat, ...
                    'dfe', ddl, 'dfr', p - 1, 'sse', scr, 'sst', sct, ...
                    'tstat', struct('beta', beta, 'se', erreurs, 't', t, ...
                                    'pval', pValeurs, 'dfe', ddl, ...
                                    'ci', [beta - marge, beta + marge]), ...
                    'fstat', struct('f', F, 'pval', 1 - fcdf(F, max(p - 1, 1), ...
                                                             max(ddl, 1)), ...
                                    'dfr', p - 1, 'dfe', ddl, ...
                                    'sser', scr, 'ssr', sct - scr));
    if isempty(quoi)
        return;
    end
    if ischar(quoi) || isstring(quoi)
        sortie = sortie.(char(quoi));
        return;
    end
    reduite = struct();
    for i = 1:numel(quoi)
        nom = char(quoi{i});
        reduite.(nom) = sortie.(nom);
    end
    sortie = reduite;
end

function A = matriceDuModele(X, modele)
%MATRICEDUMODELE La matrice de plan, terme constant en première colonne.
    n = size(X, 1);
    p = size(X, 2);
    A = [ones(n, 1), X];
    switch modele
        case {'linear', 'l'}
            % rien de plus
        case {'interaction', 'i'}
            for i = 1:p - 1
                for j = i + 1:p
                    A = [A, X(:, i) .* X(:, j)];        %#ok<AGROW>
                end
            end
        case {'purequadratic', 'p'}
            A = [A, X .^ 2];
        case {'quadratic', 'q'}
            for i = 1:p - 1
                for j = i + 1:p
                    A = [A, X(:, i) .* X(:, j)];        %#ok<AGROW>
                end
            end
            A = [A, X .^ 2];
        otherwise
            error('stats:regstats:BadModel', 'Unknown model ''%s''.', modele);
    end
end
