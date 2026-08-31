function [b, se, pval, garde, statistiques] = stepwisefit(X, y, varargin)
%STEPWISEFIT Régression pas à pas : quelles variables garder ?
%   [B,SE,PVAL,INMODEL] = STEPWISEFIT(X,Y) construit une régression en
%   ajoutant et retirant des variables une à une : à chaque pas, il
%   ajoute celle qui apporte le plus, si elle apporte assez, et retire
%   celle qui n'apporte plus assez. Il s'arrête quand plus rien ne bouge.
%
%   B donne le coefficient de chaque colonne de X — celui qu'elle aurait
%   si on l'ajoutait au modèle courant, pour celles qui n'y sont pas.
%   INMODEL dit lesquelles ont été retenues. SE et PVAL sont l'erreur
%   type et la probabilité critique de chaque coefficient.
%
%   [...,STATS] = STEPWISEFIT(...) rend le détail du modèle final : le
%   terme constant, la variance résiduelle, le R carré, la statistique de
%   Fisher.
%
%   STEPWISEFIT(...,'penter',P) fixe le seuil d'entrée, 0.05 par défaut.
%   STEPWISEFIT(...,'premove',P) fixe le seuil de sortie, 0.10 par
%   défaut. Le second doit dépasser le premier, faute de quoi la
%   procédure peut boucler en ajoutant et retirant sans fin la même
%   variable.
%   STEPWISEFIT(...,'inmodel',V) part d'un modèle donné plutôt que du
%   modèle vide.
%   STEPWISEFIT(...,'display','off') n'affiche rien ; c'est le défaut de
%   MatLibre.
%
%   La sélection pas à pas est commode et trompeuse : les probabilités
%   critiques du modèle final ne valent plus, puisqu'on a choisi les
%   variables en les regardant. Elle sert à explorer, non à conclure.
%
%   Exemples :
%      X = randn(100, 5);
%      y = 3 * X(:,2) - 2 * X(:,4) + randn(100, 1);
%      [b, se, p, garde] = stepwisefit(X, y);
%      find(garde)                  % 2 et 4 y sont toujours ; une autre
%                                   % s'y glisse parfois, c'est le defaut
%                                   % de la methode
%      [b(2), b(4)]                 % proches de 3 et -2
%
%      % Un seuil d'entree plus severe ecarte les fausses trouvailles
%      [~, ~, ~, severe] = stepwisefit(X, y, 'penter', 0.01, 'premove', 0.05);
%
%   Voir aussi REGRESS, REGSTATS, FITLM, RIDGE, LASSO.
    seuilEntree = 0.05;
    seuilSortie = 0.10;
    garde = [];
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'penter'
                seuilEntree = varargin{k + 1};
            case 'premove'
                seuilSortie = varargin{k + 1};
            case 'inmodel'
                garde = logical(varargin{k + 1});
            case {'display', 'maxiter', 'scale', 'keep'}
                % acceptés et sans effet
            otherwise
                error('stats:stepwisefit:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    if seuilSortie <= seuilEntree
        error('stats:stepwisefit:BadThresholds', ...
              'PREMOVE must be larger than PENTER.');
    end
    y = y(:);
    n = numel(y);
    p = size(X, 2);
    if isempty(garde)
        garde = false(1, p);
    end
    garde = logical(garde(:)');

    for pas = 1:100 * p
        % Que vaudrait chaque variable si on l'ajoutait ou la retirait ?
        valeursP = probabilitesCandidates(X, y, garde);
        change = false;
        % D'abord retirer : la plus mauvaise des variables retenues.
        dedans = find(garde);
        if ~isempty(dedans)
            [pire, rang] = max(valeursP(dedans));
            if pire > seuilSortie
                garde(dedans(rang)) = false;
                change = true;
            end
        end
        if ~change
            dehors = find(~garde);
            if ~isempty(dehors)
                [meilleure, rang] = min(valeursP(dehors));
                if meilleure < seuilEntree
                    garde(dehors(rang)) = true;
                    change = true;
                end
            end
        end
        if ~change
            break;
        end
    end

    % Les coefficients rendus : ceux du modèle final pour les variables
    % retenues, ceux qu'elles auraient en entrant pour les autres.
    b = zeros(p, 1);
    se = zeros(p, 1);
    pval = ones(p, 1);
    for j = 1:p
        colonnes = garde;
        colonnes(j) = true;
        A = [ones(n, 1), X(:, colonnes)];
        coefficients = A \ y;
        r = y - A * coefficients;
        ddl = max(n - size(A, 2), 1);
        mse = sum(r .^ 2) / ddl;
        covariance = mse * inv(A' * A);
        erreurs = sqrt(abs(diag(covariance)));
        rang = 1 + sum(colonnes(1:j));
        b(j) = coefficients(rang);
        se(j) = erreurs(rang);
        pval(j) = 2 * (1 - tcdf(abs(b(j) / max(se(j), eps)), ddl));
    end

    A = [ones(n, 1), X(:, garde)];
    coefficients = A \ y;
    r = y - A * coefficients;
    ddl = max(n - size(A, 2), 1);
    mse = sum(r .^ 2) / ddl;
    scr = sum(r .^ 2);
    sct = sum((y - mean(y)) .^ 2);
    rsquare = 1;
    if sct > 0
        rsquare = 1 - scr / sct;
    end
    ddlModele = max(size(A, 2) - 1, 1);
    F = (rsquare / ddlModele) / max((1 - rsquare) / ddl, eps);
    statistiques = struct('intercept', coefficients(1), 'rmse', sqrt(mse), ...
                          'mse', mse, 'rsq', rsquare, 'df0', ddlModele, ...
                          'dfe', ddl, 'fstat', F, ...
                          'pval', 1 - fcdf(F, ddlModele, ddl), ...
                          'SSresid', scr, 'SStotal', sct, 'B', b, 'SE', se, ...
                          'TSTAT', b ./ max(se, eps), 'PVAL', pval, ...
                          'source', 'stepwisefit');
end

function valeursP = probabilitesCandidates(X, y, garde)
%PROBABILITESCANDIDATES La probabilité critique de chaque variable.
%   Pour une variable retenue, c'est la sienne dans le modèle courant ;
%   pour une variable exclue, celle qu'elle aurait si on l'ajoutait.
    n = numel(y);
    p = size(X, 2);
    valeursP = ones(1, p);
    for j = 1:p
        colonnes = garde;
        colonnes(j) = true;
        A = [ones(n, 1), X(:, colonnes)];
        coefficients = A \ y;
        r = y - A * coefficients;
        ddl = max(n - size(A, 2), 1);
        mse = sum(r .^ 2) / ddl;
        if mse <= 0
            valeursP(j) = 0;
            continue;
        end
        covariance = mse * inv(A' * A);
        erreurs = sqrt(abs(diag(covariance)));
        rang = 1 + sum(colonnes(1:j));
        t = coefficients(rang) / max(erreurs(rang), eps);
        valeursP(j) = 2 * (1 - tcdf(abs(t), ddl));
    end
end
