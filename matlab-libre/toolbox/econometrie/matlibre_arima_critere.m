function valeur = matlibre_arima_critere(obj, libres, parametres, serie)
%MATLIBRE_ARIMA_CRITERE Somme des carrés des innovations, avec pénalité.
%   Un modèle non stationnaire ou non inversible est refusé par une
%   valeur immense : l'optimiseur, qui ne connaît pas les contraintes,
%   apprend ainsi à les respecter.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    modele = matlibre_arima_poser(obj, libres, parametres);
    [phi, theta] = matlibre_arima_polynomes(modele);
    if ~matlibre_racines_admissibles(phi, theta)
        valeur = 1e12;
        return
    end
    innovations = matlibre_arima_residus(serie, modele.Constant, phi, theta);
    somme = sum(innovations .^ 2);
    if ~isfinite(somme)
        valeur = 1e12;
    else
        valeur = numel(serie) * log(somme / numel(serie));
    end
end
