function y = matlibre_dl_unaire(operation, a, valeur, donnees, format)
%MATLIBRE_DL_UNAIRE Enregistre une opération à un seul opérande.
%   Y = MATLIBRE_DL_UNAIRE(OPERATION,A,VALEUR,DONNEES) fabrique le
%   DLARRAY qui porte VALEUR et inscrit le nœud qui le relie à A.
%   MATLIBRE_DL_UNAIRE(...,FORMAT) impose le format du résultat, pour les
%   opérations qui changent la disposition des dimensions.
%
%   Exemple :
%      y = matlibre_dl_unaire('exp', dlarray(0), 1, {1});
%
%   Voir aussi DLARRAY, MATLIBRE_BANDE, MATLIBRE_GRADIENT_OPERATION.
    if nargin < 5
        format = matlibre_dl_format(a);
    end
    noeud = matlibre_bande('ajouter', operation, matlibre_dl_noeud(a), donnees);
    y = matlibre_dl_construire(valeur, format, noeud);
end
