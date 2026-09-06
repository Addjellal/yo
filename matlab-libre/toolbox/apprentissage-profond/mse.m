function e = mse(predit, cible)
%MSE Erreur quadratique moyenne.
%   E = MSE(PREDIT,CIBLE) rend la moyenne des carrés des écarts, sur tous
%   les éléments. C'est le coût habituel d'une régression : sa dérivée est
%   proportionnelle à l'écart, donc simple, et son minimum est la moyenne
%   conditionnelle — un réseau entraîné à cette perte prédit l'espérance
%   de la cible, non sa médiane.
%
%   Le carré est aussi ce qui la rend sensible aux valeurs aberrantes :
%   un écart dix fois plus grand pèse cent fois plus. HUBER et L1LOSS
%   servent quand les données en contiennent.
%
%   Exemple :
%      mse([1 2 3], [1 2 4])
%
%   Voir aussi HUBER, L1LOSS, L2LOSS, CROSSENTROPY.
    d = predit - cible;
    e = sum(sum(d .^ 2)) / numel(d);
end
