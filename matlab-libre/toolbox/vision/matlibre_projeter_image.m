function J = matlibre_projeter_image(I, T, cadre, remplissage)
%MATLIBRE_PROJETER_IMAGE Applique une transformation projective à une image.
%   J = MATLIBRE_PROJETER_IMAGE(I,T,CADRE,REMPLISSAGE) rend l'image
%   transformée par T, échantillonnée sur le rectangle CADRE donné en
%   [xmin ymin largeur hauteur] dans les coordonnées de sortie. T suit la
%   convention de MATLAB : un point s'écrit en ligne, [x y 1] * T.
%
%   Le calcul va de la sortie vers l'entrée — chaque pixel de sortie
%   cherche d'où il vient —, ce qui évite les trous que laisserait le
%   parcours inverse. L'interpolation est bilinéaire ; ce qui tombe hors
%   de l'image d'entrée reçoit REMPLISSAGE.
%
%   Exemple :
%      J = matlibre_projeter_image(magic(4), eye(3), [1 1 4 4], 0);
%      isequal(J, magic(4))     % vrai
%
%   Voir aussi RECTIFYSTEREOIMAGES, ESTIMATEUNCALIBRATEDRECTIFICATION.
    if nargin < 4
        remplissage = 0;
    end
    I = double(I);
    largeur = round(cadre(3));
    hauteur = round(cadre(4));
    [X, Y] = meshgrid(cadre(1) + (0:(largeur - 1)), cadre(2) + (0:(hauteur - 1)));
    inverse = inv(double(T));
    sources = matlibre_appliquer_homographie(inverse.', [X(:), Y(:)]);
    Xs = reshape(sources(:, 1), hauteur, largeur);
    Ys = reshape(sources(:, 2), hauteur, largeur);
    plans = size(I, 3);
    J = zeros(hauteur, largeur, plans);
    [Xi, Yi] = meshgrid(1:size(I, 2), 1:size(I, 1));
    for p = 1:plans
        valeurs = interp2(Xi, Yi, I(:, :, p), Xs, Ys, 'linear');
        valeurs(isnan(valeurs)) = remplissage;
        J(:, :, p) = valeurs;
    end
end
