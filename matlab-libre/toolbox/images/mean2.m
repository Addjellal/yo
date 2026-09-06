function m = mean2(a)
%MEAN2 Moyenne de tous les éléments d'une matrice.
%   M = MEAN2(A) est un raccourci pour MEAN(A(:)) : la moyenne de toute la
%   matrice, non celle de chaque colonne.
%
%   C'est la confusion la plus fréquente sur une image : MEAN(image) rend
%   une ligne de moyennes par colonne, ce qui n'est presque jamais ce
%   qu'on veut.
%
%   Exemple :
%      mean2(magic(4))                 % 8.5
%      mean(magic(4))                  % [8.5 8.5 8.5 8.5] : par colonne
%
%   Voir aussi STD2, MEAN, IMHIST.
    a = double(a);
    m = sum(a(:)) / numel(a);
end
