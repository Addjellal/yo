function m = mean2(a)
%MEAN2 Moyenne de tous les éléments d'une matrice.
    a = double(a);
    m = sum(a(:)) / numel(a);
end
