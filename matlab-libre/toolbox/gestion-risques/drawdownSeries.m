function d = drawdownSeries(cours)
%DRAWDOWNSERIES Perte relative depuis le dernier sommet, à chaque date.
%   D = DRAWDOWNSERIES(COURS) rend, à chaque date, la perte relative
%   depuis le plus haut atteint jusque-là : (sommet - cours)/sommet.
%
%   La série vaut zéro à chaque nouveau sommet et croît entre deux
%   sommets. Elle se lit comme le regret de celui qui n'a pas vendu au
%   plus haut, et son maximum est ce que rend MAXDRAWDOWN.
%
%   Le sommet est celui du passé seul, jamais de l'avenir : c'est ce qui
%   rend la série calculable en temps réel et honnête. Une mesure qui
%   regarderait le maximum de toute la période donnerait un chiffre
%   qu'aucun investisseur n'aurait pu connaître au moment où il décidait.
%
%   Deux stratégies de même perte maximale ne se valent pas si l'une la
%   subit un mois et l'autre trois ans : c'est la durée passée sous l'eau,
%   lisible sur cette série et non sur le seul maximum, qui décide de ce
%   qui est tenable.
%
%   Exemple :
%      d = drawdownSeries([100 120 90 95 130]);
%
%   Voir aussi MAXDRAWDOWN, EXPECTEDSHORTFALL, SHARPE.
    cours = cours(:);
    sommet = cours(1);
    d = zeros(size(cours));
    for k = 1:numel(cours)
        sommet = max(sommet, cours(k));
        d(k) = (sommet - cours(k)) / sommet;
    end
end
