function texte = matlibre_formule_sinus(ordre)
%MATLIBRE_FORMULE_SINUS Écriture d'une somme de sinusoïdes.
%   T = MATLIBRE_FORMULE_SINUS(ORDRE) rend la formule du modèle à ORDRE
%   sinusoïdes, chacune avec son amplitude, sa pulsation et sa phase.
%
%   Exemple :
%      matlibre_formule_sinus(1)      % a1*sin(b1*x + c1)
%
%   Voir aussi FITTYPE, FIT.
    morceaux = cell(1, ordre);
    for k = 1:ordre
        morceaux{k} = sprintf('a%d*sin(b%d*x + c%d)', k, k, k);
    end
    texte = strjoin(morceaux, ' + ');
end
