function n = getNominal(objet)
%GETNOMINAL Valeur nominale d'un objet incertain.
%   N = GETNOMINAL(U) rend ce que U vaut quand chaque paramètre prend sa
%   valeur nominale : une matrice pour un UMAT, un modèle SS pour un USS,
%   un nombre pour un UREAL.
%
%   C'est la même chose que la propriété NominalValue ; GETNOMINAL existe
%   pour qu'on puisse l'écrire en fonction, ce qui se compose mieux.
%
%   Exemples :
%      k = ureal('k', 10, 'Range', [8 12]);
%      getNominal(k)                       % 10
%      getNominal([1 k; 0 2])              % [1 10; 0 2]
%
%      G = uss([0 1; -k -2], [0; 1], [1 0], 0);
%      pole(getNominal(G))'
%
%   Voir aussi UREAL, UMAT, USS, USUBS, USAMPLE, UNCERTAIN.
    [parametres, evaluer] = matlibre_incertitudes(objet);
    n = evaluer(umat.valeursNominales(parametres));
end
