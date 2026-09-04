function y = matlibre_dl_aplatir(x, observations, taille)
%MATLIBRE_DL_APLATIR Met les observations en colonnes.
%   Y = MATLIBRE_DL_APLATIR(X,OBSERVATIONS,TAILLE) rend une matrice dont
%   chaque colonne est une observation, toutes ses autres dimensions
%   mises bout à bout. C'est le passage d'un tenseur d'images à la matrice
%   qu'attend une couche dense.
%
%   Exemple :
%      size(matlibre_dl_aplatir(zeros(4, 4, 3, 8), 4, [4 4 3 8]))   % 48 8
%
%   Voir aussi FULLYCONNECT, FLATTENLAYER.
    ordre = [setdiff(1:numel(taille), observations), observations];
    y = permute(x, ordre);
    y = reshape(y, prod(taille) / taille(observations), taille(observations));
end
