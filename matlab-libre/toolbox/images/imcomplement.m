function c = imcomplement(image)
%IMCOMPLEMENT Négatif d'une image.
%   Pour un double dans [0,1], c'est 1-X ; pour un uint8, 255-X ; pour un
%   logique, la négation.
%
%   Exemple :
%      imcomplement([0 0.25 1])    % 1 0.75 0
%      imcomplement(uint8([0 255]))    % 255 0
    if islogical(image)
        c = ~image;
    elseif isa(image, 'uint8')
        c = uint8(255) - image;
    elseif isinteger(image)
        c = intmax(class(image)) - image;
    else
        c = 1 - image;
    end
end
