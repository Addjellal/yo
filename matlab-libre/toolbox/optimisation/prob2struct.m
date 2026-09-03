function probleme = prob2struct(prob, varargin)
%PROB2STRUCT Traduit un problème en matrices pour les solveurs.
%   S = PROB2STRUCT(PROB) rend une structure portant f, H, Aineq, bineq,
%   Aeq, beq, lb, ub, intcon, solver et objectivesense : ce que LINPROG,
%   QUADPROG ou INTLINPROG attendent.
%
%   C'est le passage de l'écriture par expressions à l'écriture par
%   matrices ; SOLVE l'emploie, et l'on peut s'en servir pour voir
%   exactement ce que le solveur reçoit.
%
%   La structure porte en outre « variables », la liste des variables
%   dans l'ordre où elles sont empilées : c'est ce qui permet de relire
%   la solution.
%
%   Exemple :
%      x = optimvar('x', 2, 'LowerBound', 0);
%      prob = optimproblem('Objective', x(1) + x(2));
%      s = prob2struct(prob);
%      s.f
%
%   Voir aussi OPTIMPROBLEM, OPTIMVAR, SOLVE, LINPROG.
    variables = recenserVariables(prob);
    noms = fieldnames(variables);
    if isempty(noms)
        error('optim:prob2struct:Vide', 'Le problème ne porte aucune variable.');
    end
    positions = struct();
    total = 0;
    lb = [];
    ub = [];
    intcon = [];
    for k = 1:numel(noms)
        v = variables.(noms{k});
        n = prod(v.Size);
        positions.(noms{k}) = total + (1:n);
        lb = [lb; v.LowerBound(:)];      %#ok<AGROW>
        ub = [ub; v.UpperBound(:)];      %#ok<AGROW>
        if any(strcmp(v.Type, {'integer', 'binary'}))
            intcon = [intcon, total + (1:n)];   %#ok<AGROW>
        end
        if strcmp(v.Type, 'binary')
            lb(total + (1:n)) = max(lb(total + (1:n)), 0);
            ub(total + (1:n)) = min(ub(total + (1:n)), 1);
        end
        total = total + n;
    end
    % L'objectif.
    [f, H, constante] = assembler(prob.Objective, positions, total);
    if strcmp(prob.ObjectiveSense, 'maximize')
        f = -f;
        H = -H;
        constante = -constante;
    end
    % Les contraintes, rangées suivant leur sens.
    Aineq = zeros(0, total);
    bineq = zeros(0, 1);
    Aeq = zeros(0, total);
    beq = zeros(0, 1);
    nomsContraintes = fieldnames(prob.Constraints);
    for k = 1:numel(nomsContraintes)
        c = prob.Constraints.(nomsContraintes{k});
        if ~isa(c, 'optimconstr')
            error('optim:prob2struct:Contrainte', ...
                  'La contrainte « %s » n''en est pas une.', nomsContraintes{k});
        end
        [ligne, quadratique, decalage] = assembler(c.Expression, positions, total);
        if any(quadratique(:) ~= 0)
            error('optim:prob2struct:Quadratique', ...
                  'MatLibre ne traite pas les contraintes quadratiques.');
        end
        if strcmp(c.Sens, '==')
            Aeq = [Aeq; ligne.'];        %#ok<AGROW>
            beq = [beq; -decalage];      %#ok<AGROW>
        else
            Aineq = [Aineq; ligne.'];    %#ok<AGROW>
            bineq = [bineq; -decalage];  %#ok<AGROW>
        end
    end
    if any(H(:) ~= 0)
        solveur = 'quadprog';
    elseif ~isempty(intcon)
        solveur = 'intlinprog';
    else
        solveur = 'linprog';
    end
    probleme = struct('f', f, 'H', H, 'Aineq', Aineq, 'bineq', bineq, ...
                      'Aeq', Aeq, 'beq', beq, 'lb', lb, 'ub', ub, ...
                      'intcon', intcon, 'solver', solveur, ...
                      'objectivesense', prob.ObjectiveSense, ...
                      'constante', constante, 'variables', {noms}, ...
                      'positions', positions, 'n', total);
end

function variables = recenserVariables(prob)
% Toutes les variables citées, qu'elles soient dans l'objectif ou dans
% une contrainte.
    variables = struct();
    if isa(prob.Objective, 'optimexpr')
        variables = fusionner(variables, prob.Objective.Variables);
    elseif isa(prob.Objective, 'optimvar')
        e = optimexpr(prob.Objective);
        variables = fusionner(variables, e.Variables);
    end
    noms = fieldnames(prob.Constraints);
    for k = 1:numel(noms)
        c = prob.Constraints.(noms{k});
        if isa(c, 'optimconstr') && isa(c.Expression, 'optimexpr')
            variables = fusionner(variables, c.Expression.Variables);
        end
    end
end

function [f, H, constante] = assembler(expression, positions, total)
% Les coefficients d'une expression, rangés sur le vecteur empilé.
    f = zeros(total, 1);
    H = zeros(total, total);
    constante = 0;
    if isempty(expression)
        return
    end
    e = optimexpr.depuis(expression);
    noms = fieldnames(e.Lineaire);
    for k = 1:numel(noms)
        indices = positions.(noms{k});
        f(indices) = f(indices) + e.Lineaire.(noms{k})(:);
    end
    for k = 1:size(e.Quadratique, 1)
        i = positions.(e.Quadratique{k, 1});
        j = positions.(e.Quadratique{k, 2});
        bloc = e.Quadratique{k, 3};
        H(i, j) = H(i, j) + bloc;
    end
    % QUADPROG minimise 0.5 x'Hx : la forme quadratique doit être
    % symétrique, et compter deux fois.
    H = H + H.';
    constante = e.Constante;
end

function s = fusionner(s, autre)
    noms = fieldnames(autre);
    for k = 1:numel(noms)
        s.(noms{k}) = autre.(noms{k});
    end
end
