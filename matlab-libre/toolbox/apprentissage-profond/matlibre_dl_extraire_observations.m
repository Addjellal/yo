function lot = matlibre_dl_extraire_observations(donnees, indices)
%MATLIBRE_DL_EXTRAIRE_OBSERVATIONS Sous-ensemble d'observations.
%   L = MATLIBRE_DL_EXTRAIRE_OBSERVATIONS(D,INDICES) prend les
%   observations demandées, quelle que soit la dimension des données : la
%   dernière dimension est celle des observations.
%
%   Exemple :
%      size(matlibre_dl_extraire_observations(zeros(4, 4, 1, 10), 1:3))
%
%   Voir aussi MINIBATCHQUEUE.
    valeurs = matlibre_dl_valeur(donnees);
    decoupe = repmat({':'}, 1, ndims(valeurs));
    decoupe{end} = indices;
    lot = valeurs(decoupe{:});
end
