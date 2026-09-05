function retard = matlibre_id_retard_apparent(y, u)
%MATLIBRE_ID_RETARD_APPARENT Retard lu dans la corrélation croisée.
%   R = MATLIBRE_ID_RETARD_APPARENT(Y,U) rend le décalage positif où la
%   corrélation entre l'entrée et la sortie est la plus forte : c'est le
%   temps que met l'entrée à se faire sentir.
%
%   Exemple :
%      matlibre_id_retard_apparent(filter([0 0 1], 1, u), u)      % 2
%
%   Voir aussi ADVICE, NKSHIFT.
    decalage = min(30, max(floor(numel(y) / 4), 1));
    r = matlibre_id_correlation(y, u, decalage);
    positifs = r((decalage + 1):end);
    [~, position] = max(abs(positifs));
    retard = position - 1;
end
