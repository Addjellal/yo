function sys = feedback(direct, retour, signe)
%FEEDBACK Boucle fermée.
%   SYS = FEEDBACK(G,H) ferme la boucle sur une contre-réaction négative :
%   la sortie de G passe par H et se retranche de l'entrée. Pour un modèle
%   monovariable, c'est G/(1+GH).
%
%   SYS = FEEDBACK(G,H,+1) somme au lieu de retrancher : G/(1-GH).
%
%   SYS = FEEDBACK(G,1) referme la boucle sur un retour unitaire ; c'est
%   la forme la plus courante.
%
%   Les modèles à plusieurs entrées et sorties sont acceptés : le calcul
%   se fait alors dans l'espace d'état, avec la matrice I - S*D2*D1 qui
%   doit être inversible — sans quoi la boucle est algébrique, et le
%   message le dit.
%
%   Exemples :
%      T = feedback(tf(10, [1 1]), 1)          % 10/(s+11)
%      T = feedback(ss(-1,1,1,0), eye(1))      % en modèle d'état
%
%   Voir aussi SERIES, PARALLEL, LFT, APPEND, CONNECT.
    if nargin < 2 || isempty(retour)
        retour = 1;
    end
    if nargin < 3
        signe = -1;
    end
    signe = sign(signe);
    if signe == 0
        signe = -1;
    end
    % Deux transmittances monovariables restent des polynômes : le
    % résultat s'écrit et se lit comme dans un cours.
    if matlibre_est_siso_tf(direct) && matlibre_est_siso_tf(retour)
        g = tf(direct);
        h = tf(retour);
        num = conv(g.num, h.den);
        den = polyadd(conv(g.den, h.den), -signe * conv(g.num, h.num));
        sys = tf(num, den, max(g.Ts, h.Ts));
        return
    end

    g = ss(direct);
    h = ss(retour);
    [ny, nu] = size(g);
    if ~isequal(size(h), [nu, ny])
        error('Control:combination:FeedbackSize', ...
              ['In FEEDBACK(G,H), H must have as many inputs as G has outputs ' ...
               'and as many outputs as G has inputs.']);
    end
    boucle = eye(nu) - signe * h.D * g.D;
    if rcond(boucle) < eps
        error('Control:combination:AlgebraicLoop', ...
              'The feedback loop is algebraic : I - H.D*G.D is singular.');
    end
    F = inv(boucle);
    n1 = size(g.A, 1);
    n2 = size(h.A, 1);
    Cy = g.C + g.D * F * signe * h.D * g.C;
    Dy = g.D * F;
    A = [g.A + g.B * F * signe * h.D * g.C, g.B * F * signe * h.C; ...
         h.B * Cy,                          h.A + h.B * g.D * F * signe * h.C];
    B = [g.B * F; h.B * Dy];
    C = [Cy, g.D * F * signe * h.C];
    sys = ss(A, B, C, Dy, ss.periode(g, h));
end

function s = polyadd(p, q)
    n = max(numel(p), numel(q));
    p = [zeros(1, n - numel(p)), p];
    q = [zeros(1, n - numel(q)), q];
    s = p + q;
end
