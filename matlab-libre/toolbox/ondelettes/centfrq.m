function frequence = centfrq(nom, iterations)
%CENTFRQ Fréquence centrale d'une ondelette.
%   F = CENTFRQ(NOM) rend la fréquence de la raie dominante du spectre de
%   la fonction d'ondelette, en cycles par unité de support. C'est elle
%   qui fait le lien entre échelle et fréquence (voir SCAL2FRQ).
%
%   L'ondelette est échantillonnée par WAVEFUN sur son support [0, L-1] ;
%   la transformée de Fourier discrète d'une période exacte de ce support
%   a donc un pas de 1/(L-1) hertz, et la fréquence centrale est un
%   multiple entier de ce pas.
%
%   F = CENTFRQ(NOM,ITER) fixe le nombre d'itérations de la cascade
%   (8 par défaut).
%
%   Les ondelettes continues — 'mexh', 'morl', 'gausP' — sont
%   échantillonnées sur leur support effectif : [-8, 8] pour le chapeau
%   mexicain et Morlet, [-5, 5] pour les gaussiennes. Le pas fréquentiel
%   vaut alors 1/16 et 1/10.
%
%   Exemple :
%      centfrq('db2')    % 0.6667 = 2/3
%      centfrq('db4')    % 0.7143 = 5/7
%      centfrq('mexh')   % 0.2500 = 4/16
%      centfrq('morl')   % 0.8125 = 13/16
%
%   Voir aussi SCAL2FRQ, WAVEFUN.
    if nargin < 2 || isempty(iterations), iterations = 8; end
    [~, ~, famille] = supportOndeletteContinue(nom);
    if isempty(famille)
        [~, psi, xval] = wavefun(nom, iterations);
    else
        % Pas de fonction d'échelle : WAVEFUN rend directement psi.
        [psi, xval] = wavefun(nom, iterations);
    end
    n = numel(psi);
    if n < 4
        frequence = 0;
        return
    end
    % Le dernier échantillon est la répétition périodique du premier : on
    % le retire pour que la DFT porte sur exactement une période, de durée
    % T = xval(end) - xval(1).
    y = psi(1:end-1);
    duree = xval(end) - xval(1);
    spectre = abs(fft(y));
    demi = floor(numel(y) / 2);
    [~, k] = max(spectre(2:demi + 1));
    frequence = k / duree;
end
