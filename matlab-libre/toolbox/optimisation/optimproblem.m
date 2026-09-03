classdef optimproblem
%OPTIMPROBLEM Problème d'optimisation décrit par ses expressions.
%   PROB = OPTIMPROBLEM crée un problème vide, à minimiser.
%   PROB = OPTIMPROBLEM('Objective',E) donne l'objectif,
%   OPTIMPROBLEM('ObjectiveSense','maximize') le sens.
%
%   Les contraintes s'ajoutent par leur nom :
%      prob.Constraints.budget = sum(x) <= 100;
%
%   SOLVE résout le problème, PROB2STRUCT rend les matrices que les
%   solveurs classiques attendent.
%
%   Cette écriture dit ce qu'on veut plutôt que comment le ranger : les
%   matrices A, b, Aeq, beq sont assemblées pour vous, dans le bon ordre.
%
%   Exemple :
%      x = optimvar('x', 2, 'LowerBound', 0);
%      prob = optimproblem('Objective', -x(1) - 2*x(2));
%      prob.Constraints.c1 = x(1) + x(2) <= 4;
%      prob.Constraints.c2 = x(1) + 3*x(2) <= 6;
%      sol = solve(prob);
%      sol.x
%
%   Voir aussi OPTIMVAR, SOLVE, PROB2STRUCT, LINPROG, QUADPROG, INTLINPROG.
    properties
        Objective = []
        ObjectiveSense = 'minimize'
        Constraints = struct()
        Description = ''
    end
    methods
        function p = optimproblem(varargin)
            k = 1;
            while k + 1 <= numel(varargin)
                switch lower(char(varargin{k}))
                    case 'objective',      p.Objective = varargin{k+1};
                    case 'objectivesense', p.ObjectiveSense = lower(char(varargin{k+1}));
                    case 'constraints',    p.Constraints = varargin{k+1};
                    case 'description',    p.Description = char(varargin{k+1});
                    otherwise
                        error('optim:optimproblem:Option', ...
                              'Option inconnue : %s.', char(varargin{k}));
                end
                k = k + 2;
            end
        end
    end
end
