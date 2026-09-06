function [haut, bas] = envelope(x)
%ENVELOPE Enveloppes supérieure et inférieure d'un signal.
%   [H,B] = ENVELOPE(X) rend les deux enveloppes, calculées comme le
%   module du signal analytique de part et d'autre de la valeur moyenne.
%
%   L'enveloppe encadre le signal : H le majore, B le minore, partout sauf
%   aux tout premiers et derniers échantillons, où l'effet de bord de la
%   transformée de Hilbert la fait dévier. C'est une propriété du calcul
%   en fréquence, non un défaut de mise en œuvre — la transformée suppose
%   le signal périodique.
%
%   Le retrait de la moyenne avant le calcul permet de traiter un signal
%   qui porte une composante continue : sans lui, l'enveloppe d'un signal
%   décalé serait fausse des deux côtés.
%
%   L'orientation est conservée : une ligne rend deux lignes.
%
%   Exemple :
%      t = (0:999) / 1000;
%      x = sin(2*pi*50*t) .* (1 + 0.5 * sin(2*pi*2*t));
%      [h, b] = envelope(x);
%      all(h(20:end-20) >= x(20:end-20))    % true : elle majore
%
%   Voir aussi HILBERT, RMS, FINDPEAKS.
    m = mean(x(:));
    a = abs(hilbert(x - m));
    haut = m + a;
    bas = m - a;
end
