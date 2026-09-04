function texte = matlibre_formule_gauss(ordre)
%MATLIBRE_FORMULE_GAUSS Écriture d'une somme de gaussiennes.
%   T = MATLIBRE_FORMULE_GAUSS(ORDRE) rend la formule du modèle à ORDRE
%   cloches : chacune a son amplitude, son centre et sa largeur.
%
%   Exemple :
%      matlibre_formule_gauss(1)      % a1*exp(-((x-b1)/c1)^2)
%
%   Voir aussi FITTYPE, FIT.
    morceaux = cell(1, ordre);
    for k = 1:ordre
        morceaux{k} = sprintf('a%d*exp(-((x-b%d)/c%d)^2)', k, k, k);
    end
    texte = strjoin(morceaux, ' + ');
end
