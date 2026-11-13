function deleteSignal(id)
%DELETESIGNAL Retire un signal de son run.
%   SIMULINK.SDI.DELETESIGNAL(ID).
%
%   Exemple :
%      [id, ~, ids] = Simulink.sdi.createRun('r', 'vars', timeseries(1), timeseries(2));
%      Simulink.sdi.deleteSignal(ids(1));
%      Simulink.sdi.getRun(id).SignalCount   % 1
%      Simulink.sdi.deleteRun(id);
%
%   Voir aussi SIMULINK.SDI.DELETERUN, SIMULINK.SDI.GETSIGNAL.
    matlibre_sdi('retirersignal', id);
end
