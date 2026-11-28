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
    % Deux branches en parallele ne partagent leur retard que s'il est le
    % meme : sinon il faudrait le porter dans une seule des deux, ce
    % qu'un modele sans retard interne ne sait pas faire. On le dit,
    % plutot que d'en garder un et d'oublier l'autre.
    r1 = matlibre_retard_scalaire(sys1, 'PARALLEL');
    r2 = matlibre_retard_scalaire(sys2, 'PARALLEL');
    if r1 ~= r2
        error('Control:ltiobject:delayNotSupported', ...
              ['PARALLEL cannot connect in parallel two branches with ' ...
               'different delays (%g and %g): that would require an internal ' ...
               'delay. PADE gives a rational approximation, which ' ...
               'can be connected in parallel like any model.'], r1, r2);
    end
    if matlibre_est_siso_tf(sys1) && matlibre_est_siso_tf(sys2)
        a = tf(sys1);
        b = tf(sys2);
        num = polyadd(conv(a.num, b.den), conv(b.num, a.den));
        sys = tf(num, conv(a.den, b.den), max(a.Ts, b.Ts));
    else
        sys = ss(sys1) + ss(sys2);
        sys.InputDelay = 0;
        sys.OutputDelay = 0;
        sys.IODelay = 0;
    end
    sys.InputDelay = r1;
end

function s = polyadd(p, q)
    n = max(numel(p), numel(q));
    p = [zeros(1, n - numel(p)), p];
    q = [zeros(1, n - numel(q)), q];
    s = p + q;
end
