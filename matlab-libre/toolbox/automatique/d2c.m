function sysc = d2c(sys, methode)
%D2C Retour au continu d'un modèle échantillonné.
%   SYSC = D2C(SYSD) rend le modèle continu dont la discrétisation par
%   bloqueur d'ordre zéro redonne SYSD. C'est l'opération inverse de C2D,
%   au bruit numérique près.
%
%   SYSC = D2C(SYSD,'tustin') emploie la transformation bilinéaire, et
%   inverse alors exactement ce que C2D(...,'tustin') a fait.
%
%   La méthode doit être celle qui a servi à discrétiser : les deux
%   transformations ne donnent pas le même modèle continu, et les mélanger
%   ne rend rien de sensé.
%
%   Le retour par bloqueur passe par le logarithme de matrice, qui n'est
%   pas toujours réel : un système discret dont un pôle est réel négatif
%   n'a pas d'équivalent continu réel. La partie imaginaire est alors
%   écartée, et le modèle rendu n'est plus un inverse exact — c'est une
%   limite de l'opération, non du calcul.
%
%   Exemples :
%      d = c2d(tf(1, [1 1]), 0.05);
%      c = d2c(d);
%      abs(dcgain(c) - 1) < 1e-6            % le gain statique est rendu
%
%      d = c2d(tf(1, [1 2 1]), 0.05, 'tustin');
%      pole(d2c(d, 'tustin'))               % -1 et -1, les poles d'origine
%
%   Voir aussi C2D, D2D, SS, TF.
    if nargin < 2
        methode = 'zoh';
    end
    s = ss(sys);
    Ts = s.Ts;
    if Ts <= 0
        error('Control:d2c:ContinuDeja', ...
              'D2C attend un modele echantillonne : son Ts doit etre positif.');
    end
    n = size(s.A, 1);
    I = eye(n);
    switch lower(char(methode))
        case 'tustin'
            % L'inverse exact de la bilinéaire de C2D : de
            % Ad = (I - A Ts/2) \ (I + A Ts/2) on tire
            % A = (2/Ts) (Ad - I) (Ad + I)^-1, et le reste suit.
            somme = s.A + I;
            A = 2 / Ts * ((s.A - I) / somme);
            B = 2 / Ts * (somme \ s.B);
            % Cd = C M^-1 avec M^-1 = (Ad + I)/2, donc C = 2 Cd (Ad + I)^-1 :
            % c'est l'inverse, non la même expression.
            C = 2 * (s.C / somme);
            % Le terme direct s'ôte avec le C discret, non le continu :
            % c'est lui qui apparaît dans la formule de C2D.
            D = s.D - s.C * B * Ts / 2;
        otherwise
            A = logm(s.A) / Ts;
            if rank(A) == n
                B = (expm(A * Ts) - I) \ A * s.B;
            else
                B = s.B / Ts;
            end
            C = s.C;
            D = s.D;
    end
    sysc = ss(real(A), real(B), real(C), real(D), 0);
end
