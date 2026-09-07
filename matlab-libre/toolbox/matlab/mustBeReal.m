function mustBeReal(a)
%MUSTBEREAL Exige une valeur réelle.
%   MUSTBEREAL(A) lève une erreur si A a une partie imaginaire non nulle.
%
%   Un complexe dont la partie imaginaire est exactement nulle passe :
%   c'est ISREAL qui décide, et il regarde le stockage, non la valeur.
%
%   Exemple :
%      mustBeReal(3);                 % passe
%      mustBeReal([1 2 3]);           % passe
%
%   Voir aussi MUSTBENUMERIC, MUSTBEFINITE, ISREAL, COMPLEX.
    matlibre_valider(isreal(a), 'MATLAB:validators:mustBeReal', ...
                     'La valeur doit être réelle.');
end
