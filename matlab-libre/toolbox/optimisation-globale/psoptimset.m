function options = psoptimset(varargin)
%PSOPTIMSET Options d'une recherche par motif.
%   O = PSOPTIMSET rend les réglages par défaut de PATTERNSEARCH :
%     MaxIter          nombre maximal d'itérations, 200
%     MeshTolerance    finesse du motif en deçà de laquelle on s'arrête,
%                      1e-6
%     InitialMeshSize  taille initiale du motif, 1
%     MeshExpansion    facteur d'agrandissement après un succès, 2
%     MeshContraction  facteur de réduction après un échec, 0,5
%     TolFun, TolX     seuils d'arrêt, 1e-6
%     Display          'final', 'iter' ou 'off'
%
%   Exemple :
%      o = psoptimset('MaxIter', 500, 'MeshTolerance', 1e-9);
%      x = patternsearch(@(v) sum(v .^ 2), [1 1], [], [], [], [], [], [], [], o);
%
%   Voir aussi PATTERNSEARCH, PARETOSEARCH, GAOPTIMSET, OPTIMOPTIONS.
    defauts = struct('MaxIter', 200, 'MeshTolerance', 1e-6, ...
                     'InitialMeshSize', 1, 'MeshExpansion', 2, ...
                     'MeshContraction', 0.5, 'TolFun', 1e-6, ...
                     'TolX', 1e-6, 'Display', 'final', ...
                     'MaxFunEvals', 5000, 'PlotFcns', []);
    options = matlibre_options_globales(defauts, 'psoptimset', varargin{:});
end
