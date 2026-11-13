function s = getSignal(id)
%GETSIGNAL Un signal du Simulation Data Inspector, par son identifiant.
%   S = SIMULINK.SDI.GETSIGNAL(ID) rend un Simulink.sdi.Signal.
%
%   Exemple :
%      [id, ~, ids] = Simulink.sdi.createRun('lu', 'vars', timeseries((1:3)', 0:2, 'Name', 'x'));
%      Simulink.sdi.getSignal(ids(1)).Name   % 'x'
%      Simulink.sdi.deleteRun(id);
%
%   Voir aussi SIMULINK.SDI.SIGNAL, SIMULINK.SDI.COMPARESIGNALS.
    s = Simulink.sdi.Signal(id);
end
