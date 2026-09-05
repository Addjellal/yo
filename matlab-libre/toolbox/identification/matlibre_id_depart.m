function depart = matlibre_id_depart(donnees, ordres)
%MATLIBRE_ID_DEPART Point de départ d'une estimation non linéaire.
%   D = MATLIBRE_ID_DEPART(Z,ORDRES) tire le point de départ d'une
%   estimation ARX, qui, elle, est exacte et sans départ.
%
%   Quand le modèle a un dénominateur propre à l'entrée — sortie-erreur,
%   Box-Jenkins —, c'est le dénominateur de l'ARX qui l'initialise ; les
%   polynômes du bruit partent de un, c'est-à-dire d'un bruit blanc.
%
%   Exemple :
%      d = matlibre_id_depart(z, [2 2 1 0 0 1]);
%
%   Voir aussi MATLIBRE_ID_ESTIMER, ARX.
    na = ordres(1); nb = ordres(2); nc = ordres(3);
    nd = ordres(4); nf = ordres(5); nk = ordres(6);
    denominateur = max(na, nf);
    depart = [];
    if nb > 0 && denominateur > 0
        provisoire = matlibre_id_moindres_carres(donnees, ...
                                                 [denominateur nb 0 0 0 nk], 'arx');
        coefficients = provisoire.A(2:end);
        numerateur = provisoire.B((nk + 1):end);
    elseif denominateur > 0
        provisoire = matlibre_id_moindres_carres(donnees, ...
                                                 [denominateur 0 0 0 0 nk], 'arx');
        coefficients = provisoire.A(2:end);
        numerateur = [];
    else
        coefficients = [];
        numerateur = zeros(1, nb);
    end
    if na > 0
        depart = [depart, coefficients(1:na)];
    end
    if nb > 0
        depart = [depart, numerateur(1:nb)];
    end
    % Les polynômes du bruit partent de l'identité : le bruit est d'abord
    % supposé blanc, et l'optimisation s'écarte de là si les données le
    % demandent.
    depart = [depart, zeros(1, nc), zeros(1, nd)];
    if nf > 0
        depart = [depart, coefficients(1:nf)];
    end
    depart = depart(:);
end
