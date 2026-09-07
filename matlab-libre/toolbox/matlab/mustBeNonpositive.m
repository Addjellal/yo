function mustBeNonpositive(a)
%MUSTBENONPOSITIVE Exige une valeur négative ou nulle.
%   MUSTBENONPOSITIVE(A) lève une erreur si un seul élément de A ne l'est pas.
%   Le contrôle porte sur tous les éléments : un tableau ne passe que s'il
%   passe entièrement.
%
%   Exemple :
%      mustBeNonpositive(0);          % passe : zero est admis
%      mustBeNonpositive([-1 0]);     % passe
%
%   Voir aussi MUSTBENEGATIVE, MUSTBENONNEGATIVE, VALIDATEATTRIBUTES.
    matlibre_valider(all(a(:) <= 0), 'MATLAB:validators:mustBeNonpositive', ...
                     'La valeur doit être négative ou nulle.');
end
