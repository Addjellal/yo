function options = saoptimset(varargin)
%SAOPTIMSET Options d'un recuit simulé.
%   O = SAOPTIMSET rend les réglages par défaut de SIMULANNEALBND :
%     MaxIter              nombre maximal d'itérations, 1000
%     InitialTemperature   température de départ, 100
%     TemperatureFcn       loi de refroidissement, 'temperatureexp'
%     ReannealInterval     itérations entre deux réchauffements, 100
%     TolFun               seuil d'arrêt, 1e-6
%     Display              'final', 'iter' ou 'off'
%
%   La température commande la probabilité d'accepter un pas qui dégrade
%   le critère : haute, on explore ; basse, on descend. C'est ce qui
%   permet de sortir d'un creux local au début et de s'y poser à la fin.
%
%   Exemple :
%      o = saoptimset('MaxIter', 5000, 'InitialTemperature', 50);
%      x = simulannealbnd(@(v) sum(v .^ 2), [1 1], [-5 -5], [5 5], o);
%
%   Voir aussi SIMULANNEALBND, GAOPTIMSET, PSOPTIMSET, OPTIMOPTIONS.
    defauts = struct('MaxIter', 1000, 'InitialTemperature', 100, ...
                     'TemperatureFcn', 'temperatureexp', ...
                     'ReannealInterval', 100, 'TolFun', 1e-6, ...
                     'Display', 'final', 'MaxFunEvals', 10000, ...
                     'PlotFcns', []);
    options = matlibre_options_globales(defauts, 'saoptimset', varargin{:});
end
