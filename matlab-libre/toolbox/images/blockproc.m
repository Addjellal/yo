function sortie = blockproc(image, taille, fonction, varargin)
%BLOCKPROC Applique une fonction bloc par bloc.
%   B = BLOCKPROC(A,[M N],FUN) découpe A en blocs disjoints de M x N et
%   applique FUN à chacun. FUN reçoit une structure dont le champ `data`
%   porte le bloc, comme dans MATLAB.
%
%   Exemple :
%      blockproc(magic(4), [2 2], @(b) mean(b.data(:)) * ones(2))
    image = double(image);
    [h, l] = size(image);
    m = taille(1);
    n = taille(2);
    sortie = [];
    for a = 1:m:h
        ligneBlocs = [];
        for b = 1:n:l
            finLigne = min(a + m - 1, h);
            finColonne = min(b + n - 1, l);
            bloc = struct('data', image(a:finLigne, b:finColonne), ...
                          'location', [a b], 'blockSize', [finLigne-a+1 finColonne-b+1], ...
                          'imageSize', [h l]);
            resultat = fonction(bloc);
            ligneBlocs = [ligneBlocs resultat];        %#ok<AGROW>
        end
        sortie = [sortie; ligneBlocs];                 %#ok<AGROW>
    end
end
