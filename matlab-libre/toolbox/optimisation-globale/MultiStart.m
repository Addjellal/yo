classdef MultiStart
%MULTISTART Solveur global par départs multiples.
%   MS = MULTISTART crée un solveur qui relance un solveur local depuis
%   plusieurs points tirés au hasard, et garde le meilleur résultat.
%   MS = MULTISTART('UseParallel',false,'Display','off') règle les
%   options ; MatLibre les accepte et n'en emploie que 'Display'.
%
%   [X,F] = RUN(MS,PROBLEME,N) lance N départs sur le problème que rend
%   CREATEOPTIMPROBLEM.
%
%   Les départs multiples ne garantissent rien : ils rendent seulement
%   improbable de rester dans le premier creux venu. C'est la différence
%   avec GLOBALSEARCH, qui choisit ses points au lieu de les tirer.
%
%   Exemple :
%      prob = createOptimProblem('fminunc', ...
%          'objective', @(x) x ^ 4 - 3 * x ^ 2 + x, 'x0', 0);
%      [x, f] = run(MultiStart, prob, 20);
%
%   Voir aussi GLOBALSEARCH, CREATEOPTIMPROBLEM, MULTISTART, FMINCON.
    properties
        Display = 'final'
        UseParallel = false
        StartPointsToRun = 'all'
        XTolerance = 1e-6
        FunctionTolerance = 1e-6
    end

    methods
        function obj = MultiStart(varargin)
            k = 1;
            while k + 1 <= numel(varargin)
                nom = char(varargin{k});
                if isprop(obj, nom)
                    obj.(nom) = varargin{k + 1};
                else
                    error('globaloptim:MultiStart:Option', ...
                          'Option inconnue : %s.', nom);
                end
                k = k + 2;
            end
        end

        function [x, valeur, drapeau, sortie] = run(obj, probleme, nDeparts)
        %RUN Lance le solveur local depuis plusieurs points.
            if nargin < 3 || isempty(nDeparts), nDeparts = 20; end
            [x, valeur, sortie] = matlibre_departs_multiples(probleme, ...
                round(nDeparts), false);
            drapeau = 1;
            if strcmpi(obj.Display, 'iter') || strcmpi(obj.Display, 'final')
                fprintf('MultiStart : %d départs, meilleure valeur %.6g\n', ...
                        round(nDeparts), valeur);
            end
        end
    end
end
