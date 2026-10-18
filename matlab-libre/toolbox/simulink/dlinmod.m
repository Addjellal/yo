function [a, b, c, d] = dlinmod(modele, Ts, x, u, para)
%DLINMOD Linéarise un modèle et l'échantillonne à la période TS.
%   [A,B,C,D] = DLINMOD(MODELE,TS) linéarise le modèle comme LINMOD, puis
%   discrétise le résultat par bloqueur d'ordre zéro : l'entrée est tenue
%   constante entre deux instants d'échantillonnage.
%   [A,B,C,D] = DLINMOD(MODELE,TS,X,U) choisit le point de
%   fonctionnement ; PARA joue le même rôle que dans LINMOD.
%   SYS = DLINMOD(...) rend la structure à champs a, b, c, d.
%
%   La discrétisation est exacte, non approchée : Ad et Bd sortent d'une
%   seule exponentielle de matrice, celle de [A B ; 0 0]*TS, dont le bloc
%   supérieur droit vaut l'intégrale de exp(A t) B — ce qui évite d'avoir
%   à inverser A, qui est souvent singulière.
%
%   TS nul rend la linéarisation continue elle-même, comme dans MATLAB.
%
%   Les états discrets — Unit Delay et Delay, Discrete-Time Integrator,
%   Discrete Transfer Fcn, Discrete Filter, Discrete Zero-Pole, Discrete
%   State-Space — tournant à la période TS se linéarisent par leur mise à
%   jour : l'état X du modèle échantillonné porte les états continus, puis
%   les discrets, et la partie continue s'échantillonne par bloqueur
%   d'ordre zéro, les états discrets et les entrées tenus entre deux
%   instants. X donne alors les deux sortes d'états, ou les seuls états
%   continus. Un bloc discret d'une autre période est refusé : MatLibre ne
%   le rééchantillonne pas.
%
%   Exemple :
%      m = new_system('premier');
%      m = add_block(m, 'inport', 'u', 'Port', 1);
%      m = add_block(m, 'sum', 's', 'Signs', '+-');
%      m = add_block(m, 'integrator', 'x');
%      m = add_block(m, 'outport', 'y', 'Port', 1);
%      m = add_line(m, 'u', 's', 1);
%      m = add_line(m, 'x', 's', 2);
%      m = add_line(m, 's', 'x');
%      m = add_line(m, 'x', 'y');
%      [Ad, Bd] = dlinmod(m, 0.5);
%      abs(Ad - exp(-0.5)) < 1e-12          % le pole continu -1
%
%   Voir aussi LINMOD, TRIM, C2D, SIM.
    if nargin < 3, x = []; end
    if nargin < 4, u = []; end
    if nargin < 5, para = []; end
    if ~isempty(Ts) && (~isscalar(Ts) || ~isreal(Ts) || ~(Ts >= 0) || isinf(Ts))
        error('Simulink:Commands:DlinmodPeriode', ...
              'La periode d''echantillonnage doit etre un nombre positif.');
    end
    if ~isempty(Ts) && Ts > 0
        [~, ~, entrees, ~, T] = matlibre_sl_etats(modele);
        discrets = blocsDiscrets(T, Ts);
        if ~isempty(discrets)
            [a, b, c, d] = hybride(T, entrees, discrets, Ts, x, u, para);
            [a, b, c, d] = rendre(a, b, c, d, nargout);
            return
        end
    end
    [ac, bc, cc, dc] = linmod(modele, x, u, para);
    if isempty(Ts) || Ts == 0
        [a, b, c, d] = rendre(ac, bc, cc, dc, nargout);
        return
    end
    n = size(ac, 1);
    m = size(bc, 2);
    if n == 0
        [a, b, c, d] = rendre(ac, bc, cc, dc, nargout);
        return
    end
    bloc = [ac, bc; zeros(m, n + m)] * Ts;
    exponentielle = expm(bloc);
    ad = exponentielle(1:n, 1:n);
    bd = exponentielle(1:n, n+1:n+m);
    [a, b, c, d] = rendre(ad, bd, cc, dc, nargout);
end

% Les blocs dont les états discrets se linéarisent, à la période TS.
function discrets = blocsDiscrets(T, Ts)
    discrets = [];
    for k = find(T.zN > 0)
        w = T.oB(k) - T.oA(k) + 1;
        switch T.code(k)
            case 80   % delay
                if T.retardAvance(k)
                    error('Simulink:Commands:DlinmodBloc', ...
                          ['Le retard ''%s'' s''active, se remet ou lit sa condition initiale ' ...
                           'sur une entree : DLINMOD ne le linearise pas.'], T.chemins{k});
                end
            case 83   % discrete-time integrator
                if T.zN(k) ~= w
                    error('Simulink:Commands:DlinmodBloc', ...
                          ['L''integrateur discret ''%s'' se remet ou lit sa condition ' ...
                           'initiale sur une entree : DLINMOD ne le linearise pas.'], T.chemins{k});
                end
            case {84, 85, 86}   % transmittances et représentation d'état discrètes
            otherwise
                continue
        end
        if abs(T.periodes(k) - Ts) > 1e-9 * Ts
            error('Simulink:Commands:DlinmodPeriode', ...
                  ['Le bloc ''%s'' tourne a la periode %g, et DLINMOD echantillonne a %g : ' ...
                   'MatLibre ne reechantillonne pas un bloc discret.'], T.chemins{k}, ...
                  T.periodes(k), Ts);
        end
        discrets(end + 1) = k; %#ok<AGROW>
    end
end

% Les états discrets, rangés : ceux d'un retard du plus ancien au plus
% récent, quelle que soit la tête de son anneau.
function rangs = ordre(T, discrets, Z)
    rangs = [];
    for k = discrets
        z = T.zA(k);
        w = T.oB(k) - T.oA(k) + 1;
        if T.code(k) == 80
            L = T.P(T.pA(k));
            tete = Z(z);
            for s = 0:L - 1
                case_ = mod(tete - 1 + s, L);
                rangs = [rangs, z + 1 + case_ * w + (0:w - 1)]; %#ok<AGROW>
            end
        elseif T.code(k) == 83
            rangs = [rangs, z:z + w - 1]; %#ok<AGROW>
        else
            rangs = [rangs, z:z + T.zN(k) - 1]; %#ok<AGROW>
        end
    end
end

% La linéarisation hybride : dérivées, mises à jour et sorties, par
% différences centrées en les états continus, les états discrets et les
% entrées ; puis la partie continue échantillonnée par bloqueur d'ordre
% zéro.
function [a, b, c, d] = hybride(T, entrees, discrets, Ts, x, u, para)
    perturbation = 1e-5;
    if numel(para) >= 3 && para(3) > 0
        perturbation = para(3);
    end
    nc = numel(T.x0);
    nu = 0;
    for k = entrees
        nu = nu + T.oB(k) - T.oA(k) + 1;
    end
    Z0 = T.Z0(:);
    rangs0 = ordre(T, discrets, Z0);
    nd = numel(rangs0);
    zd = Z0(rangs0);
    if isempty(x)
        x = T.x0(:);
    end
    x = x(:);
    if numel(x) == nc + nd
        zd = x(nc + 1:end);
        x = x(1:nc);
    elseif numel(x) ~= nc
        error('Simulink:Commands:LinmodEtat', ...
              'Le modele porte %d etats continus et %d discrets ; X en donne %d.', nc, nd, ...
              numel(x));
    end
    if isempty(u)
        u = zeros(nu, 1);
    end
    u = u(:);
    if numel(u) ~= nu
        error('Simulink:Commands:LinmodEntree', ...
              'Le modele porte %d entrees ; U en donne %d.', nu, numel(u));
    end
    point0 = [x; zd; u];
    f0 = evaluer(T, discrets, Z0, rangs0, point0, nc, nd);
    J = zeros(numel(f0), numel(point0));
    for i = 1:numel(point0)
        h = perturbation * max(1, abs(point0(i)));
        plus = point0;
        plus(i) = plus(i) + h;
        moins = point0;
        moins(i) = moins(i) - h;
        J(:, i) = (evaluer(T, discrets, Z0, rangs0, plus, nc, nd) - ...
                   evaluer(T, discrets, Z0, rangs0, moins, nc, nd)) / (2 * h);
    end
    lc = 1:nc;
    ld = nc + 1:nc + nd;
    ly = nc + nd + 1:size(J, 1);
    cu = nc + nd + 1:nc + nd + nu;
    M = expm([J(lc, :); zeros(nd + nu, nc + nd + nu)] * Ts);
    a = [M(lc, lc), M(lc, ld); J(ld, lc), J(ld, ld)];
    b = [M(lc, cu); J(ld, cu)];
    c = J(ly, [lc, ld]);
    d = J(ly, cu);
end

function f = evaluer(T, discrets, Z0, rangs0, point, nc, nd)
    Z = Z0;
    Z(rangs0) = point(nc + 1:nc + nd);
    [y, dx, Zn] = matlibre_sl_executer('pointHybride', T, point(1:nc), Z, point(nc + nd + 1:end));
    f = [dx(:); Zn(ordre(T, discrets, Zn)); y(:)];
end

function [a, b, c, d] = rendre(ad, bd, cd, dd, combien)
    if combien <= 1
        systeme = struct('a', ad, 'b', bd, 'c', cd, 'd', dd);
        a = systeme;
        b = [];
        c = [];
        d = [];
        return
    end
    a = ad;
    b = bd;
    c = cd;
    d = dd;
end
