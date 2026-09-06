function [b, a, k] = butter(n, Wn, genre)
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
%   Le prototype analogique est transposé par transformation bilinéaire
%   avec pré-distorsion de la fréquence, comme le fait la fonction de
%   référence.
%
%   Exemples :
%      [b, a] = butter(4, 0.3);
%      [b, a] = butter(2, [0.2 0.5]);      % passe-bande d'ordre 4
%      [z, p, k] = butter(4, 0.3);         % zeros, poles et gain
%
%   Voir aussi BUTTAP, BUTTORD, CHEBY1, CHEBY2, ELLIP, FILTFILT.
    if nargin < 3
        genre = 'low';
    end
    [~, poles] = buttap(n);
    [b, a, zNum, pNum, kNum] = prototypeVersNumerique(poles, [], 1, Wn, genre);
    % Trois sorties : MATLAB rend alors la forme zéros-pôles-gain, dont la
    % conception numérique est plus stable que celle des coefficients.
    if nargout > 2
        b = zNum;
        a = pNum;
        k = kNum;
    end
end
