function p = matlibre_clopper(alpha, erreurs, essais, borneBasse)
%MATLIBRE_CLOPPER Une borne de l'intervalle de Clopper-Pearson.
%   La borne basse est le p tel que P(X >= erreurs) = alpha, la borne
%   haute celui tel que P(X <= erreurs) = alpha, X suivant la binomiale
%   de paramètres (essais, p). La fonction est monotone en p : une
%   dichotomie suffit, et converge à la précision machine.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    bas = 0;
    haut = 1;
    for tour = 1:200
        milieu = (bas + haut) / 2;
        if borneBasse
            valeur = 1 - binocdf(erreurs - 1, essais, milieu);   % P(X >= k)
            % Croissante en p : on monte tant qu'on est en dessous.
            if valeur < alpha
                bas = milieu;
            else
                haut = milieu;
            end
        else
            valeur = binocdf(erreurs, essais, milieu);           % P(X <= k)
            % Décroissante en p.
            if valeur > alpha
                bas = milieu;
            else
                haut = milieu;
            end
        end
    end
    p = (bas + haut) / 2;
end
