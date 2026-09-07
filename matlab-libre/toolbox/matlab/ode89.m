function [t, y] = ode89(f, intervalle, y0, options)
%ODE89 Intégration à très haute précision par extrapolation.
%   [T,Y] = ODE89(F,[T0 TF],Y0) intègre y' = F(t,y) de T0 à TF depuis Y0.
%   [T,Y] = ODE89(F,TSPAN,Y0) avec TSPAN de plus de deux éléments intègre
%   d'un instant au suivant et tombe exactement dessus : interpoler entre
%   les pas d'une méthode d'ordre huit coûterait toute la précision
%   qu'elle a gagnée.
%   [T,Y] = ODE89(...,OPTIONS) accepte les réglages d'ODESET : 'RelTol',
%   'AbsTol', 'MaxStep'.
%
%   MATLAB emploie ici une paire de Runge-Kutta d'ordre huit et neuf de
%   Verner. MatLibre emploie l'extrapolation de Gragg-Bulirsch-Stoer, qui
%   atteint la même précision par un chemin plus court à expliquer : on
%   avance sur un même pas avec un nombre croissant de sous-pas — deux,
%   quatre, six, huit —, et l'on extrapole le résultat vers un sous-pas
%   nul par le procédé d'Aitken-Neville.
%
%   Ce qui rend l'extrapolation possible est que l'erreur de la règle du
%   point milieu est une série en puissances paires du sous-pas : chaque
%   niveau d'extrapolation supprime le terme suivant, et l'ordre monte
%   deux par deux. Quatre niveaux suffisent à dépasser l'ordre huit.
%
%   Elle convient aux problèmes lisses et non raides, où l'on veut une
%   précision proche de celle de la machine. Sur un problème raide,
%   ODE15S reste le bon choix.
%
%   Exemple :
%      [t, y] = ode89(@(t, y) -y, [0 1], 1);
%      abs(y(end) - exp(-1)) < 1e-11
%      [t, y] = ode89(@(t, y) [y(2); -y(1)], [0 2*pi], [1; 0]);
%      abs(y(end, 1) - 1) < 1e-10           % le cercle se referme
%
%   Voir aussi ODE45, ODE113, ODE15S, ODESET, DEVAL.
    if nargin < 4, options = struct(); end
    relTol = matlibre_ode_option(options, 'RelTol', 1e-10);
    absTol = matlibre_ode_option(options, 'AbsTol', 1e-12);
    pasMax = matlibre_ode_option(options, 'MaxStep', Inf);

    intervalle = double(intervalle(:))';
    y0 = double(y0(:));
    if numel(intervalle) > 2
        % Des instants demandes : on integre d'un instant au suivant et
        % l'on tombe exactement dessus. Interpoler entre les pas d'une
        % methode d'ordre huit couterait toute la precision gagnee.
        t = intervalle(:);
        y = zeros(numel(t), numel(y0));
        y(1, :) = y0.';
        etat = y0;
        for k = 2:numel(intervalle)
            [~, morceau] = ode89(f, [intervalle(k - 1), intervalle(k)], etat, options);
            etat = morceau(end, :).';
            y(k, :) = etat.';
        end
        return
    end
    instants = [];
    t0 = intervalle(1);
    tf = intervalle(2);

    t = t0;
    y = y0.';
    tCourant = t0;
    yCourant = y0;
    h = min((tf - t0) / 100, pasMax);
    if h == 0
        return
    end
    while tCourant < tf - eps(tf)
        h = min([h, tf - tCourant, pasMax]);
        [yNeuf, erreur] = matlibre_gbs_pas(f, tCourant, yCourant, h);
        tolerance = absTol + relTol * max(abs(yCourant), abs(yNeuf));
        rapport = max(erreur ./ max(tolerance, realmin));
        if rapport <= 1 || h <= 16 * eps(tCourant)
            tCourant = tCourant + h;
            yCourant = yNeuf;
            t(end + 1, 1) = tCourant;      %#ok<AGROW>
            y(end + 1, :) = yCourant.';    %#ok<AGROW>
            % Le pas suivant : l'ordre effectif est huit, d'ou la racine
            % neuvieme du rapport.
            h = h * min(4, max(0.2, 0.9 * rapport ^ (-1 / 9)));
        else
            h = h * max(0.1, 0.9 * rapport ^ (-1 / 9));
        end
        if numel(t) > 1e6
            error('MATLAB:ode89:TooManySteps', ...
                  'Trop de pas : le probleme est peut-etre raide.');
        end
    end
end
