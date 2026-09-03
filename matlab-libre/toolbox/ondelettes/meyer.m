function [psi, xval] = meyer(bas, haut, n, genre)
%MEYER Ondelette et fonction d'échelle de Meyer.
%   [PSI,X] = MEYER(LB,UB,N) échantillonne l'ondelette de Meyer sur N
%   points de [LB,UB]. N doit être une puissance de deux.
%   [PHI,X] = MEYER(LB,UB,N,'phi') rend la fonction d'échelle ;
%   'psi' (défaut) rend l'ondelette.
%
%   L'ondelette de Meyer est définie par sa transformée de Fourier, à
%   support borné et infiniment dérivable :
%
%      phi(w) = 1                          si |w| <= 2 pi/3,
%      phi(w) = cos(pi/2 nu(3|w|/(2pi)-1)) si 2 pi/3 <= |w| <= 4 pi/3,
%      phi(w) = 0                          au-delà,
%
%   où nu est MEYERAUX. L'ondelette s'en déduit par la relation
%   habituelle du banc de filtres. Elle n'est pas à support compact, mais
%   décroît plus vite que toute puissance : c'est le compromis inverse de
%   celui des Daubechies.
%
%   Exemple :
%      [psi, x] = meyer(-8, 8, 1024);
%      abs(trapz(x, psi))             % nul : moyenne nulle
%
%   Voir aussi MEYERAUX, MORLET, MEXIHAT, WAVEFUN.
    if nargin < 1 || isempty(bas), bas = -8; end
    if nargin < 2 || isempty(haut), haut = 8; end
    if nargin < 3 || isempty(n), n = 1024; end
    if nargin < 4 || isempty(genre), genre = 'psi'; end
    n = round(n);
    if n < 2 || bitand(n, n - 1) ~= 0
        error('wavelet:meyer:Puissance', ...
              'Le nombre de points doit être une puissance de deux.');
    end
    genre = lower(char(genre));
    xval = linspace(bas, haut, n);
    etendue = haut - bas;
    % La grille en pulsation qui correspond à l'échantillonnage demandé.
    w = (2 * pi / etendue) * [0:(n/2), (-n/2+1):-1];
    absw = abs(w);
    if strcmp(genre, 'phi')
        spectre = fenetrePhi(absw);
        decalage = 0;
    elseif strcmp(genre, 'psi')
        % psi(w) = exp(-i w / 2) [ ... ] : le module se construit sur deux
        % intervalles, le demi-échantillon de retard centre l'ondelette.
        spectre = zeros(size(w));
        milieu = (absw >= 2 * pi / 3) & (absw <= 4 * pi / 3);
        spectre(milieu) = sin(pi / 2 * meyeraux(3 * absw(milieu) / (2 * pi) - 1));
        loin = (absw > 4 * pi / 3) & (absw <= 8 * pi / 3);
        spectre(loin) = cos(pi / 2 * meyeraux(3 * absw(loin) / (4 * pi) - 1));
        decalage = 0.5;
    else
        error('wavelet:meyer:Genre', 'Le genre doit être ''psi'' ou ''phi''.');
    end
    spectre = spectre .* exp(-1i * w * decalage);
    psi = real(ifft(spectre)) * n / etendue;
    % Le spectre est centré sur zéro : la sortie l'est aussi, ce qui
    % demande de replier les deux moitiés.
    psi = [psi(n/2+1:end), psi(1:n/2)];
end

function f = fenetrePhi(absw)
%FENETREPHI Le module de la transformée de la fonction d'échelle.
    f = zeros(size(absw));
    f(absw <= 2 * pi / 3) = 1;
    transition = (absw > 2 * pi / 3) & (absw <= 4 * pi / 3);
    f(transition) = cos(pi / 2 * meyeraux(3 * absw(transition) / (2 * pi) - 1));
end
