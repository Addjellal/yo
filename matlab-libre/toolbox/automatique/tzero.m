function z = tzero(a, b, c, d)
%TZERO Zéros de transmission d'un modèle.
%   Z = TZERO(SYS) rend les zéros de transmission : les valeurs de s pour
%   lesquelles le modèle ne transmet rien, quelle que soit l'entrée. Un
%   zéro à partie réelle positive — un zéro instable — limite ce qu'un
%   correcteur peut faire, quel qu'il soit.
%
%   Ils s'obtiennent comme les valeurs propres généralisées du faisceau
%   de Rosenbrock.
%
%   Exemples :
%      tzero(tf([1 -1], [1 3 2]))           % 1 : un zero instable
%      isempty(tzero(tf(1, [1 1])))         % vrai : aucun zero
%      abs(tzero(ss(-1, 1, -1, 1)) - 0) < 1e-9
%
%   Voir aussi ZERO, POLE, PZMAP, MINREAL.
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
