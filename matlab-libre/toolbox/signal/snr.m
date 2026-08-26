function r = snr(signal, bruit)
%SNR Rapport signal sur bruit, en décibels.
%   R = SNR(SIGNAL,BRUIT) rend 10*log10(puissance signal / puissance bruit).
    ps = mean(signal(:) .^ 2);
    pb = mean(bruit(:) .^ 2);
    r = 10 * log10(ps / pb);
end
