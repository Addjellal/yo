function sys = tf(num, den, Ts)
%TF Modèle sous forme de fonction de transfert.
%   SYS = TF(NUM,DEN) crée un modèle continu dont la transmittance est le
%   quotient des polynômes NUM et DEN, écrits en puissances décroissantes.
%   SYS = TF(NUM,DEN,TS) crée un modèle échantillonné de période TS.
%   SYS = TF(K) crée un gain statique.
%   SYS = TF(SYS) convertit n'importe quel modèle en fonction de
%   transfert : un modèle d'état passe par SS2TF.
%
%   Exemple :
%      G = tf([1], [1 2 1]);   % 1/(s+1)^2
%      tf(ss(-1, 1, 1, 0))     % 1/(s+1)
%
%   Voir aussi SS, ZPK, TFDATA, SS2TF.
    if nargin == 1 && isstruct(num)
        modele = num;
        if strcmp(modele.type, 'ss')
            [n, d] = ss2tf(modele.A, modele.B, modele.C, modele.D);
            sys = tf(n, d, modele.Ts);
            return;
        end
        sys = modele;
        return;
    end
    if nargin == 1
        % Gain statique : tf(K) vaut K/1.
        den = 1;
    end
    if nargin < 3
        Ts = 0;
    end
    sys = struct('type', 'tf', 'num', num(:).', 'den', den(:).', 'Ts', Ts, ...
                 'A', [], 'B', [], 'C', [], 'D', []);
end
