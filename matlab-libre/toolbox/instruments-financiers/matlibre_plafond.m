function [prix, morceaux] = matlibre_plafond(courbe, exercice, reglement, echeance, volatilite, frequence, base, nominal, sens)
%MATLIBRE_PLAFOND Somme des options élémentaires d'un plafond ou d'un plancher.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    reglement = matlibre_dates(reglement);
    dates = matlibre_dates_reset(reglement, echeance, frequence);
    facteurs = matlibre_courbe_escompte(courbe, dates);
    facteurDepart = matlibre_courbe_escompte(courbe, reglement);
    precedentsFacteurs = [facteurDepart(1); facteurs(1:end-1)];
    precedentesDates = [reglement; dates(1:end-1).'];
    morceaux = zeros(numel(dates), 1);
    for k = 1:numel(dates)
        duree = yearfrac(precedentesDates(k), dates(k), base);
        tauxTerme = (precedentsFacteurs(k) / facteurs(k) - 1) / duree;
        expiration = yearfrac(reglement, precedentesDates(k), base);
        if expiration <= 0
            % Première période : le taux est déjà connu, il n'y a plus
            % d'incertitude et donc plus d'option.
            intrinseque = max(tauxTerme - exercice, 0);
            if strcmp(sens, 'floor')
                intrinseque = max(exercice - tauxTerme, 0);
            end
            morceaux(k) = nominal * duree * facteurs(k) * intrinseque;
            continue
        end
        racine = volatilite * sqrt(expiration);
        d1 = (log(tauxTerme / exercice) + volatilite ^ 2 / 2 * expiration) / racine;
        d2 = d1 - racine;
        if strcmp(sens, 'floor')
            valeur = exercice * N(-d2) - tauxTerme * N(-d1);
        else
            valeur = tauxTerme * N(d1) - exercice * N(d2);
        end
        morceaux(k) = nominal * duree * facteurs(k) * valeur;
    end
    prix = sum(morceaux);
end
