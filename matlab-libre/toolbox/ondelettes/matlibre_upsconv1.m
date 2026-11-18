function y = matlibre_upsconv1(x, f, longueur, mode)
%MATLIBRE_UPSCONV1 Suréchantillonnage puis convolution, comme IDWT le fait.
%   Y = MATLIBRE_UPSCONV1(X,F,L,MODE) insère un zéro après chaque
%   coefficient de X, convolue par le filtre de reconstruction F, et
%   garde la partie centrale de longueur L. En mode 'per', le signal
%   suréchantillonné est prolongé par périodicité avant la convolution,
%   et l'on garde L valeurs à partir du rang numel(F).
%   Sans L (vide), L vaut 2*numel(X)-numel(F)+2, ou 2*numel(X) en 'per'.
%   Un X vide donne 0.
    if isempty(x)
        y = 0;
        return
    end
    x = double(x(:)).';
    f = double(f(:)).';
    lx = 2 * numel(x);
    lf = numel(f);
    periodique = strcmp(mode, 'per');
    if nargin < 3 || isempty(longueur)
        if periodique
            longueur = lx;
        else
            longueur = lx - lf + 2;
        end
    end
    if ~periodique
        u = zeros(1, lx - 1);
        u(1:2:end) = x;
        y = conv(u, f);
        y = garderCentre(y, longueur);
    else
        u = zeros(1, lx);
        u(1:2:end) = x;
        u = wextend('1D', 'per', u, lf / 2);
        y = conv(u, f);
        y = y(lf:lf + longueur - 1);
    end
end

% La partie centrale de longueur L : MATLAB (WKEEP1) commence au rang
% 1 + floor(d) et finit à N - ceil(d), d = (N - L)/2.
function y = garderCentre(y, longueur)
    n = numel(y);
    if longueur >= n
        return
    end
    d = (n - longueur) / 2;
    y = y(1 + floor(d):n - ceil(d));
end
