function hz = bark2hz(bark)
%BARK2HZ Échelle de Bark vers les hertz, inverse de HZ2BARK (Traunmüller, 1990).
%   Les corrections des bouts s'inversent d'abord — sous 2 Bark,
%   (b - 0.3) / 0.85 ; au-dessus de 20.1, (b + 4.422) / 1.22 — puis
%   HZ = 1960 (b + 0.53) / (26.28 - b).
%
%   Exemple :
%      bark2hz(hz2bark(1000))     % 1000
%
%   Voir aussi HZ2BARK, MEL2HZ, ERB2HZ.
    b = bark;
    bas = b < 2;
    b(bas) = (b(bas) - 0.3) / 0.85;
    haut = b > 20.1;
    b(haut) = (b(haut) + 4.422) / 1.22;
    hz = 1960 * (b + 0.53) ./ (26.28 - b);
end
