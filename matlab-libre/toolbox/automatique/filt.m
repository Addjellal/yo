function sys = filt(num, den, Ts)
%FILT Modèle discret écrit en puissances de z^-1.
%   SYS = FILT(NUM,DEN) construit le modèle
%
%      H(z) = (num(1) + num(2) z^-1 + ...) / (den(1) + den(2) z^-1 + ...)
%
%   C'est la convention du traitement du signal, où les coefficients
%   suivent les retards. FILT(NUM,DEN,TS) fixe la période
%   d'échantillonnage ; sans elle, la période vaut -1, ce qui désigne un
%   modèle discret de période non précisée.
%
%   Exemple :
%      g = filt([1 0.5], [1 -0.3]);
%      tfdata(g)   % [1 0.5] : les deux écritures coïncident ici
%
%   Voir aussi TF, C2D.
    if nargin < 3 || isempty(Ts), Ts = -1; end
    num = double(num(:)).';
    den = double(den(:)).';
    % Multiplier haut et bas par z^(m-1) ramène l'écriture en puissances
    % décroissantes : il suffit d'aligner les longueurs par la droite.
    m = max(numel(num), numel(den));
    num = [num, zeros(1, m - numel(num))];
    den = [den, zeros(1, m - numel(den))];
    sys = tf(num, den, Ts);
end
