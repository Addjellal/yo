function image = iradonTransform(sinogramme, angles, taille)
%IRADONTRANSFORM Rétroprojection filtrée.
    if nargin < 2
        angles = 0:size(sinogramme, 2) - 1;
    end
    if nargin < 3
        taille = round(size(sinogramme, 1) / sqrt(2));
    end
    n = size(sinogramme, 1);
    % Filtre rampe.
    f = abs(linspace(-1, 1, n)).';
    filtre = zeros(size(sinogramme));
    for a = 1:size(sinogramme, 2)
        spectre = fftshift(fft(sinogramme(:, a)));
        filtre(:, a) = real(ifft(ifftshift(spectre .* f)));
    end
    image = zeros(taille, taille);
    centre = (taille + 1) / 2;
    centreS = (n + 1) / 2;
    for a = 1:numel(angles)
        t = angles(a) * pi / 180;
        for i = 1:taille
            for j = 1:taille
                x = j - centre;
                y = centre - i;
                s = round(x * cos(t) + y * sin(t) + centreS);
                if s >= 1 && s <= n
                    image(i, j) = image(i, j) + filtre(s, a);
                end
            end
        end
    end
    image = image * pi / numel(angles);
end
