function y = hilbert(x, n)
%HILBERT Signal analytique par transformée de Hilbert.
%   Y = HILBERT(X) rend un signal complexe dont la partie réelle est X et
%   la partie imaginaire sa transformée de Hilbert.
%   Y = HILBERT(X,N) emploie N points : X est tronqué ou complété de zéros.
%
%   Le calcul se fait en fréquence : annuler les fréquences négatives et
%   doubler les positives. C'est la définition même du signal analytique,
%   et cela explique ses effets de bord — la transformée de Fourier
%   suppose le signal périodique, si bien que le début et la fin
%   s'influencent.
%
%   Le module du signal analytique est l'enveloppe du signal, et la
%   dérivée de sa phase la fréquence instantanée. C'est à cela qu'il sert.
%
%   L'orientation est conservée : une ligne rend une ligne, une colonne
%   une colonne. Une matrice est traitée colonne par colonne, comme dans
%   MATLAB.
%
%   Exemple :
%      x = sin(2 * pi * 50 * (0:999) / 1000);
%      a = hilbert(x);
%      max(abs(real(a) - x))           % 0 : la partie reelle est x
%      abs(a(100:900))                 % 1 : l'enveloppe d'un sinus
%
%   Voir aussi ENVELOPE, FFT, ANGLE, UNWRAP.
    ligne = isrow(x);
    if isvector(x)
        colonnes = {x(:)};
    else
        colonnes = num2cell(double(x), 1);
    end
    if nargin < 2 || isempty(n)
        n = numel(colonnes{1});
    end
    sorties = cell(size(colonnes));
    for k = 1:numel(colonnes)
        X = fft(colonnes{k}, n);
        h = zeros(n, 1);
        if mod(n, 2) == 0
            h(1) = 1;
            h(n/2 + 1) = 1;
            h(2:n/2) = 2;
        else
            h(1) = 1;
            h(2:(n+1)/2) = 2;
        end
        sorties{k} = ifft(X .* h);
    end
    y = [sorties{:}];
    if ligne
        y = y.';
    end
end
