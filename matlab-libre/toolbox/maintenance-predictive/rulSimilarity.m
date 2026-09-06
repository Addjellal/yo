function rul = rulSimilarity(trajectoire, historiques, dureesVie)
%RULSIMILARITY Durée de vie restante par similarité de trajectoires.
%   Les trajectoires historiques les plus proches, au sens de l'écart
%   quadratique sur la partie commune, votent au prorata de l'inverse de
%   leur distance.
%
%   RUL = RULSIMILARITY(TRAJECTOIRE,HISTORIQUES,DUREESVIE) compare la
%   trajectoire en cours à celles de machines dont on connaît la fin.
%   HISTORIQUES est une cellule de vecteurs, DUREESVIE leurs durées.
%
%   Chaque historique vote pour ce qu'il lui restait au même stade, au
%   prorata de sa ressemblance. La méthode n'exige aucune forme de
%   dégradation particulière — seulement des exemples, ce qui la rend
%   supérieure à l'extrapolation linéaire dès que la dégradation
%   s'accélère.
%
%   Deux propriétés la valident : plus on observe, moins il reste ; et une
%   trajectoire identique à un historique connu hérite de sa durée de vie.
%
%   Sa faiblesse est celle de tout apprentissage par l'exemple : elle ne
%   sait rien d'un mode de défaillance qu'aucun historique ne contient.
%
%   Exemple :
%      rul = rulSimilarity(enCours, historiques, [100 120 90 110]);
%
%   Voir aussi RULDEGRADATION, HEALTHINDICATOR, FAULTFEATURES.
    n = numel(trajectoire);
    poids = zeros(numel(historiques), 1);
    restes = zeros(numel(historiques), 1);
    for k = 1:numel(historiques)
        h = historiques{k};
        m = min(n, numel(h));
        d = sqrt(mean((trajectoire(1:m) - h(1:m)) .^ 2));
        poids(k) = 1 / max(d, 1e-6);
        restes(k) = dureesVie(k) - m;
    end
    rul = sum(poids .* restes) / sum(poids);
end
