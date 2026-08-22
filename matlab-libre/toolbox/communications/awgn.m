function y = awgn(x, snrdB, puissanceSignal)
%AWGN Ajoute un bruit blanc gaussien pour atteindre un rapport donné.
%   Y = AWGN(X,SNR) ajoute du bruit tel que le rapport signal sur bruit
%   vaille SNR décibels, la puissance du signal étant mesurée sur X.
    if nargin < 3 || (ischar(puissanceSignal) && strcmpi(puissanceSignal, 'measured'))
        puissanceSignal = mean(abs(x(:)) .^ 2);
    end
    puissanceBruit = puissanceSignal / (10 ^ (snrdB / 10));
    if isreal(x)
        bruit = sqrt(puissanceBruit) * randn(size(x));
    else
        bruit = sqrt(puissanceBruit / 2) * (randn(size(x)) + 1i * randn(size(x)));
    end
    y = x + bruit;
end
