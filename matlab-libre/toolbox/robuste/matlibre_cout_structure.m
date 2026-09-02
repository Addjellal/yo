function valeur = matlibre_cout_structure(point, noms, bas, haut, evaluer, P)
%MATLIBRE_COUT_STRUCTURE La norme de la boucle pour un jeu de paramètres.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   HINFSTRUCT s'en sert. Un point hors des bornes est ramené dedans et
%   pénalisé, ce qui laisse le simplexe travailler sans contrainte
%   explicite ; une boucle instable rend un très grand nombre fini, pour
%   que la comparaison reste possible.
    ramene = min(max(point, bas), haut);
    penalite = sum(abs(point - ramene));
    valeurs = matlibre_point_vers_valeurs(noms, ramene);
    K = ss(evaluer(valeurs));
    boucle = lft(ss(P), K);
    gamma = hinfnorm(boucle);
    if ~isfinite(gamma)
        gamma = 1e12;
    end
    valeur = gamma * (1 + penalite);
end
