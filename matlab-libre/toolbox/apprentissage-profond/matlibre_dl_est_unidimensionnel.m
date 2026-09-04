function oui = matlibre_dl_est_unidimensionnel(x, poids, format)
%MATLIBRE_DL_EST_UNIDIMENSIONNEL La convolution ne porte-t-elle que sur une
%   dimension ?
%   OUI = MATLIBRE_DL_EST_UNIDIMENSIONNEL(X,POIDS,FORMAT) répond d'après
%   le format quand il y en a un — une seule étiquette spatiale —, sinon
%   d'après le nombre de dimensions des poids : trois pour un filtre
%   unidimensionnel, quatre pour un filtre d'image.
%
%   Exemple :
%      matlibre_dl_est_unidimensionnel(zeros(8, 2, 4), zeros(3, 2, 5), 'SCB')
%
%   Voir aussi DLCONV.
    if ~isempty(format)
        oui = sum(format == 'S') == 1;
        return
    end
    oui = ndims(poids) <= 3 && ndims(x) <= 3 && size(poids, 2) ~= size(x, 2);
    if ~oui
        oui = ndims(poids) == 3 && ndims(x) == 3;
    end
end
