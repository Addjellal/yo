function points = pointCloudFromRanges(distances, angles)
%POINTCLOUDFROMRANGES Nuage cartésien à partir d'un balayage polaire.
    distances = distances(:);
    angles = angles(:);
    points = [distances .* cos(angles), distances .* sin(angles)];
end
