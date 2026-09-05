function z = matlibre_id_experience(obj, indice)
%MATLIBRE_ID_EXPERIENCE Une expérience d'un jeu qui en porte plusieurs.
%   Z = MATLIBRE_ID_EXPERIENCE(OBJ,INDICE) rend le jeu réduit à cette
%   seule expérience.
%
%   Exemple :
%      z = merge(iddata((1:5)'), iddata((6:10)'));
%      getexp(z, 2).N      % 5
%
%   Voir aussi IDDATA, MERGE.
    z = obj;
    if ~iscell(obj.OutputData)
        return
    end
    z.OutputData = obj.OutputData{indice};
    if iscell(obj.InputData) && ~isempty(obj.InputData)
        z.InputData = obj.InputData{indice};
    end
    if numel(obj.ExperimentName) >= indice
        z.ExperimentName = obj.ExperimentName(indice);
    end
end
