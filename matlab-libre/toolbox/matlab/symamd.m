function p = symamd(A)
%SYMAMD Renumérotation par degré minimal, matrice symétrique.
%   P = SYMAMD(A) rend une permutation qui réduit le remplissage de la
%   factorisation de Cholesky de A(P,P).
%
%   L'algorithme élimine à chaque pas le nœud de plus petit degré dans le
%   graphe d'élimination, puis relie entre eux tous ses voisins — c'est ce
%   que fait la factorisation, et simuler le graphe suffit à prévoir le
%   remplissage sans calculer la moindre valeur.
%
%   MATLAB emploie ici l'approximation d'Amestoy, Davis et Duff, qui
%   majore le degré au lieu de le recalculer ; MatLibre calcule le degré
%   exact. Le résultat est du même ordre et le coût plus élevé, ce qui
%   compte sur une très grande matrice et pas sur une petite.
%
%   Réduire le remplissage n'est pas la même chose que réduire la bande :
%   SYMRCM range les coefficients près de la diagonale, SYMAMD ne s'occupe
%   que de ce que la factorisation va créer. Sur une matrice issue d'un
%   maillage, le degré minimal l'emporte largement.
%
%   Exemple :
%      A = [1 1 1 1; 1 1 0 0; 1 0 1 0; 1 0 0 1];
%      p = symamd(A);
%      isequal(sort(p), 1:4)                    % 1 : c'est une permutation
%      find(p == 1) > 1                         % le noeud le plus lie attend
%
%   Voir aussi SYMRCM, COLAMD, CHOL.
    p = matlibre_degre_minimal(A);
end
