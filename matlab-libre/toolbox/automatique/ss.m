function sys = ss(A, B, C, D, Ts)
%SS Modèle d'état.
%   SYS = SS(A,B,C,D) crée un modèle continu dx/dt = Ax + Bu, y = Cx + Du.
%   SYS = SS(A,B,C,D,TS) crée un modèle échantillonné.
%   SYS = SS(SYS) convertit n'importe quel modèle en modèle d'état : une
%   fonction de transfert passe par TF2SS, forme compagne de commande.
%   SYS = SS(K) crée un gain statique, sans état.
%
%   Exemple :
%      s = ss(tf(1, [1 1]));   % A = -1, B = 1, C = 1, D = 0
%
%   Voir aussi TF, ZPK, SSDATA, TF2SS.
    if nargin == 1 && isstruct(A)
        if strcmp(A.type, 'ss')
            sys = A;
            return;
        end
        [a, b, c, d] = tf2ss(A.num, A.den);
        sys = ss(a, b, c, d, A.Ts);
        return;
    end
    if nargin == 1
        % Gain statique : aucun état, seule la matrice de transmission
        % directe subsiste.
        D = double(A);
        A = zeros(0, 0);
        B = zeros(0, size(D, 2));
        C = zeros(size(D, 1), 0);
    end
    if nargin < 5
        Ts = 0;
    end
    sys = struct('type', 'ss', 'num', [], 'den', [], 'Ts', Ts, ...
                 'A', A, 'B', B, 'C', C, 'D', D);
end
