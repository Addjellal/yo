function [y, etat] = muxdeintrlv(donnees, retards, etatInitial)
%MUXDEINTRLV Désentrelacement multiplexé.
%   Y = MUXDEINTRLV(X,RETARDS) défait ce que MUXINTRLV a fait : les
%   retards y sont pris à l'envers, si bien que chaque symbole subit au
%   total le même retard et retrouve sa place.
%
%   [Y,ETAT] = MUXDEINTRLV(...) rend l'état final des registres,
%   MUXDEINTRLV(X,RETARDS,ETAT) repart d'un état donné.
%
%   Chaque symbole subit au total MAX(RETARDS) pas de registre, et un pas
%   vaut N positions puisque les voies se relaient : le retard est donc
%   de N fois MAX(RETARDS) symboles. Les premiers symboles rendus sont
%   ceux que les registres portaient au départ, des zéros. C'est le prix
%   de l'entrelacement convolutif.
%
%   Exemple :
%      y = muxintrlv(1:20, [0 2 4]);
%      x = muxdeintrlv(y, [0 2 4]);
%      isequal(x(13:20), 1:8)         % vrai : après douze symboles
%
%   Voir aussi MUXINTRLV, HELSCANDEINTRLV, MATDEINTRLV.
    retards = round(double(retards(:))).';
    n = numel(retards);
    % Le désentrelaceur prend les retards complémentaires : la voie qui
    % avait le plus court en a le plus long.
    complementaires = max(retards) - retards;
    if nargin < 3
        etatInitial = [];
    end
    [y, etat] = muxintrlv(donnees, complementaires, etatInitial);
end
