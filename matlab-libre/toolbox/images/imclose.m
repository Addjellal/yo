function y = imclose(x, element)
%IMCLOSE Fermeture morphologique : dilatation puis érosion.
%   Y = IMCLOSE(X,ELEMENT) bouche les trous plus petits que l'élément
%   structurant, puis rend aux formes leur taille.
%
%   La fermeture est elle aussi idempotente, et duale de l'ouverture : la
%   fermeture du complément est le complément de l'ouverture. Elle ne peut
%   qu'ajouter — le résultat contient l'original.
%
%   Exemple :
%      troue = true(20); troue(10, 10) = false;
%      imclose(troue, true(3))(10, 10)    % true : le trou est bouche
%
%   Voir aussi IMOPEN, IMDILATE, IMERODE.
    if nargin < 2
        element = ones(3, 3);
    end
    y = imerode(imdilate(x, element), element);
end
