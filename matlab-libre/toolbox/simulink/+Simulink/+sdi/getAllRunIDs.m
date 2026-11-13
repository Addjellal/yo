function ids = getAllRunIDs()
%GETALLRUNIDS Les identifiants des runs du Simulation Data Inspector.
%   IDS = SIMULINK.SDI.GETALLRUNIDS rend leur colonne, dans l'ordre où
%   les runs ont été créés.
%
%   Exemple :
%      Simulink.sdi.clear;
%      Simulink.sdi.createRun('a');
%      numel(Simulink.sdi.getAllRunIDs)   % 1
%      Simulink.sdi.clear;
%
%   Voir aussi SIMULINK.SDI.GETRUNCOUNT, SIMULINK.SDI.GETRUNIDBYINDEX.
    ids = matlibre_sdi('runs');
    ids = ids(:);
end
