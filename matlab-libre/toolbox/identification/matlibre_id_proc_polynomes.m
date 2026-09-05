function [numerateur, denominateur] = matlibre_id_proc_polynomes(modele)
%MATLIBRE_ID_PROC_POLYNOMES Fonction de transfert d'un modèle de procédé.
%   [NUM,DEN] = MATLIBRE_ID_PROC_POLYNOMES(MODELE) développe les
%   constantes de temps en polynômes en s. Le retard n'y figure pas : il
%   s'applique à part, sur le signal.
%
%   Exemple :
%      [n, d] = matlibre_id_proc_polynomes(idproc('P1', 'K', 2, 'Tp1', 3));
%      d      % 3 1
%
%   Voir aussi IDPROC, PROCEST.
    numerateur = modele.K;
    if modele.Tz ~= 0
        numerateur = conv(numerateur, [modele.Tz, 1]);
    end
    denominateur = 1;
    for constante = [modele.Tp1, modele.Tp2, modele.Tp3]
        if constante ~= 0
            denominateur = conv(denominateur, [constante, 1]);
        end
    end
    if any(modele.Type == 'I')
        denominateur = conv(denominateur, [1, 0]);
    end
end
