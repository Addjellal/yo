function z = matlibre_id_decaler(obj, decalage)
%MATLIBRE_ID_DECALER Décale l'entrée par rapport à la sortie.
%   Z = MATLIBRE_ID_DECALER(OBJ,NK) avance l'entrée de NK échantillons.
%   Retirer ainsi un retard connu épargne à l'estimateur d'avoir à le
%   représenter par des coefficients nuls, qu'il devrait pourtant estimer.
%
%   Exemple :
%      z = nkshift(iddata((1:5)', (1:5)'), 1);
%      z.u(1)      % 2
%
%   Voir aussi IDDATA, NKSHIFT.
    z = obj;
    if isempty(obj.InputData) || decalage == 0
        return
    end
    experiences = matlibre_id_nombre_experiences(obj);
    for k = 1:experiences
        entree = matlibre_id_bloc(obj.InputData, k);
        n = size(entree, 1);
        decalee = zeros(size(entree));
        if decalage > 0
            garde = 1:(n - decalage);
            decalee(garde, :) = entree(garde + decalage, :);
            decalee((n - decalage + 1):n, :) = repmat(entree(n, :), decalage, 1);
        else
            recul = -decalage;
            decalee((recul + 1):n, :) = entree(1:(n - recul), :);
            decalee(1:recul, :) = repmat(entree(1, :), recul, 1);
        end
        z = matlibre_id_poser_bloc(z, 'InputData', k, decalee);
    end
end
