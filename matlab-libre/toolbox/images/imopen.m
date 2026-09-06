function y = imopen(x, element)
%IMOPEN Ouverture morphologique : érosion puis dilatation.
%   Y = IMOPEN(X,ELEMENT) efface ce qui est plus petit que l'élément
%   structurant, puis rend aux formes restantes leur taille.
%
%   L'ouverture est idempotente : l'appliquer deux fois ne change rien de
%   plus. C'est la propriété qui en fait un filtre au sens propre, et
%   c'est ce qui la distingue d'une érosion suivie d'une dilatation
%   quelconques.
%
%   Elle ne peut que retirer : le résultat est contenu dans l'original.
%
%   Exemple :
%      bruite = false(20); bruite(5:15, 5:15) = true; bruite(2, 2) = true;
%      propre = imopen(bruite, true(3));
%      propre(2, 2)                    % false : le point isole a disparu
%
%   Voir aussi IMCLOSE, IMERODE, IMDILATE.
    if nargin < 2
        element = ones(3, 3);
    end
    y = imdilate(imerode(x, element), element);
end
