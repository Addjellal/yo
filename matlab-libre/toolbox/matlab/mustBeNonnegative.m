function mustBeNonnegative(a)
%MUSTBENONNEGATIVE Exige une valeur positive ou nulle.
%   MUSTBENONNEGATIVE(A) lève une erreur si un seul élément de A ne l'est pas.
%   Le contrôle porte sur tous les éléments : un tableau ne passe que s'il
%   passe entièrement.
%
%   Exemple :
%      mustBeNonnegative(0);          % passe : zero est admis
%      mustBeNonnegative([0 1 2]);    % passe
%
%   Voir aussi MUSTBEPOSITIVE, MUSTBENONPOSITIVE, VALIDATEATTRIBUTES.
    matlibre_valider(all(a(:) >= 0), 'MATLAB:validators:mustBeNonnegative', ...
                     'La valeur doit être positive ou nulle.');
end
