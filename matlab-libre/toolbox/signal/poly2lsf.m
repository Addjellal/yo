function lsf = poly2lsf(a)
%POLY2LSF Fréquences spectrales de raies d'un polynôme de prédiction.
%   LSF = POLY2LSF(A) forme les polynômes somme et différence
%      P(z) = A(z) + z^-(p+1) A(1/z),   Q(z) = A(z) - z^-(p+1) A(1/z),
%   dont toutes les racines sont sur le cercle unité et s'entrelacent.
%   Les LSF sont leurs arguments, rangés par ordre croissant dans
%   ]0, pi[. C'est la représentation utilisée par les codeurs de parole :
%   elle se quantifie sans perdre la stabilité.
%
%   Exemple :
%      lsf = poly2lsf([1 -0.5]);
    a = double(a(:)).';
    if a(1) == 0
        error('signal:poly2lsf:ZeroLeading', ...
              'Le premier coefficient doit être non nul.');
    end
    a = a / a(1);
    if any(abs(roots(a)) >= 1)
        error('signal:poly2lsf:UnstablePolynomial', ...
              'Le polynôme doit être à phase minimale.');
    end
    p = numel(a) - 1;
    miroir = fliplr(a);
    P = [a 0] + [0 miroir];
    Q = [a 0] - [0 miroir];
    % Les racines trivialement connues se retirent : z = -1 pour P et
    % z = +1 pour Q, plus une paire selon la parité.
    if mod(p, 2) == 0
        P = deconv(P, [1 1]);
        Q = deconv(Q, [1 -1]);
    else
        Q = deconv(Q, [1 0 -1]);
    end
    angles = [angle(roots(P)); angle(roots(Q))];
    angles = angles(angles > 1e-12 & angles < pi - 1e-12);
    lsf = sort(angles);
    lsf = lsf(:);
end
