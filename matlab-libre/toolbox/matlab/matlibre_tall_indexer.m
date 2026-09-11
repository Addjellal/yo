function v = matlibre_tall_indexer(valeur, varargin)
%MATLIBRE_TALL_INDEXER Indexation d'une valeur matérialisée.
%   V = MATLIBRE_TALL_INDEXER(VALEUR,I,...) rend VALEUR(I,...). Elle
%   existe pour que l'indexation d'un tableau différé soit elle-même
%   différée : « t(t > 5) » décrit un filtre, il ne le fait pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_tall_indexer([10 20 30], [3 1])   % [30 10]
%
%   Voir aussi TALL, GATHER.
    v = valeur(varargin{:});
end
