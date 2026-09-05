function critere = fpe(modele)
%FPE Critère d'erreur finale de prédiction d'Akaike.
%   V = FPE(MODELE) rend l'erreur quadratique corrigée du nombre de
%   paramètres :
%
%      FPE = V (1 + p/N) / (1 - p/N)
%
%   où V est l'erreur quadratique, p le nombre de paramètres et N le
%   nombre d'échantillons. Le facteur pénalise la richesse du modèle :
%   sans lui, un modèle plus riche paraîtrait toujours meilleur, puisqu'il
%   colle toujours mieux aux données dont il est tiré.
%
%   On compare deux modèles en prenant celui dont le critère est le plus
%   petit.
%
%   Exemple :
%      fpe(arx(z, [2 2 1])) < fpe(arx(z, [1 1 1]))
%
%   Voir aussi AIC, ARX, POLYEST.
    critere = matlibre_id_critere(modele, 'FPE');
end
