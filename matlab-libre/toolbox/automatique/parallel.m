function sys = parallel(sys1, sys2)
%PARALLEL Mise en parallèle de deux modèles.
%   SYS = PARALLEL(SYS1,SYS2) fait entrer le même signal dans les deux
%   modèles et somme leurs sorties : c'est SYS1 + SYS2. À ne pas
%   confondre avec APPEND, qui les juxtapose sans rien relier.
%
%   Exemple :
%      parallel(tf(1, [1 1]), tf(1, [1 2]))
%
%   Voir aussi SERIES, FEEDBACK, APPEND.
    if matlibre_est_siso_tf(sys1) && matlibre_est_siso_tf(sys2)
        a = tf(sys1);
        b = tf(sys2);
        num = polyadd(conv(a.num, b.den), conv(b.num, a.den));
        sys = tf(num, conv(a.den, b.den), max(a.Ts, b.Ts));
        return
    end
    sys = ss(sys1) + ss(sys2);
end

function s = polyadd(p, q)
    n = max(numel(p), numel(q));
    p = [zeros(1, n - numel(p)), p];
    q = [zeros(1, n - numel(q)), q];
    s = p + q;
end
