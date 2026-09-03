function y = intdump(x, facteur)
%INTDUMP Intégration et vidage.
%   Y = INTDUMP(X,N) découpe X en tranches de N échantillons et rend la
%   moyenne de chacune : c'est le filtre adapté d'une impulsion
%   rectangulaire, celui qu'on met en bout de chaîne quand chaque symbole
%   a été suréchantillonné d'un facteur N.
%
%   X peut être une matrice : chaque colonne est traitée à part. Le
%   nombre de lignes doit être un multiple de N.
%
%   Exemple :
%      intdump([1 1 1 1 3 3 3 3], 4)   % [1 3]
%
%   Voir aussi RCOSDESIGN, PAMDEMOD, UPSAMPLE, DOWNSAMPLE.
    facteur = round(facteur);
    if facteur < 1
        error('comm:intdump:Facteur', 'Le facteur doit valoir au moins un.');
    end
    ligne = isrow(x);
    if isvector(x)
        x = x(:);
    end
    [n, colonnes] = size(x);
    if mod(n, facteur) ~= 0
        error('comm:intdump:Longueur', ...
              'Le nombre d''échantillons doit être un multiple de %d.', facteur);
    end
    y = zeros(n / facteur, colonnes);
    for c = 1:colonnes
        bloc = reshape(x(:, c), facteur, []);
        y(:, c) = (sum(bloc, 1) / facteur).';
    end
    if ligne
        y = y.';
    end
end
