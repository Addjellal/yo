function y = imfilter(x, h, varargin)
%IMFILTER Filtrage linéaire d'une image par corrélation.
%   Y = IMFILTER(X,H) corrèle X avec le noyau H, les bords étant
%   répliqués. Y = IMFILTER(X,H,'conv') fait une convolution.
%
%   Le travail est confié à CONV2, qui est natif : l'image est d'abord
%   agrandie par réplication des bords, puis filtrée en mode « valid ».
%   Un noyau retourné transforme la convolution de CONV2 en corrélation.
    convolution = false;
    for k = 1:numel(varargin)
        if ischar(varargin{k}) && strcmpi(varargin{k}, 'conv')
            convolution = true;
        end
    end
    x = double(x);
    [hauteur, largeur] = size(x);
    [hn, ln] = size(h);
    di = floor(hn / 2);
    dj = floor(ln / 2);
    % Réplication des bords par indexation.
    lignes = [ones(1, di), 1:hauteur, hauteur * ones(1, hn - di - 1)];
    colonnes = [ones(1, dj), 1:largeur, largeur * ones(1, ln - dj - 1)];
    etendue = x(lignes, colonnes);
    if convolution
        noyau = h;
    else
        noyau = h(end:-1:1, end:-1:1);
    end
    y = conv2(etendue, noyau, 'valid');
end
