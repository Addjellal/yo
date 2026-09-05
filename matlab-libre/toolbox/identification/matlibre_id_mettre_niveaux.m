function u = matlibre_id_mettre_niveaux(u, niveaux, binaire)
%MATLIBRE_ID_METTRE_NIVEAUX Ramène un signal aux niveaux demandés.
%   U = MATLIBRE_ID_METTRE_NIVEAUX(U,NIVEAUX,BINAIRE) met le signal entre
%   les deux niveaux. Un signal binaire n'y prend que les deux valeurs
%   extrêmes ; un signal continu est mis à l'échelle et centré.
%
%   Exemple :
%      matlibre_id_mettre_niveaux([-1; 1], [0 10], true)      % 0 ; 10
%
%   Voir aussi IDINPUT.
    niveaux = double(niveaux);
    if binaire
        u = niveaux(1) + (niveaux(2) - niveaux(1)) * double(u > 0);
        return
    end
    etendue = max(u) - min(u);
    if etendue == 0
        u = repmat(mean(niveaux), size(u));
        return
    end
    u = niveaux(1) + (niveaux(2) - niveaux(1)) * (u - min(u)) / etendue;
end
