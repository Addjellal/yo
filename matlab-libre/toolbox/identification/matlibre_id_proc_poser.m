function modele = matlibre_id_proc_poser(p, type, poles, avecZero, avecRetard)
%MATLIBRE_ID_PROC_POSER Reconstruit un modèle de procédé depuis ses paramètres.
%   M = MATLIBRE_ID_PROC_POSER(P,TYPE,POLES,AVECZERO,AVECRETARD) range le
%   vecteur dans les champs du modèle, dans l'ordre où l'estimation les a
%   mis : gain, constantes de temps, zéro, retard.
%
%   Exemple :
%      m = matlibre_id_proc_poser([2; 4; 1], 'P1D', 1, false, true);
%
%   Voir aussi PROCEST, IDPROC.
    p = double(p(:));
    modele = idproc(type);
    modele.K = p(1);
    position = 1;
    constantes = zeros(1, 3);
    for k = 1:poles
        position = position + 1;
        constantes(k) = p(position);
    end
    modele.Tp1 = constantes(1);
    modele.Tp2 = constantes(2);
    modele.Tp3 = constantes(3);
    if avecZero
        position = position + 1;
        modele.Tz = p(position);
    end
    if avecRetard
        position = position + 1;
        modele.Td = p(position);
    end
end
