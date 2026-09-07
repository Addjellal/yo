function mustBeInteger(a)
%MUSTBEINTEGER Exige des valeurs entières.
%   MUSTBEINTEGER(A) lève une erreur si un élément de A n'est pas un
%   entier. Le contrôle porte sur la valeur, non sur la classe : 3 en
%   double passe, 3,5 non.
%
%   Un NaN ou un infini est refusé : ni l'un ni l'autre n'est un entier.
%
%   Exemple :
%      mustBeInteger(3);              % passe, bien que ce soit un double
%      mustBeInteger([1 2 3]);        % passe
%      mustBeInteger(int8(5));        % passe
%
%   Voir aussi MUSTBEPOSITIVE, MUSTBEFINITE, ROUND, ISINTEGER.
    v = double(a(:));
    matlibre_valider(all(isfinite(v)) && all(v == round(v)), ...
                     'MATLAB:validators:mustBeInteger', ...
                     'La valeur doit être entière.');
end
