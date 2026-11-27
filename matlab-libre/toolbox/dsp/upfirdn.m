function y = upfirdn(x, h, p, q)
%UPFIRDN Sur-échantillonne, filtre, puis décime.
%   Y = UPFIRDN(X,H,P,Q) insère P-1 zéros entre les échantillons de X,
%   filtre par le RIF H, puis garde un échantillon sur Q, en une seule
%   opération polyphase dans MATLAB. P et Q valent un par défaut.
%   La sortie a ceil(((numel(X) - 1) * P + numel(H)) / Q) échantillons,
%   comme dans MATLAB : les zéros insérés après le dernier échantillon
%   ne sont pas filtrés. Une matrice X est traitée colonne par colonne ;
%   un vecteur garde son orientation.
%
%   C'est l'opération de base du changement de cadence : RESAMPLE
%   l'emploie avec un filtre passe-bas conçu pour P/Q.
%
%   Exemple :
%      y = upfirdn([1 2 3], [1 1 1], 2)     % 1 1 3 2 5 3 3 : 7 échantillons
%
%   Voir aussi RESAMPLE, INTERP, DECIMATE, FILTER.
    if nargin < 3, p = 1; end
    if nargin < 4, q = 1; end
    if ~isscalar(p) || ~isscalar(q) || p < 1 || q < 1 || p ~= fix(p) || q ~= fix(q)
        error('signal:upfirdn:Facteurs', 'P and Q must be positive integers.');
    end
    ligne = isrow(x);
    if ligne
        x = x(:);
    end
    h = h(:);
    nx = size(x, 1);
    y = [];
    for c = 1:size(x, 2)
        sur = zeros((nx - 1) * p + 1, 1);
        sur(1:p:end) = x(:, c);
        filtre = conv(sur, h);
        colonne = filtre(1:q:end);
        y = [y, colonne];                                      %#ok<AGROW>
    end
    if ligne
        y = y.';
    end
end
