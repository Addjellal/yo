function [b, a, k] = cheby2(n, rs, Wn, varargin)
%CHEBY2 Filtre de Chebyshev de type II, ondulation en bande atténuée.
%   [B,A] = CHEBY2(N,RS,WN) conçoit un passe-bas d'ordre N de fréquence de
%   coupure normalisée WN (0 < WN < 1, 1 = Nyquist). RS est l'atténuation
%   minimale en décibels dans la bande coupée.
%   [Z,P,K] = CHEBY2(...) rend la forme zéros-pôles-gain.
%   [B,A] = CHEBY2(N,RS,WN,'high') conçoit un passe-haut, et
%   CHEBY2(N,RS,[W1 W2]) un passe-bande d'ordre 2N, 'stop' un coupe-bande.
%   [B,A] = CHEBY2(...,'s') conçoit un filtre analogique : WN est alors en
%   radians par seconde, et aucune pré-distorsion n'a lieu.
%
%   Le type II est l'inverse du type I : il ondule dans la bande coupée et
%   reste monotone dans la bande passante. C'est ce qui le fait préférer
%   quand la bande utile doit être plate — l'ondulation est reléguée là où
%   le signal ne passe pas.
%
%   Il l'obtient en plaçant des zéros sur l'axe imaginaire : la réponse
%   s'annule exactement à ces fréquences, et remonte entre elles jusqu'à
%   RS. Un ordre impair laisse un zéro à l'infini, si bien que le filtre
%   tend vers zéro au lieu d'osciller indéfiniment.
%
%   WN désigne ici le début de la bande coupée, non la coupure à -3 dB :
%   c'est la fréquence où l'atténuation atteint RS. Un Chebyshev de type I
%   et un de type II de mêmes ordre et WN n'ont donc pas la même bande
%   passante.
%
%   Exemples :
%      [b, a] = cheby2(4, 40, 0.3);
%      [b, a] = cheby2(6, 60, [0.2 0.5]);     % passe-bande d'ordre 12
%      [b, a] = cheby2(4, 40, 100, 's');      % analogique, 100 rad/s
%
%   Voir aussi CHEBY1, CHEB2AP, CHEB2ORD, BUTTER, ELLIP, FILTFILT.
    [genre, analogique] = matlibre_genre_filtre(varargin);
    epsilon = 1 / sqrt(10^(rs / 10) - 1);
    mu = asinh(1 / epsilon) / n;
    k = 1:n;
    theta = pi * (2 * k - 1) / (2 * n);
    polesType1 = -sinh(mu) * sin(theta) + 1i * cosh(mu) * cos(theta);
    poles = 1 ./ polesType1;
    if mod(n, 2) == 0
        zeros_ = 1i ./ cos(theta);
    else
        milieu = (n + 1) / 2;
        garde = true(1, n);
        garde(milieu) = false;
        zeros_ = 1i ./ cos(theta(garde));
    end
    gain = real(prod(-poles) / prod(-zeros_));
    if analogique
        [b, a, zNum, pNum, kNum] = ...
            matlibre_prototype_analogique(poles, zeros_, gain, Wn, genre);
    else
        [b, a, zNum, pNum, kNum] = prototypeVersNumerique(poles, zeros_, gain, Wn, genre);
    end
    % Trois sorties : MATLAB rend alors la forme zéros-pôles-gain, dont la
    % conception numérique est plus stable que celle des coefficients.
    if nargout > 2
        b = zNum;
        a = pNum;
        k = kNum;
    end
end
