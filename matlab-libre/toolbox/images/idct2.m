function x = idct2(y, m, n)
%IDCT2 Transformée en cosinus discrète inverse bidimensionnelle.
%   X = IDCT2(Y) reconstruit l'image à partir de ses coefficients.
%
%   La DCT est ce qui fait JPEG : elle concentre l'énergie d'un bloc
%   d'image dans quelques coefficients de basse fréquence, et jeter les
%   autres se voit peu. IDCT2 refait le chemin inverse.
%
%   L'aller-retour est exact à la précision machine, tant qu'on ne jette
%   rien.
%
%   Exemple :
%      image = magic(8);
%      max(max(abs(idct2(dct2(image)) - image)))    % ~1e-13
%
%   Voir aussi DCT2, FFT2, IMWRITE.
    if nargin >= 2
        [hauteur, largeur] = size(y);
        if nargin < 3, n = largeur; end
        z = zeros(m, n);
        z(1:min(m, hauteur), 1:min(n, largeur)) = ...
            y(1:min(m, hauteur), 1:min(n, largeur));
        y = z;
    end
    y = double(y);
    intermediaire = zeros(size(y));
    for j = 1:size(y, 2)
        intermediaire(:, j) = idct(y(:, j));
    end
    x = zeros(size(y));
    for i = 1:size(y, 1)
        x(i, :) = idct(intermediaire(i, :).').';
    end
end
