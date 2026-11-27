function [x, resnorm, residual, exitflag, output] = ...
    lsqnonlin(fonction, x0, bornesBasses, bornesHautes, options)
%LSQNONLIN Moindres carrés non linéaires.
%   X = LSQNONLIN(F,X0) minimise la somme des carrés des composantes de
%   F(X). LSQNONLIN(F,X0,LB,UB) impose des bornes ; LSQNONLIN(F,X0,LB,UB,
%   OPTIONS) prend une structure d'OPTIMOPTIONS ou d'OPTIMSET.
%   [X,RESNORM,RESIDUAL,EXITFLAG,OUTPUT] = LSQNONLIN(...) rend aussi la
%   somme des carrés, les résidus F(X), la cause de l'arrêt et le détail
%   (iterations, funcCount, firstorderopt, stepsize, algorithm, message).
%
%   La méthode est celle de Levenberg-Marquardt : chaque pas résout le
%   problème linéarisé amorti min |J*pas + F|^2 + lambda*|D*pas|^2, où D
%   porte les normes des colonnes de J, par une factorisation QR du
%   système augmenté — sans former J'*J. L'amortissement passe de la
%   descente de gradient à Gauss-Newton selon que le pas améliore ou non
%   le critère. Les bornes sont tenues par projection.
%
%   Options lues (noms d'OPTIMOPTIONS ou anciens noms) :
%      StepTolerance (TolX)        arrêt quand le pas < tol*(1+|x|) (1e-10)
%      OptimalityTolerance (TolFun) arrêt quand |J'*F| < tol (1e-10)
%      FunctionTolerance           arrêt quand la somme des carrés varie de
%                                  moins de tol*(1+S) ; éteint par défaut
%      MaxIterations (MaxIter)     400
%      MaxFunctionEvaluations (MaxFunEvals)
%      FiniteDifferenceType        'forward' (défaut) ou 'central', plus
%                                  précis : l'erreur du jacobien passe de
%                                  sqrt(eps) à eps^(2/3)
%      FiniteDifferenceStepSize    pas relatif (sqrt(eps), ou eps^(1/3) en
%                                  centré), multiplié par max(|x|,TypicalX)
%      SpecifyObjectiveGradient (Jacobian 'on') : F rend [F, J], et le
%                                  jacobien exact remplace les différences
%      Display                     'off', 'final' ou 'iter'
%
%   EXITFLAG vaut 1 (gradient sous la tolérance), 2 (pas sous la
%   tolérance), 3 (somme des carrés immobile, ou plus aucun pas qui la
%   fasse baisser) ou 0 (limite d'itérations ou d'évaluations atteinte).
%
%   Exemple :
%      % Ajustement de a*exp(b*t) sur des données exactes.
%      t = (0:0.5:2)';  y = 3 * exp(-0.5 * t);
%      p = lsqnonlin(@(p) p(1) * exp(p(2) * t) - y, [1; -1]);
%
%   Voir aussi LSQCURVEFIT, LSQLIN, FSOLVE, FMINSEARCH, NLINFIT.
    if nargin < 3, bornesBasses = []; end
    if nargin < 4, bornesHautes = []; end
    if nargin < 5, options = struct(); end
    toleranceX = lireOption(options, {'StepTolerance', 'TolX'}, 1e-10);
    toleranceG = lireOption(options, {'OptimalityTolerance', 'TolFun'}, 1e-10);
    toleranceF = lireOption(options, {'FunctionTolerance'}, 0);
    maximum = lireOption(options, {'MaxIterations', 'MaxIter'}, 400);
    maxEvaluations = lireOption(options, {'MaxFunctionEvaluations', 'MaxFunEvals'}, inf);
    if ischar(maxEvaluations) || isstring(maxEvaluations)
        maxEvaluations = inf;   % '100*numberOfVariables' : pas de limite propre
    end
    affichage = lower(char(lireOption(options, {'Display'}, 'off')));
    differences = lower(char(lireOption(options, {'FiniteDifferenceType'}, 'forward')));
    pasDifferences = lireOption(options, {'FiniteDifferenceStepSize'}, []);
    typique = lireOption(options, {'TypicalX'}, []);
    jacobienFourni = estVrai(lireOption(options, {'SpecifyObjectiveGradient'}, false)) || ...
                     estVrai(lireOption(options, {'Jacobian'}, false));
    if ~any(strcmp(differences, {'forward', 'central'}))
        error('optim:lsqnonlin:BadFiniteDifferenceType', ...
              'FiniteDifferenceType must be ''forward'' or ''central''.');
    end

    forme = size(x0);
    x = double(x0(:));
    n = numel(x);
    % Le pas des différences est relatif à x : v*|x(k)|, ou v*TypicalX(k)
    % si TypicalX est donné et plus grand. Un pas fixé à v pour tout
    % |x| < 1, comme le fait TypicalX = 1, fausse la dérivée d'un paramètre
    % petit — 5e-4 dans le modèle Misra1a du NIST — et coûte trois chiffres.
    if isempty(typique)
        typique = zeros(n, 1);
    end
    typique = abs(double(typique(:)));
    if isempty(pasDifferences)
        if strcmp(differences, 'central')
            pasDifferences = eps ^ (1 / 3);
        else
            pasDifferences = sqrt(eps);
        end
    end
    x = projeter(x, bornesBasses, bornesHautes);
    evaluations = 0;
    [r, J] = evaluer(x);
    critere = r' * r;
    lambda = 0.01;
    exitflag = 0;
    pas = zeros(n, 1);
    if strcmp(affichage, 'iter')
        fprintf('\n%10s %10s %16s %16s %14s\n', 'Itération', 'Évals', 'Somme des carrés', ...
                'Optimalité', 'Norme du pas');
    end
    iteration = 0;
    while iteration < maximum
        iteration = iteration + 1;
        if isempty(J)
            J = jacobienNumerique(x, r);
        end
        gradient = J' * r;
        if strcmp(affichage, 'iter')
            fprintf('%10d %10d %16.6g %16.4g %14.4g\n', iteration - 1, evaluations, ...
                    critere, norm(gradient, inf), norm(pas));
        end
        if norm(gradient, inf) < toleranceG
            exitflag = 1;
            break
        end
        echelle = sqrt(sum(J .^ 2, 1))';
        echelle(echelle == 0 | ~isfinite(echelle)) = 1;
        Jr = J ./ echelle';
        avance = false;
        epuise = false;
        while lambda <= 1e16
            reduit = -([Jr; sqrt(lambda) * eye(n)] \ [r; zeros(n, 1)]);
            candidat = projeter(x + reduit ./ echelle, bornesBasses, bornesHautes);
            [rc, Jc] = evaluer(candidat);
            critereCandidat = rc' * rc;
            if isfinite(critereCandidat) && critereCandidat < critere
                pas = candidat - x;
                ancienCritere = critere;
                x = candidat;
                r = rc;
                J = Jc;
                critere = critereCandidat;
                lambda = max(lambda / 10, eps);
                avance = true;
                break
            end
            lambda = lambda * 10;
            if evaluations >= maxEvaluations
                epuise = true;
                break
            end
        end
        if ~avance
            exitflag = 3 * ~epuise;
            break
        end
        if norm(pas) < toleranceX * (1 + norm(x))
            exitflag = 2;
            break
        end
        if abs(ancienCritere - critere) <= toleranceF * (1 + critere)
            exitflag = 3;
            break
        end
        if evaluations >= maxEvaluations
            exitflag = 0;
            break
        end
    end
    if isempty(J)
        J = jacobienNumerique(x, r);
    end
    resnorm = critere;
    residual = r;
    x = reshape(x, forme);
    messages = {'Limite d''itérations ou d''évaluations atteinte.', ...
                'Gradient sous la tolérance d''optimalité.', ...
                'Pas sous la tolérance sur x.', ...
                'Somme des carrés immobile.'};
    output = struct('iterations', iteration, 'funcCount', evaluations, ...
                    'stepsize', norm(pas), 'cgiterations', [], ...
                    'algorithm', 'levenberg-marquardt', ...
                    'firstorderopt', norm(2 * J' * r, inf), ...
                    'message', messages{exitflag + 1});
    if any(strcmp(affichage, {'final', 'iter'}))
        fprintf('%s\n', output.message);
    end

    function [valeur, jacobienExact] = evaluer(point)
        jacobienExact = [];
        if jacobienFourni
            [valeur, jacobienExact] = fonction(reshape(point, forme));
            jacobienExact = double(jacobienExact);
        else
            valeur = fonction(reshape(point, forme));
        end
        valeur = double(valeur(:));
        evaluations = evaluations + 1;
    end

    function Jn = jacobienNumerique(point, valeur)
    %JACOBIENNUMERIQUE Différences avant ou centrées, pas à l'échelle de x.
        Jn = zeros(numel(valeur), n);
        for k = 1:n
            h = pasDifferences * max(abs(point(k)), typique(k));
            if h == 0
                h = pasDifferences;
            end
            if strcmp(differences, 'central')
                plus = point; plus(k) = plus(k) + h;
                moins = point; moins(k) = moins(k) - h;
                Jn(:, k) = (valeurEn(plus) - valeurEn(moins)) / (plus(k) - moins(k));
            else
                plus = point; plus(k) = plus(k) + h;
                Jn(:, k) = (valeurEn(plus) - valeur) / (plus(k) - point(k));
            end
        end
    end

    function v = valeurEn(point)
        v = fonction(reshape(point, forme));
        v = double(v(:));
        evaluations = evaluations + 1;
    end
end

function x = projeter(x, bas, haut)
    if ~isempty(bas), x = max(x, bas(:)); end
    if ~isempty(haut), x = min(x, haut(:)); end
end

function v = lireOption(options, noms, defaut)
%LIREOPTION La première des orthographes posée, sinon la valeur par défaut.
    v = defaut;
    if ~isstruct(options), return, end
    for k = 1:numel(noms)
        if isfield(options, noms{k}) && ~isempty(options.(noms{k}))
            v = options.(noms{k});
            return
        end
    end
end

function oui = estVrai(v)
    if ischar(v) || isstring(v)
        oui = strcmpi(char(v), 'on') || strcmpi(char(v), 'true');
    else
        oui = ~isempty(v) && logical(v(1));
    end
end
