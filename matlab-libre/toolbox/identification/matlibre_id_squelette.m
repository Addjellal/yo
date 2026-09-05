function modele = matlibre_id_squelette(ordres, periode)
%MATLIBRE_ID_SQUELETTE Modèle vide aux ordres donnés.
%   M = MATLIBRE_ID_SQUELETTE([na nb nc nd nf nk],TS) rend un IDPOLY dont
%   les polynômes ont la bonne longueur et des coefficients nuls : c'est
%   la forme que l'estimation viendra remplir.
%
%   Exemple :
%      m = matlibre_id_squelette([1 1 0 0 0 1], 0.1);
%      numel(m.B)      % 2
%
%   Voir aussi POLYEST, MATLIBRE_ID_POSER_PARAMETRES.
    na = ordres(1); nb = ordres(2); nc = ordres(3);
    nd = ordres(4); nf = ordres(5); nk = ordres(6);
    modele = idpoly();
    modele.A = [1, zeros(1, na)];
    if nb > 0
        modele.B = zeros(1, nk + nb);
    else
        modele.B = [];
    end
    modele.C = [1, zeros(1, nc)];
    modele.D = [1, zeros(1, nd)];
    modele.F = [1, zeros(1, nf)];
    modele.Ts = periode;
    modele.Ordres = ordres;
end
