function r = isnat(x)
%ISNAT Vrai pour les éléments manquants d'un tableau datetime.
    if isa(x, 'datetime')
        r = isnan(x.Serie);
    else
        r = false(size(x));
    end
end
