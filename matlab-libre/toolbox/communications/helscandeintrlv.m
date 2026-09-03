function y = helscandeintrlv(donnees, lignes, colonnes, pas)
%HELSCANDEINTRLV Désentrelacement par balayage hélicoïdal.
%   Y = HELSCANDEINTRLV(X,NLIGNES,NCOLONNES,PAS) défait exactement ce que
%   HELSCANINTRLV a fait, la permutation étant inversée.
%
%   Exemple :
%      y = helscanintrlv(1:12, 3, 4, 1);
%      isequal(helscandeintrlv(y, 3, 4, 1), 1:12)   % vrai
%
%   Voir aussi HELSCANINTRLV, MATDEINTRLV, MUXDEINTRLV, DEINTRLV.
    permutation = matlibre_helice(lignes, colonnes, pas);
    y = deintrlv(donnees, permutation);
end
