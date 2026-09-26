function varargout = matlibre_sl_executer(action, varargin)
%MATLIBRE_SL_EXECUTER Fait tourner un modèle compilé.
%   T = MATLIBRE_SL_EXECUTER('preparer',C) range le modèle C, compilé par
%   MATLIBRE_SL_COMPILER, en tableaux de nombres : ce que chaque pas lit
%   sans avoir rien à chercher.
%
%   J = MATLIBRE_SL_EXECUTER('simuler',T,INSTANTS,SOLVEUR) simule aux
%   INSTANTS, régulièrement espacés du pas de la compilation, avec le
%   solveur à pas fixe SOLVEUR : ode1 (Euler), ode2 (Heun), ode3
%   (Bogacki-Shampine), ode4 (Runge-Kutta), ode5 (Dormand-Prince), ode8
%   (Prince-Dormand, d'ordre huit), ou, pour les systèmes raides, ode1be
%   (Euler implicite) et ode14x (Euler implicite extrapolé). J
%   porte le relevé — une colonne par instant, une ligne par valeur
%   relevée, dans l'ordre de T.releves —, les états continus, et le rang
%   du dernier instant simulé, qu'un bloc Stop Simulation peut avancer.
%
%   J = MATLIBRE_SL_EXECUTER('simulerVariable',T,TDEBUT,TFINAL,SOLVEUR,
%   REGLAGES,IMPOSES) simule à pas variable, pour un modèle compilé avec
%   l'option variable : ode45 (Dormand-Prince 5(4)), ode23
%   (Bogacki-Shampine 3(2)), ode113 (Adams, d'ordre 1 à 12), et pour les
%   systèmes raides ode15s (NDF, d'ordre 1 à MaxOrder), ode23s
%   (Rosenbrock), ode23t (trapèzes) et ode23tb (TR-BDF2) ; ou
%   VariableStepDiscrete. Le pas suit les tolérances RelTol et
%   AbsTol de REGLAGES, borné par MaxStep et MinStep ; il s'arrête sur
%   chaque instant d'échantillonnage, chaque cassure d'une source
%   (échelon, front d'impulsion) et chaque passage par zéro, localisé
%   dans le pas. IMPOSES, s'il n'est pas vide, donne les seuls instants
%   relevés, que le solveur atteint exactement. J porte en plus le champ
%   temps, les instants relevés.
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
    switch lower(char(action))
        case 'preparer'
            varargout{1} = preparer(varargin{1});
        case 'simuler'
            varargout{1} = simuler(varargin{:});
        case 'simulervariable'
            varargout{1} = simulerVariable(varargin{:});
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
    T.zN = cellfun(@numel, c.z0);
    % L'état des diagrammes Stateflow : une poignée, neuve à chaque
    % préparation, que les tranches d'une simulation sans fin partagent.
    T.graphes = containers.Map('KeyType', 'double', 'ValueType', 'any');
    % L'état des sous-systèmes itérés, de même.
    T.iterateurs = containers.Map('KeyType', 'double', 'ValueType', 'any');
    T.x0 = c.x0;
    T.xA = c.xA;
    T.xB = c.xB;
    T.V0 = zeros(c.nV, 1);
    % Les sous-systèmes conditionnels : la garde de chaque bloc, ce que
    % rendent leurs sorties avant le premier calcul et à l'arrêt, et les
    % objets que leurs blocs de choix consultent.
    T.garde = zeros(1, n);
    if isfield(c, 'garde')
        T.garde = c.garde;
    end
    T.objets = cell(1, n);
    if isfield(c, 'objets')
        T.objets = c.objets;
    end
    T.formes = cell(1, n);
    for k = find(strcmp(c.types, 'matlabfunction'))
        T.formes{k} = cell(1, c.nIn(k));
        for j = 1:c.nIn(k)
            T.formes{k}{j} = c.inDims{k}{j};
        end
    end
    T.revient = false(1, n);
    T.initiale = cell(1, n);
    for k = 1:n
        if isfield(c, 'sortieCond') && ~isempty(c.sortieCond{k})
            w = c.oB(k) - c.oA(k) + 1;
            valeur = double(c.sortieCond{k}.initiale(:));
            if isempty(valeur)
                valeur = 0;
            end
            valeur = valeur + zeros(w, 1);
            T.V0(c.oA(k):c.oB(k)) = valeur;
            T.revient(k) = c.sortieCond{k}.revient;
            T.initiale{k} = valeur;
        elseif strcmp(c.types{k}, 'merge')
            w = c.oB(k) - c.oA(k) + 1;
            T.V0(c.oA(k):c.oB(k)) = c.seg{k}(2:1 + w);
        end
    end
    T.sousGarde = cell(1, n);
    for k = 1:n
        g = T.garde(k);
        while g > 0
            T.sousGarde{g}(end + 1) = k;
            g = T.garde(g);
        end
    end
    T.remises = [];
    for k = find(strcmp(c.types, 'garde'))
        if c.seg{k}(4) ~= 0
            T.remises(end + 1) = k;
        end
    end
    % Les intégrateurs à remise externe ou à condition initiale externe :
    % leur état se remet au pas majeur, comme celui d'un sous-système.
    T.reinit = [];
    for k = find(strcmp(c.types, 'integrator'))
        w = (numel(c.seg{k}) - 6) / 2;
        if c.seg{k}(2 + 2 * w) > 0 || c.seg{k}(3 + 2 * w) ~= 0
            T.reinit(end + 1) = k;
        end
    end
    T.aRemettre = ~isempty(T.remises) || ~isempty(T.reinit);
    T.h = c.pas;
    T.tDebut = c.tDebut;
    T.fixe = ~(isfield(c, 'variable') && c.variable);

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
            % Un groupe par période : comptée en pas à pas fixe, en
            % secondes à pas variable.
            if T.fixe
                cle = [c.periodePas(k), c.decalagePas(k)];
            else
                cle = [c.cadence(k), c.decalage(k)];
            end
            g = find(T.groupes(:, 1) == cle(1) & T.groupes(:, 2) == cle(2), 1);
            if isempty(g)
                T.groupes(end + 1, :) = cle;
                g = size(T.groupes, 1);
            end
            T.grp(k) = g;
        elseif c.majeurSeul(k)
            T.mode(k) = 1;
        end
        % Dans un sous-système déclenché, un bloc ne calcule qu'aux fronts,
        % donc aux pas majeurs, quelle que soit sa période.
        if isfield(c, 'declenche') && c.declenche(k) && T.mode(k) ~= 3
            T.mode(k) = 1;
            T.grp(k) = 0;
        end
        % Une constante gardée ne se calcule pas une fois pour toutes : son
        % sous-système peut dormir au premier pas. Elle se calcule aux pas
        % majeurs où il est actif.
        if isfield(c, 'garde') && c.garde(k) > 0 && T.mode(k) == 3
            T.mode(k) = 1;
        end
        % Un générateur d'appels garde sa période — le solveur s'arrête à
        % ses instants —, mais se calcule à chaque pas majeur : il dit 1 à
        % ses instants, 0 entre eux.
        if strcmp(c.types{k}, 'functioncallgenerator')
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
                              'terminator', 'goto', 'ground', 'enableport', ...
                              'triggerport', 'actionport', 'xygraph', 'tofile', ...
                              'datastorememory'});
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
                  'discretestatespace', 'randomnumber', 'uniformrandomnumber', 'garde', ...
                  'counterfreerunning', 'counterlimited', 'repeatingsequencestair', 'ic', ...
                  'discretederivative', 'tappeddelay', 'difference'}
                T.aMettreAJour(end + 1) = k;
            case 'signalgenerator'
                if c.sub(k) == 4
                    T.aMettreAJour(end + 1) = k;
                end
            case 'ratetransition'
                if c.sub(k) == 2
                    T.aMettreAJour(end + 1) = k;
                end
            case 'sfunction'
                if c.seg{k}(2) > 0
                    T.aMettreAJour(end + 1) = k;
                end
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

    % Pour le pas variable : les blocs dont on surveille les passages par
    % zéro, les instants où une source casse, et les générateurs
    % d'impulsions, dont les fronts se calculent en marchant.
    T.zc = [];
    if isfield(c, 'zc')
        T.zc = find(c.zc);
    end
    T.cassures = zeros(0, 1);
    T.impulsions = [];
    for k = 1:n
        s = c.seg{k};
        w = c.oB(k) - c.oA(k) + 1;
        switch c.types{k}
            case 'step'
                T.cassures = [T.cassures; s(1:w)];
            case 'ramp'
                T.cassures = [T.cassures; s(w + 1:2 * w)];
            case 'fromworkspace'
                nt = s(1);
                temps = s(5:4 + nt);
                if s(3) == 0
                    T.cassures = [T.cassures; temps];
                else
                    T.cassures = [T.cassures; temps(end)];
                end
            case 'pulsegenerator'
                if c.sub(k) == 1
                    T.impulsions(end + 1) = k;
                end
            case 'signalgenerator'
                if any(c.sub(k) == [2 3])
                    T.impulsions(end + 1) = k;
                end
        end
    end
    T.cassures = unique(T.cassures(isfinite(T.cassures)));
    % À pas variable, un bloc surveillé fige son mode entre deux pas
    % majeurs — le côté du seuil où il était —, comme dans Simulink : aux
    % pas mineurs, il prolonge la formule de ce côté-là. Le franchissement
    % est alors vu par la détection, et le mode change au pas majeur qui
    % le suit. Les modes sont rangés au bout de Z.
    % La sortie d'un sous-système conditionnel à l'arrêt tient la valeur du
    % dernier pas majeur où il a calculé : elle est rangée au bout de Z, car
    % les pas mineurs écrivent dans V des valeurs de passage.
    T.zTenue = zeros(1, n);
    for k = find(T.revient | ~cellfun(@isempty, T.initiale))
        if ~T.revient(k)
            T.zTenue(k) = numel(T.Z0) + 1;
            T.Z0 = [T.Z0; T.initiale{k}];
        end
    end
    T.gele = false(1, n);
    T.zmA = zeros(1, n);
    if ~T.fixe
        for k = T.zc
            if any(T.code(k) == [23 24 27 40 41 47 51 52 53 60])
                T.gele(k) = true;
                T.zmA(k) = numel(T.Z0) + 1;
                T.Z0 = [T.Z0; zeros(c.oB(k) - c.oA(k) + 1, 1)];
            end
        end
    end
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
% Kutta, Dormand et Prince, Prince et Dormand pour ode8 —, et c'est leur
% ordre que le test mesure. ode1be et ode14x, implicites, n'ont pas de
% tableau : leur pas se fait à part.
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
        case 'ode8'
            [A, b, c] = tableauOde8();
        case {'ode1be', 'ode14x'}
            A = [];
            b = [];
            c = [];
        otherwise
            error('Simulink:Config:InvalidSolver', ...
                  'Le solveur a pas fixe ''%s'' est inconnu.', solveur);
    end
end

% La formule RK8(7)13M de Prince et Dormand (1981) : treize étages, la
% solution d'ordre huit. Ses coefficients sont les fractions publiées.
function [A, b, c] = tableauOde8()
    A = zeros(13, 13);
    A(2, 1) = 1/18;
    A(3, 1:2) = [1/48 1/16];
    A(4, [1 3]) = [1/32 3/32];
    A(5, [1 3 4]) = [5/16 -75/64 75/64];
    A(6, [1 4 5]) = [3/80 3/16 3/20];
    A(7, [1 4 5 6]) = [29443841/614563906 77736538/692538347 -28693883/1125000000 ...
                       23124283/1800000000];
    A(8, [1 4 5 6 7]) = [16016141/946692911 61564180/158732637 22789713/633445777 ...
                         545815736/2771057229 -180193667/1043307555];
    A(9, [1 4 5 6 7 8]) = [39632708/573591083 -433636366/683701615 ...
                           -421739975/2616292301 100302831/723423059 ...
                           790204164/839813087 800635310/3783071287];
    A(10, [1 4:9]) = [246121993/1340847787 -37695042795/15268766246 ...
                      -309121744/1061227803 -12992083/490766935 ...
                      6005943493/2108947869 393006217/1396673457 ...
                      123872331/1001029789];
    A(11, [1 4:10]) = [-1028468189/846180014 8478235783/508512852 ...
                       1311729495/1432422823 -10304129995/1701304382 ...
                       -48777925059/3047939560 15336726248/1032824649 ...
                       -45442868181/3398467696 3065993473/597172653];
    A(12, [1 4:11]) = [185892177/718116043 -3185094517/667107341 ...
                       -477755414/1098053517 -703635378/230739211 ...
                       5731566787/1027545527 5232866602/850066563 ...
                       -4093664535/808688257 3962137247/1805957418 ...
                       65686358/487910083];
    A(13, [1 4:12]) = [403863854/491063109 -5068492393/434740067 ...
                       -411421997/543043805 652783627/914296604 ...
                       11173962825/925320556 -13158990841/6184727034 ...
                       3936647629/1978049680 -160528059/685178525 ...
                       248638103/1413531060 0];
    b = [14005451/335480064 0 0 0 0 -59238493/1068277825 181606767/758867731 ...
         561292985/797845732 -1041891430/1371343529 760417239/1151165299 ...
         118820643/751138087 -528747749/2220607170 1/4];
    c = [0 1/18 1/12 1/8 5/16 3/8 59/400 93/200 5490023248/9719169821 13/20 ...
         1201146811/1299019798 1 1];
end

% Les réglages des solveurs implicites, que SIM pose sur T : l'ordre
% d'extrapolation d'ode14x, le nombre d'itérations de Newton d'ode1be et
% d'ode14x, l'ordre maximal d'ode15s. Sans eux, les valeurs de Simulink.
function r = reglagesSolveur(T)
    r = struct('ExtrapolationOrder', 4, 'NumberNewtonIterations', 1, 'MaxOrder', 5);
    if isfield(T, 'reglagesSolveur')
        for nom = fieldnames(T.reglagesSolveur).'
            r.(nom{1}) = double(T.reglagesSolveur.(nom{1}));
        end
    end
end

% Le pas des solveurs implicites à pas fixe. ode1be est Euler implicite,
% résolu par un nombre fixe d'itérations de Newton — une seule par
% défaut : le coût d'un pas ne dépend pas de la difficulté. ode14x fait le
% pas en 1, 2, ..., p sous-pas d'Euler implicite, puis extrapole les p
% résultats à pas nul (Richardson, tableau d'Aitken et Neville) : l'ordre
% monte à p, l'ordre d'extrapolation. Le jacobien se mesure une fois par
% pas.
function [x, V, Z] = pasImpliciteFixe(T, V, Z, x, k1, t, h, solveur, touche)
    r = reglagesSolveur(T);
    iterations = max(1, round(r.NumberNewtonIterations));
    [Jac, ~, V, Z] = jacobien(T, V, Z, x, k1, t, touche);
    if strcmp(solveur, 'ode1be')
        p = 1;
    else
        p = max(1, min(4, round(r.ExtrapolationOrder)));
    end
    tab = cell(p, p);
    for j = 1:p
        hj = h / j;
        W = eye(numel(x)) - hj * Jac;
        y = x;
        for s = 1:j
            ts = t + s * hj;
            z = y;
            for iteration = 1:iterations
                [V, Z] = passe(T, T.listeMineure, V, Z, z, ts, 0, false, touche);
                z = z + W \ (y + hj * derivees(T, V, z, ts) - z);
                if ~isempty(T.bornes)
                    z = borner(T, z);
                end
            end
            y = z;
        end
        tab{j, 1} = y;
        for q = 2:j
            tab{j, q} = tab{j, q - 1} + (tab{j, q - 1} - tab{j - 1, q - 1}) / (j / (j - q + 1) - 1);
        end
    end
    x = tab{p, p};
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
        if T.aRemettre
            [x, Z, refaire] = remettre(T, V, Z, x, t);
            if refaire
                [V, Z] = passe(T, T.listeMajeure, V, Z, x, t, i, true, touche);
            end
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
            k1 = derivees(T, V, x, t);
            if ~all(isfinite(k1))
                deriveeInfinie(T, k1, t);
            end
        end
        Z = majs(T, V, Z, t, touche, x);
        if nx > 0
            if nEtages == 0
                [x, V, Z] = pasImpliciteFixe(T, V, Z, x, k1, t, h, lower(solveur), touche);
            elseif nEtages == 1
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
                    K(:, s) = derivees(T, V, xs, t + cq(s) * h);
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

% === pas variable ==============================================================
%
% Les solveurs à pas variable de Simulink. ode45 (Dormand et Prince,
% ordres 5 et 4) et ode23 (Bogacki et Shampine, ordres 3 et 2) portent à
% chaque pas deux solutions d'ordres voisins : leur écart estime l'erreur,
% et le pas suivant s'en déduit ; un pas trop grand est refait plus court.
% ode23s est la formule de Rosenbrock de Shampine et Reichelt, d'ordre 2
% avec une estimation d'ordre 3 : implicite, elle garde un grand pas là où
% un système raide forcerait les deux autres à piétiner. ode23t est la
% règle des trapèzes, ode23tb la formule TR-BDF2 — un pas de trapèzes
% puis un pas de BDF2 — : implicites elles aussi, d'ordre 2, leur erreur
% s'estime par une différence divisée des dérivées. Les solveurs
% implicites mesurent leur jacobien par différences finies, une fois par
% pas.
%
% ode15s et ode113 sont à pas multiples : ils se souviennent des pas
% passés, et leur ordre varie. ode15s, les NDF de Klopfenstein et
% Shampine, d'ordre 1 à 5, pour les systèmes raides ; ode113, les
% formules d'Adams-Bashforth-Moulton, d'ordre 1 à 12, pour les
% tolérances fines. Leur mémoire repart de l'ordre 1 après toute
% discontinuité : un passage par zéro, un état remis, une source qui
% casse, un bloc échantillonné qui change la dérivée.
%
% Le pas s'arrête exactement sur les instants d'échantillonnage, sur les
% cassures des sources — l'instant d'un échelon, les fronts d'un
% générateur d'impulsions — et sur les instants imposés. Un seuil franchi
% dans le pas — passage par zéro de l'entrée d'un relais, d'une
% saturation, d'un aiguillage — est localisé par dichotomie, et le pas
% s'arrête juste après : le mode du bloc change au pas majeur suivant, et
% la solution ne franchit pas l'événement à l'aveugle.
function [A, b, bEtoile, c, ordre] = tableauVariable(solveur)
    switch solveur
        case 'ode45'
            A = [0 0 0 0 0 0 0
                 1/5 0 0 0 0 0 0
                 3/40 9/40 0 0 0 0 0
                 44/45 -56/15 32/9 0 0 0 0
                 19372/6561 -25360/2187 64448/6561 -212/729 0 0 0
                 9017/3168 -355/33 46732/5247 49/176 -5103/18656 0 0
                 35/384 0 500/1113 125/192 -2187/6784 11/84 0];
            b = [35/384 0 500/1113 125/192 -2187/6784 11/84 0];
            bEtoile = [5179/57600 0 7571/16695 393/640 -92097/339200 187/2100 1/40];
            c = [0 1/5 3/10 4/5 8/9 1 1];
            ordre = 5;
        case 'ode23'
            A = [0 0 0 0
                 1/2 0 0 0
                 0 3/4 0 0
                 2/9 1/3 4/9 0];
            b = [2/9 1/3 4/9 0];
            bEtoile = [7/24 1/4 1/3 1/8];
            c = [0 1/2 3/4 1];
            ordre = 3;
        case {'ode23s', 'ode23t', 'ode23tb'}
            A = [];
            b = [];
            bEtoile = [];
            c = [];
            ordre = 3;
        case {'ode15s', 'ode113'}
            A = [];
            b = [];
            bEtoile = [];
            c = [];
            ordre = 2;   % l'ordre 1 du départ, dont l'erreur va comme h^2
        otherwise   % variablestepdiscrete : pas d'état continu à intégrer
            A = 0;
            b = 1;
            bEtoile = 1;
            c = 0;
            ordre = 1;
    end
end

% REGLAGES porte RelTol, AbsTol, MaxStep, MinStep et InitialStep : un
% nombre, ou 'auto'. IMPOSES, s'il n'est pas vide, porte les seuls
% instants à relever.
function J = simulerVariable(T, tDebut, tFinal, solveur, reglages, imposes)
    if nargin < 6
        imposes = [];
    end
    imposes = sort(double(imposes(:)));
    solveur = lower(char(solveur));
    nx = numel(T.x0);
    discret = strcmp(solveur, 'variablestepdiscrete') || nx == 0;
    M = struct();
    [M.A, M.b, M.bE, M.c, M.ordre] = tableauVariable(solveur);
    methodes = struct('ode23s', 'rosenbrock', 'ode23t', 'trapeze', 'ode23tb', 'trbdf2', ...
                      'ode15s', 'ndf', 'ode113', 'adams');
    M.methode = 'rk';
    if isfield(methodes, solveur)
        M.methode = methodes.(solveur);
    end
    M.implicite = any(strcmp(M.methode, {'rosenbrock', 'trapeze', 'trbdf2', 'ndf'}));
    M.multipas = any(strcmp(M.methode, {'ndf', 'adams'}));
    M.ordreMax = 12;
    if strcmp(M.methode, 'ndf')
        M.ordreMax = 5;
        if isfield(reglages, 'MaxOrder') && ~ischar(reglages.MaxOrder)
            M.ordreMax = double(reglages.MaxOrder);
        end
    end
    M.H = struct('valide', false, 'k', 1, 'h', 0, 'D', [], 'nconst', 0, 'fin', []);
    M.J = [];
    M.dfdt = [];

    % Les tampons du retard pur, hors de Z : ils grandissent au besoin.
    tampons = containers.Map('KeyType', 'double', 'ValueType', 'any');
    for k = find(T.code == 75)
        p = T.pA(k);
        if T.P(p) > 0
            w = T.oB(k) - T.oA(k) + 1;
            L = T.P(p + 1);
            tampons(k) = struct('t', zeros(L, 1), 'v', zeros(w, L), 'tete', 1, 'n', 0);
        end
    end
    T.tampons = tampons;

    duree = tFinal - tDebut;
    if ischar(reglages.MaxStep)
        if isfinite(duree) && duree > 0
            pasMax = duree / 50;
        else
            pasMax = 0.2;   % Simulink prend 0,2 s quand la fin est infinie
        end
    else
        pasMax = double(reglages.MaxStep);
    end
    minimumDonne = ~ischar(reglages.MinStep);
    if minimumDonne
        pasMin = double(reglages.MinStep);
    else
        pasMin = 0;
    end
    rtol = double(reglages.RelTol);
    absoluAuto = ischar(reglages.AbsTol);
    if absoluAuto
        atol = rtol * 1e-3 * ones(nx, 1);
    else
        atol = double(reglages.AbsTol) .* ones(nx, 1);
    end
    maxAbs = abs(T.x0);

    % Les groupes de période, en secondes : le rang de leur prochain
    % instant est compté en entiers, pour que l'arrondi ne dérive pas.
    G = size(T.groupes, 1);
    periodes = T.groupes(:, 1);
    decalages = T.groupes(:, 2);
    rangs = zeros(G, 1);
    for g = 1:G
        rangs(g) = max(0, ceil((tDebut - decalages(g)) / periodes(g) - 1e-9));
    end
    prochain = decalages + rangs .* periodes;

    capacite = 256;
    temps = zeros(1, capacite);
    releveV = zeros(numel(T.journal), capacite);
    etats = zeros(nx, capacite);
    n = 0;
    iImpose = 1;
    while iImpose <= numel(imposes) && imposes(iImpose) < tDebut - toleranceTemps(tDebut)
        iImpose = iImpose + 1;
    end

    t = tDebut;
    x = T.x0;
    Z = T.Z0;
    touche = (abs(prochain - t) <= toleranceTemps(t)).';
    [V, Z] = passe(T, T.listeTout, T.V0, Z, x, t, 0, true, touche);
    if T.aRemettre
        [x, Z, refaire] = remettre(T, V, Z, x, t);
        if refaire
            [V, Z] = passe(T, T.listeMajeure, V, Z, x, t, 0, true, touche);
        end
    end
    [temps, releveV, etats, n, iImpose] = noter(temps, releveV, etats, n, t, V(T.journal), ...
                                                x, imposes, iImpose);
    T = figerBornes(T, V, x);
    avant = passagesZero(T, V, Z, x, t);
    arret = Z(1) ~= 0;
    hPropose = [];
    hForce = [];
    consecutifs = 0;
    averti = false;
    while ~arret && (isinf(tFinal) || t < tFinal - toleranceTemps(tFinal))
        % Les états discrets avancent aux instants qui viennent de tomber.
        k1 = zeros(nx, 1);
        if nx > 0
            k1 = derivees(T, V, x, t);
            if ~all(isfinite(k1))
                deriveeInfinie(T, k1, t);
            end
        end
        % Une dérivée qui saute depuis la fin du pas précédent — un bloc
        % échantillonné, un mode qui bascule — rend la mémoire des pas
        % passés fausse : les solveurs à pas multiples repartent.
        if M.multipas && M.H.valide && ...
           normeErreur(M.H.h * (k1 - M.H.fin), x, x, atol, rtol) > 0.1
            M.H.valide = false;
        end
        if M.multipas && ~M.H.valide
            M.ordre = 2;
            hPropose = [];
        end
        Z = majs(T, V, Z, t, touche, x);
        rangs(touche) = rangs(touche) + 1;
        prochain = decalages + rangs .* periodes;

        % La borne du pas : la fin, le prochain instant d'échantillonnage,
        % la prochaine cassure d'une source, le prochain instant imposé.
        cible = min([tFinal; prochain; prochaineCassure(T, t)]);
        if iImpose <= numel(imposes)
            cible = min(cible, imposes(iImpose));
        end
        borne = min(cible - t, pasMax);
        if ~isempty(hForce)
            % le pas de droite d'un événement : il ne fait que le franchir
            borne = min(borne, hForce);
            hForce = [];
        end
        err = 0;
        parErreur = false;
        if discret
            h = borne;
            xNouveau = x;
        else
            if M.implicite
                [M.J, M.dfdt, V, Z] = jacobien(T, V, Z, x, k1, t, touche);
            end
            if isempty(hPropose)
                if ischar(reglages.InitialStep)
                    [hPropose, V, Z] = pasInitial(T, V, Z, x, k1, t, borne, atol, rtol, ...
                                                  M.ordre, touche);
                else
                    hPropose = double(reglages.InitialStep);
                end
            end
            hPropose = min(hPropose, pasMax);
            h = min(hPropose, borne);
            plancher = max(pasMin, 16 * eps(max(abs(t), 1)));
            while true
                [xNouveau, err, V, Z, aux] = unPas(T, M, V, Z, x, k1, t, h, atol, rtol, ...
                                                   touche);
                if err <= 1
                    break
                end
                if h <= plancher
                    if ~isfinite(err)
                        error('Simulink:Engine:DerivNotFinite', ...
                              ['Le pas du solveur ne peut plus diminuer a t = %g : les ' ...
                               'derivees ne sont pas finies. La solution a peut-etre une ' ...
                               'singularite.'], t);
                    end
                    if ~minimumDonne
                        conseil = ' ; si le systeme est raide, essayez ode15s ou ode23s';
                        if M.implicite
                            conseil = '';
                        end
                        error('Simulink:Engine:SolverMinStepViolation', ...
                              ['A t = %g, le solveur %s ne tient plus la tolerance sans ' ...
                               'reduire le pas sous %g, le plus petit que permet la ' ...
                               'precision des nombres. La solution a peut-etre une ' ...
                               'singularite%s.'], t, solveur, plancher, conseil);
                    end
                    if ~averti
                        warning('Simulink:Engine:SolverMinStepViolation', ...
                                ['A t = %g, le solveur %s ne tient pas la tolerance au pas ' ...
                                 'minimal MinStep = %g : il avance quand meme.'], ...
                                t, solveur, pasMin);
                        averti = true;
                    end
                    break
                end
                h = max(h * max(0.1, 0.9 * err ^ (-1 / M.ordre)), plancher);
                parErreur = true;
            end
        end
        if isfinite(cible) && abs(t + h - cible) <= toleranceTemps(cible)
            h = cible - t;
        end
        tNouveau = t + h;

        % Un seuil franchi dans le pas : on le localise entre deux instants
        % très proches. Comme Simulink, on fait deux pas majeurs : l'un
        % juste avant le franchissement, où les blocs calculent encore dans
        % leur ancien mode — c'est la valeur que tient un sous-système qui
        % s'arrête —, l'autre juste après, au pas suivant.
        if ~isempty(avant)
            [Vc, ~] = passe(T, T.listeMineure, V, Z, xNouveau, tNouveau, 0, false, touche);
            apres = passagesZero(T, Vc, Z, xNouveau, tNouveau);
            if any(sign(avant) .* sign(apres) < 0)
                [gauche, droite, V, Z] = localiser(T, M, V, Z, x, k1, t, h, atol, rtol, ...
                                                   avant, touche, discret);
                if gauche > 0
                    hEvenement = gauche;
                    hForce = droite - gauche;
                else
                    hEvenement = droite;
                end
                if hEvenement < h
                    h = hEvenement;
                    tNouveau = t + h;
                    if ~discret
                        [xNouveau, ~, V, Z, aux] = unPas(T, M, V, Z, x, k1, t, h, atol, ...
                                                         rtol, touche);
                    end
                end
                if h <= 1e3 * toleranceTemps(t)
                    consecutifs = consecutifs + 1;
                    if consecutifs > 1000
                        error('Simulink:Engine:SolverConsecutiveZCNum', ...
                              ['Plus de 1000 passages par zero consecutifs a t = %g : le ' ...
                               'modele bascule sans avancer (comportement de Zenon). ' ...
                               'Revoyez le seuil qui bascule, ou coupez la detection des ' ...
                               'passages par zero (ZeroCrossControl, ou le parametre ' ...
                               'ZeroCross du bloc).'], t);
                    end
                else
                    consecutifs = 0;
                end
            end
        end

        % Le pas majeur. Un intégrateur tenu à sa borne n'en a pas bougé :
        % l'arrondi d'un solveur implicite ne l'en décolle pas.
        if any(T.satures)
            xNouveau(T.satures) = x(T.satures);
        end
        t = tNouveau;
        x = xNouveau;
        if ~isempty(T.bornes)
            x = borner(T, x);
        end
        touche = (abs(prochain - t) <= toleranceTemps(t)).';
        [V, Z] = passe(T, T.listeMajeure, V, Z, x, t, 0, true, touche);
        if T.aRemettre
            [x, Z, refaire] = remettre(T, V, Z, x, t);
            if refaire
                [V, Z] = passe(T, T.listeMajeure, V, Z, x, t, 0, true, touche);
            end
        end
        % La mémoire des pas multiples retient ce pas ; un état remis, ou
        % tenu dans ses bornes, n'est plus celui qu'elle prolonge.
        choixMultipas = [];
        if M.multipas && ~discret
            [M, choixMultipas] = retenirPas(M, aux, xNouveau, err, atol, rtol);
            if ~isequal(x, xNouveau)
                M.H.valide = false;
            end
        end
        [temps, releveV, etats, n, iImpose] = noter(temps, releveV, etats, n, t, ...
                                                    V(T.journal), x, imposes, iImpose);
        arret = Z(1) ~= 0;
        T = figerBornes(T, V, x);
        avant = passagesZero(T, V, Z, x, t);
        if nx > 0
            maxAbs = max(maxAbs, abs(x));
            if absoluAuto
                atol = rtol * max(maxAbs, 1e-3);
            end
        end
        % Le pas suivant : celui que l'erreur permet. Un pas raccourci pour
        % tomber sur un instant ne dit rien de l'erreur : on garde alors
        % celui qu'on avait proposé.
        if ~discret && ~isempty(hPropose)
            if M.multipas
                facteur = choixMultipas;
            else
                facteur = min(5, max(0.2, 0.9 * max(err, 1e-10) ^ (-1 / M.ordre)));
            end
            if parErreur || h >= hPropose
                hPropose = h * facteur;
            else
                hPropose = max(hPropose, h * facteur);
            end
        end
    end
    J = struct('temps', temps(1:n), 'releve', releveV(:, 1:n), 'etats', etats(:, 1:n), ...
               'dernier', n, 'arret', arret, 'V', V, 'Z', Z, 'x', x);
end

% Un instant relevé : tous, ou seulement les instants imposés. La
% capacité double quand elle est pleine — un relevé qui grandirait d'une
% colonne à la fois se recopierait à chaque pas.
function [temps, releveV, etats, n, iImpose] = noter(temps, releveV, etats, n, t, valeurs, ...
                                                     x, imposes, iImpose)
    if ~isempty(imposes)
        if iImpose > numel(imposes) || abs(imposes(iImpose) - t) > toleranceTemps(t)
            return
        end
        iImpose = iImpose + 1;
    end
    if n == numel(temps)
        temps = [temps, zeros(1, n)];
        releveV = [releveV, zeros(size(releveV, 1), n)];
        etats = [etats, zeros(size(etats, 1), n)];
    end
    n = n + 1;
    temps(n) = t;
    releveV(:, n) = valeurs;
    etats(:, n) = x;
end

function tol = toleranceTemps(t)
    tol = 1e-10 * max(1, abs(t));
end

% Un pas de taille H : la solution, et l'erreur relative estimée — 1 est
% la tolérance.
function [xNouveau, err, V, Z, aux] = unPas(T, M, V, Z, x, k1, t, h, atol, rtol, touche)
    aux = [];
    switch M.methode
        case 'rosenbrock'
            [xNouveau, err, V, Z] = pasRosenbrock(T, M, V, Z, x, k1, t, h, atol, rtol, touche);
            return
        case 'trapeze'
            [xNouveau, err, V, Z] = pasTrapeze(T, M, V, Z, x, k1, t, h, atol, rtol, touche);
            return
        case 'trbdf2'
            [xNouveau, err, V, Z] = pasTRBDF2(T, M, V, Z, x, k1, t, h, atol, rtol, touche);
            return
        case 'ndf'
            [xNouveau, err, V, Z, aux] = pasNDF(T, M, V, Z, x, k1, t, h, atol, rtol, touche);
            return
        case 'adams'
            [xNouveau, err, V, Z, aux] = pasAdams(T, M, V, Z, x, k1, t, h, atol, rtol, touche);
            return
    end
    S = numel(M.b);
    K = zeros(numel(x), S);
    K(:, 1) = k1;
    for s = 2:S
        xs = x + h * (K(:, 1:s - 1) * M.A(s, 1:s - 1).');
        if ~isempty(T.bornes)
            xs = borner(T, xs);
        end
        [V, Z] = passe(T, T.listeMineure, V, Z, xs, t + M.c(s) * h, 0, false, touche);
        K(:, s) = derivees(T, V, xs, t + M.c(s) * h);
    end
    xNouveau = x + h * (K * M.b.');
    ecart = h * (K * (M.b - M.bE).');
    err = normeErreur(ecart, x, xNouveau, atol, rtol);
end

function err = normeErreur(ecart, x, xNouveau, atol, rtol)
    echelle = atol + rtol * max(abs(x), abs(xNouveau));
    err = max(abs(ecart) ./ echelle);
    if isempty(err)
        err = 0;
    end
    if ~all(isfinite(xNouveau))
        err = Inf;
    end
end

% La formule de Rosenbrock d'ode23s (Shampine et Reichelt, 1997) :
% W = I - h d J, trois résolutions linéaires par pas, la troisième pour
% l'erreur.
function [xNouveau, err, V, Z] = pasRosenbrock(T, M, V, Z, x, k1, t, h, atol, rtol, touche)
    d = 1 / (2 + sqrt(2));
    e32 = 6 + sqrt(2);
    nx = numel(x);
    W = eye(nx) - h * d * M.J;
    F0 = k1;
    r1 = W \ (F0 + h * d * M.dfdt);
    x1 = x + 0.5 * h * r1;
    [V, Z] = passe(T, T.listeMineure, V, Z, x1, t + 0.5 * h, 0, false, touche);
    F1 = derivees(T, V, x1, t + 0.5 * h);
    r2 = W \ (F1 - r1) + r1;
    xNouveau = x + h * r2;
    [V, Z] = passe(T, T.listeMineure, V, Z, xNouveau, t + h, 0, false, touche);
    F2 = derivees(T, V, xNouveau, t + h);
    r3 = W \ (F2 - e32 * (r2 - F1) - 2 * (r1 - F0) + h * d * M.dfdt);
    ecart = h / 6 * (r1 - 2 * r2 + r3);
    err = normeErreur(ecart, x, xNouveau, atol, rtol);
end

% Résout Y = A + C*H*F(T1,Y) par les itérations de Newton simplifiées : la
% matrice W = I - C*H*J, où J est le jacobien mesuré en début de pas, ne
% change pas d'une itération à l'autre. Les itérations s'arrêtent quand la
% correction tombe bien sous la tolérance, ou quand leur vitesse promet
% qu'elle y tombera ; elles échouent si elles divergent, ou si quatre ne
% suffisent pas. FY est la dérivée en la solution trouvée. La solution
% n'est pas tenue dans les bornes des intégrateurs : le pas majeur l'y
% ramène.
function [y, fy, converge, V, Z] = implicite(T, M, V, Z, a, c, h, t1, y, atol, rtol, touche)
    W = eye(numel(y)) - c * h * M.J;
    converge = false;
    precedente = Inf;
    for iteration = 1:4
        [V, Z] = passe(T, T.listeMineure, V, Z, y, t1, 0, false, touche);
        fy = derivees(T, V, y, t1);
        correction = W \ (a + c * h * fy - y);
        y = y + correction;
        if ~all(isfinite(y))
            return
        end
        norme = max(abs(correction) ./ (atol + rtol * abs(y)));
        if isempty(norme) || norme <= 1e-2
            converge = true;
            break
        end
        if iteration > 1
            taux = norme / precedente;
            if taux >= 0.9
                return
            end
            if taux / (1 - taux) * norme <= 5e-2
                converge = true;
                break
            end
        end
        precedente = norme;
    end
    if converge
        [V, Z] = passe(T, T.listeMineure, V, Z, y, t1, 0, false, touche);
        fy = derivees(T, V, y, t1);
    end
end

% Des itérations de Newton qui ne convergent pas : le pas est refait
% trois fois plus court, comme une erreur trop grande le ferait.
function err = echecNewton(M)
    err = 3 ^ M.ordre;
end

% La règle des trapèzes d'ode23t : X1 = X + H/2 (F0 + F(X1)). Son erreur,
% -H^3/12 X''', s'estime par la différence seconde des dérivées au début,
% au milieu — sur l'interpolant d'Hermite — et à la fin du pas ; W la
% filtre, pour qu'un mode raide ne la gonfle pas.
function [xNouveau, err, V, Z] = pasTrapeze(T, M, V, Z, x, k1, t, h, atol, rtol, touche)
    [xNouveau, f1, converge, V, Z] = implicite(T, M, V, Z, x + h / 2 * k1, 1 / 2, h, ...
                                               t + h, x + h * k1, atol, rtol, touche);
    if ~converge
        err = echecNewton(M);
        return
    end
    xm = (x + xNouveau) / 2 + h / 8 * (k1 - f1);
    [V, Z] = passe(T, T.listeMineure, V, Z, xm, t + h / 2, 0, false, touche);
    fm = derivees(T, V, xm, t + h / 2);
    W = eye(numel(x)) - h / 2 * M.J;
    ecart = W \ (h / 3 * (k1 - 2 * fm + f1));
    err = normeErreur(ecart, x, xNouveau, atol, rtol);
end

% TR-BDF2 (Bank et al., Hosea et Shampine) : les trapèzes jusqu'à
% t + g*h, puis BDF2 sur les trois points ; avec g = 2 - sqrt(2), les deux
% étages partagent la même matrice W. L'erreur, C*H^3*X''', s'estime par
% la différence divisée seconde des trois dérivées.
function [xNouveau, err, V, Z] = pasTRBDF2(T, M, V, Z, x, k1, t, h, atol, rtol, touche)
    g = 2 - sqrt(2);
    d = g / 2;
    [xg, fg, converge, V, Z] = implicite(T, M, V, Z, x + d * h * k1, d, h, t + g * h, ...
                                         x + g * h * k1, atol, rtol, touche);
    if ~converge
        xNouveau = xg;
        err = echecNewton(M);
        return
    end
    a = (sqrt(2) + 1) / 2 * xg - (sqrt(2) - 1) / 2 * x;
    [xNouveau, f1, converge, V, Z] = implicite(T, M, V, Z, a, d, h, t + h, ...
                                               xg + (1 - g) * h * fg, atol, rtol, touche);
    if ~converge
        err = echecNewton(M);
        return
    end
    C = (-3 * g ^ 2 + 4 * g - 2) / (12 * (2 - g));
    W = eye(numel(x)) - d * h * M.J;
    ecart = W \ (C * 2 * h * ((f1 - fg) / (1 - g) - (fg - k1) / g));
    err = normeErreur(ecart, x, xNouveau, atol, rtol);
end

% La matrice qui réécrit les différences arrière 1 à K d'une grille de pas
% H sur la grille de pas RHO*H : la valeur en t - m*RHO*H du polynôme
% qu'elles décrivent, puis ses différences.
function R = changementDePas(K, rho)
    R = zeros(K, K);
    for j = 1:K
        binome = 1;
        for m = 0:j
            if m > 0
                binome = binome * (j - m + 1) / m;
            end
            s = -m * rho;
            beta = 1;
            for i = 1:K
                beta = beta * (s + i - 1) / i;
                R(i, j) = R(i, j) + (-1) ^ m * binome * beta;
            end
        end
    end
end

% ode15s : les NDF de Klopfenstein et Shampine. La formule d'ordre k,
%   (1 - kappa) g_k (X1 - X0) + somme(g_j D_j) = H F(X1),
% où X0 est la prédiction, D_j les différences arrière et g_j = 1 + ... +
% 1/j, se résout par Newton ; X1 - X0 est la différence d'ordre k + 1, et
% donne l'erreur.
function [xNouveau, err, V, Z, aux] = pasNDF(T, M, V, Z, x, k1, t, h, atol, rtol, touche)
    kappa = [-0.1850, -1/9, -0.0823, -0.0415, 0];
    G = cumsum(1 ./ (1:5));
    H = M.H;
    if H.valide
        k = H.k;
        D = H.D;
        if h ~= H.h
            D(:, 1:k) = D(:, 1:k) * changementDePas(k, h / H.h);
        end
    else
        k = 1;
        D = zeros(numel(x), M.ordreMax + 2);
        D(:, 1) = h * k1;
    end
    inverse = 1 / ((1 - kappa(k)) * G(k));
    prediction = x + sum(D(:, 1:k), 2);
    psi = (D(:, 1:k) * G(1:k).') * inverse;
    [xNouveau, fin, converge, V, Z] = implicite(T, M, V, Z, prediction - psi, inverse, h, ...
                                                t + h, prediction, atol, rtol, touche);
    aux = struct('D', D, 'k', k, 'h', h, 'ecart', xNouveau - prediction, 'fin', fin);
    if ~converge
        err = echecNewton(M);
        return
    end
    err = normeErreur(constanteNDF(k) * aux.ecart, x, xNouveau, atol, rtol);
end

function e = constanteNDF(k)
    kappa = [-0.1850, -1/9, -0.0823, -0.0415, 0];
    G = cumsum(1 ./ (1:5));
    e = kappa(k) * G(k) + 1 / (k + 1);
end

% Les coefficients des formules d'Adams : GS(j+1), ceux de la formule
% explicite, et GI(j+1) = GS(j+1) - GS(j), ceux de la formule implicite.
function [gs, gi] = coefficientsAdams(n)
    gs = zeros(1, n);
    gs(1) = 1;
    for j = 1:n - 1
        gs(j + 1) = 1 - sum(gs(1:j) ./ (j + 1:-1:2));
    end
    gi = [1, diff(gs)];
end

% ode113 : Adams-Bashforth d'ordre k prédit, Adams-Moulton corrige, en
% une évaluation de plus (PECE). La mémoire est faite des différences
% arrière des dérivées ; la correction est H*GS(k+1)*(la différence
% d'ordre k de la dérivée prédite), l'erreur la même différence pesée par
% le coefficient implicite.
function [xNouveau, err, V, Z, aux] = pasAdams(T, M, V, Z, x, k1, t, h, atol, rtol, touche)
    H = M.H;
    if H.valide
        k = H.k;
        F = H.D;
        if h ~= H.h && k > 1
            F(:, 2:k) = F(:, 2:k) * changementDePas(k - 1, h / H.h);
        end
    else
        k = 1;
        F = zeros(numel(x), M.ordreMax + 2);
        F(:, 1) = k1;
    end
    [gs, gi] = coefficientsAdams(M.ordreMax + 2);
    prediction = x + h * (F(:, 1:k) * gs(1:k).');
    if ~isempty(T.bornes)
        prediction = borner(T, prediction);
    end
    [V, Z] = passe(T, T.listeMineure, V, Z, prediction, t + h, 0, false, touche);
    difference = derivees(T, V, prediction, t + h) - sum(F(:, 1:k), 2);
    % La solution n'est pas tenue dans ses bornes ici : c'est le pas
    % majeur qui l'y ramène, et la mémoire, qui ne la prolonge plus, repart.
    xNouveau = prediction + h * gs(k + 1) * difference;
    [V, Z] = passe(T, T.listeMineure, V, Z, xNouveau, t + h, 0, false, touche);
    fin = derivees(T, V, xNouveau, t + h);
    aux = struct('D', F, 'k', k, 'h', h, 'fin', fin);
    err = normeErreur(h * gi(k + 1) * difference, x, xNouveau, atol, rtol);
end

% Un pas réussi d'un solveur à pas multiples : les différences avancent
% d'un cran, puis l'ordre et le pas du suivant se choisissent. Comme dans
% ode15s, on ne les change qu'après k + 2 pas égaux : la mémoire sert
% mieux à pas constant. L'ordre voisin gagne s'il permet un plus grand
% pas ; le pas ne grandit que si l'erreur le permet nettement. FACTEUR
% rapporte le pas suivant à celui qu'on vient de faire.
function [M, facteur] = retenirPas(M, aux, xNouveau, err, atol, rtol)
    H = M.H;
    k = aux.k;
    D = aux.D;
    h = aux.h;
    memePas = H.valide && h == H.h && k == H.k;
    constants = 1;
    if memePas
        constants = H.nconst + 1;
    end
    Dn = zeros(size(D));
    if strcmp(M.methode, 'ndf')
        Dn(:, k + 1) = aux.ecart;
        Dn(:, k + 2) = aux.ecart - D(:, k + 1);
        for j = k:-1:1
            Dn(:, j) = D(:, j) + Dn(:, j + 1);
        end
        erreurDe = @(q) normeErreur(constanteNDF(q) * Dn(:, q + 1), xNouveau, xNouveau, ...
                                    atol, rtol);
    else
        Dn(:, 1) = aux.fin;
        for j = 1:k + 1
            Dn(:, j + 1) = Dn(:, j) - D(:, j);
        end
        [~, gi] = coefficientsAdams(M.ordreMax + 2);
        erreurDe = @(q) normeErreur(h * gi(q + 1) * Dn(:, q + 1), xNouveau, xNouveau, ...
                                    atol, rtol);
    end
    facteur = 1;
    kNouveau = k;
    if constants >= k + 2
        meilleur = 1 / max(1.2 * max(err, 1e-10) ^ (1 / (k + 1)), 0.1);
        if k > 1
            f = 1 / max(1.3 * max(erreurDe(k - 1), 1e-10) ^ (1 / k), 0.1);
            if f > meilleur
                meilleur = f;
                kNouveau = k - 1;
            end
        end
        if k < M.ordreMax
            f = 1 / max(1.4 * max(erreurDe(k + 1), 1e-10) ^ (1 / (k + 2)), 0.1);
            if f > meilleur
                meilleur = f;
                kNouveau = k + 1;
            end
        end
        if kNouveau ~= k
            facteur = meilleur;
        elseif meilleur > 1
            facteur = meilleur;
        end
    end
    M.H = struct('valide', true, 'k', kNouveau, 'h', h, 'D', Dn, 'nconst', constants, ...
                 'fin', aux.fin);
    M.ordre = kNouveau + 1;
end

% Le jacobien des dérivées par rapport aux états, et leur dérivée par
% rapport au temps, par différences finies.
function [Jac, dfdt, V, Z] = jacobien(T, V, Z, x, f0, t, touche)
    nx = numel(x);
    Jac = zeros(nx, nx);
    for j = 1:nx
        xp = x;
        delta = sqrt(eps) * max(abs(x(j)), 1);
        xp(j) = xp(j) + delta;
        [V, Z] = passe(T, T.listeMineure, V, Z, xp, t, 0, false, touche);
        Jac(:, j) = (derivees(T, V, xp, t) - f0) / delta;
    end
    dt = sqrt(eps) * max(abs(t), 1);
    [V, Z] = passe(T, T.listeMineure, V, Z, x, t + dt, 0, false, touche);
    dfdt = (derivees(T, V, x, t + dt) - f0) / dt;
end

% Le premier pas, estimé comme le proposent Hairer, Nørsett et Wanner : à
% partir de la taille de l'état et de ses deux premières dérivées.
function [h, V, Z] = pasInitial(T, V, Z, x, k1, t, borne, atol, rtol, ordre, touche)
    echelle = atol + rtol * abs(x);
    d0 = max(abs(x) ./ echelle);
    d1 = max(abs(k1) ./ echelle);
    if d0 < 1e-5 || d1 < 1e-5
        h0 = 1e-6;
    else
        h0 = 0.01 * d0 / d1;
    end
    h0 = min(h0, borne);
    x1 = x + h0 * k1;
    [V, Z] = passe(T, T.listeMineure, V, Z, x1, t + h0, 0, false, touche);
    d2 = max(abs(derivees(T, V, x1, t + h0) - k1) ./ echelle) / h0;
    if max(d1, d2) <= 1e-15
        h1 = max(1e-6, h0 * 1e-3);
    else
        h1 = (0.01 / max(d1, d2)) ^ (1 / ordre);
    end
    h = min([100 * h0, h1, borne]);
end

% La dichotomie qui localise un passage par zéro : le plus petit pas au
% bout duquel un seuil a changé de signe, à la tolérance près.
function [bas, haut, V, Z] = localiser(T, M, V, Z, x, k1, t, h, atol, rtol, avant, touche, ...
                                      discret)
    bas = 0;
    haut = h;
    tolerance = max(10 * toleranceTemps(t), 64 * eps(abs(t) + h));
    while haut - bas > tolerance
        milieu = (bas + haut) / 2;
        xm = x;
        if ~discret
            [xm, ~, V, Z] = unPas(T, M, V, Z, x, k1, t, milieu, atol, rtol, touche);
        end
        [V, Z] = passe(T, T.listeMineure, V, Z, xm, t + milieu, 0, false, touche);
        if any(sign(avant) .* sign(passagesZero(T, V, Z, xm, t + milieu)) < 0)
            haut = milieu;
        else
            bas = milieu;
        end
    end
end

% La prochaine cassure d'une source après t : un instant d'échelon, le
% début d'une rampe, un instant d'un signal tenu de l'espace de travail,
% un front de générateur d'impulsions.
function tc = prochaineCassure(T, t)
    tc = Inf;
    tol = toleranceTemps(t);
    if ~isempty(T.cassures)
        j = find(T.cassures > t + tol, 1);
        if ~isempty(j)
            tc = T.cassures(j);
        end
    end
    for k = T.impulsions
        p = T.pA(k);
        w = T.oB(k) - T.oA(k) + 1;
        if T.code(k) == 18
            % carré : un front chaque demi-période ; dent de scie : une
            % chute chaque période, décalée d'une demi
            for i = 1:w
                periode = 2 * pi / T.P(p + w + i - 1);
                if T.sub(k) == 2
                    pas = periode / 2;
                    tc = min(tc, (floor(t / pas + 1e-9) + 1) * pas);
                else
                    tc = min(tc, (floor((t - periode / 2) / periode + 1e-9) + 1) * periode + ...
                                 periode / 2);
                end
            end
            continue
        end
        for i = 1:w
            periode = T.P(p + w + i - 1);
            largeur = T.P(p + 2 * w + i - 1) / 100 * periode;
            retard = T.P(p + 3 * w + i - 1);
            if t + tol < retard
                tc = min(tc, retard);
                continue
            end
            base = retard + floor((t - retard) / periode + 1e-9) * periode;
            for candidat = [base + largeur, base + periode, base + periode + largeur]
                if candidat > t + tol
                    tc = min(tc, candidat);
                    break
                end
            end
        end
    end
end

% Les seuils que surveille la détection des passages par zéro : pour
% chaque bloc à cassure, l'écart entre ce qui le fait basculer et son
% seuil. Ce sont ceux de Simulink — Abs, Sign, Relational Operator,
% MinMax, Saturation, Dead Zone, Relay, Switch, Hit Crossing, Backlash,
% Coulomb Friction, Compare To Zero et To Constant, et les bornes d'un
% intégrateur.
function g = passagesZero(T, V, Z, x, t) %#ok<INUSD>
    g = zeros(0, 1);
    for k = T.zc
        p = T.pA(k);
        e = T.eD(k);
        u = V(T.eA(e + 1):T.eB(e + 1));
        w = T.oB(k) - T.oA(k) + 1;
        switch T.code(k)
            case {23, 24, 47, 53}   % abs, sign, coulomb, compare to zero
                g = [g; u(:)]; %#ok<AGROW>
            case {52, 45}   % compare to constant, hit crossing
                g = [g; u(:) - T.P(p:p + w - 1)]; %#ok<AGROW>
            case 51   % relational
                g = [g; u(:) - V(T.eA(e + 2):T.eB(e + 2))]; %#ok<AGROW>
            case 27   % minmax : chaque paire d'entrées
                nIn = T.P(p);
                for a = 1:nIn - 1
                    ua = V(T.eA(e + a):T.eB(e + a));
                    for b = a + 1:nIn
                        g = [g; ua(:) - V(T.eA(e + b):T.eB(e + b))]; %#ok<AGROW>
                    end
                end
            case {40, 41, 42}   % saturation, dead zone, relay : deux seuils
                g = [g; u(:) - T.P(p:p + w - 1); u(:) - T.P(p + w:p + 2 * w - 1)]; %#ok<AGROW>
            case 46   % backlash : les deux bords du jeu
                y = Z(T.zA(k):T.zA(k) + w - 1);
                demi = T.P(p:p + w - 1) / 2;
                g = [g; u(:) - y - demi; u(:) - y + demi]; %#ok<AGROW>
            case 60   % switch
                u2 = V(T.eA(e + 2):T.eB(e + 2));
                if T.sub(k) == 3
                    g = [g; u2(:)]; %#ok<AGROW>
                else
                    g = [g; u2(:) - T.P(p + 1:p + T.P(p))]; %#ok<AGROW>
                end
            case 113   % garde : l'entrée Enable, le signal du Trigger
                rang = 0;
                if T.P(p) ~= 0
                    rang = 1;
                    g = [g; u(:)]; %#ok<AGROW>
                end
                if T.P(p + 1) > 0
                    ut = V(T.eA(e + rang + 1):T.eB(e + rang + 1));
                    g = [g; ut(:)]; %#ok<AGROW>
                end
            case 70   % intégrateur : ses bornes, sa dérivée s'il y est tenu, sa remise
                if T.P(p) ~= 0
                    xk = x(T.xA(k):T.xB(k));
                    g = [g; xk - T.P(p + 1:p + w); xk - T.P(p + 1 + w:p + 2 * w)]; %#ok<AGROW>
                    if isfield(T, 'satures')
                        g = [g; (u(:) + zeros(w, 1)) .* T.satures(T.xA(k):T.xB(k))]; %#ok<AGROW>
                    end
                end
                remise = T.P(p + 2 * w + 1);
                if remise >= 1 && remise <= 3
                    r = V(T.eA(e + 2):T.eB(e + 2));
                    g = [g; r(:)]; %#ok<AGROW>
                end
        end
    end
end

% À pas variable, un intégrateur borné décide au pas majeur s'il est tenu
% à sa borne — il y est, et sa dérivée pousse au-delà —, et s'y tient
% pendant tout le pas, comme dans Simulink : un état qui franchit la borne
% à un pas mineur continue sa course, le passage par zéro le localise, et
% le pas majeur qui suit le ramène à la borne.
function T = figerBornes(T, V, x)
    satures = false(numel(x), 1);
    for k = T.bornes
        a = T.xA(k);
        b = T.xB(k);
        p = T.pA(k);
        w = b - a + 1;
        e = T.eD(k);
        u = V(T.eA(e + 1):T.eB(e + 1)) + zeros(w, 1);
        xk = x(a:b);
        satures(a:b) = (xk >= T.P(p + 1:p + w) & u > 0) | ...
                       (xk <= T.P(p + 1 + w:p + 2 * w) & u < 0);
    end
    T.satures = satures;
end

% Le retard pur à pas variable : les pas n'ont pas tous la même durée, le
% tampon garde donc les instants avec les valeurs, en anneau. On y cherche
% par dichotomie les deux échantillons qui encadrent t - retard, et l'on
% interpole entre eux.
function y = retardVariable(T, k, p, t, w)
    B = T.tampons(k);
    if B.n == 0
        y = T.P(p + 2:p + 1 + w);
        return
    end
    cible = t - T.P(p);
    L = numel(B.t);
    ancien = mod(B.tete - B.n - 1, L) + 1;
    recent = mod(B.tete - 2, L) + 1;
    if cible < B.t(ancien)
        y = T.P(p + 2:p + 1 + w);
        return
    end
    if cible >= B.t(recent)
        y = B.v(:, recent);
        return
    end
    bas = 0;
    haut = B.n - 1;
    while haut - bas > 1
        milieu = floor((bas + haut) / 2);
        if B.t(mod(ancien + milieu - 1, L) + 1) <= cible
            bas = milieu;
        else
            haut = milieu;
        end
    end
    i0 = mod(ancien + bas - 1, L) + 1;
    i1 = mod(ancien + haut - 1, L) + 1;
    y = B.v(:, i0);
    if B.t(i1) > B.t(i0)
        f = (cible - B.t(i0)) / (B.t(i1) - B.t(i0));
        y = (1 - f) * y + f * B.v(:, i1);
    end
end

% Une valeur de plus dans le tampon d'un retard pur. Plein, il écrase le
% plus ancien échantillon s'il ne sert plus ; sinon il double, comme le
% bloc de Simulink qui alloue au-delà de sa taille initiale.
function pousserRetard(T, k, p, t, u)
    tampons = T.tampons;
    B = tampons(k);
    L = numel(B.t);
    if B.n == L
        ancien = B.tete;   % plein : la tête est aussi le plus ancien
        suivant = mod(ancien, L) + 1;
        if B.t(suivant) > t - T.P(p)
            % Le plus ancien sert encore : on déroule l'anneau et l'on double.
            ordre = [ancien:L, 1:ancien - 1];
            B.t = [B.t(ordre); zeros(L, 1)];
            B.v = [B.v(:, ordre), zeros(size(B.v, 1), L)];
            B.tete = L + 1;
            L = 2 * L;
        else
            B.n = B.n - 1;
        end
    end
    B.t(B.tete) = t;
    B.v(:, B.tete) = u;
    B.tete = mod(B.tete, L) + 1;
    B.n = B.n + 1;
    tampons(k) = B;
end

% === un point ==================================================================

function [y, dx] = point(T, x, u)
    T.graphes = containers.Map('KeyType', 'double', 'ValueType', 'any');
    T.iterateurs = containers.Map('KeyType', 'double', 'ValueType', 'any');
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
    dx = derivees(T, V, x(:), T.tDebut);
    y = V(T.sortiesModele);
end

% === la passe de sortie =======================================================
%
% Chaque bloc de la liste calcule sa sortie, dans l'ordre : ce qu'il lit
% est déjà calculé. Un nombre négatif dans la liste est une boucle
% algébrique, résolue là. MAJEUR dit si c'est un pas majeur ; TOUCHE,
% quels groupes de période tombent à cet instant.
function [V, Z] = passe(T, liste, V, Z, x, t, i, majeur, touche)
    gele = T.gele;
    gardes = T.garde;
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
        gk = gardes(k);
        if gk > 0 && V(oA(gk)) == 0
            % Le sous-système ne calcule pas : le bloc tient sa sortie — une
            % garde emboîtée s'éteint, une sortie « reset » revient à sa
            % valeur initiale.
            if code(k) == 113
                V(a) = 0;
            elseif T.revient(k)
                V(a:b) = T.initiale{k};
            elseif T.zTenue(k) > 0
                V(a:b) = Z(T.zTenue(k):T.zTenue(k) + b - a);
            end
            continue
        end
        if gele(k)
            if ~majeur
                V(a:b) = sortieGelee(T, k, V, Z, a, b, p, e);
                continue
            end
            Z = noterMode(T, k, V, Z, b - a + 1, p, e);
        end
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
                    case 15   % chirp : la fréquence va de f1 à f2 en T
                        w = b - a + 1;
                        f1 = T.P(p:p + w - 1);
                        cible = T.P(p + w:p + 2 * w - 1);
                        f2 = T.P(p + 2 * w:p + 3 * w - 1);
                        V(a:b) = sin(2 * pi * (f1 * t + (f2 - f1) ./ (2 * cible) * t ^ 2));
                    case {16, 17}   % counters
                        V(a) = Z(zA(k));
                    case 18   % signal generator
                        w = b - a + 1;
                        amplitude = T.P(p:p + w - 1);
                        tours = T.P(p + w:p + 2 * w - 1) * t / (2 * pi);
                        % Le carré et la dent de scie cassent : à pas variable, le
                        % morceau où l'on est se fige au pas majeur, et les pas
                        % mineurs le prolongent jusqu'à la cassure, où le pas
                        % s'arrête.
                        switch sub(k)
                            case 1
                                V(a:b) = amplitude .* sin(2 * pi * tours);
                            case 2
                                morceau = floor(2 * tours + 1e-9);
                                if ~T.fixe
                                    if majeur
                                        Z(zA(k):zA(k) + w - 1) = morceau;
                                    else
                                        morceau = Z(zA(k):zA(k) + w - 1);
                                    end
                                end
                                V(a:b) = amplitude .* (1 - 2 * mod(morceau, 2));
                            case 3
                                phase = tours + 0.5;
                                morceau = floor(phase + 1e-9);
                                if ~T.fixe
                                    if majeur
                                        Z(zA(k):zA(k) + w - 1) = morceau;
                                    else
                                        morceau = Z(zA(k):zA(k) + w - 1);
                                    end
                                end
                                V(a:b) = amplitude .* (2 * (phase - morceau) - 1);
                            otherwise
                                V(a:b) = Z(zA(k) + w:zA(k) + 2 * w - 1);
                        end
                    case 19   % repeating sequence stair
                        V(a) = T.P(p + 1 + Z(zA(k)));
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
                    case 34   % data type conversion
                        V(a:b) = convertirType(T.P(p), T.P(p + 1), T.P(p + 2), u);
                    case 35   % wrap to zero
                        V(a:b) = u .* (u <= T.P(p:p + b - a));
                    case 36   % interval test
                        w = b - a + 1;
                        haut = T.P(p:p + w - 1);
                        bas = T.P(p + w:p + 2 * w - 1);
                        if T.P(p + 2 * w) ~= 0
                            dessous = u <= haut;
                        else
                            dessous = u < haut;
                        end
                        if T.P(p + 2 * w + 1) ~= 0
                            dessus = u >= bas;
                        else
                            dessus = u > bas;
                        end
                        V(a:b) = double(dessous & dessus);
                    case 37   % saturation dynamic : up, u, lo
                        V(a:b) = min(max(V(eA(e + 2):eB(e + 2)), V(eA(e + 3):eB(e + 3))), u);
                    case 38   % dead zone dynamic : up, u, lo
                        v = V(eA(e + 2):eB(e + 2));
                        lo = V(eA(e + 3):eB(e + 3));
                        V(a:b) = (v > u) .* (v - u) + (v < lo) .* (v - lo);
                    case 39   % manual switch
                        V(a:b) = V(eA(e + sub(k)):eB(e + sub(k)));
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
                    case 57   % IC : sa valeur au premier instant, puis l'entrée
                        if Z(zA(k)) == 0
                            V(a:b) = T.P(p:p + b - a);
                        else
                            V(a:b) = u;
                        end
                    case 58   % width
                        V(a) = T.P(p);
                    case 59   % data store read
                        z = zA(T.P(p));
                        V(a:b) = Z(z:z + T.P(p + 1) - 1);
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
                        if majeur && T.zTenue(k) > 0
                            Z(T.zTenue(k):T.zTenue(k) + b - a) = V(a:b);
                        end
                    case 69   % data store write : aux pas majeurs
                        if majeur
                            z = zA(T.P(p));
                            largeur = T.P(p + 1);
                            Z(z:z + largeur - 1) = V(eA(e + 1):eB(e + 1)) + zeros(largeur, 1);
                        end
                end
            case 7
                switch code(k)
                    case 77   % second-order integrator : x, puis dx/dt
                        w = T.P(p);
                        xa = T.xA(k);
                        V(a:b) = x(xa:xa + w - 1);
                        gp = T.pd(k) + 1;
                        V(T.poA(gp):T.poB(gp)) = x(xa + w:xa + 2 * w - 1);
                    case 70   % integrator
                        if T.P(p) == 0
                            V(a:b) = x(T.xA(k):T.xB(k));
                        else
                            w = b - a + 1;
                            V(a:b) = min(max(x(T.xA(k):T.xB(k)), T.P(p + 1 + w:p + 2 * w)), ...
                                         T.P(p + 1:p + w));
                        end
                        if T.nOut(k) > 1
                            V = portsIntegrateur(T, k, V, Z, t, p, a, b);
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
                        elseif T.fixe
                            V(a:b) = retardPur(T, p, Z, zA(k), t, b - a + 1);
                        else
                            V(a:b) = retardVariable(T, k, p, t, b - a + 1);
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
                    case 87   % discrete derivative : K u / Ts - K u d'avant / Ts
                        V(a:b) = T.P(p:p + b - a) .* V(eA(e + 1):eB(e + 1)) - ...
                                 Z(zA(k):zA(k) + b - a);
                    case 88   % tapped delay : les N dernières valeurs
                        N = T.P(p);
                        valeurs = Z(zA(k):zA(k) + N - 1);
                        if T.P(p + 2) ~= 0
                            valeurs = [valeurs; V(eA(e + 1))];
                        end
                        if T.P(p + 1) ~= 0
                            valeurs = valeurs(end:-1:1);
                        end
                        V(a:b) = valeurs;
                    case 89   % difference
                        V(a:b) = V(eA(e + 1):eB(e + 1)) - Z(zA(k):zA(k) + b - a);
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
            case 10
                switch code(k)
                    case 100   % fcn
                        V(a) = T.objets{k}(V(eA(e + 1):eB(e + 1)));
                    case 102   % interpreted MATLAB function
                        y = T.objets{k}(V(eA(e + 1):eB(e + 1)));
                        V(a:b) = double(y(:));
                    case 101   % MATLAB function : ses arguments, ses sorties
                        V = appelerFonction(T, k, V, p, e);
                    case 103   % S-function : les sorties, drapeau 3
                        if T.P(p + 2) > 0
                            sys = appelerSFonction(T, k, V, Z, x, t, 3);
                            V(a:b) = double(sys(:));
                        end
                    case 104   % chart : un pas de la machine, puis ses sorties
                        V = pasGraphe(T, k, V, p, e, t);
                    case 105   % sous-système itéré
                        V = iterer(T, k, V, e, t);
                    case {106, 107}   % for iterator, while iterator : le rang, s'il le montre
                        if a > 0
                            V(a) = T.P(p);
                        end
                    case 108   % function-call generator
                        V(a) = double(estInstant(t, T.P(p), T.P(p + 1)));
                end
            case 12
                switch code(k)
                    case 120   % direct lookup : l'élément désigné, à partir de 0
                        lignes = T.P(p + 1);
                        u = V(eA(e + 1):eB(e + 1));
                        i = min(max(floor(u), 0), lignes - 1);
                        if T.P(p) == 1
                            V(a:b) = T.P(p + 3 + i);
                        else
                            j = min(max(floor(V(eA(e + 2):eB(e + 2))), 0), T.P(p + 2) - 1);
                            V(a:b) = T.P(p + 3 + i + j * lignes);
                        end
                end
            case 11
                switch code(k)
                    case {110, 111}   % if, switch case : une sortie d'action par branche
                        choisi = brancheChoisie(T, k, V, p, e);
                        pd = T.pd(k);
                        for q2 = 1:T.nOut(k)
                            V(T.poA(pd + q2 - 1)) = double(q2 == choisi);
                        end
                    case 112   % merge : l'entrée dont le sous-système vient de calculer
                        nIn = T.P(p);
                        w = b - a + 1;
                        for j = 1:nIn
                            g = T.P(p + w + j);
                            if g == 0 || V(oA(g)) ~= 0
                                V(a:b) = V(eA(e + j):eB(e + j)) + zeros(w, 1);
                            end
                        end
                    case 113   % garde d'un sous-système conditionnel
                        V(a) = double(gardeActive(T, k, V, Z, p, e));
                    case 118   % rate transition : tenue, ou retard d'une période lente
                        if sub(k) == 1
                            V(a:b) = V(eA(e + 1):eB(e + 1));
                        else
                            % Z : [tenue; entrée prise à l'instant lent d'avant]. À
                            % un instant lent, la sortie devient cette entrée.
                            w = b - a + 1;
                            if estInstant(t, T.P(p), T.P(p + 1))
                                V(a:b) = Z(zA(k) + w:zA(k) + 2 * w - 1);
                            else
                                V(a:b) = Z(zA(k):zA(k) + w - 1);
                            end
                        end
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

% --- les blocs de code

% Un sous-système itéré : son modèle, compilé à part, calcule N fois — For
% Iterator — ou tant que son entrée cond est vraie — While Iterator —, ses
% blocs à état avançant à chaque itération. Les sorties sont celles de la
% dernière. Les états tiennent d'un pas à l'autre (held), ou repartent
% (reset). Un pas majeur refait après une remise ne l'itère pas deux fois.
function V = iterer(T, k, V, e, t)
    O = T.objets{k};
    Ti = O.T;
    if isKey(T.iterateurs, k)
        etat = T.iterateurs(k);
    else
        etat = struct('V', Ti.V0, 'Z', Ti.Z0, 't', NaN, 'sorties', {{}});
    end
    if etat.t == t
        V = poserSorties(T, k, V, etat.sorties);
        return
    end
    if O.remise
        etat.Z = Ti.Z0;
    end
    for j = 1:numel(O.entrees)
        q = Ti.pA(O.entrees(j));
        largeur = Ti.oB(O.entrees(j)) - Ti.oA(O.entrees(j)) + 1;
        Ti.P(q:q + largeur - 1) = V(T.eA(e + j):T.eB(e + j)) + zeros(largeur, 1);
    end
    touche = true(1, size(Ti.groupes, 1));
    vide = zeros(0, 1);
    qi = Ti.pA(O.iter);
    ei = Ti.eD(O.iter);
    Vi = etat.V;
    Zi = etat.Z;
    if O.pour
        N = O.N;
        if O.externe
            % le nombre d'itérations se lit à l'entrée du For Iterator
            Ti.P(qi) = 1 - O.zero;
            [Vt, ~] = passe(Ti, Ti.listeTout, Vi, Zi, vide, t, 0, true, touche);
            N = round(Vt(Ti.eA(ei + 1)));
        end
        faits = 0;
        for rang = 1:N
            Ti.P(qi) = rang - O.zero;
            [Vi, Zi] = unTour(Ti, Vi, Zi, t, touche);
            faits = rang;
        end
    else
        encore = true;
        if ~O.faire
            % while : la condition initiale, à l'entrée IC, dit s'il faut
            % commencer
            Ti.P(qi) = 1;
            [Vt, ~] = passe(Ti, Ti.listeTout, Vi, Zi, vide, t, 0, true, touche);
            encore = Vt(Ti.eA(ei + 2)) ~= 0;
        end
        rang = 0;
        limite = O.max;
        if limite < 0
            limite = 1e6;
        end
        while encore
            rang = rang + 1;
            Ti.P(qi) = rang;
            [Vi, Zi] = unTour(Ti, Vi, Zi, t, touche);
            encore = Vi(Ti.eA(ei + 1)) ~= 0;
            if rang >= limite
                if O.max < 0 && encore
                    error('Simulink:blocks:WhileIteratorMaxIterations', ...
                          ['Le sous-systeme itere ''%s'' a fait un million d''iterations ' ...
                           'a t = %g sans que sa condition devienne fausse.'], ...
                          T.chemins{k}, t);
                end
                break
            end
        end
        faits = rang;
    end
    % Sans itération, les sorties tiennent : celles du pas d'avant, ou
    % leur valeur initiale.
    sorties = cell(1, numel(O.sorties));
    for j = 1:numel(O.sorties)
        o = O.sorties(j);
        plage = Ti.eA(Ti.eD(o) + 1):Ti.eB(Ti.eD(o) + 1);
        if faits > 0
            sorties{j} = Vi(plage);
        elseif ~isempty(etat.sorties)
            sorties{j} = etat.sorties{j};
        else
            sorties{j} = Ti.V0(plage);
        end
    end
    V = poserSorties(T, k, V, sorties);
    T.iterateurs(k) = struct('V', Vi, 'Z', Zi, 't', t, 'sorties', {sorties});
end

% Une itération : la passe des sorties, les remises, les mises à jour.
function [Vi, Zi] = unTour(Ti, Vi, Zi, t, touche)
    [Vi, Zi] = passe(Ti, Ti.listeTout, Vi, Zi, zeros(0, 1), t, 0, true, touche);
    if Ti.aRemettre
        [~, Zi, refaire] = remettre(Ti, Vi, Zi, zeros(0, 1), t);
        if refaire
            [Vi, Zi] = passe(Ti, Ti.listeTout, Vi, Zi, zeros(0, 1), t, 0, true, touche);
        end
    end
    Zi = majs(Ti, Vi, Zi, t, touche, zeros(0, 1));
end

function V = poserSorties(T, k, V, sorties)
    for j = 1:numel(sorties)
        gp = T.pd(k) + j - 1;
        V(T.poA(gp):T.poB(gp)) = sorties{j};
    end
end

% Une MATLAB Function : chaque entrée est un argument, chaque sortie un
% port, à la forme que l'appel d'essai a mesurée.
function V = appelerFonction(T, k, V, p, e)
    nIn = T.P(p);
    nOut = T.P(p + 1);
    u = cell(1, nIn);
    for j = 1:nIn
        u{j} = reshape(V(T.eA(e + j):T.eB(e + j)), T.formes{k}{j});
    end
    sorties = cell(1, nOut);
    [sorties{:}] = T.objets{k}(u{:});
    pd = T.pd(k);
    for q = 1:nOut
        a = T.poA(pd + q - 1);
        b = T.poB(pd + q - 1);
        y = double(sorties{q});
        if numel(y) ~= b - a + 1
            error('Simulink:blocks:MATLABFunctionOutputSize', ...
                  ['La sortie %d du bloc ''%s'' change de taille : %d valeur(s) au lieu ' ...
                   'de %d.'], q, T.chemins{k}, numel(y), b - a + 1);
        end
        V(a:b) = y(:);
    end
end

% Une S-fonction de niveau 1 : [sys,x0,str,ts] = f(t,x,u,flag,p1,...).
% Ses états sont les continus puis les discrets.
function sys = appelerSFonction(T, k, V, Z, x, t, drapeau)
    p = T.pA(k);
    nc = T.P(p);
    nd = T.P(p + 1);
    etats = zeros(nc + nd, 1);
    if nc > 0
        etats(1:nc) = x(T.xA(k):T.xB(k));
    end
    if nd > 0 && ~isempty(Z)
        etats(nc + 1:nc + nd) = Z(T.zA(k):T.zA(k) + nd - 1);
    end
    u = zeros(0, 1);
    if T.P(p + 3) ~= 0
        e = T.eD(k);
        u = V(T.eA(e + 1):T.eB(e + 1));
    end
    S = T.objets{k};
    sys = S.f(t, etats, u, drapeau, S.p{:});
end

% Un diagramme Stateflow fait un pas par instant : le premier le démarre
% dans son état initial, les suivants suivent la règle de SFSTEP. L'état
% actif et le contexte vivent dans les graphes du simulateur, une poignée
% que chaque simulation recrée ; un instant déjà vu ne refait pas le pas —
% une passe refaite au même instant rend les mêmes sorties.
function V = pasGraphe(T, k, V, p, e, t)
    graphes = T.graphes;
    G = T.objets{k};
    if isKey(graphes, k)
        etat = graphes(k);
    else
        etat = struct('courant', '', 'contexte', G.initial, 't', -Inf);
        if isempty(etat.contexte)
            etat.contexte = struct();
        end
    end
    if t > etat.t
        nIn = T.P(p);
        if nIn == 0
            u = [];
        elseif nIn == 1
            u = V(T.eA(e + 1):T.eB(e + 1));
        else
            u = cell(1, nIn);
            for j = 1:nIn
                u{j} = V(T.eA(e + j):T.eB(e + j));
            end
        end
        [etat.courant, etat.contexte] = sfstep(G.machine, etat.courant, etat.contexte, u);
        etat.t = t;
        graphes(k) = etat;
    end
    pd = T.pd(k);
    for q = 1:numel(G.sorties)
        a = T.poA(pd + q - 1);
        b = T.poB(pd + q - 1);
        if strcmp(G.sorties{q}, 'etat')
            V(a) = find(strcmp(G.noms, etat.courant), 1);
        else
            y = double(etat.contexte.(G.sorties{q}));
            if numel(y) ~= b - a + 1
                error('Simulink:blocks:ChartOutputSize', ...
                      ['La sortie ''%s'' du bloc Chart ''%s'' change de taille : %d ' ...
                       'valeur(s) au lieu de %d.'], G.sorties{q}, T.chemins{k}, numel(y), ...
                      b - a + 1);
            end
            V(a:b) = y(:);
        end
    end
end

% --- les sous-systèmes conditionnels

% La branche d'un If — la première condition vraie, sinon le « else » —
% ou d'un Switch Case — le premier cas qui contient l'entrée, sinon le
% défaut. 0 si aucune.
function choisi = brancheChoisie(T, k, V, p, e)
    choisi = 0;
    if T.code(k) == 110
        nIn = T.P(p);
        u = cell(1, nIn);
        for j = 1:nIn
            u{j} = V(T.eA(e + j):T.eB(e + j));
        end
        conditions = T.objets{k};
        for i = 1:numel(conditions)
            if conditions{i}(u{:})
                choisi = i;
                return
            end
        end
        if T.P(p + 2) ~= 0
            choisi = numel(conditions) + 1;
        end
        return
    end
    valeur = fix(V(T.eA(e + 1)));
    cas = T.objets{k};
    for i = 1:numel(cas)
        if any(cas{i} == valeur)
            choisi = i;
            return
        end
    end
    if T.P(p + 1) ~= 0
        choisi = numel(cas) + 1;
    end
end

% Un sous-système calcule si son Enable est positif, s'il vient d'y avoir
% un front de son Trigger, si son If ou son Switch Case l'a désigné. Un
% front se lit contre la valeur du pas majeur précédent : pas de front à
% la première évaluation, comme le réglage par défaut de Simulink.
function active = gardeActive(T, k, V, Z, p, e)
    active = true;
    rang = 0;
    if T.P(p) ~= 0
        rang = 1;
        active = any(V(T.eA(e + 1):T.eB(e + 1)) > 0);
    end
    front = T.P(p + 1);
    if front == 4
        % appelé par fonction : il calcule quand le générateur l'appelle
        rang = rang + 1;
        active = active && any(V(T.eA(e + rang):T.eB(e + rang)) ~= 0);
    elseif front > 0
        rang = rang + 1;
        u = V(T.eA(e + rang):T.eB(e + rang));
        z = T.zA(k);
        if Z(z) == 0
            active = false;
        else
            avant = Z(z + 2:z + 1 + numel(u));
            monte = (avant < 0 & u >= 0) | (avant == 0 & u > 0);
            descend = (avant > 0 & u <= 0) | (avant == 0 & u < 0);
            switch front
                case 1
                    declenche = any(monte);
                case 2
                    declenche = any(descend);
                otherwise
                    declenche = any(monte | descend);
            end
            active = active && declenche;
        end
    end
    if T.P(p + 2) ~= 0
        active = V(T.eA(e + 1)) ~= 0;
    end
end

% Un sous-système qui reprend avec StatesWhenEnabling (ou
% InitializeStates) à reset repart de ses conditions initiales : ses
% états, continus et discrets, y reviennent, et la passe se refait.
function [x, Z, refaire] = remettre(T, V, Z, x, t)
    refaire = false;
    for k = T.reinit
        [x, Z, remis] = remettreIntegrateur(T, k, V, Z, x, t);
        refaire = refaire || remis;
    end
    for g = T.remises
        z = T.zA(g);
        if V(T.oA(g)) ~= 0 && Z(z) ~= 0 && Z(z + 1) == 0
            for k = T.sousGarde{g}
                if T.xA(k) > 0
                    x(T.xA(k):T.xB(k)) = T.x0(T.xA(k):T.xB(k));
                end
                if T.zN(k) > 0
                    plage = T.zA(k):T.zA(k) + T.zN(k) - 1;
                    Z(plage) = T.Z0(plage);
                end
            end
            refaire = true;
        end
    end
end

% Un intégrateur à remise externe revient à sa condition initiale — le
% paramètre, ou la valeur de son entrée de condition initiale — au front
% que demande ExternalReset : montant, descendant, l'un ou l'autre ; ou
% tant que l'entrée de remise n'est pas nulle (level, level hold). Une
% condition initiale externe se lit aussi au premier instant. L'état
% d'avant la remise est gardé : le port d'état le rend à l'instant même,
% comme dans Simulink.
function [x, Z, remis] = remettreIntegrateur(T, k, V, Z, x, t)
    remis = false;
    g = T.garde(k);
    if g > 0 && V(T.oA(g)) == 0
        return   % sous-système à l'arrêt : l'état tient
    end
    p = T.pA(k);
    a = T.xA(k);
    b = T.xB(k);
    w = b - a + 1;
    q = p + 2 * w;
    remise = T.P(q + 1);
    externe = T.P(q + 2);
    wr = T.P(q + 3);
    z = T.zA(k);
    e = T.eD(k);
    if externe
        rang = 2 + (remise > 0);
        ci = V(T.eA(e + rang):T.eB(e + rang)) + zeros(w, 1);
    else
        ci = T.x0(a:b);
    end
    if T.P(p) ~= 0
        ci = min(max(ci, T.P(p + w + 1:p + 2 * w)), T.P(p + 1:p + w));
    end
    masque = false(w, 1);
    premier = Z(z) == 0;
    if remise > 0
        r = V(T.eA(e + 2):T.eB(e + 2));
        avant = Z(z + 1:z + wr);
        if premier
            avant = r;   % pas de front au premier instant
        end
        switch remise
            case 1
                d = (avant < 0 & r >= 0) | (avant == 0 & r > 0);
            case 2
                d = (avant > 0 & r <= 0) | (avant == 0 & r < 0);
            case 3
                d = (avant < 0 & r >= 0) | (avant == 0 & r ~= 0) | (avant > 0 & r <= 0);
            case 4
                d = r ~= 0 | (avant ~= 0 & r == 0);
            otherwise
                d = r ~= 0;
        end
        if numel(d) == w
            masque = d(:);
        else
            masque(:) = any(d);
        end
        Z(z + 1:z + wr) = r;
    end
    if premier
        Z(z) = 1;
        if externe
            x(a:b) = ci;
            remis = true;
        end
    end
    if any(masque)
        Z(z + wr + 1) = t;
        Z(z + wr + 2:z + wr + 1 + w) = V(T.oA(k):T.oB(k));
        rangs = a - 1 + find(masque);
        x(rangs) = ci(masque);
        remis = true;
    end
end

% Les ports de saturation et d'état d'un intégrateur. Le premier vaut 1 à
% la borne haute, -1 à la borne basse, 0 entre elles ; le second rend
% l'état — celui d'avant la remise, à l'instant d'une remise.
function V = portsIntegrateur(T, k, V, Z, t, p, a, b)
    w = b - a + 1;
    q = p + 2 * w;
    port = 2;
    if T.P(q + 4) ~= 0
        s = zeros(w, 1);
        if T.P(p) ~= 0
            y = V(a:b);
            s = double(y >= T.P(p + 1:p + w)) - double(y <= T.P(p + w + 1:p + 2 * w));
        end
        gp = T.pd(k) + port - 1;
        V(T.poA(gp):T.poB(gp)) = s;
        port = port + 1;
    end
    if T.P(q + 5) ~= 0
        valeur = V(a:b);
        if T.zN(k) > 0
            z = T.zA(k);
            wr = T.P(q + 3);
            if Z(z + wr + 1) == t
                valeur = Z(z + wr + 2:z + wr + 1 + w);
            end
        end
        gp = T.pd(k) + port - 1;
        V(T.poA(gp):T.poB(gp)) = valeur;
    end
end

% Une conversion de type : le signal reste un double, mais prend les valeurs
% que le type admet — arrondi selon le mode demandé, puis saturé ou
% replié modulo 2^n à la façon des entiers de Simulink.
function y = convertirType(type, arrondi, saturer, u)
    switch type
        case {1, 2}   % hérité, double : rien ne change
            y = u;
            return
        case 3
            y = double(single(u));
            return
        case 10
            y = double(u ~= 0);
            return
    end
    switch arrondi
        case 1
            v = fix(u);
        case 2   % Nearest : au plus proche, la moitié vers +inf
            v = floor(u + 0.5);
        case 3   % Round : au plus proche, la moitié loin de zéro
            v = round(u);
        case 4
            v = floor(u);
        case 5
            v = ceil(u);
        case 6   % Convergent : la moitié vers le pair
            v = round(u);
            moitie = abs(u - fix(u)) == 0.5;
            v(moitie) = 2 * round(u(moitie) / 2);
        otherwise
            v = fix(u);
    end
    bornes = [-128 127; 0 255; -32768 32767; 0 65535; -2147483648 2147483647; 0 4294967295];
    b = bornes(type - 3, :);
    if saturer
        y = min(max(v, b(1)), b(2));
    else
        etendue = b(2) - b(1) + 1;
        y = mod(v - b(1), etendue) + b(1);
    end
    y(isnan(u)) = 0;
end

% --- les modes figés du pas variable

% Le mode d'un bloc surveillé, vu au pas majeur : le côté de chaque seuil.
function Z = noterMode(T, k, V, Z, w, p, e)
    z = T.zmA(k);
    u = V(T.eA(e + 1):T.eB(e + 1)) + zeros(w, 1);
    switch T.code(k)
        case 23   % abs : la pente, +1 ou -1
            mode = 2 * (u >= 0) - 1;
        case {24, 51, 52, 53}   % sign, comparaisons : la valeur même
            switch T.code(k)
                case 24
                    mode = sign(u);
                case 51
                    mode = comparer(T.sub(k), u, V(T.eA(e + 2):T.eB(e + 2)));
                case 52
                    mode = comparer(T.sub(k), u, T.P(p:p + w - 1));
                otherwise
                    mode = comparer(T.sub(k), u, 0);
            end
        case 27   % minmax : le rang de l'entrée retenue
            U = entreesEnColonnes(T, V, e, T.P(p), w);
            if T.sub(k) == 1
                [~, mode] = min(U, [], 2);
            else
                [~, mode] = max(U, [], 2);
            end
        case {40, 41}   % saturation, zone morte : au-dessus, entre, au-dessous
            mode = (u > T.P(p:p + w - 1)) - (u < T.P(p + w:p + 2 * w - 1));
        case 47   % frottement : le signe
            mode = sign(u);
        otherwise   % switch : la première entrée passe-t-elle ?
            u2 = V(T.eA(e + 2):T.eB(e + 2));
            switch T.sub(k)
                case 1
                    mode = u2 >= T.P(p + 1:p + T.P(p));
                case 2
                    mode = u2 > T.P(p + 1:p + T.P(p));
                otherwise
                    mode = u2 ~= 0;
            end
            mode = double(mode) + zeros(w, 1);
    end
    Z(z:z + w - 1) = mode;
end

% La sortie d'un bloc surveillé à un pas mineur : la formule du côté où
% le pas majeur l'a trouvé, prolongée.
function y = sortieGelee(T, k, V, Z, a, b, p, e)
    w = b - a + 1;
    mode = Z(T.zmA(k):T.zmA(k) + w - 1);
    u = V(T.eA(e + 1):T.eB(e + 1)) + zeros(w, 1);
    switch T.code(k)
        case 23
            y = mode .* u;
        case {24, 51, 52, 53}
            y = mode;
        case 27
            U = entreesEnColonnes(T, V, e, T.P(p), w);
            y = U(sub2ind(size(U), (1:w).', mode));
        case 40
            y = u;
            haut = T.P(p:p + w - 1);
            bas = T.P(p + w:p + 2 * w - 1);
            y(mode > 0) = haut(mode > 0);
            y(mode < 0) = bas(mode < 0);
        case 41
            y = zeros(w, 1);
            haut = T.P(p:p + w - 1);
            bas = T.P(p + w:p + 2 * w - 1);
            y(mode > 0) = u(mode > 0) - haut(mode > 0);
            y(mode < 0) = u(mode < 0) - bas(mode < 0);
        case 47
            y = mode .* T.P(p:p + w - 1) + T.P(p + w:p + 2 * w - 1) .* u;
        otherwise
            y = V(T.eA(e + 3):T.eB(e + 3)) + zeros(w, 1);
            premier = V(T.eA(e + 1):T.eB(e + 1)) + zeros(w, 1);
            y(mode ~= 0) = premier(mode ~= 0);
    end
end

function U = entreesEnColonnes(T, V, e, nIn, w)
    U = zeros(w, nIn);
    for j = 1:nIn
        U(:, j) = V(T.eA(e + j):T.eB(e + j)) + zeros(w, 1);
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

function dx = derivees(T, V, x, t)
    dx = zeros(numel(x), 1);
    for k = T.continus
        g = T.garde(k);
        if g > 0 && V(T.oA(g)) == 0
            continue   % sous-système à l'arrêt : l'état tient
        end
        a = T.xA(k);
        b = T.xB(k);
        p = T.pA(k);
        e = T.eD(k);
        u = V(T.eA(e + 1):T.eB(e + 1));
        switch T.code(k)
            case 70   % integrator
                if T.P(p + 2 * (b - a + 1) + 1) == 5
                    % level hold : tenu à sa condition initiale tant que
                    % l'entrée de remise n'est pas nulle
                    r = V(T.eA(e + 2):T.eB(e + 2));
                    if numel(r) == b - a + 1
                        u = u + zeros(b - a + 1, 1);
                        u(r ~= 0) = 0;
                    elseif any(r ~= 0)
                        u = zeros(b - a + 1, 1);
                    end
                end
                if T.P(p) == 0
                    dx(a:b) = u;
                else
                    w = b - a + 1;
                    d = u + zeros(w, 1);
                    if isfield(T, 'satures')
                        d(T.satures(a:b)) = 0;
                    else
                        xk = x(a:b);
                        d(xk >= T.P(p + 1:p + w) & d > 0) = 0;
                        d(xk <= T.P(p + 1 + w:p + 2 * w) & d < 0) = 0;
                    end
                    dx(a:b) = d;
                end
            case {72, 73, 74}
                dx(a:b) = deriveeEtat(T, p, x(a:b), u);
            case 103   % S-function : les dérivées, drapeau 1
                sys = appelerSFonction(T, k, V, [], x, t, 1);
                dx(a:b) = double(sys(:));
            case 77   % second-order integrator : x' = dx, dx' = u
                w = (b - a + 1) / 2;
                dx(a:a + w - 1) = x(a + w:b);
                dx(a + w:b) = u + zeros(w, 1);
            case 76   % PID : l'intégrale, et le filtre de la dérivée
                w = (b - a + 1) / 2;
                dx(a:a + w - 1) = u;
                dx(a + w:b) = u - T.P(p + 3 * w:p + 4 * w - 1) .* x(a + w:b);
        end
    end
end

% === mises à jour ==============================================================

% T est-il un instant de la période P, décalée de D ? Au dix-milliardième
% près, pour que l'arrondi des pas ne le manque pas.
function oui = estInstant(t, P, D)
    if ~(P > 0) || ~isfinite(P)
        oui = true;
        return
    end
    rang = round((t - D) / P);
    oui = rang >= 0 && abs(t - D - rang * P) <= 1e-10 * max(1, abs(t));
end

function Z = majs(T, V, Z, t, touche, x)
    for k = T.aMettreAJour
        if T.mode(k) == 2 && ~touche(T.grp(k))
            continue
        end
        g = T.garde(k);
        if g > 0 && V(T.oA(g)) == 0
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
                if ~T.fixe
                    pousserRetard(T, k, p, t, u + zeros(w, 1));
                    continue
                end
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
            case 103   % S-function : les états discrets, drapeau 2
                nd = T.P(p + 1);
                if nd > 0
                    sys = appelerSFonction(T, k, V, Z, x, t, 2);
                    Z(z:z + nd - 1) = double(sys(:));
                end
            case 16   % counter free-running
                Z(z) = mod(Z(z) + 1, T.P(p));
            case 17   % counter limited
                if Z(z) >= T.P(p)
                    Z(z) = 0;
                else
                    Z(z) = Z(z) + 1;
                end
            case 18   % signal generator, random : le tirage suivant
                [valeurs, etats] = matlibre_sl_hasard(Z(z:z + w - 1), false, ...
                                                      -T.P(p:p + w - 1), T.P(p:p + w - 1));
                Z(z:z + w - 1) = etats;
                Z(z + w:z + 2 * w - 1) = valeurs;
            case 19   % repeating sequence stair
                Z(z) = mod(Z(z) + 1, T.P(p));
            case 57   % IC : le premier instant est passé
                Z(z) = 1;
            case 87   % discrete derivative
                Z(z:z + w - 1) = T.P(p:p + w - 1) .* u;
            case 88   % tapped delay
                N = T.P(p);
                Z(z:z + N - 2) = Z(z + 1:z + N - 1);
                Z(z + N - 1) = u(1);
            case 89   % difference
                Z(z:z + w - 1) = u;
            case 118   % rate transition vers le rapide : l'entrée, à ses instants
                if estInstant(t, T.P(p), T.P(p + 1))
                    Z(z:z + w - 1) = Z(z + w:z + 2 * w - 1);
                    Z(z + w:z + 2 * w - 1) = u;
                end
            case 113   % garde : ce qu'elle était, et le signal du front
                Z(z) = 1;
                Z(z + 1) = V(a);
                largeur = T.P(p + 4);
                if largeur > 0
                    rang = 1 + (T.P(p) ~= 0);
                    Z(z + 2:z + 1 + largeur) = V(T.eA(e + rang):T.eB(e + rang));
                end
        end
    end
end
