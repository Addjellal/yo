classdef LoggingInfo
%LOGGINGINFO La journalisation d'un signal ou d'une mémoire globale.
%   Le LoggingInfo d'un Simulink.Signal qui définit une mémoire partagée
%   globale dit si ses écritures se journalisent dans dsmout, et comment :
%      DataLogging      false ; true journalise
%      NameMode         false : l'élément porte le nom de la mémoire ;
%                       true : celui de LoggingName
%      LoggingName      le nom personnalisé
%      DecimateData     false ; true ne garde qu'une écriture sur
%      Decimation       Decimation (2)
%      LimitDataPoints  false ; true ne garde que les MaxPoints
%      MaxPoints        dernières (5000)
%
%   Exemple :
%      A = Simulink.Signal;
%      A.LoggingInfo.DataLogging = true;
%      A.LoggingInfo.Decimation = 3;
%      A.LoggingInfo.DataLogging                % 1
%
%   Voir aussi SIMULINK.SIGNAL, SIMULINK.SIMULATIONDATA.DATASTOREMEMORY.
    properties
        DataLogging = false
        NameMode = false
        LoggingName = ''
        DecimateData = false
        Decimation = 2
        LimitDataPoints = false
        MaxPoints = 5000
    end
    methods
        function obj = set.DataLogging(obj, v)
            obj.DataLogging = logique(v, 'DataLogging');
        end
        function obj = set.NameMode(obj, v)
            obj.NameMode = logique(v, 'NameMode');
        end
        function obj = set.DecimateData(obj, v)
            obj.DecimateData = logique(v, 'DecimateData');
        end
        function obj = set.LimitDataPoints(obj, v)
            obj.LimitDataPoints = logique(v, 'LimitDataPoints');
        end
        function obj = set.Decimation(obj, v)
            obj.Decimation = entierPositif(v, 'Decimation');
        end
        function obj = set.MaxPoints(obj, v)
            obj.MaxPoints = entierPositif(v, 'MaxPoints');
        end
        function obj = set.LoggingName(obj, v)
            if isstring(v) && isscalar(v)
                v = char(v);
            end
            if ~(ischar(v) && (isempty(v) || isrow(v)))
                error('Simulink:Logging:InvalidLoggingInfo', ...
                      'Le LoggingName d''un LoggingInfo est un texte.');
            end
            obj.LoggingName = v;
        end
        function disp(obj)
            matlibre_sl_proprietes(obj, {'DataLogging', 'NameMode', 'LoggingName', ...
                                         'DecimateData', 'Decimation', 'LimitDataPoints', ...
                                         'MaxPoints'});
        end
    end
end

function v = logique(v, nom)
    if ~((islogical(v) || isnumeric(v)) && isscalar(v) && (v == 0 || v == 1))
        error('Simulink:Logging:InvalidLoggingInfo', ...
              'Le %s d''un LoggingInfo vaut true ou false.', nom);
    end
    v = logical(v);
end

function v = entierPositif(v, nom)
    if ~(isnumeric(v) && isscalar(v) && isreal(v) && v >= 1 && v == round(v))
        error('Simulink:Logging:InvalidLoggingInfo', ...
              'Le %s d''un LoggingInfo est un entier positif.', nom);
    end
    v = double(v);
end
