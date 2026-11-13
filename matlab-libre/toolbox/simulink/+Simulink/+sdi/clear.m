function clear()
%CLEAR Vide le Simulation Data Inspector : tous ses runs.
%   SIMULINK.SDI.CLEAR.
%
%   Exemple :
%      Simulink.sdi.createRun('a');
%      Simulink.sdi.clear;
%      Simulink.sdi.getRunCount           % 0
%
%   Voir aussi SIMULINK.SDI.DELETERUN, SIMULINK.SDI.GETRUNCOUNT.
    matlibre_sdi('vider');
end
