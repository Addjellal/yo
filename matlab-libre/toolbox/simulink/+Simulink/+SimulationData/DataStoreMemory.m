classdef DataStoreMemory
%DATASTOREMEMORY Les écritures journalisées d'une mémoire partagée.
%   SIM range dans dsmout (DSMLoggingName) un élément de cette classe par
%   mémoire partagée dont DataLogging est à 'on' — un bloc Data Store
%   Memory, ou le LoggingInfo du Simulink.Signal d'une mémoire globale.
%   Ses propriétés :
%      Name                 le nom de la mémoire, ou DataLoggingName
%      BlockPath            le chemin du bloc Data Store Memory, '' pour
%                           une mémoire globale
%      Scope                'local', ou 'global' pour une mémoire que
%                           définit un Simulink.Signal
%      DSMWriterBlockPaths  les chemins des blocs qui l'écrivent, une
%                           cellule par bloc
%      DSMWriters           pour chaque écriture, le rang de son écrivain
%                           dans DSMWriterBlockPaths (uint32)
%      Values               une TIMESERIES : l'instant et la valeur de
%                           chaque écriture, dans le type de la mémoire
%
%   Exemple :
%      d = Simulink.SimulationData.DataStoreMemory;
%      d.Name = 'A';
%      d.DSMWriterBlockPaths = {'m/ecrire'};
%      d.DSMWriters = uint32([1; 1]);
%      d.Values = timeseries([2; 3], [0 1]);
%      d.DSMWriterBlockPaths{d.DSMWriters(end)}   % 'm/ecrire'
%
%   Voir aussi SIMULINK.SIMULATIONDATA.DATASET, SIMULINK.SIGNAL, SIM.
    properties
        Name = ''
        BlockPath = ''
        Scope = 'local'
        DSMWriterBlockPaths = cell(0, 1)
        DSMWriters = zeros(0, 1, 'uint32')
        Values = []
    end
    methods
        function disp(d)
            fprintf('  Simulink.SimulationData.DataStoreMemory\n');
            fprintf('    Name: ''%s''\n', d.Name);
            fprintf('    BlockPath: ''%s''\n', d.BlockPath);
            fprintf('    Scope: ''%s''\n', d.Scope);
            fprintf('    DSMWriterBlockPaths: [%dx1 cell]\n', numel(d.DSMWriterBlockPaths));
            fprintf('    DSMWriters: [%dx1 uint32]\n', numel(d.DSMWriters));
            if isempty(d.Values)
                fprintf('    Values: []\n\n');
            else
                fprintf('    Values: [1x1 timeseries]\n\n');
            end
        end
    end
end
