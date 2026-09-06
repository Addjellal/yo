function s = std2(a)
%STD2 Écart-type de tous les éléments d'une matrice.
%   S = STD2(A) est un raccourci pour STD(A(:)).
%
%   Sur une image, il mesure le contraste global : une image uniforme a un
%   écart type nul, une image très contrastée un écart type proche de la
%   moitié de sa dynamique.
%
%   Exemple :
%      std2(ones(8))                   % 0 : aucune variation
%      std2(magic(4)) > 0              % true
%
%   Voir aussi MEAN2, STD, HISTEQ.
    a = double(a(:));
    s = std(a);
end
