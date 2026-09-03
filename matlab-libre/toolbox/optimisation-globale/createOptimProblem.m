function probleme = createOptimProblem(solveur, varargin)
%CREATEOPTIMPROBLEM Description d'un problème pour un solveur global.
%   PROB = CREATEOPTIMPROBLEM(SOLVEUR,'objective',F,'x0',X0,...) rassemble
%   dans une structure ce qu'un solveur local demande : la fonction, le
%   point de départ, les bornes et les contraintes. GLOBALSEARCH et
%   MULTISTART s'en servent pour relancer ce solveur depuis plusieurs
%   points.
%
%   SOLVEUR vaut 'fmincon', 'fminunc', 'lsqnonlin' ou 'lsqcurvefit'.
%   Les couples reconnus sont 'objective', 'x0', 'lb', 'ub', 'Aineq',
%   'bineq', 'Aeq', 'beq', 'nonlcon', 'options', 'xdata' et 'ydata'.
%
%   Exemple :
%      prob = createOptimProblem('fmincon', 'objective', @(x) x ^ 2 - 3, ...
%                                'x0', 1, 'lb', -5, 'ub', 5);
%      [x, f] = run(MultiStart, prob, 10);
%
%   Voir aussi GLOBALSEARCH, MULTISTART, FMINCON, OPTIMOPTIONS.
    solveur = lower(char(solveur));
    connus = {'fmincon', 'fminunc', 'lsqnonlin', 'lsqcurvefit'};
    if ~any(strcmp(solveur, connus))
        error('globaloptim:createOptimProblem:Solveur', ...
              'Solveur inconnu : %s.', solveur);
    end
    probleme = struct('solver', solveur, 'objective', [], 'x0', [], ...
                      'lb', [], 'ub', [], 'Aineq', [], 'bineq', [], ...
                      'Aeq', [], 'beq', [], 'nonlcon', [], 'options', [], ...
                      'xdata', [], 'ydata', []);
    champs = fieldnames(probleme);
    k = 1;
    while k + 1 <= numel(varargin)
        nom = char(varargin{k});
        trouve = '';
        for j = 1:numel(champs)
            if strcmpi(champs{j}, nom)
                trouve = champs{j};
                break
            end
        end
        if isempty(trouve)
            error('globaloptim:createOptimProblem:Option', ...
                  'Option inconnue : %s.', nom);
        end
        probleme.(trouve) = varargin{k + 1};
        k = k + 2;
    end
    if isempty(probleme.objective)
        error('globaloptim:createOptimProblem:Objectif', ...
              'Le problème doit porter une fonction objectif.');
    end
end
