function [achat, vente] = matlibre_bls_general(cours, exercice, taux, portage, duree, volatilite)
%MATLIBRE_BLS_GENERAL Formule de Black et Scholes à coût de portage.
%   Le coût de portage vaut le taux moins le rendement de dividende pour
%   une action, zéro pour un contrat à terme, la différence des taux pour
%   une devise. Une seule formule couvre les trois.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    racine = volatilite .* sqrt(duree);
    d1 = (log(cours ./ exercice) + (portage + volatilite .^ 2 / 2) .* duree) ./ racine;
    d2 = d1 - racine;
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    escompte = exp((portage - taux) .* duree);
    achat = cours .* escompte .* N(d1) - exercice .* exp(-taux .* duree) .* N(d2);
    vente = exercice .* exp(-taux .* duree) .* N(-d2) - cours .* escompte .* N(-d1);
end
