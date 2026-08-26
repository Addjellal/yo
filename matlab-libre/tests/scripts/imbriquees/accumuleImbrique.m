function total = accumuleImbrique(v)
%ACCUMULEIMBRIQUE Somme un vecteur avec une fonction imbriquée.
    total = 0;
    for k = 1:numel(v)
        ajouter(v(k));
    end
    function ajouter(x)
        total = total + x;
    end
end
