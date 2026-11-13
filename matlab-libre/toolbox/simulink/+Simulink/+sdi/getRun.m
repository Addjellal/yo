function run = getRun(id)
%GETRUN Un run du Simulation Data Inspector, par son identifiant.
%   RUN = SIMULINK.SDI.GETRUN(ID) rend un Simulink.sdi.Run ; un
%   identifiant qui ne désigne pas de run est refusé.
%
%   Exemple :
%      id = Simulink.sdi.createRun('lu', 'vars', timeseries(1));
%      Simulink.sdi.getRun(id).Name       % 'lu'
%      Simulink.sdi.deleteRun(id);
%
%   Voir aussi SIMULINK.SDI.CREATERUN, SIMULINK.SDI.RUN.
    run = Simulink.sdi.Run(id);
end
