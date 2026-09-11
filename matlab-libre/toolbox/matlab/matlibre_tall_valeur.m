function v = matlibre_tall_valeur(x)
%MATLIBRE_TALL_VALEUR Valeur d'un argument, différée ou non.
%   V = MATLIBRE_TALL_VALEUR(X) rend X tel quel, ou le résultat du calcul
%   qu'il décrit si X est un tableau différé. Mêler un tableau différé et
%   un tableau ordinaire dans une même opération doit marcher : c'est
%   cette fonction qui le permet, en ramenant les deux au même plan au
%   moment où l'on calcule enfin.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_tall_valeur(3)                  % 3
%      matlibre_tall_valeur(tall([1 2 3]))      % [1 2 3]
%
%   Voir aussi TALL, GATHER, ISTALL.
    if isa(x, 'tall')
        calcul = x.Calcul;
        v = calcul();
    else
        v = x;
    end
end
