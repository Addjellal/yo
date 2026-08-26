function y = wrev(x)
%WREV Renverse l'ordre des éléments d'un vecteur.
    x = double(x);
    if isrow(x)
        y = fliplr(x);
    else
        y = flipud(x);
    end
end
