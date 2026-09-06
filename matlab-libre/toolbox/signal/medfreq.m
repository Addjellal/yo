function f = medfreq(x, fs)
%MEDFREQ Fréquence médiane : celle qui coupe la puissance en deux.
%   F = MEDFREQ(X) rend la fréquence qui partage en deux parts égales la
%   puissance du signal, avec une fréquence d'échantillonnage de 1.
%   F = MEDFREQ(X,FS) donne FS en hertz et rend F en hertz.
%
%   La densité spectrale est estimée par périodogramme, puis intégrée ;
%   la fréquence médiane est celle où l'intégrale atteint la moitié de sa
%   valeur finale, obtenue par interpolation linéaire entre les deux
%   points qui l'encadrent.
%
%   Comme toute médiane, elle résiste à ce qui se passe dans les queues :
%   une raie parasite loin de la bande utile la déplace à peine, là où la
%   fréquence moyenne MEANFREQ, qui pondère par la fréquence, s'en trouve
%   tirée. C'est pourquoi le suivi de fatigue musculaire en
%   électromyographie, où le spectre glisse vers le bas, se fait sur elle.
%
%   Exemple :
%      t = (0:1023)' / 1000;
%      f = medfreq(sin(2*pi*50*t), 1000);
%
%   Voir aussi MEANFREQ, BANDPOWER, PERIODOGRAM, OBW.
    if nargin < 2, fs = 1; end
    x = x(:);
    [pxx, freq] = periodogram(x, [], numel(x), fs);
    cumule = cumtrapz(freq, pxx);
    if cumule(end) <= 0
        f = 0;
        return
    end
    cible = cumule(end) / 2;
    k = find(cumule >= cible, 1);
    if isempty(k) || k == 1
        f = freq(1);
    else
        % Interpolation linéaire entre les deux points qui encadrent.
        f = freq(k-1) + (cible - cumule(k-1)) * (freq(k) - freq(k-1)) / ...
            (cumule(k) - cumule(k-1));
    end
end
