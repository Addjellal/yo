function s = std2(a)
%STD2 Écart-type de tous les éléments d'une matrice.
    a = double(a(:));
    s = std(a);
end
