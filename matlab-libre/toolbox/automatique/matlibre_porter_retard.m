function cible = matlibre_porter_retard(cible, source)
%MATLIBRE_PORTER_RETARD Reporte sur un modèle les retards d'un autre.
%   CIBLE = MATLIBRE_PORTER_RETARD(CIBLE,SOURCE) copie les retards et
%   l'unité de temps de SOURCE sur CIBLE. Les transformations qui ne
%   touchent qu'à la partie rationnelle — discrétisation, réduction,
%   changement de réalisation — doivent les reporter : un retard perdu
%   en chemin ne se voit nulle part.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      g = tf(1, [1 1]); g.InputDelay = 2;
%      totaldelay(matlibre_porter_retard(tf(1, [1 2]), g))    % 2
%
%   Voir aussi TOTALDELAY, HASDELAY, MATLIBRE_SANS_RETARD.
    for nom = {'InputDelay', 'OutputDelay', 'IODelay', 'TimeUnit'}
        champ = nom{1};
        if (isprop(source, champ) || isfield(source, champ)) && ...
                (isprop(cible, champ) || isfield(cible, champ))
            cible.(champ) = source.(champ);
        end
    end
end
