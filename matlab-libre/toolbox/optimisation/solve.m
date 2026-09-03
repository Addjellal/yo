function [solution, valeur, drapeau] = solve(prob, varargin)
%SOLVE Résout un problème écrit par expressions.
%   SOL = SOLVE(PROB) choisit le solveur d'après la forme du problème —
%   LINPROG pour un objectif linéaire, QUADPROG pour un objectif
%   quadratique, INTLINPROG dès qu'une variable est entière — et rend une
%   structure portant la valeur de chaque variable.
%
%   [SOL,VAL,DRAPEAU] = SOLVE(PROB) rend en outre la valeur de l'objectif
%   et le drapeau du solveur.
%
%   SOLVE(...,'Solver',NOM) impose le solveur.
%
%   Exemple :
%      x = optimvar('x', 2, 'LowerBound', 0);
%      prob = optimproblem('Objective', -x(1) - 2*x(2), ...
%                          'ObjectiveSense', 'minimize');
%      prob.Constraints.c1 = x(1) + x(2) <= 4;
%      sol = solve(prob);
%      sol.x
%
%   Voir aussi OPTIMPROBLEM, OPTIMVAR, PROB2STRUCT, LINPROG, QUADPROG.
    solveurImpose = '';
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'solver',  solveurImpose = lower(char(varargin{k+1}));
            case {'options', 'x0'}
                % Acceptées et sans effet.
            otherwise
                error('optim:solve:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    s = prob2struct(prob);
    solveur = s.solver;
    if ~isempty(solveurImpose)
        solveur = solveurImpose;
    end
    switch solveur
        case 'linprog'
            [x, ~, drapeau] = linprog(s.f, s.Aineq, s.bineq, s.Aeq, s.beq, s.lb, s.ub);
        case 'quadprog'
            [x, ~] = quadprog(s.H, s.f, s.Aineq, s.bineq, s.Aeq, s.beq, s.lb, s.ub);
            drapeau = 1;
        case 'intlinprog'
            [x, ~, drapeau] = intlinprog(s.f, s.intcon, s.Aineq, s.bineq, ...
                                         s.Aeq, s.beq, s.lb, s.ub);
        otherwise
            error('optim:solve:Solveur', 'Solveur inconnu : %s.', solveur);
    end
    x = x(:);
    % La valeur rendue est celle de l'objectif écrit, non celle du
    % problème retourné : un « maximize » rend bien son maximum.
    valeur = s.f.' * x + 0.5 * x.' * s.H * x + s.constante;
    if strcmp(s.objectivesense, 'maximize')
        valeur = -valeur;
    end
    solution = struct();
    for k = 1:numel(s.variables)
        nom = s.variables{k};
        indices = s.positions.(nom);
        solution.(nom) = x(indices);
    end
end
