function modele = set_param(modele, nom, varargin)
%SET_PARAM Modifie les paramètres d'un bloc.
    for i = 1:numel(modele.blocs)
        if strcmp(modele.blocs{i}.nom, nom)
            b = modele.blocs{i};
            for k = 1:2:numel(varargin)-1
                b.parametres.(char(varargin{k})) = varargin{k+1};
            end
            modele.blocs{i} = b;
            return;
        end
    end
    error('simulink:set_param:unknownBlock', 'Unknown block ''%s''.', nom);
end
