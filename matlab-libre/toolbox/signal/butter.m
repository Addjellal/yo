function [b, a, k] = butter(n, Wn, varargin)
%BUTTER Filtre numérique de Butterworth.
%   [B,A] = BUTTER(N,WN) conçoit un passe-bas d'ordre N de fréquence de
%   coupure normalisée WN (0 < WN < 1, 1 = Nyquist).
%   [Z,P,K] = BUTTER(...) rend la forme zéros-pôles-gain, dont la
%   conception est numériquement plus stable que celle des coefficients :
%   au-delà de l'ordre huit environ, les coefficients d'un polynôme
%   perdent leurs chiffres significatifs, pas les racines.
%   [B,A] = BUTTER(N,WN,'high') conçoit un passe-haut.
%   [B,A] = BUTTER(N,[W1 W2]) conçoit un passe-bande d'ordre 2N, et
%   BUTTER(N,[W1 W2],'stop') un coupe-bande.
%
%   Le filtre de Butterworth est le seul dont le module est monotone dans
%   les deux bandes : il n'ondule nulle part, au prix d'une transition
%   plus douce qu'un Chebyshev de même ordre.
%
%   [B,A] = BUTTER(N,WN,'s') conçoit un filtre analogique : WN est alors
%   en radians par seconde et n'est plus borné à un. 'high' et 'stop' se
%   combinent avec 's' — BUTTER(N,WN,'high','s').
%
%   Le prototype analogique est transposé par transformation bilinéaire
%   avec pré-distorsion de la fréquence, comme le fait la fonction de
%   référence. En analogique il n'y a rien à pré-distordre : seule la
%   transformation de bande s'applique.
%
%   Exemples :
%      [b, a] = butter(4, 0.3);
%      [b, a] = butter(2, [0.2 0.5]);      % passe-bande d'ordre 4
%      [z, p, k] = butter(4, 0.3);         % zeros, poles et gain
%      [b, a] = butter(4, 100, 's');       % analogique, 100 rad/s
%
%   Voir aussi BUTTAP, BUTTORD, CHEBY1, CHEBY2, ELLIP, FILTFILT.
    [genre, analogique] = matlibre_genre_filtre(varargin);
    [~, poles] = buttap(n);
    if analogique
        [b, a, zNum, pNum, kNum] = ...
            matlibre_prototype_analogique(poles, [], 1, Wn, genre);
    else
        [b, a, zNum, pNum, kNum] = prototypeVersNumerique(poles, [], 1, Wn, genre);
    end
    % Trois sorties : MATLAB rend alors la forme zéros-pôles-gain, dont la
    % conception numérique est plus stable que celle des coefficients.
    if nargout > 2
        b = zNum;
        a = pNum;
        k = kNum;
    end
end
