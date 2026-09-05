function [Pxx, f] = pwelch(x, fenetre, recouvrement, nfft, fs)
%PWELCH Densité spectrale par la méthode de Welch.
%   [PXX,F] = PWELCH(X,FENETRE,RECOUVREMENT,NFFT,FS) découpe X en
%   segments qui se recouvrent, fenêtre chacun, et moyenne les
%   périodogrammes.
%
%   FENETRE vaut soit une longueur de segment — la fenêtre est alors une
%   Hamming de cette longueur — soit directement le vecteur de la
%   fenêtre à employer. Vide, la longueur est le huitième du signal.
%
%   Un périodogramme seul a une variance qui ne décroît pas avec la
%   longueur du signal : allonger l'enregistrement affine la grille de
%   fréquences sans rien calmer. Moyenner plusieurs périodogrammes, eux,
%   divise la variance par leur nombre — c'est tout l'objet de la
%   méthode, et le recouvrement sert à en obtenir davantage.
%
%   Exemple :
%      [p, f] = pwelch(randn(1024, 1), hamming(256), 128, 512, 1000);
%
%   Voir aussi PERIODOGRAM, SPECTROGRAM, FFT, HAMMING.
    x = x(:);
    n = numel(x);
    if nargin < 2 || isempty(fenetre)
        fenetre = max(16, floor(n / 8));
    end
    if isscalar(fenetre)
        longueur = round(double(fenetre));
        fenetre = hamming(longueur);
    else
        fenetre = double(fenetre(:));
        longueur = numel(fenetre);
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
    recouvrement = round(double(recouvrement));
    if recouvrement >= longueur
        error('signal:pwelch:Recouvrement', ...
              'Le recouvrement doit être inférieur à la longueur du segment.');
    end
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
