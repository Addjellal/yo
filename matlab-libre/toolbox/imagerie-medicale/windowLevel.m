function sortie = windowLevel(image, centre, largeur)
%WINDOWLEVEL Fenêtrage densitométrique, comme sur une console de scanner.
%   S = WINDOWLEVEL(IMAGE,CENTRE,LARGEUR) ramène entre zéro et un la bande
%   d'unités Hounsfield qui va de CENTRE-LARGEUR/2 à CENTRE+LARGEUR/2 ;
%   ce qui est en dessous devient noir, ce qui est au-dessus blanc.
%
%   Un scanner mesure de -1000 (l'air) à plus de 1000 (l'os compact) : un
%   écran n'en montre qu'environ 256 niveaux. Le fenêtrage choisit donc la
%   tranche qu'on veut voir, et sacrifie le reste. C'est un choix, non une
%   dégradation : regarder le poumon et regarder l'os demandent deux
%   fenêtres différentes de la même acquisition.
%
%   Les fenêtres usuelles, en unités Hounsfield :
%      poumon      centre -600,  largeur 1500
%      tissu mou   centre   40,  largeur  400
%      os          centre  300,  largeur 1500
%      cerveau     centre   40,  largeur   80
%
%   Exemple :
%      image = [-1000 -500 0 40 200 1000];
%      windowLevel(image, 40, 400)     % fenetre tissu mou
%      windowLevel(image, -600, 1500)  % fenetre poumon
%
%   Voir aussi IMADJUST, RADONTRANSFORM, MAT2GRAY.
    bas = centre - largeur / 2;
    haut = centre + largeur / 2;
    sortie = (double(image) - bas) / max(haut - bas, eps);
    sortie = max(0, min(1, sortie));
end
