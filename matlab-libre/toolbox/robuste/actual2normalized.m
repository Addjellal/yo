function normalise = actual2normalized(atome, valeur)
%ACTUAL2NORMALIZED Passe de la valeur réelle d'un paramètre à sa valeur normalisée.
%   N = ACTUAL2NORMALIZED(P,V) rend la valeur normalisée qui correspond à
%   la valeur réelle V du paramètre incertain P. La normalisation envoie
%   la valeur nominale sur zéro, la borne haute sur un et la borne basse
%   sur moins un :
%
%      N = (V - nominal) / (haut - nominal)     si V dépasse le nominal
%      N = (V - nominal) / (nominal - bas)      sinon
%
%   C'est la coordonnée dans laquelle l'analyse de robustesse travaille :
%   un rayon de robustesse de 1.4 veut dire que la boucle tient jusqu'à
%   1.4 fois l'écart déclaré, quel que soit le paramètre.
%
%   V peut être un tableau ; N a la même taille.
%
%   Exemples :
%      p = ureal('p', 10, 'Range', [8 15]);
%      actual2normalized(p, 10)           % 0 : le nominal
%      actual2normalized(p, 15)           % 1 : la borne haute
%      actual2normalized(p, 8)            % -1 : la borne basse
%      actual2normalized(p, 20)           % 2 : deux fois l'ecart
%
%   Voir aussi NORMALIZED2ACTUAL, UREAL, ROBSTAB, WCGAIN.
    [nominal, bas, haut] = matlibre_bornes_atome(atome);
    valeur = double(valeur);
    normalise = zeros(size(valeur));
    for k = 1:numel(valeur)
        if valeur(k) >= nominal
            portee = haut - nominal;
        else
            portee = nominal - bas;
        end
        if portee == 0
            normalise(k) = 0;
        else
            normalise(k) = (valeur(k) - nominal) / portee;
        end
    end
end
