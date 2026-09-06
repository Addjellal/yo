function y = gbellmf(x, p)
%GBELLMF Cloche généralisée de paramètres [a b c].
%   Y = GBELLMF(X,[A B C]) rend 1/(1+|(X-C)/A|^(2*B)) : une cloche centrée
%   en C, de demi-largeur A à mi-hauteur, dont B règle la raideur des
%   flancs.
%
%   La valeur en C±A vaut exactement un demi quel que soit B, ce qui fait
%   de A une largeur lisible directement. B grand rapproche la courbe d'un
%   créneau — la logique floue redevient booléenne à la limite ; B petit
%   l'étale.
%
%   C'est sa souplesse qui la distingue de la gaussienne : trois
%   paramètres au lieu de deux, dont un qui découple la largeur du plateau
%   de la raideur des bords. Elle décroît en puissance et non en
%   exponentielle, donc ses queues sont plus lourdes et le recouvrement
%   entre ensembles éloignés plus marqué.
%
%   Exemple :
%      gbellmf([25 30 35], [5 2 30])
%
%   Voir aussi GAUSSMF, SIGMF, TRIMF, EVALFIS.
    y = 1 ./ (1 + abs((x - p(3)) / p(1)) .^ (2 * p(2)));
end
