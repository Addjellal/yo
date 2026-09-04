function etiquettes = onehotdecode(A, classes, dimension, genre)
%ONEHOTDECODE Indicatrices ou probabilités en étiquettes.
%   E = ONEHOTDECODE(A,CLASSES,DIM) rend, pour chaque observation, la
%   classe de plus grande valeur. C'est l'opération inverse de
%   ONEHOTENCODE, et c'est aussi ce qui transforme la sortie d'un
%   classifieur en décision.
%
%   E = ONEHOTDECODE(A,CLASSES,DIM,GENRE) où GENRE vaut 'categorical'
%   (défaut), 'string', 'double' ou 'cell'.
%
%   Exemple :
%      onehotdecode([0.2 0.9; 0.8 0.1], {'a','b'}, 1)      % b, a
%
%   Voir aussi ONEHOTENCODE, CLASSIFY, CATEGORICAL.
    if nargin < 3
        dimension = 1;
    end
    if nargin < 4
        genre = 'categorical';
    end
    A = double(A);
    if dimension == 2
        A = A.';
    end
    [~, positions] = max(A, [], 1);
    if iscell(classes)
        noms = classes;
    elseif iscategorical(classes)
        noms = cellstr(classes);
    else
        noms = cellstr(num2str(classes(:)));
    end
    choisies = noms(positions);
    switch lower(genre)
        case 'categorical', etiquettes = categorical(choisies, noms);
        case 'string',      etiquettes = string(choisies);
        case 'cell',        etiquettes = choisies;
        case 'double',      etiquettes = positions(:);
        otherwise
            error('nnet:onehotdecode:Genre', 'Genre inconnu : %s.', genre);
    end
    if strcmp(lower(genre), 'categorical') || strcmp(lower(genre), 'string')
        etiquettes = reshape(etiquettes, [], 1);
    end
end
