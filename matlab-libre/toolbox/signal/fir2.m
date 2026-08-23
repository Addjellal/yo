function b = fir2(n, f, m, fenetre)
%FIR2 Filtre RIF défini par un gabarit de réponse en fréquence.
%   B = FIR2(N,F,M) conçoit un filtre d'ordre N dont le module suit la
%   courbe donnée par les points (F,M). F va de 0 à 1, 1 étant la moitié
%   de la fréquence d'échantillonnage, et doit être croissant.
%
%   La méthode est celle de l'échantillonnage en fréquence : on
%   interpole le gabarit sur une grille fine, on repasse en temps par
%   transformée inverse, puis on fenêtre.
%
%   Exemple :
%      b = fir2(20, [0 0.5 0.5 1], [1 1 0 0]);
    if nargin < 4 || isempty(fenetre), fenetre = hamming(n + 1); end
    f = f(:).';
    m = m(:).';
    if f(1) ~= 0 || abs(f(end) - 1) > 1e-12
        error('signal:fir2:BadFrequencies', 'The frequency vector must start at 0 and end at 1.');
    end
    grille = max(512, 2^nextpow2(n + 1) * 8);
    axe = (0:grille)' / grille;
    gabarit = zeros(numel(axe), 1);
    for k = 1:numel(axe)
        gabarit(k) = interpolerGabarit(f, m, axe(k));
    end
    % Phase linéaire : retard de n/2 échantillons.
    phase = exp(-1i * pi * n * axe / 2 * 2 / 2);
    phase = exp(-1i * pi * axe * n / 2);
    spectre = gabarit .* phase;
    complet = [spectre; conj(spectre(end-1:-1:2))];
    h = real(ifft(complet));
    b = h(1:n+1)' .* fenetre(:)';
end

function v = interpolerGabarit(f, m, x)
%INTERPOLERGABARIT Lit le gabarit en x, en gérant les sauts (f répété).
    k = find(f <= x, 1, 'last');
    if isempty(k), v = m(1); return, end
    if k >= numel(f), v = m(end); return, end
    if f(k + 1) == f(k)
        v = m(k + 1);
        return
    end
    t = (x - f(k)) / (f(k + 1) - f(k));
    v = m(k) + t * (m(k + 1) - m(k));
end
