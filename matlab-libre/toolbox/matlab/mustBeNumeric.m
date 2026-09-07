function mustBeNumeric(a)
%MUSTBENUMERIC Exige une valeur numérique.
%   MUSTBENUMERIC(A) ne fait rien si A est numérique, et lève une erreur
%   sinon. Un logique n'est pas numérique ici : MUSTBENUMERICORLOGICAL
%   existe pour l'accepter.
%
%   Les validateurs ne rendent rien. C'est leur contrat : ils se taisent
%   quand tout va bien, et l'appelant n'a donc rien à tester. Ils servent
%   dans un bloc « arguments », où le nom du validateur suit le nom du
%   paramètre.
%
%   Exemple :
%      mustBeNumeric(3);              % passe
%      mustBeNumeric([1 2; 3 4]);     % passe aussi
%
%   Voir aussi MUSTBEREAL, MUSTBEFINITE, MUSTBEINTEGER, VALIDATEATTRIBUTES.
    matlibre_valider(isnumeric(a), 'MATLAB:validators:mustBeNumeric', ...
                     'La valeur doit être numérique.');
end
