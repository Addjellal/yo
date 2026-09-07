function mustBeNonNan(a)
%MUSTBENONNAN Refuse les valeurs manquantes.
%   MUSTBENONNAN(A) lève une erreur si A contient un NaN. Un infini passe,
%   à la différence de MUSTBEFINITE : l'infini est une valeur, le NaN est
%   l'absence de valeur.
%
%   Exemple :
%      mustBeNonNan([1 Inf 3]);       % passe : l'infini est une valeur
%      mustBeNonNan(0);               % passe
%
%   Voir aussi MUSTBEFINITE, ISNAN, ISMISSING.
    matlibre_valider(~any(isnan(a(:))), 'MATLAB:validators:mustBeNonNan', ...
                     'La valeur ne doit pas contenir de NaN.');
end
