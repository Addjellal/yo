function fraction = matlibre_reel_sur_reel(d1, d2)
%MATLIBRE_REEL_SUR_REEL Fraction d'année, convention réel sur réel.
%   La période est découpée par années civiles ; chaque morceau est
%   divisé par la longueur de l'année qui le contient. C'est ce qui fait
%   qu'une année pleine vaut exactement un, qu'elle soit bissextile ou
%   non.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    signe = 1;
    if d2 < d1
        [d1, d2] = deal(d2, d1);
        signe = -1;
    end
    composants = datevec([d1; d2]);
    premiere = composants(1, 1);
    derniere = composants(2, 1);
    fraction = 0;
    for annee = premiere:derniere
        debutAnnee = datenum(annee, 1, 1);
        finAnnee = datenum(annee + 1, 1, 1);
        morceau = min(d2, finAnnee) - max(d1, debutAnnee);
        if morceau > 0
            fraction = fraction + morceau / (finAnnee - debutAnnee);
        end
    end
    fraction = signe * fraction;
end
