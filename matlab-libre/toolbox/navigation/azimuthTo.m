function cap = azimuthTo(lat1, lon1, lat2, lon2)
%AZIMUTHTO Cap initial, en degrés depuis le nord.
    p1 = lat1 * pi / 180;
    p2 = lat2 * pi / 180;
    dl = (lon2 - lon1) * pi / 180;
    y = sin(dl) .* cos(p2);
    x = cos(p1) .* sin(p2) - sin(p1) .* cos(p2) .* cos(dl);
    cap = mod(atan2(y, x) * 180 / pi + 360, 360);
end
