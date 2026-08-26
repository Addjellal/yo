function d = drawdownSeries(cours)
%DRAWDOWNSERIES Perte relative depuis le dernier sommet, à chaque date.
    cours = cours(:);
    sommet = cours(1);
    d = zeros(size(cours));
    for k = 1:numel(cours)
        sommet = max(sommet, cours(k));
        d(k) = (sommet - cours(k)) / sommet;
    end
end
