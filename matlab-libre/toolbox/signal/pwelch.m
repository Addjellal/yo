function [Pxx, f] = pwelch(x, longueur, recouvrement, nfft, fs)
%PWELCH Densité spectrale par la méthode de Welch.
%   [PXX,F] = PWELCH(X,LONGUEUR,RECOUVREMENT,NFFT,FS) découpe X en
%   segments qui se recouvrent, fenêtre chacun, et moyenne les
%   périodogrammes.
    x = x(:);
    n = numel(x);
    if nargin < 2 || isempty(longueur)
        longueur = max(16, floor(n / 8));
    end
    if nargin < 3 || isempty(recouvrement)
        recouvrement = floor(longueur / 2);
    end
    if nargin < 4 || isempty(nfft)
        nfft = 2 ^ nextpow2(longueur);
    end
    if nargin < 5 || isempty(fs)
        fs = 1;
    end
    fenetre = hamming(longueur);
    pas = longueur - recouvrement;
    somme = [];
    compte = 0;
    debut = 1;
    while debut + longueur - 1 <= n
        segment = x(debut:debut+longueur-1);
        [P, f] = periodogram(segment, fenetre, nfft, fs);
        if isempty(somme)
            somme = P;
        else
            somme = somme + P;
        end
        compte = compte + 1;
        debut = debut + pas;
    end
    if compte == 0
        [somme, f] = periodogram(x, [], nfft, fs);
        compte = 1;
    end
    Pxx = somme / compte;
end
