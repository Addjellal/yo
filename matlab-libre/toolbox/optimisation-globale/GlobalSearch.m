classdef GlobalSearch
%GLOBALSEARCH Solveur global par bassins d'attraction.
%   GS = GLOBALSEARCH crée un solveur qui échantillonne largement, garde
%   les points les plus prometteurs, puis lance le solveur local depuis
%   eux seulement.
%
%   [X,F] = RUN(GS,PROBLEME) lance la recherche sur le problème que rend
%   CREATEOPTIMPROBLEM.
%
%   La différence avec MULTISTART tient au choix des points : au lieu de
%   tirer et de lancer, on tire beaucoup, on évalue, et l'on ne lance le
%   solveur local que là où la fonction est déjà basse. Le même budget
%   d'appels couvre alors plus de bassins.
%
%   Exemple :
%      prob = createOptimProblem('fminunc', ...
%          'objective', @(x) x ^ 4 - 3 * x ^ 2 + x, 'x0', 0);
%      [x, f] = run(GlobalSearch, prob);
%
%   Voir aussi MULTISTART, CREATEOPTIMPROBLEM, PARTICLESWARM, GA.
    properties
        Display = 'final'
        NumTrialPoints = 200
        NumStageOnePoints = 20
        XTolerance = 1e-6
        FunctionTolerance = 1e-6
    end

    methods
        function obj = GlobalSearch(varargin)
            k = 1;
            while k + 1 <= numel(varargin)
                nom = char(varargin{k});
                if isprop(obj, nom)
                    obj.(nom) = varargin{k + 1};
                else
                    error('globaloptim:GlobalSearch:Option', ...
                          'Option inconnue : %s.', nom);
                end
                k = k + 2;
            end
        end

        function [x, valeur, drapeau, sortie] = run(obj, probleme)
        %RUN Échantillonne, trie, puis raffine les meilleurs points.
            [x, valeur, sortie] = matlibre_departs_multiples(probleme, ...
                obj.NumStageOnePoints, true, obj.NumTrialPoints);
            drapeau = 1;
            if strcmpi(obj.Display, 'iter') || strcmpi(obj.Display, 'final')
                fprintf('GlobalSearch : %d points essayés, meilleure valeur %.6g\n', ...
                        obj.NumTrialPoints, valeur);
            end
        end
    end
end
