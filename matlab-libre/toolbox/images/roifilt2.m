function J = roifilt2(entree, I, masque, varargin)
%ROIFILT2 Filtre une image à l'intérieur d'une région seulement.
%   J = ROIFILT2(H,I,BW) filtre I par le noyau H, mais ne garde le
%   résultat que là où BW est vrai : ailleurs, l'image d'origine est
%   conservée.
%
%   J = ROIFILT2(I,BW,F) applique la fonction F à l'image entière et n'en
%   garde que la région.
%
%   Exemple :
%      I = mat2gray(peaks(50));
%      BW = poly2mask([10 40 40 10], [10 10 40 40], 50, 50);
%      J = roifilt2(fspecial('average', 5), I, BW);
%
%   Voir aussi IMFILTER, POLY2MASK, ROICOLOR, NLFILTER, BLOCKPROC.
    if nargin >= 3 && (isa(masque, 'function_handle') || ischar(masque) || isstring(masque))
        % Forme roifilt2(I, BW, F).
        image = double(entree);
        region = logical(I);
        fonction = masque;
        if ischar(fonction) || isstring(fonction)
            fonction = str2func(char(fonction));
        end
        filtree = double(fonction(image));
    else
        noyau = double(entree);
        image = double(I);
        region = logical(masque);
        filtree = imfilter(image, noyau, 'replicate');
    end
    if ~isequal(size(region), size(image))
        error('images:roifilt2:Taille', ...
              'Le masque doit avoir la taille de l''image.');
    end
    J = image;
    J(region) = filtree(region);
end
