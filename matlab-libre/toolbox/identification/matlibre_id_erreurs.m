function e = matlibre_id_erreurs(modele, y, u)
%MATLIBRE_ID_ERREURS Erreurs de prédiction à un pas d'un modèle.
%   E = MATLIBRE_ID_ERREURS(MODELE,Y,U) rend le bruit blanc que le modèle
%   impute aux données :
%
%      e = (D/C) [ A y - (B/F) u ]
%
%   C'est cette suite dont l'estimation minimise la somme des carrés :
%   ajuster un modèle, c'est chercher les polynômes qui rendent l'erreur
%   de prédiction aussi petite — et aussi blanche — que possible.
%
%   Exemple :
%      m = idpoly([1 -0.8], [0 0.2]);
%      e = matlibre_id_erreurs(m, [0; 1; 2], [0; 1; 1]);
%
%   Voir aussi PREDICT, RESID, POLYEST.
    y = y(:);
    partieSortie = filter(modele.A, 1, y);
    if isempty(modele.B) || isempty(u)
        partieEntree = zeros(size(y));
    else
        partieEntree = filter(modele.B, modele.F, u(:));
    end
    e = filter(modele.D, modele.C, partieSortie - partieEntree);
end
