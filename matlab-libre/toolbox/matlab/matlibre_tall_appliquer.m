function v = matlibre_tall_appliquer(fonction, arguments)
%MATLIBRE_TALL_APPLIQUER Applique une fonction après avoir tout matérialisé.
%   V = MATLIBRE_TALL_APPLIQUER(F,ARGUMENTS) rend F appliquée aux
%   arguments, chacun ramené à sa valeur. C'est le corps de tout calcul
%   différé : il n'est exécuté qu'au GATHER.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_tall_appliquer(@plus, {tall(1), 2})   % 3
%
%   Voir aussi TALL, GATHER, MATLIBRE_TALL_VALEUR.
    valeurs = cell(1, numel(arguments));
    for k = 1:numel(arguments)
        valeurs{k} = matlibre_tall_valeur(arguments{k});
    end
    v = fonction(valeurs{:});
end
