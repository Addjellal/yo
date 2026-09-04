function [milieu, haute, basse] = bollinger(actif, fenetre, largeur, alpha)
%BOLLINGER Bandes de Bollinger, dans l'ordre d'arguments moderne.
%   [M,H,B] = BOLLINGER(COURS,FENETRE,LARGEUR,ALPHA) fait ce que fait
%   BOLLING, les deux derniers arguments étant échangés.
%
%   Exemple :
%      [m, h, b] = bollinger(clotures, 20, 2);
%
%   Voir aussi BOLLING, MOVAVG.
    if nargin < 2, fenetre = []; end
    if nargin < 3, largeur = []; end
    if nargin < 4, alpha = [];   end
    [milieu, haute, basse] = bolling(actif, fenetre, alpha, largeur);
end
