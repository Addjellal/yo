classdef Signal
%SIGNAL Un signal journalisé dans un Simulink.SimulationData.Dataset.
%   Ses propriétés : Name, le nom du signal ; BlockPath, le chemin du bloc
%   qui l'a journalisé ; PortType ('outport' ou 'inport') et PortIndex ;
%   Values, une TIMESERIES — ses instants et ses valeurs.
%
%   Exemple :
%      s = Simulink.SimulationData.Signal;
%      s.Name = 'vitesse';
%      s.Values = timeseries([0; 1], [0 1]);
%      s.Values.Length                  % 2
%
%   Voir aussi SIMULINK.SIMULATIONDATA.DATASET, TIMESERIES, SIM.
    properties
        Name = ''
        PropagatedName = ''
        BlockPath = ''
        PortType = 'outport'
        PortIndex = 1
        Values = []
    end
end
