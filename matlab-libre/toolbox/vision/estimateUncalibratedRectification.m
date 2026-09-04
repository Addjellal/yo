function [T1, T2] = estimateUncalibratedRectification(F, points1, points2, tailleImage)
%ESTIMATEUNCALIBRATEDRECTIFICATION Rectifie une paire d'images sans calibrage.
%   [T1,T2] = ESTIMATEUNCALIBRATEDRECTIFICATION(F,P1,P2,TAILLE) rend deux
%   transformations projectives qui, appliquées aux deux images, rendent
%   les droites épipolaires horizontales : deux points correspondants se
%   retrouvent alors sur la même ligne, et la recherche de disparité se
%   ramène à une dimension.
%
%   F est la matrice fondamentale telle que la rend
%   ESTIMATEFUNDAMENTALMATRIX, P1 et P2 les points appariés, TAILLE la
%   taille [lignes colonnes] des images. Les matrices rendues sont dans la
%   convention de MATLAB : un point s'écrit en ligne, [x y 1] * T.
%
%   La construction est celle de Hartley. Pour la seconde image, on envoie
%   son épipôle à l'infini : une translation amène le centre de l'image à
%   l'origine, une rotation pose l'épipôle sur l'axe des x, et une
%   dernière matrice l'y repousse à l'infini. Pour la première image, on
%   compose d'abord la transformation qui la met en correspondance avec la
%   seconde, puis on cherche l'affinité horizontale qui rapproche au mieux
%   les points appariés — ce qui minimise la disparité résiduelle sans
%   toucher aux lignes, donc sans défaire la rectification.
%
%   Une même translation est appliquée aux deux images pour ramener leurs
%   coins dans le quadrant positif ; elle est commune aux deux, donc elle
%   ne rompt pas l'alignement des lignes.
%
%   Exemple :
%      F = estimateFundamentalMatrix(p1, p2);
%      [T1, T2] = estimateUncalibratedRectification(F, p1, p2, size(I1));
%      [J1, J2] = rectifyStereoImages(I1, I2, T1, T2);
%
%   Voir aussi ESTIMATEFUNDAMENTALMATRIX, RECTIFYSTEREOIMAGES, EPIPOLARLINE.
    F = double(F);
    points1 = double(points1);
    points2 = double(points2);
    tailleImage = double(tailleImage);
    centre = [tailleImage(2) / 2; tailleImage(1) / 2];
    % Les épipôles : F e1 = 0 dans la première image, e2' F = 0 dans la
    % seconde. Ce sont les vecteurs singuliers de valeur singulière nulle.
    [U, ~, V] = svd(F);
    e2 = U(:, 3);
    H2 = matlibre_envoyer_epipole(e2, centre);
    % M met les deux images en correspondance à travers un plan ; toute
    % valeur de v donne un plan, et [1 1 1] en donne un qui convient.
    M = matlibre_produit_vectoriel_matrice(e2) * F + e2 * [1 1 1];
    H0 = H2 * M;
    x1 = matlibre_appliquer_homographie(H0, points1);
    x2 = matlibre_appliquer_homographie(H2, points2);
    % Affinité horizontale : elle ne touche pas à l'ordonnée, donc elle
    % conserve l'alignement obtenu.
    A = [x1(:, 1), x1(:, 2), ones(size(x1, 1), 1)];
    coefficients = A \ x2(:, 1);
    HA = [coefficients(1) coefficients(2) coefficients(3); 0 1 0; 0 0 1];
    H1 = HA * H0;
    decalage = matlibre_cadrage_commun(H1, H2, tailleImage);
    H1 = decalage * H1;
    H2 = decalage * H2;
    T1 = H1.';
    T2 = H2.';
end
