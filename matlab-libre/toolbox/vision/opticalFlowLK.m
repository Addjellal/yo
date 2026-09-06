function [u, v] = opticalFlowLK(I1, I2, fenetre)
%OPTICALFLOWLK Flot optique par la méthode de Lucas-Kanade.
%   [U,V] = OPTICALFLOWLK(I1,I2,FENETRE) rend les deux composantes du
%   déplacement estimé en chaque pixel, de la première image vers la
%   seconde. FENETRE est le côté du voisinage employé, cinq par défaut.
%
%   L'hypothèse est que la luminance se conserve : un point garde sa
%   valeur en se déplaçant, d'où l'équation Ix u + Iy v + It = 0. Elle ne
%   suffit pas à déterminer les deux inconnues en un seul pixel — c'est le
%   problème de l'ouverture, qui ne laisse voir que la composante
%   perpendiculaire à un contour. Lucas et Kanade la lèvent en supposant
%   le déplacement constant sur le voisinage, ce qui donne autant
%   d'équations que de pixels de la fenêtre.
%
%   Le déplacement n'est estimé que là où la matrice normale est
%   inversible : dans une zone uniforme ou le long d'un contour droit,
%   elle est singulière et le flot rendu vaut zéro. Ce n'est pas un échec
%   du calcul mais l'absence d'information.
%
%   La méthode est locale et linéarisée : elle ne retrouve que les petits
%   déplacements, de l'ordre du pixel. Au-delà, il faut une pyramide.
%
%   Le signe suit la convention d'OPTICALFLOWFARNEBACK : un objet qui se
%   déplace vers la droite donne un U positif.
%
%   Exemple :
%      A = zeros(40); A(15:25, 15:25) = 1;
%      [u, v] = opticalFlowLK(A, circshift(A, [0 1]), 9);
%      median(median(u(12:28, 12:28)))      % environ 1 : vers la droite
%
%   Voir aussi OPTICALFLOWFARNEBACK, IMFILTER.
    if nargin < 3
        fenetre = 5;
    end
    I1 = double(I1);
    I2 = double(I2);
    % Sobel croissant vers la droite : le noyau doit estimer la dérivée,
    % non son opposé, sans quoi le flot rendu serait de signe contraire.
    hx = [-1 0 1; -2 0 2; -1 0 1] / 8;
    Ix = imfilter(I1, hx);
    Iy = imfilter(I1, hx.');
    It = I2 - I1;
    [h, l] = size(I1);
    r = floor(fenetre / 2);
    u = zeros(h, l);
    v = zeros(h, l);
    for i = 1+r:h-r
        for j = 1+r:l-r
            a = Ix(i-r:i+r, j-r:j+r);
            b = Iy(i-r:i+r, j-r:j+r);
            c = It(i-r:i+r, j-r:j+r);
            A = [a(:), b(:)];
            d = -c(:);
            M = A.' * A;
            if abs(det(M)) > 1e-8
                sol = M \ (A.' * d);
                u(i, j) = sol(1);
                v(i, j) = sol(2);
            end
        end
    end
end
