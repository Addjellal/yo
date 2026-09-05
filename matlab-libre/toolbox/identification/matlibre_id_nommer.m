function obj = matlibre_id_nommer(obj)
%MATLIBRE_ID_NOMMER Donne un nom aux voies qui n'en ont pas.
%   OBJ = MATLIBRE_ID_NOMMER(OBJ) numérote les sorties « y1 », « y2 »… et
%   les entrées « u1 », « u2 »…, comme le fait MATLAB.
%
%   Exemple :
%      z = iddata([1;2], [3;4]);
%      z.OutputName{1}      % y1
%
%   Voir aussi IDDATA.
    sorties = matlibre_id_voies(obj.OutputData);
    entrees = matlibre_id_voies(obj.InputData);
    if numel(obj.OutputName) ~= sorties
        obj.OutputName = cell(1, sorties);
        for k = 1:sorties
            obj.OutputName{k} = sprintf('y%d', k);
        end
    end
    if numel(obj.InputName) ~= entrees
        obj.InputName = cell(1, entrees);
        for k = 1:entrees
            obj.InputName{k} = sprintf('u%d', k);
        end
    end
    if iscell(obj.OutputData) && numel(obj.ExperimentName) ~= numel(obj.OutputData)
        obj.ExperimentName = cell(1, numel(obj.OutputData));
        for k = 1:numel(obj.OutputData)
            obj.ExperimentName{k} = sprintf('Exp%d', k);
        end
    end
end
