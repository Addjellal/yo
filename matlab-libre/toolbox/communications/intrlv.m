function y = intrlv(donnees, permutation)
%INTRLV Entrelacement par une permutation donnée.
%   Y = INTRLV(DONNEES,PERMUTATION) range les éléments dans l'ordre
%   indiqué : Y(k) = DONNEES(PERMUTATION(k)). Entrelacer sert à répartir
%   les erreurs en rafale sur plusieurs mots de code, là où un code
%   correcteur sait les traiter.
%
%   Si DONNEES est une matrice, chaque colonne est entrelacée séparément.
%
%   Exemple :
%      intrlv([10 20 30 40], [3 1 4 2])   % [30 10 40 20]
%
%   Voir aussi DEINTRLV, RANDINTRLV, MATINTRLV.
    permutation = round(double(permutation(:)))';
    verifierPermutation(permutation);
    if isvector(donnees)
        if numel(donnees) ~= numel(permutation)
            error('comm:intrlv:BadLength', ...
                  'La permutation doit avoir la longueur des données.');
        end
        y = donnees(permutation);
        if iscolumn(donnees), y = y(:); end
    else
        if size(donnees, 1) ~= numel(permutation)
            error('comm:intrlv:BadLength', ...
                  'La permutation doit avoir autant d''éléments que de lignes.');
        end
        y = donnees(permutation, :);
    end
end
