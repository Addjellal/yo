function options = gaoptimset(varargin)
%GAOPTIMSET Options d'un algorithme génétique.
%   O = GAOPTIMSET rend les réglages par défaut de GA :
%     PopulationSize     taille de la population, 50
%     Generations        nombre de générations, 100
%     EliteCount         individus reconduits tels quels, 2
%     CrossoverFraction  part des enfants issus d'un croisement, 0,8
%     MutationRate       taux de mutation, 0,1
%     Display            'final', 'iter' ou 'off'
%     TolFun             seuil d'arrêt sur l'amélioration, 1e-6
%     StallGenLimit      générations sans progrès avant d'arrêter, 50
%
%   O = GAOPTIMSET('PopulationSize',N,...) en change ; GAOPTIMSET(O,...)
%   part d'une structure existante.
%
%   C'est l'interface d'origine ; OPTIMOPTIONS est la moderne, et les
%   deux mènent à la même structure.
%
%   Exemple :
%      o = gaoptimset('PopulationSize', 200, 'Generations', 300);
%      x = ga(@(v) sum(v .^ 2), 3, -5, 5, o);
%
%   Voir aussi GA, GAMULTIOBJ, PSOPTIMSET, SAOPTIMSET, OPTIMOPTIONS.
    defauts = struct('PopulationSize', 50, 'Generations', 100, ...
                     'EliteCount', 2, 'CrossoverFraction', 0.8, ...
                     'MutationRate', 0.1, 'Display', 'final', ...
                     'TolFun', 1e-6, 'TolCon', 1e-6, 'StallGenLimit', 50, ...
                     'InitialPopulation', [], 'PlotFcns', []);
    options = matlibre_options_globales(defauts, 'gaoptimset', varargin{:});
end
