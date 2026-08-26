% 02-traitement-signal.m — filtrage et analyse spectrale.
%
% Un signal à deux raies noyé dans du bruit, filtré par un passe-bas de
% Butterworth ; la figure est écrite en SVG.

fs = 1000;
t = (0:999) / fs;
propre = sin(2*pi*50*t) + 0.5 * sin(2*pi*220*t);
rng(1);
bruite = propre + 0.6 * randn(size(t));

[b, a] = butter(4, 100 / (fs/2));
filtre = filtfilt(b, a, bruite);

fprintf('Rapport signal sur bruit avant filtrage : %.2f dB\n', ...
        snr(propre, bruite - propre));
fprintf('Rapport signal sur bruit apres filtrage : %.2f dB\n', ...
        snr(propre, filtre - propre));

% Spectre du signal bruité.
[Pxx, f] = periodogram(bruite, hamming(numel(t)), 1024, fs);
[~, pic] = max(Pxx);
fprintf('Raie principale detectee a %.1f Hz\n', f(pic));

figure(1);
subplot(2, 1, 1);
plot(t(1:200), bruite(1:200), t(1:200), filtre(1:200));
title('Signal bruite et signal filtre');
xlabel('Temps (s)');
legend('bruite', 'filtre');
grid on;

subplot(2, 1, 2);
semilogy(f, Pxx);
title('Densite spectrale de puissance');
xlabel('Frequence (Hz)');
grid on;

print('exemple-signal.svg');
fprintf('Figure ecrite dans exemple-signal.svg\n');
