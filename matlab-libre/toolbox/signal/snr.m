function r = snr(signal, bruit)
%SNR Rapport signal sur bruit, en décibels.
%   R = SNR(SIGNAL,BRUIT) rend 10*log10(puissance signal / puissance bruit).
%
%   Exemple :
%      rng(1);
%      signal = sin(2 * pi * 0.05 * (0:999)');
%      abs(snr(signal, 0.1 * randn(1000, 1)) - 20 * log10(rms(signal) / 0.1)) < 1
%
%   Voir aussi SINAD, THD, SFDR, TOI.
    ps = mean(signal(:) .^ 2);
    pb = mean(bruit(:) .^ 2);
    r = 10 * log10(ps / pb);
end
