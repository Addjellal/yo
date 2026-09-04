function y = matlibre_evaluer_rationnelle(coefficients, x, haut, bas)
%MATLIBRE_EVALUER_RATIONNELLE Quotient de deux polynômes.
%   Y = MATLIBRE_EVALUER_RATIONNELLE(C,X,HAUT,BAS) évalue la fraction dont
%   C donne d'abord les HAUT+1 coefficients du numérateur, puis les BAS
%   coefficients du dénominateur — dont le terme dominant vaut un.
%
%   Exemple :
%      matlibre_evaluer_rationnelle([1 0 0], 2, 1, 1)      % 1
%
%   Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
    x = x(:);
    numerateur = matlibre_base_polynome(x, haut) * coefficients(1:(haut + 1)).';
    if bas == 0
        y = numerateur;
        return
    end
    denominateur = x .^ bas;
    for k = 1:bas
        denominateur = denominateur + coefficients(haut + 1 + k) * x .^ (bas - k);
    end
    y = numerateur ./ denominateur;
end
