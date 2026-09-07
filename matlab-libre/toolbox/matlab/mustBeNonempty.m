function mustBeNonempty(a)
%MUSTBENONEMPTY Refuse une valeur vide.
%   MUSTBENONEMPTY(A) lève une erreur si A est vide.
%
%   Exemple :
%      mustBeNonempty([1 2]);         % passe
%      mustBeNonempty('a');           % passe
%
%   Voir aussi MUSTBEVECTOR, ISEMPTY, MUSTBENUMERIC.
    matlibre_valider(~isempty(a), 'MATLAB:validators:mustBeNonempty', ...
                     'La valeur ne doit pas être vide.');
end
