function r = isnat(x)
%ISNAT Vrai pour les éléments manquants d'un tableau datetime.
%   R = ISNAT(X) rend un tableau logique de la taille de X, vrai là où la
%   date est manquante.
%
%   NaT est à datetime ce que NaN est à double : une valeur qui se
%   propage dans les calculs et qui n'est égale à rien, pas même à
%   elle-même. C'est pourquoi il faut ISNAT et non une comparaison.
%
%   Sur un tableau qui n'est pas un datetime, la fonction rend faux
%   partout plutôt qu'une erreur : cela permet de l'employer sans tester
%   la classe d'abord.
%
%   Exemple :
%      d = [datetime(2024,1,1), NaT];
%      isnat(d)                        % [false true]
%      d(~isnat(d))                    % ne garde que les dates connues
%
%   Voir aussi ISDATETIME, NAT, ISMISSING, ISNAN.
    if isa(x, 'datetime')
        r = isnan(x.Serie);
    else
        r = false(size(x));
    end
end
