function mustBeNegative(a)
%MUSTBENEGATIVE Exige une valeur strictement négative.
%   MUSTBENEGATIVE(A) lève une erreur si un seul élément de A ne l'est pas.
%   Le contrôle porte sur tous les éléments : un tableau ne passe que s'il
%   passe entièrement.
%
%   Exemple :
%      mustBeNegative(-3);            % passe
%      mustBeNegative([-1 -2]);       % passe
%
%   Voir aussi MUSTBENONPOSITIVE, MUSTBEPOSITIVE, VALIDATEATTRIBUTES.
    matlibre_valider(all(a(:) < 0), 'MATLAB:validators:mustBeNegative', ...
                     'La valeur doit être strictement négative.');
end
