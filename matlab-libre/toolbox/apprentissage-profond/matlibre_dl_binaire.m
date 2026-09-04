function y = matlibre_dl_binaire(operation, a, b, valeur, donnees)
%MATLIBRE_DL_BINAIRE Enregistre une opération à deux opérandes.
%   Y = MATLIBRE_DL_BINAIRE(OPERATION,A,B,VALEUR,DONNEES) fabrique le
%   DLARRAY qui porte VALEUR et inscrit sur la bande le nœud qui le relie
%   à A et à B, avec ce dont la dérivation aura besoin.
%
%   Exemple :
%      y = matlibre_dl_binaire('plus', dlarray(1), 2, 3, {[1 1], [1 1]});
%
%   Voir aussi DLARRAY, MATLIBRE_BANDE, MATLIBRE_GRADIENT_OPERATION.
    noeud = matlibre_bande('ajouter', operation, ...
                           [matlibre_dl_noeud(a), matlibre_dl_noeud(b)], donnees);
    y = matlibre_dl_construire(valeur, matlibre_dl_format(a, b), noeud);
end
