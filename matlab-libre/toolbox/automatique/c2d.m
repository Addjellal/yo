function sysd = c2d(sys, Ts, methode)
%C2D Discrétisation d'un modèle continu.
%   SYSD = C2D(SYS,TS) échantillonne le modèle à la période TS par
%   bloqueur d'ordre zéro : l'entrée est supposée constante entre deux
%   instants, ce qui est le cas derrière un convertisseur numérique.
%
%   SYSD = C2D(SYS,TS,'tustin') emploie la transformation bilinéaire, qui
%   conserve mieux la réponse fréquentielle près de la fréquence de
%   Nyquist, au prix d'une légère distorsion.
%
%   SYSD = C2D(SYS,TS,'foh') suppose l'entrée linéaire entre deux instants
%   (bloqueur triangulaire) : la réponse à une rampe échantillonnée est
%   exacte. SYSD = C2D(SYS,TS,'impulse') rend un modèle dont la réponse
%   impulsionnelle vaut TS fois celle du modèle continu aux instants
%   d'échantillonnage.
%
%   Le bloqueur d'ordre zéro et le triangulaire se calculent par
%   l'exponentielle d'une matrice augmentée, exacte même quand A est
%   singulière — un intégrateur, le cas courant d'un asservissement.
%
%   Exemples :
%      d = c2d(tf(1, [1 1]), 0.1);
%      d.Ts                             % 0.1
%      abs(dcgain(d) - dcgain(tf(1, [1 1]))) < 1e-9    % le gain statique tient
%
%   Voir aussi D2C, D2D, TUSTIN, SS, TF.
    if nargin < 3
        methode = 'zoh';
    end
    s = ss(sys);
    n = size(s.A, 1);
    switch lower(char(methode))
        case 'tustin'
            I = eye(n);
            M = I - s.A * Ts / 2;
            Ad = M \ (I + s.A * Ts / 2);
            Bd = M \ (s.B * Ts);
            Cd = s.C / M;
            Dd = s.D + s.C * (M \ (s.B * Ts / 2));
        case 'zoh'
            % expm([A B; 0 0] Ts) = [Ad Bd; 0 I] : Bd = intégrale de
            % e^(A t) B sur une période, sans inverser A.
            m = size(s.B, 2);
            M = expm([s.A, s.B; zeros(m, n + m)] * Ts);
            Ad = M(1:n, 1:n);
            Bd = M(1:n, n + 1:n + m);
            Cd = s.C;
            Dd = s.D;
        case 'foh'
            % Le bloqueur triangulaire : x(k+1) = F x(k) + G1 u(k) +
            % G2 (u(k+1) - u(k)), que l'état x - G2 u rend causal.
            m = size(s.B, 2);
            M = expm([s.A, s.B, zeros(n, m); zeros(m, n + m), eye(m) / Ts; ...
                      zeros(m, n + 2 * m)] * Ts);
            F = M(1:n, 1:n);
            G1 = M(1:n, n + 1:n + m);
            G2 = M(1:n, n + m + 1:n + 2 * m);
            Ad = F;
            Bd = G1 + F * G2 - G2;
            Cd = s.C;
            Dd = s.D + s.C * G2;
        case 'impulse'
            % Réponse impulsionnelle Ts h(k Ts) : Ts C Ad^k B.
            Ad = expm(s.A * Ts);
            Bd = Ad * s.B;
            Cd = Ts * s.C;
            Dd = Ts * s.C * s.B;
        otherwise
            error('Control:transformation:C2DMethod', ...
                  ['Unsupported discretization method ''%s''. Valid methods are ' ...
                   '''zoh'', ''foh'', ''impulse'', and ''tustin''.'], char(methode));
    end
    % La discretisation ne touche qu'a la partie rationnelle : le retard
    % reste ce qu'il est, compte en secondes de part et d'autre. Le perdre
    % ici l'aurait fait disparaitre sans rien dire.
    sysd = matlibre_porter_retard(ss(Ad, Bd, Cd, Dd, Ts), sys);
end
