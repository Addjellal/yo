function [b, a] = butter(n, Wn, genre)
%BUTTER Filtre numérique de Butterworth.
%   [B,A] = BUTTER(N,WN) conçoit un passe-bas d'ordre N de fréquence de
%   coupure normalisée WN (0 < WN < 1, 1 = Nyquist).
%   [B,A] = BUTTER(N,WN,'high') conçoit un passe-haut.
%
%   Le prototype analogique est transposé par transformation bilinéaire
%   avec pré-distorsion de la fréquence, comme le fait la fonction de
%   référence.
    if nargin < 3
        genre = 'low';
    end
    genre = lower(char(genre));
    % Pôles du prototype passe-bas analogique normalisé.
    k = 1:n;
    theta = (2 * k - 1) * pi / (2 * n);
    poles = -sin(theta) + 1i * cos(theta);
    % Pré-distorsion.
    omega = tan(pi * Wn / 2);
    if strcmp(genre, 'high')
        poles = omega ./ poles;
    else
        poles = omega * poles;
    end
    % Transformation bilinéaire s -> (1 - z^-1) / (1 + z^-1).
    pz = (1 + poles) ./ (1 - poles);
    if strcmp(genre, 'high')
        zz = ones(1, n);
    else
        zz = -ones(1, n);
    end
    a = real(poly(pz));
    b = real(poly(zz));
    % Normalisation du gain.
    if strcmp(genre, 'high')
        gain = polyval(b, -1) / polyval(a, -1);
    else
        gain = polyval(b, 1) / polyval(a, 1);
    end
    b = b / gain;
end
