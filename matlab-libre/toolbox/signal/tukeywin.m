function w = tukeywin(n, r)
%TUKEYWIN Fenêtre de Tukey, cosinus surélevé à rapport réglable.
%   W = TUKEYWIN(N,R) : R = 0 donne la fenêtre rectangulaire, R = 1 la
%   fenêtre de Hann. R vaut 0,5 par défaut.
%
%   Exemple :
%      isequal(tukeywin(8, 0), rectwin(8))   % vrai
    if nargin < 2, r = 0.5; end
    n = round(n);
    if n <= 1, w = ones(max(n, 0), 1); return, end
    r = max(0, min(1, r));
    if r == 0, w = ones(n, 1); return, end
    t = (0:n-1)' / (n - 1);
    w = ones(n, 1);
    gauche = t < r / 2;
    droite = t > 1 - r / 2;
    w(gauche) = 0.5 * (1 + cos(2 * pi / r * (t(gauche) - r / 2)));
    w(droite) = 0.5 * (1 + cos(2 * pi / r * (t(droite) - 1 + r / 2)));
end
