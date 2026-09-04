function contributions = matlibre_gradient_agregation(g, donnees)
%MATLIBRE_GRADIENT_AGREGATION Dérivée d'une agrégation.
%   C = MATLIBRE_GRADIENT_AGREGATION(G,DONNEES) rend la dérivée par
%   rapport à l'entrée. Pour le maximum, elle ne revient qu'à l'élément
%   qui a gagné sa fenêtre ; pour la moyenne, elle se partage à parts
%   égales entre tous les éléments de la fenêtre.
%
%   Un même pixel appartenant à plusieurs fenêtres quand elles se
%   recouvrent, les contributions s'y ajoutent.
%
%   Exemple :
%      % appelée par la rétropropagation, jamais directement
%
%   Voir aussi MAXPOOL, AVGPOOL, MATLIBRE_DL_AGREGER.
    contexte = donnees{1};
    if isfield(contexte, 'unidimensionnel') && contexte.unidimensionnel
        g = reshape(g, contexte.tailleSortie);
    end
    valeurs = reshape(g, 1, []);
    total = prod(contexte.tailleEtendue);
    if strcmp(contexte.genre, 'max')
        cibles = contexte.indices(contexte.choix);
        versEtendue = accumarray(cibles(:), valeurs(:), [total 1]);
    else
        part = valeurs / contexte.coefficients;
        repartie = repmat(part, contexte.coefficients, 1);
        versEtendue = accumarray(contexte.indices(:), repartie(:), [total 1]);
    end
    versEtendue = reshape(versEtendue, contexte.tailleEtendue);
    bords = contexte.bords;
    tailleX = contexte.tailleX;
    versX = versEtendue((1:tailleX(1)) + bords(1), (1:tailleX(2)) + bords(3), :);
    versX = reshape(versX, tailleX);
    if isfield(contexte, 'unidimensionnel') && contexte.unidimensionnel
        versX = reshape(versX, tailleX(1), tailleX(3), tailleX(4));
    end
    contributions = {versX};
end
