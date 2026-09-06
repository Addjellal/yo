function image = iradonTransform(sinogramme, angles, taille)
%IRADONTRANSFORM Rétroprojection filtrée.
%   IMAGE = IRADONTRANSFORM(S,ANGLES,TAILLE) reconstruit une image à
%   partir de son sinogramme. ANGLES est la liste des angles de
%   projection, en degrés ; TAILLE le côté de l'image rendue.
%
%   Rétroprojeter sans filtrer étale chaque projection sur toute l'image
%   et donne un résultat flou : chaque point y contribue à tout ce qui est
%   sur sa droite. Le filtre rampe — multiplier le spectre de chaque
%   projection par la fréquence — corrige exactement ce flou, parce que
%   l'étalement pèse les basses fréquences comme l'inverse de la
%   fréquence. C'est ce qui fait que la reconstruction marche.
%
%   Le filtre rampe amplifie donc les hautes fréquences, et avec elles le
%   bruit : c'est le compromis de toute tomographie, et la raison pour
%   laquelle les scanners réels adoucissent la rampe.
%
%   Exemple :
%      image = zeros(64); image(24:40, 24:40) = 1;
%      s = radonTransform(image, 0:179);
%      reconstruite = iradonTransform(s, 0:179, 64);
%
%   Voir aussi RADONTRANSFORM, WINDOWLEVEL.
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
