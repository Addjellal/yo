function [psi, xval] = gauswavf(bas, haut, n, ordre)
%GAUSWAVF Ondelettes gaussiennes : les dérivées de exp(-x^2).
%   [PSI,X] = GAUSWAVF(LB,UB,N,P) échantillonne sur N points de [LB,UB] la
%   dérivée P-ième de la gaussienne, normalisée à une norme deux unitaire.
%   P va de 1 à 8. La dérivée s'écrit avec les polynômes d'Hermite :
%
%      d^p/dx^p exp(-x^2) = (-1)^p H_p(x) exp(-x^2)
%
%   et la constante de normalisation se calcule exactement par Parseval :
%
%      ||d^p/dx^p exp(-x^2)||^2 = sqrt(2 pi) (2p-1)!! / 2
%
%   Exemple :
%      [psi, x] = gauswavf(-5, 5, 1000, 1);
%      trapz(x, psi .^ 2)   % un
%
%   Voir aussi MEXIHAT, MORLET, CWT.
    if nargin < 1 || isempty(bas), bas = -5; end
    if nargin < 2 || isempty(haut), haut = 5; end
    if nargin < 3 || isempty(n), n = 1000; end
    if nargin < 4 || isempty(ordre), ordre = 1; end
    ordre = round(ordre);
    if ordre < 1 || ordre > 8
        error('wavelet:gauswavf:BadOrder', 'L''ordre doit aller de 1 à 8.');
    end
    xval = linspace(bas, haut, n);
    % Polynôme d'Hermite par récurrence : H0 = 1, H1 = 2x,
    % H_{k+1} = 2x H_k - 2k H_{k-1}.
    hMoins = ones(1, n);
    h = 2 * xval;
    for k = 1:(ordre - 1)
        suivant = 2 * xval .* h - 2 * k * hMoins;
        hMoins = h;
        h = suivant;
    end
    if ordre == 0
        h = hMoins;
    end
    % Double factorielle (2p-1)!!
    doubleFactorielle = 1;
    for k = 1:ordre
        doubleFactorielle = doubleFactorielle * (2 * k - 1);
    end
    norme = sqrt(sqrt(2 * pi) * doubleFactorielle / 2);
    psi = (-1) ^ ordre * h .* exp(-xval .^ 2) / norme;
end
