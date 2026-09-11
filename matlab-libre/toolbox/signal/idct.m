function x = idct(y, n)
%IDCT Transformée en cosinus discrète inverse.
%   X = IDCT(Y) rend la transformée en cosinus discrète inverse de Y :
%   IDCT(DCT(X)) restitue X. La transformée est orthonormée, donc
%   l'inverse est la transposée, et l'énergie se conserve.
%
%   X = IDCT(Y,N) tronque ou complète Y par des zéros à N points avant de
%   transformer. Annuler les derniers coefficients est exactement ce que
%   fait une compression : les coefficients de rang élevé portent les
%   variations rapides, et les supprimer lisse le signal sans le déplacer.
%
%   C'est cette concentration de l'énergie dans les premiers coefficients,
%   pour un signal corrélé, qui explique l'emploi de la DCT en JPEG et en
%   MP3 plutôt que celui de la transformée de Fourier.
%
%   L'orientation est conservée, comme le fait IFFT : une ligne rend une
%   ligne, une colonne rend une colonne.
%
%   Exemple :
%      x = [1 2 3 4 5]';
%      max(abs(idct(dct(x)) - x)) < 1e-12
%      isrow(idct([1 2 3 4]))          % 1 : une ligne reste une ligne
%
%   Voir aussi DCT, FFT, IFFT.
    enLigne = isrow(y);
    y = y(:);
    if nargin > 1 && ~isempty(n)
        if numel(y) > n
            y = y(1:n);
        else
            y = [y; zeros(n - numel(y), 1)];
        end
    end
    N = numel(y);
    x = zeros(N, 1);
    for m = 1:N
        s = y(1) / sqrt(N);
        for k = 2:N
            s = s + sqrt(2/N) * y(k) * cos(pi * (2*m - 1) * (k - 1) / (2 * N));
        end
        x(m) = s;
    end
    if enLigne
        x = x.';
    end
end
