function sortie = imimposemin(image, marqueurs, connexite)
%IMIMPOSEMIN Force les minima régionaux à se trouver là où on le dit.
%   Sert à contrôler la ligne de partage des eaux : sans cela, chaque
%   petite cuvette du relief donne un bassin.
%
%   La construction est celle de Soille : on creuse à moins l'infini là
%   où sont les marqueurs, on remonte tout le reste d'un cran, et on
%   reconstruit par en dessous. Les seuls minima qui survivent sont ceux
%   qu'on a imposés.
%
%   Exemple :
%      relief = [3 3 3; 3 1 3; 3 3 3];
%      m = false(3); m(1,1) = true;
%      imregionalmin(imimposemin(relief, m))   % le seul minimum est en (1,1)
    if nargin < 3 || isempty(connexite), connexite = 8; end
    image = double(image);
    marqueurs = logical(marqueurs);
    etendue = max(image(:)) - min(image(:));
    if etendue == 0
        pas = 0.1;
    else
        pas = etendue / 1000;
    end
    contrainte = image;
    contrainte(marqueurs) = -Inf;
    contrainte(~marqueurs) = Inf;
    masque = min(image + pas, contrainte);
    % La reconstruction par érosion s'obtient en niant les deux images.
    sortie = -imreconstruct(-contrainte, -masque, connexite);
end
