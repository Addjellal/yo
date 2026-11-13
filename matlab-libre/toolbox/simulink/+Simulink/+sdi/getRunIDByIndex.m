function id = getRunIDByIndex(k)
%GETRUNIDBYINDEX L'identifiant du K-ième run du Simulation Data Inspector.
%   ID = SIMULINK.SDI.GETRUNIDBYINDEX(K) ; un rang hors des runs est refusé.
%
%   Exemple :
%      Simulink.sdi.clear;
%      id = Simulink.sdi.createRun('a');
%      Simulink.sdi.getRunIDByIndex(1) == id   % true
%      Simulink.sdi.clear;
%
%   Voir aussi SIMULINK.SDI.GETALLRUNIDS, SIMULINK.SDI.GETRUN.
    ids = matlibre_sdi('runs');
    if ~isnumeric(k) || ~isscalar(k) || k < 1 || k > numel(ids) || k ~= round(k)
        error('SDI:sdi:IndexOutOfRange', ...
              'Le Simulation Data Inspector porte %d run(s) : il n''a pas de run %s.', ...
              numel(ids), strtrim(evalc('disp(k)')));
    end
    id = ids(k);
end
