function modele = add_line(modele, source, destination, entree)
%ADD_LINE Relie la sortie d'un bloc à l'entrée d'un autre.
%   MODELE = ADD_LINE(MODELE,'source','destination') ou
%   ADD_LINE(MODELE,'source','destination',NUMERO) pour choisir l'entrée.
    if nargin < 4
        entree = 1;
    end
    a = indiceBloc(modele, source);
    b = indiceBloc(modele, destination);
    modele.liens(end+1, :) = [a, b, entree];
end

function k = indiceBloc(modele, nom)
    k = 0;
    for i = 1:numel(modele.blocs)
        if strcmp(modele.blocs{i}.nom, nom)
            k = i;
            return;
        end
    end
    error('simulink:add_line:unknownBlock', 'Unknown block ''%s''.', nom);
end
