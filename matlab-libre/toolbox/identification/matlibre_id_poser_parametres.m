function modele = matlibre_id_poser_parametres(modele, p)
%MATLIBRE_ID_POSER_PARAMETRES Remplace les paramètres libres d'un modèle.
%   MODELE = MATLIBRE_ID_POSER_PARAMETRES(MODELE,P) redistribue le vecteur
%   dans A, B, C, D et F, en respectant la longueur de chacun et le retard
%   que porte B.
%
%   Exemple :
%      m = setpvec(idpoly([1 0], [0 0]), [-0.5; 0.3]);
%      m.A      % 1 -0.5
%
%   Voir aussi GETPVEC, POLYEST.
    p = double(p(:)).';
    nk = matlibre_id_retard_modele(modele);
    na = numel(modele.A) - 1;
    nb = max(numel(modele.B) - nk, 0);
    nc = numel(modele.C) - 1;
    nd = numel(modele.D) - 1;
    nf = numel(modele.F) - 1;
    position = 0;
    if na > 0
        modele.A = [1, p((position + 1):(position + na))];
        position = position + na;
    end
    if nb > 0
        modele.B = [zeros(1, nk), p((position + 1):(position + nb))];
        position = position + nb;
    end
    if nc > 0
        modele.C = [1, p((position + 1):(position + nc))];
        position = position + nc;
    end
    if nd > 0
        modele.D = [1, p((position + 1):(position + nd))];
        position = position + nd;
    end
    if nf > 0
        modele.F = [1, p((position + 1):(position + nf))];
    end
    modele.ParameterVector = matlibre_id_parametres(modele);
end
