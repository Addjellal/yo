function d = haversine(lat1, lon1, lat2, lon2, rayon)
%HAVERSINE Distance orthodromique entre deux points, en mètres.
    if nargin < 5
        rayon = 6371000;
    end
    p1 = lat1 * pi / 180;
    p2 = lat2 * pi / 180;
    dp = (lat2 - lat1) * pi / 180;
    dl = (lon2 - lon1) * pi / 180;
    a = sin(dp/2) .^ 2 + cos(p1) .* cos(p2) .* sin(dl/2) .^ 2;
    d = 2 * rayon * atan2(sqrt(a), sqrt(1 - a));
end
