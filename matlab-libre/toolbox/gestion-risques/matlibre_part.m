function p = matlibre_part(numerateur, denominateur)
%MATLIBRE_PART Rapport, nul quand le dénominateur l'est.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if denominateur == 0
        p = 0;
    else
        p = numerateur / denominateur;
    end
end
