function J = imoverlay(I, masque, couleur)
%IMOVERLAY Pose un masque coloré sur une image.
%   J = IMOVERLAY(I,BW) rend une image en couleurs où les points de BW
%   sont peints en jaune, le reste gardant l'image d'origine. C'est la
%   façon de montrer ce qu'une segmentation a trouvé.
%
%   J = IMOVERLAY(I,BW,COULEUR) choisit la couleur : un triplet RVB entre
%   0 et 1, ou un nom — 'red', 'green', 'blue', 'yellow', 'cyan',
%   'magenta', 'white', 'black'.
%
%   Exemple :
%      I = mat2gray(peaks(60));
%      J = imoverlay(I, I > 0.7, 'red');
%
%   Voir aussi LABEL2RGB, IMSHOW, IMFUSE, BWPERIM.
    if nargin < 3 || isempty(couleur)
        couleur = [1 1 0];
    end
    if ischar(couleur) || isstring(couleur)
        couleur = couleurNommee(char(couleur));
    end
    couleur = double(couleur(:)).';
    I = im2double(I);
    if size(I, 3) == 1
        I = repmat(I, [1 1 3]);
    end
    masque = logical(masque);
    J = I;
    for canal = 1:3
        plan = J(:, :, canal);
        plan(masque) = couleur(canal);
        J(:, :, canal) = plan;
    end
end

function c = couleurNommee(nom)
    switch lower(nom)
        case 'red',     c = [1 0 0];
        case 'green',   c = [0 1 0];
        case 'blue',    c = [0 0 1];
        case 'yellow',  c = [1 1 0];
        case 'cyan',    c = [0 1 1];
        case 'magenta', c = [1 0 1];
        case 'white',   c = [1 1 1];
        case 'black',   c = [0 0 0];
        otherwise
            error('images:imoverlay:Couleur', 'Couleur inconnue : %s.', nom);
    end
end
