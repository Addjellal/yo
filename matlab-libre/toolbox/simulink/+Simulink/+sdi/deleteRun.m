function deleteRun(id)
%DELETERUN Retire un run du Simulation Data Inspector, et ses signaux.
%   SIMULINK.SDI.DELETERUN(ID).
%
%   Exemple :
%      id = Simulink.sdi.createRun('provisoire');
%      Simulink.sdi.deleteRun(id);
%      any(Simulink.sdi.getAllRunIDs == id)   % false
%
%   Voir aussi SIMULINK.SDI.CLEAR, SIMULINK.SDI.DELETESIGNAL.
    matlibre_sdi('retirerrun', id);
end
