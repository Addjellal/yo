function varargout = matlibre_sl_executer(action, varargin)
%MATLIBRE_SL_EXECUTER Fait tourner un modèle compilé.
%   T = MATLIBRE_SL_EXECUTER('preparer',C) range le modèle C, compilé par
%   MATLIBRE_SL_COMPILER, en tableaux de nombres : ce que chaque pas lit
%   sans avoir rien à chercher.
%
%   J = MATLIBRE_SL_EXECUTER('simuler',T,INSTANTS,SOLVEUR) simule aux
%   INSTANTS, régulièrement espacés du pas de la compilation, avec le
%   solveur à pas fixe SOLVEUR : ode1 (Euler), ode2 (Heun), ode3
%   (Bogacki-Shampine), ode4 (Runge-Kutta) ou ode5 (Dormand-Prince). J
%   porte le relevé — une colonne par instant, une ligne par valeur
%   relevée, dans l'ordre de T.releves —, les états continus, et le rang
%   du dernier instant simulé, qu'un bloc Stop Simulation peut avancer.
%
%   [Y,DX] = MATLIBRE_SL_EXECUTER('point',T,X,U) évalue le modèle en un
%   point : états continus X, entrées U des blocs INPORT dans l'ordre de
%   leur paramètre Port. Y rend les sorties — ce qui arrive aux blocs
%   OUTPORT —, DX la dérivée des états. C'est ce que LINMOD et TRIM
%   perturbent.
%
%   Chaque pas se fait comme dans Simulink. Une passe de sortie d'abord,
%   où chaque bloc calcule sa sortie dans l'ordre que la compilation a
%   fixé ; une boucle algébrique y est résolue par la méthode de Newton,
%   son jacobien gardé d'un pas à l'autre. Puis les dérivées des états
%   continus, la mise à jour des états discrets, et l'intégration. Un
%   solveur d'ordre supérieur refait des passes de sortie en des points
%   intermédiaires du pas : ce sont les pas mineurs, où les blocs
%   échantillonnés, et ceux qui comparent leur entrée à celle du pas
%   précédent, gardent la valeur du pas majeur.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = add_block(new_system('m'), 'constant', 'c', 'Value', 2);
%      m = add_line(add_block(m, 'integrator', 'x'), 'c', 'x');
%      T = matlibre_sl_executer('preparer', matlibre_sl_compiler(m, ...
%                               struct('pas', 0.1, 'silencieux', true)));
%      J = matlibre_sl_executer('simuler', T, 0:0.1:1, 'ode1');
%      J.etats(end)                           % 2 : l'intégrale de 2 sur 1 s
%
%   Voir aussi SIM, MATLIBRE_SL_COMPILER, LINMOD.
    switch action
        case 'preparer'
            varargout{1} = preparer(varargin{1});
        case 'simuler'
            varargout{1} = simuler(varargin{:});
        case 'point'
            [y, dx] = point(varargin{:});
            varargout{1} = y;
            varargout{2} = dx;
        case 'tableau'
            [varargout{1}, varargout{2}, varargout{3}] = tableau(varargin{1});
        otherwise
            error('Simulink:Engine:Action', 'Action inconnue : %s.', char(action));
    end
end

% === préparation ===============================================================

function T = preparer(c)
    n = c.n;
    T = struct();
    T.n = n;
    T.nom = c.nom;
    T.chemins = c.chemins;
    T.noms = c.noms;
    T.types = c.types;
    T.code = c.code;
    T.fam = floor(c.code / 10);
    T.direct = c.direct;
    T.sub = c.sub;
    T.nIn = c.nIn;
    T.nOut = c.nOut;
    T.oA = c.oA;
    T.oB = c.oB;
    T.poA = c.vA;
    T.poB = c.vB;
    T.pd = c.portDebut;

    % Les entrées : pour l'entrée j du bloc k, la plage V(eA(eD(k)+j) :
    % eB(eD(k)+j)). Une entrée en l'air lit V(1), la masse, qui vaut zéro.
    % Une case de plus, sur la masse, sert au bloc sans entrée qui vient
    % en dernier : il peut lire sa « première entrée » sans sortir du
    % tableau.
    total = sum(c.nIn);
    T.eD = zeros(1, n);
    T.eA = ones(1, total + 1);
    T.eB = ones(1, total + 1);
    pos = 0;
    for k = 1:n
        T.eD(k) = pos;
        for j = 1:c.nIn(k)
            T.eA(pos + j) = c.inA{k}(j);
            T.eB(pos + j) = c.inB{k}(j);
        end
        pos = pos + c.nIn(k);
    end

    % Les paramètres, bout à bout ; pA(k) est le début du segment du bloc.
    T.pA = zeros(1, n);
    T.P = zeros(0, 1);
    for k = 1:n
        T.pA(k) = numel(T.P) + 1;
        T.P = [T.P; c.seg{k}];
    end
    % Les états discrets, bout à bout ; Z(1) est la demande d'arrêt.
    T.zA = zeros(1, n);
    T.Z0 = 0;
    for k = 1:n
        T.zA(k) = numel(T.Z0) + 1;
        T.Z0 = [T.Z0; c.z0{k}];
    end
    T.x0 = c.x0;
    T.xA = c.xA;
    T.xB = c.xB;
    T.V0 = zeros(c.nV, 1);
    T.h = c.pas;
    T.tDebut = c.tDebut;
    T.fixe = true;

    % Le mode de chaque bloc : 0 calculé à chaque passe, 1 aux seuls pas
    % majeurs, 2 aux instants de sa période, 3 une fois pour toutes.
    T.mode = zeros(1, n);
    T.grp = zeros(1, n);
    T.groupes = zeros(0, 2);
    for k = 1:n
        cadence = c.cadence(k);
        if isinf(cadence)
            T.mode(k) = 3;
        elseif cadence > 0
            T.mode(k) = 2;
            cle = [c.periodePas(k), c.decalagePas(k)];
            g = find(T.groupes(:, 1) == cle(1) & T.groupes(:, 2) == cle(2), 1);
            if isempty(g)
                T.groupes(end + 1, :) = cle;
                g = size(T.groupes, 1);
            end
            T.grp(k) = g;
        elseif c.majeurSeul(k)
            T.mode(k) = 1;
        end
    end

    % Les boucles algébriques : les inconnues, le bloc qui porte chacune,
    % et la place de leur jacobien dans Z.
    T.boucles = struct('ordre', {}, 'z', {}, 'zBloc', {}, 'blocs', {}, 'jA', {});
    for b = 1:numel(c.boucles)
        B = c.boucles{b};
        zBloc = zeros(numel(B.z), 1);
        for d = B.dechires
            for q = 1:c.nOut(d)
                gp = c.portDebut(d) + q - 1;
                zBloc(ismember(B.z(:), c.vA(gp):c.vB(gp))) = d;
            end
        end
        nz = numel(B.z);
        T.boucles(b).ordre = B.ordre;
        T.boucles(b).z = B.z(:);
        T.boucles(b).zBloc = zBloc;
        T.boucles(b).blocs = B.blocs;
        T.boucles(b).jA = numel(T.Z0) + 1;
        T.Z0 = [T.Z0; 0; zeros(nz * nz, 1)];
    end

    % Les listes de calcul. Les blocs qui ne calculent rien — ceux qui ne
    % font que recevoir un signal, et la masse — n'y sont pas.
    rien = ismember(c.types, {'outport', 'scope', 'display', 'toworkspace', ...
                              'terminator', 'goto', 'ground'});
    liste = [];
    numero = 0;
    for e = 1:numel(c.etapes)
        etape = c.etapes{e};
        if isstruct(etape)
            numero = numero + 1;
            liste = [liste, -numero]; %#ok<AGROW>
        else
            liste = [liste, etape(~rien(etape))]; %#ok<AGROW>
        end
    end
    for b = 1:numel(T.boucles)
        o = T.boucles(b).ordre;
        T.boucles(b).ordre = o(~rien(o));
    end
    T.listeTout = liste;
    garde = true(size(liste));
    mineure = true(size(liste));
    for q = 1:numel(liste)
        if liste(q) > 0
            garde(q) = T.mode(liste(q)) ~= 3;
            mineure(q) = T.mode(liste(q)) == 0;
        end
    end
    T.listeMajeure = liste(garde);
    T.listeMineure = liste(mineure);

    % Les blocs dont un état avance à chaque pas majeur, ou à chaque
    % instant de leur période.
    T.aMettreAJour = [];
    for k = 1:n
        switch c.types{k}
            case {'relay', 'ratelimiter', 'hitcrossing', 'backlash', 'detectchange', ...
                  'detectincrease', 'detectdecrease', 'derivative', 'memory', ...
                  'discreteintegrator', 'discretetransferfcn', 'discretefilter', ...
                  'discretestatespace', 'randomnumber', 'uniformrandomnumber'}
                T.aMettreAJour(end + 1) = k;
            case 'delay'
                if c.seg{k}(1) > 0
                    T.aMettreAJour(end + 1) = k;
                end
            case 'transportdelay'
                if c.seg{k}(1) > 0
                    T.aMettreAJour(end + 1) = k;
                end
        end
    end
    T.continus = find(c.xA > 0);
    T.bornes = [];
    for k = find(strcmp(c.types, 'integrator'))
        if c.seg{k}(1) ~= 0
            T.bornes(end + 1) = k;
        end
    end

    % Le relevé : pour chaque port de sortie, sa valeur ; pour un bloc
    % sans sortie, ce qui arrive à ses entrées.
    T.journal = zeros(0, 1);
    T.releves = struct('bloc', {}, 'port', {}, 'entree', {}, 'dims', {}, 'lignes', {});
    for k = 1:n
        if c.nOut(k) >= 1
            for q = 1:c.nOut(k)
                gp = c.portDebut(k) + q - 1;
                T = releve(T, k, q, false, c.dims{gp}, (c.vA(gp):c.vB(gp)).');
            end
        else
            for j = 1:c.nIn(k)
                T = releve(T, k, j, true, c.inDims{k}{j}, (c.inA{k}(j):c.inB{k}(j)).');
            end
        end
    end

    % Les bornes du modèle, pour LINMOD : les INPORT et les OUTPORT dans
    % l'ordre de leur paramètre Port.
    T.entreesModele = parPort(c, 'inport');
    T.sortiesModele = zeros(0, 1);
    for k = parPort(c, 'outport')
        T.sortiesModele = [T.sortiesModele; (c.inA{k}(1):c.inB{k}(1)).'];
    end
end

function T = releve(T, k, port, entree, dims, indices)
    debut = numel(T.journal);
    T.journal = [T.journal; indices];
    T.releves(end + 1) = struct('bloc', k, 'port', port, 'entree', entree, ...
                                'dims', dims, 'lignes', debut + (1:numel(indices)));
end

function blocs = parPort(c, type)
    blocs = find(strcmp(c.types, type));
    rangs = zeros(size(blocs));
    for i = 1:numel(blocs)
        rangs(i) = double(c.p{blocs(i)}.Port);
    end
    [~, ordre] = sort(rangs);
    blocs = blocs(ordre);
end

% === solveurs ==================================================================
%
% Le tableau de Butcher de chaque solveur à pas fixe. Un solveur d'ordre
% p rend une erreur qui décroît comme le pas à la puissance p ; les
% coefficients sont ceux de la littérature — Heun, Bogacki et Shampine,
% Kutta, Dormand et Prince —, et c'est leur ordre que le test mesure.
function [A, b, c] = tableau(solveur)
    switch lower(solveur)
        case {'ode1', 'fixedstepdiscrete'}
            A = 0;
            b = 1;
            c = 0;
        case 'ode2'
            A = [0 0; 1 0];
            b = [1/2 1/2];
            c = [0 1];
        case 'ode3'
            A = [0 0 0; 1/2 0 0; 0 3/4 0];
            b = [2/9 1/3 4/9];
            c = [0 1/2 3/4];
        case 'ode4'
            A = [0 0 0 0; 1/2 0 0 0; 0 1/2 0 0; 0 0 1 0];
            b = [1/6 1/3 1/3 1/6];
            c = [0 1/2 1/2 1];
        case 'ode5'
            A = [0 0 0 0 0 0
                 1/5 0 0 0 0 0
                 3/40 9/40 0 0 0 0
                 44/45 -56/15 32/9 0 0 0
                 19372/6561 -25360/2187 64448/6561 -212/729 0 0
                 9017/3168 -355/33 46732/5247 49/176 -5103/18656 0];
            b = [35/384 0 500/1113 125/192 -2187/6784 11/84];
            c = [0 1/5 3/10 4/5 8/9 1];
        otherwise
            error('Simulink:Config:InvalidSolver', ...
                  'Le solveur a pas fixe ''%s'' est inconnu.', solveur);
    end
end

% === simulation ================================================================

function J = simuler(T, instants, solveur, reprise)
    [Aq, bq, cq] = tableau(solveur);
    nEtages = numel(bq);
    N = numel(instants);
    h = T.h;
    if nargin >= 4 && ~isempty(reprise)
        V = reprise.V;
        Z = reprise.Z;
        x = reprise.x;
        i0 = reprise.i0;
        avancerApres = reprise.avancer;
        premier = isfield(reprise, 'premier') && reprise.premier;
    else
        V = T.V0;
        Z = T.Z0;
        x = T.x0;
        i0 = 0;
        avancerApres = false;
        premier = true;
    end
    nx = numel(x);
    journal = T.journal;
    releveV = zeros(numel(journal), N);
    etats = zeros(nx, N);
    G = size(T.groupes, 1);
    periodes = T.groupes(:, 1);
    decalages = T.groupes(:, 2);
    touche = false(1, G);
    dernier = N;
    bornes = ~isempty(T.bornes);
    for r = 1:N
        t = instants(r);
        i = i0 + r - 1;
        for g = 1:G
            touche(g) = i >= decalages(g) && mod(i - decalages(g), periodes(g)) == 0;
        end
        if premier && r == 1
            [V, Z] = passe(T, T.listeTout, V, Z, x, t, i, true, touche);
        else
            [V, Z] = passe(T, T.listeMajeure, V, Z, x, t, i, true, touche);
        end
        releveV(:, r) = V(journal);
        etats(:, r) = x;
        if Z(1) ~= 0
            dernier = r;
            break
        end
        if r == N && ~avancerApres
            break
        end
        if nx > 0
            k1 = derivees(T, V, x);
            if ~all(isfinite(k1))
                deriveeInfinie(T, k1, t);
            end
        end
        Z = majs(T, V, Z, t, touche);
        if nx > 0
            if nEtages == 1
                x = x + h * k1;
            else
                K = zeros(nx, nEtages);
                K(:, 1) = k1;
                for s = 2:nEtages
                    xs = x + h * (K(:, 1:s - 1) * Aq(s, 1:s - 1).');
                    if bornes
                        xs = borner(T, xs);
                    end
                    [V, Z] = passe(T, T.listeMineure, V, Z, xs, t + cq(s) * h, i, false, ...
                                   touche);
                    K(:, s) = derivees(T, V, xs);
                end
                x = x + h * (K * bq.');
            end
            if bornes
                x = borner(T, x);
            end
        end
    end
    J = struct('releve', releveV(:, 1:dernier), 'etats', etats(:, 1:dernier), ...
               'dernier', dernier, 'arret', Z(1) ~= 0, 'V', V, 'Z', Z, 'x', x);
end

function deriveeInfinie(T, dx, t)
    for k = T.continus
        if ~all(isfinite(dx(T.xA(k):T.xB(k))))
            error('Simulink:Engine:DerivNotFinite', ...
                  ['La derivee de l''etat de ''%s'' n''est pas finie a t = %g : la ' ...
                   'simulation s''arrete. La solution a peut-etre une singularite ' ...
                   '(division par zero, entree infinie).'], T.chemins{k}, t);
        end
    end
end

% Les intégrateurs bornés : l'état reste dans ses bornes.
function x = borner(T, x)
    for k = T.bornes
        a = T.xA(k);
        b = T.xB(k);
        p = T.pA(k);
        w = b - a + 1;
        x(a:b) = min(max(x(a:b), T.P(p + 1 + w:p + 2 * w)), T.P(p + 1:p + w));
    end
end

% === un point ==================================================================

function [y, dx] = point(T, x, u)
    P = T.P;
    pos = 0;
    for k = T.entreesModele
        p = T.pA(k);
        w = T.oB(k) - T.oA(k) + 1;
        P(p:p + w - 1) = u(pos + 1:pos + w);
        pos = pos + w;
    end
    T.P = P;
    G = size(T.groupes, 1);
    touche = false(1, G);
    for g = 1:G
        touche(g) = T.groupes(g, 2) == 0;
    end
    [V, ~] = passe(T, T.listeTout, T.V0, T.Z0, x(:), T.tDebut, 0, true, touche);
    dx = derivees(T, V, x(:));
    y = V(T.sortiesModele);
end

% === la passe de sortie =======================================================
%
% Chaque bloc de la liste calcule sa sortie, dans l'ordre : ce qu'il lit
% est déjà calculé. Un nombre négatif dans la liste est une boucle
% algébrique, résolue là. MAJEUR dit si c'est un pas majeur ; TOUCHE,
% quels groupes de période tombent à cet instant.
function [V, Z] = passe(T, liste, V, Z, x, t, i, majeur, touche)
    code = T.code;
    fam = T.fam;
    mode = T.mode;
    grp = T.grp;
    oA = T.oA;
    oB = T.oB;
    eD = T.eD;
    eA = T.eA;
    eB = T.eB;
    pA = T.pA;
    zA = T.zA;
    sub = T.sub;
    for q = 1:numel(liste)
        k = liste(q);
        if k < 0
            [V, Z] = resoudreBoucle(T, -k, V, Z, x, t, i, majeur, touche);
            continue
        end
        m = mode(k);
        if m ~= 0
            if ~majeur
                continue
            end
            if m == 2 && ~touche(grp(k))
                continue
            end
        end
        a = oA(k);
        b = oB(k);
        p = pA(k);
        e = eD(k);
        switch fam(k)
            case 0
                switch code(k)
                    case 1   % constant
                        V(a:b) = T.P(p:p + b - a);
                    case 2   % step
                        if a == b
                            if t >= T.P(p)
                                V(a) = T.P(p + 2);
                            else
                                V(a) = T.P(p + 1);
                            end
                        else
                            w = b - a + 1;
                            y = T.P(p + w:p + 2 * w - 1);
                            apres = T.P(p + 2 * w:p + 3 * w - 1);
                            haut = t >= T.P(p:p + w - 1);
                            y(haut) = apres(haut);
                            V(a:b) = y;
                        end
                    case 3   % ramp
                        if a == b
                            if t < T.P(p + 1)
                                V(a) = T.P(p + 2);
                            else
                                V(a) = T.P(p) * (t - T.P(p + 1)) + T.P(p + 2);
                            end
                        else
                            w = b - a + 1;
                            debut = T.P(p + w:p + 2 * w - 1);
                            x0 = T.P(p + 2 * w:p + 3 * w - 1);
                            y = T.P(p:p + w - 1) .* (t - debut) + x0;
                            avant = t < debut;
                            y(avant) = x0(avant);
                            V(a:b) = y;
                        end
                    case 4   % sine
                        if a == b
                            V(a) = T.P(p) * sin(T.P(p + 1) * t + T.P(p + 2)) + T.P(p + 3);
                        else
                            w = b - a + 1;
                            V(a:b) = T.P(p:p + w - 1) .* sin(T.P(p + w:p + 2 * w - 1) * t + ...
                                     T.P(p + 2 * w:p + 3 * w - 1)) + T.P(p + 3 * w:p + 4 * w - 1);
                        end
                    case {5, 6}   % clock, digital clock
                        V(a) = t;
                    case 7   % pulse generator
                        w = b - a + 1;
                        amplitude = T.P(p:p + w - 1);
                        periode = T.P(p + w:p + 2 * w - 1);
                        largeur = T.P(p + 2 * w:p + 3 * w - 1);
                        retard = T.P(p + 3 * w:p + 4 * w - 1);
                        if sub(k) == 1
                            phase = t - retard;
                            nombre = floor(phase ./ periode + 1e-9);
                            dans = phase - nombre .* periode;
                            allume = phase >= -1e-9 * periode & ...
                                     dans < largeur / 100 .* periode - 1e-9 * periode;
                        else
                            rang = round((t - T.tDebut) / T.P(p + 4 * w));
                            allume = rang >= retard & mod(rang - retard, periode) < largeur;
                        end
                        V(a:b) = amplitude .* allume;
                    case 8   % ground
                        V(a:b) = 0;
                    case 9   % repeating sequence
                        nt = T.P(p);
                        tv = T.P(p + 1:p + nt);
                        yv = T.P(p + nt + 1:p + 2 * nt);
                        s = tv(1) + mod(t - tv(1), tv(nt) - tv(1));
                        j = 1;
                        while j < nt && tv(j + 1) <= s
                            j = j + 1;
                        end
                        if j >= nt
                            V(a) = yv(nt);
                        else
                            V(a) = yv(j) + (yv(j + 1) - yv(j)) * (s - tv(j)) / (tv(j + 1) - tv(j));
                        end
                end
            case 1
                switch code(k)
                    case {10, 11}   % random number, uniform random number
                        w = b - a + 1;
                        V(a:b) = Z(zA(k) + w:zA(k) + 2 * w - 1);
                    case 12   % inport
                        V(a:b) = T.P(p:p + b - a);
                    case 13   % from workspace
                        V(a:b) = lireEspace(T, p, Z(zA(k)), t);
                        Z(zA(k)) = rangEspace(T, p, Z(zA(k)), t);
                    case 14   % from
                        V(a:b) = V(eA(e + 1):eB(e + 1));
                end
            case 2
                u = V(eA(e + 1):eB(e + 1));
                switch code(k)
                    case 20   % gain
                        nK = T.P(p) * T.P(p + 1);
                        switch sub(k)
                            case 1
                                if nK == 1
                                    V(a:b) = T.P(p + 2) * u;
                                else
                                    V(a:b) = T.P(p + 2:p + 1 + nK) .* u;
                                end
                            case {2, 4}
                                if nK == 1
                                    V(a:b) = T.P(p + 2) * u;
                                else
                                    y = reshape(T.P(p + 2:p + 1 + nK), T.P(p), T.P(p + 1)) * u;
                                    V(a:b) = y;
                                end
                            otherwise
                                if nK == 1
                                    V(a:b) = T.P(p + 2) * u;
                                else
                                    y = u.' * reshape(T.P(p + 2:p + 1 + nK), T.P(p), T.P(p + 1));
                                    V(a:b) = y.';
                                end
                        end
                    case 21   % sum
                        nIn = T.P(p);
                        if nIn == 1
                            if T.P(p + 1) > 0
                                V(a) = sum(u);
                            else
                                V(a) = -sum(u);
                            end
                        else
                            if T.P(p + 1) > 0
                                y = u;
                            else
                                y = -u;
                            end
                            for j = 2:nIn
                                if T.P(p + j) > 0
                                    y = y + V(eA(e + j):eB(e + j));
                                else
                                    y = y - V(eA(e + j):eB(e + j));
                                end
                            end
                            V(a:b) = y;
                        end
                    case 22   % product
                        V(a:b) = produit(T, k, V, u, p, e);
                    case 23   % abs
                        V(a:b) = abs(u);
                    case 24   % sign
                        V(a:b) = sign(u);
                    case 25   % math function
                        V = fonctionMath(T, k, V, u, p, e, a, b);
                    case 26   % trigonometry
                        V = trigonometrie(T, k, V, u, e, a, b);
                    case 27   % minmax
                        nIn = T.P(p);
                        if nIn == 1
                            if sub(k) == 1
                                V(a) = min(u);
                            else
                                V(a) = max(u);
                            end
                        else
                            y = u;
                            for j = 2:nIn
                                if sub(k) == 1
                                    y = min(y, V(eA(e + j):eB(e + j)));
                                else
                                    y = max(y, V(eA(e + j):eB(e + j)));
                                end
                            end
                            V(a:b) = y;
                        end
                    case 28   % bias
                        V(a:b) = u + T.P(p:p + b - a);
                    case 29   % dot product
                        V(a) = sum(u .* V(eA(e + 2):eB(e + 2)));
                end
            case 3
                u = V(eA(e + 1):eB(e + 1));
                switch code(k)
                    case 30   % unary minus
                        V(a:b) = -u;
                    case 31   % rounding
                        switch sub(k)
                            case 1
                                V(a:b) = floor(u);
                            case 2
                                V(a:b) = ceil(u);
                            case 3
                                V(a:b) = round(u);
                            otherwise
                                V(a:b) = fix(u);
                        end
                    case 32   % polynomial
                        nc = T.P(p);
                        y = T.P(p + 1);
                        for j = 2:nc
                            y = y .* u + T.P(p + j);
                        end
                        V(a:b) = y;
                    case 33   % sqrt
                        switch sub(k)
                            case 1
                                V(a:b) = racine(u);
                            case 2
                                V(a:b) = sign(u) .* sqrt(abs(u));
                            otherwise
                                V(a:b) = 1 ./ racine(u);
                        end
                end
            case 4
                u = V(eA(e + 1):eB(e + 1));
                switch code(k)
                    case 40   % saturation
                        if a == b
                            if u > T.P(p)
                                V(a) = T.P(p);
                            elseif u < T.P(p + 1)
                                V(a) = T.P(p + 1);
                            else
                                V(a) = u;
                            end
                        else
                            w = b - a + 1;
                            V(a:b) = min(max(u, T.P(p + w:p + 2 * w - 1)), T.P(p:p + w - 1));
                        end
                    case 41   % dead zone
                        if a == b
                            if u > T.P(p)
                                V(a) = u - T.P(p);
                            elseif u < T.P(p + 1)
                                V(a) = u - T.P(p + 1);
                            else
                                V(a) = 0;
                            end
                        else
                            w = b - a + 1;
                            haut = T.P(p:p + w - 1);
                            bas = T.P(p + w:p + 2 * w - 1);
                            V(a:b) = (u > haut) .* (u - haut) + (u < bas) .* (u - bas);
                        end
                    case 42   % relay
                        w = b - a + 1;
                        etat = modeRelais(T, p, w, u, Z(zA(k):zA(k) + w - 1));
                        y = T.P(p + 3 * w:p + 4 * w - 1);
                        marche = T.P(p + 2 * w:p + 3 * w - 1);
                        y(etat == 1) = marche(etat == 1);
                        V(a:b) = y;
                    case 43   % quantizer
                        q = T.P(p:p + b - a);
                        V(a:b) = q .* round(u ./ q);
                    case 44   % rate limiter
                        V(a:b) = limiteurPente(T, p, zA(k), Z, u, t, b - a + 1);
                    case 45   % hit crossing
                        w = b - a + 1;
                        ecart = u - T.P(p:p + w - 1);
                        z = zA(k);
                        if Z(z) == 0
                            V(a:b) = double(ecart == 0);
                        else
                            avant = Z(z + 1:z + w);
                            montee = avant < 0 & ecart >= 0;
                            descente = avant > 0 & ecart <= 0;
                            switch sub(k)
                                case 1
                                    V(a:b) = double(montee);
                                case 2
                                    V(a:b) = double(descente);
                                otherwise
                                    V(a:b) = double(montee | descente);
                            end
                        end
                    case 46   % backlash
                        w = b - a + 1;
                        y = Z(zA(k):zA(k) + w - 1);
                        demi = T.P(p:p + w - 1) / 2;
                        monte = u > y + demi;
                        descend = u < y - demi;
                        u = u + zeros(w, 1);
                        y(monte) = u(monte) - demi(monte);
                        y(descend) = u(descend) + demi(descend);
                        V(a:b) = y;
                    case 47   % coulomb and viscous friction
                        w = b - a + 1;
                        V(a:b) = sign(u) .* (T.P(p + w:p + 2 * w - 1) .* abs(u) + T.P(p:p + w - 1));
                    case 48   % 1-D lookup table
                        V(a:b) = table1(T, p, u);
                    case 49   % 2-D lookup table
                        V(a:b) = table2(T, p, u, V(eA(e + 2):eB(e + 2)));
                end
            case 5
                u = V(eA(e + 1):eB(e + 1));
                switch code(k)
                    case 50   % logic
                        V(a:b) = logique(T, k, V, u, p, e);
                    case 51   % relational
                        V(a:b) = comparer(sub(k), u, V(eA(e + 2):eB(e + 2)));
                    case 52   % compare to constant
                        V(a:b) = comparer(sub(k), u, T.P(p:p + b - a));
                    case 53   % compare to zero
                        V(a:b) = comparer(sub(k), u, 0);
                    case 54   % detect change
                        V(a:b) = double(u ~= Z(zA(k):zA(k) + b - a));
                    case 55   % detect increase
                        V(a:b) = double(u > Z(zA(k):zA(k) + b - a));
                    case 56   % detect decrease
                        V(a:b) = double(u < Z(zA(k):zA(k) + b - a));
                end
            case 6
                switch code(k)
                    case 60   % switch
                        u2 = V(eA(e + 2):eB(e + 2));
                        seuil = T.P(p + 1:p + T.P(p));
                        switch sub(k)
                            case 1
                                passe1 = u2 >= seuil;
                            case 2
                                passe1 = u2 > seuil;
                            otherwise
                                passe1 = u2 ~= 0;
                        end
                        if numel(passe1) == 1
                            if passe1
                                V(a:b) = V(eA(e + 1):eB(e + 1));
                            else
                                V(a:b) = V(eA(e + 3):eB(e + 3));
                            end
                        else
                            w = b - a + 1;
                            y = V(eA(e + 3):eB(e + 3)) + zeros(w, 1);
                            y1 = V(eA(e + 1):eB(e + 1)) + zeros(w, 1);
                            y(passe1) = y1(passe1);
                            V(a:b) = y;
                        end
                    case 61   % multiport switch
                        commande = V(eA(e + 1));
                        rang = fix(commande) + T.P(p + 1);
                        if ~(rang >= 1 && rang <= T.P(p))
                            if T.P(p + 1)
                                base = 'a partir de zero';
                            else
                                base = 'a partir de un';
                            end
                            error('Simulink:blocks:MultiPortSwitchIndexOutOfRange', ...
                                  ['L''entree de commande de ''%s'' vaut %g a t = %g : elle ' ...
                                   'doit designer l''une de ses %d entrees de donnees, ' ...
                                   'numerotees %s.'], T.chemins{k}, commande, t, T.P(p), base);
                        end
                        V(a:b) = V(eA(e + 1 + rang):eB(e + 1 + rang));
                    case {62, 65}   % mux, concatenate
                        if code(k) == 65 && sub(k) == 2
                            V(a:b) = concatener(T, p, V, e);
                        else
                            pos = a;
                            for j = 1:T.nIn(k)
                                ra = eA(e + j);
                                rb = eB(e + j);
                                V(pos:pos + rb - ra) = V(ra:rb);
                                pos = pos + rb - ra + 1;
                            end
                        end
                    case 63   % demux
                        ra = eA(e + 1) - 1;
                        pd = T.pd(k);
                        for j = 1:T.nOut(k)
                            V(T.poA(pd + j - 1):T.poB(pd + j - 1)) = ...
                                V(ra + T.P(p + 2 * j - 2):ra + T.P(p + 2 * j - 1));
                        end
                    case 64   % selector
                        V(a:b) = V(eA(e + 1) - 1 + T.P(p + 1:p + T.P(p)));
                    case 66   % reshape
                        V(a:b) = V(eA(e + 1):eB(e + 1));
                    case 68   % signal conversion
                        pd = T.pd(k);
                        for j = 1:T.P(p)
                            V(T.poA(pd + j - 1):T.poB(pd + j - 1)) = V(eA(e + j):eB(e + j));
                        end
                end
            case 7
                switch code(k)
                    case 70   % integrator
                        if T.P(p) == 0
                            V(a:b) = x(T.xA(k):T.xB(k));
                        else
                            w = b - a + 1;
                            V(a:b) = min(max(x(T.xA(k):T.xB(k)), T.P(p + 1 + w:p + 2 * w)), ...
                                         T.P(p + 1:p + w));
                        end
                    case 71   % derivative
                        z = zA(k);
                        if Z(z) == 0
                            V(a:b) = 0;
                        else
                            if T.fixe
                                dt = T.h;
                            else
                                dt = t - Z(z + 1);
                            end
                            V(a:b) = (V(eA(e + 1):eB(e + 1)) - Z(z + 2:z + 1 + b - a + 1)) / dt;
                        end
                    case {72, 73, 74}   % transfer fcn, state-space, zero-pole
                        % Sans transmission directe, l'entrée n'est pas encore
                        % calculée quand le bloc l'est : D est nul, on ne la
                        % lit pas.
                        if T.direct(k)
                            u = V(eA(e + 1):eB(e + 1));
                        else
                            u = 0;
                        end
                        V(a:b) = sortieEtat(T, p, x(T.xA(k):T.xB(k)), u);
                    case 75   % transport delay
                        if T.P(p) == 0
                            V(a:b) = V(eA(e + 1):eB(e + 1));
                        else
                            V(a:b) = retardPur(T, p, Z, zA(k), t, b - a + 1);
                        end
                    case 76   % PID controller
                        u = V(eA(e + 1):eB(e + 1));
                        xa = T.xA(k);
                        if a == b
                            V(a) = T.P(p) * u + T.P(p + 1) * x(xa) + ...
                                   T.P(p + 2) * T.P(p + 3) * (u - T.P(p + 3) * x(xa + 1));
                        else
                            w = b - a + 1;
                            N = T.P(p + 3 * w:p + 4 * w - 1);
                            V(a:b) = T.P(p:p + w - 1) .* u + T.P(p + w:p + 2 * w - 1) .* ...
                                     x(xa:xa + w - 1) + T.P(p + 2 * w:p + 3 * w - 1) .* N .* ...
                                     (u - N .* x(xa + w:xa + 2 * w - 1));
                        end
                end
            case 8
                switch code(k)
                    case 80   % delay
                        if T.P(p) == 0
                            V(a:b) = V(eA(e + 1):eB(e + 1));
                        else
                            w = b - a + 1;
                            debut = zA(k) + 1 + (Z(zA(k)) - 1) * w;
                            V(a:b) = Z(debut:debut + w - 1);
                        end
                    case 81   % memory
                        V(a:b) = Z(zA(k):zA(k) + b - a);
                    case 82   % zero-order hold
                        V(a:b) = V(eA(e + 1):eB(e + 1));
                    case 83   % discrete-time integrator
                        xk = Z(zA(k):zA(k) + b - a);
                        switch T.P(p + 1)
                            case 1
                                V(a:b) = xk;
                            case 2
                                V(a:b) = xk + T.P(p) * V(eA(e + 1):eB(e + 1));
                            otherwise
                                V(a:b) = xk + T.P(p) * V(eA(e + 1):eB(e + 1)) / 2;
                        end
                    case {84, 85}   % discrete transfer fcn, discrete filter
                        V(a) = sortieFiltre(T, p, Z, zA(k), V(eA(e + 1)));
                    case 86   % discrete state-space
                        nx = T.P(p);
                        if T.direct(k)
                            u = V(eA(e + 1):eB(e + 1));
                        else
                            u = 0;
                        end
                        V(a:b) = sortieEtat(T, p, Z(zA(k):zA(k) + nx - 1), u);
                end
            case 9
                switch code(k)
                    case 95   % stop simulation
                        if any(V(eA(e + 1):eB(e + 1)) ~= 0)
                            Z(1) = 1;
                        end
                    case 96   % assertion
                        if T.P(p) ~= 0 && majeur && any(V(eA(e + 1):eB(e + 1)) == 0)
                            if T.P(p + 1) ~= 0
                                error('Simulink:blocks:AssertionAssert', ...
                                      'Assertion detectee dans ''%s'' a t = %g.', ...
                                      T.chemins{k}, t);
                            end
                            warning('Simulink:blocks:AssertionAssert', ...
                                    'Assertion detectee dans ''%s'' a t = %g.', T.chemins{k}, t);
                        end
                end
        end
    end
end

% --- les calculs un peu longs, sortis de la passe pour qu'elle reste lisible

function y = racine(u)
    y = sqrt(abs(u));
    y(u < 0) = NaN;
end

function y = produit(T, k, V, u, p, e)
    nIn = T.P(p);
    ops = T.P(p + 1:p + nIn);
    if T.P(p + nIn + 1) == 0
        if nIn == 1
            if ops(1) > 0
                y = prod(u);
            else
                y = 1 / prod(u);
            end
            return
        end
        if ops(1) > 0
            y = u;
        else
            y = 1 ./ u;
        end
        for j = 2:nIn
            uj = V(T.eA(e + j):T.eB(e + j));
            if ops(j) > 0
                y = y .* uj;
            else
                y = y ./ uj;
            end
        end
        return
    end
    d = p + nIn + 2;
    y = [];
    for j = 1:nIn
        M = reshape(V(T.eA(e + j):T.eB(e + j)), T.P(d + 2 * j - 2), T.P(d + 2 * j - 1));
        if j == 1
            if ops(1) > 0
                y = M;
            else
                y = inv(M);
            end
        elseif ops(j) > 0
            y = y * M;
        else
            y = y / M;
        end
    end
    y = y(:);
    if ~all(isfinite(y)) && any(ops < 0)
        warning('Simulink:blocks:ProductSingularMatrix', ...
                'Le produit matriciel de ''%s'' inverse une matrice singuliere.', T.chemins{k});
    end
end

function V = fonctionMath(T, k, V, u, p, e, a, b)
    switch T.sub(k)
        case 1
            V(a:b) = exp(u);
        case 2
            y = log(abs(u));
            y(u < 0) = NaN;
            V(a:b) = y;
        case 3
            V(a:b) = 10 .^ u;
        case 4
            y = log10(abs(u));
            y(u < 0) = NaN;
            V(a:b) = y;
        case 5
            V(a:b) = u .* u;
        case 6
            V(a:b) = u .^ 2;
        case 7
            V(a:b) = racine(u);
        case 8
            u2 = V(T.eA(e + 2):T.eB(e + 2));
            y = u .^ u2;
            if ~isreal(y)
                imaginaire = imag(y) ~= 0;
                y = real(y);
                y(imaginaire) = NaN;
            end
            V(a:b) = y;
        case 9
            V(a:b) = u;
        case 10
            V(a:b) = 1 ./ u;
        case 11
            V(a:b) = hypot(u, V(T.eA(e + 2):T.eB(e + 2)));
        case 12
            V(a:b) = rem(u, V(T.eA(e + 2):T.eB(e + 2)));
        case 13
            V(a:b) = mod(u, V(T.eA(e + 2):T.eB(e + 2)));
        otherwise   % transpose, hermitian : des nombres réels, donc le même
            M = reshape(u, T.P(p), T.P(p + 1)).';
            V(a:b) = M(:);
    end
end

function V = trigonometrie(T, k, V, u, e, a, b)
    switch T.sub(k)
        case 1
            V(a:b) = sin(u);
        case 2
            V(a:b) = cos(u);
        case 3
            V(a:b) = tan(u);
        case 4
            y = asin(max(min(u, 1), -1));
            y(abs(u) > 1) = NaN;
            V(a:b) = y;
        case 5
            y = acos(max(min(u, 1), -1));
            y(abs(u) > 1) = NaN;
            V(a:b) = y;
        case 6
            V(a:b) = atan(u);
        case 7
            V(a:b) = atan2(u, V(T.eA(e + 2):T.eB(e + 2)));
        case 8
            V(a:b) = sinh(u);
        case 9
            V(a:b) = cosh(u);
        case 10
            V(a:b) = tanh(u);
        case 11
            V(a:b) = asinh(u);
        case 12
            y = acosh(max(u, 1));
            y(u < 1) = NaN;
            V(a:b) = y;
        case 13
            y = atanh(max(min(u, 1), -1));
            y(abs(u) > 1) = NaN;
            V(a:b) = y;
        otherwise   % sincos : deux sorties
            V(a:b) = sin(u);
            pd = T.pd(k);
            V(T.poA(pd + 1):T.poB(pd + 1)) = cos(u);
    end
end

function y = logique(T, k, V, u, p, e)
    operateur = T.sub(k);
    if operateur == 7
        y = double(u == 0);
        return
    end
    nIn = T.P(p);
    if nIn == 1
        bits = u ~= 0;
        switch operateur
            case {1, 3}
                r = all(bits);
            case {2, 4}
                r = any(bits);
            otherwise
                r = mod(sum(bits), 2) == 1;
        end
    else
        r = u ~= 0;
        for j = 2:nIn
            bits = V(T.eA(e + j):T.eB(e + j)) ~= 0;
            switch operateur
                case {1, 3}
                    r = r & bits;
                case {2, 4}
                    r = r | bits;
                otherwise
                    r = xor(r, bits);
            end
        end
    end
    if operateur == 3 || operateur == 4 || operateur == 6
        r = ~r;
    end
    y = double(r);
end

function y = comparer(operateur, u1, u2)
    switch operateur
        case 1
            y = double(u1 == u2);
        case 2
            y = double(u1 ~= u2);
        case 3
            y = double(u1 < u2);
        case 4
            y = double(u1 <= u2);
        case 5
            y = double(u1 >= u2);
        otherwise
            y = double(u1 > u2);
    end
end

% Le mode d'un relais après avoir vu son entrée : en marche au-dessus du
% seuil de marche, à l'arrêt au-dessous du seuil d'arrêt, inchangé entre
% les deux.
function etat = modeRelais(T, p, w, u, etat)
    u = u + zeros(w, 1);
    etat(u <= T.P(p + w:p + 2 * w - 1)) = 0;
    etat(u >= T.P(p:p + w - 1)) = 1;
end

function y = limiteurPente(T, p, z, Z, u, t, w)
    precedent = Z(z + 2:z + 1 + w);
    if Z(z) == 0 || T.fixe
        dt = T.h;
    else
        dt = t - Z(z + 1);
    end
    montee = T.P(p:p + w - 1);
    descente = T.P(p + w:p + 2 * w - 1);
    if w == 1
        pente = (u - precedent) / dt;
        if pente > montee
            y = precedent + dt * montee;
        elseif pente < descente
            y = precedent + dt * descente;
        else
            y = u;
        end
        return
    end
    u = u + zeros(w, 1);
    pente = (u - precedent) / dt;
    y = u;
    trop = pente > montee;
    y(trop) = precedent(trop) + dt * montee(trop);
    pasAssez = pente < descente;
    y(pasAssez) = precedent(pasAssez) + dt * descente(pasAssez);
end

% Table à une dimension : interpolation linéaire, ou valeur tenue, ou
% plus proche ; au-delà des bornes, tenue ou prolongée.
function y = table1(T, p, u)
    nb = T.P(p);
    xs = T.P(p + 3:p + 2 + nb);
    ys = T.P(p + 3 + nb:p + 2 + 2 * nb);
    switch T.P(p + 1)
        case 2
            methode = 'previous';
        case 3
            methode = 'nearest';
        otherwise
            methode = 'linear';
    end
    if T.P(p + 2) == 1 || ~strcmp(methode, 'linear')
        y = interp1(xs, ys, min(max(u, xs(1)), xs(nb)), methode);
    else
        y = interp1(xs, ys, u, 'linear', 'extrap');
    end
end

% Table à deux dimensions : interpolation bilinéaire, tenue aux bornes.
function y = table2(T, p, u1, u2)
    nr = T.P(p);
    ns = T.P(p + 1);
    r = T.P(p + 2:p + 1 + nr);
    s = T.P(p + 2 + nr:p + 1 + nr + ns);
    base = p + 2 + nr + ns;
    w = max(numel(u1), numel(u2));
    u1 = u1 + zeros(w, 1);
    u2 = u2 + zeros(w, 1);
    y = zeros(w, 1);
    for j = 1:w
        a = min(max(u1(j), r(1)), r(nr));
        b = min(max(u2(j), s(1)), s(ns));
        i1 = 1;
        while i1 < nr - 1 && r(i1 + 1) <= a
            i1 = i1 + 1;
        end
        j1 = 1;
        while j1 < ns - 1 && s(j1 + 1) <= b
            j1 = j1 + 1;
        end
        fa = (a - r(i1)) / (r(i1 + 1) - r(i1));
        fb = (b - s(j1)) / (s(j1 + 1) - s(j1));
        t11 = T.P(base + (j1 - 1) * nr + i1 - 1);
        t21 = T.P(base + (j1 - 1) * nr + i1);
        t12 = T.P(base + j1 * nr + i1 - 1);
        t22 = T.P(base + j1 * nr + i1);
        y(j) = (1 - fa) * (1 - fb) * t11 + fa * (1 - fb) * t21 + (1 - fa) * fb * t12 + ...
               fa * fb * t22;
    end
end

function y = concatener(T, p, V, e)
    dim = T.P(p);
    nIn = T.P(p + 1);
    d = p + 2;
    y = [];
    for j = 1:nIn
        M = reshape(V(T.eA(e + j):T.eB(e + j)), T.P(d + 2 * j - 2), T.P(d + 2 * j - 1));
        y = cat(dim, y, M);
    end
    y = y(:);
end

% Une représentation d'état : y = C x + D u. Le segment porte [nx; ny; nu;
% A; B; C; D], par colonnes.
function y = sortieEtat(T, p, xk, u)
    nx = T.P(p);
    ny = T.P(p + 1);
    nu = T.P(p + 2);
    iC = p + 3 + nx * nx + nx * nu;
    iD = iC + ny * nx;
    if numel(u) ~= nu
        u = u + zeros(nu, 1);
    end
    if ny == 1 && nu == 1
        if nx == 0
            y = T.P(iD) * u;
        else
            y = T.P(iC:iC + nx - 1).' * xk + T.P(iD) * u;
        end
        return
    end
    y = reshape(T.P(iD:iD + ny * nu - 1), ny, nu) * u;
    if nx > 0
        y = reshape(T.P(iC:iC + ny * nx - 1), ny, nx) * xk + y;
    end
end

function dx = deriveeEtat(T, p, xk, u)
    nx = T.P(p);
    nu = T.P(p + 2);
    iA = p + 3;
    iB = iA + nx * nx;
    if numel(u) ~= nu
        u = u + zeros(nu, 1);
    end
    if nu == 1
        dx = reshape(T.P(iA:iA + nx * nx - 1), nx, nx) * xk + T.P(iB:iB + nx - 1) * u;
    else
        dx = reshape(T.P(iA:iA + nx * nx - 1), nx, nx) * xk + ...
             reshape(T.P(iB:iB + nx * nu - 1), nx, nu) * u;
    end
end

% Un filtre discret en forme directe II : un seul jeu de valeurs retardées
% sert au numérateur et au dénominateur. Le segment porte [m; b; a].
function y = sortieFiltre(T, p, Z, z, u)
    m = T.P(p);
    b0 = T.P(p + 1);
    if m == 0
        y = b0 * u;
        return
    end
    s = Z(z:z + m - 1);
    ia = p + 2 + m;
    w = u - T.P(ia + 1:ia + m).' * s;
    if b0 ~= 0
        y = b0 * w + T.P(p + 2:p + 1 + m).' * s;
    else
        y = T.P(p + 2:p + 1 + m).' * s;
    end
end

% Le retard pur : le tampon garde les entrées des pas majeurs passés, la
% k-ième à l'instant tDebut + k h. On y lit l'instant t - retard, en
% interpolant entre les deux échantillons qui l'encadrent ; avant le
% premier, c'est la sortie initiale.
function y = retardPur(T, p, Z, z, t, w)
    retard = T.P(p);
    longueur = T.P(p + 1);
    nPousses = Z(z);
    q = (t - retard - T.tDebut) / T.h;
    qr = round(q);
    if abs(q - qr) < 1e-9
        q = qr;
    end
    if q < 0 || nPousses == 0
        y = T.P(p + 2:p + 1 + w);
        return
    end
    j0 = floor(q);
    f = q - j0;
    recent = nPousses - 1;
    if j0 >= recent
        y = echantillon(Z, z, recent, longueur, w);
        return
    end
    j0 = max(j0, nPousses - longueur);
    y = echantillon(Z, z, j0, longueur, w);
    if f > 0
        y = (1 - f) * y + f * echantillon(Z, z, j0 + 1, longueur, w);
    end
end

function v = echantillon(Z, z, j, longueur, w)
    debut = z + 1 + mod(j, longueur) * w;
    v = Z(debut:debut + w - 1);
end

% Un signal lu dans l'espace de travail : interpolé entre ses instants,
% ou tenu ; au-delà du dernier, nul, tenu ou prolongé selon le réglage.
% Le segment porte [n; w; interpole; apres; temps; valeurs par colonnes].
function y = lireEspace(T, p, j, t)
    j = rangEspace(T, p, j, t);
    n = T.P(p);
    w = T.P(p + 1);
    temps = p + 4;
    valeurs = p + 4 + n;
    colonnes = (0:w - 1).' * n;
    tj = T.P(temps + j - 1);
    if t <= T.P(temps) || n == 1
        y = T.P(valeurs + colonnes);
        return
    end
    if j >= n
        dernier = T.P(valeurs + n - 1 + colonnes);
        if t <= T.P(temps + n - 1)
            y = dernier;
            return
        end
        switch T.P(p + 3)
            case 0
                y = zeros(w, 1);
            case 1
                y = dernier;
            otherwise
                avant = T.P(valeurs + n - 2 + colonnes);
                y = dernier + (dernier - avant) * (t - T.P(temps + n - 1)) / ...
                    (T.P(temps + n - 1) - T.P(temps + n - 2));
        end
        return
    end
    vj = T.P(valeurs + j - 1 + colonnes);
    if T.P(p + 2) == 0
        y = vj;
        return
    end
    tSuivant = T.P(temps + j);
    vSuivant = T.P(valeurs + j + colonnes);
    y = vj + (vSuivant - vj) * ((t - tj) / (tSuivant - tj));
end

% Le rang du dernier instant donné qui ne dépasse pas t, cherché à partir
% de celui du pas précédent : le temps avance, la recherche est courte.
function j = rangEspace(T, p, j, t)
    n = T.P(p);
    temps = p + 4;
    while j < n && T.P(temps + j) <= t
        j = j + 1;
    end
    while j > 1 && T.P(temps + j - 1) > t
        j = j - 1;
    end
end

% === boucles algébriques =======================================================
%
% Les sorties des blocs qui coupent la boucle sont les inconnues z. On
% calcule la boucle à partir de z, les blocs coupés rendent g(z), et l'on
% cherche z = g(z) par la méthode de Newton. Le jacobien se mesure par
% différences finies et se garde d'un pas à l'autre : une boucle linéaire
% se résout alors en deux évaluations par pas.
function [V, Z] = resoudreBoucle(T, b, V, Z, x, t, i, majeur, touche)
    B = T.boucles(b);
    actif = true(numel(B.z), 1);
    for q = 1:numel(B.z)
        k = B.zBloc(q);
        m = T.mode(k);
        if m ~= 0
            actif(q) = majeur && (m ~= 2 || touche(T.grp(k)));
        end
    end
    if ~any(actif)
        [V, Z] = passe(T, B.ordre, V, Z, x, t, i, majeur, touche);
        return
    end
    indices = B.z(actif);
    nz = numel(indices);
    complet = all(actif);
    z = V(indices);
    [V, Z] = passe(T, B.ordre, V, Z, x, t, i, majeur, touche);
    g = V(indices);
    F = g - z;
    jA = B.jA;
    jacobienValide = complet && Z(jA) ~= 0;
    if jacobienValide
        J = reshape(Z(jA + 1:jA + nz * nz), nz, nz);
    else
        J = zeros(nz, nz);
    end
    neuf = false;
    converge = false;
    for iteration = 1:50
        if max(abs(F)) <= 1e-10 * max(1, max(abs(g)))
            converge = true;
            break
        end
        if ~all(isfinite(F))
            break
        end
        if ~jacobienValide
            for j = 1:nz
                zp = z;
                d = sqrt(eps) * max(1, abs(z(j)));
                zp(j) = zp(j) + d;
                V(indices) = zp;
                [V, Z] = passe(T, B.ordre, V, Z, x, t, i, majeur, touche);
                J(:, j) = ((V(indices) - zp) - F) / d;
            end
            jacobienValide = true;
            neuf = true;
            if ~all(isfinite(J(:))) || rcond(J) < 1e-14
                error('Simulink:Engine:AlgLoopSingular', ...
                      ['La boucle algebrique qui passe par %s n''a pas de solution unique ' ...
                       'a t = %g : sa matrice jacobienne est singuliere. Un gain de boucle ' ...
                       'egal a un, par exemple, la rend indeterminee. Ajoutez un bloc ' ...
                       'Memory ou Unit Delay pour la couper.'], ...
                      listeChemins(T, B.blocs), t);
            end
        end
        normeAvant = max(abs(F));
        z = z - J \ F;
        V(indices) = z;
        [V, Z] = passe(T, B.ordre, V, Z, x, t, i, majeur, touche);
        g = V(indices);
        F = g - z;
        if ~neuf && max(abs(F)) > 0.5 * normeAvant
            jacobienValide = false;   % le jacobien gardé ne vaut plus : on le refait
        end
        neuf = false;
    end
    if ~converge
        if ~all(isfinite(z)) || ~all(isfinite(F))
            error('Simulink:Engine:AlgStateNotFinite', ...
                  ['L''etat de la boucle algebrique qui passe par %s est infini ou NaN ' ...
                   'a t = %g.'], listeChemins(T, B.blocs), t);
        end
        error('Simulink:Engine:AlgLoopNotConverged', ...
              ['La boucle algebrique qui passe par %s ne converge pas a t = %g : ' ...
               'l''ecart restant est %g apres 50 iterations de Newton. Verifiez que la ' ...
               'boucle a une solution, ou coupez-la par un bloc Memory.'], ...
              listeChemins(T, B.blocs), t, max(abs(F)));
    end
    % Le jacobien ne se garde que s'il a été mesuré : une boucle résolue du
    % premier coup n'en a pas calculé, et garder des zéros ferait diviser
    % par zéro au pas suivant.
    if complet && jacobienValide
        Z(jA) = 1;
        Z(jA + 1:jA + nz * nz) = J(:);
    end
end

function texte = listeChemins(T, blocs)
    texte = ['''' strjoin(T.chemins(blocs), ''', ''') ''''];
end

% === dérivées ==================================================================

function dx = derivees(T, V, x)
    dx = zeros(numel(x), 1);
    for k = T.continus
        a = T.xA(k);
        b = T.xB(k);
        p = T.pA(k);
        e = T.eD(k);
        u = V(T.eA(e + 1):T.eB(e + 1));
        switch T.code(k)
            case 70   % integrator
                if T.P(p) == 0
                    dx(a:b) = u;
                else
                    w = b - a + 1;
                    d = u + zeros(w, 1);
                    xk = x(a:b);
                    d(xk >= T.P(p + 1:p + w) & d > 0) = 0;
                    d(xk <= T.P(p + 1 + w:p + 2 * w) & d < 0) = 0;
                    dx(a:b) = d;
                end
            case {72, 73, 74}
                dx(a:b) = deriveeEtat(T, p, x(a:b), u);
            case 76   % PID : l'intégrale, et le filtre de la dérivée
                w = (b - a + 1) / 2;
                dx(a:a + w - 1) = u;
                dx(a + w:b) = u - T.P(p + 3 * w:p + 4 * w - 1) .* x(a + w:b);
        end
    end
end

% === mises à jour ==============================================================

function Z = majs(T, V, Z, t, touche)
    for k = T.aMettreAJour
        if T.mode(k) == 2 && ~touche(T.grp(k))
            continue
        end
        z = T.zA(k);
        p = T.pA(k);
        e = T.eD(k);
        a = T.oA(k);
        b = T.oB(k);
        w = b - a + 1;
        u = V(T.eA(e + 1):T.eB(e + 1));
        switch T.code(k)
            case {10, 11}   % random numbers : le tirage suivant
                [valeurs, etatsPM] = matlibre_sl_hasard(Z(z:z + w - 1), T.P(p) ~= 0, ...
                                                        T.P(p + 1:p + w), ...
                                                        T.P(p + 1 + w:p + 2 * w));
                Z(z:z + w - 1) = etatsPM;
                Z(z + w:z + 2 * w - 1) = valeurs;
            case 42   % relay
                Z(z:z + w - 1) = modeRelais(T, p, w, u, Z(z:z + w - 1));
            case 44   % rate limiter
                Z(z) = 1;
                Z(z + 1) = t;
                Z(z + 2:z + 1 + w) = V(a:b);
            case 45   % hit crossing
                Z(z) = 1;
                Z(z + 1:z + w) = u - T.P(p:p + w - 1);
            case 46   % backlash
                Z(z:z + w - 1) = V(a:b);
            case {54, 55, 56}   % detect change, increase, decrease
                Z(z:z + w - 1) = u;
            case 71   % derivative
                Z(z) = 1;
                Z(z + 1) = t;
                Z(z + 2:z + 1 + numel(u)) = u;
            case 75   % transport delay
                longueur = T.P(p + 1);
                n = Z(z);
                debut = z + 1 + mod(n, longueur) * w;
                Z(debut:debut + w - 1) = u;
                Z(z) = n + 1;
            case 80   % delay
                L = T.P(p);
                tete = Z(z);
                debut = z + 1 + (tete - 1) * w;
                Z(debut:debut + w - 1) = u;
                Z(z) = mod(tete, L) + 1;
            case 81   % memory
                Z(z:z + w - 1) = u;
            case 83   % discrete-time integrator
                switch T.P(p + 1)
                    case 1
                        Z(z:z + w - 1) = Z(z:z + w - 1) + T.P(p) * u;
                    case 2
                        Z(z:z + w - 1) = V(a:b);
                    otherwise
                        Z(z:z + w - 1) = V(a:b) + T.P(p) * u / 2;
                end
            case {84, 85}   % discrete transfer fcn, discrete filter
                m = T.P(p);
                if m > 0
                    s = Z(z:z + m - 1);
                    ia = p + 2 + m;
                    Z(z + 1:z + m - 1) = s(1:m - 1);
                    Z(z) = u - T.P(ia + 1:ia + m).' * s;
                end
            case 86   % discrete state-space
                nx = T.P(p);
                if nx > 0
                    Z(z:z + nx - 1) = deriveeEtat(T, p, Z(z:z + nx - 1), u);
                end
        end
    end
end
