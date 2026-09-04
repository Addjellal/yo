function repetitions = matlibre_dl_repetitions(arguments)
%MATLIBRE_DL_REPETITIONS Nombre de copies demandé à REPMAT.
%   R = MATLIBRE_DL_REPETITIONS(ARGUMENTS) accepte un vecteur, un nombre
%   — qui vaut alors pour les deux premières dimensions — ou une suite de
%   nombres, et rend le vecteur de répétitions.
%
%   Exemple :
%      matlibre_dl_repetitions({2})        % 2 2
%      matlibre_dl_repetitions({2, 3})     % 2 3
%
%   Voir aussi DLARRAY, REPMAT.
    if numel(arguments) == 1
        repetitions = double(arguments{1});
        if isscalar(repetitions)
            repetitions = [repetitions, repetitions];
        end
    else
        repetitions = zeros(1, numel(arguments));
        for k = 1:numel(arguments)
            repetitions(k) = double(arguments{k});
        end
    end
end
