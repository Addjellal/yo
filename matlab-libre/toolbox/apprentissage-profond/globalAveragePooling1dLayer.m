function c = globalAveragePooling1dLayer(varargin)
%GLOBALAVERAGEPOOLING1DLAYER Moyenne sur toute la dimension de temps.
%   C = GLOBALAVERAGEPOOLING1DLAYER() remplace chaque canal par la moyenne
%   de ses valeurs sur toute la séquence. La sortie a donc une taille
%   fixe, quelle que soit la longueur de l'entrée : c'est ce qui permet de
%   brancher une couche dense derrière des séquences de longueurs
%   inégales.
%
%   Exemple :
%      c = globalAveragePooling1dLayer();
%
%   Voir aussi GLOBALAVERAGEPOOLING2DLAYER, AVERAGEPOOLING1DLAYER.
    c = struct('type', 'globalavgpool1d', 'nom', matlibre_couche_nom(varargin));
end
