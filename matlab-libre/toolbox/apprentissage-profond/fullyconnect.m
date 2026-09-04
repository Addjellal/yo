function y = fullyconnect(x, poids, biais, varargin)
%FULLYCONNECT Combinaison linéaire de toutes les entrées.
%   Y = FULLYCONNECT(X,POIDS,BIAIS) rend POIDS*X + BIAIS. X a une colonne
%   par observation, POIDS une ligne par sortie et une colonne par entrée.
%
%   Quand X porte plus de deux dimensions — une image, par exemple —, les
%   dimensions autres que celle des observations sont d'abord mises bout à
%   bout : c'est ce que fait MATLAB, et c'est ce qui permet de brancher
%   une couche dense derrière une couche convolutive sans rien aplatir à
%   la main.
%
%   FULLYCONNECT(...,'DataFormat',F) donne le format quand X n'en porte
%   pas ; seule la position de la dimension d'observation compte.
%
%   L'opération est dérivable : employée dans DLFEVAL, elle rend ses
%   dérivées par rapport à X, aux poids et au biais.
%
%   Exemple :
%      y = fullyconnect(dlarray([1; 2], 'CB'), [1 0; 0 1; 1 1], [0; 0; 0]);
%      extractdata(y)      % 1 ; 2 ; 3
%
%   Voir aussi DLARRAY, FULLYCONNECTEDLAYER, DLCONV, DLGRADIENT.
    format = '';
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'dataformat')
            format = upper(char(varargin{k + 1}));
        end
    end
    if isempty(format) && isa(x, 'dlarray')
        format = dims(x);
    end
    taille = size(x);
    if numel(taille) > 2 || (~isempty(format) && numel(format) > 2)
        observations = matlibre_dl_position_lot(format, numel(taille));
        x = matlibre_dl_aplatir(x, observations, taille);
    end
    y = poids * x + biais;
    if isa(y, 'dlarray')
        y = dlarray(y, 'CB');
    end
end
