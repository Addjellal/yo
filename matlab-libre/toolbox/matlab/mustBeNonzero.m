function mustBeNonzero(a)
%MUSTBENONZERO Exige une valeur non nulle.
%   MUSTBENONZERO(A) lève une erreur si un seul élément de A ne l'est pas.
%   Le contrôle porte sur tous les éléments : un tableau ne passe que s'il
%   passe entièrement.
%
%   Exemple :
%      mustBeNonzero(3);              % passe
%      mustBeNonzero([-1 1]);         % passe
%
%   Voir aussi MUSTBEPOSITIVE, MUSTBENONEMPTY, VALIDATEATTRIBUTES.
    matlibre_valider(all(a(:) ~= 0), 'MATLAB:validators:mustBeNonzero', ...
                     'La valeur doit être non nulle.');
end
