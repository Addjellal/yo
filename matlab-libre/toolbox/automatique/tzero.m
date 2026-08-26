function z = tzero(a, b, c, d)
%TZERO Zéros de transmission d'un système d'état.
%   Z = TZERO(A,B,C,D) ou TZERO(SYS). Ce sont les valeurs de s pour
%   lesquelles la matrice de Rosenbrock [A-sI B; C D] perd son rang :
%   le transfert s'y annule, quelle que soit la direction d'entrée.
%
%   Quand D est inversible, ces valeurs sont exactement les valeurs
%   propres de A - B*inv(D)*C : c'est le résultat classique, et c'est ce
%   qui est calculé ici. Sinon, on passe par la fonction de transfert.
%
%   Exemple :
%      tzero(-1, 1, -1, 1)   % 0 : le transfert vaut s/(s+1)
    if nargin == 1
        systeme = a;
        a = systeme.A;
        b = systeme.B;
        c = systeme.C;
        d = systeme.D;
    end
    if isempty(d), d = zeros(size(c, 1), size(b, 2)); end
    carre = size(d, 1) == size(d, 2);
    if carre && size(d, 1) > 0 && rcond(d) > 1e-12
        z = eig(a - b * (d \ c));
        return
    end
    % D singulière ou système non carré : les zéros sont les racines du
    % numérateur de la fonction de transfert.
    [num, ~] = ss2tf(a, b, c, d);
    num = num(:).';
    while numel(num) > 1 && abs(num(1)) < 1e-12
        num(1) = [];
    end
    if numel(num) <= 1
        z = zeros(0, 1);
    else
        z = roots(num);
    end
end
