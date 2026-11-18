function hz = mel2hz(mel)
%MEL2HZ Échelle de Mel vers les hertz : HZ = 700 (10^(MEL/2595) - 1).
%   L'inverse exact de HZ2MEL (O'Shaughnessy, 1987).
%
%   Exemple :
%      mel2hz(1000)               % 1000
%
%   Voir aussi HZ2MEL, BARK2HZ, ERB2HZ.
    hz = 700 * (10 .^ (mel / 2595) - 1);
end
