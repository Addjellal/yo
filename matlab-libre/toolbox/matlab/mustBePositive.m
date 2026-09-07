function mustBePositive(a)
%MUSTBEPOSITIVE Exige une valeur strictement positive.
%   MUSTBEPOSITIVE(A) lève une erreur si un seul élément de A ne l'est pas.
%   Le contrôle porte sur tous les éléments : un tableau ne passe que s'il
%   passe entièrement.
%
%   Exemple :
%      mustBePositive(3);             % passe
%      mustBePositive([1 2 3]);       % passe
%
%   Voir aussi MUSTBENONNEGATIVE, MUSTBENEGATIVE, MUSTBENONZERO, VALIDATEATTRIBUTES.
    matlibre_valider(all(a(:) > 0), 'MATLAB:validators:mustBePositive', ...
                     'La valeur doit être strictement positive.');
end
