function options = fcmOptions(varargin)
%FCMOPTIONS Options des c-moyennes floues.
%   O = FCMOPTIONS rend les réglages par défaut de FCM :
%     NumClusters      nombre de classes, 'auto'
%     Exponent         exposant de flou, 2
%     MaxNumIteration  nombre maximal d'itérations, 100
%     MinImprovement   amélioration en deçà de laquelle on s'arrête, 1e-5
%     DistanceMetric   distance employée, 'euclidean'
%     Verbose          affichage, 0
%
%   Exemple :
%      o = fcmOptions('NumClusters', 3, 'Exponent', 1.5);
%      [c, u] = fcm(donnees, o);
%
%   Voir aussi FCM, SUBCLUSTOPTIONS, GENFISOPTIONS.
    options = struct('NumClusters', 'auto', 'Exponent', 2, ...
                     'MaxNumIteration', 100, 'MinImprovement', 1e-5, ...
                     'DistanceMetric', 'euclidean', 'Verbose', 0);
    options = poserOptions(options, 'fcmOptions', varargin{:});
end
