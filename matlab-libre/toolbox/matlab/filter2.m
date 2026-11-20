function Y = filter2(H, X, forme)
%FILTER2 Filtrage bidimensionnel par corrélation.
%   Y = FILTER2(H,X) filtre la matrice X par le noyau H, au sens de la
%   corrélation : chaque sortie est la somme des produits de H et de la
%   fenêtre de X qui lui fait face, sans retourner H. C'est CONV2 avec le
%   noyau tourné d'un demi-tour, conv2(X, rot90(H,2), FORME), comme
%   MATLAB. Y a la taille de X.
%   Y = FILTER2(H,X,FORME) choisit la partie rendue : 'same' (défaut),
%   'valid' (les fenêtres entièrement dans X) ou 'full'.
%
%   Exemple :
%      filter2([1 2; 3 4], magic(3), 'valid')      % [1*8+2*1+3*3+4*5 ...]
%      isequal(filter2([1 2; 3 4], magic(3), 'valid'), conv2(magic(3), [4 3; 2 1], 'valid'))   % 1
%
%   Voir aussi CONV2, FILTER, XCORR2, IMFILTER.
    if nargin < 3
        forme = 'same';
    end
    if ~any(strcmpi(forme, {'same', 'valid', 'full'}))
        error('MATLAB:filter2:BadShape', 'FORME vaut ''same'', ''valid'' ou ''full''.');
    end
    Y = conv2(X, rot90(H, 2), lower(char(forme)));
end
