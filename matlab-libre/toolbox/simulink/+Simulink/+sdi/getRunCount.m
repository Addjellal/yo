function n = getRunCount()
%GETRUNCOUNT Le nombre de runs du Simulation Data Inspector.
%   N = SIMULINK.SDI.GETRUNCOUNT.
%
%   Exemple :
%      Simulink.sdi.clear;
%      Simulink.sdi.getRunCount           % 0
%
%   Voir aussi SIMULINK.SDI.GETALLRUNIDS, SIMULINK.SDI.CLEAR.
    n = numel(matlibre_sdi('runs'));
end
