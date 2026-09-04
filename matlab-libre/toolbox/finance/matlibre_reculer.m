function jour = matlibre_reculer(echeance, nombre, moisParPeriode, regleFinMois)
%MATLIBRE_RECULER Date de coupon située NOMBRE périodes avant l'échéance.
%   Le calcul part toujours de l'échéance : reculer d'un mois puis d'un
%   autre ne donne pas le même résultat que reculer de deux d'un coup,
%   dès qu'un mois est plus court que l'autre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    jour = datemnth(echeance, -nombre * moisParPeriode, 0, 0, regleFinMois);
end
