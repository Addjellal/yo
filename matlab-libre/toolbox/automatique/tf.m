function sys = tf(num, den, Ts)
%TF Modèle sous forme de fonction de transfert.
%   SYS = TF(NUM,DEN) crée un modèle continu dont la transmittance est le
%   quotient des polynômes NUM et DEN, écrits en puissances décroissantes.
%   SYS = TF(NUM,DEN,TS) crée un modèle échantillonné de période TS.
%
%   Exemple :
%      G = tf([1], [1 2 1]);   % 1/(s+1)^2
    if nargin < 3
        Ts = 0;
    end
    if nargin == 1 && isstruct(num)
        sys = num;
        return;
    end
    sys = struct('type', 'tf', 'num', num(:).', 'den', den(:).', 'Ts', Ts, ...
                 'A', [], 'B', [], 'C', [], 'D', []);
end
