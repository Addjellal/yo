function J = matlibre_niveau_pyramide(I, echelle)
%MATLIBRE_NIVEAU_PYRAMIDE Image réduite d'un facteur donné.
%   J = MATLIBRE_NIVEAU_PYRAMIDE(I,ECHELLE) rend l'image réduite ECHELLE
%   fois. Une échelle de un rend l'image telle quelle, sans passer par un
%   rééchantillonnage qui la modifierait inutilement.
%
%   Exemple :
%      size(matlibre_niveau_pyramide(zeros(40), 2))    % 20 20
%
%   Voir aussi DETECTORBFEATURES, DETECTBRISKFEATURES, IMRESIZE.
    if abs(echelle - 1) < 1e-12
        J = I;
    else
        J = imresize(I, 1 / echelle);
    end
end
