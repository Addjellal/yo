function c = conndef(n, type)
%CONNDEF Tableau de connexité par défaut.
%   C = CONNDEF(N,TYPE) où TYPE vaut 'minimal' (les voisins qui partagent
%   une face) ou 'maximal' (tous les voisins immédiats).
%
%   Exemple :
%      conndef(2, 'minimal')   % [0 1 0; 1 1 1; 0 1 0]
    if nargin < 2 || isempty(type), type = 'maximal'; end
    n = round(n);
    dimensions = repmat(3, 1, max(n, 2));
    if strncmpi(char(type), 'max', 3)
        c = true(dimensions);
        return
    end
    c = false(dimensions);
    centre = num2cell(repmat(2, 1, numel(dimensions)));
    c(centre{:}) = true;
    for d = 1:numel(dimensions)
        for decalage = [-1 1]
            position = centre;
            position{d} = 2 + decalage;
            c(position{:}) = true;
        end
    end
end
