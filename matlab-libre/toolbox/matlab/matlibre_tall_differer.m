function r = matlibre_tall_differer(fonction, arguments)
%MATLIBRE_TALL_DIFFERER Décrit un calcul sans l'exécuter.
%   R = MATLIBRE_TALL_DIFFERER(F,ARGUMENTS) rend un tableau différé qui,
%   au GATHER, vaudra F appliquée aux arguments. Rien n'est calculé ici :
%   c'est ce qui permet d'enchaîner des opérations puis de ne payer
%   qu'une fois.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      r = matlibre_tall_differer(@plus, {tall(1), 2});
%      gather(r)                       % 3
%
%   Voir aussi TALL, GATHER, MATLIBRE_TALL_APPLIQUER.
    r = tall(@() matlibre_tall_appliquer(fonction, arguments), 'differe');
end
