function [psi, xval] = cgauwavf(bas, haut, n, ordre)
%CGAUWAVF Ondelette gaussienne complexe.
%   [PSI,X] = CGAUWAVF(LB,UB,N,P) échantillonne sur N points de [LB,UB]
%   la dérivée P-ième de exp(-i x) exp(-x^2), normalisée à une norme deux
%   unitaire. P va de 1 à 8.
%
%   La modulation par exp(-i x) rend l'ondelette complexe : sa
%   transformée ne couvre que les pulsations positives, si bien que la
%   transformée continue en rend module et phase séparément — ce qu'une
%   ondelette réelle ne permet pas.
%
%   La dérivée se calcule par récurrence sur le polynôme qui multiplie
%   l'exponentielle : P_0 = 1, P_{k+1} = P_k' + (-2x - i) P_k.
%
%   Exemple :
%      [psi, x] = cgauwavf(-5, 5, 1000, 1);
%      trapz(x, abs(psi) .^ 2)        % un
%      abs(trapz(x, psi))             % nul : moyenne nulle
%
%   Voir aussi GAUSWAVF, CMORWAVF, SHANWAVF, MEXIHAT, CWT.
    if nargin < 1 || isempty(bas), bas = -5; end
    if nargin < 2 || isempty(haut), haut = 5; end
    if nargin < 3 || isempty(n), n = 1000; end
    if nargin < 4 || isempty(ordre), ordre = 1; end
    ordre = round(ordre);
    if ordre < 1 || ordre > 8
        error('wavelet:cgauwavf:BadOrder', 'L''ordre doit aller de 1 à 8.');
    end
    xval = linspace(bas, haut, n);
    constante = normalisation(@(t) gaussienneComplexe(t, ordre));
    psi = constante * gaussienneComplexe(xval, ordre);
end

function v = gaussienneComplexe(x, ordre)
%GAUSSIENNECOMPLEXE La dérivée, sans normalisation.
    % Polynôme en puissances décroissantes, comme POLYVAL.
    p = 1;
    for k = 1:ordre
        derivee = polyder(p);
        p = ajouter(derivee, conv([-2 -1i], p));
    end
    v = polyval(p, x) .* exp(-x .^ 2 - 1i * x);
end

function s = ajouter(a, b)
%AJOUTER Somme de deux polynômes de degrés éventuellement différents.
    n = max(numel(a), numel(b));
    s = [zeros(1, n - numel(a)), a] + [zeros(1, n - numel(b)), b];
end

function c = normalisation(fonction)
%NORMALISATION Constante qui donne une norme deux unitaire.
%   L'intégrale est prise sur un intervalle assez large pour que la queue
%   soit négligeable, et non sur celui que demande l'appelant : la
%   constante ne dépend donc pas de la fenêtre d'échantillonnage.
    t = linspace(-20, 20, 20001);
    energie = trapz(t, abs(fonction(t)) .^ 2);
    c = 1 / sqrt(energie);
end
