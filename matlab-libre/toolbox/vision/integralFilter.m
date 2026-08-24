function J = integralFilter(imageIntegrale, noyau)
%INTEGRALFILTER Filtrage par boîtes sur une image intégrale.
%   J = INTEGRALFILTER(II,NOYAU) applique un filtre composé de rectangles
%   pondérés, chacun évalué en quatre accès à l'image intégrale II rendue
%   par INTEGRALIMAGE. Le coût ne dépend donc pas de la taille des
%   rectangles.
%
%   NOYAU est une structure aux champs
%     BoundingBoxes  une ligne [x y largeur hauteur] par rectangle,
%                    en coordonnées relatives au coin supérieur gauche
%     Weights        le poids de chaque rectangle
%
%   Exemple :
%      noyau = struct('BoundingBoxes', [1 1 3 3], 'Weights', 1);
%      J = integralFilter(integralImage(ones(5)), noyau);
%      J(1)   % 9 : la somme d'un carré de trois sur trois
%
%   Voir aussi INTEGRALIMAGE.
    II = double(imageIntegrale);
    boites = double(noyau.BoundingBoxes);
    poids = double(noyau.Weights(:))';
    hauteurTotale = max(boites(:, 2) + boites(:, 4)) - 1;
    largeurTotale = max(boites(:, 1) + boites(:, 3)) - 1;
    lignes = size(II, 1) - 1 - hauteurTotale + 1;
    colonnes = size(II, 2) - 1 - largeurTotale + 1;
    if lignes < 1 || colonnes < 1
        J = [];
        return
    end
    J = zeros(lignes, colonnes);
    for k = 1:size(boites, 1)
        x = boites(k, 1); y = boites(k, 2);
        largeur = boites(k, 3); hauteur = boites(k, 4);
        haut = y:(y + lignes - 1);
        gauche = x:(x + colonnes - 1);
        somme = II(haut + hauteur, gauche + largeur) - II(haut, gauche + largeur) ...
              - II(haut + hauteur, gauche) + II(haut, gauche);
        J = J + poids(k) * somme;
    end
end
