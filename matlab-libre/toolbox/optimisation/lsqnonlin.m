function [x, resnorm, residual, exitflag, output] = lsqnonlin(fonction, x0, bornesBasses, bornesHautes, options)
%LSQNONLIN Moindres carrés non linéaires.
%   X = LSQNONLIN(F,X0) minimise la somme des carrés des composantes de
%   F(X). LSQNONLIN(F,X0,LB,UB) impose des bornes.
%
%   La méthode est celle de Levenberg-Marquardt : le jacobien est estimé
%   par différences finies, et l'amortissement passe de la descente de
%   gradient à Gauss-Newton selon que le pas améliore ou non le critère.
%
%   Exemple :
%      % Ajustement de a*exp(b*t) sur des données exactes.
%      t = (0:0.5:2)';  y = 3 * exp(-0.5 * t);
%      p = lsqnonlin(@(p) p(1) * exp(p(2) * t) - y, [1; -1]);
    if nargin < 3, bornesBasses = []; end
    if nargin < 4, bornesHautes = []; end
    if nargin < 5, options = struct(); end
    toleranceX = lireOption(options, 'TolX', 1e-10);
    toleranceF = lireOption(options, 'TolFun', 1e-10);
    maximum = lireOption(options, 'MaxIter', 400);

    x = x0(:);
    n = numel(x);
    x = projeter(x, bornesBasses, bornesHautes);
    r = fonction(x);
    r = r(:);
    critere = sum(r.^2);
    lambda = 1e-3;
    exitflag = 0;
    for iteration = 1:maximum
        J = jacobien(fonction, x, r);
        gradient = J' * r;
        if norm(gradient, inf) < toleranceF
            exitflag = 1;
            break
        end
        H = J' * J;
        avance = false;
        for essai = 1:30
            pas = -(H + lambda * diag(max(diag(H), 1e-12))) \ gradient;
            candidat = projeter(x + pas, bornesBasses, bornesHautes);
            rc = fonction(candidat);
            rc = rc(:);
            critereCandidat = sum(rc.^2);
            if critereCandidat < critere
                if norm(candidat - x, inf) < toleranceX * (1 + norm(x, inf))
                    x = candidat; r = rc; critere = critereCandidat;
                    exitflag = 2;
                    avance = true;
                    break
                end
                x = candidat;
                r = rc;
                critere = critereCandidat;
                lambda = max(lambda / 10, 1e-12);
                avance = true;
                break
            end
            lambda = lambda * 10;
            if lambda > 1e12, break, end
        end
        if ~avance
            exitflag = 3;
            break
        end
        if exitflag == 2, break, end
    end
    resnorm = critere;
    residual = r;
    output = struct('iterations', iteration, 'algorithm', 'levenberg-marquardt', ...
                    'firstorderopt', norm(2 * J' * r, inf));
    % n sert à documenter la dimension ; il n'entre pas dans la sortie.
end

function J = jacobien(fonction, x, r)
%JACOBIEN Différences finies avant, pas adapté à l'échelle de x.
    n = numel(x);
    m = numel(r);
    J = zeros(m, n);
    for k = 1:n
        pas = sqrt(eps) * max(abs(x(k)), 1);
        xk = x;
        xk(k) = xk(k) + pas;
        rk = fonction(xk);
        J(:, k) = (rk(:) - r) / pas;
    end
end

function x = projeter(x, bas, haut)
    if ~isempty(bas), x = max(x, bas(:)); end
    if ~isempty(haut), x = min(x, haut(:)); end
end

function v = lireOption(options, nom, defaut)
    if isstruct(options) && isfield(options, nom) && ~isempty(options.(nom))
        v = options.(nom);
    else
        v = defaut;
    end
end
