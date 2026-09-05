function critere = aic(modele, genre)
%AIC Critère d'information d'Akaike.
%   V = AIC(MODELE) rend N log(V) + 2p, où V est l'erreur quadratique, p
%   le nombre de paramètres et N le nombre d'échantillons.
%
%   V = AIC(MODELE,'nAIC') rend le critère normalisé par le nombre
%   d'échantillons, et V = AIC(MODELE,'BIC') remplace la pénalité par
%   p log(N), plus sévère : elle croît avec la taille des données, si bien
%   que le critère finit par désigner le vrai modèle quand il est dans la
%   liste, ce que le critère d'Akaike ne garantit pas.
%
%   Exemple :
%      aic(arx(z, [2 2 1]))
%
%   Voir aussi FPE, ARX, POLYEST.
    if nargin < 2
        genre = 'aic';
    end
    valeur = matlibre_id_critere(modele, 'MSE');
    n = matlibre_id_critere(modele, 'nobs');
    p = matlibre_id_critere(modele, 'nparams');
    switch lower(char(genre))
        case 'aic'
            critere = n * log(max(valeur, realmin)) + 2 * p;
        case 'naic'
            critere = log(max(valeur, realmin)) + 2 * p / n;
        case 'bic'
            critere = n * log(max(valeur, realmin)) + p * log(n);
        otherwise
            error('ident:aic:Genre', 'Critère inconnu : %s.', char(genre));
    end
end
