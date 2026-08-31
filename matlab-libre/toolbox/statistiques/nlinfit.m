function [beta, residus, jacobienne, covariance, erreurQuadratique] = ...
    nlinfit(X, y, modele, beta0, options)
%NLINFIT Ajustement d'un modèle non linéaire par moindres carrés.
%   BETA = NLINFIT(X,Y,MODELE,BETA0) cherche les paramètres BETA qui
%   rendent MODELE(BETA,X) le plus proche de Y au sens des moindres
%   carrés, en partant de BETA0. MODELE est une poignée de fonction dont
%   le premier argument est le vecteur des paramètres et le second les
%   données.
%
%   La minimisation est celle de Levenberg-Marquardt : à chaque pas, on
%   résout le système linéarisé, amorti d'un terme qu'on augmente quand
%   le pas fait remonter la somme des carrés et qu'on diminue quand il la
%   fait descendre. C'est ce qui permet de partir loin de la solution
%   sans diverger.
%
%   [BETA,R] = NLINFIT(...) rend les résidus Y - MODELE(BETA,X).
%   [BETA,R,J] = NLINFIT(...) rend la jacobienne du modèle au point
%   trouvé, obtenue par différences finies centrées.
%   [BETA,R,J,COVB] = NLINFIT(...) rend la covariance estimée des
%   paramètres, dont NLPARCI tire les intervalles de confiance.
%   [BETA,R,J,COVB,MSE] = NLINFIT(...) rend la variance résiduelle.
%
%   NLINFIT(...,OPTIONS) accepte une structure portant les champs
%   TolFun, TolX et MaxIter.
%
%   Un ajustement non linéaire dépend du point de départ : deux BETA0
%   différents peuvent mener à deux minima locaux différents. Il vaut
%   toujours mieux partir d'une estimation grossière mais sensée.
%
%   Exemples :
%      x = (0:0.2:5)';
%      y = 2.5 * exp(-0.8 * x) + 0.01 * randn(size(x));
%      beta = nlinfit(x, y, @(b, t) b(1) * exp(-b(2) * t), [1; 1])
%      % proche de [2.5 ; 0.8]
%
%      [b, r, J, covb] = nlinfit(x, y, @(b, t) b(1) * exp(-b(2) * t), [1; 1]);
%      nlparci(b, r, 'covar', covb)
%
%   Voir aussi NLPARCI, LSQCURVEFIT, FITLM, REGRESS, POLYFIT.
    if nargin < 5 || isempty(options)
        options = struct();
    end
    tolFun = champOuDefaut(options, 'TolFun', 1e-10);
    tolX = champOuDefaut(options, 'TolX', 1e-10);
    maximum = champOuDefaut(options, 'MaxIter', 400);
    y = y(:);
    beta = beta0(:);
    p = numel(beta);
    residus = y - reshape(modele(beta, X), [], 1);
    somme = sum(residus .^ 2);
    amortissement = 1e-3;
    for iteration = 1:maximum
        J = jacobienneNumerique(modele, beta, X, numel(y));
        gradient = J' * residus;
        normale = J' * J;
        avance = false;
        for essai = 1:30
            pas = (normale + amortissement * diag(max(diag(normale), 1e-12))) \ gradient;
            candidat = beta + pas;
            residusCandidat = y - reshape(modele(candidat, X), [], 1);
            sommeCandidat = sum(residusCandidat .^ 2);
            if isfinite(sommeCandidat) && sommeCandidat < somme
                beta = candidat;
                avance = true;
                break;
            end
            amortissement = amortissement * 10;
        end
        if ~avance
            break;
        end
        amortissement = max(amortissement / 10, 1e-12);
        ancienneSomme = somme;
        residus = y - reshape(modele(beta, X), [], 1);
        somme = sum(residus .^ 2);
        if max(abs(pas)) <= tolX * (1 + max(abs(beta)))
            break;
        end
        if abs(ancienneSomme - somme) <= tolFun * (1 + somme)
            break;
        end
    end
    jacobienne = jacobienneNumerique(modele, beta, X, numel(y));
    ddl = max(numel(y) - p, 1);
    erreurQuadratique = sum(residus .^ 2) / ddl;
    covariance = erreurQuadratique * pinv(jacobienne' * jacobienne);
end

function J = jacobienneNumerique(modele, beta, X, n)
%JACOBIENNENUMERIQUE Dérivées du modèle par différences centrées.
    p = numel(beta);
    J = zeros(n, p);
    for j = 1:p
        pas = max(1e-7 * abs(beta(j)), 1e-9);
        avant = beta;
        apres = beta;
        avant(j) = avant(j) - pas;
        apres(j) = apres(j) + pas;
        J(:, j) = (reshape(modele(apres, X), [], 1) - ...
                   reshape(modele(avant, X), [], 1)) / (2 * pas);
    end
end

function valeur = champOuDefaut(structure, nom, defaut)
%CHAMPOUDEFAUT Un champ d'options, ou sa valeur par défaut.
    valeur = defaut;
    if isstruct(structure) && isfield(structure, nom) && ~isempty(structure.(nom))
        valeur = structure.(nom);
    end
end
