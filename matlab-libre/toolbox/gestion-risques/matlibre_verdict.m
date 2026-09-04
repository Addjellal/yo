function texte = matlibre_verdict(rejete)
%MATLIBRE_VERDICT Écrit « accept » ou « reject ».
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if rejete
        texte = 'reject';
    else
        texte = 'accept';
    end
end
