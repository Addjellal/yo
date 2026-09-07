function b = pageinv(a)
%PAGEINV Inverse chaque page d'un tableau.
%   B = PAGEINV(A) inverse séparément chacune des pages A(:,:,k,...), qui
%   doivent être carrées. La forme du tableau est conservée.
%
%   Une page est une tranche à deux dimensions d'un tableau qui en a
%   davantage. Les fonctions PAGE... traitent chacune comme une matrice
%   indépendante : c'est la façon d'appliquer une opération matricielle à
%   une pile de matrices sans écrire de boucle, et sans mélanger les pages
%   entre elles comme le ferait une multiplication ordinaire.
%
%   Comme INV, elle avertit et rend des infinis sur une page singulière.
%   Inverser pour résoudre reste une mauvaise idée : PAGEMLDIVIDE est plus
%   précis et plus rapide.
%
%   Exemple :
%      A = cat(3, [2 0; 0 4], [1 1; 0 1]);
%      B = pageinv(A);
%      B(:, :, 1)                          % [0.5 0; 0 0.25]
%      max(max(abs(pagemtimes(A, B) - cat(3, eye(2), eye(2))))) < 1e-12
%
%   Voir aussi PAGEMLDIVIDE, PAGEMTIMES, PAGETRANSPOSE, INV.
    a = double(a);
    formes = size(a);
    if numel(formes) < 3
        b = inv(a);
        return
    end
    if formes(1) ~= formes(2)
        error('MATLAB:pageinv:NotSquare', 'Chaque page doit être carrée.');
    end
    pages = prod(formes(3:end));
    b = zeros(formes);
    for k = 1:pages
        b(:, :, k) = inv(a(:, :, k));
    end
end
