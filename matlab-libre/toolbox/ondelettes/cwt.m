function [coefficients, frequences] = cwt(x, echelles, nom, delta)
%CWT Transformée en ondelettes continue.
%   C = CWT(X,ECHELLES,NOM) rend une ligne de coefficients par échelle :
%
%      C(a,b) = 1/sqrt(a) * somme_k X(k) psi((k-b)/a)
%
%   NOM peut désigner une ondelette continue — 'mexh' (chapeau mexicain,
%   par défaut), 'morl' (Morlet réelle), 'gausP' pour P de 1 à 8 — ou une
%   ondelette discrète, 'dbN' ou 'symN', dont la fonction d'ondelette est
%   alors calculée par l'algorithme en cascade puis rééchantillonnée.
%
%   [C,F] = CWT(X,ECHELLES,NOM,DELTA) rend en plus les pseudo-fréquences
%   associées aux échelles, DELTA étant le pas d'échantillonnage :
%   F = CENTFRQ(NOM) ./ (ECHELLES * DELTA).
%
%   Les bords ne sont pas prolongés : la somme se limite aux indices
%   présents, ce qui atténue les coefficients sur une largeur d'échelle
%   à chaque extrémité.
%
%   Exemple :
%      t = (0:1023) / 1024;
%      x = sin(2 * pi * 60 * t);
%      [c, f] = cwt(x, 1:64, 'morl', 1/1024);
%      [~, k] = max(max(abs(c), [], 2));
%      f(k)     % voisin de 60 Hz
%
%   Voir aussi CENTFRQ, SCAL2FRQ, MEXIHAT, MORLET, GAUSWAVF.
    if nargin < 2 || isempty(echelles), echelles = 1:8; end
    if nargin < 3 || isempty(nom), nom = 'mexh'; end
    if nargin < 4 || isempty(delta), delta = 1; end
    x = double(x);
    x = x(:)';
    n = numel(x);
    echelles = double(echelles(:))';
    [bas, haut, famille, ordre] = supportOndeletteContinue(nom);
    psiTable = [];
    xTable = [];
    if isempty(famille)
        % Ondelette discrète : on prend la fonction d'ondelette de la
        % cascade, recentrée sur son support.
        [~, psiTable, xTable] = wavefun(nom, 10);
        xTable = xTable - (xTable(1) + xTable(end)) / 2;
        bas = xTable(1);
        haut = xTable(end);
    end
    portee = max(abs(bas), abs(haut));
    coefficients = zeros(numel(echelles), n);
    for s = 1:numel(echelles)
        a = echelles(s);
        if a <= 0
            error('wavelet:cwt:BadScale', 'Les échelles doivent être positives.');
        end
        m = max(1, ceil(portee * a));
        u = (-m:m) / a;
        noyau = evaluerOndelette(u, famille, ordre, psiTable, xTable) / sqrt(a);
        y = conv(x, noyau(end:-1:1));
        coefficients(s, :) = y(m + 1:m + n);
    end
    if nargout > 1
        frequences = centfrq(nom) ./ (echelles * delta);
    end
end

function psi = evaluerOndelette(u, famille, ordre, psiTable, xTable)
%EVALUERONDELETTE Valeur de l'ondelette aux abscisses U.
    switch famille
        case 'mexh'
            psi = 2 / (sqrt(3) * pi ^ 0.25) * (1 - u .^ 2) .* exp(-u .^ 2 / 2);
        case 'morl'
            psi = exp(-u .^ 2 / 2) .* cos(5 * u);
        case 'gaus'
            hMoins = ones(size(u));
            h = 2 * u;
            for k = 1:(ordre - 1)
                suivant = 2 * u .* h - 2 * k * hMoins;
                hMoins = h;
                h = suivant;
            end
            doubleFactorielle = 1;
            for k = 1:ordre
                doubleFactorielle = doubleFactorielle * (2 * k - 1);
            end
            psi = (-1) ^ ordre * h .* exp(-u .^ 2) / sqrt(sqrt(2 * pi) * doubleFactorielle / 2);
        otherwise
            psi = interp1(xTable, psiTable, u, 'linear', 0);
    end
end
