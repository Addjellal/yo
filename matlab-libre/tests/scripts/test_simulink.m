% test_simulink.m — le moteur de Simulink, bloc par bloc et en combinaison.
%
% Chaque vérification porte sur une propriété qui définit le calcul : une
% formule fermée, une invariance, un ordre de convergence mesuré, un
% message d'erreur qui nomme le bloc fautif. Les combinaisons sont
% engendrées : sources, traitements, dimensions, solveurs et périodes se
% croisent, et chaque croisement est comparé au calcul direct.
disp('--- simulink ---');

%% ------------------------------------------------ 1. Blocs sans memoire
% Chaque traitement sans mémoire, appliqué à une source connue, rend la
% fonction de la source — pour un scalaire comme pour un vecteur, avec
% tous les solveurs, en continu comme en échantillonné.
traitements = {
    'gain',        {'Gain', 3},                           @(u) 3 * u
    'gain',        {'Gain', [1; -2; 0.5]},                @(u) [1 -2 0.5] .* u
    'bias',        {'Bias', -1},                          @(u) u - 1
    'abs',         {},                                    @(u) abs(u)
    'sign',        {},                                    @(u) sign(u)
    'unaryminus',  {},                                    @(u) -u
    'saturation',  {'UpperLimit', 0.5, 'LowerLimit', -0.25}, @(u) min(max(u, -0.25), 0.5)
    'deadzone',    {'UpperValue', 0.3, 'LowerValue', -0.3},  ...
                   @(u) (u > 0.3) .* (u - 0.3) + (u < -0.3) .* (u + 0.3)
    'quantizer',   {'QuantizationInterval', 0.25},         @(u) 0.25 * round(u / 0.25)
    'math',        {'Operator', 'square'},                @(u) u .^ 2
    'math',        {'Operator', 'exp'},                   @(u) exp(u)
    'math',        {'Operator', 'reciprocal'},            @(u) 1 ./ (u + 3) .* 0 + 1 ./ u
    'trigonometry', {'Operator', 'cos'},                  @(u) cos(u)
    'trigonometry', {'Operator', 'atan'},                 @(u) atan(u)
    'rounding',    {'Operator', 'floor'},                 @(u) floor(u)
    'rounding',    {'Operator', 'fix'},                   @(u) fix(u)
    'polynomial',  {'coefs', [2 -1 0.5]},                 @(u) 2 * u .^ 2 - u + 0.5
    'coulombfriction', {'Offset', 0.5, 'Gain', 2},        @(u) sign(u) .* (2 * abs(u) + 0.5)
    'comparetozero', {'relop', '>'},                      @(u) double(u > 0)
    'comparetoconstant', {'relop', '<=', 'const', 0.2},   @(u) double(u <= 0.2)
    'lookup',      {'BreakpointsData', [-1 0 1], 'TableData', [2 0 1]}, ...
                   @(u) interp1([-1 0 1], [2 0 1], min(max(u, -1), 1))
    'sqrt',        {'Operator', 'signedSqrt'},            @(u) sign(u) .* sqrt(abs(u))
};
% La réciproque a son pôle en zéro : on la décale pour qu'elle reste finie.
traitements{12, 3} = @(u) 1 ./ u;
% Chaque source se donne avec sa formule, sur une voie ou sur trois : sur
% trois, chaque voie est décalée de la précédente par son biais, sa pente
% ou sa valeur finale. La formule est écrite comme le simulateur calcule,
% pour que les seuils des blocs discontinus tombent du même côté.
sources = {
    'sine',     {'Amplitude', 1.5, 'Frequency', 2, 'Phase', 0.3}, ...
                @(t, b) 1.5 * sin(2 * t + 0.3) + b, {0, [0 0.2 -0.3]}
    'ramp',     {'Slope', 0.7, 'Start', 0.1, 'InitialOutput', -0.4}, ...
                @(t, b) (t >= 0.1) .* (b .* (t - 0.1)) - 0.4, {0.7, [0.7 0.35 -0.2]}
    'step',     {'Time', 0.35, 'Before', -0.6, 'After', 0.9}, ...
                @(t, b) -0.6 + (t >= 0.35) .* (b + 0.6), {0.9, [-0.6 0.1 1.2]}
};
combinaisons = 0;
for i = 1:size(sources, 1)
    for j = 1:size(traitements, 1)
        for dimension = [1 3]
            for solveur = {'ode1', 'ode4'}
                for echantillonne = [false true]
                    parametresSource = sources{i, 2};
                    if dimension == 3
                        % Trois voies : la même source, décalée d'une voie
                        % à l'autre par son biais ou sa pente.
                        parametresSource = etendreSource(sources{i, 1}, parametresSource);
                    elseif strcmp(traitements{j, 1}, 'gain') && numel(traitements{j, 2}{2}) > 1
                        continue   % un gain vecteur demande un signal vecteur
                    end
                    if strcmp(traitements{j, 1}, 'math') && ...
                            strcmp(traitements{j, 2}{2}, 'reciprocal') && ...
                            ~strcmp(sources{i, 1}, 'step')
                        continue   % une source qui passe par zéro n'a pas de réciproque finie
                    end
                    m = new_system('croise');
                    m = add_block(m, sources{i, 1}, 'source', parametresSource{:});
                    amont = 'source';
                    if echantillonne
                        m = add_block(m, 'zoh', 'tenue', 'SampleTime', 0.05);
                        m = add_line(m, 'source', 'tenue');
                        amont = 'tenue';
                    end
                    m = add_block(m, traitements{j, 1}, 'traitement', traitements{j, 2}{:});
                    m = add_line(m, amont, 'traitement');
                    r = sim(m, 0.6, simset('FixedStep', 0.01, 'Solver', solveur{1}));
                    t = r.temps;
                    if echantillonne
                        t = floor(t / 0.05 + 1e-9) * 0.05;   % l'instant tenu
                    end
                    decalages = sources{i, 4}{1 + (dimension == 3)};
                    attenduSource = sources{i, 3}(t, decalages);
                    attendu = traitements{j, 3}(attenduSource);
                    obtenu = r.signaux.traitement;
                    assert(isequal(size(obtenu), size(attendu)), ...
                           sprintf('%s de %s (%d voies) : taille %s au lieu de %s', ...
                                   traitements{j, 1}, sources{i, 1}, dimension, ...
                                   mat2str(size(obtenu)), mat2str(size(attendu))));
                    ecart = max(abs(obtenu(:) - attendu(:)));
                    assert(ecart < 1e-9, sprintf(['%s de %s (%d voies, %s, echantillonne ' ...
                           '%d) : ecart %g'], traitements{j, 1}, sources{i, 1}, dimension, ...
                           solveur{1}, echantillonne, ecart));
                    combinaisons = combinaisons + 1;
                end
            end
        end
    end
end
fprintf('blocs sans memoire : %d combinaisons verifiees\n', combinaisons);

%% ------------------------------------------ 2. Chaines de blocs croises
% Trois traitements enchaînés, tirés d'une liste : la chaîne rend la
% composée des trois fonctions. Les chaînes sont engendrées, et chacune
% se compare au calcul direct.
unaires = {
    'gain',        {'Gain', -2},                         @(u) -2 * u
    'bias',        {'Bias', 0.5},                        @(u) u + 0.5
    'abs',         {},                                   @(u) abs(u)
    'saturation',  {'UpperLimit', 1, 'LowerLimit', -1},  @(u) min(max(u, -1), 1)
    'trigonometry', {'Operator', 'sin'},                 @(u) sin(u)
    'math',        {'Operator', 'square'},               @(u) u .^ 2
    'polynomial',  {'coefs', [1 0 -1]},                  @(u) u .^ 2 - 1
    'unaryminus',  {},                                   @(u) -u
    'quantizer',   {'QuantizationInterval', 0.1},        @(u) 0.1 * round(u / 0.1)
};
rng(7);
chaines = 0;
for essai = 1:40
    choix = randi(size(unaires, 1), 1, 3);
    m = new_system('chaine');
    m = add_block(m, 'sine', 's', 'Amplitude', [1; 2], 'Frequency', 3);
    precedent = 's';
    f = @(u) u;
    for etage = 1:3
        nom = sprintf('b%d', etage);
        m = add_block(m, unaires{choix(etage), 1}, nom, unaires{choix(etage), 2}{:});
        m = add_line(m, precedent, nom);
        precedent = nom;
        g = unaires{choix(etage), 3};
        f = @(u) g(f(u));
    end
    r = sim(m, 0.5, 0.01);
    attendu = f([sin(3 * r.temps), 2 * sin(3 * r.temps)]);
    assert(max(max(abs(r.signaux.b3 - attendu))) < 1e-9, ...
           sprintf('chaine %s : le resultat n''est pas la composee', ...
                   strjoin(unaires(choix, 1)', ' > ')));
    chaines = chaines + 1;
end
fprintf('chaines de trois blocs : %d verifiees\n', chaines);

%% ------------------------------------------- 3. Signaux vecteurs et matrices
% Mux, Demux, Selector, Concatenate, Reshape : l'aiguillage ne change pas
% les valeurs, il les range.
m = new_system('aiguillage');
m = add_block(m, 'constant', 'a', 'Value', [1 2]);
m = add_block(m, 'constant', 'b', 'Value', 7);
m = add_block(m, 'sine', 's', 'Amplitude', 1);
m = add_block(m, 'mux', 'mx', 'Inputs', 3);
m = add_block(m, 'demux', 'dx', 'Outputs', [1 3]);
m = add_block(m, 'selector', 'sel', 'Indices', [4 1]);
m = add_block(m, 'concatenate', 'cc', 'NumInputs', 2);
m = add_block(m, 'sum', 'somme', 'Signs', '+');
m = add_line(m, 'a', 'mx', 1);
m = add_line(m, 'b', 'mx', 2);
m = add_line(m, 's', 'mx', 3);
m = add_line(m, 'mx', 'dx');
m = add_line(m, 'mx', 'sel');
m = add_line(m, 'dx/2', 'cc', 1);
m = add_line(m, 'dx/1', 'cc', 2);
m = add_line(m, 'mx', 'somme');
r = sim(m, 1, 0.1);
t = r.temps;
assert(isequal(size(r.signaux.mx), [numel(t) 4]), 'le Mux rend un vecteur de quatre');
assert(max(max(abs(r.signaux.mx - [ones(size(t)), 2 * ones(size(t)), 7 * ones(size(t)), ...
                                   sin(t)]))) < 1e-15);
assert(isequal(r.signaux.dx, ones(size(t))), 'la premiere sortie du Demux porte un element');
assert(isequal(size(r.signaux.dx_port2), [numel(t) 3]), 'la seconde en porte trois');
assert(max(max(abs(r.signaux.sel - [sin(t), ones(size(t))]))) < 1e-15, ...
       'le Selector prend les elements dans l''ordre de ses indices');
assert(max(max(abs(r.signaux.cc - [2 * ones(size(t)), 7 * ones(size(t)), sin(t), ...
                                   ones(size(t))]))) < 1e-15, ...
       'Concatenate met bout a bout, dans l''ordre de ses entrees');
assert(max(abs(r.signaux.somme - (10 + sin(t)))) < 1e-14, ...
       'une somme a une seule entree additionne ses elements');

% Un gain matriciel, un produit matriciel, une transposée : les matrices
% gardent leur forme, et le relevé est m x n x N.
m = new_system('matrices');
m = add_block(m, 'constant', 'M', 'Value', [1 2; 3 4]);
m = add_block(m, 'constant', 'v', 'Value', [1; -1]);
m = add_block(m, 'gain', 'Kv', 'Gain', [2 0; 1 1], 'Multiplication', 'Matrix(K*u)');
m = add_block(m, 'product', 'MM', 'Inputs', '**', 'Multiplication', 'Matrix(*)');
m = add_block(m, 'math', 'Mt', 'Operator', 'transpose');
m = add_block(m, 'product', 'inverse', 'Inputs', '/', 'Multiplication', 'Matrix(*)');
m = add_line(m, 'v', 'Kv');
m = add_line(m, 'M', 'MM', 1);
m = add_line(m, 'M', 'MM', 2);
m = add_line(m, 'M', 'Mt');
m = add_line(m, 'M', 'inverse');
r = sim(m, 0.02, 0.01);
assert(isequal(r.signaux.Kv(1, :), [2 0]), 'K*u, u colonne');
assert(isequal(size(r.signaux.MM), [2 2 3]), 'une matrice se releve m x n x N');
assert(isequal(r.signaux.MM(:, :, 1), [1 2; 3 4]^2));
assert(isequal(r.signaux.Mt(:, :, 2), [1 3; 2 4]), 'la transposee');
assert(max(max(abs(r.signaux.inverse(:, :, 1) - inv([1 2; 3 4])))) < 1e-14, ...
       'un produit a une seule entree divisee inverse la matrice');

%% ----------------------------------------- 4. Blocs a plusieurs sorties
% Le sinus-cosinus rend deux sorties ; un sous-système à deux OUTPORT en
% rend deux, que l'on relie chacune.
m = new_system('deuxSorties');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'trigonometry', 'sc', 'Operator', 'sincos');
m = add_block(m, 'sum', 'un', 'Signs', '++');
m = add_block(m, 'math', 'carreS', 'Operator', 'square');
m = add_block(m, 'math', 'carreC', 'Operator', 'square');
m = add_line(m, 'horloge', 'sc');
m = add_line(m, 'sc/1', 'carreS');
m = add_line(m, 'sc/2', 'carreC');
m = add_line(m, 'carreS', 'un', 1);
m = add_line(m, 'carreC', 'un', 2);
r = sim(m, 2, 0.05);
assert(max(abs(r.signaux.un - 1)) < 1e-15, 'sin^2 + cos^2 = 1, par les deux sorties');

interne = new_system('separe');
interne = add_block(interne, 'inport', 'e', 'Port', 1);
interne = add_block(interne, 'gain', 'double', 'Gain', 2);
interne = add_block(interne, 'gain', 'triple', 'Gain', 3);
interne = add_block(interne, 'outport', 's1', 'Port', 1);
interne = add_block(interne, 'outport', 's2', 'Port', 2);
interne = add_line(interne, 'e', 'double');
interne = add_line(interne, 'e', 'triple');
interne = add_line(interne, 'double', 's1');
interne = add_line(interne, 'triple', 's2');
m = new_system('dessus');
m = add_block(m, 'constant', 'c', 'Value', 5);
m = add_block(m, 'subsystem', 'boite', 'Model', interne);
m = add_block(m, 'sum', 'ecart', 'Signs', '-+');
m = add_line(m, 'c', 'boite');
m = add_line(m, 'boite/1', 'ecart', 1);
m = add_line(m, 'boite/2', 'ecart', 2);
r = sim(m, 0.02, 0.01);
assert(all(r.signaux.ecart == 5), 'la seconde sortie du sous-systeme est la sienne');
assert(all(r.signaux.boite == 10) && all(r.signaux.boite_port2 == 15));

%% --------------------------------------- 5. Periodes d'echantillonnage
% Trois périodes, un décalage : chaque bloc ne change qu'à ses instants,
% et un bloc qui hérite prend la période la plus rapide de ses entrées.
m = new_system('cadences');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'zoh', 'lent', 'SampleTime', 0.3);
m = add_block(m, 'zoh', 'rapide', 'SampleTime', 0.1);
m = add_block(m, 'zoh', 'decale', 'SampleTime', [0.2 0.05]);
m = add_block(m, 'sum', 'melange', 'Signs', '++');
m = add_line(m, 'horloge', 'lent');
m = add_line(m, 'horloge', 'rapide');
m = add_line(m, 'horloge', 'decale');
m = add_line(m, 'lent', 'melange', 1);
m = add_line(m, 'rapide', 'melange', 2);
r = sim(m, 1, 0.05);
t = r.temps;
tenue = @(periode, decalage) max(floor((t - decalage) / periode + 1e-9), 0) * periode + decalage;
assert(max(abs(r.signaux.lent - tenue(0.3, 0))) < 1e-12, 'la tenue lente');
assert(max(abs(r.signaux.rapide - tenue(0.1, 0))) < 1e-12, 'la tenue rapide');
valeursDecalees = tenue(0.2, 0.05);
valeursDecalees(t < 0.05) = 0;   % avant son premier instant, la sortie est nulle
assert(max(abs(r.signaux.decale - valeursDecalees)) < 1e-12, 'le decalage retarde les instants');
assert(max(abs(r.signaux.melange - (tenue(0.3, 0) + tenue(0.1, 0)))) < 1e-12);
compile = matlibre_sl_compiler(m, struct('pas', 0.05, 'silencieux', true));
assert(abs(compile.cadence(strcmp(compile.noms, 'melange')) - 0.1) < 1e-15, ...
       'la somme herite de la periode la plus rapide');

% Un retard discret ne compte que ses propres instants.
m = new_system('retardLent');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'zoh', 'z', 'SampleTime', 0.2);
m = add_block(m, 'delay', 'retard', 'DelayLength', 2, 'SampleTime', 0.2);
m = add_line(m, 'horloge', 'z');
m = add_line(m, 'z', 'retard');
r = sim(m, 1.2, 0.1);
attendu = max(floor(r.temps / 0.2 + 1e-9) - 2, 0) * 0.2;
assert(max(abs(r.signaux.retard - attendu)) < 1e-12, ...
       'deux periodes de retard, non deux pas');

% Un bloc sans entrée, seul et dernier du calcul : sa mise à jour ne lit
% pas au-delà des entrées du modèle. Plus court que sa période, il garde
% son premier tirage ; plus long, il le tient une période entière.
for type = {'randomnumber', 'uniformrandomnumber'}
    m = new_system('tirage');
    m = add_block(m, type{1}, 'bruit', 'Seed', 3, 'SampleTime', 0.1);
    r = sim(m, 0.02, 0.01);
    assert(numel(r.temps) == 3 && all(r.signaux.bruit == r.signaux.bruit(1)), ...
           [type{1} ' : plus court que sa periode, un seul tirage']);
    r = sim(m, 0.5, 0.01);
    paliers = reshape(r.signaux.bruit(1:50), 10, 5);
    assert(all(all(paliers == paliers(1, :))) && numel(unique(paliers(1, :))) == 5, ...
           [type{1} ' : un tirage par periode, tenu entre deux']);
end

%% ------------------------------------------------------------- 6. Solveurs
% L'ordre de chaque solveur se mesure, sur un modèle mixte où un bloc
% échantillonné alimente un intégrateur : le continu garde son ordre.
m = new_system('ordres');
m = add_block(m, 'integrator', 'x', 'InitialCondition', 1);
m = add_block(m, 'gain', 'k', 'Gain', -1);
m = add_block(m, 'sine', 'force', 'Frequency', 2);
m = add_block(m, 'sum', 's', 'Signs', '++');
m = add_line(m, 'x', 'k');
m = add_line(m, 'k', 's', 1);
m = add_line(m, 'force', 's', 2);
m = add_line(m, 's', 'x');
% x' = -x + sin(2t), x(0) = 1 : x = (7/5) e^-t + (sin 2t - 2 cos 2t)/5.
exacte = @(t) 7 / 5 * exp(-t) + (sin(2 * t) - 2 * cos(2 * t)) / 5;
ordres = struct('ode1', 1, 'ode2', 2, 'ode3', 3, 'ode4', 4, 'ode5', 5);
nomsSolveurs = fieldnames(ordres);
for kS = 1:numel(nomsSolveurs)
    erreurs = zeros(1, 3);
    pasEssayes = [0.1 0.05 0.025];
    for kP = 1:3
        r = sim(m, 2, simset('FixedStep', pasEssayes(kP), 'Solver', nomsSolveurs{kS}));
        erreurs(kP) = abs(r.signaux.x(end) - exacte(2));
    end
    % Le dernier rapport, le plus proche du régime asymptotique : ode4
    % n'y arrive qu'aux petits pas sur ce modèle, dont la constante
    % d'erreur s'annule presque.
    mesure = log2(erreurs(2) / erreurs(3));
    assert(abs(mesure - ordres.(nomsSolveurs{kS})) < 0.3, ...
           sprintf('%s converge a l''ordre %g, non %d', nomsSolveurs{kS}, ...
                   mean(mesure), ordres.(nomsSolveurs{kS})));
end
% FixedStepDiscrete refuse un état continu, en nommant le bloc.
refus = false;
try
    sim(set_param(m, 'Solver', 'FixedStepDiscrete'), 1);
catch err
    refus = strcmp(err.identifier, 'Simulink:Engine:DiscreteSolverContinuousStates') && ...
            ~isempty(strfind(err.message, 'ordres/x'));
end
assert(refus, 'FixedStepDiscrete refuse un etat continu, en nommant le bloc');

%% ------------------------------------------------- 7. Boucles algebriques
% y = u - 2 y : une boucle sans état, que Newton résout exactement.
m = new_system('boucle');
m = add_block(m, 'sine', 'u', 'Frequency', 1);
m = add_block(m, 'sum', 'e', 'Signs', '+-');
m = add_block(m, 'gain', 'k', 'Gain', 2);
m = add_line(m, 'u', 'e', 1);
m = add_line(m, 'k', 'e', 2);
m = add_line(m, 'e', 'k');
m = set_param(m, 'AlgebraicLoopMsg', 'none');
r = sim(m, 2, 0.01);
assert(max(abs(r.signaux.e - sin(r.temps) / 3)) < 1e-10, 'e = u / 3');
% Le réglage AlgebraicLoopMsg décide : un avertissement par défaut, une
% erreur si on le demande — et le message nomme les blocs de la boucle.
lastwarn('');
sim(set_param(m, 'AlgebraicLoopMsg', 'warning'), 0.1, 0.01);
[texte, identifiant] = lastwarn();
assert(strcmp(identifiant, 'Simulink:Engine:AlgebraicLoop') && ...
       ~isempty(strfind(texte, 'boucle/e')), 'la boucle est signalee, et nommee');
refus = false;
try
    sim(set_param(m, 'AlgebraicLoopMsg', 'error'), 0.1, 0.01);
catch err
    refus = strcmp(err.identifier, 'Simulink:Engine:AlgebraicLoop');
end
assert(refus, 'AlgebraicLoopMsg a error refuse la boucle');

% Une boucle non linéaire : y = cos(y), le point fixe de Dottie.
m = new_system('dottie');
m = add_block(m, 'trigonometry', 'c', 'Operator', 'cos');
m = add_line(m, 'c', 'c');
m = set_param(m, 'AlgebraicLoopMsg', 'none');
r = sim(m, 0.05, 0.01);
assert(max(abs(r.signaux.c - 0.739085133215161)) < 1e-9, 'y = cos(y)');

% Une boucle à gain unité n'a pas de solution unique : elle est refusée
% en le disant.
m = new_system('singuliere');
m = add_block(m, 'constant', 'u', 'Value', 1);
m = add_block(m, 'sum', 'e', 'Signs', '++');
m = add_block(m, 'gain', 'k', 'Gain', 1);
m = add_line(m, 'u', 'e', 1);
m = add_line(m, 'k', 'e', 2);
m = add_line(m, 'e', 'k');
m = set_param(m, 'AlgebraicLoopMsg', 'none');
refus = false;
try
    sim(m, 0.1, 0.01);
catch err
    refus = strcmp(err.identifier, 'Simulink:Engine:AlgLoopSingular') && ...
            ~isempty(strfind(err.message, 'singuliere/'));
end
assert(refus, 'une boucle de gain unite est refusee');

% Une boucle algébrique au milieu d'un système continu : l'intégrateur
% lit la sortie de la boucle, et tout le reste suit.
m = new_system('mixte');
m = add_block(m, 'integrator', 'x', 'InitialCondition', 1);
m = add_block(m, 'sum', 'e', 'Signs', '+-');
m = add_block(m, 'gain', 'k', 'Gain', 1);
m = add_block(m, 'gain', 'moins', 'Gain', -1);
m = add_line(m, 'x', 'e', 1);
m = add_line(m, 'k', 'e', 2);
m = add_line(m, 'e', 'k');
m = add_line(m, 'e', 'moins');
m = add_line(m, 'moins', 'x');
m = set_param(m, 'AlgebraicLoopMsg', 'none', 'Solver', 'ode4');
r = sim(m, 1, 0.01);
% e = x - e donne e = x/2, et x' = -x/2.
assert(abs(r.signaux.x(end) - exp(-0.5)) < 1e-8, 'x'' = -x/2 par la boucle');

%% --------------------------------------------------------- 8. Goto et From
m = new_system('etiquettes');
m = add_block(m, 'sine', 's');
m = add_block(m, 'goto', 'envoi', 'GotoTag', 'signal');
m = add_block(m, 'from', 'reception', 'GotoTag', 'signal');
m = add_block(m, 'gain', 'k', 'Gain', 2);
m = add_line(m, 's', 'envoi');
m = add_line(m, 'reception', 'k');
r = sim(m, 1, 0.1);
assert(max(abs(r.signaux.k - 2 * sin(r.temps))) < 1e-15, 'From rend le signal du Goto');
refus = false;
try
    sim(set_param(m, 'reception', 'GotoTag', 'autre'), 1, 0.1);
catch err
    refus = strcmp(err.identifier, 'Simulink:Engine:GotoTagMissing') && ...
            ~isempty(strfind(err.message, 'etiquettes/reception'));
end
assert(refus, 'un From sans Goto est refuse, en le nommant');
refus = false;
try
    deux = add_line(add_block(m, 'goto', 'envoi2', 'GotoTag', 'signal'), 's', 'envoi2');
    sim(deux, 1, 0.1);
catch err
    refus = strcmp(err.identifier, 'Simulink:Engine:GotoTagDuplicate');
end
assert(refus, 'deux Goto de meme etiquette sont refuses');
% Une étiquette locale ne traverse pas un sous-système ; une étiquette
% globale, si.
dedans = new_system('dedans');
dedans = add_block(dedans, 'from', 'lu', 'GotoTag', 'g');
dedans = add_block(dedans, 'outport', 'o', 'Port', 1);
dedans = add_line(dedans, 'lu', 'o');
m = new_system('portee');
m = add_block(m, 'constant', 'c', 'Value', 3);
m = add_block(m, 'goto', 'envoi', 'GotoTag', 'g', 'TagVisibility', 'global');
m = add_block(m, 'subsystem', 'b', 'Model', dedans);
m = add_line(m, 'c', 'envoi');
r = sim(m, 0.02, 0.01);
assert(all(r.signaux.b == 3), 'une etiquette globale traverse les sous-systemes');
refus = false;
try
    sim(set_param(m, 'envoi', 'TagVisibility', 'local'), 0.02, 0.01);
catch err
    refus = strcmp(err.identifier, 'Simulink:Engine:GotoTagMissing');
end
assert(refus, 'une etiquette locale ne les traverse pas');

%% --------------------------------------------- 9. Reglages du modele
m = new_system('reglages');
m = add_block(m, 'constant', 'c', 'Value', 1);
m = add_block(m, 'integrator', 'x');
m = add_line(m, 'c', 'x');
assert(strcmp(get_param(m, 'Solver'), 'ode1') && get_param(m, 'StopTime') == 10, ...
       'un modele neuf porte les reglages par defaut');
m = set_param(m, 'Solver', 'ode4', 'StartTime', 1, 'StopTime', 3, 'FixedStep', 0.5);
assert(strcmp(get_param(m, 'Solver'), 'ode4'));
r = sim(m);
assert(r.temps(1) == 1 && r.temps(end) == 3 && numel(r.temps) == 5, ...
       'SIM part de StartTime et va jusqu''a StopTime');
assert(abs(r.signaux.x(end) - 2) < 1e-12, 'l''integrale de 1 entre 1 et 3');
r = sim(m, 'StopTime', '2', 'FixedStep', 0.25);
assert(r.temps(end) == 2 && numel(r.temps) == 5, 'les reglages par nom valent pour un appel');
assert(get_param(m, 'StopTime') == 3, 'sans changer le modele');
refus = false;
try
    set_param(m, 'Solver', 'ode99');
catch err
    refus = strcmp(err.identifier, 'Simulink:Commands:SolveurInconnu') && ...
            ~isempty(strfind(err.message, 'ode4'));
end
assert(refus, 'un solveur inconnu est refuse, en disant ceux qui existent');
refus = false;
try
    set_param(m, 'ReglageQuiNExistePas', 1);
catch err
    refus = strcmp(err.identifier, 'Simulink:Commands:ParamUnknown');
end
assert(refus, 'un reglage inconnu du modele est refuse');
[tt, xx, yy] = sim(m, 2, 0.5);
assert(isequal(tt, (1:0.5:2)') && isequal(size(xx), [3 1]) && isempty(yy), ...
       '[T,X,Y] = SIM(...) rend instants, etats et sorties');

%% --------------------------------------------- 10. Arret, assertion, depot
m = new_system('arret');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'comparetoconstant', 'fini', 'relop', '>=', 'const', 0.5);
m = add_block(m, 'stopsimulation', 'stop');
m = add_line(m, 'horloge', 'fini');
m = add_line(m, 'fini', 'stop');
r = sim(m, 10, 0.1);
assert(abs(r.temps(end) - 0.5) < 1e-12, 'Stop Simulation arrete au pas ou son entree s''allume');
m = set_param(m, 'StopTime', Inf);
r = sim(m, [], 0.1);
assert(abs(r.temps(end) - 0.5) < 1e-12, 'et c''est lui qui borne une simulation sans fin');

m = new_system('assertion');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'comparetoconstant', 'avant', 'relop', '<', 'const', 0.3);
m = add_block(m, 'assertion', 'verif');
m = add_line(m, 'horloge', 'avant');
m = add_line(m, 'avant', 'verif');
refus = false;
try
    sim(m, 1, 0.1);
catch err
    refus = strcmp(err.identifier, 'Simulink:blocks:AssertionAssert') && ...
            ~isempty(strfind(err.message, 'assertion/verif')) && ...
            ~isempty(strfind(err.message, '0.3'));
end
assert(refus, 'l''assertion echoue a l''instant dit, en nommant le bloc');

m = new_system('depot');
m = add_block(m, 'sine', 's', 'Amplitude', [1; 2]);
m = add_block(m, 'toworkspace', 'tableau', 'VariableName', 'depotTableau');
m = add_block(m, 'toworkspace', 'structure', 'VariableName', 'depotStructure', ...
              'SaveFormat', 'Structure With Time');
m = add_line(m, 's', 'tableau');
m = add_line(m, 's', 'structure');
r = sim(m, 1, 0.1);
assert(isequal(size(depotTableau), [11 2]), 'Array : une ligne par instant');
assert(isequal(depotStructure.time, r.temps) && ...
       isequal(depotStructure.signals.values, depotTableau) && ...
       depotStructure.signals.dimensions == 2, 'Structure With Time');

%% --------------------------------------- 11. Messages d'erreur, un a un
% Chaque erreur a l'identifiant de Simulink et nomme le bloc par son
% chemin, comme le ferait le diagnostic de Simulink.
cas = {
    @() add_block(new_system('e1'), 'blocQuiNExistePas', 'b'), ...
        'Simulink:Commands:InvalidBlockType', 'blocQuiNExistePas'
    @() add_block(new_system('e2'), 'gain', 'g', 'Gian', 2), ...
        'Simulink:Commands:ParamUnknown', 'Gian'
    @() add_block(add_block(new_system('e3'), 'gain', 'g'), 'gain', 'g'), ...
        'Simulink:Commands:AddBlockCantAdd', 'g'
    @() add_line(add_block(add_block(new_system('e4'), 'constant', 'c'), 'gain', 'g'), ...
                 'c', 'g', 2), ...
        'Simulink:Commands:AddLineInvalidPort', 'e4/g'
    @() add_line(add_line(add_block(add_block(add_block(new_system('e5'), 'constant', ...
                 'a'), 'constant', 'b'), 'gain', 'g'), 'a', 'g'), 'b', 'g'), ...
        'Simulink:Commands:AddLineDestConnected', 'e5/g'
    @() sim(add_line(add_block(add_block(new_system('e6'), 'constant', 'c', 'Value', ...
                 [1 2 3]), 'gain', 'g', 'Gain', [1 2]), 'c', 'g'), 1), ...
        'Simulink:Engine:DimensionMismatch', 'e6/g'
    @() sim(add_block(new_system('e7'), 'zoh', 'z', 'SampleTime', 0.015), 1, 0.01), ...
        'Simulink:SampleTime:NotMultipleOfFixedStep', 'e7/z'
    @() sim(add_line(add_block(add_block(new_system('e8'), 'constant', 'c', 'Value', ...
                 [1 2 3]), 'demux', 'd', 'Outputs', 2), 'c', 'd'), 1), ...
        'Simulink:Engine:DimensionMismatch', 'e8/d'
    @() sim(add_line(add_block(add_block(new_system('e9'), 'constant', 'c', 'Value', ...
                 [1 2]), 'selector', 's', 'Indices', 3), 'c', 's'), 1), ...
        'Simulink:Selector:IndexOutOfRange', 'e9/s'
    @() sim(add_block(new_system('e10'), 'transferfcn', 'h', 'Numerator', [1 0 0], ...
                 'Denominator', [1 1]), 1), ...
        'Simulink:blocks:TransferFcnImproper', 'e10/h'
    @() sim(add_block(new_system('e11'), 'statespace', 's', 'A', [1 2], 'B', 1, ...
                 'C', 1), 1), ...
        'Simulink:blocks:StateSpaceANotSquare', 'e11/s'
    @() sim(add_line(add_block(add_block(new_system('e12'), 'constant', 'c', 'Value', 7), ...
                 'multiportswitch', 'm', 'Inputs', 2), 'c', 'm', 1), 1), ...
        'Simulink:blocks:MultiPortSwitchIndexOutOfRange', 'e12/m'
    @() sim(add_block(new_system('e13'), 'saturation', 's', 'UpperLimit', -1, ...
                 'LowerLimit', 1), 1), ...
        'Simulink:blocks:SaturationLimits', 'e13/s'
    @() sim(set_param(add_block(new_system('e14'), 'gain', 'g'), ...
                 'UnconnectedInputMsg', 'error'), 1), ...
        'Simulink:Engine:InputNotConnected', 'e14/g'
    @() sim(add_block(new_system('e15'), 'lookup', 't', 'BreakpointsData', [0 2 1], ...
                 'TableData', [0 1 2]), 1), ...
        'Simulink:blocks:LookupBreakpointsNotMonotonic', 'e15/t'
    @() set_param(add_block(new_system('e16'), 'gain', 'g'), 'g', 'BlockType', 'sum'), ...
        'Simulink:Commands:ParamReadOnly', ''
    @() sim(add_block(new_system('e17'), 'relay', 'r', 'OnSwitch', -1, 'OffSwitch', 1), 1), ...
        'Simulink:blocks:RelayOnOffSwitch', 'e17/r'
    @() sim(add_block(new_system('e18'), 'discretetransferfcn', 'h', 'Numerator', ...
                 [1 1 1], 'Denominator', [1 0.5]), 1), ...
        'Simulink:blocks:TransferFcnImproper', 'e18/h'
};
for k = 1:size(cas, 1)
    recu = '';
    message = '';
    try
        cas{k, 1}();
    catch err
        recu = err.identifier;
        message = err.message;
    end
    assert(strcmp(recu, cas{k, 2}), sprintf('cas %d : %s attendu, %s recu (%s)', k, ...
                                            cas{k, 2}, recu, message));
    assert(isempty(cas{k, 3}) || ~isempty(strfind(message, cas{k, 3})), ...
           sprintf('cas %d : le message ne nomme pas %s : %s', k, cas{k, 3}, message));
end
fprintf('messages d''erreur : %d cas verifies\n', size(cas, 1));

%% ------------------------------------------------- 12. Linearisation
% LINMOD sur un modèle à entrée et sortie vecteurs : le système de deux
% intégrateurs indépendants, gains 2 et 3.
m = new_system('vecteur');
m = add_block(m, 'inport', 'u', 'Port', 1, 'PortDimensions', 2);
m = add_block(m, 'gain', 'k', 'Gain', [2; 3]);
m = add_block(m, 'integrator', 'x', 'InitialCondition', [0; 0]);
m = add_block(m, 'outport', 'y', 'Port', 1);
m = add_line(m, 'u', 'k');
m = add_line(m, 'k', 'x');
m = add_line(m, 'x', 'y');
[A, B, C, D] = linmod(m);
assert(max(max(abs(A))) < 1e-9 && max(max(abs(B - diag([2 3])))) < 1e-8 && ...
       max(max(abs(C - eye(2)))) < 1e-8 && max(max(abs(D))) < 1e-12, ...
       'deux voies, deux etats, deux entrees et deux sorties');

%% --------------------------------------------------------- 13. Pas variable
% La tolérance commande l'erreur : pour chaque solveur, une tolérance
% plus fine donne une erreur plus petite, et plus de pas.
m = new_system('decroissance');
m = add_block(m, 'gain', 'k', 'Gain', -1);
m = add_block(m, 'integrator', 'x', 'InitialCondition', 1);
m = add_line(m, 'x', 'k');
m = add_line(m, 'k', 'x');
for solveur = {'ode45', 'ode23', 'ode23s'}
    erreurs = zeros(1, 3);
    nombresDePas = zeros(1, 3);
    tolerances = [1e-3 1e-5 1e-7];
    for kT = 1:3
        r = sim(m, 'Solver', solveur{1}, 'RelTol', tolerances(kT), 'MaxStep', Inf, ...
                'StopTime', 5);
        erreurs(kT) = max(abs(r.signaux.x - exp(-r.temps)));
        nombresDePas(kT) = numel(r.temps) - 1;
        assert(erreurs(kT) < 100 * tolerances(kT), ...
               sprintf('%s : erreur %g pour la tolerance %g', solveur{1}, erreurs(kT), ...
                       tolerances(kT)));
    end
    assert(all(diff(erreurs) < 0) && all(diff(nombresDePas) > 0), ...
           [solveur{1} ' : une tolerance plus fine, une erreur plus petite et plus de pas']);
end
% Le pas maximal borne le pas : MaxStep par défaut vaut le cinquantième
% de la durée, et le relevé porte un instant par pas majeur.
r = sim(m, 'Solver', 'ode45', 'StopTime', 5);
assert(max(diff(r.temps)) <= 0.1 + 1e-12 && numel(r.temps) >= 51, ...
       'le cinquantieme de la duree borne le pas');
r = sim(m, [0 0.5 1 2], simset('Solver', 'ode45'));
assert(isequal(r.temps(:).', [0 0.5 1 2]) && abs(r.signaux.x(end) - exp(-2)) < 1e-5, ...
       'les instants imposes sont les seuls releves, et atteints exactement');
r = sim(m, 'Solver', 'VariableStepAuto', 'StopTime', 1);
r45 = sim(m, 'Solver', 'ode45', 'StopTime', 1);
assert(isequal(r.temps, r45.temps) && isequal(r.signaux.x, r45.signaux.x), ...
       'VariableStepAuto prend ode45 quand il y a des etats continus');

% Les instants d'échantillonnage sont atteints exactement, et un bloc
% discret y rend ce que rend le pas fixe : deux périodes, un décalage.
m = new_system('multicadence');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'zoh', 'lent', 'SampleTime', 0.3);
m = add_block(m, 'discretetransferfcn', 'filtre', 'Numerator', [0 0.4], ...
              'Denominator', [1 -0.6], 'SampleTime', [0.2 0.05]);
m = add_block(m, 'integrator', 'x');
m = add_line(m, 'horloge', 'lent');
m = add_line(m, 'lent', 'filtre');
m = add_line(m, 'lent', 'x');
rVariable = sim(m, 'Solver', 'ode45', 'StopTime', 2);
rFixe = sim(m, 'Solver', 'ode4', 'FixedStep', 0.05, 'StopTime', 2);
for instant = [0:0.3:2, 0.05:0.2:2]
    iV = find(abs(rVariable.temps - instant) < 1e-12, 1);
    iF = find(abs(rFixe.temps - instant) < 1e-12, 1);
    assert(~isempty(iV), sprintf('l''instant %g est atteint', instant));
    assert(abs(rVariable.signaux.filtre(iV) - rFixe.signaux.filtre(iF)) < 1e-12 && ...
           abs(rVariable.signaux.lent(iV) - rFixe.signaux.lent(iF)) < 1e-12, ...
           sprintf('a %g, les blocs discrets rendent ce que rend le pas fixe', instant));
end
assert(abs(rVariable.signaux.x(end) - sum(0.3 * (0:0.3:1.5)) - 0.2 * 1.8) < 1e-9, ...
       'l''integrale d''une tenue est exacte');

% Les cassures des sources sont des fins de pas : l'intégrale d'un échelon
% et d'un train d'impulsions est exacte, quel que soit le solveur.
for solveur = {'ode45', 'ode23', 'ode23s'}
    m = new_system('cassures');
    m = add_block(m, 'step', 'echelon', 'Time', 0.4567, 'After', 2);
    m = add_block(m, 'pulsegenerator', 'train', 'Period', 0.3, 'PulseWidth', 40, ...
                  'PhaseDelay', 0.05);
    m = add_block(m, 'integrator', 'xe');
    m = add_block(m, 'integrator', 'xp');
    m = add_line(m, 'echelon', 'xe');
    m = add_line(m, 'train', 'xp');
    r = sim(m, 'Solver', solveur{1}, 'StopTime', 1.25);
    assert(abs(r.signaux.xe(end) - 2 * (1.25 - 0.4567)) < 1e-10, ...
           [solveur{1} ' : l''echelon tombe sur une fin de pas']);
    assert(abs(r.signaux.xp(end) - 4 * 0.12) < 1e-10, ...
           [solveur{1} ' : chaque front d''impulsion aussi']);
    assert(any(abs(r.temps - 0.4567) < 1e-12), [solveur{1} ' : l''instant de l''echelon']);
end

% Les passages par zéro : chaque bloc à cassure, sur une entrée
% sin(2t) + 0,3, alimente un intégrateur. L'intégrale se compare au calcul
% direct, morceau par morceau entre les instants où l'entrée franchit le
% seuil du bloc — que le solveur doit localiser.
u = @(t) sin(2 * t) + 0.3;
franchit = @(c) sort([(asin(c - 0.3) + 2 * pi * (0:1)) / 2, ...
                      (pi - asin(c - 0.3) + 2 * pi * (0:1)) / 2]);
cas = {
    'abs',               {},                                         @(v) abs(v),            0
    'sign',              {},                                         @(v) sign(v),           0
    'saturation',        {'UpperLimit', 0.5, 'LowerLimit', -0.5},    @(v) min(max(v, -0.5), 0.5), [0.5 -0.5]
    'deadzone',          {'UpperValue', 0.4, 'LowerValue', -0.4},    @(v) (v > 0.4) .* (v - 0.4) + (v < -0.4) .* (v + 0.4), [0.4 -0.4]
    'comparetoconstant', {'relop', '>=', 'const', 0.2, 'OutDataTypeStr', 'double'}, @(v) double(v >= 0.2), 0.2
    'comparetozero',     {'relop', '>', 'OutDataTypeStr', 'double'}, @(v) double(v > 0),     0
    'coulombfriction',   {'Offset', 1, 'Gain', 2},                   @(v) sign(v) .* (1 + 2 * abs(v)), 0
    };
duree = 3;
for kC = 1:size(cas, 1)
    coupures = [];
    for seuil = cas{kC, 4}
        coupures = [coupures, franchit(seuil)]; %#ok<AGROW>
    end
    attendu = integrerParMorceaux(@(t) cas{kC, 3}(u(t)), 0, duree, coupures);
    for solveur = {'ode45', 'ode23'}
        m = new_system('franchissement');
        m = add_block(m, 'sine', 'entree', 'Frequency', 2, 'Bias', 0.3);
        m = add_block(m, cas{kC, 1}, 'bloc', cas{kC, 2}{:});
        m = add_block(m, 'integrator', 'x');
        m = add_line(m, 'entree', 'bloc');
        m = add_line(m, 'bloc', 'x');
        r = sim(m, 'Solver', solveur{1}, 'StopTime', duree, 'RelTol', 1e-8, 'AbsTol', 1e-10);
        assert(abs(r.signaux.x(end) - attendu) < 1e-7, ...
               sprintf('%s par %s : %g au lieu de %g', cas{kC, 1}, solveur{1}, ...
                       r.signaux.x(end), attendu));
    end
end
% Deux entrées : la comparaison, le plus grand, l'aiguillage. Un
% comparateur rend un booléen, que l'intégrateur refuse comme dans
% Simulink : on lui demande un double (OutDataTypeStr).
cas2 = {
    'relational', {'Operator', '<', 'OutDataTypeStr', 'double'}, @(v) double(v < 0.1)
    'minmax',     {'Function', 'max'},     @(v) max(v, 0.1)
    };
for kC = 1:size(cas2, 1)
    attendu = integrerParMorceaux(@(t) cas2{kC, 3}(u(t)), 0, duree, franchit(0.1));
    m = new_system('deuxEntrees');
    m = add_block(m, 'sine', 'entree', 'Frequency', 2, 'Bias', 0.3);
    m = add_block(m, 'constant', 'seuil', 'Value', 0.1);
    m = add_block(m, cas2{kC, 1}, 'bloc', cas2{kC, 2}{:});
    m = add_block(m, 'integrator', 'x');
    m = add_line(m, 'entree', 'bloc', 1);
    m = add_line(m, 'seuil', 'bloc', 2);
    m = add_line(m, 'bloc', 'x');
    r = sim(m, 'Solver', 'ode45', 'StopTime', duree, 'RelTol', 1e-8, 'AbsTol', 1e-10);
    assert(abs(r.signaux.x(end) - attendu) < 1e-7, [cas2{kC, 1} ' : le seuil est localise']);
end
m = new_system('aiguillage');
m = add_block(m, 'sine', 'entree', 'Frequency', 2, 'Bias', 0.3);
m = add_block(m, 'constant', 'haut', 'Value', 1);
m = add_block(m, 'constant', 'bas', 'Value', -1);
m = add_block(m, 'switch', 'choix', 'Threshold', 0.1);
m = add_block(m, 'integrator', 'x');
m = add_line(m, 'haut', 'choix', 1);
m = add_line(m, 'entree', 'choix', 2);
m = add_line(m, 'bas', 'choix', 3);
m = add_line(m, 'choix', 'x');
r = sim(m, 'Solver', 'ode45', 'StopTime', duree, 'RelTol', 1e-8, 'AbsTol', 1e-10);
attendu = integrerParMorceaux(@(t) 2 * (u(t) >= 0.1) - 1, 0, duree, franchit(0.1));
assert(abs(r.signaux.x(end) - attendu) < 1e-7, 'l''aiguillage bascule au bon instant');

% Le relais : ses seuils de marche et d'arrêt sont franchis tour à tour.
% Sans la détection, le mode ne change qu'au pas majeur suivant, et
% l'intégrale s'en ressent : la détection se coupe pour tout le modèle
% (ZeroCrossControl) ou pour le seul bloc (ZeroCross).
m = new_system('relais');
m = add_block(m, 'sine', 'entree', 'Frequency', 2, 'Bias', 0.3);
m = add_block(m, 'relay', 'r', 'OnSwitch', 0.5, 'OffSwitch', -0.5, 'OnOutput', 1, ...
              'OffOutput', 0);
m = add_block(m, 'integrator', 'x');
m = add_line(m, 'entree', 'r');
m = add_line(m, 'r', 'x');
marche = franchit(0.5);
arret = franchit(-0.5);
% Parti à l'arrêt (0,3 < 0,5) : en marche du premier franchissement
% montant de 0,5 au franchissement descendant de -0,5 qui suit.
enMarche = [marche(1), arret(2); marche(3), arret(4)];
enMarche = min(enMarche, duree);
attendu = sum(enMarche(:, 2) - enMarche(:, 1));
r = sim(m, 'Solver', 'ode45', 'StopTime', duree);
assert(abs(r.signaux.x(end) - attendu) < 1e-8, 'le relais bascule a ses seuils');
sansModele = sim(m, 'Solver', 'ode45', 'StopTime', duree, 'ZeroCrossControl', 'DisableAll');
sansBloc = sim(set_param(m, 'r', 'ZeroCross', 'off'), 'Solver', 'ode45', 'StopTime', duree);
assert(abs(sansModele.signaux.x(end) - attendu) > 1e-4 && ...
       isequal(sansModele.signaux.x, sansBloc.signaux.x), ...
       'sans la detection, le relais bascule en retard, et les deux reglages l''eteignent');
avecTout = sim(set_param(m, 'r', 'ZeroCross', 'off'), 'Solver', 'ode45', ...
               'StopTime', duree, 'ZeroCrossControl', 'EnableAll');
assert(abs(avecTout.signaux.x(end) - attendu) < 1e-8, 'EnableAll passe outre le bloc');

% Hit Crossing : un seul pas marque le franchissement, juste après lui.
m = new_system('franchi');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'hitcrossing', 'hc', 'HitCrossingOffset', 0.3337);
m = add_line(m, 'horloge', 'hc');
r = sim(m, 'Solver', 'ode45', 'StopTime', 1);
marques = find(r.signaux.hc == 1);
assert(numel(marques) == 1 && abs(r.temps(marques) - 0.3337) < 1e-8, ...
       'le franchissement est marque une fois, a son instant');

% L'intégrateur borné touche sa borne et la quitte au bon instant :
% x' = 2 cos t, borné à 1,5 — il y reste tant que la dérivée pousse.
m = new_system('borne');
m = add_block(m, 'sine', 'derivee', 'Amplitude', 2, 'Phase', pi / 2);
m = add_block(m, 'integrator', 'x', 'LimitOutput', 'on', 'UpperSaturationLimit', 1.5);
m = add_line(m, 'derivee', 'x');
r = sim(m, 'Solver', 'ode45', 'StopTime', 3, 'RelTol', 1e-8);
assert(abs(r.signaux.x(end) - (1.5 + 2 * (sin(3) - 1))) < 1e-6, ...
       'la borne est tenue puis quittee a l''instant ou la derivee change de signe');

% Stop Simulation, sans instant final : l'arrêt tombe au franchissement.
m = new_system('arret');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'comparetoconstant', 'assez', 'relop', '>=', 'const', 2.345);
m = add_block(m, 'stopsimulation', 'stop');
m = add_line(m, 'horloge', 'assez');
m = add_line(m, 'assez', 'stop');
r = sim(m, 'Solver', 'ode45', 'StopTime', Inf);
assert(abs(r.temps(end) - 2.345) < 1e-8, 'l''arret tombe a l''instant du franchissement');

% Le retard pur garde les instants avec les valeurs : il interpole entre
% deux pas majeurs, et son tampon grandit au-delà de sa taille initiale.
m = new_system('retard');
m = add_block(m, 'sine', 'entree', 'Frequency', 2);
m = add_block(m, 'transportdelay', 'retard', 'DelayTime', 0.37, 'BufferSize', 16);
m = add_line(m, 'entree', 'retard');
r = sim(m, 'Solver', 'ode45', 'StopTime', 3, 'MaxStep', 0.007);
attendu = sin(2 * (r.temps - 0.37));
attendu(r.temps < 0.37) = 0;
assert(max(abs(r.signaux.retard - attendu)) < 1e-4, ...
       'le retard interpole entre les instants gardes, au-dela de la taille initiale');

% Une boucle algébrique se résout aussi à pas variable.
m = new_system('boucle');
m = add_block(m, 'sine', 'entree');
m = add_block(m, 'sum', 'e', 'Signs', '+-');
m = add_block(m, 'gain', 'k', 'Gain', 3);
m = add_line(m, 'entree', 'e', 1);
m = add_line(m, 'k', 'e', 2);
m = add_line(m, 'e', 'k');
m = set_param(m, 'AlgebraicLoopMsg', 'none');
r = sim(m, 'Solver', 'ode23', 'StopTime', 2);
assert(max(abs(r.signaux.e - sin(r.temps) / 4)) < 1e-12, 'e = u - 3e, soit u / 4');

% Un système raide : ode23s y garde un grand pas, ode45 piétine.
m = new_system('raide');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'trigonometry', 'consigne', 'Operator', 'cos');
m = add_block(m, 'sum', 'ecart', 'Signs', '+-');
m = add_block(m, 'gain', 'raideur', 'Gain', 1000);
m = add_block(m, 'integrator', 'x');
m = add_line(m, 'horloge', 'consigne');
m = add_line(m, 'consigne', 'ecart', 1);
m = add_line(m, 'x', 'ecart', 2);
m = add_line(m, 'ecart', 'raideur');
m = add_line(m, 'raideur', 'x');
r45 = sim(m, 'Solver', 'ode45', 'StopTime', 2, 'MaxStep', 1);
r23s = sim(m, 'Solver', 'ode23s', 'StopTime', 2, 'MaxStep', 1);
permanent = (1e6 * cos(2) + 1e3 * sin(2)) / (1e6 + 1);
assert(numel(r23s.temps) * 5 < numel(r45.temps) && ...
       abs(r23s.signaux.x(end) - permanent) < 1e-3 && abs(r45.signaux.x(end) - permanent) < 1e-3, ...
       'ode23s traverse le systeme raide en bien moins de pas');

% Le solveur et son type vont ensemble.
m = new_system('types');
m = set_param(m, 'SolverType', 'Variable-step');
assert(strcmp(get_param(m, 'Solver'), 'VariableStepAuto'), ...
       'un type donne seul prend le solveur automatique');
m = set_param(m, 'Solver', 'ode4');
assert(strcmp(get_param(m, 'SolverType'), 'Fixed-step'), 'le type suit le solveur');
m = set_param(m, 'SolverType', 'Variable-step');
assert(strcmp(get_param(m, 'Solver'), 'VariableStepAuto'), ...
       'un type qui ne convient plus remplace le solveur');
m = set_param(m, 'Solver', 'ode23');
assert(strcmp(get_param(m, 'SolverType'), 'Variable-step'), 'ode23 est a pas variable');

% Les erreurs du pas variable, chacune avec son identifiant.
m = new_system('explose');
m = add_block(m, 'math', 'carre', 'Operator', 'square');
m = add_block(m, 'integrator', 'x', 'InitialCondition', 1);
m = add_line(m, 'x', 'carre');
m = add_line(m, 'carre', 'x');
decalage = add_block(new_system('decalage'), 'zoh', 'h', 'SampleTime', [0.1 0.2]);
casErreurs = {
    @() sim(m, 'Solver', 'ode45', 'StopTime', 2), 'Simulink:Engine:SolverMinStepViolation', 'singularite'
    @() sim(m, 'Solver', 'VariableStepDiscrete'), 'Simulink:Engine:DiscreteSolverContinuousStates', 'explose/x'
    @() sim(decalage, 'Solver', 'ode45'), 'Simulink:SampleTime:InvalidOffset', 'decalage/h'
    @() sim(m, 'Solver', 'ode45', 'RelTol', -1), 'Simulink:Config:InvalidValue', 'RelTol'
    @() sim(m, 'Solver', 'ode45', 'MinStep', 1, 'MaxStep', 0.1), 'Simulink:Config:InvalidValue', 'pas minimal'
    @() set_param(m, 'Solver', 'ode7'), 'Simulink:Commands:SolveurInconnu', 'ode15s'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('pas variable, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('pas variable : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% --------------------------------------- 14. Sous-systemes conditionnels
% Un sous-système activé n'intègre que quand son Enable est positif : un
% intégrateur de 1 y compte le temps passé activé. Ses états tiennent à
% l'arrêt (held), ou repartent de zéro à la reprise (reset) ; sa sortie
% tient, ou revient à sa valeur initiale.
interne = new_system('chrono');
interne = add_block(interne, 'constant', 'un', 'Value', 1);
interne = add_block(interne, 'integrator', 'x');
interne = add_block(interne, 'outport', 's', 'Port', 1);
interne = add_block(interne, 'enableport', 'Enable');
interne = add_line(interne, 'un', 'x');
interne = add_line(interne, 'x', 's');
m = new_system('active');
m = add_block(m, 'pulsegenerator', 'porte', 'Period', 2, 'PulseWidth', 50);
m = add_block(m, 'subsystem', 'sous', 'Model', interne);
m = add_line(m, 'porte', 'sous/Enable');
% À l'arrêt, la sortie tient la valeur du dernier pas majeur où le
% sous-système a calculé — celui d'avant la coupure, que l'impulsion fait
% tomber sur un pas, à pas fixe comme à pas variable.
for solveur = {'ode1', 'ode4', 'ode45', 'ode23'}
    r = sim(m, 'Solver', solveur{1}, 'StopTime', 3.5, 'FixedStep', 0.01);
    iCoupure = find(r.temps >= 1 - 1e-12, 1);
    iReprise = find(r.temps >= 2 - 1e-12, 1);
    iFin = find(r.temps >= 3 - 1e-12, 1);
    avantCoupure = r.temps(iCoupure - 1);
    assert(abs(r.temps(iCoupure) - 1) < 1e-12 && ...
           all(r.signaux.sous(iCoupure:iReprise - 1) == r.signaux.sous(iCoupure - 1)) && ...
           abs(r.signaux.sous(iCoupure - 1) - avantCoupure) < 1e-9, ...
           [solveur{1} ' : a l''arret, la sortie tient celle du dernier pas actif']);
    assert(abs(r.signaux.sous(end) - (1 + r.temps(iFin - 1) - 2)) < 1e-9, ...
           [solveur{1} ' : l''etat a tenu, puis repris : la duree active s''ajoute']);
end
reprise = set_param(m, 'sous', 'Model', set_param(interne, 'Enable', ...
                                                  'StatesWhenEnabling', 'reset'));
for solveur = {'ode1', 'ode45'}
    r = sim(reprise, 'Solver', solveur{1}, 'StopTime', 3.5, 'FixedStep', 0.01);
    iFin = find(r.temps >= 3 - 1e-12, 1);
    assert(abs(r.signaux.sous(end) - (r.temps(iFin - 1) - 2)) < 1e-9, ...
           [solveur{1} ' : reset, l''etat repart de zero a la reprise']);
end
retour = set_param(m, 'sous', 'Model', set_param(interne, 's', 'OutputWhenDisabled', ...
                                                 'reset', 'InitialOutput', -1));
r = sim(retour, 'Solver', 'ode4', 'StopTime', 3.5, 'FixedStep', 0.01);
assert(r.signaux.sous(find(r.temps >= 1.5, 1)) == -1 && r.signaux.sous(end) == -1 && ...
       abs(r.signaux.sous(find(r.temps >= 0.5, 1)) - 0.5) < 1e-9, ...
       'a l''arret, la sortie revient a sa valeur initiale');
% Le passage par zéro de l'Enable est localisé : activé tant que
% sin(t + 0,5) > 0, soit jusqu'à pi - 0,5.
m = new_system('activeSinus');
m = add_block(m, 'sine', 'porte', 'Phase', 0.5);
m = add_block(m, 'subsystem', 'sous', 'Model', interne);
m = add_line(m, 'porte', 'sous/Enable');
r = sim(m, 'Solver', 'ode45', 'StopTime', 4);
assert(abs(r.signaux.sous(end) - (pi - 0.5)) < 1e-8, 'l''arret tombe a pi - 0,5, localise');
iPaire = find(abs(r.temps - (pi - 0.5)) < 1e-8);
assert(numel(iPaire) == 2 && r.signaux.porte(iPaire(1)) > 0 && r.signaux.porte(iPaire(2)) < 0, ...
       'deux pas majeurs encadrent le passage par zero, comme dans Simulink');

% Un sous-système déclenché ne calcule qu'aux fronts : un compteur fait
% d'un retard y compte les fronts, montants, descendants ou les deux. Pas
% de front à la première évaluation, comme dans Simulink.
compteur = new_system('compteur');
compteur = add_block(compteur, 'constant', 'un', 'Value', 1);
compteur = add_block(compteur, 'sum', 'plus', 'Signs', '++');
compteur = add_block(compteur, 'delay', 'avant', 'DelayLength', 1);
compteur = add_block(compteur, 'outport', 'n', 'Port', 1);
compteur = add_block(compteur, 'triggerport', 'Trigger');
compteur = add_line(compteur, 'un', 'plus', 1);
compteur = add_line(compteur, 'avant', 'plus', 2);
compteur = add_line(compteur, 'plus', 'avant');
compteur = add_line(compteur, 'plus', 'n');
fronts = struct('rising', 3, 'falling', 4, 'either', 7);
for type = fieldnames(fronts).'
    m = new_system('fronts');
    m = add_block(m, 'pulsegenerator', 'horloge', 'Period', 1, 'PulseWidth', 50);
    m = add_block(m, 'subsystem', 'compte', 'Model', ...
                  set_param(compteur, 'Trigger', 'TriggerType', type{1}));
    m = add_line(m, 'horloge', 'compte/Trigger');
    for solveur = {'ode1', 'ode45'}
        r = sim(m, 'Solver', solveur{1}, 'StopTime', 3.7, 'FixedStep', 0.01);
        assert(r.signaux.compte(end) == fronts.(type{1}), ...
               sprintf('%s par %s : %g fronts comptes', type{1}, solveur{1}, ...
                       r.signaux.compte(end)));
    end
end
% Activé et déclenché : les fronts ne comptent que pendant l'activation.
activeDeclenche = add_block(set_param(compteur, 'Trigger', 'TriggerType', 'rising'), ...
                   'enableport', 'Enable');
m = new_system('activeDeclenche');
m = add_block(m, 'pulsegenerator', 'horloge', 'Period', 1, 'PulseWidth', 50);
m = add_block(m, 'step', 'autorise', 'Time', 1.5);
m = add_block(m, 'subsystem', 'compte', 'Model', activeDeclenche);
m = add_line(m, 'autorise', 'compte/Enable');
m = add_line(m, 'horloge', 'compte/Trigger');
r = sim(m, 'Solver', 'ode1', 'StopTime', 3.7, 'FixedStep', 0.01);
assert(r.signaux.compte(end) == 2, 'seuls les fronts de 2 et 3 comptent');

% If, deux sous-systèmes d'action et un Merge : la valeur absolue.
positif = new_system('positif');
positif = add_block(positif, 'inport', 'u', 'Port', 1);
positif = add_block(positif, 'outport', 'y', 'Port', 1);
positif = add_block(positif, 'actionport', 'Action');
positif = add_line(positif, 'u', 'y');
negatif = add_block(positif, 'gain', 'moins', 'Gain', -1);
negatif = add_line(delete_line(negatif, 'u', 'y'), 'u', 'moins');
negatif = add_line(negatif, 'moins', 'y');
m = new_system('valeurAbsolue');
m = add_block(m, 'sine', 'u', 'Frequency', 3);
m = add_block(m, 'if', 'si', 'IfExpression', 'u1 > 0');
m = add_block(m, 'subsystem', 'alors', 'Model', positif);
m = add_block(m, 'subsystem', 'sinon', 'Model', negatif);
m = add_block(m, 'merge', 'fusion');
m = add_line(m, 'u', 'si');
m = add_line(m, 'u', 'alors', 1);
m = add_line(m, 'u', 'sinon', 1);
m = add_line(m, 'si/1', 'alors/Ifaction');
m = add_line(m, 'si/2', 'sinon/Ifaction');
m = add_line(m, 'alors', 'fusion', 1);
m = add_line(m, 'sinon', 'fusion', 2);
for solveur = {'ode4', 'ode45'}
    r = sim(m, 'Solver', solveur{1}, 'StopTime', 3, 'FixedStep', 0.01);
    assert(max(abs(r.signaux.fusion - abs(sin(3 * r.temps)))) < 1e-12, ...
           [solveur{1} ' : le Merge rend la branche choisie']);
end
% Trois branches — if, elseif, else — sur deux entrées.
m = new_system('troisBranches');
m = add_block(m, 'clock', 't');
m = add_block(m, 'constant', 'seuil', 'Value', 2);
m = add_block(m, 'if', 'si', 'NumInputs', 2, 'IfExpression', 'u1 < 1', ...
              'ElseIfExpressions', 'u1 < u2');
valeurs = [10 20 30];
for j = 1:3
    branche = new_system(sprintf('branche%d', j));
    branche = add_block(branche, 'constant', 'v', 'Value', valeurs(j));
    branche = add_block(branche, 'outport', 'y', 'Port', 1);
    branche = add_block(branche, 'actionport', 'Action');
    branche = add_line(branche, 'v', 'y');
    m = add_block(m, 'subsystem', sprintf('b%d', j), 'Model', branche);
    m = add_line(m, sprintf('si/%d', j), sprintf('b%d/Ifaction', j));
end
m = add_block(m, 'merge', 'fusion', 'Inputs', 3);
m = add_line(m, 't', 'si', 1);
m = add_line(m, 'seuil', 'si', 2);
for j = 1:3
    m = add_line(m, sprintf('b%d', j), 'fusion', j);
end
r = sim(m, 'Solver', 'ode1', 'StopTime', 3, 'FixedStep', 0.25);
attendu = 10 * (r.temps < 1) + 20 * (r.temps >= 1 & r.temps < 2) + 30 * (r.temps >= 2);
assert(isequal(r.signaux.fusion, attendu), 'if, elseif, else');
% Switch Case, avec un défaut.
m = new_system('parCas');
m = add_block(m, 'clock', 't');
m = add_block(m, 'rounding', 'entier', 'Operator', 'floor');
m = add_block(m, 'switchcase', 'selon', 'CaseConditions', '{0, [1 2]}');
m = add_line(m, 't', 'entier');
m = add_line(m, 'entier', 'selon');
for j = 1:3
    branche = new_system(sprintf('cas%d', j));
    branche = add_block(branche, 'constant', 'v', 'Value', valeurs(j));
    branche = add_block(branche, 'outport', 'y', 'Port', 1);
    branche = add_block(branche, 'actionport', 'Action');
    branche = add_line(branche, 'v', 'y');
    m = add_block(m, 'subsystem', sprintf('c%d', j), 'Model', branche);
    m = add_line(m, sprintf('selon/%d', j), sprintf('c%d/Ifaction', j));
end
m = add_block(m, 'merge', 'fusion', 'Inputs', 3, 'InitialOutput', -5);
for j = 1:3
    m = add_line(m, sprintf('c%d', j), 'fusion', j);
end
r = sim(m, 'Solver', 'ode1', 'StopTime', 4, 'FixedStep', 0.5);
attendu = 10 * (r.temps < 1) + 20 * (r.temps >= 1 & r.temps < 3) + 30 * (r.temps >= 3);
assert(isequal(r.signaux.fusion, attendu), 'le cas 0, les cas 1 et 2, puis le defaut');

% Emboîtés : un sous-système activé dans un sous-système activé ne
% calcule que quand les deux le permettent.
dedans = set_param(interne, 'Enable', 'StatesWhenEnabling', 'held');
milieu = new_system('milieu');
milieu = add_block(milieu, 'inport', 'e', 'Port', 1);
milieu = add_block(milieu, 'subsystem', 'dedans', 'Model', dedans);
milieu = add_block(milieu, 'outport', 's', 'Port', 1);
milieu = add_block(milieu, 'enableport', 'Enable');
milieu = add_line(milieu, 'e', 'dedans/Enable');
milieu = add_line(milieu, 'dedans', 's');
m = new_system('emboites');
m = add_block(m, 'step', 'exterieur', 'Time', 1);
m = add_block(m, 'pulsegenerator', 'inter2', 'Period', 1, 'PulseWidth', 50);
m = add_block(m, 'subsystem', 'milieu', 'Model', milieu);
m = add_line(m, 'inter2', 'milieu', 1);
m = add_line(m, 'exterieur', 'milieu/Enable');
r = sim(m, 'Solver', 'ode45', 'StopTime', 3.2);
% Actif quand t >= 1 et que l'impulsion est haute : [1,1.5), [2,2.5), [3,3.2].
assert(abs(r.signaux.milieu(end) - 1.2) < 1e-9, 'les deux gardes s''ajoutent');

% Les sous-systèmes conditionnels de la bibliothèque arrivent garnis : In1
% relié à Out1, et leurs ports de contrôle, qui comptent comme entrées.
gabarits = {'Enabled Subsystem', 2; 'Triggered Subsystem', 2; ...
            'Enabled and Triggered Subsystem', 3; 'If Action Subsystem', 2; ...
            'simulink/Ports & Subsystems/Switch Case Action Subsystem', 2};
for kG = 1:size(gabarits, 1)
    m = add_block(new_system('gabarit'), gabarits{kG, 1}, 'sous');
    ports = get_param(m, 'sous', 'Ports');
    assert(ports(1) == gabarits{kG, 2} && ports(2) == 1, ...
           [gabarits{kG, 1} ' : ses entrees, controles compris']);
end
m = new_system('gabaritActive');
m = add_block(m, 'Enabled Subsystem', 'es');
m = add_block(m, 'step', 'porte', 'Time', 0.5);
m = add_block(m, 'constant', 'entree', 'Value', 3);
m = add_line(m, 'entree', 'es', 1);
m = add_line(m, 'porte', 'es/Enable');
r = sim(m, 'Solver', 'ode1', 'StopTime', 1, 'FixedStep', 0.25);
assert(isequal(r.signaux.es.', [0 0 3 3 3]), 'In1 passe a Out1 des que Enable s''allume');

% Les erreurs des sous-systèmes conditionnels.
continu = add_block(compteur, 'integrator', 'intrus');
continu = add_line(continu, 'un', 'intrus');
avecContinu = add_block(new_system('declencheContinu'), 'subsystem', 'compte', ...
                        'Model', continu);
deuxEnable = add_block(add_block(interne, 'enableport', 'Enable2'), 'triggerport', 'T');
deuxEnable = add_block(new_system('deuxPorts'), 'subsystem', 'sous', 'Model', ...
                       add_block(deuxEnable, 'enableport', 'Enable3'));
actionEtEnable = add_block(new_system('melange'), 'subsystem', 'sous', 'Model', ...
                           add_block(interne, 'actionport', 'Action'));
siFaux = add_block(new_system('siFaux'), 'if', 'si', 'IfExpression', 'u1 > inconnue');
casFaux = add_block(new_system('casFaux'), 'switchcase', 'selon', 'CaseConditions', ...
                    '{1.5}');
casErreurs = {
    @() sim(avecContinu), 'Simulink:blocks:TriggeredSubsystemContinuousStates', 'compte/intrus'
    @() sim(deuxEnable), 'Simulink:blocks:ControlPortDuplicate', 'sous'
    @() sim(actionEtEnable), 'Simulink:blocks:ActionPortWithEnableTrigger', 'sous'
    @() sim(siFaux), 'Simulink:blocks:IfExpressionInvalid', 'siFaux/si'
    @() sim(casFaux), 'Simulink:blocks:SwitchCaseConditionsInvalid', 'casFaux/selon'
    @() add_line(add_block(new_system('x'), 'subsystem', 'sous', 'Model', interne), ...
                 'sous', 'sous/Trigger'), 'Simulink:Commands:AddLineInvalidPort', 'Trigger'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('conditionnels, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('sous-systemes conditionnels : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------------------------------ 15. Blocs de code et Stateflow
% Fcn : une expression de u, écrite comme en MATLAB ou comme dans
% Simulink (u[2]), qui lit l'espace de travail au moment de simuler.
m = new_system('fonctions');
m = add_block(m, 'clock', 't');
m = add_block(m, 'constant', 'deux', 'Value', 2);
m = add_block(m, 'mux', 'mx', 'Inputs', 2);
m = add_block(m, 'fcn', 'f', 'Expr', 'u[2]*sin(u(1)) + decalageFcn');
m = add_block(m, 'interpretedmatlabfunction', 'g', 'MATLABFcn', 'cos');
m = add_block(m, 'interpretedmatlabfunction', 'h', 'MATLABFcn', 'u * [1 2 3]', ...
              'OutputDimensions', 3);
m = add_line(m, 't', 'mx', 1);
m = add_line(m, 'deux', 'mx', 2);
m = add_line(m, 'mx', 'f');
m = add_line(m, 't', 'g');
m = add_line(m, 't', 'h');
assignin('base', 'decalageFcn', 0.5);
r = sim(m, 'Solver', 'ode1', 'StopTime', 1, 'FixedStep', 0.1);
assert(max(abs(r.signaux.f - (2 * sin(r.temps) + 0.5))) < 1e-14, 'Fcn : u[2]*sin(u(1)) + une variable');
assert(max(abs(r.signaux.g - cos(r.temps))) < 1e-14, 'Interpreted MATLAB Function : un nom de fonction');
assert(isequal(size(r.signaux.h), [11 3]) && max(max(abs(r.signaux.h - r.temps * [1 2 3]))) < 1e-14, ...
       'Interpreted MATLAB Function : une expression, trois sorties');

% MATLAB Function : deux arguments, deux sorties, une variable persistante.
% La persistante compte les appels : un par pas majeur, et elle repart de
% zéro à chaque simulation.
script = sprintf(['function [somme, appels] = f(a, b)\n' ...
                  'persistent n\n' ...
                  'if isempty(n)\n' ...
                  '    n = 0;\n' ...
                  'end\n' ...
                  'n = n + 1;\n' ...
                  'somme = a + b;\n' ...
                  'appels = n;\n']);
m = new_system('mfb');
m = add_block(m, 'clock', 't');
m = add_block(m, 'constant', 'c', 'Value', [1; 2]);
m = add_block(m, 'matlabfunction', 'f', 'Script', script);
m = add_line(m, 't', 'f', 1);
m = add_line(m, 'c', 'f', 2);
[ne, ns] = matlibre_sl_ports(struct('type', 'matlabfunction', 'nom', 'f', ...
                                    'parametres', struct('Script', script)));
assert(ne == 2 && ns == 2, 'les arguments font les entrees, les sorties les sorties');
for essai = 1:2
    r = sim(m, 'Solver', 'ode4', 'StopTime', 1, 'FixedStep', 0.1);
    assert(isequal(size(r.signaux.f), [11 2]) && ...
           max(max(abs(r.signaux.f - (r.temps + [1 2])))) < 1e-14, 'la somme d''un scalaire et d''un vecteur');
    assert(isequal(r.signaux.f_port2.', 1:11), ...
           'un appel par pas majeur, et la persistante repart a chaque simulation');
end

% S-fonctions de niveau 1 : une continue, x' = -a x + u, y = 2 x ; une
% discrète qui compte ses instants.
dossierSfn = tempname();
mkdir(dossierSfn);
f = fopen(fullfile(dossierSfn, 'sfnPremierOrdre.m'), 'w');
fprintf(f, ['function [sys, x0, str, ts] = sfnPremierOrdre(t, x, u, flag, a)\n' ...
            'switch flag\n' ...
            '    case 0\n' ...
            '        sys = [1, 0, 1, 1, 0, 0, 1]; x0 = 0; str = []; ts = [0 0];\n' ...
            '    case 1\n' ...
            '        sys = -a * x + u; x0 = []; str = []; ts = [];\n' ...
            '    case 3\n' ...
            '        sys = 2 * x; x0 = []; str = []; ts = [];\n' ...
            '    otherwise\n' ...
            '        sys = []; x0 = []; str = []; ts = [];\n' ...
            'end\n']);
fclose(f);
f = fopen(fullfile(dossierSfn, 'sfnCompteur.m'), 'w');
fprintf(f, ['function [sys, x0, str, ts] = sfnCompteur(t, x, u, flag)\n' ...
            'switch flag\n' ...
            '    case 0\n' ...
            '        sys = [0, 1, 1, 0, 0, 0, 1]; x0 = 0; str = []; ts = [0.1 0];\n' ...
            '    case 2\n' ...
            '        sys = x + 1; x0 = []; str = []; ts = [];\n' ...
            '    case 3\n' ...
            '        sys = x; x0 = []; str = []; ts = [];\n' ...
            '    otherwise\n' ...
            '        sys = []; x0 = []; str = []; ts = [];\n' ...
            'end\n']);
fclose(f);
addpath(dossierSfn);
m = new_system('sfn');
m = add_block(m, 'step', 'e', 'Time', 0);
m = add_block(m, 'sfunction', 's', 'FunctionName', 'sfnPremierOrdre', 'Parameters', '3');
m = add_line(m, 'e', 's');
r = sim(m, 'Solver', 'ode45', 'StopTime', 2, 'RelTol', 1e-8);
assert(max(abs(r.signaux.s - 2 * (1 - exp(-3 * r.temps)) / 3)) < 1e-6, ...
       'la S-fonction continue integre ses derivees');
m = add_block(new_system('sfnDiscrete'), 'sfunction', 's', 'FunctionName', 'sfnCompteur');
r = sim(m, 'Solver', 'FixedStepDiscrete', 'StopTime', 0.5, 'FixedStep', 0.05);
assert(isequal(r.signaux.s.', [0 0 1 1 2 2 3 3 4 4 5]), ...
       'la S-fonction discrete avance a sa periode, 0,1');
rmpath(dossierSfn);

% Stateflow : un thermostat. La machine chauffe sous 19 degres et s'arrête
% au-dessus de 21 ; la pièce perd vers l'extérieur. Le diagramme fait un
% pas par pas majeur ; la température reste dans la bande.
machine = sfchart('thermostat');
machine = sfstate(machine, 'arret', @(c) setfield(c, 'chauffe', 0));
machine = sfstate(machine, 'marche', @(c) setfield(c, 'chauffe', 1));
machine = sftransition(machine, 'arret', 'marche', @(c, u) u < 19);
machine = sftransition(machine, 'marche', 'arret', @(c, u) u > 21);
m = new_system('piece');
m = add_block(m, 'chart', 'regulateur', 'Chart', machine, 'Outputs', {'chauffe', 'etat'}, ...
              'InitialContext', struct('chauffe', 0));
m = add_block(m, 'gain', 'puissance', 'Gain', 5);
m = add_block(m, 'sum', 'bilan', 'Signs', '+-');
m = add_block(m, 'gain', 'pertes', 'Gain', 0.2);
m = add_block(m, 'constant', 'exterieur', 'Value', 10);
m = add_block(m, 'sum', 'ecart', 'Signs', '+-');
m = add_block(m, 'integrator', 'temperature', 'InitialCondition', 20);
m = add_line(m, 'temperature', 'regulateur');
m = add_line(m, 'regulateur', 'puissance');
m = add_line(m, 'temperature', 'ecart', 1);
m = add_line(m, 'exterieur', 'ecart', 2);
m = add_line(m, 'ecart', 'pertes');
m = add_line(m, 'puissance', 'bilan', 1);
m = add_line(m, 'pertes', 'bilan', 2);
m = add_line(m, 'bilan', 'temperature');
r = sim(m, 'Solver', 'ode4', 'StopTime', 30, 'FixedStep', 0.05);
apres = r.temps > 5;
assert(min(r.signaux.temperature(apres)) > 18.9 && max(r.signaux.temperature(apres)) < 21.1, ...
       'le thermostat tient la piece entre 19 et 21');
assert(all(r.signaux.regulateur_port2 == r.signaux.regulateur + 1), ...
       'etat 1 : arret, chauffe 0 ; etat 2 : marche, chauffe 1');
% La machine suit la règle de Stateflow : on vérifie chaque pas contre
% SFSTEP appliqué à la température relevée au pas.
courant = '';
contexte = struct('chauffe', 0);
for i = 1:numel(r.temps)
    [courant, contexte] = sfstep(machine, courant, contexte, r.signaux.temperature(i));
    assert(contexte.chauffe == r.signaux.regulateur(i), 'le bloc fait le pas de SFSTEP');
end

% Les erreurs des blocs de code.
casErreurs = {
    @() sim(add_block(new_system('e1'), 'fcn', 'f', 'Expr', 'u(1) +')), ...
        'Simulink:blocks:FcnExpressionInvalid', 'e1/f'
    @() sim(add_block(new_system('e2'), 'fcn', 'f', 'Expr', '[u u]')), ...
        'Simulink:blocks:FcnOutputDimension', 'e2/f'
    @() sim(add_block(new_system('e3'), 'interpretedmatlabfunction', 'g', 'MATLABFcn', ...
                      'u * [1 2]', 'OutputDimensions', 3)), ...
        'Simulink:blocks:FcnOutputDimension', 'e3/g'
    @() sim(add_block(new_system('e4'), 'matlabfunction', 'f', 'Script', ...
                      sprintf('function y = f(u)\ny = inconnue(u);'))), ...
        'Simulink:blocks:MATLABFunctionError', 'e4/f'
    @() sim(add_block(new_system('e5'), 'sfunction', 's', 'FunctionName', 'pasUneSfonction')), ...
        'Simulink:blocks:SFunctionNotFound', 'e5/s'
    @() sim(add_block(new_system('e6'), 'chart', 'c')), 'Simulink:blocks:ChartMachineMissing', 'e6/c'
    @() sim(add_block(new_system('e7'), 'chart', 'c', 'Chart', machine, 'Outputs', {'absent'})), ...
        'Simulink:blocks:ChartOutputMissing', 'absent'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('blocs de code, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('blocs de code et Stateflow : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% --------------------------------------------- 16. Fichiers .slx et .mdl
% Un .slx écrit dans la disposition de Simulink — le modèle dans
% blockdiagram.xml, les systèmes dans systems/, la configuration dans
% configSet0.xml, un bloc de bibliothèque en Reference, un lien ramifié
% — se lit en un modèle qui simule ce que le schéma dit.
dossierSlx = tempname();
mkdir(fullfile(dossierSlx, 'simulink', 'systems'));
mkdir(fullfile(dossierSlx, '_rels'));
parties = {
    '[Content_Types].xml', ['<?xml version="1.0" encoding="utf-8"?><Types xmlns="http://' ...
        'schemas.openxmlformats.org/package/2006/content-types"><Default Extension="xml" ' ...
        'ContentType="application/vnd.mathworks.simulink.model+xml"/></Types>']
    fullfile('simulink', 'blockdiagram.xml'), ['<?xml version="1.0" encoding="utf-8"?>' ...
        '<ModelInformation Version="1.0"><Model Name="exemple"><P Name="Version">10.4</P>' ...
        '<BlockParameterDefaults><Block BlockType="Gain"><P Name="Gain">1</P>' ...
        '<P Name="Multiplication">Element-wise(K.*u)</P></Block><Block BlockType="Integrator">' ...
        '<P Name="InitialCondition">0</P></Block></BlockParameterDefaults>' ...
        '<System Ref="system_root"/></Model></ModelInformation>']
    fullfile('simulink', 'configSet0.xml'), ['<?xml version="1.0" encoding="utf-8"?>' ...
        '<ConfigSet><Object PropName="Components" ObjectID="2" ClassName="Simulink.SolverCC">' ...
        '<P Name="StartTime">0.0</P><P Name="StopTime">2</P><P Name="SolverType">Fixed-step</P>' ...
        '<P Name="Solver">ode4</P><P Name="FixedStep">0.01</P></Object>' ...
        '<Object PropName="Components" ObjectID="3" ClassName="Simulink.DebuggingCC">' ...
        '<P Name="AlgebraicLoopMsg">warning</P></Object></ConfigSet>']
    fullfile('simulink', 'systems', 'system_root.xml'), ['<?xml version="1.0" encoding="utf-8"?>' ...
        '<System><P Name="Location">[0, 0, 800, 600]</P>' ...
        '<Block BlockType="Step" Name="Step" SID="1"><P Name="Position">[40, 90, 70, 120]</P>' ...
        '<P Name="Time">0.5</P></Block>' ...
        '<Block BlockType="Sum" Name="Sum" SID="2"><P Name="Ports">[2, 1]</P>' ...
        '<P Name="IconShape">round</P><P Name="Inputs">|+-</P></Block>' ...
        '<Block BlockType="Gain" Name="Gain" SID="3"><P Name="Gain">4</P></Block>' ...
        '<Block BlockType="Integrator" Name="Integrator" SID="4"/>' ...
        '<Block BlockType="Reference" Name="Ramp" SID="5"><P Name="SourceBlock">' ...
        'simulink/Sources/Ramp</P><P Name="SourceType">Ramp</P><InstanceData>' ...
        '<P Name="slope">0.5</P><P Name="start">0</P><P Name="X0">1</P></InstanceData></Block>' ...
        '<Block BlockType="SubSystem" Name="Subsystem" SID="6"><P Name="Ports">[1, 1]</P>' ...
        '<System Ref="system_6"/></Block>' ...
        '<Block BlockType="Scope" Name="Scope" SID="9"><P Name="NumInputPorts">2</P></Block>' ...
        '<Line><P Name="Src">1#out:1</P><P Name="Dst">2#in:1</P></Line>' ...
        '<Line><P Name="Src">2#out:1</P><P Name="Dst">3#in:1</P></Line>' ...
        '<Line><P Name="Src">3#out:1</P><P Name="Dst">4#in:1</P></Line>' ...
        '<Line><P Name="Src">4#out:1</P><Branch><P Name="Dst">2#in:2</P></Branch>' ...
        '<Branch><P Name="Dst">6#in:1</P></Branch></Line>' ...
        '<Line><P Name="Src">6#out:1</P><P Name="Dst">9#in:1</P></Line>' ...
        '<Line><P Name="Src">5#out:1</P><P Name="Dst">9#in:2</P></Line></System>']
    fullfile('simulink', 'systems', 'system_6.xml'), ['<?xml version="1.0" encoding="utf-8"?>' ...
        '<System><Block BlockType="Inport" Name="In1" SID="7"/>' ...
        '<Block BlockType="Gain" Name="Double" SID="8"><P Name="Gain">2</P></Block>' ...
        '<Block BlockType="Outport" Name="Out1" SID="10"/>' ...
        '<Line><P Name="Src">7#out:1</P><P Name="Dst">8#in:1</P></Line>' ...
        '<Line><P Name="Src">8#out:1</P><P Name="Dst">10#in:1</P></Line></System>']
    };
for kP = 1:size(parties, 1)
    identifiant = fopen(fullfile(dossierSlx, parties{kP, 1}), 'w');
    fprintf(identifiant, '%s', parties{kP, 2});
    fclose(identifiant);
end
fichierSlx = fullfile(tempdir(), 'exemple.slx');
zip(fichierSlx, {'[Content_Types].xml', 'simulink'}, dossierSlx);
lu = load_system(fichierSlx);
assert(strcmp(lu.nom, 'exemple') && numel(lu.blocs) == 7, 'le modele, ses sept blocs');
assert(strcmp(get_param(lu, 'Ramp', 'BlockType'), 'ramp') && ...
       strcmp(get_param(lu, 'Sum', 'Signs'), '|+-'), ...
       'un bloc de bibliotheque par son chemin, un parametre par son nom Simulink');
assert(strcmp(get_param(lu, 'Solver'), 'ode4') && get_param(lu, 'FixedStep') == 0.01, ...
       'la configuration du solveur');
% Le même schéma, bâti à la main : la simulation est la même, au bit près.
sousDouble = add_line(add_line(add_block(add_block(add_block(new_system('Subsystem'), ...
    'inport', 'In1', 'Port', 1), 'gain', 'Double', 'Gain', 2), 'outport', 'Out1', 'Port', 1), ...
    'In1', 'Double'), 'Double', 'Out1');
m = new_system('exemple');
m = add_block(m, 'step', 'Step', 'Time', 0.5);
m = add_block(m, 'sum', 'Sum', 'Signs', '|+-');
m = add_block(m, 'gain', 'Gain', 'Gain', 4);
m = add_block(m, 'integrator', 'Integrator');
m = add_block(m, 'ramp', 'Ramp', 'Slope', 0.5, 'InitialOutput', 1);
m = add_block(m, 'subsystem', 'Subsystem', 'Model', sousDouble);
m = add_block(m, 'scope', 'Scope', 'NumInputPorts', 2);
m = add_line(m, 'Step', 'Sum', 1);
m = add_line(m, 'Sum', 'Gain');
m = add_line(m, 'Gain', 'Integrator');
m = add_line(m, 'Integrator', 'Sum', 2);
m = add_line(m, 'Integrator', 'Subsystem');
m = add_line(m, 'Subsystem', 'Scope', 1);
m = add_line(m, 'Ramp', 'Scope', 2);
rLu = sim(lu);
rMain = sim(m, 'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 2);
assert(isequal(rLu.temps, rMain.temps) && isequal(rLu.signaux.Scope, rMain.signaux.Scope), ...
       'le .slx simule ce que le schema dit');

% Le même modèle en .mdl, le format texte : sections emboîtées, liens par
% noms de blocs, branches.
texteMdl = sprintf(['Model {\n  Name "exemple"\n  Array {\n    Type "Handle"\n' ...
    '    Simulink.ConfigSet {\n      Array {\n        Simulink.SolverCC {\n' ...
    '          StartTime "0.0"\n          StopTime "2"\n          SolverType "Fixed-step"\n' ...
    '          Solver "ode4"\n          FixedStep "0.01"\n        }\n      }\n    }\n  }\n' ...
    '  System {\n    Name "exemple"\n' ...
    '    Block {\n      BlockType Step\n      Name "Step"\n      SID "1"\n' ...
    '      Position [40, 90, 70, 120]\n      Time "0.5"\n    }\n' ...
    '    Block {\n      BlockType Sum\n      Name "Sum"\n      Inputs "|+-"\n    }\n' ...
    '    Block {\n      BlockType Gain\n      Name "Gain"\n      Gain "4"\n    }\n' ...
    '    Block {\n      BlockType Integrator\n      Name "Integrator"\n    }\n' ...
    '    Block {\n      BlockType Reference\n      Name "Ramp"\n' ...
    '      SourceBlock "simulink/Sources/Ramp"\n      slope "0.5"\n      X0 "1"\n    }\n' ...
    '    Block {\n      BlockType SubSystem\n      Name "Subsystem"\n      System {\n' ...
    '        Name "Subsystem"\n        Block {\n          BlockType Inport\n          Name "In1"\n' ...
    '        }\n        Block {\n          BlockType Gain\n          Name "Double"\n' ...
    '          Gain "2"\n        }\n        Block {\n          BlockType Outport\n' ...
    '          Name "Out1"\n        }\n        Line {\n          SrcBlock "In1"\n' ...
    '          SrcPort 1\n          DstBlock "Double"\n          DstPort 1\n        }\n' ...
    '        Line {\n          SrcBlock "Double"\n          SrcPort 1\n          DstBlock "Out1"\n' ...
    '          DstPort 1\n        }\n      }\n    }\n' ...
    '    Block {\n      BlockType Scope\n      Name "Scope"\n      NumInputPorts "2"\n    }\n' ...
    '    Line {\n      SrcBlock "Step"\n      SrcPort 1\n      DstBlock "Sum"\n      DstPort 1\n    }\n' ...
    '    Line {\n      SrcBlock "Sum"\n      SrcPort 1\n      DstBlock "Gain"\n      DstPort 1\n    }\n' ...
    '    Line {\n      SrcBlock "Gain"\n      SrcPort 1\n      DstBlock "Integrator"\n' ...
    '      DstPort 1\n    }\n' ...
    '    Line {\n      SrcBlock "Integrator"\n      SrcPort 1\n      Points [20, 0]\n' ...
    '      Branch {\n        DstBlock "Sum"\n        DstPort 2\n      }\n' ...
    '      Branch {\n        DstBlock "Subsystem"\n        DstPort 1\n      }\n    }\n' ...
    '    Line {\n      SrcBlock "Subsystem"\n      SrcPort 1\n      DstBlock "Scope"\n' ...
    '      DstPort 1\n    }\n' ...
    '    Line {\n      SrcBlock "Ramp"\n      SrcPort 1\n      DstBlock "Scope"\n' ...
    '      DstPort 2\n    }\n  }\n}\n']);
fichierMdl = fullfile(tempdir(), 'exemple.mdl');
identifiant = fopen(fichierMdl, 'w');
fprintf(identifiant, '%s', texteMdl);
fclose(identifiant);
luMdl = load_system(fichierMdl);
rMdl = sim(luMdl);
assert(isequal(rMdl.signaux.Scope, rMain.signaux.Scope), 'le .mdl aussi');

% Un modèle de MatLibre s'écrit en .slx et se relit à l'identique :
% sous-systèmes conditionnels, ports de contrôle et réglages compris.
chrono = new_system('chrono');
chrono = add_block(chrono, 'constant', 'un', 'Value', 1);
chrono = add_block(chrono, 'integrator', 'x');
chrono = add_block(chrono, 'outport', 's', 'Port', 1);
chrono = add_block(chrono, 'enableport', 'Enable');
chrono = add_line(chrono, 'un', 'x');
chrono = add_line(chrono, 'x', 's');
m = new_system('allerRetour');
m = add_block(m, 'pulsegenerator', 'porte', 'Period', 2, 'PulseWidth', 50);
m = add_block(m, 'ramp', 'rampe', 'Slope', 2);
m = add_block(m, 'sum', 'somme', 'Signs', '+-');
m = add_block(m, 'subsystem', 'sous', 'Model', chrono);
m = add_line(m, 'porte', 'sous/Enable');
m = add_line(m, 'sous', 'somme', 1);
m = add_line(m, 'rampe', 'somme', 2);
m = set_param(m, 'Solver', 'ode45', 'StopTime', 3.5, 'RelTol', 1e-5);
fichierEcrit = save_system(m, fullfile(tempdir(), 'allerRetour.slx'));
assert(strcmp(fichierEcrit(end-3:end), '.slx'), 'SAVE_SYSTEM ecrit le .slx demande');
relu = load_system(fichierEcrit);
assert(get_param(relu, 'RelTol') == 1e-5 && strcmp(get_param(relu, 'Solver'), 'ode45'), ...
       'les reglages voyagent');
a = sim(m);
b = sim(relu);
assert(isequal(a.temps, b.temps) && isequal(a.signaux.somme, b.signaux.somme), ...
       'le modele relu simule comme l''original');

% Un bloc sans équivalent est refusé en le nommant — tous ensemble.
identifiant = fopen(fullfile(dossierSlx, 'simulink', 'systems', 'system_root.xml'), 'w');
fprintf(identifiant, '%s', ['<System><Block BlockType="Scope" Name="Scope" SID="1"/>' ...
    '<Block BlockType="Integrator" Name="Integrator" SID="2"/>' ...
    '<Block BlockType="Foo" Name="Inconnu" SID="3"/>' ...
    '<Block BlockType="Reference" Name="Autre" SID="4"><P Name="SourceBlock">' ...
    'maBibliotheque/Bloc</P></Block></System>']);
fclose(identifiant);
delete(fichierSlx);
zip(fichierSlx, {'[Content_Types].xml', 'simulink'}, dossierSlx);
refus = '';
try
    load_system(fichierSlx);
catch err
    refus = err.message;
    assert(strcmp(err.identifier, 'Simulink:slx:BlocsNonReconnus'));
end
assert(~isempty(strfind(refus, 'Inconnu')) && ~isempty(strfind(refus, 'maBibliotheque/Bloc')), ...
       'les blocs sans equivalent sont nommes ensemble');
delete(fichierSlx);
delete(fichierMdl);
delete(fichierEcrit);
disp('fichiers .slx et .mdl : lus, ecrits, relus');

%% ------------------------------------------ 17. Masques et bibliotheques
% Un sous-système masqué : K / (tau s + 1), K et tau étant ses variables
% de masque, que ses blocs intérieurs nomment. Une valeur du masque peut
% nommer une variable de l'espace de travail.
dedans = new_system('premierOrdre');
dedans = add_block(dedans, 'inport', 'u', 'Port', 1);
dedans = add_block(dedans, 'transferfcn', 'h', 'Numerator', 'K', 'Denominator', '[tau 1]');
dedans = add_block(dedans, 'outport', 'y', 'Port', 1);
dedans = add_line(add_line(dedans, 'u', 'h'), 'h', 'y');
m = new_system('masque');
m = add_block(m, 'step', 'e', 'Time', 0);
m = add_block(m, 'subsystem', 'filtre', 'Model', dedans, 'Mask', 'on', ...
              'MaskVariables', 'K=@1;tau=@2;', 'MaskValueString', '1|1', ...
              'MaskPrompts', {'Gain', 'Constante de temps'});
m = add_line(m, 'e', 'filtre');
m = set_param(m, 'filtre', 'K', 3, 'tau', 'constanteMasque');
assignin('base', 'constanteMasque', 0.5);
assert(strcmp(get_param(m, 'filtre', 'K'), '3') && ...
       strcmp(get_param(m, 'filtre', 'MaskValueString'), '3|constanteMasque'), ...
       'une variable de masque se regle comme un parametre');
r = sim(m, 'Solver', 'ode45', 'StopTime', 2, 'RelTol', 1e-8);
assert(max(abs(r.signaux.filtre - 3 * (1 - exp(-r.temps / 0.5)))) < 1e-7, ...
       'les blocs du dedans lisent l''espace du masque');
% Emboîtés : le masque du dedans voit celui du dehors.
exterieur = new_system('exterieur');
exterieur = add_block(exterieur, 'inport', 'u', 'Port', 1);
exterieur = add_block(exterieur, 'subsystem', 'interieur', 'Model', dedans, 'Mask', 'on', ...
                      'MaskVariables', 'K=@1;tau=@2;', 'MaskValueString', '2*G|0.25');
exterieur = add_block(exterieur, 'outport', 'y', 'Port', 1);
exterieur = add_line(add_line(exterieur, 'u', 'interieur'), 'interieur', 'y');
m2 = new_system('emboite');
m2 = add_block(m2, 'step', 'e', 'Time', 0);
m2 = add_block(m2, 'subsystem', 'bloc', 'Model', exterieur, 'Mask', 'on', ...
               'MaskVariables', 'G=@1;', 'MaskValueString', '5');
m2 = add_line(m2, 'e', 'bloc');
r = sim(m2, 'Solver', 'ode45', 'StopTime', 1, 'RelTol', 1e-8);
assert(max(abs(r.signaux.bloc - 10 * (1 - exp(-r.temps / 0.25)))) < 1e-6, ...
       'un masque emboite evalue ses valeurs dans l''espace de celui qui l''englobe');

% Une bibliothèque : ses blocs se posent dans un modèle, liés. La
% bibliothèque changée, le bloc suit ; les valeurs de son masque restent.
bib = new_system('mesBlocs', 'Library');
bib = add_block(bib, 'subsystem', 'Premier ordre', 'Model', dedans, 'Mask', 'on', ...
                'MaskVariables', 'K=@1;tau=@2;', 'MaskValueString', '1|1');
assignin('base', 'mesBlocs', bib);
m = new_system('usage');
m = add_block(m, 'step', 'e', 'Time', 0);
m = add_block(m, 'mesBlocs/Premier ordre', 'filtre', 'K', 3, 'tau', 0.5);
m = add_line(m, 'e', 'filtre');
assert(strcmp(get_param(m, 'filtre', 'ReferenceBlock'), 'mesBlocs/Premier ordre') && ...
       strcmp(get_param(m, 'filtre', 'LinkStatus'), 'resolved'), 'le bloc est lie');
r = sim(m, 'Solver', 'ode45', 'StopTime', 2, 'RelTol', 1e-8);
assert(max(abs(r.signaux.filtre - 3 * (1 - exp(-r.temps / 0.5)))) < 1e-7, ...
       'le bloc de bibliotheque simule avec ses valeurs de masque');
assignin('base', 'mesBlocs', set_param(bib, 'Premier ordre/h', 'Numerator', '2*K'));
r = sim(m, 'Solver', 'ode45', 'StopTime', 2, 'RelTol', 1e-8);
assert(max(abs(r.signaux.filtre - 6 * (1 - exp(-r.temps / 0.5)))) < 1e-7, ...
       'la bibliotheque changee, le bloc lie suit');
evalin('base', 'clear mesBlocs');
lastwarn('');
r = sim(m, 'Solver', 'ode45', 'StopTime', 2, 'RelTol', 1e-8);
[~, idAvert] = lastwarn();
assert(strcmp(idAvert, 'Simulink:Libraries:MissingSourceBlock') && ...
       max(abs(r.signaux.filtre - 3 * (1 - exp(-r.temps / 0.5)))) < 1e-7, ...
       'la bibliotheque introuvable, la copie sert, en le disant');
casErreurs = {
    @() sim(bib), 'Simulink:Engine:CannotSimulateLibrary', 'mesBlocs'
    @() set_param(m, 'filtre', 'Absente', 1), 'Simulink:Commands:ParamUnknown', 'Absente'
    @() sim(set_param(m, 'filtre', 'MaskVariables', 'K=1;')), ...
        'Simulink:Masks:InvalidMaskVariables', 'K=1'
    @() sim(set_param(m, 'filtre', 'K', 'inconnueDuMasque')), ...
        'Simulink:Commands:ParametreNonEvalue', 'inconnueDuMasque'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('masques, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('masques et bibliotheques : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------------------------------ 18. Bus et types de donnees
% Un bus réunit des signaux sous leurs noms ; un Bus Selector les reprend
% par ces noms, jusque dans un bus emboîté. OutputAsBus les rend en un
% seul signal.
m = new_system('bus');
m = add_block(m, 'clock', 't');
m = add_block(m, 'constant', 'c', 'Value', [1 2 3]);
m = add_block(m, 'sine', 's');
m = add_block(m, 'buscreator', 'mesures', 'Inputs', 'temps,vecteur');
m = add_block(m, 'buscreator', 'tout', 'Inputs', 'mesures,onde');
m = add_block(m, 'busselector', 'choix', 'OutputSignals', 'onde,mesures.vecteur,mesures.temps');
m = add_block(m, 'busselector', 'paquet', 'OutputSignals', 'mesures.vecteur,onde', ...
              'OutputAsBus', 'on');
m = add_block(m, 'buscreator', 'anonyme', 'Inputs', 2);
m = add_block(m, 'busselector', 'second', 'OutputSignals', 'signal2');
m = add_line(m, 't', 'mesures', 1);
m = add_line(m, 'c', 'mesures', 2);
m = add_line(m, 'mesures', 'tout', 1);
m = add_line(m, 's', 'tout', 2);
m = add_line(m, 'tout', 'choix');
m = add_line(m, 'tout', 'paquet');
m = add_line(m, 't', 'anonyme', 1);
m = add_line(m, 's', 'anonyme', 2);
m = add_line(m, 'anonyme', 'second');
r = sim(m, 'Solver', 'ode1', 'StopTime', 1, 'FixedStep', 0.5);
assert(isequal(r.signaux.choix, sin(r.temps)) && isequal(r.signaux.choix_port2, repmat([1 2 3], 3, 1)) && ...
       isequal(r.signaux.choix_port3, r.temps), 'chaque element par son nom, emboite compris');
assert(isequal(r.signaux.paquet, [repmat([1 2 3], 3, 1), sin(r.temps)]), 'OutputAsBus : un seul signal');
assert(isequal(r.signaux.second, sin(r.temps)), 'des elements sans nom s''appellent signal1, signal2');
% Un bus traverse un sous-système, comme un signal.
passe = add_line(add_block(add_block(new_system('passe'), 'inport', 'e', 'Port', 1), ...
                           'outport', 's', 'Port', 1), 'e', 's');
m2 = add_block(m, 'subsystem', 'boite', 'Model', passe);
m2 = add_block(m2, 'busselector', 'apres', 'OutputSignals', 'onde');
m2 = add_line(add_line(m2, 'tout', 'boite'), 'boite', 'apres');
r = sim(m2, 'Solver', 'ode1', 'StopTime', 1, 'FixedStep', 0.5);
assert(isequal(r.signaux.apres, sin(r.temps)), 'le bus traverse un sous-systeme');

% Data Type Conversion : le signal prend les valeurs que le type admet —
% arrondi selon RndMeth, replié modulo 2^n ou saturé.
m = add_block(new_system('types'), 'ramp', 'r', 'Slope', 100, 'InitialOutput', -0.5);
conversions = {
    'i8', {'OutDataTypeStr', 'int8'}, @(u) mod(fix(u) + 128, 256) - 128
    'i8s', {'OutDataTypeStr', 'int8', 'SaturateOnIntegerOverflow', 'on', 'RndMeth', 'Round'}, ...
        @(u) min(max(round(u), -128), 127)
    'u8f', {'OutDataTypeStr', 'uint8', 'RndMeth', 'Floor', 'SaturateOnIntegerOverflow', 'on'}, ...
        @(u) min(max(floor(u), 0), 255)
    'i16c', {'OutDataTypeStr', 'int16', 'RndMeth', 'Ceiling'}, @(u) ceil(u)
    'sgl', {'OutDataTypeStr', 'single'}, @(u) double(single(u))
    'bool', {'OutDataTypeStr', 'boolean'}, @(u) double(u ~= 0)
    };
for kC = 1:size(conversions, 1)
    m = add_block(m, 'datatypeconversion', conversions{kC, 1}, conversions{kC, 2}{:});
    m = add_line(m, 'r', conversions{kC, 1});
end
r = sim(m, 'Solver', 'ode1', 'StopTime', 3, 'FixedStep', 0.3);
for kC = 1:size(conversions, 1)
    assert(isequal(r.signaux.(conversions{kC, 1}), conversions{kC, 3}(r.signaux.r)), ...
           [conversions{kC, 1} ' : la conversion de Simulink']);
end
casErreurs = {
    @() sim(set_param(add_line(add_block(add_block(new_system('b1'), 'constant', 'c'), ...
        'busselector', 'b'), 'c', 'b'), 'b', 'OutputSignals', 'x')), ...
        'Simulink:Bus:SelectorInputNotBus', 'b1/b'
    @() sim(set_param(m2, 'choix', 'OutputSignals', 'mesures.absent')), ...
        'Simulink:Bus:SelectorElementNotFound', 'mesures.absent'
    @() sim(set_param(m2, 'choix', 'OutputSignals', 'onde.x')), ...
        'Simulink:Bus:SelectorElementNotFound', 'n''est pas un bus'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('bus, cas %d : %s attendu, %s rendu (%s)', kE, casErreurs{kE, 2}, vu, message));
end
fprintf('bus et types : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------------------------------ 19. Tous les solveurs de Simulink
% Les solveurs à pas fixe qui manquaient : ode8 converge à l'ordre huit,
% ode1be à l'ordre un, ode14x à l'ordre de son extrapolation — quel que
% soit le nombre d'itérations de Newton sur ce modèle linéaire.
m = new_system('ordresHauts');
m = add_block(m, 'integrator', 'x', 'InitialCondition', 1);
m = add_block(m, 'gain', 'k', 'Gain', -1);
m = add_block(m, 'sine', 'force', 'Frequency', 2);
m = add_block(m, 'sum', 's', 'Signs', '++');
m = add_line(m, 'x', 'k');
m = add_line(m, 'k', 's', 1);
m = add_line(m, 'force', 's', 2);
m = add_line(m, 's', 'x');
exacte = @(t) 7 / 5 * exp(-t) + (sin(2 * t) - 2 * cos(2 * t)) / 5;
casOrdres = {
    'ode8',   {},                                                   8, [0.8 0.4 0.2]
    'ode1be', {},                                                   1, [0.1 0.05 0.025]
    'ode14x', {},                                                   4, [0.2 0.1 0.05]
    'ode14x', {'ExtrapolationOrder', 2},                            2, [0.1 0.05 0.025]
    'ode14x', {'ExtrapolationOrder', 3, 'NumberNewtonIterations', 3}, 3, [0.2 0.1 0.05]
    };
for kS = 1:size(casOrdres, 1)
    erreurs = zeros(1, 3);
    for kP = 1:3
        r = sim(m, 'Solver', casOrdres{kS, 1}, 'FixedStep', casOrdres{kS, 4}(kP), ...
                'StopTime', 4, casOrdres{kS, 2}{:});
        erreurs(kP) = abs(r.signaux.x(end) - exacte(4));
    end
    mesure = log2(erreurs(2) / erreurs(3));
    assert(abs(mesure - casOrdres{kS, 3}) < 0.35, ...
           sprintf('%s converge a l''ordre %g, non %d', casOrdres{kS, 1}, mesure, ...
                   casOrdres{kS, 3}));
end

% Un système raide, x' = 1000 (cos t - x). Au pas de 0,05 s, Euler
% explicite diverge ; ode1be et ode14x, implicites, suivent la solution.
m = new_system('raide');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'trigonometry', 'consigne', 'Operator', 'cos');
m = add_block(m, 'sum', 'ecart', 'Signs', '+-');
m = add_block(m, 'gain', 'raideur', 'Gain', 1000);
m = add_block(m, 'integrator', 'x');
m = add_line(m, 'horloge', 'consigne');
m = add_line(m, 'consigne', 'ecart', 1);
m = add_line(m, 'x', 'ecart', 2);
m = add_line(m, 'ecart', 'raideur');
m = add_line(m, 'raideur', 'x');
lambda = 1000;
exacteRaide = @(t) (lambda ^ 2 * cos(t) + lambda * sin(t)) / (lambda ^ 2 + 1) - ...
                   lambda ^ 2 / (lambda ^ 2 + 1) * exp(-lambda * t);
rEuler = sim(m, 'Solver', 'ode1', 'FixedStep', 0.05, 'StopTime', 2);
assert(~(abs(rEuler.signaux.x(end)) < 10), 'Euler explicite diverge sur le systeme raide');
for solveur = {'ode1be', 'ode14x'}
    r = sim(m, 'Solver', solveur{1}, 'FixedStep', 0.05, 'StopTime', 2);
    assert(abs(r.signaux.x(end) - exacteRaide(2)) < 1e-4, ...
           [solveur{1} ' : l''implicite tient le systeme raide au grand pas']);
end
% À pas variable, les solveurs raides le traversent en bien moins de pas
% qu'ode45 et ode113, que la stabilité bride ; tous tiennent la tolérance.
r45 = sim(m, 'Solver', 'ode45', 'StopTime', 2, 'RelTol', 1e-4, 'MaxStep', Inf);
for solveur = {'ode15s', 'ode23t', 'ode23tb', 'ode23s'}
    r = sim(m, 'Solver', solveur{1}, 'StopTime', 2, 'RelTol', 1e-4, 'MaxStep', Inf);
    assert(numel(r.temps) * 5 < numel(r45.temps), ...
           sprintf('%s : %d pas, contre %d pour ode45', solveur{1}, numel(r.temps), ...
                   numel(r45.temps)));
    assert(max(abs(r.signaux.x - exacteRaide(r.temps))) < 2e-3, ...
           [solveur{1} ' : la solution du systeme raide']);
end
r113 = sim(m, 'Solver', 'ode113', 'StopTime', 2, 'RelTol', 1e-4, 'MaxStep', Inf);
assert(max(abs(r113.signaux.x - exacteRaide(r113.temps))) < 2e-3, ...
       'ode113 tient le systeme raide, a petits pas');

% La tolérance commande l'erreur, pour chaque nouveau solveur à pas
% variable : plus fine, une erreur plus petite et plus de pas.
m = new_system('decroissance');
m = add_block(m, 'gain', 'k', 'Gain', -1);
m = add_block(m, 'integrator', 'x', 'InitialCondition', 1);
m = add_line(m, 'x', 'k');
m = add_line(m, 'k', 'x');
nouveaux = {'ode113', 'ode15s', 'ode23t', 'ode23tb'};
for solveur = nouveaux
    erreurs = zeros(1, 3);
    nombresDePas = zeros(1, 3);
    tolerances = [1e-3 1e-5 1e-7];
    for kT = 1:3
        r = sim(m, 'Solver', solveur{1}, 'RelTol', tolerances(kT), 'MaxStep', Inf, ...
                'StopTime', 5);
        erreurs(kT) = max(abs(r.signaux.x - exp(-r.temps)));
        nombresDePas(kT) = numel(r.temps) - 1;
        assert(erreurs(kT) < 100 * tolerances(kT), ...
               sprintf('%s : erreur %g pour la tolerance %g', solveur{1}, erreurs(kT), ...
                       tolerances(kT)));
    end
    assert(all(diff(erreurs) < 0) && all(diff(nombresDePas) > 0), ...
           [solveur{1} ' : une tolerance plus fine, une erreur plus petite et plus de pas']);
end
% L'ordre maximal d'ode15s : plus il est haut, moins il faut de pas à
% tolérance fine.
pasParOrdre = zeros(1, 3);
ordresMax = [1 3 5];
for kO = 1:3
    r = sim(m, 'Solver', 'ode15s', 'RelTol', 1e-6, 'StopTime', 5, 'MaxStep', Inf, ...
            'MaxOrder', ordresMax(kO));
    pasParOrdre(kO) = numel(r.temps);
    assert(max(abs(r.signaux.x - exp(-r.temps))) < 1e-3, ...
           sprintf('ode15s d''ordre au plus %d tient la tolerance', ordresMax(kO)));
end
assert(all(diff(pasParOrdre) < 0), 'un ordre maximal plus haut, moins de pas');

% Chaque nouveau solveur croise les autres familles de blocs : blocs
% échantillonnés à deux cadences, cassures des sources, passage par zéro
% d'une saturation, intégrateur borné, retard pur, boucle algébrique,
% arrêt. À chaque discontinuité, la mémoire des pas multiples repart.
modeles = struct();
m = new_system('multicadence');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'zoh', 'lent', 'SampleTime', 0.3);
m = add_block(m, 'discretetransferfcn', 'filtre', 'Numerator', [0 0.4], ...
              'Denominator', [1 -0.6], 'SampleTime', [0.2 0.05]);
m = add_block(m, 'integrator', 'x');
m = add_line(m, 'horloge', 'lent');
m = add_line(m, 'lent', 'filtre');
m = add_line(m, 'lent', 'x');
modeles.cadences = m;
rFixe = sim(m, 'Solver', 'ode4', 'FixedStep', 0.05, 'StopTime', 2);
m = new_system('cassures');
m = add_block(m, 'step', 'echelon', 'Time', 0.4567, 'After', 2);
m = add_block(m, 'pulsegenerator', 'train', 'Period', 0.3, 'PulseWidth', 40, ...
              'PhaseDelay', 0.05);
m = add_block(m, 'integrator', 'xe');
m = add_block(m, 'integrator', 'xp');
m = add_line(m, 'echelon', 'xe');
m = add_line(m, 'train', 'xp');
modeles.cassures = m;
m = new_system('franchissement');
m = add_block(m, 'sine', 'entree', 'Frequency', 2, 'Bias', 0.3);
m = add_block(m, 'saturation', 'bloc', 'UpperLimit', 0.5, 'LowerLimit', -0.5);
m = add_block(m, 'integrator', 'x');
m = add_line(m, 'entree', 'bloc');
m = add_line(m, 'bloc', 'x');
modeles.saturation = m;
u = @(t) sin(2 * t) + 0.3;
franchit = @(c) sort([(asin(c - 0.3) + 2 * pi * (0:1)) / 2, ...
                      (pi - asin(c - 0.3) + 2 * pi * (0:1)) / 2]);
attenduSaturation = integrerParMorceaux(@(t) min(max(u(t), -0.5), 0.5), 0, 3, ...
                                        [franchit(0.5), franchit(-0.5)]);
m = new_system('borne');
m = add_block(m, 'sine', 'derivee', 'Amplitude', 2, 'Phase', pi / 2);
m = add_block(m, 'integrator', 'x', 'LimitOutput', 'on', 'UpperSaturationLimit', 1.5);
m = add_line(m, 'derivee', 'x');
modeles.borne = m;
m = new_system('retard');
m = add_block(m, 'sine', 'entree', 'Frequency', 2);
m = add_block(m, 'transportdelay', 'retard', 'DelayTime', 0.37, 'BufferSize', 16);
m = add_line(m, 'entree', 'retard');
modeles.retard = m;
m = new_system('boucle');
m = add_block(m, 'sine', 'entree');
m = add_block(m, 'sum', 'e', 'Signs', '+-');
m = add_block(m, 'gain', 'k', 'Gain', 3);
m = add_block(m, 'integrator', 'x');
m = add_line(m, 'entree', 'e', 1);
m = add_line(m, 'k', 'e', 2);
m = add_line(m, 'e', 'k');
m = add_line(m, 'e', 'x');
modeles.boucle = set_param(m, 'AlgebraicLoopMsg', 'none');
m = new_system('arret');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'comparetoconstant', 'assez', 'relop', '>=', 'const', 2.345);
m = add_block(m, 'stopsimulation', 'stop');
m = add_line(m, 'horloge', 'assez');
m = add_line(m, 'assez', 'stop');
modeles.arret = m;
% Les solveurs d'ordre 2 accumulent une erreur par pas plus grande à même
% tolérance : leur seuil suit leur ordre.
seuils = struct('ode113', 1e-6, 'ode15s', 1e-6, 'ode23t', 2e-5, 'ode23tb', 2e-5);
for solveur = nouveaux
    s = solveur{1};
    r = sim(modeles.cadences, 'Solver', s, 'StopTime', 2);
    for instant = [0:0.3:2, 0.05:0.2:2]
        iV = find(abs(r.temps - instant) < 1e-12, 1);
        iF = find(abs(rFixe.temps - instant) < 1e-12, 1);
        assert(~isempty(iV) && abs(r.signaux.filtre(iV) - rFixe.signaux.filtre(iF)) < 1e-12, ...
               sprintf('%s : a %g, le filtre discret rend ce que rend le pas fixe', s, instant));
    end
    assert(abs(r.signaux.x(end) - sum(0.3 * (0:0.3:1.5)) - 0.2 * 1.8) < 1e-9, ...
           [s ' : l''integrale d''une tenue est exacte']);
    r = sim(modeles.cassures, 'Solver', s, 'StopTime', 1.25);
    assert(abs(r.signaux.xe(end) - 2 * (1.25 - 0.4567)) < 1e-10 && ...
           abs(r.signaux.xp(end) - 4 * 0.12) < 1e-10, ...
           [s ' : l''echelon et les fronts tombent sur des fins de pas']);
    r = sim(modeles.saturation, 'Solver', s, 'StopTime', 3, 'RelTol', 1e-8, 'AbsTol', 1e-10);
    assert(abs(r.signaux.x(end) - attenduSaturation) < seuils.(s), ...
           sprintf('%s : la saturation bascule au bon instant (%g)', s, ...
                   abs(r.signaux.x(end) - attenduSaturation)));
    r = sim(modeles.borne, 'Solver', s, 'StopTime', 3, 'RelTol', 1e-8);
    assert(abs(r.signaux.x(end) - (1.5 + 2 * (sin(3) - 1))) < 10 * seuils.(s), ...
           [s ' : l''integrateur borne touche sa borne et la quitte au bon instant']);
    r = sim(modeles.retard, 'Solver', s, 'StopTime', 3, 'MaxStep', 0.007);
    attendu = sin(2 * (r.temps - 0.37));
    attendu(r.temps < 0.37) = 0;
    assert(max(abs(r.signaux.retard - attendu)) < 1e-4, [s ' : le retard pur interpole']);
    r = sim(modeles.boucle, 'Solver', s, 'StopTime', 2, 'RelTol', 1e-8);
    assert(max(abs(r.signaux.e - sin(r.temps) / 4)) < 1e-12 && ...
           abs(r.signaux.x(end) - (1 - cos(2)) / 4) < 10 * seuils.(s), ...
           [s ' : la boucle algebrique se resout a chaque pas']);
    r = sim(modeles.arret, 'Solver', s, 'StopTime', Inf);
    assert(abs(r.temps(end) - 2.345) < 1e-8, [s ' : l''arret tombe au franchissement']);
end

% Un sous-système activé dont l'état repart de zéro à chaque activation :
% la remise est une discontinuité de l'état, que la mémoire de ode15s et
% d'ode113 franchit en repartant ; la sortie tient à l'arrêt.
interne = new_system('chronoRemis');
interne = add_block(interne, 'constant', 'un', 'Value', 1);
interne = add_block(interne, 'integrator', 'x');
interne = add_block(interne, 'outport', 's', 'Port', 1);
interne = add_block(interne, 'enableport', 'Enable', 'StatesWhenEnabling', 'reset');
interne = add_line(interne, 'un', 'x');
interne = add_line(interne, 'x', 's');
m = new_system('activeRemise');
m = add_block(m, 'pulsegenerator', 'porte', 'Period', 2, 'PulseWidth', 50);
m = add_block(m, 'subsystem', 'sous', 'Model', interne);
m = add_line(m, 'porte', 'sous/Enable');
for solveur = nouveaux
    r = sim(m, 'Solver', solveur{1}, 'StopTime', 3.5);
    iCoupure = find(r.temps >= 1 - 1e-12, 1);
    iFin = find(r.temps >= 3 - 1e-12, 1);
    assert(abs(r.signaux.sous(iCoupure) - r.temps(iCoupure - 1)) < 1e-9 && ...
           abs(r.signaux.sous(end) - (r.temps(iFin - 1) - 2)) < 1e-9, ...
           [solveur{1} ' : l''etat repart de zero a la reprise, la sortie tient a l''arret']);
end

% Les réglages propres aux solveurs se vérifient comme les autres.
m = new_system('reglagesSolveur');
m = set_param(m, 'Solver', 'ode15s', 'MaxOrder', 2);
assert(get_param(m, 'MaxOrder') == 2 && strcmp(get_param(m, 'SolverType'), 'Variable-step'), ...
       'MaxOrder se pose et se relit');
m = set_param(m, 'Solver', 'ode14x', 'ExtrapolationOrder', '3', 'NumberNewtonIterations', 2);
assert(get_param(m, 'ExtrapolationOrder') == 3 && get_param(m, 'NumberNewtonIterations') == 2 ...
       && strcmp(get_param(m, 'SolverType'), 'Fixed-step'), ...
       'ode14x est a pas fixe, et ses reglages se relisent');
o = simset('Solver', 'ode15s', 'MaxOrder', 3);
assert(o.MaxOrder == 3, 'simset porte MaxOrder');
decroissance = add_line(add_line(add_block(add_block(new_system('d'), 'gain', 'k', ...
    'Gain', -1), 'integrator', 'x', 'InitialCondition', 1), 'x', 'k'), 'k', 'x');
explose = add_line(add_line(add_block(add_block(new_system('explose'), 'math', 'carre', ...
    'Operator', 'square'), 'integrator', 'x', 'InitialCondition', 1), 'x', 'carre'), ...
    'carre', 'x');
casErreurs = {
    @() set_param(m, 'MaxOrder', 6), 'Simulink:Config:InvalidValue', 'de 1 a 5'
    @() set_param(m, 'MaxOrder', 2.5), 'Simulink:Config:InvalidValue', 'MaxOrder'
    @() set_param(m, 'ExtrapolationOrder', 0), 'Simulink:Config:InvalidValue', 'de 1 a 4'
    @() set_param(m, 'NumberNewtonIterations', 0), 'Simulink:Config:InvalidValue', 'au moins'
    @() simset('MaxOrder', 9), 'Simulink:Config:InvalidValue', 'MaxOrder'
    @() set_param(m, 'Solver', 'ode6'), 'Simulink:Commands:SolveurInconnu', 'ode113'
    @() sim(decroissance, 'Solver', 'ode15s', 'MaxOrder', 0), 'Simulink:Config:InvalidValue', 'MaxOrder'
    @() sim(explose, 'Solver', 'ode15s', 'StopTime', 2), 'Simulink:Engine:SolverMinStepViolation', 'ode15s'
    @() sim(explose, 'Solver', 'ode113', 'StopTime', 2), 'Simulink:Engine:SolverMinStepViolation', 'essayez ode15s'
    @() sim(decroissance, 'Solver', 'VariableStepDiscrete'), 'Simulink:Engine:DiscreteSolverContinuousStates', 'ode15s'
    @() sim(decroissance, 'Solver', 'FixedStepDiscrete'), 'Simulink:Engine:DiscreteSolverContinuousStates', 'ode14x'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('solveurs, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('solveurs : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% --------------------------------------- 20. L'integrateur de Simulink en entier
% La balle qui rebondit, comme dans l'exemple de Simulink : la vitesse se
% remet quand la position franchit zéro en descendant, à -0,8 fois l'état
% d'avant le choc, que rend le port d'état. Sa condition initiale vient
% de son entrée ; au premier instant, l'état vaut zéro, et elle aussi.
m = new_system('balle');
m = add_block(m, 'constant', 'gravite', 'Value', -9.81);
m = add_block(m, 'integrator', 'vitesse', 'ExternalReset', 'falling', ...
              'InitialConditionSource', 'external', 'ShowStatePort', 'on');
m = add_block(m, 'integrator', 'position', 'InitialCondition', 10);
m = add_block(m, 'gain', 'rebond', 'Gain', -0.8);
m = add_line(m, 'gravite', 'vitesse', 1);
m = add_line(m, 'vitesse', 'position');
m = add_line(m, 'position', 'vitesse', 2);
m = add_line(m, 'vitesse/State', 'rebond');
m = add_line(m, 'rebond', 'vitesse', 3);
balle = m;
[entreesBalle, sortiesBalle] = matlibre_sl_ports(m.blocs{2});
assert(entreesBalle == 3 && sortiesBalle == 2, ...
       'la remise et la condition initiale font deux entrees, le port d''etat une sortie');
t1 = sqrt(2 * 10 / 9.81);
chocs = t1 * cumsum([1, 2 * 0.8 .^ (1:3)]);
for solveur = {'ode45', 'ode23', 'ode113', 'ode15s', 'ode23t', 'ode23tb', 'ode23s'}
    r = sim(m, 'Solver', solveur{1}, 'StopTime', 8, 'RelTol', 1e-8);
    iChocs = find(diff(r.signaux.vitesse) > 1).' + 1;
    assert(numel(iChocs) == 4 && max(abs(r.temps(iChocs).' - chocs)) < 1e-6, ...
           [solveur{1} ' : les chocs sont localises a leurs instants']);
    assert(max(abs(r.signaux.vitesse(iChocs) + 0.8 * r.signaux.vitesse_port2(iChocs))) < 1e-9 ...
           && abs(r.signaux.vitesse_port2(iChocs(1)) + 9.81 * t1) < 1e-6, ...
           [solveur{1} ' : au choc, le port d''etat rend la vitesse d''avant, la sortie la neuve']);
    assert(r.signaux.vitesse(1) == 0 && r.signaux.position(1) == 10, ...
           [solveur{1} ' : la condition initiale externe vaut au premier instant']);
end
% À pas fixe, sans localisation, le choc tombe au pas qui suit.
r = sim(m, 'Solver', 'ode4', 'FixedStep', 0.001, 'StopTime', 8);
iChocs = find(diff(r.signaux.vitesse) > 1).' + 1;
assert(numel(iChocs) == 4 && all(r.temps(iChocs).' - chocs >= -1e-12) && ...
       all(r.temps(iChocs).' - chocs < 0.0011), 'a pas fixe, le choc tombe au pas suivant');

% Les cinq remises, sur un créneau de période 1 : montant à 0, 1 et 2,
% descendant à 0,5 et 1,5. L'intégrale de 1 compte le temps depuis la
% dernière remise ; level remet tant que le créneau est haut, et au
% moment où il retombe ; level hold tient l'état pendant ce temps.
instants = [0.25 0.75 1.25 1.75 2.1];
attendus = struct('rising',   [0.25 0.75 0.25 0.75 0.1], ...
                  'falling',  [0.25 0.25 0.75 0.25 0.6], ...
                  'either',   [0.25 0.25 0.25 0.25 0.1], ...
                  'level',    [0 0.25 0 0.25 0], ...
                  'level_hold', [0 0.25 0 0.25 0]);
for type = fieldnames(attendus).'
    m = new_system('remises');
    m = add_block(m, 'pulsegenerator', 'porte', 'Period', 1, 'PulseWidth', 50);
    m = add_block(m, 'constant', 'un', 'Value', 1);
    m = add_block(m, 'integrator', 'x', 'ExternalReset', strrep(type{1}, '_', ' '));
    m = add_line(m, 'un', 'x', 1);
    m = add_line(m, 'porte', 'x', 2);
    rFixe = sim(m, 'Solver', 'ode1', 'FixedStep', 0.01, 'StopTime', 2.2);
    rVariable = sim(m, [0, instants], simset('Solver', 'ode45'));
    rMultipas = sim(m, [0, instants], simset('Solver', 'ode15s'));
    for kI = 1:numel(instants)
        iF = find(abs(rFixe.temps - instants(kI)) < 1e-9, 1);
        assert(abs(rFixe.signaux.x(iF) - attendus.(type{1})(kI)) < 1e-9 && ...
               abs(rVariable.signaux.x(kI + 1) - attendus.(type{1})(kI)) < 1e-9 && ...
               abs(rMultipas.signaux.x(kI + 1) - attendus.(type{1})(kI)) < 1e-9, ...
               sprintf('remise %s, a %g : %g attendu', type{1}, instants(kI), ...
                       attendus.(type{1})(kI)));
    end
end

% La condition initiale externe se lit au premier instant, fût-il
% décalé : ici l'horloge plus deux, à t = 1.
m = new_system('initialeExterne');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'bias', 'plusDeux', 'Bias', 2);
m = add_block(m, 'constant', 'un', 'Value', 1);
m = add_block(m, 'integrator', 'x', 'InitialConditionSource', 'external');
m = add_line(m, 'horloge', 'plusDeux');
m = add_line(m, 'un', 'x', 1);
m = add_line(m, 'plusDeux', 'x', 2);
for solveur = {'ode1', 'ode45', 'ode113'}
    r = sim(m, 'Solver', solveur{1}, 'StartTime', 1, 'StopTime', 3, 'FixedStep', 0.1);
    assert(abs(r.signaux.x(1) - 3) < 1e-12 && abs(r.signaux.x(end) - 5) < 1e-9, ...
           [solveur{1} ' : l''etat part de la condition initiale lue a t = 1']);
end

% Un état vecteur : une remise scalaire remet tout, une remise vecteur
% chaque composante à son front.
m = new_system('vecteurRemis');
m = add_block(m, 'constant', 'pente', 'Value', [1; 2]);
m = add_block(m, 'step', 'commun', 'Time', 1);
m = add_block(m, 'step', 'premier', 'Time', 0.5);
m = add_block(m, 'step', 'second', 'Time', 1.5);
m = add_block(m, 'mux', 'chacun');
m = add_block(m, 'integrator', 'tout', 'ExternalReset', 'rising', 'InitialCondition', [5; 6]);
m = add_block(m, 'integrator', 'part', 'ExternalReset', 'rising');
m = add_line(m, 'pente', 'tout', 1);
m = add_line(m, 'commun', 'tout', 2);
m = add_line(m, 'pente', 'part', 1);
m = add_line(m, 'premier', 'chacun', 1);
m = add_line(m, 'second', 'chacun', 2);
m = add_line(m, 'chacun', 'part', 2);
r = sim(m, 'Solver', 'ode45', 'StopTime', 2);
assert(max(abs(r.signaux.tout(end, :) - [6 8])) < 1e-9, ...
       'une remise scalaire remet toutes les composantes a leur condition initiale');
assert(max(abs(r.signaux.part(end, :) - [1.5 1])) < 1e-9, ...
       'une remise vecteur remet chaque composante a son propre front');

% Le port de saturation : 1 à la borne haute, -1 à la basse, 0 entre.
m = new_system('saturationMontree');
m = add_block(m, 'sine', 'derivee', 'Amplitude', 2, 'Phase', pi / 2);
m = add_block(m, 'integrator', 'x', 'LimitOutput', 'on', 'UpperSaturationLimit', 1.5, ...
              'LowerSaturationLimit', -1, 'ShowSaturationPort', 'on', 'ShowStatePort', 'on');
m = add_line(m, 'derivee', 'x');
r = sim(m, 'Solver', 'ode45', 'StopTime', 6, 'RelTol', 1e-8);
tHaut = asin(0.75);
assert(all(r.signaux.x_port2(r.temps > tHaut + 1e-6 & r.temps < pi / 2 - 1e-6) == 1) && ...
       all(r.signaux.x_port2(r.temps < tHaut - 1e-6) == 0), ...
       'le port de saturation vaut 1 a la borne haute, 0 avant');
assert(any(r.signaux.x_port2 == -1) && ...
       all(r.signaux.x(r.signaux.x_port2 == -1) == -1), 'et -1 a la borne basse');
assert(isequal(r.signaux.x_port3, r.signaux.x), ...
       'sans remise, le port d''etat rend la sortie');

% Le fichier .slx garde la remise, la condition initiale externe et le
% port d'état, que Simulink écrit « SID#state ».
cheminBalle = [tempname() '.slx'];
save_system(balle, cheminBalle);
dossierBalle = tempname();
unzip(cheminBalle, dossierBalle);
xmlBalle = fileread(fullfile(dossierBalle, 'simulink', 'blockdiagram.xml'));
assert(~isempty(strfind(xmlBalle, '#state')) && ~isempty(strfind(xmlBalle, 'ExternalReset')), ...
       'le .slx ecrit le port d''etat et la remise');
relue = load_system(cheminBalle);
r = sim(relue, 'Solver', 'ode45', 'StopTime', 8, 'RelTol', 1e-8);
iChocs = find(diff(r.signaux.vitesse) > 1).' + 1;
assert(numel(iChocs) == 4 && max(abs(r.temps(iChocs).' - chocs)) < 1e-6, ...
       'la balle relue du .slx rebondit aux memes instants');
delete(cheminBalle);
rmdir(dossierBalle, 's');

% Les erreurs, chacune avec son identifiant et le bloc nommé.
sansEtat = add_block(add_block(new_system('sansEtat'), 'integrator', 'x'), 'gain', 'g');
largeurCI = new_system('largeurCI');
largeurCI = add_block(largeurCI, 'constant', 'u', 'Value', [1; 2; 3]);
largeurCI = add_block(largeurCI, 'constant', 'ci', 'Value', [1; 2]);
largeurCI = add_block(largeurCI, 'integrator', 'x', 'InitialConditionSource', 'external');
largeurCI = add_line(add_line(largeurCI, 'u', 'x', 1), 'ci', 'x', 2);
largeurRemise = new_system('largeurRemise');
largeurRemise = add_block(largeurRemise, 'constant', 'u', 'Value', [1; 2; 3]);
largeurRemise = add_block(largeurRemise, 'constant', 'r', 'Value', [0; 1]);
largeurRemise = add_block(largeurRemise, 'integrator', 'x', 'ExternalReset', 'level');
largeurRemise = add_line(add_line(largeurRemise, 'u', 'x', 1), 'r', 'x', 2);
casErreurs = {
    @() add_line(sansEtat, 'x/State', 'g'), 'Simulink:Commands:AddLineInvalidPort', 'ShowStatePort'
    @() add_line(sansEtat, 'g/State', 'x'), 'Simulink:Commands:AddLineInvalidPort', 'port d''etat'
    @() sim(largeurCI), 'Simulink:Engine:DimensionMismatch', 'condition initiale'
    @() sim(largeurRemise), 'Simulink:Engine:DimensionMismatch', 'de remise'
    @() sim(set_param(balle, 'vitesse', 'ExternalReset', 'parfois')), 'Simulink:Parameters:InvalidValue', 'level hold'
    @() add_line(balle, 'gravite', 'vitesse', 4), 'Simulink:Commands:AddLineInvalidPort', '3 port(s)'
    @() matlibre_sl_programme(balle), 'Simulink:programme:BlocNonEcrit', 'balle/vitesse'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('integrateur, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('integrateur : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ----------------------------------------- 21. Les blocs courants qui manquaient
% Les sources. Chirp : une sinusoïde dont la fréquence va de f1 à f2 en
% T, soit sin(2 pi (f1 t + (f2 - f1) t^2 / (2 T))).
m = add_block(new_system('chirp'), 'chirp', 'balayage', 'f1', 0.5, 'T', 2, 'f2', 1.5);
for solveur = {'ode4', 'ode45'}
    r = sim(m, 'Solver', solveur{1}, 'FixedStep', 0.01, 'StopTime', 3);
    assert(max(abs(r.signaux.balayage - sin(2 * pi * (0.5 * r.temps + 0.25 * r.temps .^ 2)))) ...
           < 1e-12, [solveur{1} ' : le chirp suit sa loi']);
end
% Band-Limited White Noise : un bruit tenu Ts, de variance Cov / Ts, que
% la graine rend reproductible.
m = add_block(new_system('bruit'), 'bandlimitedwhitenoise', 'b', 'Cov', 0.2, 'Ts', 0.01, ...
              'seed', 7);
r1 = sim(m, 'Solver', 'ode1', 'FixedStep', 0.01, 'StopTime', 50);
r2 = sim(m, 'Solver', 'ode1', 'FixedStep', 0.01, 'StopTime', 50);
r3 = sim(set_param(m, 'b', 'seed', 8), 'Solver', 'ode1', 'FixedStep', 0.01, 'StopTime', 50);
assert(abs(var(r1.signaux.b) / 20 - 1) < 0.05 && abs(mean(r1.signaux.b)) < 0.2, ...
       'le bruit blanc a la variance Cov / Ts');
assert(isequal(r1.signaux.b, r2.signaux.b) && ~isequal(r1.signaux.b, r3.signaux.b), ...
       'la meme graine rend le meme bruit, une autre un autre');
rTenu = sim(m, 'Solver', 'ode1', 'FixedStep', 0.005, 'StopTime', 0.1);
assert(all(rTenu.signaux.b(1:2:end - 1) == rTenu.signaux.b(2:2:end)), ...
       'entre deux tirages, le bruit est tenu');
% Les compteurs et la suite en escalier, à leur période ; à pas variable,
% ils comptent aux mêmes instants.
m = new_system('compteurs');
m = add_block(m, 'counterlimited', 'borne', 'uplimit', 3, 'tsamp', 0.1);
m = add_block(m, 'counterfreerunning', 'libre', 'NumBits', 2, 'tsamp', 0.1);
m = add_block(m, 'repeatingsequencestair', 'escalier', 'OutValues', [5 6 7], 'tsamp', 0.1);
rFixe = sim(m, 'Solver', 'ode1', 'FixedStep', 0.05, 'StopTime', 0.9);
rVariable = sim(m, 'Solver', 'ode45', 'StopTime', 0.9);
attendus = struct('borne', [0 1 2 3 0 1 2 3 0 1], 'libre', [0 1 2 3 0 1 2 3 0 1], ...
                  'escalier', [5 6 7 5 6 7 5 6 7 5]);
for nom = fieldnames(attendus).'
    for n = 0:9
        iF = find(abs(rFixe.temps - n / 10) < 1e-9, 1);
        iV = find(abs(rVariable.temps - n / 10) < 1e-9, 1);
        assert(rFixe.signaux.(nom{1})(iF) == attendus.(nom{1})(n + 1) && ...
               (iF == numel(rFixe.temps) || ...
                rFixe.signaux.(nom{1})(iF + 1) == attendus.(nom{1})(n + 1)) && ...
               rVariable.signaux.(nom{1})(iV) == attendus.(nom{1})(n + 1), ...
               sprintf('%s : a %g, %d attendu', nom{1}, n / 10, attendus.(nom{1})(n + 1)));
    end
end
% Le générateur de signaux : l'intégrale de chaque forme sur 2,25 s, à pas
% variable, que les cassures n'abîment pas.
integrales = struct('sine', (1 - cos(2 * pi * 2.25)) / pi, 'square', 0.5, ...
                    'sawtooth', 0.125);
for forme = fieldnames(integrales).'
    m = add_block(new_system('generateur'), 'signalgenerator', 'g', 'WaveForm', forme{1}, ...
                  'Amplitude', 2, 'Frequency', 1, 'Units', 'Hertz');
    m = add_line(add_block(m, 'integrator', 'x'), 'g', 'x');
    for solveur = {'ode45', 'ode15s', 'ode23t'}
        r = sim(m, 'Solver', solveur{1}, 'StopTime', 2.25, 'RelTol', 1e-9, 'AbsTol', 1e-12);
        assert(abs(r.signaux.x(end) - integrales.(forme{1})) < 1e-6, ...
               sprintf('%s par %s : %g au lieu de %g', forme{1}, solveur{1}, ...
                       r.signaux.x(end), integrales.(forme{1})));
    end
end
m = add_block(new_system('generateur'), 'signalgenerator', 'g', 'WaveForm', 'random', ...
              'Amplitude', 3);
r = sim(m, 'Solver', 'ode1', 'FixedStep', 0.01, 'StopTime', 5);
assert(all(abs(r.signaux.g) <= 3) && std(r.signaux.g) > 1, ...
       'la forme random tire dans [-A, A]');
m = add_block(new_system('generateur'), 'signalgenerator', 'g', 'Frequency', 2);
r = sim(m, 'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 1);
assert(max(abs(r.signaux.g - sin(2 * r.temps))) < 1e-12, ...
       'en rad/sec, la frequence est une pulsation');

% Les non-linéarités à bornes dynamiques, Wrap To Zero, Interval Test et
% Manual Switch, sur un sinus.
m = new_system('dynamiques');
m = add_block(m, 'constant', 'haut', 'Value', 0.5);
m = add_block(m, 'constant', 'bas', 'Value', -0.2);
m = add_block(m, 'sine', 'u');
m = add_block(m, 'saturationdynamic', 'sat');
m = add_block(m, 'deadzonedynamic', 'zone');
m = add_block(m, 'wraptozero', 'repli', 'Threshold', 0.3);
m = add_block(m, 'intervaltest', 'dedans', 'uplimit', 0.5, 'lowlimit', -0.5);
m = add_block(m, 'intervaltest', 'ouvert', 'uplimit', 0.5, 'lowlimit', -0.5, ...
              'IntervalClosedRight', 'off', 'IntervalClosedLeft', 'off');
m = add_block(m, 'manualswitch', 'bas_choisi', 'sw', '0');
m = add_block(m, 'manualswitch', 'haut_choisi');
for nom = {'sat', 'zone'}
    m = add_line(m, 'haut', nom{1}, 1);
    m = add_line(m, 'u', nom{1}, 2);
    m = add_line(m, 'bas', nom{1}, 3);
end
m = add_line(m, 'u', 'repli');
m = add_line(m, 'u', 'dedans');
m = add_line(m, 'u', 'ouvert');
for nom = {'bas_choisi', 'haut_choisi'}
    m = add_line(m, 'haut', nom{1}, 1);
    m = add_line(m, 'u', nom{1}, 2);
end
r = sim(m, 'Solver', 'ode1', 'FixedStep', pi / 12, 'StopTime', 2 * pi);
u = sin(r.temps);
assert(max(abs(r.signaux.sat - min(max(u, -0.2), 0.5))) < 1e-12, 'Saturation Dynamic');
assert(max(abs(r.signaux.zone - ((u > 0.5) .* (u - 0.5) + (u < -0.2) .* (u + 0.2)))) < 1e-12, ...
       'Dead Zone Dynamic');
assert(isequal(r.signaux.repli, u .* (u <= 0.3)), 'Wrap To Zero');
assert(isequal(r.signaux.dedans, double(abs(u) <= 0.5)), 'Interval Test sur un sinus');
assert(isequal(r.signaux.bas_choisi, u) && all(r.signaux.haut_choisi == 0.5), ...
       'Manual Switch rend l''entree choisie');

% Aux bornes mêmes, l'intervalle fermé les compte, l'ouvert non.
m = new_system('bornes');
m = add_block(m, 'repeatingsequencestair', 'valeurs', 'OutValues', [0.5 -0.5 0 0.7 -0.7], ...
              'tsamp', 1);
m = add_block(m, 'intervaltest', 'ferme', 'uplimit', 0.5, 'lowlimit', -0.5);
m = add_block(m, 'intervaltest', 'ouvert', 'uplimit', 0.5, 'lowlimit', -0.5, ...
              'IntervalClosedRight', 'off', 'IntervalClosedLeft', 'off');
m = add_line(m, 'valeurs', 'ferme');
m = add_line(m, 'valeurs', 'ouvert');
r = sim(m, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 4);
assert(isequal(r.signaux.ferme.', [1 1 1 0 0]) && isequal(r.signaux.ouvert.', [0 0 1 0 0]), ...
       'Interval Test : les bornes comprises ou non');

% IC rend sa valeur au premier instant, puis l'entrée ; Width compte.
m = new_system('ic');
m = add_block(m, 'constant', 'c', 'Value', [1 2 3]);
m = add_block(m, 'ic', 'depart', 'Value', 7);
m = add_block(m, 'width', 'largeur');
m = add_line(m, 'c', 'depart');
m = add_line(m, 'c', 'largeur');
for solveur = {'ode1', 'ode45'}
    r = sim(m, 'Solver', solveur{1}, 'FixedStep', 0.1, 'StopTime', 0.3);
    assert(isequal(r.signaux.depart(1, :), [7 7 7]) && ...
           isequal(r.signaux.depart(end, :), [1 2 3]) && all(r.signaux.largeur == 3), ...
           [solveur{1} ' : IC, puis l''entree ; Width vaut 3']);
end

% Les mémoires partagées : un compteur qui lit, ajoute un et écrit. La
% lecture passe avant l'écriture, et rend ce que le pas d'avant a laissé.
% Une mémoire posée dans un sous-système y cache celle du dessus.
m = new_system('memoires');
m = add_block(m, 'datastorememory', 'memoire', 'DataStoreName', 'compte', 'InitialValue', 10);
m = add_block(m, 'datastoreread', 'lecture', 'DataStoreName', 'compte');
m = add_block(m, 'bias', 'plusUn', 'Bias', 1);
m = add_block(m, 'datastorewrite', 'ecriture', 'DataStoreName', 'compte');
m = add_line(m, 'lecture', 'plusUn');
m = add_line(m, 'plusUn', 'ecriture');
interne = new_system('interne');
interne = add_block(interne, 'datastorememory', 'locale', 'DataStoreName', 'compte', ...
                    'InitialValue', -5);
interne = add_block(interne, 'datastoreread', 'lue', 'DataStoreName', 'compte');
interne = add_block(interne, 'outport', 's', 'Port', 1);
interne = add_line(interne, 'lue', 's');
m = add_block(m, 'subsystem', 'dedans', 'Model', interne);
for solveur = {'ode1', 'ode45'}
    r = sim(m, 'Solver', solveur{1}, 'FixedStep', 0.1, 'StopTime', 0.5, 'MaxStep', 0.1);
    assert(isequal(r.signaux.lecture(1:6).', 10:15) && all(r.signaux.dedans == -5), ...
           [solveur{1} ' : lire avant d''ecrire, et la memoire locale cache l''autre']);
end

% Rate Transition : vers le lent, la tenue ; vers le rapide, le retard
% d'une période lente, qui part de sa condition initiale.
m = new_system('transitions');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'zoh', 'lent', 'SampleTime', 0.5);
m = add_block(m, 'ratetransition', 'versRapide', 'OutPortSampleTime', 0.1, 'X0', -1);
m = add_block(m, 'zoh', 'rapide', 'SampleTime', 0.1);
m = add_block(m, 'ratetransition', 'versLent', 'OutPortSampleTime', 0.5);
m = add_line(m, 'horloge', 'lent');
m = add_line(m, 'lent', 'versRapide');
m = add_line(m, 'horloge', 'rapide');
m = add_line(m, 'rapide', 'versLent');
for solveur = {'ode1', 'ode45'}
    r = sim(m, 'Solver', solveur{1}, 'FixedStep', 0.1, 'StopTime', 1.5);
    for instant = 0:0.1:1.5
        i = find(abs(r.temps - instant) < 1e-9, 1);
        rapide = -1;
        if instant >= 0.5 - 1e-9
            rapide = 0.5 * floor(instant / 0.5 + 1e-9) - 0.5;
        end
        assert(abs(r.signaux.versRapide(i) - rapide) < 1e-12 && ...
               abs(r.signaux.versLent(i) - 0.5 * floor(instant / 0.5 + 1e-9)) < 1e-12, ...
               sprintf('%s : Rate Transition a %g', solveur{1}, instant));
    end
end

% L'intégrateur du second ordre : la chute libre, x et v exacts.
m = new_system('chute');
m = add_block(m, 'constant', 'g', 'Value', -9.81);
m = add_block(m, 'secondorderintegrator', 'corps', 'ICX', 10, 'ICDXDT', 2);
m = add_line(m, 'g', 'corps');
% Les formules exactes sur un polynôme le sont ici ; les NDF d'ode15s,
% corrigées, s'en écartent à la tolérance près.
seuils = struct('ode45', 1e-9, 'ode113', 1e-9, 'ode15s', 1e-6, 'ode4', 1e-9);
for solveur = fieldnames(seuils).'
    r = sim(m, 'Solver', solveur{1}, 'StopTime', 1, 'FixedStep', 0.01, 'RelTol', 1e-8);
    assert(max(abs(r.signaux.corps - (10 + 2 * r.temps - 9.81 / 2 * r.temps .^ 2))) < ...
           seuils.(solveur{1}) && ...
           max(abs(r.signaux.corps_port2 - (2 - 9.81 * r.temps))) < seuils.(solveur{1}), ...
           [solveur{1} ' : la chute libre par l''integrateur du second ordre']);
end

% Les blocs discrets : dérivée, différence, retards en prise, zéros-pôles.
m = new_system('discrets');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'zoh', 'echantillon', 'SampleTime', 0.1);
m = add_block(m, 'math', 'carre', 'Operator', 'square');
m = add_block(m, 'discretederivative', 'derivee', 'gainval', 2);
m = add_block(m, 'difference', 'ecart');
m = add_block(m, 'tappeddelay', 'prises', 'NumDelays', 3, 'includeCurrent', 'on');
m = add_block(m, 'tappeddelay', 'recentes', 'NumDelays', 3, 'DelayOrder', 'Newest');
m = add_block(m, 'discretezeropole', 'zp', 'Zeros', [], 'Poles', 0.5, 'Gain', 1, ...
              'SampleTime', 0.1);
m = add_block(m, 'discretetransferfcn', 'tf', 'Numerator', 1, 'Denominator', [1 -0.5], ...
              'SampleTime', 0.1);
m = add_line(m, 'horloge', 'echantillon');
m = add_line(m, 'echantillon', 'carre');
for nom = {'derivee', 'ecart', 'prises', 'recentes', 'zp', 'tf'}
    m = add_line(m, 'carre', nom{1});
end
r = sim(m, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 0.5);
u = (0:5).' .^ 2 / 100;
precedent = [0; u(1:end - 1)];
assert(max(abs(r.signaux.derivee - 2 * (u - precedent) / 0.1)) < 1e-12, ...
       'Discrete Derivative : K (u - u d''avant) / Ts');
assert(max(abs(r.signaux.ecart - (u - precedent))) < 1e-12, 'Difference');
assert(max(abs(r.signaux.prises(end, :) - [u(3) u(4) u(5) u(6)])) < 1e-12 && ...
       max(abs(r.signaux.recentes(end, :) - [u(5) u(4) u(3)])) < 1e-12, ...
       'Tapped Delay : le plus ancien d''abord, ou le plus recent');
assert(max(abs(r.signaux.zp - r.signaux.tf)) < 1e-15, ...
       'Discrete Zero-Pole est la transmittance de ses zeros et poles');

% To File écrit le temps et le signal, une colonne sur Decimation ; XY
% Graph relève ses deux entrées.
fichier = [tempname() '.mat'];
m = new_system('fichier');
m = add_block(m, 'sine', 'sinus');
m = add_block(m, 'clock', 'horloge');
m = add_block(m, 'tofile', 'enregistre', 'Filename', fichier, 'MatrixName', 'donnees', ...
              'Decimation', 2);
m = add_block(m, 'xygraph', 'trace');
m = add_line(m, 'sinus', 'enregistre');
m = add_line(m, 'horloge', 'trace', 1);
m = add_line(m, 'sinus', 'trace', 2);
r = sim(m, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 1);
lu = load(fichier);
assert(isequal(size(lu.donnees), [2 6]) && max(abs(lu.donnees(1, :) - (0:0.2:1))) < 1e-12 && ...
       max(abs(lu.donnees(2, :) - sin(0:0.2:1))) < 1e-12, ...
       'To File ecrit le temps et le signal, decimes');
assert(isequal(r.signaux.trace, r.temps) && isequal(r.signaux.trace_port2, sin(r.temps)), ...
       'XY Graph releve x et y');
delete(fichier);

% Un .slx qui porte les nouveaux blocs se relit et simule à l'identique :
% les blocs masqués de la bibliothèque y sont des Reference.
m = new_system('nouveaux');
m = add_block(m, 'chirp', 'balayage', 'f1', 0.2, 'T', 1, 'f2', 1);
m = add_block(m, 'ratetransition', 'rt', 'OutPortSampleTime', 0.1);
m = add_block(m, 'difference', 'ecart');
m = add_block(m, 'datastorememory', 'memoire', 'DataStoreName', 'M', 'InitialValue', 0);
m = add_block(m, 'datastorewrite', 'ecrit', 'DataStoreName', 'M');
m = add_block(m, 'datastoreread', 'lit', 'DataStoreName', 'M');
m = add_block(m, 'secondorderintegrator', 'double', 'ICX', 1);
m = add_block(m, 'counterlimited', 'compte', 'uplimit', 4, 'tsamp', 0.1);
m = add_line(m, 'balayage', 'rt');
m = add_line(m, 'rt', 'ecart');
m = add_line(m, 'ecart', 'ecrit');
m = add_line(m, 'lit', 'double');
chemin = [tempname() '.slx'];
save_system(m, chemin);
relu = load_system(chemin);
r = sim(m, 'Solver', 'ode45', 'StopTime', 1);
rRelu = sim(relu, 'Solver', 'ode45', 'StopTime', 1);
assert(isequal(r.temps, rRelu.temps) && isequal(r.signaux.double, rRelu.signaux.double) && ...
       isequal(r.signaux.compte, rRelu.signaux.compte), ...
       'le .slx des nouveaux blocs se relit et simule a l''identique');
delete(chemin);

% Tous les solveurs sur un même modèle qui croise les familles : un bruit
% tenu, passé à une période lente, différencié, écrit dans une mémoire,
% relu, intégré ; un compteur ; un chirp borné par des signaux. Ce qui est
% discret ne dépend pas du solveur, et l'intégrale d'un signal tenu est
% exacte pour tous.
m = new_system('croisement');
m = add_block(m, 'bandlimitedwhitenoise', 'bruit', 'Cov', 0.01, 'Ts', 0.1);
m = add_block(m, 'ratetransition', 'lent', 'OutPortSampleTime', 0.5);
m = add_block(m, 'difference', 'ecart');
m = add_block(m, 'datastorememory', 'memoire', 'DataStoreName', 'D', 'InitialValue', 0);
m = add_block(m, 'datastorewrite', 'ecrit', 'DataStoreName', 'D');
m = add_block(m, 'datastoreread', 'lit', 'DataStoreName', 'D', 'SampleTime', 0.1);
m = add_block(m, 'ic', 'depart', 'Value', 1);
m = add_block(m, 'integrator', 'somme');
m = add_block(m, 'counterlimited', 'compte', 'uplimit', 5, 'tsamp', 0.1);
m = add_block(m, 'chirp', 'balayage', 'f1', 0.2, 'T', 3, 'f2', 1);
m = add_block(m, 'constant', 'plafond', 'Value', 0.5);
m = add_block(m, 'unaryminus', 'plancher');
m = add_block(m, 'saturationdynamic', 'borne');
m = add_line(m, 'bruit', 'lent');
m = add_line(m, 'lent', 'ecart');
m = add_line(m, 'ecart', 'ecrit');
m = add_line(m, 'lit', 'depart');
m = add_line(m, 'lit', 'somme');
m = add_line(m, 'plafond', 'borne', 1);
m = add_line(m, 'balayage', 'borne', 2);
m = add_line(m, 'plafond', 'plancher');
m = add_line(m, 'plancher', 'borne', 3);
reference = sim(m, 'Solver', 'ode1', 'FixedStep', 0.01, 'StopTime', 3);
instants = 0:0.1:3;
for solveur = {'ode4', 'ode8', 'ode14x', 'ode1be', 'ode45', 'ode113', 'ode15s', 'ode23t', ...
               'ode23tb', 'ode23s'}
    r = sim(m, 'Solver', solveur{1}, 'FixedStep', 0.01, 'StopTime', 3);
    for instant = instants
        i = find(abs(r.temps - instant) < 1e-9, 1);
        iR = find(abs(reference.temps - instant) < 1e-9, 1);
        assert(~isempty(i) && ...
               abs(r.signaux.ecart(i) - reference.signaux.ecart(iR)) < 1e-12 && ...
               abs(r.signaux.lit(i) - reference.signaux.lit(iR)) < 1e-12 && ...
               r.signaux.compte(i) == reference.signaux.compte(iR) && ...
               abs(r.signaux.somme(i) - reference.signaux.somme(iR)) < 1e-9, ...
               sprintf('%s : a %g, le modele croise rend ce que rend ode1', solveur{1}, instant));
    end
    assert(all(abs(r.signaux.borne) <= 0.5 + 1e-12) && r.signaux.depart(1) == 1, ...
           [solveur{1} ' : le chirp reste borne, et IC part de sa valeur']);
end

% Les erreurs, chacune avec son identifiant et le bloc nommé.
sansMemoire = add_block(new_system('sansMemoire'), 'datastoreread', 'lit', ...
                        'DataStoreName', 'X');
deuxMemoires = add_block(add_block(new_system('deuxMemoires'), 'datastorememory', 'a', ...
                         'DataStoreName', 'X'), 'datastorememory', 'b', 'DataStoreName', 'X');
largeurMemoire = new_system('largeurMemoire');
largeurMemoire = add_block(largeurMemoire, 'datastorememory', 'm', 'DataStoreName', 'X', ...
                           'InitialValue', [0 0]);
largeurMemoire = add_block(largeurMemoire, 'constant', 'c', 'Value', [1 2 3]);
largeurMemoire = add_block(largeurMemoire, 'datastorewrite', 'w', 'DataStoreName', 'X');
largeurMemoire = add_line(largeurMemoire, 'c', 'w');
continuDiscret = add_line(add_block(add_block(new_system('continuDiscret'), 'sine', 's'), ...
                          'difference', 'd'), 's', 'd');
largeurPrises = add_line(add_block(add_block(new_system('largeurPrises'), 'constant', 'c', ...
                         'Value', [1 2]), 'tappeddelay', 't', 'samptime', 0.1), 'c', 't');
casErreurs = {
    @() sim(sansMemoire), 'Simulink:DataStores:DataStoreNotFound', 'sansMemoire/lit'
    @() sim(deuxMemoires), 'Simulink:DataStores:DuplicateDataStore', 'deux fois'
    @() sim(largeurMemoire), 'Simulink:DataStores:DataStoreWidthMismatch', 'largeurMemoire/w'
    @() sim(continuDiscret), 'Simulink:SampleTime:DiscreteBlockContinuous', 'continuDiscret/d'
    @() sim(largeurPrises), 'Simulink:Engine:DimensionMismatch', 'scalaire'
    @() sim(add_block(new_system('b'), 'bandlimitedwhitenoise', 'n', 'Ts', 0)), ...
        'Simulink:Parameters:InvalidValue', 'positive'
    @() sim(add_block(new_system('c'), 'counterfreerunning', 'n', 'NumBits', 0.5)), ...
        'Simulink:Parameters:InvalidValue', 'bits'
    @() sim(add_block(new_system('g'), 'signalgenerator', 'g', 'WaveForm', 'triangle')), ...
        'Simulink:Parameters:InvalidValue', 'sawtooth'
    @() sim(add_block(new_system('z'), 'discretezeropole', 'z', 'Zeros', [1 2], 'Poles', 0.5)), ...
        'Simulink:blocks:TransferFcnImproper', 'propre'
    @() matlibre_sl_programme(add_block(new_system('p'), 'chirp', 'c')), ...
        'Simulink:programme:BlocNonEcrit', 'p/c'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('nouveaux blocs, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('nouveaux blocs : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ----------------------------- 22. Sous-systemes iteres et appeles par fonction
% For Iterator : le sous-système calcule N fois par pas. Ici il ajoute u
% fois le rang à un accumulateur : 2 (1 + 2 + 3 + 4) = 20 par pas. Ses
% états tiennent d'un pas à l'autre (held), ou repartent (reset).
interne = new_system('boucle');
interne = add_block(interne, 'inport', 'u', 'Port', 1);
interne = add_block(interne, 'foriterator', 'iteration', 'IterationLimit', 4);
interne = add_block(interne, 'product', 'fois');
interne = add_block(interne, 'sum', 'plus', 'Signs', '++');
interne = add_block(interne, 'delay', 'acc', 'InitialCondition', 0);
interne = add_block(interne, 'outport', 's', 'Port', 1);
interne = add_line(interne, 'u', 'fois', 1);
interne = add_line(interne, 'iteration', 'fois', 2);
interne = add_line(interne, 'fois', 'plus', 1);
interne = add_line(interne, 'acc', 'plus', 2);
interne = add_line(interne, 'plus', 'acc');
interne = add_line(interne, 'plus', 's');
m = new_system('iteree');
m = add_block(m, 'constant', 'deux', 'Value', 2);
m = add_block(m, 'subsystem', 'somme', 'Model', interne);
m = add_line(m, 'deux', 'somme');
for solveur = {'ode1', 'ode45', 'ode15s'}
    r = sim(m, 'Solver', solveur{1}, 'FixedStep', 1, 'StopTime', 2, 'MaxStep', 1);
    assert(isequal(r.signaux.somme(ismember(r.temps, [0 1 2])).', [20 40 60]), ...
           [solveur{1} ' : l''iteration accumule, et l''etat tient d''un pas a l''autre']);
end
r = sim(set_param(m, 'somme', 'Model', set_param(interne, 'iteration', 'ResetStates', 'reset')), ...
        'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 2);
assert(isequal(r.signaux.somme.', [20 20 20]), 'reset : l''etat repart a chaque pas');
r = sim(set_param(m, 'somme', 'Model', set_param(interne, 'iteration', 'IndexMode', ...
        'Zero-based')), 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 0);
assert(r.signaux.somme == 12, 'Zero-based : le rang va de 0 a N - 1');
% Le nombre d'itérations peut venir d'une entrée : ici du dehors.
externe = set_param(interne, 'iteration', 'IterationSource', 'external');
externe = add_block(externe, 'inport', 'n', 'Port', 2);
externe = add_line(externe, 'n', 'iteration');
m2 = new_system('iterationsExternes');
m2 = add_block(m2, 'constant', 'un', 'Value', 1);
m2 = add_block(m2, 'constant', 'combien', 'Value', 3);
m2 = add_block(m2, 'subsystem', 'somme', 'Model', set_param(externe, 'iteration', ...
               'ResetStates', 'reset'));
m2 = add_line(m2, 'un', 'somme', 1);
m2 = add_line(m2, 'combien', 'somme', 2);
r = sim(m2, 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 1);
assert(all(r.signaux.somme == 6), 'le nombre d''iterations lu a l''entree du For Iterator');

% While Iterator : do-while divise par deux tant que le résultat dépasse
% 1 ; while ne commence pas si sa condition initiale est fausse ; MaxIters
% borne tout.
w = new_system('moitie');
w = add_block(w, 'inport', 'x0', 'Port', 1);
w = add_block(w, 'inport', 'commencer', 'Port', 2);
w = add_block(w, 'whileiterator', 'tantque', 'WhileBlockType', 'do-while', 'MaxIters', 100, ...
              'ShowIterationPort', 'on');
w = add_block(w, 'delay', 'precedent', 'InitialCondition', 0);
w = add_block(w, 'switch', 'choix', 'Threshold', 1, 'Criteria', 'u2 > Threshold');
w = add_block(w, 'gain', 'demi', 'Gain', 0.5);
w = add_block(w, 'comparetoconstant', 'encore', 'relop', '>', 'const', 1);
w = add_block(w, 'outport', 'y', 'Port', 1);
w = add_block(w, 'outport', 'n', 'Port', 2);
w = add_line(w, 'precedent', 'choix', 1);
w = add_line(w, 'tantque', 'choix', 2);
w = add_line(w, 'x0', 'choix', 3);
w = add_line(w, 'choix', 'demi');
w = add_line(w, 'demi', 'precedent');
w = add_line(w, 'demi', 'encore');
w = add_line(w, 'encore', 'tantque', 1);
w = add_line(w, 'demi', 'y');
w = add_line(w, 'tantque', 'n');
m = new_system('divisions');
m = add_block(m, 'constant', 'x', 'Value', 20);
m = add_block(m, 'constant', 'oui', 'Value', 1);
m = add_block(m, 'subsystem', 'div', 'Model', w);
m = add_line(m, 'x', 'div', 1);
m = add_line(m, 'oui', 'div', 2);
r = sim(m, 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 1);
assert(all(r.signaux.div == 0.625) && all(r.signaux.div_port2 == 5), ...
       'do-while : cinq divisions, de 20 a 0,625');
tantQue = set_param(w, 'tantque', 'WhileBlockType', 'while');
tantQue = add_line(tantQue, 'commencer', 'tantque', 2);
r = sim(set_param(m, 'div', 'Model', tantQue), 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 1);
assert(all(r.signaux.div == 0.625), 'while, condition initiale vraie : les memes divisions');
m3 = set_param(set_param(m, 'div', 'Model', tantQue), 'oui', 'Value', 0);
r = sim(m3, 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 1);
assert(all(r.signaux.div == 0) && all(r.signaux.div_port2 == 0), ...
       'while, condition initiale fausse : pas une iteration, les sorties tiennent');
r = sim(set_param(m, 'div', 'Model', set_param(w, 'tantque', 'MaxIters', 2)), ...
        'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 0);
assert(r.signaux.div == 5 && r.signaux.div_port2 == 2, 'MaxIters borne les iterations');
gabarits = add_block(new_system('gabarits'), 'While Iterator Subsystem', 'tantQue');
gabarits = add_block(gabarits, 'For Iterator Subsystem', 'pourChaque');
r = sim(gabarits, 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 1);
assert(isfield(r.signaux, 'tantQue') && isfield(r.signaux, 'pourChaque'), ...
       'les gabarits itérés se simulent, sans port d''iteration');

% Un sous-système itéré dans un sous-système activé n'itère que quand
% celui-ci calcule.
enveloppe = new_system('enveloppe');
enveloppe = add_block(enveloppe, 'inport', 'e', 'Port', 1);
enveloppe = add_block(enveloppe, 'subsystem', 'somme', 'Model', interne);
enveloppe = add_block(enveloppe, 'outport', 's', 'Port', 1);
enveloppe = add_block(enveloppe, 'enableport', 'Enable');
enveloppe = add_line(add_line(enveloppe, 'e', 'somme'), 'somme', 's');
m = new_system('activeIteree');
m = add_block(m, 'constant', 'deux', 'Value', 2);
m = add_block(m, 'pulsegenerator', 'porte', 'Period', 2, 'PulseWidth', 50, 'SampleTime', 1, ...
              'PulseType', 'Sample based');
m = set_param(m, 'porte', 'Period', 2, 'PulseWidth', 1);
m = add_block(m, 'subsystem', 'actif', 'Model', enveloppe);
m = add_line(m, 'deux', 'actif', 1);
m = add_line(m, 'porte', 'actif/Enable');
r = sim(m, 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 4);
assert(isequal(r.signaux.actif.', [20 20 40 40 60]), ...
       'itere dans un sous-systeme active : seulement aux pas actifs');

% Function-Call Generator et sous-système appelé par fonction : un
% compteur qui avance à chaque appel, toutes les 0,5 s, quel que soit le
% solveur.
compteur = new_system('compteur');
compteur = add_block(compteur, 'constant', 'un', 'Value', 1);
compteur = add_block(compteur, 'sum', 'plus', 'Signs', '++');
compteur = add_block(compteur, 'delay', 'avant', 'InitialCondition', 0);
compteur = add_block(compteur, 'outport', 'n', 'Port', 1);
compteur = add_block(compteur, 'triggerport', 'function', 'TriggerType', 'function-call');
compteur = add_line(compteur, 'un', 'plus', 1);
compteur = add_line(compteur, 'avant', 'plus', 2);
compteur = add_line(compteur, 'plus', 'avant');
compteur = add_line(compteur, 'plus', 'n');
m = new_system('appels');
m = add_block(m, 'functioncallgenerator', 'horloge', 'sample_time', 0.5);
m = add_block(m, 'subsystem', 'appele', 'Model', compteur);
m = add_line(m, 'horloge', 'appele/Trigger');
for solveur = {'ode1', 'ode4', 'ode45', 'ode113'}
    r = sim(m, 'Solver', solveur{1}, 'FixedStep', 0.1, 'StopTime', 2);
    for instant = [0 0.3 0.5 0.9 1 1.7 2]
        i = find(abs(r.temps - instant) < 1e-9, 1);
        assert(r.signaux.appele(i) == floor(instant / 0.5 + 1e-9) + 1, ...
               sprintf('%s : a %g, %d appels', solveur{1}, instant, ...
                       floor(instant / 0.5 + 1e-9) + 1));
    end
end
fc = add_block(new_system('fc'), 'Function-Call Subsystem', 'boite');
assert(strcmp(get_param(fc.blocs{1}.parametres.Model, 'function', 'TriggerType'), ...
              'function-call'), 'le gabarit porte un Trigger function-call');

% Le .slx garde le sous-système itéré et l'appel de fonction.
m = new_system('iteresFichier');
m = add_block(m, 'constant', 'deux', 'Value', 2);
m = add_block(m, 'subsystem', 'somme', 'Model', interne);
m = add_block(m, 'functioncallgenerator', 'horloge', 'sample_time', 0.5);
m = add_block(m, 'subsystem', 'appele', 'Model', compteur);
m = add_line(m, 'deux', 'somme');
m = add_line(m, 'horloge', 'appele/Trigger');
chemin = [tempname() '.slx'];
save_system(m, chemin);
relu = load_system(chemin);
r = sim(m, 'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 2);
rRelu = sim(relu, 'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 2);
assert(isequal(r.signaux.somme, rRelu.signaux.somme) && ...
       isequal(r.signaux.appele, rRelu.signaux.appele), ...
       'le .slx des sous-systemes iteres et appeles se relit a l''identique');
delete(chemin);

% Les erreurs, chacune avec son identifiant et le bloc nommé.
continuDedans = add_line(add_block(interne, 'integrator', 'x'), 'u', 'x');
periodeDedans = set_param(interne, 'acc', 'SampleTime', 0.5);
deuxIterateurs = add_block(interne, 'whileiterator', 'autre');
avecEnable = add_block(interne, 'enableport', 'Enable');
avecEnableModele = add_block(new_system('e'), 'subsystem', 'boite', 'Model', avecEnable);
sansGenerateur = add_line(add_block(add_block(new_system('sansGenerateur'), 'pulsegenerator', ...
    'p'), 'subsystem', 'appele', 'Model', compteur), 'p', 'appele/Trigger');
generateurAilleurs = add_line(add_block(add_block(new_system('generateurAilleurs'), ...
    'functioncallgenerator', 'g'), 'gain', 'k'), 'g', 'k');
deuxAppels = add_line(add_block(add_block(new_system('deuxAppels'), 'functioncallgenerator', ...
    'g', 'numberOfIterations', 2), 'subsystem', 'appele', 'Model', compteur), 'g', ...
    'appele/Trigger');
continuAppele = add_line(add_block(compteur, 'integrator', 'x'), 'un', 'x');
continuAppeleModele = add_line(add_block(add_block(new_system('continuAppele'), ...
    'functioncallgenerator', 'g'), 'subsystem', 'appele', 'Model', continuAppele), 'g', ...
    'appele/Trigger');
avecIterateur = @(dedans) add_line(add_block(add_block(new_system('x'), 'constant', 'c'), ...
    'subsystem', 'somme', 'Model', dedans), 'c', 'somme');
casErreurs = {
    @() sim(avecIterateur(continuDedans)), 'Simulink:blocks:IteratorSubsystemContinuousStates', 'somme/x'
    @() sim(avecIterateur(periodeDedans)), 'Simulink:blocks:IteratorSubsystemSampleTime', 'somme/acc'
    @() sim(avecIterateur(deuxIterateurs)), 'Simulink:blocks:IteratorDuplicate', 'somme'
    @() sim(avecEnableModele), 'Simulink:blocks:IteratorWithControlPort', 'boite'
    @() sim(avecIterateur(set_param(interne, 'iteration', 'IterationLimit', 2.5))), ...
        'Simulink:blocks:ForIteratorInvalidLimit', 'iteration'
    @() sim(sansGenerateur), 'Simulink:blocks:FcnCallSubsystemInputNotFcnCall', 'Function-Call Generator'
    @() sim(generateurAilleurs), 'Simulink:blocks:FcnCallOutputToNonFcnCallInput', 'generateurAilleurs/k'
    @() sim(deuxAppels), 'Simulink:blocks:FcnCallGenIterations', 'deuxAppels/g'
    @() sim(continuAppeleModele), 'Simulink:blocks:TriggeredSubsystemContinuousStates', 'appele/x'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('iteres et appeles, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('iteres et appeles : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% --------------------------- 23. Entrees externes, references de modele, tables
% Les entrées externes : SIM(MODELE,INTERVALLE,OPTIONS,[t, u]), ou
% LoadExternalInput et ExternalInput sur le modèle. Chaque entrée du
% modèle, dans l'ordre de son paramètre Port, prend autant de colonnes
% que sa largeur ; les valeurs s'interpolent entre les instants.
m = new_system('externes');
m = add_block(m, 'inport', 'a', 'Port', 1);
m = add_block(m, 'inport', 'b', 'Port', 2, 'PortDimensions', 2);
m = add_block(m, 'sum', 'somme', 'Signs', '|+');
m = add_block(m, 'sum', 'total', 'Signs', '++');
m = add_block(m, 'integrator', 'x');
m = add_block(m, 'outport', 'y', 'Port', 1);
m = add_line(m, 'b', 'somme');
m = add_line(m, 'a', 'total', 1);
m = add_line(m, 'somme', 'total', 2);
m = add_line(m, 'total', 'x');
m = add_line(m, 'x', 'y');
modeleExterne = m;
t = (0:0.5:2).';
u = [t, t, ones(size(t)), 2 * ones(size(t))];   % a = t, b = [1 2]
% x' = t + 3, x(2) = 2 + 6 = 8
for solveur = {'ode4', 'ode45', 'ode15s'}
    r = sim(m, [0 2], simset('Solver', solveur{1}, 'FixedStep', 0.01), u);
    assert(abs(r.signaux.x(end) - 8) < 1e-6 && ...
           max(abs(r.signaux.a - r.temps)) < 1e-12, ...
           [solveur{1} ' : les entrees externes, interpolees, alimentent le modele']);
end
assignin('base', 'entreeA', [t, t]);
assignin('base', 'entreeB', [t, ones(size(t)), 2 * ones(size(t))]);
r = sim(set_param(m, 'LoadExternalInput', 'on', 'ExternalInput', 'entreeA, entreeB'), ...
        'Solver', 'ode45', 'StopTime', 2);
assert(abs(r.signaux.x(end) - 8) < 1e-9, 'ExternalInput : une variable par entree');
assignin('base', 'entreesStructure', struct('time', t, 'signals', ...
         struct('values', {t, [ones(size(t)), 2 * ones(size(t))]}, 'dimensions', {1, 2})));
r = sim(set_param(m, 'LoadExternalInput', 'on', 'ExternalInput', 'entreesStructure'), ...
        'Solver', 'ode45', 'StopTime', 2);
assert(abs(r.signaux.x(end) - 8) < 1e-9, 'ExternalInput : une structure a temps');
r = sim(m, [0 3], simset('Solver', 'ode45'), u);
assert(abs(r.signaux.a(end) - 2) < 1e-12, 'apres le dernier instant, la valeur tient');
evalin('base', 'clear entreeA entreeB entreesStructure');

% Une référence de modèle relit son modèle à chaque simulation : changé,
% il change ce que rend le bloc.
doubleur = new_system('doubleurRef');
doubleur = add_block(doubleur, 'inport', 'e', 'Port', 1);
doubleur = add_block(doubleur, 'gain', 'k', 'Gain', 2);
doubleur = add_block(doubleur, 'outport', 's', 'Port', 1);
doubleur = add_line(add_line(doubleur, 'e', 'k'), 'k', 's');
assignin('base', 'doubleurRef', doubleur);
m = new_system('reference');
m = add_block(m, 'constant', 'c', 'Value', 3);
m = add_block(m, 'modelreference', 'modele', 'ModelName', 'doubleurRef');
m = add_line(m, 'c', 'modele');
[entreesRef, sortiesRef] = matlibre_sl_ports(m.blocs{2});
assert(entreesRef == 1 && sortiesRef == 1, 'la reference a les ports du modele qu''elle nomme');
r = sim(m, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 0.2);
assert(all(r.signaux.modele == 6), 'la reference calcule son modele');
assignin('base', 'doubleurRef', set_param(doubleur, 'k', 'Gain', 5));
r = sim(m, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 0.2);
assert(all(r.signaux.modele == 15), 'et le relit a chaque simulation');
cheminRef = [tempname() '.slx'];
[dossierRef, nomRef] = fileparts(cheminRef);
save_system(doubleur, cheminRef);
ancien = cd(dossierRef);
r = sim(set_param(m, 'modele', 'ModelName', nomRef), 'Solver', 'ode1', 'FixedStep', 0.1, ...
        'StopTime', 0);
cd(ancien);
assert(r.signaux.modele == 6, 'une reference a un fichier .slx');
delete(cheminRef);
evalin('base', 'clear doubleurRef');

% Les tables : n-D à deux dimensions, interpolée comme la table 2-D ;
% directe, l'élément que désignent ses entrées, à partir de 0 et bornées.
m = new_system('tables');
m = add_block(m, 'constant', 'x', 'Value', 0.5);
m = add_block(m, 'constant', 'y', 'Value', 0.25);
m = add_block(m, 'lookup', 'nd', 'NumberOfTableDimensions', 2, 'BreakpointsData', [0 1], ...
              'BreakpointsForDimension2', [0 1], 'TableData', [0 1; 2 3]);
m = add_block(m, 'lookup2d', 'deuxD', 'BreakpointsForDimension1', [0 1], ...
              'BreakpointsForDimension2', [0 1], 'Table', [0 1; 2 3]);
m = add_block(m, 'repeatingsequencestair', 'rang', 'OutValues', [0 1 2 5 -1], 'tsamp', 1);
m = add_block(m, 'directlookup', 'direct', 'Table', [10 20 30]);
m = add_block(m, 'directlookup', 'directe2', 'Table', [1 2; 3 4], 'NumberOfTableDimensions', 2);
m = add_block(m, 'constant', 'un', 'Value', 1);
m = add_line(m, 'x', 'nd', 1);
m = add_line(m, 'y', 'nd', 2);
m = add_line(m, 'x', 'deuxD', 1);
m = add_line(m, 'y', 'deuxD', 2);
m = add_line(m, 'rang', 'direct');
m = add_line(m, 'rang', 'directe2', 1);
m = add_line(m, 'un', 'directe2', 2);
r = sim(m, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 4);
assert(all(r.signaux.nd == 1.25) && isequal(r.signaux.nd, r.signaux.deuxD), ...
       'la table n-D a deux dimensions interpole comme la table 2-D');
assert(isequal(r.signaux.direct.', [10 20 30 30 10]) && ...
       isequal(r.signaux.directe2.', [2 4 4 4 2]), ...
       'la table directe rend l''element designe, a partir de 0 et borne');

% Les erreurs, chacune avec son identifiant.
casErreurs = {
    @() sim(modeleExterne, [0 1], [], [0 1; 1 2]), 'Simulink:SimInput:NumPortsMismatch', 'colonne'
    @() sim(modeleExterne, [0 1], [], 'pasUneVariable'), 'Simulink:SimInput:InvalidExpression', 'pasUneVariable'
    @() sim(modeleExterne, [0 1], [], [1 0 0 0 0; 0 1 1 1 1]), 'Simulink:SimInput:TimeNotMonotonic', 'croitre'
    @() sim(add_block(new_system('r'), 'modelreference', 'm')), 'Simulink:modelReference:ModelNameEmpty', 'ModelName'
    @() sim(add_block(new_system('r'), 'modelreference', 'm', 'ModelName', 'modeleQuiNExistePas')), ...
        'Simulink:modelReference:ModelNotFound', 'modeleQuiNExistePas'
    @() sim(add_block(new_system('t'), 'lookup', 'l', 'NumberOfTableDimensions', 7)), ...
        'Simulink:blocks:LookupNDDimensions', 'une a six'
    @() set_param(new_system('c'), 'LoadExternalInput', 'parfois'), 'Simulink:Config:InvalidValue', 'LoadExternalInput'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('entrees et references, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('entrees et references : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------------------------ 24. Rappels du modele et commandes
% Les rappels : InitFcn pose les variables que lisent les blocs, avant la
% compilation ; StartFcn et StopFcn encadrent la simulation, StopFcn même
% quand elle échoue ; PostLoadFcn suit le chargement, PreSaveFcn et
% PostSaveFcn l'enregistrement, CloseFcn la fermeture.
m = new_system('rappels');
m = add_block(m, 'constant', 'c', 'Value', 'gainDuRappel');
m = set_param(m, 'InitFcn', 'gainDuRappel = 4; journalRappels = {''init''};', ...
              'StartFcn', 'journalRappels{end + 1} = ''start'';', ...
              'StopFcn', 'journalRappels{end + 1} = ''stop'';');
r = sim(m, 'Solver', 'ode1', 'StopTime', 0.1, 'FixedStep', 0.1);
assert(all(r.signaux.c == 4) && isequal(evalin('base', 'journalRappels'), ...
       {'init', 'start', 'stop'}), 'InitFcn avant la compilation, puis StartFcn et StopFcn');
echoue = add_line(add_block(add_block(m, 'constant', 'zero', 'Value', 0), 'assertion', 'a'), ...
                  'zero', 'a');
try
    sim(echoue, 'Solver', 'ode1', 'StopTime', 0.1, 'FixedStep', 0.1);
catch
end
assert(strcmp(evalin('base', 'journalRappels{end}'), 'stop'), ...
       'StopFcn s''execute aussi quand la simulation echoue');
m = set_param(m, 'PostLoadFcn', 'chargeFait = 1;', 'PreSaveFcn', 'sauveFait = 1;', ...
              'PostSaveFcn', 'sauveFait = sauveFait + 1;', 'CloseFcn', 'fermeFait = 1;');
for extension = {'.slx', '.m'}
    evalin('base', 'clear chargeFait sauveFait');
    chemin = [tempname() extension{1}];
    save_system(m, chemin);
    assert(evalin('base', 'sauveFait') == 2, [extension{1} ' : PreSaveFcn puis PostSaveFcn']);
    relu = load_system(chemin);
    assert(evalin('base', 'chargeFait') == 1 && ...
           strcmp(get_param(relu, 'InitFcn'), get_param(m, 'InitFcn')), ...
           [extension{1} ' : les rappels voyagent avec le modele, PostLoadFcn au chargement']);
    delete(chemin);
end
close_system(relu);
assert(evalin('base', 'fermeFait') == 1, 'CloseFcn a la fermeture');
evalin('base', 'clear gainDuRappel journalRappels chargeFait sauveFait fermeFait');

% SimulationCommand : update compile, start simule et dépose OUT ; SIM
% sans sortie dépose son résultat, dans OUT ou dans tout et yout. Les
% To Workspace sont aussi dans le résultat.
m = new_system('commandes');
m = add_block(m, 'constant', 'c', 'Value', 3);
m = add_block(m, 'toworkspace', 'versEspace', 'VariableName', 'simout');
m = add_block(m, 'outport', 'y', 'Port', 1);
m = add_line(m, 'c', 'versEspace');
m = add_line(m, 'c', 'y');
m = set_param(m, 'StopTime', 0.1, 'FixedStep', 0.1);
evalin('base', 'clear out tout yout');
set_param(m, 'SimulationCommand', 'start');
dehors = evalin('base', 'out');
assert(all(dehors.simout == 3) && all(dehors.yout == 3), ...
       'SimulationCommand start : OUT porte le resultat, To Workspace compris');
sim(set_param(m, 'ReturnWorkspaceOutputsName', 'resultatNomme'));
assert(isfield(evalin('base', 'resultatNomme'), 'tout'), 'ReturnWorkspaceOutputsName');
sim(set_param(m, 'ReturnWorkspaceOutputs', 'off'));
assert(isequal(evalin('base', 'yout'), [3; 3]) && numel(evalin('base', 'tout')) == 2, ...
       'ReturnWorkspaceOutputs off : tout et yout');
evalin('base', 'clear out tout yout resultatNomme simout');
r = sim(set_param(m, 'SimulationMode', 'accelerator'));
assert(all(r.yout == 3), 'le mode accelerator simule comme normal');
m2 = add_block(m, 'gain', 'enLair');
avertissement = lastwarn('');
set_param(m2, 'SimulationCommand', 'update');
[~, idAvertissement] = lastwarn();
assert(strcmp(idAvertissement, 'Simulink:Engine:InputNotConnected'), ...
       'SimulationCommand update compile, et dit l''entree en l''air');
lastwarn(avertissement);

% Les erreurs.
casErreurs = {
    @() sim(set_param(new_system('r'), 'InitFcn', 'error(''monRappel:echec'', ''non'')')), ...
        'Simulink:Engine:CallbackEvalErr', 'InitFcn'
    @() set_param(new_system('r'), 'InitFcn', 3), 'Simulink:Config:InvalidValue', 'InitFcn'
    @() set_param(new_system('r'), 'SimulationCommand', 'avancer'), ...
        'Simulink:Commands:SetParamInvalidArgumentValue', 'avancer'
    @() set_param(new_system('r'), 'SimulationMode', 'turbo'), 'Simulink:Config:InvalidValue', 'turbo'
    @() set_param(new_system('r'), 'ReturnWorkspaceOutputsName', '2x'), ...
        'Simulink:Config:InvalidValue', '2x'
    @() set_param(add_block(new_system('u'), 'chose', 'b'), 'SimulationCommand', 'update'), ...
        'Simulink:Commands:InvalidBlockType', 'chose'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('rappels et commandes, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('rappels et commandes : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------------------------- 25. Stateflow : hierarchie et temps
% Des états emboîtés : on entre du plus haut au plus profond, on sort du
% plus profond au plus haut ; une transition partie d'un parent sort de
% son sous-état actif, quel qu'il soit. Le journal du contexte garde
% l'ordre des actions.
noter = @(quoi) @(c) setfield(c, 'journal', [c.journal, {quoi}]);
m = sfchart('feux');
m = sfstate(m, 'marche', noter('entre marche'), [], noter('sort marche'));
m = sfstate(m, 'marche.vert', noter('entre vert'), [], noter('sort vert'));
m = sfstate(m, 'marche.orange', noter('entre orange'), [], noter('sort orange'));
m = sfstate(m, 'panne', noter('entre panne'));
m = sftransition(m, 'marche.vert', 'marche.orange', @(c, u) u == 1);
m = sftransition(m, 'marche', 'panne', @(c, u) u == 9);
m = sftransition(m, 'panne', 'marche', @(c, u) u == 0);
[e, c] = sfstep(m, '', struct('journal', {{}}), []);
assert(strcmp(e, 'marche.vert') && isequal(c.journal, {'entre marche', 'entre vert'}), ...
       'on entre du plus haut au sous-etat par defaut');
[e, c] = sfstep(m, e, c, 1);
assert(strcmp(e, 'marche.orange') && isequal(c.journal(3:4), {'sort vert', 'entre orange'}), ...
       'une transition entre freres ne sort pas du parent');
[e, c] = sfstep(m, e, c, 9);
assert(strcmp(e, 'panne') && ...
       isequal(c.journal(5:7), {'sort orange', 'sort marche', 'entre panne'}), ...
       'la transition du parent sort de son sous-etat actif, puis de lui');
[e, c] = sfstep(m, e, c, 0);
assert(strcmp(e, 'marche.vert'), 'revenir au parent, c''est entrer dans son defaut');
% Le parent passe avant ses sous-états : sa transition l'emporte.
m2 = sftransition(m, 'marche.vert', 'marche.orange', @(c, u) u == 9);
[e2, ~] = sfrun(m2, 9, struct('journal', {{}}));
assert(strcmp(e2{1}, 'panne'), 'la transition du parent est essayee d''abord');
% Une transition vers soi sort et rentre.
m3 = sftransition(m, 'panne', 'panne', @(c, u) u == 5);
[e3, c3] = sfrun(m3, [9 5], struct('journal', {{}}));
assert(strcmp(e3{2}, 'panne') && sum(strcmp(c3.journal, 'entre panne')) == 2, ...
       'une transition vers soi rentre dans l''etat');

% Deux régions parallèles, chacune sa machine ; l'historique ramène au
% sous-état quitté ; SFDEFAULT choisit l'entrée.
m = sfchart('voiture');
m = sfstate(m, 'phares');
m = sfstate(m, 'phares.eteints');
m = sfstate(m, 'phares.allumes');
m = sfstate(m, 'moteur');
m = sfstate(m, 'moteur.arret');
m = sfstate(m, 'moteur.marche');
m = sfdecomposition(m, '', 'parallel');
m = sftransition(m, 'phares.eteints', 'phares.allumes', @(c, u) u == 1);
m = sftransition(m, 'moteur.arret', 'moteur.marche', @(c, u) u == 2);
h = sfrun(m, [1 2]);
assert(isequal(h{1}, {'phares.allumes', 'moteur.arret'}) && ...
       isequal(h{2}, {'phares.allumes', 'moteur.marche'}), ...
       'les regions paralleles avancent chacune');
m = sfchart('lecteur');
m = sfstate(m, 'arret');
m = sfstate(m, 'lecture');
m = sfstate(m, 'lecture.piste1');
m = sfstate(m, 'lecture.piste2');
m = sftransition(m, 'lecture.piste1', 'lecture.piste2', @(c, u) u == 1);
m = sftransition(m, 'lecture', 'arret', @(c, u) u == 2);
m = sftransition(m, 'arret', 'lecture', @(c, u) u == 3);
h = sfrun(m, [3 1 2 3]);
assert(strcmp(h{4}, 'lecture.piste1'), 'sans historique, on rentre par le defaut');
h = sfrun(sfhistory(m, 'lecture'), [3 1 2 3]);
assert(strcmp(h{4}, 'lecture.piste2'), 'avec historique, on rentre ou l''on etait');
h = sfrun(sfdefault(m, 'lecture.piste2'), 3);
assert(strcmp(h{1}, 'lecture.piste2'), 'SFDEFAULT choisit le sous-etat d''entree');

% La logique temporelle : après N réveils, avant, au N-ième, tous les N ;
% en secondes, avec l'instant de chaque pas.
m = sfchart('minuterie');
m = sfstate(m, 'attente');
m = sfstate(m, 'fini');
m = sftransition(m, 'attente', 'fini', @(c, u) sfafter(c, 3));
h = sfrun(m, zeros(1, 4));
assert(isequal(h, {'attente', 'attente', 'fini', 'fini'}), 'after(3, tick)');
mSec = sftransition(sfstate(sfstate(sfchart('s'), 'a'), 'b'), 'a', 'b', ...
                    @(c, u) sfafter(c, 0.25, 'sec'));
h = sfrun(mSec, zeros(1, 4), struct(), 0:0.1:0.4);
assert(isequal(h, {'a', 'a', 'b', 'b'}), 'after(0.25, sec)');
m = sfchart('clignotant');
m = sfstate(m, 'actif', [], @(c, u) setfield(c, 'coups', c.coups + sfevery(c, 2)));
[~, c] = sfrun(m, zeros(1, 6), struct('coups', 0));
assert(c.coups == 3, 'every(2, tick)');
m = sftransition(sfstate(sfstate(sfchart('i'), 'bas'), 'haut'), 'bas', 'haut', ...
                 @(c, u) sfat(c, 2));
assert(isequal(sfrun(m, zeros(1, 3)), {'bas', 'haut', 'haut'}), 'at(2, tick)');
m = sftransition(sfstate(sfstate(sfchart('f'), 'ouverte'), 'vue'), 'ouverte', 'vue', ...
                 @(c, u) u == 1 && sfbefore(c, 2));
assert(isequal(sfrun(m, [0 0 1]), {'ouverte', 'ouverte', 'ouverte'}), 'before(2, tick)');

% Dans un schéma : un clignotant qui bascule toutes les 0,5 s, en secondes
% de simulation, et deux régions parallèles dont la sortie etat rend la
% première.
m = sfchart('clignoteur');
m = sfstate(m, 'eteint', @(c) setfield(c, 'lampe', 0));
m = sfstate(m, 'allume', @(c) setfield(c, 'lampe', 1));
m = sftransition(m, 'eteint', 'allume', @(c, u) sfafter(c, 0.5, 'sec'));
m = sftransition(m, 'allume', 'eteint', @(c, u) sfafter(c, 0.5, 'sec'));
schema = new_system('clignote');
schema = add_block(schema, 'chart', 'lampe', 'Chart', m, 'Inputs', 0, ...
                   'Outputs', {'lampe', 'etat'}, 'InitialContext', struct('lampe', 0), ...
                   'SampleTime', 0.1);
for solveur = {'ode1', 'ode45'}
    r = sim(schema, 'Solver', solveur{1}, 'FixedStep', 0.1, 'StopTime', 2);
    for instant = [0 0.4 0.5 0.9 1.0 1.5]
        i = find(abs(r.temps - instant) < 1e-9, 1);
        assert(r.signaux.lampe(i) == mod(floor(instant / 0.5 + 1e-9), 2), ...
               sprintf('%s : le clignotant a %g', solveur{1}, instant));
    end
end

% Le langage d'action en texte : étiquettes d'état « en: du: ex: »,
% étiquettes de transition « evenement[condition]{action}/action », et
% logique temporelle écrite comme dans Stateflow.
m = sfchart('compteur');
m = sfstate(m, 'arret', 'en: y = 0;');
m = sfstate(m, 'compte', 'en: n = 0; du: n = n + u; ex: y = n;');
m = sftransition(m, 'arret', 'compte', 'go');
m = sftransition(m, 'compte', 'arret', '[n >= 3]{alerte = 1;}', 'fin = 1;');
[h, c] = sfrun(m, {'rien', 'go', 1, 1, 1, 0}, struct('alerte', 0));
assert(isequal(h, {'arret', 'compte', 'compte', 'compte', 'compte', 'arret'}), ...
       'texte : une entree dans un etat n''execute pas son sejour au meme pas');
assert(c.n == 3 && c.alerte == 1 && c.fin == 1 && c.y == 0, 'texte : actions');
assert(~isfield(c, 'ans'), 'texte : ans ne remonte pas au contexte');
m = sfchart('minuterie');
m = sfstate(m, 'a');
m = sfstate(m, 'b');
m = sftransition(m, 'a', 'b', '[after(3, tick)]');
assert(isequal(sfrun(m, zeros(1, 4)), {'a', 'a', 'b', 'b'}), 'texte : after(3, tick)');
m = sfchart('rythme');
m = sfstate(m, 'a', 'du: k = k + every(2, tick);');
[~, c] = sfrun(m, zeros(1, 6), struct('k', 0));
assert(c.k == 3, 'texte : every(2, tick)');
m = sfchart('t');
m = sfstate(m, 'tourne', 'du: s = s + u;');
[~, c] = sfrun(m, [1 2 3], struct('s', 0));
assert(c.s == 6, 'texte : action de sejour');
c = matlibre_sf_evaluer('x = x + u; z = 2 * x;', struct('x', 1), 2, false);
assert(c.x == 3 && c.z == 6, 'texte : evaluer');
m = sfchart('mixte');
m = sfstate(m, 'a', 'v = 1;', @(c, u) setfield(c, 'v', c.v + u), '');
[~, c] = sfrun(m, [2 3]);
assert(c.v == 6, 'texte : poignees et texte melanges');
% dans un bloc Chart, les événements arrivent par l'entrée
schema = new_system('lampeTexte');
schema = add_block(schema, 'constant', 'u', 'Value', 1);
m = sfchart('lampeTexte');
m = sfstate(m, 'eteint', 'en: lampe = 0;');
m = sfstate(m, 'allume', 'en: lampe = 1;');
m = sftransition(m, 'eteint', 'allume', '[after(0.5, sec) && u > 0]');
m = sftransition(m, 'allume', 'eteint', '[after(0.5, sec)]');
schema = add_block(schema, 'chart', 'lampe', 'Chart', m, 'Inputs', 1, ...
                   'Outputs', {'lampe'}, 'InitialContext', struct('lampe', 0), ...
                   'SampleTime', 0.1);
schema = add_line(schema, 'u/1', 'lampe/1');
r = sim(schema, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 2);
for instant = [0 0.4 0.5 0.9 1.0 1.5]
    i = find(abs(r.temps - instant) < 1e-9, 1);
    assert(r.signaux.lampe(i) == mod(floor(instant / 0.5 + 1e-9), 2), ...
           sprintf('texte : le clignotant a %g', instant));
end

% Les erreurs.
casErreurs = {
    @() sfstate(sfchart('x'), 'a.b'), 'Stateflow:EtatParentAbsent', 'a'
    @() sfstate(sfstate(sfchart('x'), 'a'), 'a'), 'Stateflow:EtatDouble', 'a'
    @() sfdecomposition(sfchart('x'), '', 'melange'), 'Stateflow:DecompositionInconnue', 'melange'
    @() sfhistory(sfchart('x'), 'absent'), 'Stateflow:EtatInconnu', 'absent'
    @() sfrun(sftransition(sfdecomposition(sfstate(sfstate(sfchart('x'), 'a'), 'b'), '', ...
        'parallel'), 'a', 'b', @(c, u) true), 1), 'Stateflow:TransitionEntreParalleles', 'paralleles'
    @() sfafter(struct(), 1), 'Stateflow:TempsInconnu', 'sf_ticks'
    @() sfrun(mSec, 0), 'Stateflow:TempsInconnu', 'sf_t'
    @() sfafter(struct('sf_ticks', 1), 1, 'minute'), 'Stateflow:UniteTemporelle', 'minute'
    @() sfrun(sfstate(sfchart('x'), 'a', 'du: y = inconnue + 1;'), [1 2]), 'Stateflow:TexteInvalide', 'inconnue'
    @() sfrun(sftransition(sfstate(sfstate(sfchart('x'), 'a'), 'b'), 'a', 'b', ...
        '[every(2, sec)]'), [1 2]), 'Stateflow:UniteTemporelle', 'every'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('stateflow, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('stateflow : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------------------- 26. Batteries croisees sur tout le catalogue
% Chaque type de bloc du catalogue, seul, puis dans une boucle fermée,
% puis en amont et en aval des autres. Chaque modèle ainsi bâti doit
% soit se simuler, soit être refusé par une erreur de Simulink — un
% identifiant « Simulink:… » ou « Stateflow:… », et un message qui nomme
% un bloc par son chemin —, jamais par une erreur interne du simulateur.
% Les modèles de la batterie écrivent — un To File pose son fichier là où
% l'on se trouve — : on travaille dans un dossier temporaire, effacé à la
% fin, pour ne rien laisser derrière soi.
dossierBatterie = tempname();
mkdir(dossierBatterie);
dossierAvantBatterie = pwd();
cd(dossierBatterie);
catalogueBatterie = matlibre_sl_catalogue();
typesBatterie = {};
for kT = 1:numel(catalogueBatterie)
    if ~strcmp(catalogueBatterie(kT).famille, 'Interne')
        typesBatterie{end + 1} = catalogueBatterie(kT).type; %#ok<SAGROW>
    end
end
nTypes = numel(typesBatterie);

% Chaque type seul, sur un scalaire et sur un vecteur.
nSimules = 0;
nRefuses = 0;
for kT = 1:nTypes
    for valeur = {0.5, [0.5; 1.5; 2.5]}
        [s, ok] = batterieModele('solo', typesBatterie(kT), valeur{1});
        if ~ok, continue, end
        for solveur = {'ode1', 'ode45'}
            id = batterieSimuler(s, solveur{1}, typesBatterie{kT});
            if strcmp(id, 'ok'), nSimules = nSimules + 1; else, nRefuses = nRefuses + 1; end
        end
    end
end
fprintf('batterie, chaque bloc seul : %d simulations, %d refus nommes\n', nSimules, nRefuses);

% Chaque type dans une boucle fermée r - T(e) -> e, sous trois solveurs.
nSimules = 0;
nRefuses = 0;
for kT = 1:nTypes
    s = new_system('boucle');
    s = add_block(s, typesBatterie{kT}, 'b');
    [ne, ns] = matlibre_sl_ports(s.blocs{1});
    if isnan(ne), ne = 1; end
    if isnan(ns), ns = 1; end
    if ne == 0 || ns == 0, continue, end
    s = add_block(s, 'sine', 'r', 'Amplitude', 0.5, 'Bias', 0.25);
    s = add_block(s, 'sum', 'e', 'Signs', '+-');
    s = add_line(s, 'r/1', 'e/1');
    s = add_line(s, 'e/1', 'b/1');
    s = add_line(s, 'b/1', 'e/2');
    for i = 2:ne
        s = add_block(s, 'constant', sprintf('c%d', i), 'Value', 0.5);
        s = add_line(s, sprintf('c%d/1', i), sprintf('b/%d', i));
    end
    for j = 1:ns
        s = add_block(s, 'outport', sprintf('o%d', j));
        s = add_line(s, sprintf('b/%d', j), sprintf('o%d/1', j));
    end
    for solveur = {'ode1', 'ode45', 'ode15s'}
        id = batterieSimuler(s, solveur{1}, ['boucle sur ' typesBatterie{kT}]);
        if strcmp(id, 'ok'), nSimules = nSimules + 1; else, nRefuses = nRefuses + 1; end
    end
end
fprintf('batterie, chaque bloc en boucle : %d simulations, %d refus nommes\n', ...
        nSimules, nRefuses);

% Chaque type seul dans un sous-système activé, déclenché, itéré, masqué,
% ou sous une période discrète : les ports de contrôle en double, les
% itérateurs mal placés, les états continus là où Simulink les refuse,
% tout est une erreur nommée.
nSimules = 0;
nRefuses = 0;
contextesBatterie = {'enable', 'trigger', 'for', 'discret', 'masque'};
for kT = 1:nTypes
    for kC = 1:numel(contextesBatterie)
        m = batterieContexte(typesBatterie{kT}, contextesBatterie{kC});
        solveur = {'ode1', 'ode45'};
        id = batterieSimuler(m, solveur{1 + mod(kT + kC, 2)}, ...
                             [typesBatterie{kT} ' dans ' contextesBatterie{kC}]);
        if strcmp(id, 'ok'), nSimules = nSimules + 1; else, nRefuses = nRefuses + 1; end
    end
end
fprintf('batterie, chaque bloc dans un sous-systeme : %d simulations, %d refus nommes\n', ...
        nSimules, nRefuses);

% Chaque paramètre de chaque type, mis à une valeur qu'on pourrait taper
% par erreur : une variable qui n'existe pas, NaN, vide, une matrice, un
% nombre négatif, un complexe, une expression mal formée, un choix qui
% n'existe pas. Le bloc se simule, ou il est refusé — par ADD_BLOCK ou
% par SIM — par une erreur de Simulink qui le nomme.
nEssais = 0;
nRefuses = 0;
for kT = 1:nTypes
    entree = catalogueBatterie(strcmp({catalogueBatterie.type}, typesBatterie{kT}));
    for q = 1:size(entree.params, 1)
        nomP = entree.params{q, 1};
        nature = entree.params{q, 3};
        if iscell(nature)
            fautes = {'choixInexistant', 3};
        elseif ischar(nature) && strcmp(nature, 'modele')
            fautes = {42};
        else
            fautes = {'variableInexistante', NaN, [], [1 2; 3 4], -1, 1 + 2i, 'texte ('};
        end
        for f = 1:numel(fautes)
            nEssais = nEssais + 1;
            contexte = sprintf('%s.%s = %s', typesBatterie{kT}, nomP, ...
                               strtrim(evalc('disp(fautes{f})')));
            try
                s = batterieFautif(typesBatterie{kT}, nomP, fautes{f});
            catch err
                assert(strncmp(err.identifier, 'Simulink:', 9), ...
                       sprintf('%s : erreur interne %s : %s', contexte, err.identifier, ...
                               err.message));
                nRefuses = nRefuses + 1;
                continue
            end
            if ~strcmp(batterieSimuler(s, 'ode45', contexte), 'ok')
                nRefuses = nRefuses + 1;
            end
        end
    end
end
fprintf('batterie, parametres fautifs : %d essais, %d refus nommes\n', nEssais, nRefuses);

% Les paires : un type en amont d'un autre. Toutes les paires se
% simulent en quelques minutes ; la batterie en prend une sur sept, choisie
% pour que chaque type soit en amont et en aval d'une quinzaine d'autres.
nSimules = 0;
nRefuses = 0;
for k1 = 1:nTypes
    for k2 = 1:nTypes
        if mod(k1 + 3 * k2, 7) ~= 0, continue, end
        [s, ok] = batterieModele('paire', typesBatterie([k1 k2]), 1.5);
        if ~ok, continue, end
        solveur = {'ode1', 'ode45'};
        id = batterieSimuler(s, solveur{1 + mod(k1 + k2, 2)}, ...
                             [typesBatterie{k1} ' -> ' typesBatterie{k2}]);
        if strcmp(id, 'ok'), nSimules = nSimules + 1; else, nRefuses = nRefuses + 1; end
    end
end
fprintf('batterie, paires de blocs : %d simulations, %d refus nommes\n', nSimules, nRefuses);

% Les défauts de Simulink : une Transfer Fcn posée telle quelle est
% 1/(s+1), une Discrete Transfer Fcn 1/(z+0.5) ; une transmittance
% réduite à un gain n'a pas d'état et se simule.
s = new_system('defauts');
s = add_block(s, 'step', 'u');
s = add_block(s, 'transferfcn', 'h');
s = add_block(s, 'transferfcn', 'g', 'Numerator', 3, 'Denominator', 2);
s = add_block(s, 'discretetransferfcn', 'd', 'SampleTime', 1);
s = add_line(s, 'u/1', 'h/1');
s = add_line(s, 'u/1', 'g/1');
s = add_line(s, 'u/1', 'd/1');
s = add_block(s, 'outport', 'oh');
s = add_line(s, 'h/1', 'oh/1');
s = add_block(s, 'outport', 'og');
s = add_line(s, 'g/1', 'og/1');
s = add_block(s, 'outport', 'od');
s = add_line(s, 'd/1', 'od/1');
r = sim(s, 'Solver', 'ode45', 'StopTime', 5, 'RelTol', 1e-8, 'AbsTol', 1e-10);
tS = r.tout;
assert(max(abs(r.yout(tS >= 1, 1) - (1 - exp(-(tS(tS >= 1) - 1))))) < 1e-5, ...
       'defaut de la Transfer Fcn : 1/(s+1)');
assert(all(abs(r.yout(tS >= 1, 2) - 1.5) < 1e-12), 'transmittance reduite a un gain');
iD = find(abs(tS - 4) < 1e-9, 1);
% y(k) = -0.5 y(k-1) + u(k-1), l'échelon en k = 1 : y(2) = 1, y(3) = 0.5, y(4) = 0.75
assert(abs(r.yout(iD, 3) - 0.75) < 1e-12, 'defaut de la Discrete Transfer Fcn : 1/(z+0.5)');

% Un filtre discret sur un vecteur : chaque élément est une voie, filtrée
% à part, comme dans Simulink. Le Discrete Zero-Pole reste scalaire.
s = new_system('voies');
s = add_block(s, 'sine', 'u', 'Amplitude', [1; 2; 3], 'Frequency', [1; 2; 3]);
s = add_block(s, 'discretetransferfcn', 'f', 'Numerator', [1 0.2], ...
              'Denominator', [1 -0.5 0.06], 'SampleTime', 0.1);
s = add_block(s, 'discretefilter', 'g', 'Numerator', [0 1], 'Denominator', [1 -0.8], ...
              'SampleTime', 0.1);
s = add_line(s, 'u/1', 'f/1');
s = add_line(s, 'u/1', 'g/1');
s = add_block(s, 'outport', 'o1');
s = add_line(s, 'f/1', 'o1/1');
s = add_block(s, 'outport', 'o2');
s = add_line(s, 'g/1', 'o2/1');
r = sim(s, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1, 'StopTime', 2);
for j = 1:3
    u = j * sin(j * r.tout);
    assert(max(abs(r.yout(:, j) - filter([0 1 0.2], [1 -0.5 0.06], u))) < 1e-12, ...
           sprintf('voie %d du Discrete Transfer Fcn', j));
    assert(max(abs(r.yout(:, 3 + j) - filter([0 1], [1 -0.8], u))) < 1e-12, ...
           sprintf('voie %d du Discrete Filter', j));
end
s = new_system('boucleVoies');
s = add_block(s, 'constant', 'r', 'Value', [1; 2]);
s = add_block(s, 'sum', 'e', 'Signs', '+-');
s = add_block(s, 'discretetransferfcn', 'f', 'Numerator', 0.5, 'Denominator', [1 -0.5], ...
              'SampleTime', 1);
s = add_line(s, 'r/1', 'e/1');
s = add_line(s, 'e/1', 'f/1');
s = add_line(s, 'f/1', 'e/2');
s = add_block(s, 'outport', 'o');
s = add_line(s, 'f/1', 'o/1');
r = sim(s, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 60);
assert(max(abs(r.yout(end, :) - [0.5 1])) < 1e-9, 'boucle vectorielle par un filtre discret');

% Une MATLAB Function dans une boucle : sa taille se déduit de la boucle.
s = new_system('boucleFonction');
s = add_block(s, 'constant', 'r', 'Value', 1);
s = add_block(s, 'sum', 'e', 'Signs', '+-');
s = add_block(s, 'matlabfunction', 'f', 'Script', sprintf('function y = f(u)\ny = 0.5 * u;'));
s = add_block(s, 'outport', 'o');
s = add_line(s, 'r/1', 'e/1');
s = add_line(s, 'e/1', 'f/1');
s = add_line(s, 'f/1', 'e/2');
s = add_line(s, 'f/1', 'o/1');
evalc('r = sim(s, ''Solver'', ''ode1'', ''FixedStep'', 0.1, ''StopTime'', 0.2);');
assert(max(abs(r.yout - 1 / 3)) < 1e-9, 'MATLAB Function dans une boucle algebrique');

% Les erreurs.
modeleVoisin = add_block(new_system('m'), 'constant', 'c');
casErreurs = {
    @() sim(add_line(add_block(add_block(new_system('zp'), 'constant', 'u', 'Value', [1; 2]), ...
        'discretezeropole', 'z', 'SampleTime', 1), 'u/1', 'z/1')), ...
        'Simulink:Engine:DimensionMismatch', 'zp/z'
    @() add_block(new_system('m'), 'iterateur', 'i'), 'Simulink:Commands:InvalidBlockType', 'interne'
    @() add_block(new_system('m'), 'garde', 'g'), 'Simulink:Commands:InvalidBlockType', 'interne'
    @() sim(add_block(new_system('vide'), 'subsystem', 's')), 'Simulink:Commands:SousSystemeVide', 'vide/s'
    @() sim(add_block(new_system('r'), 'modelreference', 'm')), ...
        'Simulink:modelReference:ModelNameEmpty', 'r/m'
    @() get_param(modeleVoisin, 'absent', 'Value'), 'Simulink:Commands:InvSimulinkObjectName', 'absent'
    @() set_param(modeleVoisin, 'absent', 'Value', 1), 'Simulink:Commands:InvSimulinkObjectName', 'absent'
    @() add_line(modeleVoisin, 'c/1', 'absent/1'), 'Simulink:Commands:InvSimulinkObjectName', 'absent'
    @() get_param(modeleVoisin, 'c', 'Absent'), 'Simulink:Commands:ParamUnknown', 'Absent'
    @() delete_line(modeleVoisin, 'c/1', 'c/1'), 'Simulink:Commands:DeleteLineNoLine', 'c'
    @() sim(modeleVoisin, 'StartTime', 2, 'StopTime', 1), ...
        'Simulink:SolverConfig:StopTimeBeforeStartTime', 'duree'
    @() sim(add_block(new_system('fw'), 'fromworkspace', 'f')), ...
        'Simulink:blocks:FromWorkspaceVariableNotFound', 'fw/f'
    @() sim(add_block(new_system('cplx'), 'saturation', 's', 'UpperLimit', 1 + 2i)), ...
        'Simulink:Parameters:InvParamSetting', 'complexe'
    @() sim(add_block(new_system('vide'), 'constant', 'c', 'Value', [])), ...
        'Simulink:Parameters:InvParamSetting', 'vide/c'
    @() sim(add_block(new_system('sg'), 'sum', 's', 'Signs', '+x')), ...
        'Simulink:Parameters:InvParamSetting', 'Signs'
    @() sim(add_block(new_system('pr'), 'product', 'p', 'Inputs', '*+')), ...
        'Simulink:Parameters:InvParamSetting', 'Inputs'
    @() sim(add_block(new_system('st'), 'constant', 'c', 'SampleTime', NaN)), ...
        'Simulink:SampleTime:InvalidSampleTime', 'st/c'
    @() sim(add_block(new_system('po'), 'inport', 'i', 'Port', 0)), ...
        'Simulink:Parameters:InvParamSetting', 'entier positif'
    @() sim(add_block(new_system('tf'), 'tofile', 'f', 'MatrixName', 'a b')), ...
        'Simulink:blocks:ToFileInvalidName', 'tf/f'
    @() sim(add_block(new_system('ssm'), 'subsystem', 's', 'Model', 42)), ...
        'Simulink:Commands:SousSystemeVide', 'ssm/s'
    @() sim(add_line(add_line(add_block(add_block(add_block(new_system('nan'), 'constant', ...
        'u'), 'integrator', 'i', 'InitialCondition', NaN), 'outport', 'o'), 'u/1', 'i/1'), ...
        'i/1', 'o/1'), 'Solver', 'ode45'), 'Simulink:Engine:DerivNotFinite', 'nan/i'
    @() sim(batterieFautif('switch', 'Threshold', [1 2; 3 4]), 'Solver', 'ode45'), ...
        'Simulink:Parameters:InvParamSetting', 'Threshold'
    @() sim(batterieFautif('transportdelay', 'DelayTime', -1)), ...
        'Simulink:blocks:TransportDelayNegativeDelay', 'fautif/b'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('batterie, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('batterie : %d cas d''erreur verifies\n', size(casErreurs, 1));
cd(dossierAvantBatterie);
rmdir(dossierBatterie, 's');

%% ------------------------------------------------------- 27. odeN et daessc
% odeN applique à pas fixe, sans l'adapter, la formule que choisit
% ODENIntegrationMethod — ode3 par défaut : il rend, au bit près, ce que
% rend le solveur du même nom. daessc intègre par les BDF, d'ordre 1 à
% MaxOrder : les NDF d'ode15s sans leur correction.
oscillateur = new_system('oscillateur');
oscillateur = add_block(oscillateur, 'integrator', 'v', 'InitialCondition', 1);
oscillateur = add_block(oscillateur, 'integrator', 'x', 'InitialCondition', 0);
oscillateur = add_block(oscillateur, 'gain', 'k', 'Gain', -4);
oscillateur = add_block(oscillateur, 'outport', 'y');
oscillateur = add_line(oscillateur, 'v/1', 'x/1');
oscillateur = add_line(oscillateur, 'x/1', 'k/1');
oscillateur = add_line(oscillateur, 'k/1', 'v/1');
oscillateur = add_line(oscillateur, 'x/1', 'y/1');
for methode = {'ode1', 'ode2', 'ode3', 'ode4', 'ode5', 'ode8'}
    a = sim(oscillateur, 'Solver', 'odeN', 'ODENIntegrationMethod', methode{1}, ...
            'FixedStep', 0.05, 'StopTime', 2);
    b = sim(oscillateur, 'Solver', methode{1}, 'FixedStep', 0.05, 'StopTime', 2);
    assert(isequal(a.yout, b.yout), ['odeN avec ' methode{1}]);
end
a = sim(oscillateur, 'Solver', 'odeN', 'FixedStep', 0.05, 'StopTime', 2);
b = sim(oscillateur, 'Solver', 'ode3', 'FixedStep', 0.05, 'StopTime', 2);
assert(isequal(a.yout, b.yout), 'odeN par defaut : ode3');
avecOdeN = set_param(oscillateur, 'Solver', 'odeN', 'ODENIntegrationMethod', 'ode5');
assert(strcmp(get_param(avecOdeN, 'SolverType'), 'Fixed-step') && ...
       strcmp(get_param(avecOdeN, 'ODENIntegrationMethod'), 'ode5'), 'odeN est a pas fixe');
% le réglage voyage avec le modèle, dans le .slx
fichierSlx = [tempname() '.slx'];
save_system(avecOdeN, fichierSlx);
relu = load_system(fichierSlx);
delete(fichierSlx);
assert(strcmp(get_param(relu, 'Solver'), 'odeN') && ...
       strcmp(get_param(relu, 'ODENIntegrationMethod'), 'ode5'), 'odeN relu du .slx');

% daessc, sur un système raide : chaque ordre maximal suit la solution
% exacte, et un ordre plus haut fait moins de pas
raide = new_system('raide');
raide = add_block(raide, 'integrator', 'x', 'InitialCondition', 1);
raide = add_block(raide, 'gain', 'k', 'Gain', -1000);
raide = add_block(raide, 'step', 'u', 'Time', 0.5, 'After', 1000);
raide = add_block(raide, 'sum', 's', 'Signs', '++');
raide = add_block(raide, 'outport', 'y');
raide = add_line(raide, 'x/1', 'k/1');
raide = add_line(raide, 'k/1', 's/1');
raide = add_line(raide, 'u/1', 's/2');
raide = add_line(raide, 's/1', 'x/1');
raide = add_line(raide, 'x/1', 'y/1');
nPas = zeros(1, 5);
for ordre = 1:5
    o = sim(raide, 'Solver', 'daessc', 'MaxOrder', ordre, 'StopTime', 1, ...
            'RelTol', 1e-6, 'AbsTol', 1e-8);
    exacte = exp(-1000 * o.tout) .* (o.tout < 0.5) + ...
             (o.tout >= 0.5) .* (1 + (exp(-500) - 1) * exp(-1000 * (o.tout - 0.5)));
    assert(max(abs(o.yout - exacte)) < 1e-3, sprintf('daessc, ordre maximal %d', ordre));
    nPas(ordre) = numel(o.tout);
end
assert(all(diff(nPas(1:3)) < 0) && nPas(5) <= nPas(3), ...
       'daessc : un ordre maximal plus haut fait moins de pas');
% sur l'oscillateur, daessc suit la solution exacte sin(2t)/2
d = sim(oscillateur, 'Solver', 'daessc', 'StopTime', 3, 'RelTol', 1e-8, 'AbsTol', 1e-10);
assert(max(abs(d.yout - sin(2 * d.tout) / 2)) < 1e-5, 'daessc sur un oscillateur');
assert(strcmp(get_param(set_param(oscillateur, 'Solver', 'daessc'), 'SolverType'), ...
              'Variable-step'), 'daessc est a pas variable');
% les BDF et les NDF sont deux familles : daessc et ode15s ne font pas les
% mêmes pas
e = sim(oscillateur, 'Solver', 'ode15s', 'StopTime', 3, 'RelTol', 1e-8, 'AbsTol', 1e-10);
assert(numel(d.tout) ~= numel(e.tout) || max(abs(d.yout - e.yout)) > 0, ...
       'daessc n''est pas ode15s sous un autre nom');

casErreurs = {
    @() set_param(oscillateur, 'ODENIntegrationMethod', 'ode14x'), ...
        'Simulink:Config:InvalidValue', 'ode8'
    @() sim(oscillateur, 'Solver', 'daessc', 'MaxOrder', 6), 'Simulink:Config:InvalidValue', ...
        'de 1 a 5'
    @() set_param(oscillateur, 'Solver', 'ode6'), 'Simulink:Commands:SolveurInconnu', 'daessc'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('odeN et daessc, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('odeN et daessc : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------------------------------- 28. Types de bus : Simulink.Bus
% Un type de bus se définit comme dans Simulink, par Simulink.Bus et
% Simulink.BusElement, et se range dans l'espace de travail de base. Un
% Bus Creator, une entrée, une sortie, un port de sous-système le
% reçoivent par OutDataTypeStr, 'Bus: Nom' : le bus prend les noms du
% type, et ce qui ne s'y accorde pas est refusé en nommant le bloc.
clear elementsBus
elementsBus(1) = Simulink.BusElement;
elementsBus(1).Name = 'position';
elementsBus(2) = Simulink.BusElement;
elementsBus(2).Name = 'vitesse';
elementsBus(2).Dimensions = 2;
Capteurs = Simulink.Bus;
Capteurs.Elements = elementsBus;
assignin('base', 'Capteurs', Capteurs);
assert(strcmp(class(Capteurs), 'Simulink.Bus') && ...
       strcmp(class(Capteurs.Elements), 'Simulink.BusElement') && ...
       numel(Capteurs.Elements) == 2, 'un type de bus et ses elements');
assert(strcmp(Simulink.BusElement().Name, 'a') && Simulink.BusElement().Dimensions == 1 && ...
       strcmp(Simulink.BusElement().DataType, 'double'), 'les defauts d''un element');
modeleVide = Simulink.Bus.createMATLABStruct('Capteurs');
assert(isequal(fieldnames(modeleVide), {'position'; 'vitesse'}) && ...
       modeleVide.position == 0 && isequal(modeleVide.vitesse, [0; 0]), ...
       'createMATLABStruct : la forme du bus, en zeros');
assert(isequal(Simulink.Bus.createMATLABStruct(Capteurs), modeleVide), ...
       'createMATLABStruct accepte l''objet comme son nom');

% Un Bus Creator typé : les éléments prennent les noms du type.
typeBus = new_system('typeBus');
typeBus = add_block(typeBus, 'constant', 'p', 'Value', 3);
typeBus = add_block(typeBus, 'constant', 'v', 'Value', [1; 2]);
typeBus = add_block(typeBus, 'buscreator', 'bc', 'Inputs', '2', ...
                    'OutDataTypeStr', 'Bus: Capteurs');
typeBus = add_block(typeBus, 'busselector', 'bs', 'OutputSignals', 'vitesse,position');
typeBus = add_block(typeBus, 'outport', 'o1');
typeBus = add_block(typeBus, 'outport', 'o2', 'OutDataTypeStr', 'Inherit: auto');
typeBus = add_line(typeBus, 'p/1', 'bc/1');
typeBus = add_line(typeBus, 'v/1', 'bc/2');
typeBus = add_line(typeBus, 'bc/1', 'bs/1');
typeBus = add_line(typeBus, 'bs/1', 'o1/1');
typeBus = add_line(typeBus, 'bs/2', 'o2/1');
r = sim(typeBus, 'StopTime', 1);
assert(isequal(r.yout(end, :), [1 2 3]), 'le Bus Selector choisit par les noms du type');

% Un sous-système dont l'entrée est typée reçoit le bus, et le lit par
% ses noms ; une sortie de modèle typée reçoit un bus de son type.
dedans = new_system('dedans');
dedans = add_block(dedans, 'inport', 'e', 'OutDataTypeStr', 'Bus: Capteurs');
dedans = add_block(dedans, 'busselector', 'bs', 'OutputSignals', 'position');
dedans = add_block(dedans, 'gain', 'g', 'Gain', 10);
dedans = add_block(dedans, 'outport', 's');
dedans = add_line(dedans, 'e/1', 'bs/1');
dedans = add_line(dedans, 'bs/1', 'g/1');
dedans = add_line(dedans, 'g/1', 's/1');
porteur = new_system('porteur');
porteur = add_block(porteur, 'constant', 'p', 'Value', 4);
porteur = add_block(porteur, 'constant', 'v', 'Value', [5; 6]);
porteur = add_block(porteur, 'buscreator', 'bc', 'Inputs', 'position,vitesse');
porteur = add_block(porteur, 'subsystem', 'sous', 'Model', dedans);
porteur = add_block(porteur, 'outport', 'y');
porteur = add_block(porteur, 'outport', 'b', 'OutDataTypeStr', 'Bus: Capteurs');
porteur = add_line(porteur, 'p/1', 'bc/1');
porteur = add_line(porteur, 'v/1', 'bc/2');
porteur = add_line(porteur, 'bc/1', 'sous/1');
porteur = add_line(porteur, 'sous/1', 'y/1');
porteur = add_line(porteur, 'bc/1', 'b/1');
r = sim(porteur, 'StopTime', 1);
assert(r.yout(end, 1) == 40 && isequal(r.yout(end, 2:4), [4 5 6]), ...
       'un bus de noms accordes traverse les ports types');

% Une entrée de modèle typée est un bus : l'entrée externe en donne les
% colonnes, élément après élément.
entreeBus = new_system('entreeBus');
entreeBus = add_block(entreeBus, 'inport', 'e', 'OutDataTypeStr', 'Bus: Capteurs');
entreeBus = add_block(entreeBus, 'busselector', 'bs', 'OutputSignals', 'vitesse');
entreeBus = add_block(entreeBus, 'outport', 'y');
entreeBus = add_line(entreeBus, 'e/1', 'bs/1');
entreeBus = add_line(entreeBus, 'bs/1', 'y/1');
r = sim(entreeBus, [0 1], simset('Solver', 'ode1'), [0 1 7 8; 1 1 7 8]);
assert(isequal(r.yout(end, :), [7 8]), 'une entree de modele qui est un bus');

% Un bus emboîté : un élément dont DataType vaut 'Bus: Capteurs'.
clear elementsBus
elementsBus(1) = Simulink.BusElement;
elementsBus(1).Name = 'mesures';
elementsBus(1).DataType = 'Bus: Capteurs';
elementsBus(2) = Simulink.BusElement;
elementsBus(2).Name = 'instant';
Etat = Simulink.Bus;
Etat.Elements = elementsBus;
assignin('base', 'Etat', Etat);
emboite = new_system('emboite');
emboite = add_block(emboite, 'constant', 'p', 'Value', 1);
emboite = add_block(emboite, 'constant', 'v', 'Value', [2; 3]);
emboite = add_block(emboite, 'clock', 't');
emboite = add_block(emboite, 'buscreator', 'capteurs', 'Inputs', '2', ...
                    'OutDataTypeStr', 'Bus: Capteurs');
emboite = add_block(emboite, 'buscreator', 'etat', 'Inputs', '2', 'OutDataTypeStr', 'Bus: Etat');
emboite = add_block(emboite, 'busselector', 'bs', 'OutputSignals', 'mesures.vitesse,instant');
emboite = add_block(emboite, 'outport', 'o1');
emboite = add_block(emboite, 'outport', 'o2');
emboite = add_line(emboite, 'p/1', 'capteurs/1');
emboite = add_line(emboite, 'v/1', 'capteurs/2');
emboite = add_line(emboite, 'capteurs/1', 'etat/1');
emboite = add_line(emboite, 't/1', 'etat/2');
emboite = add_line(emboite, 'etat/1', 'bs/1');
emboite = add_line(emboite, 'bs/1', 'o1/1');
emboite = add_line(emboite, 'bs/2', 'o2/1');
r = sim(emboite, 'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 1);
assert(isequal(r.yout(end, :), [2 3 1]), 'un bus emboite, lu par « mesures.vitesse »');
etatVide = Simulink.Bus.createMATLABStruct('Etat');
assert(isstruct(etatVide.mesures) && isequal(etatVide.mesures.vitesse, [0; 0]) && ...
       etatVide.instant == 0, 'createMATLABStruct descend dans un bus emboite');

% Simulink.Bus.createObject bâtit le type du bus d'un Bus Creator.
libre = new_system('libre');
libre = add_block(libre, 'constant', 'a', 'Value', [1 2; 3 4]);
libre = add_block(libre, 'constant', 'b', 'Value', 5);
libre = add_block(libre, 'buscreator', 'bc', 'Inputs', 'matrice,nombre');
libre = add_block(libre, 'terminator', 't');
libre = add_line(libre, 'a/1', 'bc/1');
libre = add_line(libre, 'b/1', 'bc/2');
libre = add_line(libre, 'bc/1', 't/1');
info = Simulink.Bus.createObject(libre, 'libre/bc');
cree = evalin('base', info.busName);
assert(strcmp(info.busName, 'slBus1') && isa(cree, 'Simulink.Bus') && ...
       isequal({cree.Elements.Name}, {'matrice', 'nombre'}) && ...
       isequal(cree.Elements(1).Dimensions, [2 2]) && cree.Elements(2).Dimensions == 1, ...
       'createObject : le type du bus d''un Bus Creator');
evalin('base', 'clear slBus1');

% Les erreurs.
assignin('base', 'pasUnBus', 3);
clear elementsBus
elementsBus(1) = Simulink.BusElement;
elementsBus(1).Name = 'boucle';
elementsBus(1).DataType = 'Bus: Boucle';
Boucle = Simulink.Bus;
Boucle.Elements = elementsBus;
assignin('base', 'Boucle', Boucle);
sousMauvais = new_system('sousMauvais');
sousMauvais = add_block(sousMauvais, 'inport', 'e', 'OutDataTypeStr', 'Bus: Capteurs');
sousMauvais = add_block(sousMauvais, 'terminator', 't');
sousMauvais = add_line(sousMauvais, 'e/1', 't/1');
nomsFaux = new_system('nomsFaux');
nomsFaux = add_block(nomsFaux, 'constant', 'p', 'Value', 1);
nomsFaux = add_block(nomsFaux, 'constant', 'v', 'Value', [1; 2]);
nomsFaux = add_block(nomsFaux, 'buscreator', 'bc', 'Inputs', 'x,y');
nomsFaux = add_block(nomsFaux, 'subsystem', 'sous', 'Model', sousMauvais);
nomsFaux = add_line(nomsFaux, 'p/1', 'bc/1');
nomsFaux = add_line(nomsFaux, 'v/1', 'bc/2');
nomsFaux = add_line(nomsFaux, 'bc/1', 'sous/1');
sortieSimple = new_system('sortieSimple');
sortieSimple = add_block(sortieSimple, 'constant', 'c', 'Value', 1);
sortieSimple = add_block(sortieSimple, 'outport', 'o', 'OutDataTypeStr', 'Bus: Capteurs');
sortieSimple = add_line(sortieSimple, 'c/1', 'o/1');
casErreurs = {
    @() sim(busCreeAvec('Bus: Inexistant', {1, 2})), 'Simulink:Bus:BusObjectNotFound', 'mauvais/bc'
    @() sim(busCreeAvec('Bus: pasUnBus', {1, 2})), 'Simulink:Bus:NotABusObject', 'pasUnBus'
    @() sim(busCreeAvec('Bus: Capteurs', {1, [1; 2], 3})), ...
        'Simulink:Bus:BusCreatorElementCountMismatch', 'mauvais/bc'
    @() sim(busCreeAvec('Bus: Capteurs', {1, 2})), 'Simulink:Bus:ElementDimensionsMismatch', ...
        'vitesse'
    @() sim(busCreeAvec('Bus: Etat', {1, 2})), 'Simulink:Bus:ElementNotBus', 'mesures'
    @() sim(busCreeAvec('Bus: Boucle', {1})), 'Simulink:Bus:BusRecursive', 'mauvais/bc'
    @() sim(nomsFaux), 'Simulink:Bus:ElementNamesMismatch', 'nomsFaux/sous/e'
    @() sim(sortieSimple), 'Simulink:Bus:SignalNotBus', 'sortieSimple/o'
    @() Simulink.Bus.createMATLABStruct('Inexistant'), 'Simulink:Bus:BusObjectNotFound', ...
        'Inexistant'
    @() Simulink.Bus.createObject(typeBus, 'typeBus/p'), ...
        'Simulink:Bus:CreateObjectNotBusCreator', 'typeBus/p'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('types de bus, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('types de bus : %d cas d''erreur verifies\n', size(casErreurs, 1));
evalin('base', 'clear Capteurs Etat Boucle pasUnBus');

%% --------------------------------- 29. S-fonctions de niveau 2 (M-S-Function)
% Une S-fonction de niveau 2 est une fonction MATLAB d'un argument, le
% bloc : sa fonction setup dit ses ports, ses paramètres, sa période, ses
% états, et enregistre ses méthodes — Outputs, Update, Derivatives,
% InitializeConditions, PostPropagationSetup. Le bloc « Level-2 MATLAB
% S-Function » la nomme par FunctionName, et lui passe Parameters.
dossierSFonctions = tempname();
mkdir(dossierSFonctions);
sourcesSFonctions = {
    'msfGain', {'function msfGain(block)', '    setup(block);', 'end', ...
        'function setup(block)', '    block.NumInputPorts = 1;', ...
        '    block.NumOutputPorts = 1;', '    block.SetPreCompInpPortInfoToDynamic;', ...
        '    block.SetPreCompOutPortInfoToDynamic;', ...
        '    block.InputPort(1).DirectFeedthrough = true;', '    block.NumDialogPrms = 1;', ...
        '    block.SampleTimes = [-1 0];', '    block.RegBlockMethod(''Outputs'', @Outputs);', ...
        'end', 'function Outputs(block)', ...
        '    block.OutputPort(1).Data = block.DialogPrm(1).Data * block.InputPort(1).Data;', ...
        'end'}
    'msfIntegre', {'function msfIntegre(block)', '    setup(block);', 'end', ...
        'function setup(block)', '    block.NumInputPorts = 1;', ...
        '    block.NumOutputPorts = 1;', '    block.SetPreCompPortInfoToDefaults;', ...
        '    block.NumDialogPrms = 1;', '    block.NumContStates = 1;', ...
        '    block.SampleTimes = [0 0];', ...
        '    block.RegBlockMethod(''InitializeConditions'', @Initialiser);', ...
        '    block.RegBlockMethod(''Outputs'', @Outputs);', ...
        '    block.RegBlockMethod(''Derivatives'', @Derivees);', 'end', ...
        'function Initialiser(block)', '    block.ContStates.Data = block.DialogPrm(1).Data;', ...
        'end', 'function Outputs(block)', ...
        '    block.OutputPort(1).Data = block.ContStates.Data;', 'end', ...
        'function Derivees(block)', '    block.Derivatives.Data = block.InputPort(1).Data;', ...
        'end'}
    'msfCompte', {'function msfCompte(block)', '    setup(block);', 'end', ...
        'function setup(block)', '    block.NumInputPorts = 1;', ...
        '    block.NumOutputPorts = 1;', '    block.SetPreCompPortInfoToDefaults;', ...
        '    block.SampleTimes = [0.5 0];', ...
        '    block.RegBlockMethod(''PostPropagationSetup'', @Travail);', ...
        '    block.RegBlockMethod(''InitializeConditions'', @Initialiser);', ...
        '    block.RegBlockMethod(''Outputs'', @Outputs);', ...
        '    block.RegBlockMethod(''Update'', @MiseAJour);', 'end', ...
        'function Travail(block)', '    block.NumDworks = 1;', ...
        '    block.Dwork(1).Name = ''total'';', '    block.Dwork(1).Dimensions = 1;', ...
        '    block.Dwork(1).UsedAsDiscState = true;', 'end', ...
        'function Initialiser(block)', '    block.Dwork(1).Data = 0;', 'end', ...
        'function Outputs(block)', '    block.OutputPort(1).Data = block.Dwork(1).Data;', 'end', ...
        'function MiseAJour(block)', ...
        '    block.Dwork(1).Data = block.Dwork(1).Data + block.InputPort(1).Data;', 'end'}
    'msfDeux', {'function msfDeux(block)', '    setup(block);', 'end', ...
        'function setup(block)', '    block.NumInputPorts = 2;', ...
        '    block.NumOutputPorts = 2;', '    block.SetPreCompInpPortInfoToDynamic;', ...
        '    block.SetPreCompOutPortInfoToDynamic;', ...
        '    block.InputPort(1).DirectFeedthrough = true;', ...
        '    block.InputPort(2).DirectFeedthrough = true;', ...
        '    block.RegBlockMethod(''Outputs'', @Outputs);', 'end', ...
        'function Outputs(block)', ...
        '    block.OutputPort(1).Data = block.InputPort(1).Data + block.InputPort(2).Data;', ...
        '    block.OutputPort(2).Data = block.InputPort(1).Data .* block.InputPort(2).Data;', ...
        'end'}
    'msfLarge', {'function msfLarge(block)', '    block.NumInputPorts = 1;', ...
        '    block.NumOutputPorts = 1;', '    block.SetPreCompPortInfoToDefaults;', ...
        '    block.InputPort(1).DirectFeedthrough = true;', ...
        '    block.RegBlockMethod(''Outputs'', @Outputs);', 'end', ...
        'function Outputs(block)', '    block.OutputPort(1).Data = [1 2];', 'end'}
    'msfPanne', {'function msfPanne(block)', '    block.NumInputPorts = 1;', ...
        '    block.NumOutputPorts = 1;', '    block.SetPreCompPortInfoToDefaults;', ...
        '    block.SampleTimes = [0 0];', ...
        '    block.RegBlockMethod(''Outputs'', @Outputs);', 'end', ...
        'function Outputs(block)', '    if block.CurrentTime > 0.25', ...
        '        error(''calcul impossible'');', '    end', ...
        '    block.OutputPort(1).Data = 0;', 'end'}
    'msfSetup', {'function msfSetup(block)', '    block.NumInputPorts = 1;', ...
        '    block.PortInexistant = 3;', 'end'}
    'msfFixe', {'function msfFixe(block)', '    block.NumInputPorts = 1;', ...
        '    block.NumOutputPorts = 1;', '    block.InputPort(1).Dimensions = 2;', ...
        '    block.OutputPort(1).Dimensions = 1;', ...
        '    block.RegBlockMethod(''Outputs'', @Outputs);', 'end', ...
        'function Outputs(block)', '    block.OutputPort(1).Data = 0;', 'end'}
    };
for kS = 1:size(sourcesSFonctions, 1)
    fid = fopen(fullfile(dossierSFonctions, [sourcesSFonctions{kS, 1} '.m']), 'w');
    fprintf(fid, '%s\n', sourcesSFonctions{kS, 2}{:});
    fclose(fid);
end
addpath(dossierSFonctions);

% Un gain, par son paramètre, sur un vecteur : les ports dynamiques
% prennent les dimensions du signal.
m = new_system('niveau2');
m = add_block(m, 'constant', 'u', 'Value', [1; 2; 3]);
m = add_block(m, 'msfunction', 'g', 'FunctionName', 'msfGain', 'Parameters', '4');
m = add_block(m, 'outport', 'y');
m = add_line(m, 'u/1', 'g/1');
m = add_line(m, 'g/1', 'y/1');
[ne, ns] = matlibre_sl_ports(m.blocs{2});
assert(ne == 1 && ns == 1, 'les ports d''une S-fonction de niveau 2 se lisent dans setup');
r = sim(m, 'StopTime', 1);
assert(isequal(r.yout(end, :), [4 8 12]), 'une S-fonction de niveau 2 : un gain sur un vecteur');
assert(strcmp(get_param(m, 'g', 'FunctionName'), 'msfGain'), 'FunctionName se relit');

% Un état continu : x' = u, x(0) = 1, sous tous les solveurs.
m = new_system('integre');
m = add_block(m, 'constant', 'u', 'Value', 2);
m = add_block(m, 'msfunction', 'i', 'FunctionName', 'msfIntegre', 'Parameters', '1');
m = add_block(m, 'outport', 'y');
m = add_line(m, 'u/1', 'i/1');
m = add_line(m, 'i/1', 'y/1');
for solveur = {'ode1', 'ode4', 'ode45', 'ode15s'}
    r = sim(m, 'Solver', solveur{1}, 'FixedStep', 0.1, 'StopTime', 1);
    assert(max(abs(r.yout - (1 + 2 * r.tout))) < 1e-9, ...
           ['un etat continu de niveau 2, sous ' solveur{1}]);
end
% refermée sur un gain, elle suit exp(-t) : sans transmission directe,
% elle rompt la boucle
m = add_block(m, 'gain', 'k', 'Gain', -1);
m = delete_line(m, 'u/1', 'i/1');
m = add_line(m, 'i/1', 'k/1');
m = add_line(m, 'k/1', 'i/1');
r = sim(m, 'Solver', 'ode45', 'StopTime', 2, 'RelTol', 1e-8, 'AbsTol', 1e-10);
assert(max(abs(r.yout - exp(-r.tout))) < 1e-6, 'une S-fonction de niveau 2 dans une boucle');

% Un état discret dans un vecteur de travail, mis à jour par Update à
% chaque période de 0,5 s.
m = new_system('compte');
m = add_block(m, 'constant', 'u', 'Value', 1);
m = add_block(m, 'msfunction', 'c', 'FunctionName', 'msfCompte');
m = add_block(m, 'outport', 'y');
m = add_line(m, 'u/1', 'c/1');
m = add_line(m, 'c/1', 'y/1');
r = sim(m, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.5, 'StopTime', 2);
assert(isequal(r.yout(:)', 0:4), 'Update et Dwork : un compteur');
% deux simulations de suite repartent chacune de zéro
r = sim(m, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.5, 'StopTime', 2);
assert(isequal(r.yout(:)', 0:4), 'chaque simulation recree le bloc');

% Deux entrées, deux sorties.
m = new_system('deux');
m = add_block(m, 'constant', 'a', 'Value', [1; 2]);
m = add_block(m, 'constant', 'b', 'Value', [3; 4]);
m = add_block(m, 'msfunction', 'f', 'FunctionName', 'msfDeux');
m = add_block(m, 'outport', 'somme');
m = add_block(m, 'outport', 'produit');
m = add_line(m, 'a/1', 'f/1');
m = add_line(m, 'b/1', 'f/2');
m = add_line(m, 'f/1', 'somme/1');
m = add_line(m, 'f/2', 'produit/1');
r = sim(m, 'StopTime', 1);
assert(isequal(r.yout(end, :), [4 6 3 8]), 'deux entrees, deux sorties');

% Les erreurs, chacune nommant la S-fonction et le bloc.
casErreurs = {
    @() sim(niveau2Avec('', '')), 'Simulink:blocks:SFunctionNotFound', 'mauvais/s'
    @() sim(niveau2Avec('msfInexistante', '')), 'Simulink:blocks:SFunctionNotFound', ...
        'msfInexistante'
    @() sim(niveau2Avec('msfGain', '')), 'Simulink:blocks:SFunctionParameterCount', 'mauvais/s'
    @() sim(niveau2Avec('msfGain', '1, 2')), 'Simulink:blocks:SFunctionParameterCount', ...
        'attend 1'
    @() sim(niveau2Avec('msfLarge', '')), 'Simulink:blocks:SFunctionOutputDimensions', ...
        'mauvais/s'
    @() sim(niveau2Avec('msfPanne', ''), 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 1), ...
        'Simulink:blocks:SFunctionError', 'Outputs a t = 0.3'
    @() sim(niveau2Avec('msfSetup', '')), 'Simulink:blocks:SFunctionSetupError', 'mauvais/s'
    @() sim(niveau2Avec('msfFixe', '')), 'Simulink:blocks:SFunctionInputDimensions', ...
        'mauvais/s'
    @() sim(niveau2Avec('msfGain', 'inconnueDuTout')), 'Simulink:blocks:SFunctionParameters', ...
        'inconnueDuTout'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('S-fonctions de niveau 2, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('S-fonctions de niveau 2 : %d cas d''erreur verifies\n', size(casErreurs, 1));
rmpath(dossierSFonctions);
rmdir(dossierSFonctions, 's');

%% ---------------------------------------------- 30. Types de données propagés
% Chaque signal a un type — double, single, int8 à uint32, boolean — que
% Simulink propage de bloc en bloc : une constante a celui de sa valeur
% ou de son OutDataTypeStr, un comparateur rend un booléen, un bloc de
% calcul hérite du type de ses entrées et y ramène son résultat —
% arrondi selon RndMeth, replié au-delà des bornes, ou saturé si
% SaturateOnIntegerOverflow vaut 'on'.
cas = {
    % bloc      a            b            parametres                              attendu   classe
    'sum',      int8(100),   int8(100),   {},                                     -56,      'int8'
    'sum',      int8(100),   int8(100),   {'SaturateOnIntegerOverflow', 'on'},    127,      'int8'
    'sum',      uint8(5),    uint8(10),   {'Signs', '+-'},                        251,      'uint8'
    'sum',      uint8(5),    uint8(10),   {'Signs', '+-', 'SaturateOnIntegerOverflow', 'on'}, 0, 'uint8'
    'product',  int16(7),    int16(2),    {'Inputs', '*/'},                       3,        'int16'
    'product',  int16(7),    int16(2),    {'Inputs', '*/', 'RndMeth', 'Nearest'}, 4,        'int16'
    'product',  int16(-7),   int16(2),    {'Inputs', '*/', 'RndMeth', 'Floor'},   -4,       'int16'
    'product',  int16(300),  int16(300),  {},                                     24464,    'int16'
    'sum',      single(1),   single(1e-8), {},                                    1,        'single'
    'sum',      int8(3),     2.5,         {},                                     5.5,      'double'
    'relational', 3,         4,           {'Operator', '<'},                      1,        'logical'
    'switch',   int8(-5),    int8(1),     {},                                     -5,       'int8'
    };
for kT = 1:size(cas, 1)
    m = typesDeux(cas{kT, 1}, cas{kT, 2}, cas{kT, 3}, cas{kT, 4});
    if strcmp(cas{kT, 1}, 'switch')
        m = add_block(m, 'constant', 'c', 'Value', int8(9));
        m = add_line(m, 'c/1', 'op/3');
    end
    r = sim(m, 'StopTime', 1);
    assert(strcmp(class(r.yout), cas{kT, 6}) && double(r.yout(end)) == cas{kT, 5}, ...
           sprintf('types, cas %d (%s) : %s %g attendu, %s %g rendu', kT, cas{kT, 1}, ...
                   cas{kT, 6}, cas{kT, 5}, class(r.yout), double(r.yout(end))));
end
fprintf('types de donnees : %d cas de calcul verifies\n', size(cas, 1));

% Le gain d'un entier, arrondi par défaut vers le bas.
m = new_system('gainEntier');
m = add_block(m, 'constant', 'a', 'Value', int8(-3));
m = add_block(m, 'gain', 'g', 'Gain', 0.5);
m = add_block(m, 'gain', 'z', 'Gain', 0.5, 'RndMeth', 'Zero');
m = add_block(m, 'outport', 'o1');
m = add_block(m, 'outport', 'o2');
m = add_line(m, 'a/1', 'g/1');
m = add_line(m, 'a/1', 'z/1');
m = add_line(m, 'g/1', 'o1/1');
m = add_line(m, 'z/1', 'o2/1');
r = sim(m, 'StopTime', 1);
assert(isequal(r.yout(end, :), int8([-2 -1])), 'gain d''un int8 : Floor, puis Zero');

% Le type va jusqu'à l'espace de travail : To Workspace range la classe du
% signal ; une constante typée par OutDataTypeStr, une Data Type
% Conversion, une MATLAB Function donnent le leur.
m = new_system('jusquau');
m = add_block(m, 'constant', 'c', 'Value', 200, 'OutDataTypeStr', 'uint8');
m = add_block(m, 'datatypeconversion', 'd', 'OutDataTypeStr', 'int16');
m = add_block(m, 'matlabfunction', 'f', 'Script', sprintf('function y = f(u)\ny = single(u) / 3;'));
m = add_block(m, 'toworkspace', 't1', 'VariableName', 'enUint8', 'SaveFormat', 'Array');
m = add_block(m, 'toworkspace', 't2', 'VariableName', 'enInt16', 'SaveFormat', 'Array');
m = add_block(m, 'toworkspace', 't3', 'VariableName', 'enSingle', 'SaveFormat', 'Array');
m = add_line(m, 'c/1', 'd/1');
m = add_line(m, 'c/1', 't1/1');
m = add_line(m, 'd/1', 't2/1');
m = add_line(m, 'd/1', 'f/1');
m = add_line(m, 'f/1', 't3/1');
sim(m, 'StopTime', 1);
assert(strcmp(class(enUint8), 'uint8') && enUint8(end) == 200 && ...
       strcmp(class(enInt16), 'int16') && enInt16(end) == 200 && ...
       strcmp(class(enSingle), 'single') && enSingle(end) == single(200) / 3, ...
       'To Workspace range la classe du signal');
clear enUint8 enInt16 enSingle

% Les erreurs de type, comme Simulink les donne.
fusion = new_system('fusion');
fusion = add_block(fusion, 'constant', 'a', 'Value', int8(1));
fusion = add_block(fusion, 'constant', 'b', 'Value', 2);
fusion = add_block(fusion, 'merge', 'm');
fusion = add_line(fusion, 'a/1', 'm/1');
fusion = add_line(fusion, 'b/1', 'm/2');
sortieTypee = new_system('sortieTypee');
sortieTypee = add_block(sortieTypee, 'constant', 'c', 'Value', 1);
sortieTypee = add_block(sortieTypee, 'outport', 'o', 'OutDataTypeStr', 'int16');
sortieTypee = add_line(sortieTypee, 'c/1', 'o/1');
casErreurs = {
    @() sim(add_line(add_block(add_block(new_system('entier'), 'constant', 'c', 'Value', ...
        int8(1)), 'integrator', 'i'), 'c/1', 'i/1')), ...
        'Simulink:DataType:InputPortDataTypeMismatch', 'entier/i'
    @() sim(add_line(add_block(add_block(new_system('logique'), 'constant', 'c', 'Value', ...
        true), 'transferfcn', 'h'), 'c/1', 'h/1')), ...
        'Simulink:DataType:InputPortDataTypeMismatch', 'boolean'
    @() sim(add_line(add_block(add_block(new_system('trig'), 'constant', 'c', 'Value', ...
        uint8(1)), 'trigonometry', 't'), 'c/1', 't/1')), ...
        'Simulink:DataType:InputPortDataTypeMismatch', 'trig/t'
    @() sim(fusion), 'Simulink:DataType:MergeDataTypeMismatch', 'fusion/m'
    @() sim(sortieTypee), 'Simulink:DataType:InputPortDataTypeMismatch', 'sortieTypee/o'
    @() sim(add_block(new_system('deborde'), 'constant', 'c', 'Value', 300, 'OutDataTypeStr', ...
        'int8')), 'Simulink:Parameters:ParamOverflow', 'deborde/c'
    @() sim(add_block(new_system('inconnu'), 'constant', 'c', 'OutDataTypeStr', 'int7')), ...
        'Simulink:DataType:UnknownDataType', 'int7'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('types de donnees, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('types de donnees : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------ 31. Stateflow : jonctions, fonctions, tables de verite
% Une transition vers une jonction n'est prise que si un chemin de gardes
% vraies mène jusqu'à un état ; un segment dont la suite échoue est
% abandonné au profit du suivant. Les actions de condition s'exécutent à
% mesure que les gardes sont vraies, celles des transitions une fois le
% chemin choisi, segment après segment.
m = sfchart('retour');
m = sfstate(m, 'A');
m = sfstate(m, 'B');
m = sfstate(m, 'C');
m = sfjunction(m, 'j1');
m = sfjunction(m, 'j2');
m = sftransition(m, 'A', 'j1', '[go == 1]{essais = essais + 1;}', 'trace = [trace 1];');
m = sftransition(m, 'j1', 'j2', '[x > 5]', 'trace = [trace 2];');
m = sftransition(m, 'j2', 'B', '[y > 5]', 'trace = [trace 3];');
m = sftransition(m, 'j1', 'C', '', 'trace = [trace 4];');
depart = struct('go', 1, 'x', 10, 'y', 0, 'essais', 0, 'trace', []);
[h, c] = sfrun(m, 0, depart);
assert(isequal(h, {'C'}) && isequal(c.trace, [1 4]) && c.essais == 1, ...
       'jonctions : le chemin vers B echoue, celui vers C est pris');
depart.y = 10;
[h, c] = sfrun(m, 0, depart);
assert(isequal(h, {'B'}) && isequal(c.trace, [1 2 3]), ...
       'jonctions : le chemin complet, ses actions dans l''ordre');
depart.go = 0;
[h, c] = sfrun(m, 0, depart);
assert(isequal(h, {'A'}) && isempty(c.trace) && c.essais == 0, ...
       'jonctions : la premiere garde fausse, rien ne bouge');
% sans chemin par défaut : on reste, mais l'action de condition a eu lieu
m = sfchart('impasse');
m = sfstate(m, 'A');
m = sfstate(m, 'B');
m = sfjunction(m, 'j');
m = sftransition(m, 'A', 'j', '[true]{vus = vus + 1;}');
m = sftransition(m, 'j', 'B', '[x > 100]');
[h, c] = sfrun(m, [0 0 0], struct('x', 1, 'vus', 0));
assert(isequal(h, {'A', 'A', 'A'}) && c.vus == 3, ...
       'une impasse : l''etat reste, l''action de condition s''est faite a chaque essai');

% Une fonction de la machine, appelée par les textes.
m = sfchart('chauffe');
m = sffunction(m, 'consigne', @(heure) 18 + 2 * (heure >= 8 && heure < 22));
m = sfstate(m, 'regle', 'du: c = consigne(u);');
m = sfstate(m, 'alarme');
m = sftransition(m, 'regle', 'alarme', '[consigne(u) > 25]');
[h, c] = sfrun(m, [7 9 12], struct('c', 0));
assert(c.c == 20 && all(strcmp(h, 'regle')), 'une fonction de la machine');

% Une table de vérité : la première décision qui s'accorde.
m = sfchart('signe');
m = sftruthtable(m, 'classe', {'x'}, {'k'}, {'x > 0', 'x < 0'}, ['TF-'; 'FT-'], ...
                 {'k = 1;', 'k = -1;', 'k = 0;'});
m = sfstate(m, 'mesure', 'du: s = classe(u);');
valeurs = [3 -2 0];
for kV = 1:numel(valeurs)
    [~, c] = sfrun(m, [0 valeurs(kV)]);
    assert(c.s == sign(valeurs(kV)), sprintf('table de verite sur %g', valeurs(kV)));
end
% dans un bloc Chart, sur un signal
schema = new_system('tableVerite');
schema = add_block(schema, 'sine', 'u', 'Amplitude', 2);
schema = add_block(schema, 'chart', 'c', 'Chart', m, 'Inputs', 1, 'Outputs', {'s'}, ...
                   'InitialContext', struct('s', 0), 'SampleTime', 0.1);
schema = add_line(schema, 'u/1', 'c/1');
r = sim(schema, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 3);
iMesure = r.temps > 0.05;
assert(all(r.signaux.c(iMesure) == sign(2 * sin(r.temps(iMesure) - 0.1)) | ...
           r.signaux.c(iMesure) == sign(2 * sin(r.temps(iMesure)))), ...
       'une table de verite dans un bloc Chart');

% Les erreurs.
boucle = sfchart('boucle');
boucle = sfstate(boucle, 'A');
boucle = sfjunction(boucle, 'j1');
boucle = sfjunction(boucle, 'j2');
boucle = sftransition(boucle, 'A', 'j1', '');
boucle = sftransition(boucle, 'j1', 'j2', '');
boucle = sftransition(boucle, 'j2', 'j1', '');
table = sftruthtable(sfchart('t'), 'f', {'x'}, {'y'}, {'x > 0'}, 'TF', {'y = 1;', 'y = 2;'});
casErreurs = {
    @() sfrun(boucle, [0 0]), 'Stateflow:BoucleDeJonctions', 'bouclent'
    @() sfjunction(sfjunction(sfchart('x'), 'j'), 'j'), 'Stateflow:JonctionDouble', 'j'
    @() sfstate(sfjunction(sfchart('x'), 'j'), 'j'), 'Stateflow:EtatDouble', 'j'
    @() sffunction(sfchart('x'), 'f', 3), 'Stateflow:FonctionInvalide', 'poignee'
    @() sftruthtable(sfchart('x'), 't', {'x'}, {'y'}, {'x > 0', 'x < 0'}, 'TF', {'y=1;', 'y=2;'}), ...
        'Stateflow:TableDeVeriteInvalide', 'une par condition'
    @() sftruthtable(sfchart('x'), 't', {'x'}, {'y'}, {'x > 0'}, 'TX', {'y=1;', 'y=2;'}), ...
        'Stateflow:TableDeVeriteInvalide', 'peu importe'
    @() table.fonctions.f(1, 2), 'Stateflow:TableDeVeriteArguments', 'prend 1'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('jonctions et tables, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('jonctions et tables : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------------------ 32. timeseries, Dataset et formats du journal
% Une timeseries porte des valeurs et leurs instants. Un From Workspace la
% lit, un To Workspace au format 'Timeseries' en rend une, SIM l'accepte
% comme entrée externe ; SaveFormat donne à yout la forme d'une matrice,
% d'une structure, ou d'un Simulink.SimulationData.Dataset.
serie = timeseries([0; 2; 4], [0 1 2], 'Name', 'vitesse');
assert(strcmp(class(serie), 'timeseries') && serie.Length == 3 && ...
       strcmp(serie.Name, 'vitesse') && serie.TimeInfo.Increment == 1 && ...
       serie.TimeInfo.End == 2, 'une timeseries et ses informations de temps');
milieu = resample(serie, [0.5 1.5]);
assert(isequal(milieu.Data, [1; 3]) && isequal(milieu.Time, [0.5; 1.5]), 'resample interpole');
assert(isequal(getdatasamples(serie, 2), 2), 'getdatasamples');
matricielle = timeseries(reshape(1:12, 2, 2, 3), [0 1 2]);
assert(~matricielle.IsTimeFirst && isequal(getdatasamples(matricielle, 2), [5 7; 6 8]), ...
       'des echantillons matriciels, l''instant en dernier');
assert(isequal(timeseries([7 8 9]).Time, [0; 1; 2]), 'sans instants : 0, 1, 2...');

% Le bloc From Workspace lit une timeseries ; To Workspace en rend une.
assignin('base', 'vitesseLue', serie);
m = new_system('lecture');
m = add_block(m, 'fromworkspace', 'f', 'VariableName', 'vitesseLue');
m = add_block(m, 'toworkspace', 'tw', 'VariableName', 'vitesseEcrite', 'SaveFormat', 'Timeseries');
m = add_line(m, 'f/1', 'tw/1');
sim(m, 'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 2);
assert(isa(vitesseEcrite, 'timeseries') && isequal(vitesseEcrite.Data(:)', 0:4) && ...
       isequal(vitesseEcrite.Time(:)', 0:0.5:2) && strcmp(vitesseEcrite.Name, 'vitesseEcrite'), ...
       'From Workspace lit une timeseries, To Workspace en ecrit une');
evalin('base', 'clear vitesseLue');
clear vitesseEcrite

% Une timeseries comme entrée externe du modèle.
m = new_system('externe');
m = add_block(m, 'inport', 'e');
m = add_block(m, 'outport', 'o');
m = add_line(m, 'e/1', 'o/1');
r = sim(m, [0 2], simset('Solver', 'ode1', 'FixedStep', 0.5), serie);
assert(isequal(r.yout(:)', 0:4), 'une timeseries en entree externe');

% SaveFormat : Dataset, StructureWithTime, Structure.
m = new_system('journalDs');
m = add_block(m, 'sine', 's');
m = add_block(m, 'gain', 'g', 'Gain', 2);
m = add_block(m, 'outport', 'y1');
m = add_block(m, 'outport', 'y2');
m = add_line(m, 's/1', 'y1/1');
m = add_line(m, 's/1', 'g/1');
m = add_line(m, 'g/1', 'y2/1');
r = sim(m, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 1, 'SaveFormat', 'Dataset');
assert(isa(r.yout, 'Simulink.SimulationData.Dataset') && r.yout.numElements == 2, ...
       'SaveFormat Dataset : un element par sortie');
deuxieme = r.yout{2};
valeurs = deuxieme.Values.Data;
assert(isa(deuxieme, 'Simulink.SimulationData.Signal') && ...
       strcmp(deuxieme.BlockPath, 'journalDs/y2') && isa(deuxieme.Values, 'timeseries') && ...
       abs(valeurs(end) - 2 * sin(1)) < 1e-12, 'un Signal, sa timeseries');
assert(strcmp(get(r.yout, 'y1').Name, 'y1') && isequal(getElementNames(r.yout), {'y1'; 'y2'}), ...
       'un element par son nom');
r = sim(m, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 1, 'SaveFormat', 'StructureWithTime');
assert(numel(r.yout.time) == 11 && numel(r.yout.signals) == 2 && ...
       strcmp(r.yout.signals(2).blockName, 'journalDs/y2'), 'SaveFormat StructureWithTime');
r = sim(m, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 1, 'SaveFormat', 'Structure');
assert(isempty(r.yout.time) && numel(r.yout.signals) == 2, 'SaveFormat Structure');

deuxEntrees = new_system('deux');
deuxEntrees = add_block(deuxEntrees, 'inport', 'a');
deuxEntrees = add_block(deuxEntrees, 'inport', 'b', 'Port', 2);
deuxEntrees = add_block(deuxEntrees, 'outport', 'o1');
deuxEntrees = add_block(deuxEntrees, 'outport', 'o2');
deuxEntrees = add_line(deuxEntrees, 'a/1', 'o1/1');
deuxEntrees = add_line(deuxEntrees, 'b/1', 'o2/1');
casErreurs = {
    @() timeseries([1 2 3], [0 2 1]), 'MATLAB:timeseries:TimeNotMonotonic', 'croissants'
    @() timeseries([1; 2; 3], [0 1]), 'MATLAB:timeseries:SizeMismatch', '2 instant'
    @() sim(m, 'SaveFormat', 'Tableau'), 'Simulink:Config:InvalidValue', 'Dataset'
    @() get(Simulink.SimulationData.Dataset, 'absent'), ...
        'Simulink:SimulationData:DatasetElementNotFound', 'absent'
    @() get(Simulink.SimulationData.Dataset, 3), ...
        'Simulink:SimulationData:DatasetIndexOutOfRange', '0 element'
    @() sim(deuxEntrees, [0 1], [], serie), 'Simulink:SimInput:NumPortsMismatch', 'timeseries'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('timeseries et journal, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('timeseries et journal : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------- 33. Simulink.Parameter, Simulink.Signal, SimulationInput et parsim
% Un Simulink.Parameter se lit dans les paramètres des blocs comme une
% variable, converti dans son DataType et borné par Min et Max ; un
% Simulink.Signal définit une mémoire partagée globale ; un
% SimulationInput change variables, paramètres de blocs et réglages le
% temps d'une simulation, et PARSIM en fait toute une série.
Kg = Simulink.Parameter(3);
assert(isequal(Kg.Dimensions, [1 1]) && strcmp(Kg.Complexity, 'real') && ...
       strcmp(Kg.DataType, 'auto') && isa(Kg.CoderInfo, 'Simulink.CoderInfo') && ...
       strcmp(Kg.CoderInfo.StorageClass, 'Auto'), 'un Simulink.Parameter et ses proprietes');
autreNom = Kg;
autreNom.Value = 4;
assert(Kg.Value == 4, 'un objet poignee : deux noms, un meme parametre');
copie = copy(Kg);
copie.Value = 9;
assert(Kg.Value == 4 && copie.Value == 9, 'copy en fait un autre');
affiche = evalc('disp(Kg)');
assert(~isempty(strfind(affiche, 'Parameter with properties')) && ...
       ~isempty(strfind(affiche, 'DataType: ''auto''')), 'l''affichage d''un parametre');
Kg.Value = 3;

m = new_system('parametre');
m = add_block(m, 'constant', 'c', 'Value', 1);
m = add_block(m, 'gain', 'g', 'Gain', '2*Kg');
m = add_block(m, 'outport', 'y');
m = add_line(add_line(m, 'c', 'g'), 'g', 'y');
r = sim(m, 1);
assert(r.yout(end) == 6, 'un gain qui lit 2*Kg, Kg un Simulink.Parameter');
Kg.Value = 5;
r = sim(m, 1);
assert(r.yout(end) == 10, 'la valeur du parametre au moment de simuler');

% Le DataType convertit : une constante réglée sur le paramètre sort un
% signal de ce type ; une expression 'int8(5)' garde aussi sa classe.
Pt = Simulink.Parameter(7);
Pt.DataType = 'int16';
t = new_system('typeParametre');
t = add_block(t, 'constant', 'c', 'Value', 'Pt');
t = add_block(t, 'outport', 'y');
t = add_line(t, 'c', 'y');
r = sim(t, 1);
assert(isa(r.yout, 'int16') && r.yout(end) == 7, 'DataType int16 : un signal int16');
r = sim(set_param(t, 'c', 'Value', 'int8(5)'), 1);
assert(isa(r.yout, 'int8') && r.yout(end) == 5, 'une expression int8(5) donne un signal int8');
Pt.DataType = 'boolean';
r = sim(t, 1);
assert(islogical(r.yout) && r.yout(end), 'DataType boolean');
r = sim(set_param(t, 'c', 'Value', Simulink.Parameter(2.5)), 1);
assert(r.yout(end) == 2.5, 'un Simulink.Parameter donne tel quel au bloc');

% Un masque lit le paramètre comme le reste du modèle.
dedans = new_system('dedans');
dedans = add_block(dedans, 'inport', 'e');
dedans = add_block(dedans, 'gain', 'k', 'Gain', 'G');
dedans = add_block(dedans, 'outport', 'sortie');
dedans = add_line(add_line(dedans, 'e', 'k'), 'k', 'sortie');
mm = new_system('masqueParametre');
mm = add_block(mm, 'constant', 'c', 'Value', 1);
mm = add_block(mm, 'subsystem', 'sous', 'Model', dedans, 'Mask', 'on', ...
               'MaskVariables', 'G=@1;', 'MaskValueString', 'Kg');
mm = add_block(mm, 'outport', 'y');
mm = add_line(add_line(mm, 'c', 'sous'), 'sous', 'y');
r = sim(mm, 1);
assert(r.yout(end) == 5, 'une variable de masque qui lit un Simulink.Parameter');

% Un Simulink.Signal définit une mémoire globale, sans Data Store Memory ;
% un Data Store Memory du même nom l'emporte.
Memoire = Simulink.Signal;
Memoire.InitialValue = '5';
g = new_system('globale');
g = add_block(g, 'datastoreread', 'lire', 'DataStoreName', 'Memoire');
g = add_block(g, 'gain', 'k', 'Gain', 2);
g = add_block(g, 'datastorewrite', 'ecrire', 'DataStoreName', 'Memoire');
g = add_block(g, 'outport', 'y');
g = add_line(add_line(g, 'lire', 'k'), 'k', 'ecrire');
g = add_line(g, 'lire', 'y');
g = set_param(g, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 3);
r = sim(g);
assert(isequal(r.yout(:)', [5 10 20 40]), 'une memoire globale definie par un Simulink.Signal');
Memoire.Dimensions = 2;
r = sim(g);
assert(isequal(size(r.yout), [4 2]) && isequal(r.yout(1, :), [5 5]), ...
       'Dimensions etend la valeur initiale du signal');
r = sim(add_block(g, 'datastorememory', 'locale', 'DataStoreName', 'Memoire', 'InitialValue', 1));
assert(isequal(r.yout(:)', [1 2 4 8]), 'un Data Store Memory du modele l''emporte sur l''objet');

% L'état final d'une simulation, repris comme état initial de la suivante.
h = new_system('reprise');
h = add_block(h, 'constant', 'un', 'Value', 1);
h = add_block(h, 'integrator', 'x');
h = add_block(h, 'outport', 'y');
h = add_line(add_line(h, 'un', 'x'), 'x', 'y');
h = set_param(h, 'StopTime', 1, 'Solver', 'ode4', 'SaveFinalState', 'on');
r1 = sim(h);
assert(abs(r1.xFinal - 1) < 1e-9, 'SaveFinalState : l''etat final dans xFinal');
r2 = sim(set_param(h, 'LoadInitialState', 'on', 'InitialState', r1.xFinal));
assert(abs(r2.yout(1) - 1) < 1e-9 && abs(r2.xFinal - 2) < 1e-9, ...
       'LoadInitialState reprend la simulation la ou elle s''etait arretee');
xDepart = 10;
r3 = sim(set_param(h, 'LoadInitialState', 'on', 'InitialState', 'xDepart', ...
                   'FinalStateName', 'etatFin'));
assert(r3.yout(1) == 10 && abs(r3.etatFin - 11) < 1e-9, ...
       'InitialState donne par une expression, FinalStateName renomme le champ');

% Un SimulationInput : variables, paramètres de blocs et réglages le temps
% d'une simulation ; l'espace de base et le modèle n'en gardent rien.
entree = new_system('entree');
entree = add_block(entree, 'constant', 'c', 'Value', 'Kvar');
entree = add_block(entree, 'gain', 'g', 'Gain', 2);
entree = add_block(entree, 'outport', 'y');
entree = add_line(add_line(entree, 'c', 'g'), 'g', 'y');
in = Simulink.SimulationInput('entree');
in = in.setVariable('Kvar', 5);
in = in.setBlockParameter('entree/g', 'Gain', '3');
in = in.setModelParameter('StopTime', '1');
affiche = evalc('disp(in)');
assert(~isempty(strfind(affiche, 'SimulationInput with properties')) && ...
       ~isempty(strfind(affiche, 'Variables: [1x1 Simulink.Simulation.Variable]')), ...
       'l''affichage d''un SimulationInput');
out = sim(in);
assert(out.yout(end) == 15 && out.tout(end) == 1 && isempty(out.ErrorMessage), 'sim(in)');
assert(~exist('Kvar', 'var') && isequal(get_param(entree, 'g', 'Gain'), 2), ...
       'ni la variable ni le parametre de bloc ne restent');
Kvar = 1;
out = sim(in);
assert(out.yout(end) == 15 && Kvar == 1, 'une variable qui existait retrouve sa valeur');
meta = out.SimulationMetadata;
assert(strcmp(meta.ModelInfo.ModelName, 'entree') && meta.ModelInfo.StopTime == 1 && ...
       strcmp(meta.ExecutionInfo.StopEvent, 'ReachedStopTime'), 'SimulationMetadata');
assert(in.getVariable('Kvar') == 5 && isequal(in.getBlockParameter('entree/g', 'Gain'), '3') && ...
       isequal(in.getModelParameter('stoptime'), '1'), 'relire ce qui est pose');
assert(isempty(in.removeVariable('Kvar').Variables), 'removeVariable');
in = in.setVariable('Kvar', 6);
assert(numel(in.Variables) == 1 && in.getVariable('Kvar') == 6, 'poser deux fois remplace');
clear Kvar

% Un tableau de SimulationInput : les simulations se font l'une après
% l'autre ; celle qui échoue range son message, les autres aboutissent.
lot(1:3) = Simulink.SimulationInput('entree');
for kL = 1:3
    lot(kL) = lot(kL).setVariable('Kvar', kL);
    lot(kL) = lot(kL).setModelParameter('StopTime', '1');
end
lot(2) = lot(2).setBlockParameter('entree/g', 'Gain', 'variableAbsente');
out = sim(lot);
assert(isequal(size(out), [1 3]) && out(1).yout(end) == 2 && out(3).yout(end) == 6 && ...
       isempty(out(1).ErrorMessage), 'sim d''un tableau de SimulationInput');
assert(~isempty(strfind(out(2).ErrorMessage, 'variableAbsente')) && isempty(out(2).yout) && ...
       strcmp(out(2).SimulationMetadata.ExecutionInfo.StopEvent, 'DiagnosticError'), ...
       'la simulation en erreur range son message');
out = parsim(lot, 'ShowProgress', 'off', 'TransferBaseWorkspaceVariables', 'on');
assert(out(3).yout(end) == 6 && ~isempty(out(2).ErrorMessage), 'parsim');
journal = evalc('parsim(lot);');
assert(~isempty(strfind(journal, 'Simulation 2 sur 3 en erreur')) && ...
       ~isempty(strfind(journal, '3 simulation(s) faite(s), 1 en erreur')), ...
       'parsim dit ou il en est');
out = parsim(lot, 'ShowProgress', 'off', 'StopOnError', 'on');
assert(isempty(out(1).ErrorMessage) && ~isempty(strfind(out(3).ErrorMessage, 'StopOnError')), ...
       'StopOnError : les simulations suivantes ne se font pas');
assignin('base', 'preparations', 0);
out = parsim(lot([1 3]), 'ShowProgress', 'off', ...
             'SetupFcn', @() evalin('base', 'preparations = preparations + 1;'), ...
             'CleanupFcn', @() evalin('base', 'preparations = preparations + 10;'));
assert(preparations == 11 && numel(out) == 2, 'SetupFcn et CleanupFcn, une fois chacune');
clear preparations
o = sim(lot(2), 'CaptureErrors', 'on');
assert(~isempty(strfind(o.ErrorMessage, 'variableAbsente')), 'CaptureErrors');

% PreSimFcn change le SimulationInput ; PostSimFcn remplace le résultat.
avant = lot(1).setPreSimFcn(@(x) x.setVariable('Kvar', 100));
avant = avant.setPostSimFcn(@(o) struct('fin', o.yout(end)));
o = sim(avant);
assert(o.fin == 200 && isequal(fieldnames(o)', {'fin', 'ErrorMessage', 'SimulationMetadata'}), ...
       'PreSimFcn et PostSimFcn');

% L'état initial et les entrées externes d'un SimulationInput.
in = Simulink.SimulationInput(h);
in = in.setInitialState(5);
o = sim(in);
assert(abs(o.yout(1) - 5) < 1e-12 && abs(o.xFinal - 6) < 1e-9, 'setInitialState');
ext = new_system('ext');
ext = add_block(ext, 'inport', 'e');
ext = add_block(ext, 'outport', 'o');
ext = add_line(ext, 'e', 'o');
in = Simulink.SimulationInput(ext);
in = in.setExternalInput([(0:0.5:1)', (0:2)']);
in = in.setModelParameter('StopTime', '1', 'Solver', 'ode1', 'FixedStep', '0.5');
o = sim(in);
assert(isequal(o.yout(:)', 0:2), 'setExternalInput');

Hors = Simulink.Parameter(7);
Hors.Max = 5;
Debord = Simulink.Parameter(300);
Debord.DataType = 'int8';
Fixe = Simulink.Parameter(1.03);
Fixe.DataType = 'fixdt(1,16,4)';
r = sim(set_param(t, 'c', 'Value', 'Fixe'), 1);
assert(isfi(r.yout) && r.yout.FractionLength == 4 && double(r.yout(end)) == 1, ...
       'un Simulink.Parameter fixdt range sa valeur sur la grille de son type');
Alias = Simulink.Parameter(1);
Alias.DataType = 'MonAlias';
BusFaux = Simulink.Parameter(1);
BusFaux.DataType = 'Bus: Capteurs';
Mauvaise = Simulink.Signal;
Mauvaise.InitialValue = '[1 2 3]';
Mauvaise.Dimensions = 2;
gMauvaise = set_param(set_param(g, 'lire', 'DataStoreName', 'Mauvaise'), 'ecrire', ...
                      'DataStoreName', 'Mauvaise');
un = Simulink.SimulationInput('entree');
casErreurs = {
    @() poserPropriete(Simulink.Parameter, 'DataType', '12x'), ...
        'Simulink:Data:InvalidDataType', '12x'
    @() poserPropriete(Simulink.Parameter, 'Min', 'a'), 'Simulink:Data:InvalidMinMax', 'Min'
    @() poserPropriete(Simulink.Parameter, 'Value', {1}), ...
        'Simulink:Data:InvalidParameterValue', 'cell'
    @() poserPropriete(Simulink.Signal, 'Dimensions', 0), ...
        'Simulink:Data:InvalidDimensions', 'Dimensions'
    @() poserPropriete(Simulink.Signal, 'Complexity', 'imaginaire'), ...
        'Simulink:Data:InvalidValue', 'Complexity'
    @() sim(set_param(t, 'c', 'Value', 'Hors'), 1), 'Simulink:Data:ParameterOutOfRange', ...
        'typeParametre/c'
    @() sim(set_param(t, 'c', 'Value', 'Debord'), 1), 'Simulink:Data:ParameterOverflow', ...
        '-128 a 127'
    @() sim(set_param(t, 'c', 'Value', 'Alias'), 1), 'Simulink:DataType:UnknownDataType', ...
        'MonAlias'
    @() sim(set_param(t, 'c', 'Value', 'BusFaux'), 1), ...
        'Simulink:Data:ParameterTypeMismatch', 'structure'
    @() sim(gMauvaise), 'Simulink:DataStores:InvalidInitialValue', '3 element'
    @() sim(set_param(h, 'LoadInitialState', 'on', 'InitialState', [1 2])), ...
        'Simulink:SimInput:InitialStateDimensions', '2 valeur'
    @() set_param(h, 'FinalStateName', '1x'), 'Simulink:Config:InvalidValue', 'FinalStateName'
    @() Simulink.SimulationInput(''), 'Simulink:Simulation:InvalidModelName', 'NEW_SYSTEM'
    @() un.setVariable('1a', 3), 'Simulink:Simulation:InvalidVariableName', 'nom'
    @() un.setBlockParameter('entree/g', 'Gain'), ...
        'Simulink:Simulation:InvalidNumberOfArguments', 'triplets'
    @() un.setModelParameter('StopTime'), 'Simulink:Simulation:InvalidNumberOfArguments', ...
        'paires'
    @() un.getVariable('absente'), 'Simulink:Simulation:VariableNotFound', 'absente'
    @() un.setPreSimFcn(3), 'Simulink:Simulation:InvalidFunctionHandle', 'PreSimFcn'
    @() validate(un.setBlockParameter('entree/zz', 'Gain', '3')), ...
        'Simulink:Commands:InvSimulinkObjectName', 'entree/zz'
    @() validate(un.setBlockParameter('autre/g', 'Gain', '3')), ...
        'Simulink:Commands:InvSimulinkObjectName', 'commence par'
    @() sim(un, 'StopTime', '3'), 'Simulink:Commands:SimArguments', 'SETMODELPARAMETER'
    @() parsim(3), 'Simulink:parsim:InvalidInput', 'SimulationInput'
    @() parsim(lot, 'RunInBackground', 'on'), 'Simulink:parsim:RunInBackgroundUnsupported', ...
        'pool'
    @() sim(lot(2)), 'Simulink:Commands:ParametreNonEvalue', 'variableAbsente'
    @() sim(Simulink.SimulationInput('modeleQuiNExistePas')), ...
        'Simulink:Commands:OpenSystemUnknownSystem', 'modeleQuiNExistePas'
    @() sim(lot(1).setPreSimFcn(@(x) 3)), 'Simulink:Simulation:InvalidPreSimFcnOutput', ...
        'double'
    @() sim(lot(1).setPostSimFcn(@(o) 3)), 'Simulink:Simulation:InvalidPostSimFcnOutput', ...
        'double'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('parametres et SimulationInput, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
assert(~exist('Kvar', 'var'), 'aucune simulation en erreur ne laisse sa variable');
fprintf('parametres et SimulationInput : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------------------ 34. Journal des signaux : logsout et ports
% Un signal se règle sur le port de sortie d'où il part : GET_PARAM rend
% les poignées des ports d'un bloc, SET_PARAM sur l'une d'elles nomme le
% signal et le journalise, et SIM range les signaux journalisés dans
% logsout, un Simulink.SimulationData.Dataset.
jr = new_system('journalise');
jr = add_block(jr, 'sine', 's');
jr = add_block(jr, 'gain', 'g', 'Gain', 2);
jr = add_block(jr, 'outport', 'y');
jr = add_line(add_line(jr, 's', 'g'), 'g', 'y');
pg = get_param(jr, 'g', 'PortHandles');
assert(numel(pg.Inport) == 1 && numel(pg.Outport) == 1 && isempty(pg.Enable) && ...
       isempty(pg.Trigger), 'PortHandles : une poignee par port');
assert(isequal(get_param(jr, 'journalise/g', 'PortHandles'), pg), 'les memes poignees');
assert(strcmp(get_param(jr, pg.Outport(1), 'PortType'), 'outport') && ...
       get_param(jr, pg.Outport(1), 'PortNumber') == 1 && ...
       strcmp(get_param(jr, pg.Inport(1), 'Parent'), 'journalise/g') && ...
       strcmp(get_param(jr, pg.Inport(1), 'PortType'), 'inport'), ...
       'PortType, PortNumber, Parent');
assert(strcmp(get_param(jr, pg.Outport(1), 'DataLogging'), 'off') && ...
       isempty(get_param(jr, pg.Outport(1), 'Name')), 'les defauts d''un port');
jr = set_param(jr, pg.Outport(1), 'Name', 'double', 'DataLogging', 'on');
reglage = {'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 1};
r = sim(jr, reglage{:});
assert(isa(r.logsout, 'Simulink.SimulationData.Dataset') && r.logsout.numElements == 1 && ...
       strcmp(r.logsout.Name, 'logsout'), 'logsout, un Dataset');
element = r.logsout.get('double');
valeurs = element.Values.Data;
assert(strcmp(element.BlockPath, 'journalise/g') && element.PortIndex == 1 && ...
       strcmp(element.Name, 'double') && isa(element.Values, 'timeseries') && ...
       numel(element.Values.Time) == 11 && abs(valeurs(end) - 2 * sin(1)) < 1e-12, ...
       'un element : son nom, son bloc, son port, ses valeurs');
ps = get_param(jr, 's', 'PortHandles');
jr = set_param(jr, ps.Outport(1), 'Name', 'onde');
assert(strcmp(get_param(jr, pg.Inport(1), 'Name'), 'onde'), ...
       'un port d''entree voit le nom du signal qui lui arrive');
jr = set_param(jr, ps.Outport(1), 'DataLogging', 'on', 'DataLoggingNameMode', 'Custom', ...
               'DataLoggingName', 'source', 'DataLoggingDecimateData', 'on', ...
               'DataLoggingDecimation', 5);
assert(strcmp(get_param(jr, ps.Outport(1), 'DataLoggingDecimation'), '5'), ...
       'un nombre se range en texte, comme dans Simulink');
r = sim(jr, reglage{:});
source = r.logsout.get('source');
assert(isequal(r.logsout.getElementNames, {'source'; 'double'}) && ...
       max(abs(source.Values.Time(:)' - [0 0.5 1])) < 1e-12, ...
       'DataLoggingName et un instant sur cinq');
jr = set_param(jr, ps.Outport(1), 'DataLoggingLimitDataPoints', 'on', 'DataLoggingMaxPoints', '2');
r = sim(jr, reglage{:});
source = r.logsout.get('source');
assert(max(abs(source.Values.Time(:)' - [0.5 1])) < 1e-12, 'les deux derniers seulement');
r = sim(jr, reglage{:}, 'SignalLogging', 'off');
assert(~isfield(r, 'logsout'), 'SignalLogging off : pas de journal');
r = sim(jr, reglage{:}, 'SignalLoggingName', 'journal');
assert(isfield(r, 'journal') && ~isfield(r, 'logsout'), 'SignalLoggingName');
r = sim(new_system('rien'), 1);
assert(~isfield(r, 'logsout'), 'sans signal journalise, pas de logsout');
sim(set_param(jr, 'ReturnWorkspaceOutputs', 'off'), reglage{:});
assert(exist('logsout', 'var') == 1 && logsout.numElements == 2, ...
       'sans sortie, logsout va dans l''espace de travail');
clear logsout tout yout
out = sim(Simulink.SimulationInput(jr));
assert(out.logsout.numElements == 2, 'sim(in) journalise aussi');

% Les signaux vecteurs et matrices ; un signal dans un sous-système.
vm = new_system('formes');
vm = add_block(vm, 'constant', 'v', 'Value', [1 2 3]);
vm = add_block(vm, 'constant', 'mat', 'Value', [1 2; 3 4]);
vm = add_block(vm, 'terminator', 't1');
vm = add_block(vm, 'terminator', 't2');
vm = add_line(add_line(vm, 'v', 't1'), 'mat', 't2');
pv = get_param(vm, 'v', 'PortHandles');
pm = get_param(vm, 'mat', 'PortHandles');
vm = set_param(vm, pv.Outport(1), 'Name', 'vecteur', 'DataLogging', 'on');
vm = set_param(vm, pm.Outport(1), 'Name', 'matrice', 'DataLogging', 'on');
r = sim(vm, reglage{:});
vecteur = r.logsout.get('vecteur').Values.Data;
matrice = r.logsout.get('matrice').Values.Data;
assert(isequal(size(vecteur), [11 3]) && isequal(vecteur(end, :), [1 2 3]) && ...
       isequal(size(matrice), [2 2 11]) && isequal(matrice(:, :, 5), [1 2; 3 4]), ...
       'un vecteur par ligne, une matrice par page');
dedans = new_system('dedans');
dedans = add_block(dedans, 'inport', 'e');
dedans = add_block(dedans, 'gain', 'k', 'Gain', 3);
dedans = add_block(dedans, 'outport', 'o');
dedans = add_line(add_line(dedans, 'e', 'k'), 'k', 'o');
em = new_system('emboite');
em = add_block(em, 'constant', 'c', 'Value', 2);
em = add_block(em, 'subsystem', 'sous', 'Model', dedans);
em = add_block(em, 'outport', 'y');
em = add_line(add_line(em, 'c', 'sous'), 'sous', 'y');
pk = get_param(em, 'sous/k', 'PortHandles');
em = set_param(em, pk.Outport(1), 'Name', 'triple', 'DataLogging', 'on');
assert(strcmp(get_param(em, pk.Outport(1), 'Parent'), 'emboite/sous/k'), 'un port du dedans');
psous = get_param(em, 'emboite/sous', 'PortHandles');
em = set_param(em, psous.Outport(1), 'Name', 'sortieSous', 'DataLogging', 'on');
r = sim(em, 1);
triple = r.logsout.get('triple');
valeurs = triple.Values.Data;
assert(isequal(r.logsout.getElementNames, {'sortieSous'; 'triple'}) && ...
       strcmp(triple.BlockPath, 'emboite/sous/k') && valeurs(end) == 6, ...
       'un signal journalise dans un sous-systeme');

% Les noms et la journalisation passent par les fichiers : le .m de
% SAVE_SYSTEM, le .slx, et le .mdl de Simulink.
dossierJournal = tempname();
mkdir(dossierJournal);
fichierM = save_system(em, fullfile(dossierJournal, 'emboite_journal.m'));
r = sim(load_system(fichierM), 1);
assert(isequal(r.logsout.getElementNames, {'sortieSous'; 'triple'}), 'le .m reprend le journal');
save_system(em, fullfile(dossierJournal, 'emboite_journal.slx'));
relu = load_system(fullfile(dossierJournal, 'emboite_journal.slx'));
r = sim(relu, 1);
pkRelu = get_param(relu, 'sous/k', 'PortHandles');
assert(isequal(r.logsout.getElementNames, {'sortieSous'; 'triple'}) && ...
       strcmp(get_param(relu, pkRelu.Outport(1), 'Name'), 'triple'), 'le .slx aussi');
texteMdl = sprintf(['Model {\n  Name "journalMdl"\n  System {\n    Name "journalMdl"\n' ...
    '    Block {\n      BlockType Constant\n      Name "C"\n      Value "4"\n    }\n' ...
    '    Block {\n      BlockType Gain\n      Name "G"\n      Gain "3"\n' ...
    '      Port {\n        PortNumber 1\n        Name "produit"\n        DataLogging on\n' ...
    '      }\n    }\n' ...
    '    Block {\n      BlockType Outport\n      Name "Out1"\n    }\n' ...
    '    Line {\n      Name "consigne"\n      SrcBlock "C"\n      SrcPort 1\n' ...
    '      DstBlock "G"\n      DstPort 1\n    }\n' ...
    '    Line {\n      SrcBlock "G"\n      SrcPort 1\n      DstBlock "Out1"\n' ...
    '      DstPort 1\n    }\n  }\n}\n']);
fichierMdl = fullfile(dossierJournal, 'journalMdl.mdl');
identifiant = fopen(fichierMdl, 'w');
fprintf(identifiant, '%s', texteMdl);
fclose(identifiant);
lu = load_system(fichierMdl);
r = sim(lu, 1);
produit = r.logsout.get('produit');
valeurs = produit.Values.Data;
pgLu = get_param(lu, 'G', 'PortHandles');
assert(valeurs(end) == 12 && strcmp(get_param(lu, pgLu.Inport(1), 'Name'), 'consigne'), ...
       'le .mdl : un Port journalise, un lien nomme');
rmdir(dossierJournal, 's');

autre = add_block(new_system('autre'), 'gain', 'g');
sansGain = delete_block(jr, 'g');
casErreurs = {
    @() set_param(jr, pg.Outport(1), 'DataLogging', 'peut-etre'), ...
        'Simulink:Commands:SetParamInvalidValue', '''off'' ou ''on'''
    @() set_param(jr, pg.Outport(1), 'Couleur', 'rouge'), 'Simulink:Commands:ParamUnknown', ...
        'Couleur'
    @() set_param(jr, pg.Inport(1), 'DataLogging', 'on'), 'Simulink:Commands:ParamReadOnly', ...
        'port de sortie'
    @() set_param(jr, 12345.5, 'Name', 'x'), 'Simulink:Commands:InvalidPortHandle', ...
        'PortHandles'
    @() set_param(autre, pg.Outport(1), 'Name', 'x'), 'Simulink:Commands:InvalidPortHandle', ...
        'journalise'
    @() set_param(jr, pg.Outport(1), 'DataLoggingDecimation', 0), ...
        'Simulink:Commands:SetParamInvalidValue', 'entier'
    @() set_param(jr, pg.Outport(1), 'Name'), 'Simulink:Commands:SetParamArguments', 'paires'
    @() set_param(jr, pg.Outport(1), 'DataLoggingNameMode', 'Auto'), ...
        'Simulink:Commands:SetParamInvalidValue', 'Custom'
    @() get_param(jr, pg.Outport(1)), 'Simulink:Commands:GetParamArguments', 'reglage'
    @() get_param(jr, pg.Outport(1), 'Couleur'), 'Simulink:Commands:ParamUnknown', 'Couleur'
    @() get_param(jr, 'absent', 'PortHandles'), 'Simulink:Commands:InvSimulinkObjectName', ...
        'absent'
    @() set_param(sansGain, pg.Outport(1), 'Name', 'x'), ...
        'Simulink:Commands:InvSimulinkObjectName', 'plus de bloc'
    @() sim(jr, 'SignalLoggingName', '1x'), 'Simulink:Config:InvalidValue', 'SignalLoggingName'
    @() sim(jr, 'SignalLogging', 'parfois'), 'Simulink:Config:InvalidValue', 'SignalLogging'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('journal des signaux, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
fprintf('journal des signaux : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------ 35. Batterie : journal et parsim sur tout le catalogue
% Chaque type de bloc du catalogue, seul, sur un scalaire puis sur un
% vecteur, toutes ses sorties journalisées, simulé par PARSIM sous deux
% solveurs. Chaque simulation aboutit — et logsout porte un élément par
% sortie, un échantillon par instant —, ou range dans ErrorMessage une
% erreur de Simulink qui nomme le bloc ; jamais une erreur interne.
dossierBatterie = tempname();
mkdir(dossierBatterie);
dossierAvantBatterie = pwd();
cd(dossierBatterie);
catalogueBatterie = matlibre_sl_catalogue();
typesBatterie = {};
for kT = 1:numel(catalogueBatterie)
    if ~strcmp(catalogueBatterie(kT).famille, 'Interne')
        typesBatterie{end + 1} = catalogueBatterie(kT).type; %#ok<SAGROW>
    end
end
lotBatterie = Simulink.SimulationInput.empty;
attendus = [];
contextes = {};
for kT = 1:numel(typesBatterie)
    for valeur = {0.5, [0.5; 1.5; 2.5]}
        [s, ok] = batterieModele('journalBatterie', typesBatterie(kT), valeur{1});
        if ~ok, continue, end
        portsB = get_param(s, 'b1', 'PortHandles');
        for h = portsB.Outport
            s = set_param(s, h, 'DataLogging', 'on', 'Name', sprintf('sortie%d', ...
                          get_param(s, h, 'PortNumber')));
        end
        for solveur = {'ode3', 'ode45'}
            entreeB = Simulink.SimulationInput(s);
            entreeB = entreeB.setModelParameter('Solver', solveur{1}, 'FixedStep', '0.1', ...
                                                'StopTime', '0.5');
            lotBatterie(end + 1) = entreeB; %#ok<SAGROW>
            attendus(end + 1) = numel(portsB.Outport); %#ok<SAGROW>
            contextes{end + 1} = sprintf('%s (%s)', typesBatterie{kT}, solveur{1}); %#ok<SAGROW>
        end
    end
end
evalc('sortiesBatterie = parsim(lotBatterie, ''ShowProgress'', ''off'');');
nJournalises = 0;
nRefuses = 0;
for kB = 1:numel(lotBatterie)
    o = sortiesBatterie(kB);
    if isempty(o.ErrorMessage)
        if attendus(kB) == 0
            continue
        end
        assert(isfield(o, 'logsout') && o.logsout.numElements == attendus(kB), ...
               sprintf('%s : %d sorties journalisees attendues', contextes{kB}, attendus(kB)));
        for kE = 1:attendus(kB)
            element = o.logsout.get(sprintf('sortie%d', kE));
            assert(numel(element.Values.Time) == numel(o.tout) && ...
                   strcmp(element.BlockPath, 'journalBatterie/b1'), ...
                   sprintf('%s : la sortie %d n''a pas un echantillon par instant', ...
                           contextes{kB}, kE));
        end
        nJournalises = nJournalises + 1;
    else
        diagnostic = o.SimulationMetadata.ExecutionInfo.ErrorDiagnostic;
        assert(strncmp(diagnostic.identifier, 'Simulink:', 9) || ...
               strncmp(diagnostic.identifier, 'Stateflow:', 10) || ...
               strncmp(diagnostic.identifier, 'Simscape:', 9), ...
               sprintf('%s : erreur interne %s : %s', contextes{kB}, diagnostic.identifier, ...
                       o.ErrorMessage));
        assert(~isempty(strfind(o.ErrorMessage, 'journalBatterie/')), ...
               sprintf('%s : le message ne nomme pas de bloc : %s', contextes{kB}, ...
                       o.ErrorMessage));
        nRefuses = nRefuses + 1;
    end
end
cd(dossierAvantBatterie);
rmdir(dossierBatterie, 's');
assert(nJournalises > 300, 'la batterie journalise la plupart des blocs');
fprintf('batterie du journal par parsim : %d simulations journalisees, %d refus nommes\n', ...
        nJournalises, nRefuses);

%% ------------------------------------------- 36. Variantes : sous-systèmes et signaux
% Un sous-système à variantes porte plusieurs variantes, chacune avec sa
% condition VariantControl ; seule celle dont la condition est vraie au
% moment de simuler calcule. Variant Source et Variant Sink font de même
% pour un signal. Un Simulink.Variant range une condition sous un nom.
doubleur = new_system('doubleur');
doubleur = add_block(doubleur, 'inport', 'u');
doubleur = add_block(doubleur, 'gain', 'k', 'Gain', 2);
doubleur = add_block(doubleur, 'outport', 'y');
doubleur = add_line(add_line(doubleur, 'u', 'k'), 'k', 'y');
tripleur = set_param(doubleur, 'k', 'Gain', 3);
choix = new_system('choix');
choix = add_block(choix, 'inport', 'u');
choix = add_block(choix, 'outport', 'y');
choix = add_block(choix, 'subsystem', 'Double', 'Model', doubleur, 'VariantControl', 'Mode == 1');
choix = add_block(choix, 'subsystem', 'Triple', 'Model', tripleur, 'VariantControl', 'Mode == 2');
va = new_system('variantes');
va = add_block(va, 'constant', 'c', 'Value', 5);
va = add_block(va, 'subsystem', 'V', 'Model', choix, 'Variant', 'on');
va = add_block(va, 'outport', 'y');
va = add_line(add_line(va, 'c', 'V'), 'V', 'y');
Mode = 1;
r = sim(va, 1);
assert(r.yout(end) == 10, 'la variante active : Mode == 1');
Mode = 2;
r = sim(va, 1);
assert(r.yout(end) == 15, 'l''autre variante, sans toucher au modele');
Mode = 3;
r = sim(set_param(va, 'V/Triple', 'VariantControl', '(default)'), 1);
assert(r.yout(end) == 15, 'la variante par defaut quand aucune condition n''est vraie');
r = sim(set_param(va, 'V', 'AllowZeroVariantControls', 'on'), 1);
assert(r.yout(end) == 0, 'AllowZeroVariantControls : sans variante active, zero');
Moteur = Simulink.Variant('Mode == 3');
assert(strcmp(Moteur.Condition, 'Mode == 3'), 'un Simulink.Variant range sa condition');
r = sim(set_param(va, 'V/Triple', 'VariantControl', 'Moteur'), 1);
assert(r.yout(end) == 15, 'une condition donnee par un Simulink.Variant');
etiquettes = set_param(va, 'V', 'VariantControlMode', 'label', 'LabelModeActiveChoice', 'rapide');
etiquettes = set_param(etiquettes, 'V/Double', 'VariantControl', 'lent');
etiquettes = set_param(etiquettes, 'V/Triple', 'VariantControl', 'rapide');
r = sim(etiquettes, 1);
assert(r.yout(end) == 15, 'le mode label : l''etiquette active');
ModeP = Simulink.Parameter(2);
r = sim(set_param(set_param(va, 'V/Double', 'VariantControl', 'ModeP == 1'), 'V/Triple', ...
                  'VariantControl', 'ModeP == 2'), 1);
assert(r.yout(end) == 15, 'une condition qui lit un Simulink.Parameter');

% Une variante qui n'a pas toutes les sorties : celle qui manque vaut zéro.
deuxSorties = add_block(choix, 'outport', 'z');
deuxSorties = set_param(deuxSorties, 'Triple', 'Model', ...
                        add_line(add_block(tripleur, 'outport', 'z'), 'k', 'z'));
vb = add_block(va, 'outport', 'y2');
vb = set_param(vb, 'V', 'Model', deuxSorties);
vb = add_line(vb, 'V/2', 'y2');
Mode = 1;
r = sim(vb, 1);
assert(isequal(r.yout(end, :), [10 0]), 'la sortie que la variante n''a pas vaut zero');
Mode = 2;
r = sim(vb, 1);
assert(isequal(r.yout(end, :), [15 15]), 'et celle qui l''a la rend');

% Les variantes par SimulationInput : un balayage de Mode par parsim.
balayage(1:2) = Simulink.SimulationInput(va);
balayage(1) = balayage(1).setVariable('Mode', 1);
balayage(2) = balayage(2).setVariable('Mode', 2);
sortiesVariantes = parsim(balayage, 'ShowProgress', 'off');
assert(sortiesVariantes(1).yout(end) == 10 && sortiesVariantes(2).yout(end) == 15, ...
       'parsim balaie les variantes');

% Variant Source et Variant Sink.
vsrc = new_system('sourceVariante');
vsrc = add_block(vsrc, 'constant', 'a', 'Value', 10);
vsrc = add_block(vsrc, 'constant', 'b', 'Value', 20);
vsrc = add_block(vsrc, 'variantsource', 'vs', 'VariantControls', {'Mode == 1', 'Mode == 3'});
vsrc = add_block(vsrc, 'outport', 'y');
vsrc = add_line(add_line(vsrc, 'a', 'vs', 1), 'b', 'vs', 2);
vsrc = add_line(vsrc, 'vs', 'y');
assert(isequal(get_param(vsrc, 'vs', 'Ports'), [2 1 0 0 0 0 0 0]), ...
       'un Variant Source : une entree par condition');
Mode = 3;
r = sim(vsrc, 1);
assert(r.yout(end) == 20, 'Variant Source : la deuxieme entree');
Mode = 1;
r = sim(vsrc, 1);
assert(r.yout(end) == 10, 'Variant Source : la premiere');
vsnk = new_system('puitsVariante');
vsnk = add_block(vsnk, 'constant', 'a', 'Value', 7);
vsnk = add_block(vsnk, 'variantsink', 'vk', 'VariantControls', {'Mode == 1', 'Mode == 2'});
vsnk = add_block(vsnk, 'outport', 'y1');
vsnk = add_block(vsnk, 'outport', 'y2');
vsnk = add_line(add_line(vsnk, 'a', 'vk'), 'vk/1', 'y1');
vsnk = add_line(vsnk, 'vk/2', 'y2');
Mode = 2;
r = sim(vsnk, 1);
assert(isequal(r.yout(end, :), [0 7]), 'Variant Sink : la sortie active recoit, l''autre vaut zero');

% Les variantes passent par les fichiers : le .m et le .slx.
dossierVariantes = tempname();
mkdir(dossierVariantes);
fichierM = save_system(va, fullfile(dossierVariantes, 'variantesM.m'));
Mode = 2;
r = sim(load_system(fichierM), 1);
assert(r.yout(end) == 15, 'le .m reprend les variantes');
save_system(va, fullfile(dossierVariantes, 'variantesX.slx'));
relu = load_system(fullfile(dossierVariantes, 'variantesX.slx'));
Mode = 1;
r = sim(relu, 1);
assert(r.yout(end) == 10, 'le .slx aussi');
save_system(vsrc, fullfile(dossierVariantes, 'sourceX.slx'));
reluSource = load_system(fullfile(dossierVariantes, 'sourceX.slx'));
Mode = 3;
r = sim(reluSource, 1);
assert(r.yout(end) == 20 && isequal(get_param(reluSource, 'vs', 'Ports'), [2 1 0 0 0 0 0 0]), ...
       'un Variant Source relu garde ses conditions');
rmdir(dossierVariantes, 's');

intrus = add_block(choix, 'gain', 'g');
mauvaisPort = set_param(choix, 'Double', 'Model', ...
                        add_block(doubleur, 'inport', 'autre', 'Port', 2));
Mode = 1;
casErreurs = {
    @() sim(set_param(va, 'V/Triple', 'VariantControl', 'Mode >= 1'), 1), ...
        'Simulink:Variants:MultipleActiveVariants', 'variantes/V/Triple'
    @() sim(set_param(set_param(va, 'V/Double', 'VariantControl', 'Mode == 7'), 'V/Triple', ...
                      'VariantControl', 'Mode == 8'), 1), 'Simulink:Variants:NoActiveVariant', ...
        'variantes/V'
    @() sim(set_param(va, 'V/Double', 'VariantControl', 'ModeInconnu == 1'), 1), ...
        'Simulink:Variants:InvalidVariantControl', 'ModeInconnu'
    @() sim(set_param(va, 'V/Double', 'VariantControl', '[1 1]'), 1), ...
        'Simulink:Variants:InvalidVariantControl', '2 valeurs'
    @() sim(set_param(va, 'V', 'VariantControlMode', 'label'), 1), ...
        'Simulink:Variants:NoActiveLabel', 'LabelModeActiveChoice'
    @() sim(set_param(va, 'V', 'VariantControlMode', 'label', 'LabelModeActiveChoice', 'x'), 1), ...
        'Simulink:Variants:InvalidLabel', '''x'''
    @() sim(set_param(set_param(va, 'V/Double', 'VariantControl', '(default)'), 'V/Triple', ...
                      'VariantControl', '(default)'), 1), 'Simulink:Variants:MultipleDefaults', ...
        'par defaut'
    @() sim(set_param(va, 'V', 'Model', intrus), 1), ...
        'Simulink:Variants:InvalidBlockInVariant', '''g'''
    @() sim(set_param(va, 'V', 'Model', new_system('vide')), 1), ...
        'Simulink:Variants:NoVariantChoices', 'variantes/V'
    @() sim(set_param(va, 'V', 'Model', mauvaisPort), 1), 'Simulink:Variants:PortMismatch', ...
        'autre'
    @() Simulink.Variant(3), 'Simulink:Variants:InvalidCondition', 'texte'
    @() sim(set_param(vsrc, 'vs', 'VariantControls', {'Mode == 1', 'Mode == 1'}), 1), ...
        'Simulink:Variants:MultipleActiveVariants', 'sourceVariante/vs'
    };
for kE = 1:size(casErreurs, 1)
    Mode = 1;
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('variantes, cas %d : %s attendu, %s rendu (%s)', kE, casErreurs{kE, 2}, ...
                   vu, message));
end
clear Mode ModeP Moteur
fprintf('variantes : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ----------------------------------- 37. L'espace de travail du modèle
% Chaque modèle a son espace de travail, un Simulink.ModelWorkspace que
% rend GET_PARAM(M,'ModelWorkspace') : ses variables passent avant
% celles de l'espace de base, pour les blocs, les masques et les
% conditions des variantes. SAVE_SYSTEM l'écrit, un SimulationInput y
% pose ses variables quand Workspace nomme le modèle.
ew = new_system('espaceModele');
ew = add_block(ew, 'constant', 'c', 'Value', 'Kew');
ew = add_line(add_block(ew, 'outport', 'y'), 'c', 'y');
hws = get_param(ew, 'ModelWorkspace');
assert(isa(hws, 'Simulink.ModelWorkspace') && strcmp(hws.DataSource, 'Model File'), ...
       'l''espace de travail du modele');
assignin(hws, 'Kew', 42);
assert(hasVariable(hws, 'Kew') && getVariable(hws, 'Kew') == 42, 'assignin et getVariable');
r = sim(ew, 1);
assert(r.yout(end) == 42, 'un bloc lit la variable de l''espace du modele');
Kew = 5;
r = sim(ew, 1);
assert(r.yout(end) == 42, 'elle passe avant celle de l''espace de base');
clear(hws, 'Kew');
r = sim(ew, 1);
assert(r.yout(end) == 5, 'retiree, c''est celle de base qui vaut');
evalin(hws, 'Kew = 2 * 3; Lew = Kew + 1;');
assert(getVariable(hws, 'Lew') == 7 && isequal(sort({whos(hws).name}), {'Kew', 'Lew'}), ...
       'evalin execute du code dans l''espace, whos le decrit');
hws.DataSource = 'MATLAB Code';
hws.MATLABCode = 'Kew = 100;';
reload(hws);
r = sim(ew, 1);
assert(r.yout(end) == 100 && ~hasVariable(hws, 'Lew'), 'reload reexecute MATLABCode');
hws.DataSource = 'Model File';
hws.MATLABCode = '';
clear Kew

% Un Simulink.Parameter de l'espace du modèle, un masque, une variante.
Pew = Simulink.Parameter(2);
Pew.DataType = 'int16';
assignin(hws, 'Pew', Pew);
clear Pew
r = sim(set_param(ew, 'c', 'Value', 'Kew * Pew'), 1);
assert(isa(r.yout, 'int16') && r.yout(end) == 200, 'un Simulink.Parameter de l''espace du modele');
dedansEw = new_system('dedansEw');
dedansEw = add_block(dedansEw, 'inport', 'e');
dedansEw = add_block(dedansEw, 'gain', 'k', 'Gain', 'G');
dedansEw = add_block(dedansEw, 'outport', 's');
dedansEw = add_line(add_line(dedansEw, 'e', 'k'), 'k', 's');
masqueEw = add_block(ew, 'subsystem', 'sous', 'Model', dedansEw, 'Mask', 'on', ...
                     'MaskVariables', 'G=@1;', 'MaskValueString', 'Kew');
masqueEw = add_line(add_block(masqueEw, 'outport', 'y2'), 'sous', 'y2');
masqueEw = add_line(masqueEw, 'c', 'sous');
r = sim(masqueEw, 1);
assert(isequal(r.yout(end, :), [100 10000]), 'un masque lit l''espace du modele');

% SAVE_SYSTEM écrit l'espace ; NEW_SYSTEM en donne un neuf.
fichierEw = save_system(ew, fullfile(tempdir(), 'espaceModeleSauve.m'));
assert(~isempty(strfind(fileread(fichierEw), 'ModelWorkspace')), 'le .m ecrit l''espace');
neuf = new_system('espaceModele');
assert(~hasVariable(get_param(neuf, 'ModelWorkspace'), 'Kew'), 'un modele neuf, un espace vide');
relu = load_system(fichierEw);
r = sim(relu, 1);
assert(r.yout(end) == 100 && isa(getVariable(get_param(relu, 'ModelWorkspace'), 'Pew'), ...
                                 'Simulink.Parameter'), 'le .m relu repose l''espace');
delete(fichierEw);

% Un SimulationInput pose une variable dans l'espace du modèle, le temps
% d'une simulation.
in = Simulink.SimulationInput(relu);
in = in.setVariable('Kew', 7, 'Workspace', 'espaceModele');
o = sim(in);
assert(o.yout(end) == 7 && getVariable(get_param(relu, 'ModelWorkspace'), 'Kew') == 100, ...
       'setVariable dans l''espace du modele, rendu ensuite');
bdclose('espaceModele');
assert(~matlibre_sl_espace('existe', 'espaceModele'), 'BDCLOSE vide l''espace');

hwsErreurs = get_param(new_system('erreursEw'), 'ModelWorkspace');
casErreurs = {
    @() getVariable(hwsErreurs, 'absente'), 'Simulink:Data:VariableNotFound', 'absente'
    @() assignin(hwsErreurs, '1x', 3), 'Simulink:Data:InvalidVariableName', '1x'
    @() evalin(hwsErreurs, 'x = variableInconnue + 1;'), 'Simulink:Data:WorkspaceEvalError', ...
        'erreursEw'
    @() poserPropriete(hwsErreurs, 'DataSource', 'Disquette'), 'Simulink:Data:InvalidValue', ...
        'DataSource'
    @() sim(Simulink.SimulationInput(ew).setVariable('Kew', 1, 'Workspace', 'autre')), ...
        'Simulink:Simulation:InvalidWorkspace', 'autre'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('espace du modele, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
bdclose('erreursEw');
fprintf('espace du modele : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------------------ 38. Stateflow : événements d'entrée et de sortie
% SFEVENT déclare les événements d'un diagramme. Dans un bloc Chart, ceux
% d'entrée arrivent par un port de déclenchement, un élément par
% événement, et le diagramme ne calcule que quand l'un d'eux survient ;
% ceux de sortie ont chacun leur port : un 'Function call' appelle un
% sous-système appelé par fonction, un 'Either' bascule à chaque émission.
compteurEvt = sfchart('compteurEvt');
compteurEvt = sfevent(compteurEvt, 'impulsion', 'Input', 'Rising');
compteurEvt = sfevent(compteurEvt, 'plein', 'Output', 'Function call');
compteurEvt = sfstate(compteurEvt, 'compte', 'en: n = 0; du: n = n + 1;');
compteurEvt = sftransition(compteurEvt, 'compte', 'compte', 'impulsion[n >= 2]{plein;}');
assert(numel(compteurEvt.evenements) == 2 && ...
       strcmp(compteurEvt.evenements(2).declencheur, 'Function call'), 'SFEVENT');
appele = new_system('appele');
appele = add_block(appele, 'triggerport', 'f', 'TriggerType', 'function-call');
appele = add_block(appele, 'constant', 'un', 'Value', 1);
appele = add_block(appele, 'sum', 's', 'Signs', '++');
appele = add_block(appele, 'memory', 'mem');
appele = add_block(appele, 'outport', 'o');
appele = add_line(add_line(appele, 'un', 's', 1), 'mem', 's', 2);
appele = add_line(add_line(appele, 's', 'mem'), 's', 'o');
ev = new_system('evenements');
ev = add_block(ev, 'pulsegenerator', 'p', 'Period', 1, 'PulseWidth', 50, 'Amplitude', 1);
ev = add_block(ev, 'chart', 'graphe', 'Chart', compteurEvt, 'Inputs', 0, 'Outputs', {'n'}, ...
               'InitialContext', struct('n', 0));
ev = add_block(ev, 'subsystem', 'appele', 'Model', appele);
ev = add_block(ev, 'outport', 'n');
ev = add_block(ev, 'outport', 'appels');
ev = add_line(ev, 'p', 'graphe');
ev = add_line(ev, 'graphe/1', 'n');
ev = add_line(ev, 'graphe/2', 'appele');
ev = add_line(ev, 'appele', 'appels');
assert(isequal(get_param(ev, 'graphe', 'Ports'), [1 2 0 0 0 0 0 0]), ...
       'un port de declenchement, un port par evenement de sortie');
r = sim(ev, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.25, 'StopTime', 10);
instant = @(t) find(abs(r.tout - t) < 1e-9, 1);
assert(r.yout(instant(1), 1) == 0 && r.yout(instant(2), 1) == 1 && ...
       r.yout(instant(3), 1) == 2 && r.yout(instant(3.5), 1) == 2, ...
       'le diagramme ne calcule qu''aux fronts montants, le premier l''initialise');
assert(r.yout(instant(3.75), 2) == 0 && r.yout(instant(4), 2) == 1 && ...
       r.yout(instant(7), 2) == 2 && r.yout(end, 2) == 3, ...
       'l''evenement de sortie appelle le sous-systeme a chaque emission');

% 'Either' en entrée et en sortie ; un événement par élément.
basculeEvt = sfevent(sfchart('basculeEvt'), 'tic', 'Input', 'Either');
basculeEvt = sfevent(basculeEvt, 'fin', 'Output', 'Either');
basculeEvt = sfstate(basculeEvt, 'a', 'en: k = 0; du: k = k + 1;');
basculeEvt = sftransition(basculeEvt, 'a', 'a', 'tic[k >= 1]{send(fin);}');
eb = new_system('bascules');
eb = add_block(eb, 'pulsegenerator', 'p', 'Period', 1, 'PulseWidth', 50, 'Amplitude', 1);
eb = add_block(eb, 'chart', 'graphe', 'Chart', basculeEvt, 'Inputs', 0, 'Outputs', {'k'}, ...
               'InitialContext', struct('k', 0));
eb = add_block(eb, 'outport', 'k');
eb = add_block(eb, 'outport', 'fin');
eb = add_line(add_line(eb, 'p', 'graphe'), 'graphe/1', 'k');
eb = add_line(eb, 'graphe/2', 'fin');
r = sim(eb, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.25, 'StopTime', 4);
instant = @(t) find(abs(r.tout - t) < 1e-9, 1);
assert(isequal(r.yout(instant(1), :), [1 0]) && isequal(r.yout(instant(1.5), :), [0 1]) && ...
       isequal(r.yout(instant(2.5), :), [0 0]) && isequal(r.yout(instant(3.5), :), [0 1]), ...
       'Either : chaque front reveille le diagramme, fin bascule a chaque emission');
deuxEvt = sfevent(sfevent(sfchart('deuxEvt'), 'haut', 'Input', 'Rising'), 'bas', 'Input', ...
                  'Falling');
deuxEvt = sfstate(deuxEvt, 'repos', 'en: s = 0;');
deuxEvt = sfstate(deuxEvt, 'actif', 'en: s = 1;');
deuxEvt = sftransition(deuxEvt, 'repos', 'actif', 'haut');
deuxEvt = sftransition(deuxEvt, 'actif', 'repos', 'bas');
ed = new_system('deuxEvenements');
ed = add_block(ed, 'step', 'monte', 'Time', 1);
ed = add_block(ed, 'step', 'descend', 'Time', 2, 'Before', 1, 'After', 0);
ed = add_block(ed, 'mux', 'mx', 'Inputs', 2);
ed = add_block(ed, 'chart', 'graphe', 'Chart', deuxEvt, 'Inputs', 0, 'Outputs', {'s'}, ...
               'InitialContext', struct('s', 0));
ed = add_block(ed, 'outport', 's');
ed = add_line(add_line(ed, 'monte', 'mx', 1), 'descend', 'mx', 2);
ed = add_line(add_line(ed, 'mx', 'graphe'), 'graphe', 's');
r = sim(ed, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.5, 'StopTime', 4);
instant = @(t) find(abs(r.tout - t) < 1e-9, 1);
assert(r.yout(instant(1)) == 0 && r.yout(instant(2)) == 0 && r.yout(end) == 0, ...
       'deux evenements, un element chacun');
sansDeclencheur = add_block(new_system('sansDeclencheur'), 'chart', 'graphe', 'Chart', ...
                            compteurEvt, 'Inputs', 0, 'Outputs', {'n'}, ...
                            'InitialContext', struct('n', 0));
sansDeclencheur = add_block(sansDeclencheur, 'constant', 'c', 'Value', [1 1]);
sansDeclencheur = add_line(sansDeclencheur, 'c', 'graphe');
appelFaux = add_block(new_system('appelFaux'), 'constant', 'c', 'Value', 1);
appelFaux = add_block(appelFaux, 'subsystem', 'appele', 'Model', appele);
appelFaux = add_line(appelFaux, 'c', 'appele');
casErreurs = {
    @() sfevent(compteurEvt, 'local1', 'Local'), 'Stateflow:Events:LocalUnsupported', 'local1'
    @() sfevent(compteurEvt, 'x', 'Input', 'Parfois'), 'Stateflow:Events:InvalidTrigger', ...
        'Parfois'
    @() sfevent(compteurEvt, 'y', 'Output', 'Rising'), 'Stateflow:Events:InvalidTrigger', ...
        'Rising'
    @() sfevent(compteurEvt, 'impulsion', 'Input'), 'Stateflow:Events:DuplicateName', ...
        'impulsion'
    @() sfevent(compteurEvt, 'compte', 'Input'), 'Stateflow:Events:DuplicateName', 'compte'
    @() sfevent(compteurEvt, '2x', 'Input'), 'Stateflow:Events:InvalidName', '2x'
    @() sfevent(compteurEvt, 'z', 'Globale'), 'Stateflow:Events:InvalidScope', 'Globale'
    @() sim(sansDeclencheur, 1), 'Simulink:blocks:ChartTriggerWidth', 'sansDeclencheur/graphe'
    @() sim(appelFaux, 1), 'Simulink:blocks:FcnCallSubsystemInputNotFcnCall', 'appelFaux/appele'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('evenements, cas %d : %s attendu, %s rendu (%s)', kE, casErreurs{kE, 2}, ...
                   vu, message));
end
fprintf('evenements Stateflow : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------- 39. Blocs de bibliothèque : réglages d'avance et nouveaux blocs
% Divide, Subtract, Sum of Elements et Product of Elements sont des Product
% et des Sum que la bibliothèque règle d'avance. From File lit le fichier
% qu'écrit To File ; Assignment remplace des éléments ; Combinatorial
% Logic lit une table de vérité ; Signal Specification vérifie ce qui le
% traverse.
bib = new_system('bibliotheque');
bib = add_block(bib, 'constant', 'a', 'Value', 6);
bib = add_block(bib, 'constant', 'b', 'Value', 3);
bib = add_block(bib, 'simulink/Math Operations/Divide', 'quotient');
bib = add_block(bib, 'simulink/Math Operations/Subtract', 'difference');
bib = add_block(bib, 'outport', 'q');
bib = add_block(bib, 'outport', 'd');
bib = add_line(add_line(bib, 'a', 'quotient', 1), 'b', 'quotient', 2);
bib = add_line(add_line(bib, 'a', 'difference', 1), 'b', 'difference', 2);
bib = add_line(add_line(bib, 'quotient', 'q'), 'difference', 'd');
r = sim(bib, 1);
assert(isequal(r.yout(end, :), [2 3]), 'Divide divise, Subtract soustrait');
elements = add_block(new_system('elements'), 'simulink/Math Operations/Sum of Elements', 'se');
assert(strcmp(get_param(elements, 'se', 'Signs'), '+') && ...
       isequal(get_param(elements, 'se', 'Ports'), [1 1 0 0 0 0 0 0]), ...
       'Sum of Elements : une seule entree, dont il somme les elements');
elements = add_block(elements, 'simulink/Math Operations/Product of Elements', 'pe');
assert(strcmp(get_param(elements, 'pe', 'Inputs'), '*'), 'Product of Elements');
choisi = add_block(new_system('choisi'), 'simulink/Math Operations/Divide', 'dd', 'Inputs', '/*');
assert(strcmp(get_param(choisi, 'dd', 'Inputs'), '/*'), 'un reglage donne l''emporte sur l''avance');

% From File relit ce qu'écrit To File.
dossierFichier = tempname();
mkdir(dossierFichier);
ecrit = new_system('ecrit');
ecrit = add_block(ecrit, 'ramp', 'r', 'Slope', 2);
ecrit = add_block(ecrit, 'tofile', 'tf', 'Filename', fullfile(dossierFichier, 'rampe.mat'));
ecrit = add_line(ecrit, 'r', 'tf');
sim(ecrit, 'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 2);
lu = new_system('lu');
lu = add_block(lu, 'fromfile', 'ff', 'FileName', fullfile(dossierFichier, 'rampe.mat'));
lu = add_line(add_block(lu, 'outport', 'y'), 'ff', 'y');
r = sim(lu, 'Solver', 'ode1', 'FixedStep', 0.25, 'StopTime', 2);
assert(max(abs(r.yout(:)' - 2 * (0:0.25:2))) < 1e-12, 'From File interpole le fichier de To File');
r = sim(set_param(lu, 'ff', 'InterpolationWithinTimeRange', 'Zero-order hold'), ...
       'Solver', 'ode1', 'FixedStep', 0.25, 'StopTime', 2);
assert(abs(r.yout(2) - 0) < 1e-12 && abs(r.yout(4) - 1) < 1e-12, 'Zero-order hold : en paliers');
r = sim(set_param(lu, 'ff', 'ExtrapolationAfterLastDataPoint', 'Hold last value'), ...
       'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 3);
assert(r.yout(end) == 4, 'Hold last value apres la derniere donnee');
serieFichier = timeseries([1; 3], [0; 1]);
save(fullfile(dossierFichier, 'serie.mat'), 'serieFichier');
r = sim(set_param(lu, 'ff', 'FileName', fullfile(dossierFichier, 'serie.mat')), ...
       'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 1);
assert(isequal(r.yout(:)', [1 2 3]), 'From File lit aussi une timeseries');
pasMatrice = 'texte';
save(fullfile(dossierFichier, 'mauvais.mat'), 'pasMatrice');

% Assignment : aux indices, par un indice de départ, dans une matrice,
% sur une sortie de taille donnée.
af = new_system('affectation');
af = add_block(af, 'constant', 'y0', 'Value', [1 2 3 4 5]);
af = add_block(af, 'constant', 'u', 'Value', [10 20]);
af = add_block(af, 'assignment', 'as', 'IndexParamArray', {'[2 4]'});
af = add_block(af, 'outport', 'y');
af = add_line(add_line(af, 'y0', 'as', 1), 'u', 'as', 2);
af = add_line(af, 'as', 'y');
r = sim(af, 1);
assert(isequal(r.yout(end, :), [1 10 3 20 5]), 'Assignment aux indices donnes');
r = sim(set_param(af, 'as', 'IndexOptionArray', {'Starting index (dialog)'}, ...
                  'IndexParamArray', {'3'}), 1);
assert(isequal(r.yout(end, :), [1 2 10 20 5]), 'Assignment a partir d''un indice');
r = sim(set_param(af, 'as', 'IndexMode', 'Zero-based', 'IndexParamArray', {'[0 1]'}), 1);
assert(isequal(r.yout(end, :), [10 20 3 4 5]), 'Assignment en indices a partir de 0');
matrice = new_system('affectationMatrice');
matrice = add_block(matrice, 'constant', 'y0', 'Value', zeros(2, 3));
matrice = add_block(matrice, 'constant', 'u', 'Value', [7; 8]);
matrice = add_block(matrice, 'assignment', 'as', 'NumberOfDimensions', 2, ...
                    'IndexOptionArray', {'Assign all', 'Index vector (dialog)'}, ...
                    'IndexParamArray', {'', '2'});
matrice = add_line(add_line(matrice, 'y0', 'as', 1), 'u', 'as', 2);
matrice = add_line(add_block(matrice, 'toworkspace', 'tw', 'VariableName', 'affecteeMatrice'), ...
                   'as', 'tw');
sim(matrice, 1);
assert(isequal(squeeze(affecteeMatrice(:, :, end)), [0 7 0; 0 8 0]), ...
       'Assignment d''une colonne entiere');
clear affecteeMatrice
taille = new_system('affectationTaille');
taille = add_block(taille, 'constant', 'u', 'Value', 9);
taille = add_block(taille, 'assignment', 'as', 'OutputInitialize', ...
                   'Specify size for each dimension in table', 'OutputSizeArray', {'4'}, ...
                   'IndexParamArray', {'3'});
taille = add_line(add_line(add_block(taille, 'outport', 'y'), 'as', 'y'), 'u', 'as');
assert(isequal(get_param(taille, 'as', 'Ports'), [1 1 0 0 0 0 0 0]), ...
       'sans Y0, un seul port d''entree');
r = sim(taille, 1);
assert(isequal(r.yout(end, :), [0 0 9 0]), 'Assignment sur une sortie de taille donnee');

% Combinatorial Logic : la ligne de la table que désignent les entrées.
cl = new_system('combinatoire');
cl = add_block(cl, 'constant', 'u', 'Value', [1 1]);
cl = add_block(cl, 'combinatoriallogic', 'demi');
cl = add_line(add_line(add_block(cl, 'outport', 'y'), 'demi', 'y'), 'u', 'demi');
r = sim(cl, 1);
assert(isequal(r.yout(end, :), [1 0]), 'le demi-additionneur : 1 + 1 donne retenue 1, somme 0');
r = sim(set_param(cl, 'u', 'Value', [0 1]), 1);
assert(isequal(r.yout(end, :), [0 1]), 'et 0 + 1 donne somme 1');

% Signal Specification laisse passer ce qui s'accorde à ce qu'il annonce.
sp = new_system('specification');
sp = add_block(sp, 'constant', 'u', 'Value', [1 2 3]);
sp = add_block(sp, 'signalspecification', 'spec', 'Dimensions', 3, 'OutDataTypeStr', 'double');
sp = add_line(add_line(add_block(sp, 'outport', 'y'), 'spec', 'y'), 'u', 'spec');
r = sim(sp, 1);
assert(isequal(r.yout(end, :), [1 2 3]), 'Signal Specification laisse passer');

casErreurs = {
    @() sim(set_param(lu, 'ff', 'FileName', 'absent_introuvable.mat'), 1), ...
        'Simulink:blocks:FromFileNotFound', 'lu/ff'
    @() sim(set_param(lu, 'ff', 'FileName', fullfile(dossierFichier, 'mauvais.mat')), 1), ...
        'Simulink:blocks:FromFileInvalidData', 'lu/ff'
    @() sim(set_param(af, 'as', 'IndexParamArray', {'[5 6]'}), 1), ...
        'Simulink:blocks:AssignmentOutOfRange', 'affectation/as'
    @() sim(set_param(af, 'as', 'IndexParamArray', {'[1 2 3]'}), 1), ...
        'Simulink:blocks:AssignmentOutOfRange', 'affectation/as'
    @() sim(set_param(af, 'as', 'IndexParamArray', {'[0 1]'}), 1), ...
        'Simulink:blocks:AssignmentInvalidIndex', 'affectation/as'
    @() sim(set_param(af, 'as', 'NumberOfDimensions', 3), 1), ...
        'Simulink:blocks:AssignmentDimensions', 'affectation/as'
    @() sim(set_param(af, 'as', 'IndexOptionArray', {'Index vector (port)'}), 1), ...
        'Simulink:blocks:AssignmentIndexOptions', 'affectation/as'
    @() sim(set_param(cl, 'u', 'Value', [1 0 1]), 1), ...
        'Simulink:blocks:CombinatorialLogicRows', 'combinatoire/demi'
    @() sim(set_param(cl, 'demi', 'TruthTable', [0; 1; 1]), 1), ...
        'Simulink:blocks:CombinatorialLogicRows', 'puissance de deux'
    @() sim(set_param(sp, 'spec', 'Dimensions', 2), 1), ...
        'Simulink:blocks:SignalSpecificationDimensions', 'specification/spec'
    @() sim(set_param(sp, 'spec', 'OutDataTypeStr', 'int8'), 1), ...
        'Simulink:DataType:SignalSpecificationMismatch', 'specification/spec'
    };
for kE = 1:size(casErreurs, 1)
    vu = '';
    message = '';
    try
        casErreurs{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casErreurs{kE, 2}) && ~isempty(strfind(message, casErreurs{kE, 3})), ...
           sprintf('blocs de bibliotheque, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casErreurs{kE, 2}, vu, message));
end
rmdir(dossierFichier, 's');
fprintf('blocs de bibliotheque : %d cas d''erreur verifies\n', size(casErreurs, 1));

%% ------------------------------ 40. Tables à plus de deux dimensions
% La n-D Lookup Table interpole jusqu'à six dimensions, une entrée par
% dimension ; la Direct Lookup Table (n-D) lit un élément, ses entrées
% comptées à partir de 0 et ramenées dans les bornes.
T3 = reshape(1:24, [2 3 4]);
tab3 = new_system('tab3');
tab3 = add_block(tab3, 'constant', 'a', 'Value', 0.5);
tab3 = add_block(tab3, 'constant', 'b', 'Value', 1.5);
tab3 = add_block(tab3, 'constant', 'c', 'Value', 2);
tab3 = add_block(tab3, 'simulink/Lookup Tables/n-D Lookup Table', 'tb', ...
                 'NumberOfTableDimensions', 3, 'BreakpointsForDimension1', [0 1], ...
                 'BreakpointsForDimension2', [0 1 2], ...
                 'BreakpointsForDimension3', [0 1 2 3], 'Table', T3);
tab3 = add_line(add_block(tab3, 'outport', 'y'), 'tb', 'y');
tab3 = add_line(add_line(add_line(tab3, 'a', 'tb', 1), 'b', 'tb', 2), 'c', 'tb', 3);
r = sim(tab3, 1);
attendu = interpn(0:1, 0:2, 0:3, T3, 0.5, 1.5, 2);
assert(abs(r.yout(end) - attendu) < 1e-12 && abs(attendu - 16.5) < 1e-12, ...
       'n-D Lookup Table a trois dimensions : interpolation multilineaire');
% hors des bornes : tenue (Clip) ou prolongée (Linear)
tenue = sim(set_param(tab3, 'c', 'Value', 5), 1);
assert(abs(tenue.yout(end) - interpn(0:1, 0:2, 0:3, T3, 0.5, 1.5, 3)) < 1e-12, ...
       'Clip tient la table a son bord');
prolongee = sim(set_param(set_param(tab3, 'c', 'Value', 5), 'tb', 'ExtrapMethod', 'Linear'), 1);
assert(abs(prolongee.yout(end) - (tenue.yout(end) + 2 * 6)) < 1e-12, ...
       'Linear prolonge le dernier intervalle (T croit de 6 par page)');
proche = sim(set_param(tab3, 'tb', 'InterpMethod', 'Nearest', 'ExtrapMethod', 'Clip'), 1);
assert(proche.yout(end) == T3(2, 3, 3), 'Nearest rend le point le plus proche');
plat = sim(set_param(tab3, 'tb', 'InterpMethod', 'Flat'), 1);
assert(plat.yout(end) == T3(1, 2, 3), 'Flat rend le point inferieur');
% une table à quatre dimensions, parcourue par une horloge
T4 = reshape(1:16, [2 2 2 2]);
tab4 = new_system('tab4');
tab4 = add_block(tab4, 'clock', 't');
tab4 = add_block(tab4, 'constant', 'z', 'Value', 0);
tab4 = add_block(tab4, 'lookup', 'tb', 'NumberOfTableDimensions', 4, ...
                 'BreakpointsData', [0 1], 'BreakpointsForDimension2', [0 1], ...
                 'BreakpointsForDimension3', [0 1], 'BreakpointsForDimension4', [0 1], ...
                 'TableData', T4);
tab4 = add_line(add_block(tab4, 'outport', 'y'), 'tb', 'y');
tab4 = add_line(add_line(tab4, 't', 'tb', 1), 'z', 'tb', 2);
tab4 = add_line(add_line(tab4, 'z', 'tb', 3), 't', 'tb', 4);
r = sim(tab4, 'Solver', 'ode1', 'FixedStep', 0.25, 'StopTime', 1);
assert(max(abs(r.yout(:)' - (1 + 9 * (0:0.25:1)))) < 1e-12, ...
       'une table a quatre dimensions suit ses deux entrees variables');
% la table directe à trois dimensions
dir3 = new_system('dir3');
dir3 = add_block(dir3, 'constant', 'a', 'Value', 1);
dir3 = add_block(dir3, 'constant', 'b', 'Value', 2);
dir3 = add_block(dir3, 'constant', 'c', 'Value', 9);
dir3 = add_block(dir3, 'simulink/Lookup Tables/Direct Lookup Table (n-D)', 'dl', ...
                 'NumberOfTableDimensions', 3, 'Table', T3);
dir3 = add_line(add_block(dir3, 'outport', 'y'), 'dl', 'y');
dir3 = add_line(add_line(add_line(dir3, 'a', 'dl', 1), 'b', 'dl', 2), 'c', 'dl', 3);
r = sim(dir3, 1);
assert(r.yout(end) == T3(2, 3, 4), 'la table directe ramene l''indice 9 a la derniere page');
r = sim(set_param(dir3, 'c', 'Value', 1), 1);
assert(r.yout(end) == T3(2, 3, 2), 'la table directe compte a partir de 0');
% les erreurs qu'un utilisateur rencontre, chacune nommant le bloc fautif
casTables = {
    @() sim(set_param(tab3, 'tb', 'BreakpointsForDimension2', [0 1]), 1), ...
        'Simulink:blocks:LookupTableSizeMismatch', 'tab3/tb'
    @() sim(set_param(tab3, 'tb', 'BreakpointsForDimension3', [0 2 1 3]), 1), ...
        'Simulink:blocks:LookupBreakpointsNotMonotonic', 'tab3/tb'
    @() sim(set_param(tab3, 'tb', 'NumberOfTableDimensions', 7), 1), ...
        'Simulink:blocks:LookupNDDimensions', 'tab3/tb'
    @() sim(set_param(tab4, 'tb', 'NumberOfTableDimensions', 3), 1), ...
        'Simulink:blocks:LookupTableSizeMismatch', 'tab4/tb'
    @() sim(set_param(dir3, 'dl', 'NumberOfTableDimensions', 7), 1), ...
        'Simulink:blocks:LookupNDDimensions', 'dir3/dl'
    @() sim(set_param(set_param(dir3, 'dl', 'NumberOfTableDimensions', 4), ...
                      'dl', 'Table', ones(2, 2, 2, 2, 2)), 1), ...
        'Simulink:blocks:LookupTableSizeMismatch', 'dir3/dl'
    };
for kE = 1:size(casTables, 1)
    vu = '';
    message = '';
    try
        casTables{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casTables{kE, 2}) && ~isempty(strfind(message, casTables{kE, 3})), ...
           sprintf('tables n-D, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casTables{kE, 2}, vu, message));
end
fprintf('tables n-D : %d cas d''erreur verifies\n', size(casTables, 1));

%% ------------------------ 41. Suite de la bibliothèque : logique, tables, vérification
% Les détections de front, les opérations bit à bit, les tables qui
% arrivent par les signaux, la pré-recherche, les transmittances
% discrètes de la bibliothèque, l'Index Vector et les blocs de
% vérification, avec les erreurs qu'un utilisateur de Simulink rencontre.
fronts = new_system('fronts');
fronts = add_block(fronts, 'simulink/Sources/Sine Wave', 's');
nomsFronts = {'Detect Rise Positive', 'Detect Rise Nonnegative', 'Detect Fall Negative', ...
              'Detect Fall Nonpositive'};
for kF = 1:4
    fronts = add_block(fronts, ['simulink/Logic and Bit Operations/' nomsFronts{kF}], ...
                       sprintf('f%d', kF));
    fronts = add_block(fronts, 'outport', sprintf('y%d', kF));
    fronts = add_line(add_line(fronts, 's', sprintf('f%d', kF)), sprintf('f%d', kF), ...
                      sprintf('y%d', kF));
end
r = sim(fronts, 'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 10);
u = sin(r.tout);
avant = [-Inf; u(1:end - 1)];
attendus = [(u > 0) & ~([0; u(1:end - 1)] > 0), (u >= 0) & ~([-1; u(1:end - 1)] >= 0), ...
            (u < 0) & ~([0; u(1:end - 1)] < 0), (u <= 0) & ~([1; u(1:end - 1)] <= 0)];
assert(isequal(r.yout ~= 0, attendus), 'les quatre detections de front, vinit nul');
assert(isequal(find(r.yout(:, 1))', find((u > 0) & ~([0; u(1:end - 1)] > 0))'), ...
       'Detect Rise Positive : les instants ou le sinus devient positif');
constante = new_system('constante');
constante = add_block(constante, 'constant', 'c', 'Value', 3);
constante = add_block(constante, 'simulink/Logic and Bit Operations/Detect Rise Positive', 'rp');
constante = add_line(add_line(add_block(constante, 'outport', 'y'), 'c', 'rp'), 'rp', 'y');
r = sim(constante, 'Solver', 'ode1', 'FixedStep', 0.25, 'StopTime', 1);
assert(isequal(r.yout', [1 0 0 0 0]), 'un front se detecte une fois, meme sur une constante');
% le test d'intervalle dont les bornes sont des signaux
itd = new_system('itd');
itd = add_block(itd, 'constant', 'up', 'Value', 2);
itd = add_block(itd, 'constant', 'u', 'Value', [1 2 3]);
itd = add_block(itd, 'constant', 'lo', 'Value', 1);
itd = add_block(itd, 'simulink/Logic and Bit Operations/Interval Test Dynamic', 'it');
itd = add_line(add_block(itd, 'outport', 'y'), 'it', 'y');
itd = add_line(add_line(add_line(itd, 'up', 'it', 1), 'u', 'it', 2), 'lo', 'it', 3);
r = sim(itd, 1);
assert(isequal(r.yout(end, :), [1 1 0]), 'Interval Test Dynamic, bornes comprises');
r = sim(set_param(itd, 'it', 'IntervalClosedLeft', 'off'), 1);
assert(isequal(r.yout(end, :), [0 1 0]), 'Interval Test Dynamic, borne basse exclue');
% les bits d'un entier
bits = new_system('bits');
bits = add_block(bits, 'constant', 'c', 'Value', 'uint8(12)');
bits = add_block(bits, 'simulink/Logic and Bit Operations/Bitwise Operator', 'bw', 'BitMask', 10);
bits = add_block(bits, 'simulink/Logic and Bit Operations/Bit Set', 'bs', 'iBit', 0);
bits = add_block(bits, 'simulink/Logic and Bit Operations/Bit Clear', 'bc', 'iBit', 2);
bits = add_block(bits, 'simulink/Logic and Bit Operations/Shift Arithmetic', 'sa', ...
                 'BitShiftNumber', 2);
for nomBit = {'bw', 'bs', 'bc', 'sa'}
    bits = add_block(bits, 'outport', ['o' nomBit{1}]);
    bits = add_line(add_line(bits, 'c', nomBit{1}), nomBit{1}, ['o' nomBit{1}]);
end
r = sim(bits, 1);
assert(isequal(r.yout(end, :), [8 13 8 3]) && isa(r.yout, 'uint8'), ...
       'AND avec le masque, Bit Set, Bit Clear, decalage a droite, en uint8');
r = sim(set_param(set_param(bits, 'bw', 'logicop', 'XOR'), 'sa', 'BitShiftDirection', 'Left'), 1);
assert(isequal(r.yout(end, :), [6 13 8 48]), 'XOR avec le masque, decalage a gauche');
signe = new_system('signe');
signe = add_block(signe, 'constant', 'c', 'Value', 'int8(-7)');
signe = add_block(signe, 'simulink/Logic and Bit Operations/Shift Arithmetic', 'sa', ...
                  'BitShiftNumber', 1);
signe = add_line(add_line(add_block(signe, 'outport', 'y'), 'c', 'sa'), 'sa', 'y');
r = sim(signe, 1);
assert(r.yout(end) == -4, 'le decalage arithmetique a droite garde le signe');
entre = new_system('entre');
entre = add_block(entre, 'constant', 'a', 'Value', 'uint8(12)');
entre = add_block(entre, 'constant', 'b', 'Value', 'uint8(10)');
entre = add_block(entre, 'simulink/Logic and Bit Operations/Bitwise Operator', 'bw', ...
                  'UseBitMask', 'off', 'NumInputPorts', 2, 'logicop', 'NOR');
entre = add_line(add_line(add_line(add_block(entre, 'outport', 'y'), 'a', 'bw', 1), ...
                          'b', 'bw', 2), 'bw', 'y');
r = sim(entre, 1);
assert(r.yout(end) == 241, 'NOR entre deux entrees : bitcmp(12 | 10) en uint8');
% une MATLAB Function reçoit ses entrées dans leur type
typee = new_system('typee');
typee = add_block(typee, 'constant', 'c', 'Value', 'int8(100)');
typee = add_block(typee, 'matlabfunction', 'f', 'Script', ...
                  sprintf('function y = fcn(u)\ny = u + u;\n'));
typee = add_line(add_line(add_block(typee, 'outport', 'y'), 'c', 'f'), 'f', 'y');
r = sim(typee, 1);
assert(r.yout(end) == 127, 'un int8 calcule en int8 dans la fonction : il sature');
% Trente simulations d'un modèle à MATLAB Function ne font pas grossir la
% mémoire : l'arbre des fichiers relus après rehash se libère.
if exist('/proc/self/status', 'file') == 2
    memoireSim = @() str2double(regexp(fileread('/proc/self/status'), 'VmRSS:\s*(\d+)', ...
                                       'tokens', 'once'));
    sim(typee, 1);
    avantSim = memoireSim();
    for kSim = 1:30
        sim(typee, 1);
    end
    assert(memoireSim() - avantSim < 60000, 'la memoire ne croit pas de simulation en simulation');
end
% la sinusoïde de l'entrée, les dimensions
fonction = new_system('fonction');
fonction = add_block(fonction, 'clock', 't');
fonction = add_block(fonction, 'simulink/Math Operations/Sine Wave Function', 'sw', ...
                     'Amplitude', 2, 'Bias', 1, 'Frequency', 3, 'Phase', 0.5);
fonction = add_line(add_line(add_block(fonction, 'outport', 'y'), 't', 'sw'), 'sw', 'y');
r = sim(fonction, 'Solver', 'ode1', 'FixedStep', 0.25, 'StopTime', 1);
assert(max(abs(r.yout - (2 * sin(3 * r.tout + 0.5) + 1))) < 1e-12, 'Sine Wave Function');
permutee = new_system('permutee');
permutee = add_block(permutee, 'constant', 'c', 'Value', [1 2; 3 4; 5 6]);
permutee = add_block(permutee, 'simulink/Math Operations/Permute Dimensions', 'pd');
permutee = add_block(permutee, 'simulink/Math Operations/Squeeze', 'sq');
permutee = add_line(add_line(add_block(permutee, 'outport', 'y'), 'c', 'pd'), 'pd', 'sq');
permutee = add_line(permutee, 'sq', 'y');
r = sim(permutee, 1);
assert(isequal(r.yout(end, :), [1 2 3 4 5 6]), ...
       'Permute Dimensions transpose ; yout range la matrice colonne apres colonne');
racines = new_system('racines');
racines = add_block(racines, 'constant', 'c', 'Value', -4);
racines = add_block(racines, 'simulink/Math Operations/Signed Sqrt', 'ss');
racines = add_block(racines, 'constant', 'd', 'Value', 4);
racines = add_block(racines, 'simulink/Math Operations/Reciprocal Sqrt', 'rs');
racines = add_line(add_line(add_block(racines, 'outport', 'y1'), 'c', 'ss'), 'ss', 'y1');
racines = add_line(add_line(add_block(racines, 'outport', 'y2'), 'd', 'rs'), 'rs', 'y2');
r = sim(racines, 1);
assert(isequal(r.yout(end, :), [-2 0.5]), 'Signed Sqrt et Reciprocal Sqrt');
% la table qui arrive par les signaux
dynamique = new_system('dynamique');
dynamique = add_block(dynamique, 'constant', 'x', 'Value', [0.5 2.5 9]);
dynamique = add_block(dynamique, 'constant', 'xd', 'Value', [0 1 2 3]);
dynamique = add_block(dynamique, 'constant', 'yd', 'Value', [0 10 20 40]);
dynamique = add_block(dynamique, 'simulink/Lookup Tables/Lookup Table Dynamic', 'ltd');
dynamique = add_line(add_block(dynamique, 'outport', 'y'), 'ltd', 'y');
dynamique = add_line(add_line(add_line(dynamique, 'x', 'ltd', 1), 'xd', 'ltd', 2), ...
                     'yd', 'ltd', 3);
methodesDyn = {'Interpolation-Use End Values', [5 30 40]; ...
               'Interpolation-Extrapolation', [5 30 160]; 'Use Input Nearest', [10 40 40]; ...
               'Use Input Below', [0 20 40]; 'Use Input Above', [10 40 40]};
for kM = 1:size(methodesDyn, 1)
    r = sim(set_param(dynamique, 'ltd', 'LookUpMeth', methodesDyn{kM, 1}), 1);
    assert(isequal(r.yout(end, :), methodesDyn{kM, 2}), ['Lookup Table Dynamic : ' ...
                                                           methodesDyn{kM, 1}]);
end
% la pré-recherche et l'interpolation qui la suit
pre = new_system('pre');
pre = add_block(pre, 'constant', 'u', 'Value', [5 15 25 110 200]);
pre = add_block(pre, 'simulink/Lookup Tables/Prelookup', 'pl');
pre = add_block(pre, 'outport', 'k');
pre = add_block(pre, 'outport', 'f');
pre = add_line(add_line(add_line(pre, 'u', 'pl'), 'pl/1', 'k'), 'pl/2', 'f');
r = sim(pre, 1);
assert(isequal(r.yout(end, :), [0 0 1 9 9 0 0.5 0.5 1 1]), 'Prelookup, Clip');
r = sim(set_param(pre, 'pl', 'ExtrapMethod', 'Linear'), 1);
assert(isequal(r.yout(end, :), [0 0 1 9 9 -0.5 0.5 0.5 1 10]), 'Prelookup, Linear');
r = sim(set_param(pre, 'pl', 'UseLastBreakpoint', 'on'), 1);
assert(isequal(r.yout(end, :), [0 0 1 10 10 0 0.5 0.5 0 0]), 'Prelookup, dernier point');
chaine = new_system('chaine');
chaine = add_block(chaine, 'constant', 'a', 'Value', 25);
chaine = add_block(chaine, 'constant', 'b', 'Value', 42);
chaine = add_block(chaine, 'simulink/Lookup Tables/Prelookup', 'p1');
chaine = add_block(chaine, 'simulink/Lookup Tables/Prelookup', 'p2');
chaine = add_block(chaine, 'simulink/Lookup Tables/Interpolation Using Prelookup', 'it');
chaine = add_line(add_line(chaine, 'a', 'p1'), 'b', 'p2');
chaine = add_line(add_line(chaine, 'p1/1', 'it/1'), 'p1/2', 'it/2');
chaine = add_line(add_line(chaine, 'p2/1', 'it/3'), 'p2/2', 'it/4');
chaine = add_line(add_block(chaine, 'outport', 'y'), 'it', 'y');
r = sim(chaine, 1);
tablePre = sqrt((1:11)' * (1:11));
assert(abs(r.yout(end) - interp2(10:10:110, 10:10:110, tablePre, 42, 25)) < 1e-12, ...
       'Prelookup puis Interpolation Using Prelookup : l''interpolation bilineaire');
sinCos = new_system('sinCos');
sinCos = add_block(sinCos, 'constant', 'u', 'Value', [0 0.1 0.25 0.6 0.9]);
sinCos = add_block(sinCos, 'simulink/Lookup Tables/Sine, Cosine', 's', ...
                   'Formula', 'sin(2*pi*u) and cos(2*pi*u)');
sinCos = add_block(sinCos, 'outport', 'ys');
sinCos = add_block(sinCos, 'outport', 'yc');
sinCos = add_line(add_line(add_line(sinCos, 'u', 's'), 's/1', 'ys'), 's/2', 'yc');
r = sim(sinCos, 1);
u = [0 0.1 0.25 0.6 0.9];
assert(max(abs(r.yout(end, :) - [sin(2 * pi * u), cos(2 * pi * u)])) < 1e-3, ...
       'Sine, Cosine : la table d''un quart d''onde');
% les transmittances discrètes de la bibliothèque
discret = new_system('discret');
discret = add_block(discret, 'simulink/Sources/Step', 'e', 'Time', 0);
discret = add_block(discret, 'zoh', 'z', 'SampleTime', 1);
discret = add_block(discret, 'simulink/Discrete/Discrete FIR Filter', 'fir', ...
                    'Coefficients', [0.5 0.3 0.2], 'SampleTime', 1);
discret = add_block(discret, 'simulink/Discrete/Transfer Fcn First Order', 'p1');
discret = add_block(discret, 'simulink/Discrete/Transfer Fcn Lead or Lag', 'll');
discret = add_block(discret, 'simulink/Discrete/Transfer Fcn Real Zero', 'rz');
discret = add_line(discret, 'e', 'z');
for nomD = {'fir', 'p1', 'll', 'rz'}
    discret = add_block(discret, 'outport', ['o' nomD{1}]);
    discret = add_line(add_line(discret, 'z', nomD{1}), nomD{1}, ['o' nomD{1}]);
end
r = sim(discret, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 4);
un = ones(5, 1);
attendu = [filter([0.5 0.3 0.2], 1, un), filter(0.05 * [1 0], [1 -0.95], un), ...
           filter([1 -0.75], [1 -0.95], un), filter([1 -0.75], 1, un)];
assert(max(abs(r.yout(:) - attendu(:))) < 1e-12, ...
       'Discrete FIR Filter, Transfer Fcn First Order, Lead or Lag, Real Zero');
r = sim(set_param(discret, 'fir', 'InitialStates', [1 2]), 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 1, 'StopTime', 4);
assert(max(abs(r.yout(:, 1)' - [1.2 1 1 1 1])) < 1e-12, 'les etats de depart du FIR');
% Index Vector, Environment Controller, Integrator Limited
choix = new_system('choix');
choix = add_block(choix, 'constant', 'k', 'Value', 2);
choix = add_block(choix, 'constant', 'v', 'Value', [10 20 30]);
choix = add_block(choix, 'simulink/Signal Routing/Index Vector', 'ix');
choix = add_block(choix, 'simulink/Signal Routing/Environment Controller', 'ec');
choix = add_line(add_line(choix, 'k', 'ix', 1), 'v', 'ix', 2);
choix = add_line(add_line(choix, 'ix', 'ec', 1), 'v', 'ec', 2);
choix = add_line(add_block(choix, 'outport', 'y'), 'ec', 'y');
r = sim(choix, 1);
assert(r.yout(end) == 30, 'Index Vector compte a partir de zero ; Environment Controller rend Sim');
borne = new_system('borne');
borne = add_block(borne, 'constant', 'c', 'Value', 1);
borne = add_block(borne, 'simulink/Continuous/Integrator Limited', 'i');
borne = add_line(add_line(add_block(borne, 'outport', 'y'), 'c', 'i'), 'i', 'y');
r = sim(borne, 3);
assert(abs(r.yout(end) - 1) < 1e-9 && strcmp(get_param(borne, 'i', 'LimitOutput'), 'on'), ...
       'Integrator Limited : borne entre 0 et 1 d''avance');
% les blocs de vérification
verif = new_system('verif');
verif = add_block(verif, 'ramp', 'r', 'Slope', 1);
verif = add_block(verif, 'simulink/Model Verification/Check Static Range', 'cs', ...
                  'min', 0, 'max', 2.5);
verif = add_line(verif, 'r', 'cs');
r = sim(set_param(verif, 'cs', 'max', 10), 'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 5);
assert(numel(r.tout) == 11, 'dans ses bornes, le controle laisse passer');
etatAvertissement = warning('off', 'Simulink:blocks:AssertionAssert');
avertir = sim(set_param(verif, 'cs', 'stopWhenAssertionFail', 'off'), 'Solver', 'ode1', ...
              'FixedStep', 0.5, 'StopTime', 5);
warning(etatAvertissement);
assert(numel(avertir.tout) == 11, 'stopWhenAssertionFail off : un avertissement, pas un arret');
ecart = new_system('ecart');
ecart = add_block(ecart, 'ramp', 'r', 'Slope', 1);
ecart = add_block(ecart, 'simulink/Model Verification/Check Static Gap', 'cg', 'min', 1, 'max', 2);
ecart = add_line(ecart, 'r', 'cg');
bornes = new_system('bornes');
bornes = add_block(bornes, 'ramp', 'r', 'Slope', -1);
bornes = add_block(bornes, 'simulink/Model Verification/Check Static Lower Bound', 'lo', 'min', -2);
bornes = add_block(bornes, 'simulink/Model Verification/Check Static Upper Bound', 'hi', 'max', 0);
bornes = add_line(add_line(bornes, 'r', 'lo'), 'r', 'hi');
dyn = new_system('dyn');
dyn = add_block(dyn, 'constant', 'haut', 'Value', 3);
dyn = add_block(dyn, 'ramp', 'sig', 'Slope', 1, 'InitialOutput', 0.5);
dyn = add_block(dyn, 'constant', 'bas', 'Value', 0);
dyn = add_block(dyn, 'simulink/Model Verification/Check Dynamic Range', 'cr');
dyn = add_line(add_line(add_line(dyn, 'haut', 'cr', 1), 'sig', 'cr', 2), 'bas', 'cr', 3);
dynEcart = set_param(set_param(replace_block(dyn, 'checkdynamicrange', 'checkdynamicgap'), ...
                               'haut', 'Value', 3), 'bas', 'Value', 2);
dynBas = new_system('dynBas');
dynBas = add_block(dynBas, 'constant', 'bas', 'Value', 1);
dynBas = add_block(dynBas, 'ramp', 'sig', 'Slope', -1, 'InitialOutput', 2);
dynBas = add_block(dynBas, 'simulink/Model Verification/Check Dynamic Lower Bound', 'cl');
dynBas = add_line(add_line(dynBas, 'bas', 'cl', 1), 'sig', 'cl', 2);
dynLarge = add_line(delete_line(add_block(dynBas, 'constant', 'l3', 'Value', [1 2 3]), ...
                                'bas', 'cl', 1), 'l3', 'cl', 1);
dynLarge = set_param(dynLarge, 'sig', 'InitialOutput', [4 5]);
reglage = {'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 5};
casVerif = {
    @() sim(verif, reglage{:}), 'Simulink:blocks:AssertionAssert', 'verif/cs'' a t = 3'
    @() sim(set_param(verif, 'cs', 'max_included', 'off', 'max', 2), reglage{:}), ...
        'Simulink:blocks:AssertionAssert', 'verif/cs'' a t = 2'
    @() sim(set_param(verif, 'cs', 'min', 3, 'max', 1), 1), ...
        'Simulink:blocks:CheckBoundsOrder', 'verif/cs'
    @() sim(ecart, reglage{:}), 'Simulink:blocks:AssertionAssert', 'ecart/cg'' a t = 1.5'
    @() sim(bornes, reglage{:}), 'Simulink:blocks:AssertionAssert', 'bornes/lo'' a t = 2.5'
    @() sim(dyn, reglage{:}), 'Simulink:blocks:AssertionAssert', 'dyn/cr'' a t = 2.5'
    @() sim(dynEcart, reglage{:}), 'Simulink:blocks:AssertionAssert', 'dyn/cr'' a t = 2'
    @() sim(dynBas, 'Solver', 'ode1', 'FixedStep', 0.25, 'StopTime', 5), ...
        'Simulink:blocks:AssertionAssert', 'dynBas/cl'' a t = 1'
    @() sim(dynLarge, 1), 'Simulink:Engine:DimensionMismatch', 'min est de dimension 3'
    @() sim(set_param(bits, 'c', 'Value', 12), 1), ...
        'Simulink:DataType:BitOperationInputType', 'bits/bw'
    @() sim(set_param(bits, 'bs', 'iBit', 40), 1), 'Simulink:blocks:BitIndex', 'bits/bs'
    @() sim(set_param(bits, 'bs', 'iBit', 9), 1), 'Simulink:blocks:BitIndex', 'bits/bs'
    @() sim(set_param(entre, 'bw', 'NumInputPorts', 1), 1), ...
        'Simulink:blocks:BitwiseOperatorInputs', 'entre/bw'
    @() sim(set_param(signe, 'sa', 'BinPtShiftNumber', 2), 1), ...
        'Simulink:blocks:ShiftArithmeticBinaryPoint', 'signe/sa'
    @() sim(set_param(fonction, 'sw', 'SineType', 'Sample based'), 1), ...
        'Simulink:blocks:SineWaveFunctionSampleBased', 'fonction/sw'
    @() sim(set_param(permutee, 'pd', 'Order', [1 1]), 1), ...
        'Simulink:blocks:PermuteDimensionsOrder', 'permutee/pd'
    @() sim(set_param(dynamique, 'xd', 'Value', [0 2 1 3]), 1), ...
        'Simulink:blocks:LookupTableDynamicBreakpoints', 'dynamique/ltd'
    @() sim(set_param(dynamique, 'xd', 'Value', [0 1 2]), 1), ...
        'Simulink:blocks:LookupTableDynamicSize', 'dynamique/ltd'
    @() sim(set_param(pre, 'pl', 'BreakpointsData', [3 1 2]), 1), ...
        'Simulink:blocks:PrelookupBreakpoints', 'pre/pl'
    @() sim(set_param(chaine, 'it', 'NumberOfTableDimensions', 7), 1), ...
        'Simulink:blocks:LookupNDDimensions', 'chaine/it'
    @() sim(set_param(chaine, 'it', 'Table', ones(11, 11, 2)), 1), ...
        'Simulink:blocks:LookupTableSizeMismatch', 'chaine/it'
    @() sim(set_param(sinCos, 's', 'NumDataPoints', 1), 1), ...
        'Simulink:blocks:SineCosineTableSize', 'sinCos/s'
    @() sim(set_param(discret, 'fir', 'InitialStates', [1 2 3]), 1), ...
        'Simulink:blocks:DiscreteFirInitialStates', 'discret/fir'
    @() sim(set_param(choix, 'k', 'Value', 3), 1), ...
        'Simulink:blocks:MultiPortSwitchIndexOutOfRange', 'choix/ix'
    };
for kE = 1:size(casVerif, 1)
    vu = '';
    message = '';
    try
        evalc('casVerif{kE, 1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casVerif{kE, 2}) && ~isempty(strfind(message, casVerif{kE, 3})), ...
           sprintf('bibliotheque, cas %d : %s attendu, %s rendu (%s)', kE, casVerif{kE, 2}, ...
                   vu, message));
end
fprintf('suite de la bibliotheque : %d cas d''erreur verifies\n', size(casVerif, 1));

%% --------------------------------------- 42. Le PID de Simulink en entier
% Controller et Form choisissent les parties et leur forme ; les
% conditions initiales portent sur les états de Simulink ; le PID discret
% intègre et filtre par la méthode qu'on lui choisit ; bornée, la sortie
% se protège de l'emballement par recalcul ou par blocage ; une entrée
% remet les états, d'autres donnent leurs conditions initiales.
pid = new_system('pid');
pid = add_block(pid, 'constant', 'e', 'Value', 1);
pid = add_block(pid, 'pidcontroller', 'k', 'P', 2, 'I', 3, 'D', 0, ...
                'InitialConditionForIntegrator', 5);
pid = add_line(add_line(add_block(pid, 'outport', 'y'), 'e', 'k'), 'k', 'y');
r = sim(pid, 1, 1e-3);
assert(abs(r.yout(end) - (2 + 5 + 3)) < 1e-9, 'la condition initiale est celle de l''integrale');
r = sim(set_param(pid, 'k', 'Form', 'Ideal'), 1, 1e-3);
assert(abs(r.yout(end) - (2 + 5 + 2 * 3)) < 1e-9, 'la forme ideale : P (1 + I/s + ...)');
r = sim(set_param(pid, 'k', 'Controller', 'P'), 1, 1e-3);
assert(abs(r.yout(end) - 2) < 1e-12, 'Controller P : ni integrale ni derivee');
r = sim(set_param(set_param(pid, 'k', 'D', 0.1), 'k', 'Controller', 'PD'), 0.5, 1e-3);
assert(abs(r.yout(1) - (2 + 0.1 * 100)) < 1e-9 && abs(r.yout(end) - 2) < 1e-3, ...
       'Controller PD : la derivee filtree d''une constante s''eteint');
pidDefaut = add_block(new_system('pidDefaut'), 'simulink/Continuous/PID Controller', 'k');
assert(get_param(pidDefaut, 'k', 'I') == 1, 'I vaut 1 par defaut, comme dans Simulink');
% le PID discret, par les trois méthodes
pidD = new_system('pidD');
pidD = add_block(pidD, 'constant', 'e', 'Value', 1);
pidD = add_block(pidD, 'simulink/Discrete/Discrete PID Controller', 'k', 'P', 2, 'I', 3, ...
                 'D', 0, 'SampleTime', 0.1);
pidD = add_line(add_line(add_block(pidD, 'outport', 'y'), 'e', 'k'), 'k', 'y');
reglageD = {'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1, 'StopTime', 0.5};
attendus = {'Forward Euler', 2 + 0.3 * (0:5); 'Backward Euler', 2 + 0.3 * (1:6); ...
            'Trapezoidal', 2.15 + 0.3 * (0:5)};
for kM = 1:3
    r = sim(set_param(pidD, 'k', 'IntegratorMethod', attendus{kM, 1}), reglageD{:});
    assert(max(abs(r.yout' - attendus{kM, 2})) < 1e-12, ['PID discret : ' attendus{kM, 1}]);
end
assert(strcmp(get_param(pidD, 'k', 'TimeDomain'), 'Discrete-time'), ...
       'Discrete PID Controller est regle en Discrete-time');
r = sim(set_param(pidD, 'k', 'P', 0, 'I', 0, 'D', 1, 'N', 5), reglageD{:});
assert(max(abs(r.yout' - 5 * 0.5 .^ (0:5))) < 1e-12, 'la derivee filtree discrete, Forward Euler');
r = sim(set_param(pidD, 'k', 'P', 0, 'I', 0, 'D', 1, 'UseFilter', 'off'), reglageD{:});
assert(all(r.yout == 0), 'sans filtre, la difference d''une constante est nulle');
r = sim(set_param(pidD, 'k', 'LimitOutput', 'on', 'UpperSaturationLimit', 3), ...
        'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1, 'StopTime', 1);
assert(max(r.yout) == 3 && r.yout(end) == 3, 'la sortie bornee');
% l'emballement : l'erreur s'inverse à t = 1
emb = new_system('emb');
emb = add_block(emb, 'step', 'e', 'Time', 1, 'Before', 1, 'After', -1);
emb = add_block(emb, 'pidcontroller', 'k', 'P', 1, 'I', 2, 'D', 0, 'LimitOutput', 'on', ...
                'UpperSaturationLimit', 2);
emb = add_line(add_line(add_block(emb, 'outport', 'y'), 'e', 'k'), 'k', 'y');
reglageE = {'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 3};
r = sim(emb, reglageE{:});
assert(abs(r.yout(end) - (-3)) < 0.02, 'sans protection, l''integrale emballee retarde la sortie');
r = sim(set_param(emb, 'k', 'AntiWindupMode', 'clamping'), reglageE{:});
assert(abs(r.yout(end) - (-4)) < 0.02, 'le blocage arrete l''integrale a la borne');
r = sim(set_param(emb, 'k', 'AntiWindupMode', 'back-calculation', 'Kb', 1), reglageE{:});
assert(r.yout(end) < -3.1 && r.yout(end) > -4, 'le recalcul ramene l''integrale vers la borne');
rD = sim(set_param(set_param(emb, 'k', 'TimeDomain', 'Discrete-time', 'SampleTime', 0.01), ...
                   'k', 'AntiWindupMode', 'clamping'), reglageE{:});
assert(abs(rD.yout(end) - (-4)) < 0.05, 'le blocage du PID discret');
% la remise et les conditions initiales par des entrées
remise = new_system('remise');
remise = add_block(remise, 'constant', 'e', 'Value', 1);
remise = add_block(remise, 'step', 'r', 'Time', 0.5);
remise = add_block(remise, 'constant', 'ci', 'Value', 10);
remise = add_block(remise, 'pidcontroller', 'k', 'P', 0, 'I', 1, 'Controller', 'PI', ...
                   'ExternalReset', 'rising', 'InitialConditionSource', 'external');
remise = add_line(add_line(add_line(remise, 'e', 'k', 1), 'r', 'k', 2), 'ci', 'k', 3);
remise = add_line(add_block(remise, 'outport', 'y'), 'k', 'y');
[ne, ~] = matlibre_sl_ports(remise.blocs{4});
assert(ne == 3, 'u, Reset et I0 : un PI n''a pas d''entree D0');
for domaine = {'Continuous-time', 'Discrete-time'}
    r = sim(set_param(remise, 'k', 'TimeDomain', domaine{1}, 'SampleTime', 0.01), ...
            'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 1);
    auPoint = @(t) r.yout(find(r.tout >= t - 1e-9, 1));
    assert(abs(auPoint(0) - 10) < 1e-9 && abs(auPoint(0.4) - 10.4) < 0.02 && ...
           abs(auPoint(0.6) - 10.1) < 0.02 && abs(r.yout(end) - 10.5) < 0.02, ...
           ['la remise sur front montant, ' domaine{1}]);
end
brute = new_system('brute');
brute = add_block(brute, 'ramp', 'e', 'Slope', 3);
brute = add_block(brute, 'pidcontroller', 'k', 'P', 0, 'I', 0, 'D', 2, 'UseFilter', 'off');
brute = add_line(add_line(add_block(brute, 'outport', 'y'), 'e', 'k'), 'k', 'y');
r = sim(brute, 'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 1);
assert(abs(r.yout(end) - 6) < 1e-9, 'la derivee non filtree d''une rampe');
% le PID avancé se relit comme il s'écrit
dossierPid = tempname();
mkdir(dossierPid);
save_system(remise, fullfile(dossierPid, 'remise.slx'));
relu = sim(load_system(fullfile(dossierPid, 'remise.slx')), 'Solver', 'ode4', ...
           'FixedStep', 0.01, 'StopTime', 1);
assert(abs(relu.yout(end) - 10.5) < 0.02, 'le PID a remise externe passe par le .slx');
rmdir(dossierPid, 's');
% Rate Limiter Dynamic, Weighted Sample Time Math, MinMax Running Resettable
pente = new_system('pente');
pente = add_block(pente, 'constant', 'up', 'Value', 2);
pente = add_block(pente, 'step', 'u', 'Time', 0.5, 'After', 10);
pente = add_block(pente, 'constant', 'lo', 'Value', -1);
pente = add_block(pente, 'zoh', 'z', 'SampleTime', 0.1);
pente = add_block(pente, 'simulink/Discontinuities/Rate Limiter Dynamic', 'rl');
pente = add_line(add_line(pente, 'u', 'z'), 'z', 'rl', 2);
pente = add_line(add_line(pente, 'up', 'rl', 1), 'lo', 'rl', 3);
pente = add_line(add_block(pente, 'outport', 'y'), 'rl', 'y');
r = sim(pente, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1, 'StopTime', 1);
assert(max(abs(r.yout' - [0 0 0 0 0 0.2 0.4 0.6 0.8 1 1.2])) < 1e-12, ...
       'Rate Limiter Dynamic : au plus up Ts par pas');
poids = new_system('poids');
poids = add_block(poids, 'constant', 'c', 'Value', 3);
poids = add_block(poids, 'zoh', 'z', 'SampleTime', 0.5);
poids = add_block(poids, 'simulink/Math Operations/Weighted Sample Time Math', 'ws', ...
                  'TsampMathOp', '*', 'weightValue', 2);
poids = add_line(add_line(poids, 'c', 'z'), 'z', 'ws');
poids = add_line(add_block(poids, 'outport', 'y'), 'ws', 'y');
r = sim(poids, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.5, 'StopTime', 1);
assert(all(r.yout == 3), 'Weighted Sample Time Math : u (w Ts), Ts la periode heritee');
r = sim(set_param(poids, 'ws', 'TsampMathOp', '1/Ts Only'), 'Solver', ...
        'FixedStepDiscrete', 'FixedStep', 0.5, 'StopTime', 1);
assert(all(r.yout == 4), 'Weighted Sample Time Math : w / Ts');
courant = new_system('courant');
courant = add_block(courant, 'simulink/Sources/Sine Wave', 's');
courant = add_block(courant, 'pulsegenerator', 'R', 'Period', 4, 'PulseWidth', 10, ...
                    'PhaseDelay', 3);
courant = add_block(courant, 'simulink/Math Operations/MinMax Running Resettable', 'm', ...
                    'Function', 'max');
courant = add_line(add_line(courant, 's', 'm', 1), 'R', 'm', 2);
courant = add_line(add_block(courant, 'outport', 'y'), 'm', 'y');
r = sim(courant, 'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 5);
attendu = zeros(size(r.tout));
m = 0;
for kT = 1:numel(r.tout)
    if r.tout(kT) >= 3 && r.tout(kT) < 3.4
        m = 0;
    end
    m = max(sin(r.tout(kT)), m);
    attendu(kT) = m;
end
assert(max(abs(r.yout - attendu)) < 1e-12, 'MinMax Running Resettable : le maximum couru, remis par R');
casPid = {
    @() sim(set_param(pid, 'k', 'N', 0), 1), 'Simulink:blocks:PIDFilterCoefficientNotPositive', 'pid/k'
    @() sim(set_param(pidD, 'k', 'N', -1, 'D', 1), 1), ...
        'Simulink:blocks:PIDFilterCoefficientNotPositive', 'pidD/k'
    @() sim(set_param(pidD, 'k', 'LimitOutput', 'on', 'UpperSaturationLimit', -1, ...
                      'LowerSaturationLimit', 1), 1), 'Simulink:blocks:PIDSaturationLimits', 'pidD/k'
    @() sim(set_param(pidD, 'k', 'SampleTime', 0), 1), ...
        'Simulink:SampleTime:DiscreteBlockContinuous', 'pidD/k'
    @() sim(set_param(pid, 'k', 'Controller', 'PIDF'), 1), 'Simulink:Parameters:InvalidValue', 'PID, PI, PD, P, I'
    };
for kE = 1:size(casPid, 1)
    vu = '';
    message = '';
    try
        evalc('casPid{kE, 1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casPid{kE, 2}) && ~isempty(strfind(message, casPid{kE, 3})), ...
           sprintf('PID, cas %d : %s attendu, %s rendu (%s)', kE, casPid{kE, 2}, vu, message));
end
fprintf('PID et blocs de periode : %d cas d''erreur verifies\n', size(casPid, 1));

%% ----------------------------- 43. Discrete-Time Integrator et Delay complets
% L'intégrateur discret se borne, montre sa saturation et son état, se
% remet par une entrée, lit sa condition initiale d'une autre, et accumule
% sans période ; le Delay lit sa longueur d'une entrée, s'active, se remet
% et lit x0. Ni l'un ni l'autre ne devient à transmission directe : dans
% une boucle, il la coupe toujours.
reglageI = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 6};
dti = new_system('dti');
dti = add_block(dti, 'constant', 'c', 'Value', 1);
dti = add_block(dti, 'discreteintegrator', 'i', 'SampleTime', 1, 'LimitOutput', 'on', ...
                'UpperSaturationLimit', 3, 'ShowSaturationPort', 'on', 'ShowStatePort', 'on');
dti = add_line(dti, 'c', 'i');
dti = add_block(add_block(add_block(dti, 'outport', 'y'), 'outport', 's'), 'outport', 'x');
dti = add_line(add_line(add_line(dti, 'i/1', 'y'), 'i/2', 's'), 'i/3', 'x');
r = sim(dti, reglageI{:});
assert(isequal(r.yout', [0 1 2 3 3 3 3; 0 0 0 1 1 1 1; 0 1 2 3 3 3 3]), ...
       'borne, port de saturation et port d''etat');
r = sim(set_param(dti, 'i', 'IntegratorMethod', 'Accumulation: Forward Euler', ...
                  'SampleTime', 0.5, 'LimitOutput', 'off'), 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 0.5, 'StopTime', 3);
assert(isequal(r.yout(:, 1)', 0:6), 'l''accumulation ne multiplie pas par la periode');
r = sim(set_param(dti, 'i', 'IntegratorMethod', 'Integration: Backward Euler', ...
                  'LimitOutput', 'off'), reglageI{:});
assert(isequal(r.yout(:, 1)', 1:7), 'Integration: Backward Euler, nom de Simulink');
remiseI = new_system('remiseI');
remiseI = add_block(remiseI, 'constant', 'c', 'Value', 1);
remiseI = add_block(remiseI, 'step', 'r', 'Time', 3);
remiseI = add_block(remiseI, 'constant', 'x0', 'Value', 10);
remiseI = add_block(remiseI, 'discreteintegrator', 'i', 'SampleTime', 1, ...
                    'ExternalReset', 'rising', 'InitialConditionSource', 'external', ...
                    'ShowStatePort', 'on');
remiseI = add_line(add_line(add_line(remiseI, 'c', 'i', 1), 'r', 'i', 2), 'x0', 'i', 3);
remiseI = add_block(add_block(remiseI, 'outport', 'y'), 'outport', 'x');
remiseI = add_line(add_line(remiseI, 'i/1', 'y'), 'i/2', 'x');
r = sim(remiseI, reglageI{:});
assert(isequal(r.yout', [10 11 12 10 11 12 13; 10 11 12 13 11 12 13]), ...
       'la remise a l''instant meme ; le port d''etat rend l''etat d''avant la remise');
boucleI = new_system('boucleI');
boucleI = add_block(boucleI, 'constant', 'c', 'Value', 1);
boucleI = add_block(boucleI, 'sum', 's', 'Signs', '+-');
boucleI = add_block(boucleI, 'discreteintegrator', 'i', 'SampleTime', 1, 'ExternalReset', 'level');
boucleI = add_block(boucleI, 'constant', 'rz', 'Value', 0);
boucleI = add_line(add_line(boucleI, 'c', 's', 1), 'i', 's', 2);
boucleI = add_line(add_line(boucleI, 's', 'i', 1), 'rz', 'i', 2);
boucleI = add_line(add_block(boucleI, 'outport', 'y'), 'i', 'y');
etatAvertissement = warning('off', 'all');
r = sim(boucleI, reglageI{:});
warning(etatAvertissement);
assert(isequal(r.yout', [0 1 1 1 1 1 1]), 'l''integrateur a remise coupe encore la boucle');
% le Delay
variable = new_system('variable');
variable = add_block(variable, 'clock', 't');
variable = add_block(variable, 'constant', 'L', 'Value', 2);
variable = add_block(variable, 'simulink/Discrete/Variable Integer Delay', 'z', ...
                     'DelayLengthUpperLimit', 5, 'SampleTime', 1, 'InitialCondition', -1);
variable = add_line(add_line(variable, 't', 'z', 1), 'L', 'z', 2);
variable = add_line(add_block(variable, 'outport', 'y'), 'z', 'y');
r = sim(variable, reglageI{:});
assert(isequal(r.yout', [-1 -1 0 1 2 3 4]), 'la longueur du retard lue d''une entree');
r = sim(set_param(variable, 'L', 'Value', 9), reglageI{:});
assert(isequal(r.yout', [-1 -1 -1 -1 -1 0 1]), 'la longueur est bornee par DelayLengthUpperLimit');
r = sim(set_param(variable, 'L', 'Value', 0), reglageI{:});
assert(isequal(r.yout', 0:6), 'une longueur nulle passe l''entree telle quelle');
active = new_system('active');
active = add_block(active, 'clock', 't');
active = add_block(active, 'pulsegenerator', 'en', 'Period', 4, 'PulseWidth', 50);
active = add_block(active, 'simulink/Discrete/Enabled Delay', 'z', 'SampleTime', 1);
active = add_line(add_line(active, 't', 'z', 1), 'en', 'z', 2);
active = add_line(add_block(active, 'outport', 'y'), 'z', 'y');
r = sim(active, reglageI{:});
assert(isequal(r.yout', [0 0 0 0 1 4 4]), 'desactive, le retard tient sa sortie et ses etats');
remis = new_system('remis');
remis = add_block(remis, 'clock', 't');
remis = add_block(remis, 'step', 'r', 'Time', 3);
remis = add_block(remis, 'constant', 'x0', 'Value', 7);
remis = add_block(remis, 'simulink/Discrete/Resettable Delay', 'z', 'SampleTime', 1);
remis = add_line(add_line(add_line(remis, 't', 'z', 1), 'r', 'z', 2), 'x0', 'z', 3);
remis = add_line(add_block(remis, 'outport', 'y'), 'z', 'y');
r = sim(set_param(remis, 'z', 'DelayLength', 2), reglageI{:});
assert(isequal(r.yout', [7 7 0 7 7 3 4]), 'le tampon entier revient a x0 au front de remise');
assert(get_param(add_block(new_system('d2'), 'simulink/Discrete/Delay', 'z'), 'z', ...
                 'DelayLength') == 2, 'le Delay de la bibliotheque retarde de deux pas');
assert(get_param(add_block(new_system('d1'), 'delay', 'z'), 'z', 'DelayLength') == 1, ...
       'le type delay de MatLibre, comme Unit Delay, d''un seul');
boucleD = new_system('boucleD');
boucleD = add_block(boucleD, 'constant', 'c', 'Value', 1);
boucleD = add_block(boucleD, 'sum', 's', 'Signs', '++');
boucleD = add_block(boucleD, 'simulink/Discrete/Enabled Delay', 'z', 'SampleTime', 1);
boucleD = add_block(boucleD, 'constant', 'en', 'Value', 1);
boucleD = add_line(add_line(boucleD, 'c', 's', 1), 'z', 's', 2);
boucleD = add_line(add_line(boucleD, 's', 'z', 1), 'en', 'z', 2);
boucleD = add_line(add_block(boucleD, 'outport', 'y'), 'z', 'y');
r = sim(boucleD, reglageI{:});
assert(isequal(r.yout', 0:6), 'le retard a activation coupe la boucle d''un accumulateur');
casRetard = {
    @() sim(set_param(dti, 'i', 'LowerSaturationLimit', 5), 1), ...
        'Simulink:blocks:DiscreteIntegratorLimits', 'dti/i'
    @() sim(set_param(dti, 'i', 'Gain', [1 2]), 1), ...
        'Simulink:blocks:DiscreteIntegratorGain', 'dti/i'
    @() sim(set_param(variable, 'z', 'DelayLengthUpperLimit', 0), 1), ...
        'Simulink:blocks:DelayLengthUpperLimit', 'variable/z'
    @() sim(set_param(remis, 'z', 'ExternalReset', 'Parfois'), 1), ...
        'Simulink:Parameters:InvalidValue', 'Rising'
    };
for kE = 1:size(casRetard, 1)
    vu = '';
    message = '';
    try
        evalc('casRetard{kE, 1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casRetard{kE, 2}) && ~isempty(strfind(message, casRetard{kE, 3})), ...
           sprintf('integrateur et retard, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casRetard{kE, 2}, vu, message));
end
fprintf('integrateur discret et retard : %d cas d''erreur verifies\n', size(casRetard, 1));

%% ------------------ 44. Retards variables, tenue du premier ordre, séquences, tableurs
% Variable Time Delay lit son retard quand le signal sort, Variable
% Transport Delay quand il entre ; tous deux coupent une boucle. First-Order
% Hold prolonge ses deux derniers échantillons ; Repeating Sequence
% Interpolated répète sa table ; From Spreadsheet lit un tableur en texte ;
% Bus to Vector aplatit un bus.
retardV = new_system('retardV');
retardV = add_block(retardV, 'clock', 't');
retardV = add_block(retardV, 'constant', 'tau', 'Value', 0.3);
retardV = add_block(retardV, 'simulink/Continuous/Variable Time Delay', 'd', 'InitialOutput', -1);
retardV = add_line(add_line(retardV, 't', 'd', 1), 'tau', 'd', 2);
retardV = add_line(add_block(retardV, 'outport', 'y'), 'd', 'y');
reglageV = {'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 1};
attendu = max(0:0.1:1, 0.3) - 0.3;
attendu(1:3) = -1;
for genre = {'Variable time delay', 'Variable transport delay'}
    r = sim(set_param(retardV, 'd', 'VariableDelayType', genre{1}), reglageV{:});
    assert(max(abs(r.yout' - attendu)) < 1e-12, ['retard constant : ' genre{1}]);
end
assert(strcmp(get_param(retardV, 'd', 'VariableDelayType'), 'Variable time delay'), ...
       'Variable Time Delay est un Variable Transport Delay regle d''avance');
croissant = new_system('croissant');
croissant = add_block(croissant, 'clock', 't');
croissant = add_block(croissant, 'gain', 'g', 'Gain', 0.5);
croissant = add_block(croissant, 'variabletransportdelay', 'd', 'VariableDelayType', ...
                      'Variable time delay');
croissant = add_line(add_line(add_line(croissant, 't', 'g'), 't', 'd', 1), 'g', 'd', 2);
croissant = add_line(add_block(croissant, 'outport', 'y'), 'd', 'y');
r = sim(croissant, 'Solver', 'ode45', 'StopTime', 2);
assert(abs(r.yout(end) - 1) < 1e-6, 'retard de t/2 : y(2) = u(1)');
retour = new_system('retour');
retour = add_block(retour, 'integrator', 'i', 'InitialCondition', 1);
retour = add_block(retour, 'constant', 'tau', 'Value', 0.5);
retour = add_block(retour, 'variabletransportdelay', 'd', 'VariableDelayType', ...
                   'Variable time delay', 'InitialOutput', 1);
retour = add_block(retour, 'gain', 'g', 'Gain', -1);
retour = add_line(add_line(retour, 'i', 'd', 1), 'tau', 'd', 2);
retour = add_line(add_line(retour, 'd', 'g'), 'g', 'i');
retour = add_line(add_block(retour, 'outport', 'y'), 'i', 'y');
r = sim(retour, 'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 1);
assert(abs(r.yout(51) - 0.5) < 1e-9 && abs(r.yout(end) - 0.125) < 1e-4, ...
       'x'' = -x(t - 0.5) : le retard coupe la boucle, sans boucle algebrique');
% First-Order Hold
tenue = new_system('tenue');
tenue = add_block(tenue, 'simulink/Sources/Sine Wave', 's');
tenue = add_block(tenue, 'simulink/Discrete/First-Order Hold', 'h', 'Ts', 0.5);
tenue = add_line(add_line(add_block(tenue, 'outport', 'y'), 's', 'h'), 'h', 'y');
r = sim(tenue, 'Solver', 'ode4', 'FixedStep', 0.25, 'StopTime', 2);
t = r.tout;
tk = floor(t / 0.5 + 1e-9) * 0.5;
avant = max(tk - 0.5, 0);
attendu = sin(tk) + (sin(tk) - sin(avant)) / 0.5 .* (t - tk);
assert(max(abs(r.yout - attendu)) < 1e-12, 'First-Order Hold : la droite des deux derniers echantillons');
% Repeating Sequence Interpolated
sequence = new_system('sequence');
sequence = add_block(sequence, 'simulink/Sources/Repeating Sequence Interpolated', 's', ...
                     'tsamp', 0.05);
sequence = add_line(add_block(sequence, 'outport', 'y'), 's', 'y');
r = sim(sequence, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.05, 'StopTime', 1.2);
attendu = interp1([0 0.1 0.5 0.6 1], [3 1 4 2 1], mod(r.tout, 1));
assert(max(abs(r.yout - attendu)) < 1e-12, 'la sequence datee, repetee avec la periode 1');
r = sim(set_param(sequence, 's', 'LookUpMeth', 'Use Input Below'), 'Solver', ...
        'FixedStepDiscrete', 'FixedStep', 0.05, 'StopTime', 1.2);
assert(isequal(r.yout(1:4)', [3 3 1 1]), 'Use Input Below : la valeur de la date d''avant');
% From Spreadsheet
dossierTab = tempname();
mkdir(dossierTab);
fichierTab = fullfile(dossierTab, 'signal.csv');
writematrix([0 0 10; 1 2 20; 2 4 30], fichierTab);
tableur = new_system('tableur');
tableur = add_block(tableur, 'simulink/Sources/From Spreadsheet', 's', 'FileName', fichierTab);
tableur = add_line(add_block(tableur, 'outport', 'y'), 's', 'y');
r = sim(tableur, 'Solver', 'ode4', 'FixedStep', 0.5, 'StopTime', 3);
assert(isequal(r.yout', [0:6; 10:5:40]), 'interpole et prolonge le tableur');
r = sim(set_param(tableur, 's', 'InterpolationWithinTimeRange', 'Zero order hold', ...
                  'ExtrapolationAfterLastDataPoint', 'Hold last value'), 'Solver', 'ode4', ...
        'FixedStep', 0.5, 'StopTime', 3);
assert(isequal(r.yout', [0 0 2 2 4 4 4; 10 10 20 20 30 30 30]), 'tenue d''ordre zero, puis tenue');
fichierMauvais = fullfile(dossierTab, 'mauvais.csv');
writematrix([2 1; 1 2], fichierMauvais);
% Bus to Vector
bv = new_system('bv');
bv = add_block(bv, 'constant', 'a', 'Value', 1);
bv = add_block(bv, 'constant', 'c', 'Value', 2);
bv = add_block(bv, 'buscreator', 'bc', 'Inputs', 2);
bv = add_block(bv, 'simulink/Signal Attributes/Bus to Vector', 'v');
bv = add_block(bv, 'gain', 'g', 'Gain', [1 10]);
bv = add_line(add_line(bv, 'a', 'bc', 1), 'c', 'bc', 2);
bv = add_line(add_line(bv, 'bc', 'v'), 'v', 'g');
bv = add_line(add_block(bv, 'outport', 'y'), 'g', 'y');
r = sim(bv, 1);
assert(isequal(r.yout(end, :), [1 20]), 'Bus to Vector : le bus devient un vecteur');
casRetardV = {
    @() sim(set_param(retardV, 'd', 'MaximumDelay', 0), 1), ...
        'Simulink:blocks:VariableTransportDelayMaximum', 'retardV/d'
    @() sim(set_param(retardV, 'tau', 'Value', [0.1 0.2]), 1), ...
        'Simulink:blocks:VariableTransportDelayInput', 'retardV/d'
    @() sim(set_param(tenue, 'h', 'Ts', 0), 1), 'Simulink:blocks:FirstOrderHoldSampleTime', 'tenue/h'
    @() sim(set_param(sequence, 's', 'TimeValues', [0 1]), 1), ...
        'Simulink:blocks:RepeatingSequenceSize', 'sequence/s'
    @() sim(set_param(sequence, 's', 'TimeValues', [0 0.5 0.2 0.6 1]), 1), ...
        'Simulink:blocks:RepeatingSequenceTimes', 'sequence/s'
    @() sim(set_param(tableur, 's', 'FileName', fullfile(dossierTab, 'absent.csv')), 1), ...
        'Simulink:blocks:FromSpreadsheetNotFound', 'tableur/s'
    @() sim(set_param(tableur, 's', 'FileName', fichierMauvais), 1), ...
        'Simulink:blocks:FromSpreadsheetInvalidData', 'tableur/s'
    };
for kE = 1:size(casRetardV, 1)
    vu = '';
    message = '';
    try
        evalc('casRetardV{kE, 1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casRetardV{kE, 2}) && ~isempty(strfind(message, casRetardV{kE, 3})), ...
           sprintf('retards variables et sources, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casRetardV{kE, 2}, vu, message));
end
rmdir(dossierTab, 's');
fprintf('retards variables et sources : %d cas d''erreur verifies\n', size(casRetardV, 1));

%% ------------------------------------ 45. Algebraic Constraint et Bus Assignment
% L'Algebraic Constraint rend z tel que son entrée f(z) s'annule — ou
% vaille z —, la boucle algébrique qu'il ferme étant résolue par Newton à
% partir d'InitialGuess ; il donne aux schémas leurs équations
% algébriques. Le Bus Assignment remplace des éléments d'un bus par leur
% nom.
etatAvertissement = warning('off', 'all');
contrainte = new_system('contrainte');
contrainte = add_block(contrainte, 'constant', 'c', 'Value', -6);
contrainte = add_block(contrainte, 'fcn', 'f', 'Expr', 'u^2 + u');
contrainte = add_block(contrainte, 'sum', 's', 'Signs', '++');
contrainte = add_block(contrainte, 'simulink/Math Operations/Algebraic Constraint', 'z', ...
                       'InitialGuess', 1);
contrainte = add_line(add_line(contrainte, 'z', 'f'), 'f', 's', 1);
contrainte = add_line(add_line(contrainte, 'c', 's', 2), 's', 'z');
contrainte = add_line(add_block(contrainte, 'outport', 'y'), 'z', 'y');
r = sim(contrainte, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 0.3);
assert(max(abs(r.yout - 2)) < 1e-8, 'z^2 + z - 6 = 0 depuis 1 : z = 2');
r = sim(set_param(contrainte, 'z', 'InitialGuess', -5), 'Solver', 'ode1', 'FixedStep', 0.1, ...
        'StopTime', 0.1);
assert(max(abs(r.yout + 3)) < 1e-8, 'depuis -5, l''autre racine : z = -3');
r = sim(set_param(contrainte, 'z', 'Constraint', 'f(z) = z', 'InitialGuess', 3), ...
        'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 0.2);
assert(max(abs(r.yout - sqrt(6))) < 1e-8, 'f(z) = z : z^2 - 6 = 0');
dae = new_system('dae');
dae = add_block(dae, 'integrator', 'x', 'InitialCondition', 1);
dae = add_block(dae, 'simulink/Math Operations/Algebraic Constraint', 'z');
dae = add_block(dae, 'clock', 't');
dae = add_block(dae, 'trigonometry', 'sn', 'Operator', 'sin');
dae = add_block(dae, 'sum', 'f', 'Signs', '+--');
dae = add_block(dae, 'gain', 'g', 'Gain', -1);
dae = add_line(add_line(dae, 't', 'sn'), 'z', 'f', 1);
dae = add_line(add_line(dae, 'x', 'f', 2), 'sn', 'f', 3);
dae = add_line(add_line(dae, 'f', 'z'), 'z', 'g');
dae = add_line(dae, 'g', 'x');
dae = add_line(add_block(dae, 'outport', 'y'), 'x', 'y');
r = sim(dae, 'Solver', 'ode45', 'StopTime', 1);
exact = 0.5 * exp(-r.tout) - 0.5 * sin(r.tout) + 0.5 * cos(r.tout);
assert(max(abs(r.yout - exact)) < 1e-5, 'x'' = -z, z = x + sin t : l''equation algebrique tenue');
warning(etatAvertissement);
% Bus Assignment
affecte = new_system('affecte');
affecte = add_block(affecte, 'constant', 'a', 'Value', 1);
affecte = add_block(affecte, 'constant', 'v', 'Value', [2 3]);
affecte = add_block(affecte, 'constant', 'n', 'Value', [20 30]);
affecte = add_block(affecte, 'buscreator', 'bc', 'Inputs', 'x,y');
affecte = add_block(affecte, 'simulink/Signal Routing/Bus Assignment', 'as', ...
                    'AssignedSignals', 'y');
affecte = add_block(affecte, 'busselector', 'sel', 'OutputSignals', 'x,y');
affecte = add_line(add_line(affecte, 'a', 'bc', 1), 'v', 'bc', 2);
affecte = add_line(add_line(affecte, 'bc', 'as', 1), 'n', 'as', 2);
affecte = add_line(affecte, 'as', 'sel');
affecte = add_block(add_block(affecte, 'outport', 'ox'), 'outport', 'oy');
affecte = add_line(add_line(affecte, 'sel/1', 'ox'), 'sel/2', 'oy');
r = sim(affecte, 1);
assert(isequal(r.yout(end, :), [1 20 30]), 'y remplace, x garde ; le Bus Selector lit la suite');
emboite = new_system('emboite');
emboite = add_block(emboite, 'constant', 'a', 'Value', 1);
emboite = add_block(emboite, 'constant', 'b', 'Value', 2);
emboite = add_block(emboite, 'constant', 'c', 'Value', 3);
emboite = add_block(emboite, 'constant', 'n', 'Value', 9);
emboite = add_block(emboite, 'buscreator', 'interne', 'Inputs', 'p,q');
emboite = add_block(emboite, 'buscreator', 'externe', 'Inputs', 'r,s');
emboite = add_block(emboite, 'busassignment', 'as', 'AssignedSignals', 's.q');
emboite = add_block(emboite, 'busselector', 'sel', 'OutputSignals', 's.q,r');
emboite = add_line(add_line(emboite, 'a', 'interne', 1), 'b', 'interne', 2);
emboite = add_line(add_line(emboite, 'c', 'externe', 1), 'interne', 'externe', 2);
emboite = add_line(add_line(emboite, 'externe', 'as', 1), 'n', 'as', 2);
emboite = add_line(emboite, 'as', 'sel');
emboite = add_block(add_block(emboite, 'outport', 'o1'), 'outport', 'o2');
emboite = add_line(add_line(emboite, 'sel/1', 'o1'), 'sel/2', 'o2');
r = sim(emboite, 1);
assert(isequal(r.yout(end, :), [9 3]), 'un element d''un bus emboite, par son chemin s.q');
horsBoucle = add_line(add_block(add_block(new_system('horsBoucle'), 'constant', 'c'), ...
                                'algebraicconstraint', 'z'), 'c', 'z');
casContrainte = {
    @() sim(horsBoucle, 1), 'Simulink:blocks:AlgebraicConstraintNotInLoop', 'horsBoucle/z'
    @() sim(set_param(affecte, 'as', 'AssignedSignals', 'z'), 1), ...
        'Simulink:Bus:AssignmentElementNotFound', 'affecte/as'
    @() sim(set_param(affecte, 'as', 'AssignedSignals', 'x'), 1), ...
        'Simulink:Bus:AssignmentDimensions', 'affecte/as'
    @() sim(add_line(add_line(add_block(add_block(add_block(new_system('pasBus'), ...
            'constant', 'a'), 'constant', 'b'), 'busassignment', 'as'), 'a', 'as', 1), ...
            'b', 'as', 2), 1), 'Simulink:Bus:AssignmentInputNotBus', 'pasBus/as'
    };
for kE = 1:size(casContrainte, 1)
    vu = '';
    message = '';
    try
        evalc('casContrainte{kE, 1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casContrainte{kE, 2}) && ~isempty(strfind(message, casContrainte{kE, 3})), ...
           sprintf('contrainte et bus, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casContrainte{kE, 2}, vu, message));
end
fprintf('contrainte algebrique et bus : %d cas d''erreur verifies\n', size(casContrainte, 1));

%% ------------------------------------------------------------ 46. Signal Editor
% Le Signal Editor rejoue un scénario, un Dataset de timeseries rangé dans
% un fichier MAT, une sortie par signal. Une MATLAB Function dont la
% sortie, compilée réelle, deviendrait complexe en route est refusée en
% nommant le bloc : Simulink fixe la complexité d'un signal avant de
% simuler (voir la section 48 pour les signaux complexes).
Scenario = Simulink.SimulationData.Dataset;
Scenario = addElement(Scenario, timeseries([0; 2; 4], [0; 1; 2], 'Name', 'rampe'));
Scenario = addElement(Scenario, timeseries([1 10; 3 30], [0; 2], 'Name', 'paire'));
fichierScenario = [tempname() '.mat'];
save(fichierScenario, 'Scenario');
editeur = new_system('editeur');
editeur = add_block(editeur, 'simulink/Sources/Signal Editor', 'ed', 'FileName', fichierScenario);
[ne, ns] = matlibre_sl_ports(editeur.blocs{1});
assert(ne == 0 && ns == 2, 'une sortie par signal du scenario');
editeur = add_block(add_block(editeur, 'outport', 'y1'), 'outport', 'y2');
editeur = add_line(add_line(editeur, 'ed/1', 'y1'), 'ed/2', 'y2');
r = sim(editeur, 'Solver', 'ode4', 'FixedStep', 0.5, 'StopTime', 3);
assert(isequal(r.yout', [0 1 2 3 4 4 4; 1 1.5 2 2.5 3 3 3; 10 15 20 25 30 30 30]), ...
       'interpole, puis tient la derniere valeur ; un signal vecteur garde ses elements');
Autre = Scenario;
save(fichierScenario, 'Scenario', 'Autre');
r = sim(set_param(editeur, 'ed', 'ActiveScenario', 'Autre'), 'Solver', 'ode4', ...
        'FixedStep', 0.5, 'StopTime', 1);
assert(isequal(r.yout(:, 1)', [0 1 2]), 'ActiveScenario choisit le scenario');
nombre = 12; %#ok<NASGU>
save(fichierScenario, 'Scenario', 'nombre');
% une sortie qui deviendrait complexe
fonction = new_system('fonction');
fonction = add_block(fonction, 'constant', 'c', 'Value', -4);
fonction = add_block(fonction, 'matlabfunction', 'm', 'Script', ...
                     sprintf('function y = fcn(u)\ny = sqrt(u);\n'));
fonction = add_line(add_line(add_block(fonction, 'outport', 'y'), 'c', 'm'), 'm', 'y');
casComplexe = {
    @() sim(fonction, 1), 'Simulink:DataType:ComplexSignalNotSupported', 'fonction/m'
    @() sim(set_param(editeur, 'ed', 'ActiveScenario', 'Absent'), 1), ...
        'Simulink:SignalEditor:ScenarioNotFound', 'editeur/ed'
    @() sim(set_param(editeur, 'ed', 'ActiveScenario', 'nombre'), 1), ...
        'Simulink:SignalEditor:InvalidScenario', 'editeur/ed'
    @() sim(set_param(editeur, 'ed', 'FileName', 'scenarioIntrouvable.mat'), 1), ...
        'Simulink:SignalEditor:FileNotFound', 'editeur/ed'
    };
for kE = 1:size(casComplexe, 1)
    vu = '';
    message = '';
    try
        evalc('casComplexe{kE, 1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casComplexe{kE, 2}) && ~isempty(strfind(message, casComplexe{kE, 3})), ...
           sprintf('scenario et complexes, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   casComplexe{kE, 2}, vu, message));
end
delete(fichierScenario);
fprintf('scenarios : %d cas d''erreur verifies\n', size(casComplexe, 1));

%% ------------------------------------------- 47. Batterie de modèles tirés au hasard
% Des modèles tirés au hasard, reproductibles : une source, puis une chaîne
% de deux à cinq blocs du catalogue, réglages tirés dans leurs listes de
% choix, valeurs gênantes (nulles, négatives, vecteurs) et entrées
% vecteurs de temps en temps. Chaque simulation, à pas fixe et à pas
% variable, ne doit lever qu'une erreur Simulink qui nomme le modèle ; un
% modèle qui simule doit se relire à l'identique par le .slx et par le .m.
% Les défauts que la batterie a trouvés, gardés ici en cas fixes : un
% Signal Generator de fréquence négative ou nulle faisait piétiner le
% solveur à pas variable sur ses fronts, un nombre de ports qui n'en est
% pas un (« 2.5 », « -1 ») donnait un message trompeur, et un bloc discret
% relu d'un .slx écrit par MatLibre prenait la période par défaut de
% Simulink au lieu de la sienne.
for forme = {'square', 'sawtooth'}
    generateur = new_system('generateur');
    generateur = add_block(generateur, 'signalgenerator', 's', 'WaveForm', forme{1}, ...
                           'Frequency', -1, 'Units', 'Hertz');
    generateur = add_line(add_block(generateur, 'outport', 'y'), 's', 'y');
    r = sim(generateur, 'Solver', 'ode45', 'StopTime', 1.2);
    assert(numel(r.tout) < 500 && abs(r.tout(end) - 1.2) < 1e-9, ...
           sprintf('%s de frequence negative : le solveur avance', forme{1}));
    r0 = sim(set_param(generateur, 's', 'Frequency', 0), 'Solver', 'ode45', 'StopTime', 1.2);
    assert(numel(r0.tout) < 500 && abs(r0.tout(end) - 1.2) < 1e-9, ...
           sprintf('%s de frequence nulle : le solveur avance', forme{1}));
end
r = sim(set_param(generateur, 's', 'WaveForm', 'square', 'Frequency', -1), ...
        'Solver', 'ode45', 'StopTime', 1.2);
assert(r.yout(end) == -1, 'un carre de frequence -1 Hz vaut -1 a t = 1,2 s');
casPorts = {'sum', 'Inputs', '2.5', 'Simulink:Parameters:InvParamSetting'
            'sum', 'Inputs', '+x', 'Simulink:Parameters:InvParamSetting'
            'mux', 'Inputs', '-1', 'Simulink:Parameters:InvalidPortCount'
            'product', 'Inputs', '1.5', 'Simulink:Parameters:InvParamSetting'
            'buscreator', 'Inputs', '-2', 'Simulink:Parameters:InvalidPortCount'
            'demux', 'Outputs', '0.5', 'Simulink:Parameters:InvalidPortCount'};
for kP = 1:size(casPorts, 1)
    ports = new_system('ports');
    ports = add_block(add_block(ports, 'constant', 'c'), casPorts{kP, 1}, 'b', ...
                      casPorts{kP, 2}, casPorts{kP, 3});
    vu = '';
    message = '';
    try
        ports = add_line(add_line(add_block(ports, 'outport', 'y'), 'c', 'b'), 'b', 'y');
        evalc('sim(ports, 1);');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casPorts{kP, 4}) && ~isempty(strfind(message, 'ports/b')), ...
           sprintf('%s %s = %s : %s attendu, %s rendu (%s)', casPorts{kP, :}, vu, message));
end
discret = new_system('discret');
discret = add_block(discret, 'zoh', 'z');
discret = add_block(discret, 'unitdelay', 'd');
fichierDiscret = [tempname() '.slx'];
save_system(discret, fichierDiscret);
relu = load_system(fichierDiscret);
assert(isequal(get_param(relu, 'z', 'SampleTime'), get_param(discret, 'z', 'SampleTime')) && ...
       isequal(get_param(relu, 'd', 'SampleTime'), get_param(discret, 'd', 'SampleTime')), ...
       'un .slx ecrit par MatLibre garde ses periodes par defaut');
delete(fichierDiscret);
disp('cas fixes de la batterie : ok');
rng(47);
catalogueAlea = matlibre_sl_catalogue();
exclusAlea = {'subsystem', 'modelreference', 'iterateur', 'enableport', 'triggerport', ...
              'actionport', 'if', 'switchcase', 'goto', 'from', 'datastorememory', ...
              'datastoreread', 'datastorewrite', 'chart', 'sfunction', 'msfunction', ...
              'fromfile', 'fromspreadsheet', 'signaleditor', 'fromworkspace', 'variantsource', ...
              'variantsink', 'busselector', 'busassignment', 'inport', 'foriterator', ...
              'whileiterator', 'merge', 'functioncallgenerator', 'tofile', ...
              'algebraicconstraint', 'garde'};
sourcesAlea = {};
blocsAlea = {};
for kT = 1:numel(catalogueAlea)
    entree = catalogueAlea(kT);
    if strcmp(entree.famille, 'Interne') || any(strcmp(entree.type, exclusAlea))
        continue
    end
    [ne, ns] = matlibre_sl_ports(struct('type', entree.type, 'nom', 'b', ...
                                        'parametres', struct()), entree.type);
    if isnan(ne) || isnan(ns) || ns == 0
        continue
    end
    if ne == 0
        sourcesAlea{end + 1} = entree.type; %#ok<SAGROW>
    else
        blocsAlea{end + 1} = entree.type; %#ok<SAGROW>
    end
end
dossierAlea = tempname();
mkdir(dossierAlea);
statsAlea = [0 0 0];   % simulés, refusés, relus
for n = 1:120
    typesAlea = [sourcesAlea(randi(numel(sourcesAlea))), ...
                 blocsAlea(randi(numel(blocsAlea), 1, randi([2 5])))];
    nomAlea = sprintf('alea%d', n);
    [m, reglagesAlea] = aleaBatir(nomAlea, typesAlea, catalogueAlea);
    contexte = sprintf('%s : %s%s', nomAlea, strjoin(typesAlea, ' -> '), reglagesAlea);
    for solveur = {'ode1', 'ode45'}
        [r, id, message] = aleaSimuler(m, solveur{1});
        if ~isempty(id)
            statsAlea(2) = statsAlea(2) + 1;
            assert(strncmp(id, 'Simulink:', 9) || strncmp(id, 'Stateflow:', 10) || ...
               strncmp(id, 'Simscape:', 9), ...
                   sprintf('%s (%s) : erreur interne %s : %s', contexte, solveur{1}, id, message));
            assert(~isempty(strfind(message, nomAlea)), ...
                   sprintf('%s (%s) : le message ne nomme pas le modele : %s', contexte, ...
                           solveur{1}, message));
            continue
        end
        statsAlea(1) = statsAlea(1) + 1;
        if ~strcmp(solveur{1}, 'ode1')
            continue
        end
        for ext = {'.slx', '.m'}
            fichier = fullfile(dossierAlea, [nomAlea ext{1}]);
            save_system(m, fichier);
            [r2, id2, message2] = aleaSimuler(load_system(fichier), 'ode1');
            assert(isempty(id2), sprintf('%s : relu par %s, il echoue : %s %s', contexte, ...
                                         ext{1}, id2, message2));
            assert(aleaMemesValeurs(r.yout, r2.yout), ...
                   sprintf('%s : relu par %s, il ne rend pas la meme chose', contexte, ext{1}));
            statsAlea(3) = statsAlea(3) + 1;
        end
    end
end
rmdir(dossierAlea, 's');
fprintf(['batterie de modeles tires au hasard : %d simulations, %d refus nommes, ' ...
         '%d relectures identiques\n'], statsAlea);

%% --------------------------------------------------------- 48. Signaux complexes
% Un signal est réel ou complexe, et le reste de bout en bout : une
% constante, un gain, une donnée complexes le rendent complexe, un calcul
% le transmet, Abs ou Complex to Real-Imag le rendent réel. La racine d'un
% signal complexe dont la valeur du moment est négative est imaginaire,
% et non NaN. Un bloc qui ne calcule qu'en réel le refuse en se nommant.
parties = new_system('parties');
parties = add_block(parties, 'constant', 'c', 'Value', 1 + 2i);
parties = add_block(parties, 'gain', 'g', 'Gain', 2);
parties = add_block(parties, 'complextorealimag', 'ri');
parties = add_block(add_block(parties, 'outport', 're'), 'outport', 'im');
parties = add_line(add_line(add_line(parties, 'c', 'g'), 'g', 'ri'), 'ri/1', 're');
parties = add_line(parties, 'ri/2', 'im');
r = sim(parties, 'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 1);
assert(isreal(r.yout) && isequal(r.yout, repmat([2 4], 3, 1)), ...
       'Complex to Real-Imag rend deux signaux reels');
conjugue = new_system('conjugue');
conjugue = add_block(conjugue, 'constant', 'c', 'Value', 3);
conjugue = add_block(conjugue, 'realimagtocomplex', 'rc', 'Input', 'Real', 'ConstantPart', -1);
conjugue = add_block(conjugue, 'math', 'f', 'Operator', 'conj');
conjugue = add_block(conjugue, 'abs', 'a');
conjugue = add_block(add_block(conjugue, 'outport', 'y'), 'outport', 'm');
conjugue = add_line(add_line(add_line(conjugue, 'c', 'rc'), 'rc', 'f'), 'f', 'y');
conjugue = add_line(add_line(conjugue, 'f', 'a'), 'a', 'm');
r = sim(conjugue, 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 1);
assert(isequal(r.yout(:, 1), [3 + 1i; 3 + 1i]) && ...
       max(abs(r.yout(:, 2) - sqrt(10))) < 1e-12, 'conj, puis le module');
cumul = new_system('cumul');
cumul = add_block(cumul, 'constant', 'c', 'Value', 1i);
cumul = add_block(cumul, 'sum', 's', 'Signs', '++');
cumul = add_block(cumul, 'unitdelay', 'd', 'SampleTime', 1);
cumul = add_line(add_block(cumul, 'outport', 'y'), 'd', 'y');
cumul = add_line(add_line(add_line(cumul, 'c', 's/1'), 'd', 's/2'), 's', 'd');
r = sim(cumul, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 3);
assert(isequal(r.yout, [0; 1i; 2i; 3i]), 'une boucle porte le complexe au retard');
racineCx = new_system('racineCx');
racineCx = add_block(racineCx, 'constant', 'c', 'Value', -4);
racineCx = add_block(racineCx, 'constant', 'z', 'Value', 0i);
racineCx = add_block(racineCx, 'sum', 's', 'Signs', '++');
racineCx = add_block(racineCx, 'sqrt', 'r');
racineCx = add_block(racineCx, 'math', 'l', 'Operator', 'log');
racineCx = add_block(racineCx, 'trigonometry', 'as', 'Operator', 'acos');
racineCx = add_block(add_block(add_block(racineCx, 'outport', 'y'), 'outport', 'ln'), 'outport', 'ac');
racineCx = add_line(add_line(add_line(racineCx, 'c', 's/1'), 'z', 's/2'), 's', 'r');
racineCx = add_line(add_line(add_line(racineCx, 's', 'l'), 's', 'as'), 'r', 'y');
racineCx = add_line(add_line(racineCx, 'l', 'ln'), 'as', 'ac');
r = sim(racineCx, 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 1);
assert(isequal(r.yout(1, 1), 2i) && abs(r.yout(1, 2) - log(-4)) < 1e-12 && ...
       abs(r.yout(1, 3) - acos(-4)) < 1e-12, ...
       'un signal complexe de valeur reelle negative : racine, log et acos complexes');
% module et argument, aller et retour ; hermitienne et produit scalaire
polaire = new_system('polaire');
polaire = add_block(polaire, 'constant', 'm', 'Value', 2);
polaire = add_block(polaire, 'constant', 'a', 'Value', pi / 3);
polaire = add_block(polaire, 'magnitudeangletocomplex', 'p');
polaire = add_block(polaire, 'complextomagnitudeangle', 'q');
polaire = add_block(polaire, 'trigonometry', 'e', 'Operator', 'cos + jsin');
polaire = add_block(polaire, 'constant', 'M', 'Value', [1 + 1i, 2; 3, 4i]);
polaire = add_block(polaire, 'math', 'h', 'Operator', 'hermitian');
polaire = add_block(polaire, 'math', 't', 'Operator', 'transpose');
polaire = add_block(polaire, 'math', 'm2', 'Operator', 'magnitude^2');
polaire = add_block(polaire, 'constant', 'v', 'Value', [1i; 2]);
polaire = add_block(polaire, 'dotproduct', 'dp');
noms = {'mo', 'ar', 'ex', 'he', 'tr', 'ca', 'ps'};
for i = 1:numel(noms)
    polaire = add_block(polaire, 'outport', noms{i});
end
polaire = add_line(add_line(add_line(polaire, 'm', 'p/1'), 'a', 'p/2'), 'p', 'q');
polaire = add_line(add_line(add_line(polaire, 'q/1', 'mo'), 'q/2', 'ar'), 'a', 'e');
polaire = add_line(add_line(add_line(polaire, 'e', 'ex'), 'M', 'h'), 'h', 'he');
polaire = add_line(add_line(add_line(polaire, 'M', 't'), 't', 'tr'), 'M', 'm2');
polaire = add_line(add_line(add_line(polaire, 'm2', 'ca'), 'v', 'dp/1'), 'v', 'dp/2');
polaire = add_line(polaire, 'dp', 'ps');
r = sim(polaire, 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 0);
y = r.yout(1, :);
M = [1 + 1i, 2; 3, 4i];
assert(abs(y(1) - 2) < 1e-12 && abs(y(2) - pi / 3) < 1e-12, 'Magnitude-Angle, aller et retour');
assert(abs(y(3) - exp(1i * pi / 3)) < 1e-12, 'cos + jsin rend exp(ju)');
Mh = M';
Mt = M.';
assert(isequal(y(4:7), Mh(:).') && isequal(y(8:11), Mt(:).'), ...
       'hermitian conjugue, transpose non');
assert(isequal(y(12:15), real(M(:).' .* conj(M(:).'))) && y(16) == 5, ...
       'magnitude^2 est reel ; Dot Product vaut sum(conj(u1) .* u2)');
% des données complexes : espace de travail, MATLAB Function, aiguillage
assignin('base', 'signalComplexe', [0 1+1i; 1 3+3i]);
donnees = new_system('donnees');
donnees = add_block(donnees, 'fromworkspace', 'f', 'VariableName', 'signalComplexe');
donnees = add_block(donnees, 'matlabfunction', 'mf', 'Script', ...
                    sprintf('function y = fcn(u)\ny = u * 1i;\n'));
donnees = add_block(donnees, 'constant', 'k', 'Value', 0.5);
donnees = add_block(donnees, 'clock', 'h');
donnees = add_block(donnees, 'switch', 'sw', 'Threshold', 0.5);
donnees = add_block(donnees, 'relational', 'eg', 'Operator', '==');
donnees = add_block(add_block(add_block(donnees, 'outport', 'y'), 'outport', 'a'), 'outport', 'b');
donnees = add_line(add_line(add_line(donnees, 'f', 'mf'), 'mf', 'y'), 'f', 'sw/1');
donnees = add_line(add_line(add_line(donnees, 'h', 'sw/2'), 'mf', 'sw/3'), 'sw', 'a');
donnees = add_line(add_line(add_line(donnees, 'f', 'eg/1'), 'mf', 'eg/2'), 'eg', 'b');
r = sim(donnees, 'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 1);
assert(max(abs(r.yout(:, 1) - [-1 + 1i; -2 + 2i; -3 + 3i])) < 1e-12, ...
       'From Workspace complexe, interpole ; MATLAB Function complexe');
assert(max(abs(r.yout(:, 2) - [-1 + 1i; 2 + 2i; 3 + 3i])) < 1e-12 && isequal(r.yout(:, 3), [0; 0; 0]), ...
       'le Switch aiguille des complexes sur une commande reelle ; == compare');
fichierCx = [tempname() '.slx'];
save_system(donnees, fichierCx);
r2 = sim(load_system(fichierCx), 'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 1);
assert(isequal(r2.yout, r.yout), 'relu du .slx, un modele complexe rend la meme chose');
save_system(polaire, fichierCx);
r2 = sim(load_system(fichierCx), 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 0);
assert(max(abs(r2.yout(1, :) - y)) < 1e-12, 'une constante complexe se relit du .slx');
delete(fichierCx);
fir = new_system('fir');
fir = add_block(fir, 'constant', 'c', 'Value', 2i);
fir = add_block(fir, 'discretefirfilter', 'f', 'Coefficients', [0.5 0.5], 'SampleTime', 1);
fir = add_line(add_line(add_block(fir, 'outport', 'y'), 'c', 'f'), 'f', 'y');
r = sim(fir, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 2);
assert(isequal(r.yout, [1i; 2i; 2i]), 'un filtre FIR filtre un complexe');
% ce que Simulink refuse
refus = @(type, varargin) aleaRefusComplexe(type, varargin{:});
casCx = {
    refus('saturation'), 'Simulink:DataType:InputPortComplexityMismatch', 'refus/b'
    refus('integrator'), 'Simulink:DataType:InputPortComplexityMismatch', 'refus/b'
    refus('minmax'), 'Simulink:DataType:InputPortComplexityMismatch', 'refus/b'
    refus('transferfcn'), 'Simulink:DataType:InputPortComplexityMismatch', 'refus/b'
    refus('relational', 'Operator', '<'), 'Simulink:DataType:InputPortComplexityMismatch', 'refus/b'
    refus('realimagtocomplex', 'Input', 'Real'), 'Simulink:DataType:InputPortComplexityMismatch', 'refus/b'
    refus('trigonometry', 'Operator', 'atan2'), 'Simulink:DataType:InputPortComplexityMismatch', 'refus/b'
    refus('math', 'Operator', 'rem'), 'Simulink:DataType:InputPortComplexityMismatch', 'refus/b'
    refus('lookup'), 'Simulink:DataType:InputPortComplexityMismatch', 'refus/b'
    refus('signalspecification', 'SignalType', 'real'), 'Simulink:DataType:SignalSpecificationMismatch', 'refus/b'
    refus('multiportswitch', 'Inputs', '1'), 'Simulink:DataType:InputPortComplexityMismatch', 'refus/b'
    refus('saturation', 'UpperLimit', 1i), 'Simulink:Parameters:InvParamSetting', 'refus/b'
    };
for kC = 1:size(casCx, 1)
    vu = '';
    message = '';
    try
        evalc('sim(casCx{kC, 1}, 1);');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, casCx{kC, 2}) && ~isempty(strfind(message, casCx{kC, 3})), ...
           sprintf('complexes, cas %d : %s attendu, %s rendu (%s)', kC, casCx{kC, 2}, vu, message));
end
reel = new_system('reel');
reel = add_block(add_block(reel, 'constant', 'c', 'Value', 2), 'signalspecification', 's', ...
                 'SignalType', 'complex');
reel = add_line(add_line(add_block(reel, 'outport', 'y'), 'c', 's'), 's', 'y');
vu = '';
try
    evalc('sim(reel, 1);');
catch err
    vu = err.identifier;
end
assert(strcmp(vu, 'Simulink:DataType:SignalSpecificationMismatch'), ...
       'Signal Specification complexe recoit un signal reel');
sortie = new_system('sortie');
sortie = add_block(sortie, 'constant', 'c', 'Value', 1i);
sortie = add_line(add_block(sortie, 'outport', 'y', 'SignalType', 'complex'), 'c', 'y');
r = sim(sortie, 1);
assert(isequal(r.yout(end), 1i), 'une sortie complexe recoit un complexe');
for cas = {{1i, 'real'}, {1, 'complex'}}
    vu = '';
    message = '';
    try
        evalc('sim(set_param(set_param(sortie, ''c'', ''Value'', cas{1}{1}), ''y'', ''SignalType'', cas{1}{2}), 1);');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, 'Simulink:DataType:InputPortComplexityMismatch') && ...
           ~isempty(strfind(message, 'sortie/y')), sprintf('SignalType %s : %s', cas{1}{2}, message));
end
Scenario = Simulink.SimulationData.Dataset;
Scenario = addElement(Scenario, timeseries([0; 2 + 2i], [0; 2], 'Name', 'z'));
fichierScenario = [tempname() '.mat'];
save(fichierScenario, 'Scenario');
editeurCx = new_system('editeurCx');
editeurCx = add_block(editeurCx, 'signaleditor', 'ed', 'FileName', fichierScenario);
editeurCx = add_line(add_block(editeurCx, 'outport', 'y'), 'ed', 'y');
r = sim(editeurCx, 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 3);
assert(isequal(r.yout, [0; 1 + 1i; 2 + 2i; 2 + 2i]), 'un scenario complexe se rejoue complexe');
delete(fichierScenario);
% le module ou l'égalité d'un complexe n'a pas de passage par zéro à
% chercher : le pas variable avance sans basculer
lisse = new_system('lisse');
lisse = add_block(lisse, 'sinewave', 's');
lisse = add_block(lisse, 'constant', 'j', 'Value', 1i);
lisse = add_block(lisse, 'product', 'p');
lisse = add_block(lisse, 'abs', 'a');
lisse = add_block(lisse, 'relational', 'r', 'Operator', '==');
lisse = add_block(lisse, 'constant', 'z', 'Value', 0);
lisse = add_block(add_block(lisse, 'outport', 'y1'), 'outport', 'y2');
lisse = add_line(add_line(add_line(lisse, 's', 'p/1'), 'j', 'p/2'), 'p', 'a');
lisse = add_line(add_line(add_line(lisse, 'a', 'y1'), 'p', 'r/1'), 'z', 'r/2');
lisse = add_line(lisse, 'r', 'y2');
r = sim(lisse, 'Solver', 'ode45', 'StopTime', 10);
assert(isreal(r.yout) && max(abs(r.yout(:, 1) - abs(sin(r.tout)))) < 1e-12, ...
       'Abs d''un complexe sous ode45, sans passage par zero');
fprintf('signaux complexes : %d refus nommes verifies\n', size(casCx, 1) + 3);

%% ----------------------------------------------------- 49. Types à virgule fixe
% Un signal peut être à virgule fixe — fixdt(1,16,8), 'sfix16_En8', ou le
% nom d'un Simulink.NumericType de l'espace de travail : ses valeurs sont
% sur la grille de son type, arrondies et saturées ou repliées comme le
% disent RndMeth et SaturateOnIntegerOverflow. Un calcul dont le type
% n'est pas dit ne perd rien : une somme garde la plus fine des échelles
% et gagne un bit par retenue possible, un produit additionne tailles et
% bits après la virgule, un gain range son paramètre en meilleure
% précision ; au plus 32 bits. To Workspace rend des FI.
fixe = new_system('fixe');
fixe = add_block(fixe, 'constant', 'c', 'Value', pi, 'OutDataTypeStr', 'fixdt(1,16,8)');
fixe = add_block(fixe, 'constant', 'd', 'Value', 0.1, 'OutDataTypeStr', 'sfix8_En6');
fixe = add_block(fixe, 'sum', 's');
fixe = add_block(fixe, 'product', 'p');
fixe = add_block(fixe, 'gain', 'g', 'Gain', 3);
fixe = add_block(fixe, 'datatypeconversion', 'dtc', 'OutDataTypeStr', 'int8', 'RndMeth', 'Nearest');
fixe = add_block(fixe, 'datatypeconversion', 'si', 'OutDataTypeStr', 'int16', ...
                 'ConvertRealWorld', 'Stored Integer (SI)');
fixe = add_block(fixe, 'toworkspace', 'tw', 'VariableName', 'sommeFixe', 'SaveFormat', 'Array');
for nomSortie = {'ys', 'yp', 'yg', 'yd', 'yi'}
    fixe = add_block(fixe, 'outport', nomSortie{1});
end
fixe = add_line(add_line(fixe, 'c', 's/1'), 'd', 's/2');
fixe = add_line(add_line(fixe, 'c', 'p/1'), 'd', 'p/2');
fixe = add_line(add_line(add_line(fixe, 'c', 'g'), 's', 'dtc'), 'c', 'si');
fixe = add_line(add_line(add_line(fixe, 's', 'ys'), 'p', 'yp'), 'g', 'yg');
fixe = add_line(add_line(add_line(fixe, 'dtc', 'yd'), 'si', 'yi'), 's', 'tw');
c = matlibre_sl_compiler(fixe);
noms = {};
for k = 1:c.n
    if c.nOut(k) > 0
        noms(end + 1, :) = {c.noms{k}, matlibre_sl_types('nom', c.typePort(c.portDebut(k)))}; %#ok<SAGROW>
    end
end
attendus = {'c', 'sfix16_En8'; 'd', 'sfix8_En6'; 's', 'sfix17_En8'; 'p', 'sfix24_En14'; ...
            'g', 'sfix32_En21'; 'dtc', 'int8'; 'si', 'int16'};
for i = 1:size(attendus, 1)
    assert(strcmp(noms{strcmp(noms(:, 1), attendus{i, 1}), 2}, attendus{i, 2}), ...
           sprintf('le type de %s est %s', attendus{i, :}));
end
r = sim(fixe, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1);
cq = 804 / 256;   % pi sur la grille 2^-8
dq = 6 / 64;      % 0.1 sur la grille 2^-6
assert(isequal(r.yout(1, :), [cq + dq, cq * dq, 3 * cq, 3, 804]), ...
       'somme, produit et gain exacts ; int8 arrondi au plus proche ; entier stocke garde');
assert(isfi(sommeFixe) && sommeFixe.WordLength == 17 && sommeFixe.FractionLength == 8 && ...
       double(sommeFixe(1)) == cq + dq, 'To Workspace rend des FI de son type');
% arrondis et débordements d'un gain de type imposé
arrondi = new_system('arrondi');
arrondi = add_block(arrondi, 'constant', 'c', 'Value', [3; -3], 'OutDataTypeStr', 'fixdt(1,16,0)');
arrondi = add_block(arrondi, 'gain', 'g', 'Gain', 0.5, 'OutDataTypeStr', 'fixdt(1,16,0)');
arrondi = add_line(add_line(add_block(arrondi, 'outport', 'y'), 'c', 'g'), 'g', 'y');
methodes = {'Floor', [1 -2]; 'Ceiling', [2 -1]; 'Zero', [1 -1]; 'Nearest', [2 -1]; ...
            'Round', [2 -2]; 'Convergent', [2 -2]};
for i = 1:size(methodes, 1)
    r = sim(set_param(arrondi, 'g', 'RndMeth', methodes{i, 1}), 'Solver', ...
            'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 0);
    assert(isequal(double(r.yout(1, :)), methodes{i, 2}), ...
           sprintf('RndMeth %s : 1.5 et -1.5 donnent %s', methodes{i, 1}, mat2str(methodes{i, 2})));
end
deborde = set_param(set_param(arrondi, 'c', 'Value', 3.14, 'OutDataTypeStr', 'fixdt(1,16,8)'), ...
                    'g', 'Gain', 100, 'OutDataTypeStr', 'fixdt(1,16,8)');
r = sim(deborde, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 0);
assert(double(r.yout(1)) == mod(round(3.140625 * 100 * 256) + 32768, 65536) / 256 - 128, ...
       'sans saturation, un debordement se replie');
r = sim(set_param(deborde, 'g', 'SaturateOnIntegerOverflow', 'on'), 'Solver', ...
        'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 0);
assert(double(r.yout(1)) == 32767 / 256, 'avec saturation, il sature');
% un Simulink.NumericType de l'espace de travail ; une MATLAB Function recoit des FI
assignin('base', 'TypeCapteur', fixdt(0, 12, 4));
capteur = new_system('capteur');
capteur = add_block(capteur, 'constant', 'c', 'Value', 7.3, 'OutDataTypeStr', 'TypeCapteur');
capteur = add_block(capteur, 'matlabfunction', 'm', 'Script', ...
                    sprintf('function [y, estFi] = fcn(u)\ny = u * 2;\nestFi = double(isfi(u));\n'));
capteur = add_block(add_block(capteur, 'outport', 'y'), 'outport', 'f');
capteur = add_line(add_line(add_line(capteur, 'c', 'm'), 'm/1', 'y'), 'm/2', 'f');
c = matlibre_sl_compiler(capteur);
assert(strcmp(matlibre_sl_types('nom', c.typePort(c.portDebut(1))), 'ufix12_En4'), ...
       'le type nomme dans l''espace de travail');
r = sim(capteur, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 0);
assert(isequal(r.yout(1, :), [2 * 117 / 16, 1]), 'la MATLAB Function calcule en virgule fixe');
fichierFixe = [tempname() '.slx'];
save_system(fixe, fichierFixe);
r2 = sim(load_system(fichierFixe), 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1);
r = sim(fixe, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1);
assert(isequal(r2.yout, r.yout), 'un modele a virgule fixe se relit du .slx');
delete(fichierFixe);
% ce que Simulink refuse
refusFixe = {
    @() sim(set_param(fixe, 'c', 'Value', 200), 1), 'Simulink:Parameters:ParamOverflow', 'fixe/c'
    @() sim(set_param(fixe, 'c', 'OutDataTypeStr', 'fixdt(1,16'), 1), ...
        'Simulink:DataType:UnknownDataType', 'fixe/c'
    @() sim(set_param(fixe, 'c', 'OutDataTypeStr', 'sfix16_Ex'), 1), ...
        'Simulink:DataType:UnknownDataType', 'fixe/c'
    @() sim(set_param(fixe, 'g', 'OutDataTypeStr', 'fixdt(1,16)'), 1), ...
        'Simulink:DataType:UnspecifiedScaling', 'fixe/g'
    @() sim(add_line(add_block(fixe, 'integrator', 'int'), 'c', 'int'), 1), ...
        'Simulink:DataType:InputPortDataTypeMismatch', 'sfix16_En8'
    };
for kF = 1:size(refusFixe, 1)
    vu = '';
    message = '';
    try
        evalc('refusFixe{kF, 1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, refusFixe{kF, 2}) && ~isempty(strfind(message, refusFixe{kF, 3})), ...
           sprintf('virgule fixe, cas %d : %s attendu, %s rendu (%s)', kF, refusFixe{kF, 2}, ...
                   vu, message));
end
% le paramètre d'un gain à entrée à virgule fixe est lui-même quantifié
quantifie = new_system('quantifie');
quantifie = add_block(quantifie, 'constant', 'c', 'Value', 1, 'OutDataTypeStr', 'fixdt(1,16,8)');
quantifie = add_block(quantifie, 'gain', 'g', 'Gain', 0.1);
quantifie = add_block(quantifie, 'gain', 'h', 'Gain', 0.1, 'ParamDataTypeStr', 'fixdt(1,8,4)');
quantifie = add_block(quantifie, 'sum', 's', 'OutDataTypeStr', 'Inherit: Same as first input');
quantifie = add_block(add_block(add_block(quantifie, 'outport', 'yg'), 'outport', 'yh'), 'outport', 'ys');
quantifie = add_line(add_line(add_line(quantifie, 'c', 'g'), 'c', 'h'), 'g', 'yg');
quantifie = add_line(add_line(add_line(quantifie, 'h', 'yh'), 'g', 's/1'), 'c', 's/2');
quantifie = add_line(quantifie, 's', 'ys');
c = matlibre_sl_compiler(quantifie);
typeDe = @(nom) matlibre_sl_types('nom', c.typePort(c.portDebut(find(strcmp(c.noms, nom), 1))));
assert(strcmp(typeDe('g'), 'sfix32_En26') && strcmp(typeDe('h'), 'sfix24_En12') && ...
       strcmp(typeDe('s'), 'sfix32_En26'), 'gain : entree fois parametre ; Same as first input');
r = sim(quantifie, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 0);
assert(isequal(double(r.yout(1, 1:2)), [round(0.1 * 2 ^ 18) / 2 ^ 18, 2 / 16]), ...
       'le gain 0.1 est range sur 16 bits, meilleure precision, ou dans ParamDataTypeStr');
% la condition initiale d'un retard se range sur la grille de son type
retardFixe = new_system('retardFixe');
retardFixe = add_block(retardFixe, 'constant', 'c', 'Value', 1, 'OutDataTypeStr', 'fixdt(1,16,8)');
retardFixe = add_block(retardFixe, 'unitdelay', 'd', 'InitialCondition', 0.1, 'SampleTime', 1);
retardFixe = add_line(add_line(add_block(retardFixe, 'outport', 'y'), 'c', 'd'), 'd', 'y');
r = sim(retardFixe, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1);
assert(isequal(double(r.yout), [26 / 256; 1]), 'la condition initiale 0.1 devient 26/256');
fprintf('virgule fixe : %d refus nommes verifies\n', size(refusFixe, 1));
%% ----------------------------------------------- 50. Réseaux électriques Simscape
% Les blocs de Simscape se relient par leurs ports physiques — LConn à
% gauche, RConn à droite — et chaque réseau, avec son Solver Configuration
% et sa référence, se met en équations par l'analyse nodale modifiée :
% il devient une représentation d'état, que tous les solveurs intègrent et
% que LINMOD linéarise. Un courant va du + au - à travers un bloc.
rc = new_system('rc');
rc = add_block(rc, 'dcvoltagesource', 'V', 'v0', 5);
rc = add_block(rc, 'resistor', 'R', 'R', 1, 'R_unit', 'kOhm');
rc = add_block(rc, 'capacitor', 'C', 'c', 1, 'c_unit', 'uF', 'r', 0);
rc = add_block(rc, 'electricalreference', 'G');
rc = add_block(rc, 'solverconfiguration', 'S');
rc = add_block(rc, 'voltagesensor', 'VS');
rc = add_block(rc, 'currentsensor', 'IS');
rc = add_block(rc, 'pssimulinkconverter', 'PS');
rc = add_block(rc, 'pssimulinkconverter', 'PI');
rc = add_block(add_block(rc, 'outport', 'v'), 'outport', 'i');
rc = add_line(rc, 'V/LConn1', 'IS/LConn1');
rc = add_line(rc, 'IS/RConn1', 'R/LConn1');
rc = add_line(rc, 'R/RConn1', 'C/LConn1');
rc = add_line(rc, 'C/RConn1', 'G/LConn1');
rc = add_line(rc, 'V/RConn1', 'G/LConn1');
rc = add_line(rc, 'S/RConn1', 'G/LConn1');
rc = add_line(rc, 'VS/LConn1', 'C/LConn1');
rc = add_line(rc, 'VS/RConn1', 'C/RConn1');
rc = add_line(add_line(rc, 'VS', 'PS'), 'PS', 'v');
rc = add_line(add_line(rc, 'IS', 'PI'), 'PI', 'i');
r = sim(rc, 'Solver', 'ode4', 'FixedStep', 1e-5, 'StopTime', 5e-3);
tau = 1e-3;
attendu = [5 * (1 - exp(-r.tout / tau)), 5e-3 * exp(-r.tout / tau)];
assert(max(abs(r.yout(:, 1) - attendu(:, 1))) < 1e-8 && ...
       max(abs(r.yout(:, 2) - attendu(:, 2))) < 1e-11, ...
       'RC : la tension monte en 1 - exp(-t/RC), le courant decroit');
r = sim(rc, 'Solver', 'ode45', 'StopTime', 5e-3, 'RelTol', 1e-8, 'AbsTol', 1e-10);
assert(abs(r.yout(end, 1) - 5 * (1 - exp(-5))) < 1e-6, 'RC a pas variable');
[A, B, C, D] = linmod(rc);
assert(abs(A + 1000) < 1e-3 && isempty(B) && isequal(size(C), [2 1]), ...
       'LINMOD voit un etat, la tension du condensateur');
% RLC série commandé : une Controlled Voltage Source, un échelon
rlc = new_system('rlc');
rlc = add_block(rlc, 'step', 'u', 'Time', 0, 'After', 1);
rlc = add_block(rlc, 'simulinkpsconverter', 'SP');
rlc = add_block(rlc, 'controlledvoltagesource', 'V');
rlc = add_block(rlc, 'resistor', 'R', 'R', 2);
rlc = add_block(rlc, 'inductor', 'L', 'l', 1, 'g', 0);
rlc = add_block(rlc, 'capacitor', 'C', 'c', 0.5, 'r', 0);
rlc = add_block(rlc, 'electricalreference', 'G');
rlc = add_block(rlc, 'solverconfiguration', 'S');
rlc = add_block(rlc, 'voltagesensor', 'VS');
rlc = add_block(rlc, 'outport', 'y');
rlc = add_line(add_line(rlc, 'u', 'SP'), 'SP', 'V');
rlc = add_line(rlc, 'V/LConn1', 'R/LConn1');
rlc = add_line(rlc, 'R/RConn1', 'L/LConn1');
rlc = add_line(rlc, 'L/RConn1', 'C/LConn1');
rlc = add_line(rlc, 'C/RConn1', 'G/LConn1');
rlc = add_line(rlc, 'V/RConn1', 'G/LConn1');
rlc = add_line(rlc, 'S/RConn1', 'V/RConn1');
rlc = add_line(rlc, 'VS/LConn1', 'C/LConn1');
rlc = add_line(rlc, 'VS/RConn1', 'G/LConn1');
rlc = add_line(rlc, 'VS', 'y');
r = sim(rlc, 'Solver', 'ode45', 'StopTime', 5, 'RelTol', 1e-9, 'AbsTol', 1e-12);
% LC s^2 + RC s + 1 = 0,5 s^2 + s + 1 : racines -1 +- i
t = r.tout;
exacte = 1 - exp(-t) .* (cos(t) + sin(t));
assert(max(abs(r.yout - exacte)) < 1e-6, 'RLC serie : la reponse indicielle exacte');
% une source de courant sinusoïdale dans une résistance
ac = new_system('ac');
ac = add_block(ac, 'accurrentsource', 'I', 'amp', 2, 'amp_unit', 'mA', 'frequency', 50, ...
               'shift', 90);
ac = add_block(ac, 'resistor', 'R', 'R', 1, 'R_unit', 'kOhm');
ac = add_block(ac, 'electricalreference', 'G');
ac = add_block(ac, 'solverconfiguration', 'S');
ac = add_block(ac, 'voltagesensor', 'VS');
ac = add_block(ac, 'outport', 'y');
ac = add_line(ac, 'I/RConn1', 'R/LConn1');
ac = add_line(ac, 'R/RConn1', 'G/LConn1');
ac = add_line(ac, 'I/LConn1', 'G/LConn1');
ac = add_line(ac, 'S/RConn1', 'G/LConn1');
ac = add_line(ac, 'VS/LConn1', 'R/LConn1');
ac = add_line(ac, 'VS/RConn1', 'R/RConn1');
ac = add_line(ac, 'VS', 'y');
r = sim(ac, 'Solver', 'ode4', 'FixedStep', 1e-4, 'StopTime', 0.02);
assert(max(abs(r.yout - 2 * cos(2 * pi * 50 * r.tout))) < 1e-9, ...
       'le courant sort par le - : 2 mA dans 1 kOhm, dephase de 90 degres');
% un réseau dans un sous-système : ses connexions suivent ses blocs au dépliage
interne = new_system('filtre');
interne = add_block(interne, 'inport', 'u');
interne = add_block(interne, 'simulinkpsconverter', 'SP');
interne = add_block(interne, 'controlledvoltagesource', 'V');
interne = add_block(interne, 'resistor', 'R', 'R', 1, 'R_unit', 'kOhm');
interne = add_block(interne, 'capacitor', 'C', 'c', 1, 'c_unit', 'uF', 'r', 0);
interne = add_block(interne, 'electricalreference', 'G');
interne = add_block(interne, 'solverconfiguration', 'S');
interne = add_block(interne, 'voltagesensor', 'VS');
interne = add_block(interne, 'outport', 'y');
interne = add_line(add_line(interne, 'u', 'SP'), 'SP', 'V');
interne = add_line(interne, 'V/LConn1', 'R/LConn1');
interne = add_line(interne, 'R/RConn1', 'C/LConn1');
interne = add_line(interne, 'C/RConn1', 'G/LConn1');
interne = add_line(interne, 'V/RConn1', 'G/LConn1');
interne = add_line(interne, 'S/RConn1', 'G/LConn1');
interne = add_line(interne, 'VS/LConn1', 'C/LConn1');
interne = add_line(interne, 'VS/RConn1', 'G/LConn1');
interne = add_line(interne, 'VS', 'y');
dehors = new_system('dehors');
dehors = add_block(dehors, 'step', 'e', 'Time', 0, 'After', 2);
dehors = add_block(dehors, 'subsystem', 'rc', 'Model', interne);
dehors = add_block(dehors, 'outport', 'y');
dehors = add_line(add_line(dehors, 'e', 'rc'), 'rc', 'y');
r = sim(dehors, 'Solver', 'ode4', 'FixedStep', 1e-5, 'StopTime', 3e-3);
assert(abs(r.yout(end) - 2 * (1 - exp(-3))) < 1e-8, 'un reseau dans un sous-systeme');
% un réseau dont tous les nœuds sont à la référence n'a rien à résoudre
court = new_system('court');
court = add_block(court, 'resistor', 'R');
court = add_block(court, 'electricalreference', 'G');
court = add_block(court, 'solverconfiguration', 'S');
court = add_block(court, 'voltagesensor', 'VS');
court = add_line(add_line(court, 'R/LConn1', 'G/LConn1'), 'R/RConn1', 'G/LConn1');
court = add_line(add_line(court, 'S/RConn1', 'G/LConn1'), 'VS/LConn1', 'R/LConn1');
court = add_line(court, 'VS/RConn1', 'G/LConn1');
court = add_line(add_block(court, 'outport', 'y'), 'VS', 'y');
r = sim(court, 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 0.2);
assert(isequal(r.yout, zeros(3, 1)), 'une resistance court-circuitee ne porte aucune tension');
% .slx et .m relisent les connexions physiques
for ext = {'.slx', '.m'}
    fichierRLC = [tempname() ext{1}];
    save_system(rlc, fichierRLC);
    r2 = sim(load_system(fichierRLC), 'Solver', 'ode45', 'StopTime', 5, 'RelTol', 1e-9, ...
             'AbsTol', 1e-12);
    assert(max(abs(r2.yout(end) - exacte(end))) < 1e-6, ['relu par ' ext{1}]);
    delete(fichierRLC);
end
% ce que Simscape refuse
sansConfig = delete_block(rc, 'S');
sansRef = delete_block(rc, 'G');
sansRef = add_line(sansRef, 'S/RConn1', 'C/RConn1');
% une source de courant qui débite dans une résistance que rien ne ramène
% à la référence : la tension de cet îlot n'est pas déterminée
flottant = add_block(add_block(rc, 'dccurrentsource', 'If'), 'resistor', 'Rf');
flottant = add_line(add_line(flottant, 'If/LConn1', 'C/LConn1'), 'If/RConn1', 'Rf/LConn1');
doubleConfig = add_line(add_block(rc, 'solverconfiguration', 'S2'), 'S2/RConn1', 'G/LConn1');
boucle = add_line(add_block(rc, 'dcvoltagesource', 'V2', 'v0', 1), 'V2/LConn1', 'C/LConn1');
boucle = add_line(boucle, 'V2/RConn1', 'G/LConn1');
refusPhysique = {
    @() sim(sansConfig, 1e-3), 'Simscape:Network:SolverConfigurationMissing', 'rc/R'
    @() sim(sansRef, 1e-3), 'Simscape:Network:ReferenceMissing', 'rc/C'
    @() sim(flottant, 1e-3), 'Simscape:Network:SingularNetwork', 'rc/Rf'
    @() sim(doubleConfig, 1e-3), 'Simscape:Network:MultipleSolverConfigurations', 'rc/S2'
    @() sim(boucle, 1e-3), 'Simscape:Network:SingularNetwork', 'rc/V2'
    @() add_line(rc, 'VS', 'R/LConn1'), 'Simulink:Commands:AddLinePhysicalPort', 'LConn'
    @() add_line(rc, 'R/LConn2', 'C/LConn1'), 'Simulink:Commands:AddLineInvalidPort', 'rc'
    @() add_line(rc, 'G/RConn1', 'C/LConn1'), 'Simulink:Commands:AddLineInvalidPort', 'G'
    @() add_line(rc, 'R/RConn1', 'C/LConn1'), 'Simulink:Commands:AddLineDestConnected', 'rc'
    @() sim(set_param(rc, 'R', 'R', 0), 1e-3), 'Simulink:Parameters:InvParamSetting', 'rc/R'
    @() sim(set_param(rc, 'R', 'R_unit', 'furlong'), 1e-3), ...
        'Simulink:Parameters:InvParamSetting', 'furlong'
    };
for kP = 1:size(refusPhysique, 1)
    vu = '';
    message = '';
    try
        evalc('refusPhysique{kP, 1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, refusPhysique{kP, 2}) && ~isempty(strfind(message, refusPhysique{kP, 3})), ...
           sprintf('Simscape, cas %d : %s attendu, %s rendu (%s)', kP, refusPhysique{kP, 2}, ...
                   vu, message));
end
fprintf('reseaux electriques : %d refus nommes verifies\n', size(refusPhysique, 1));
%% ------------------------------------ 51. Réseaux mécaniques, électromécaniques et thermiques
% La même mise en équations vaut en mécanique : une vitesse est une
% grandeur « à travers », une force ou un couple une grandeur
% « traversante ». Une masse, une inertie sont des condensateurs vers la
% référence, un ressort une bobine, un amortisseur une conductance. Le
% convertisseur électromécanique lie les deux domaines : v = K w,
% couple = K i. Un capteur de mouvement rend la vitesse et la position.
msd = new_system('msd');
msd = add_block(msd, 'step', 'f', 'Time', 0, 'After', 10);
msd = add_block(msd, 'simulinkpsconverter', 'SP');
msd = add_block(msd, 'idealforcesource', 'F');
msd = add_block(msd, 'mass', 'M', 'mass', 1000, 'mass_unit', 'g');
msd = add_block(msd, 'translationalspring', 'K', 'spr_rate', 10);
msd = add_block(msd, 'translationaldamper', 'B', 'D', 2);
msd = add_block(msd, 'mechanicaltranslationalreference', 'G');
msd = add_block(msd, 'solverconfiguration', 'S');
msd = add_block(msd, 'idealtranslationalmotionsensor', 'X');
msd = add_block(add_block(msd, 'outport', 'v'), 'outport', 'x');
msd = add_line(add_line(msd, 'f', 'SP'), 'SP', 'F');
msd = add_line(msd, 'F/LConn1', 'M/LConn1');
msd = add_line(msd, 'F/RConn1', 'G/LConn1');
msd = add_line(msd, 'K/LConn1', 'M/LConn1');
msd = add_line(msd, 'K/RConn1', 'G/LConn1');
msd = add_line(msd, 'B/LConn1', 'M/LConn1');
msd = add_line(msd, 'B/RConn1', 'G/LConn1');
msd = add_line(msd, 'S/RConn1', 'G/LConn1');
msd = add_line(msd, 'X/LConn1', 'M/LConn1');
msd = add_line(msd, 'X/RConn1', 'G/LConn1');
msd = add_line(add_line(msd, 'X/1', 'v'), 'X/2', 'x');
r = sim(msd, 'Solver', 'ode45', 'StopTime', 6, 'RelTol', 1e-9, 'AbsTol', 1e-12);
t = r.tout;
% x'' + 2 x' + 10 x = 10 : racines -1 +- 3i
xExact = 1 - exp(-t) .* (cos(3 * t) + sin(3 * t) / 3);
vExact = exp(-t) .* (10 / 3) .* sin(3 * t);
assert(max(abs(r.yout(:, 2) - xExact)) < 1e-6 && max(abs(r.yout(:, 1) - vExact)) < 1e-6, ...
       'masse, ressort, amortisseur : la force pousse la masse, le capteur rend v et x');
% une inertie freinée par un amortisseur, sous un couple
rot = new_system('rot');
rot = add_block(rot, 'constant', 'c', 'Value', 1);
rot = add_block(rot, 'idealtorquesource', 'T');
rot = add_block(rot, 'inertia', 'J', 'inertia', 0.01);
rot = add_block(rot, 'rotationaldamper', 'D', 'D', 0.1);
rot = add_block(rot, 'mechanicalrotationalreference', 'G');
rot = add_block(rot, 'solverconfiguration', 'S');
rot = add_block(rot, 'idealrotationalmotionsensor', 'W', 'phi0', 90, 'phi0_unit', 'deg');
rot = add_block(add_block(rot, 'outport', 'w'), 'outport', 'a');
rot = add_line(rot, 'c', 'T');
rot = add_line(rot, 'T/LConn1', 'J/LConn1');
rot = add_line(rot, 'T/RConn1', 'G/LConn1');
rot = add_line(rot, 'D/LConn1', 'J/LConn1');
rot = add_line(rot, 'D/RConn1', 'G/LConn1');
rot = add_line(rot, 'S/RConn1', 'G/LConn1');
rot = add_line(rot, 'W/LConn1', 'J/LConn1');
rot = add_line(rot, 'W/RConn1', 'G/LConn1');
rot = add_line(add_line(rot, 'W/1', 'w'), 'W/2', 'a');
r = sim(rot, 'Solver', 'ode4', 'FixedStep', 1e-4, 'StopTime', 0.5);
t = r.tout;
assert(max(abs(r.yout(:, 1) - 10 * (1 - exp(-10 * t)))) < 1e-8 && ...
       max(abs(r.yout(:, 2) - (pi / 2 + 10 * t - (1 - exp(-10 * t))))) < 1e-8, ...
       'inertie et amortisseur : w = 10 (1 - exp(-10 t)), l''angle part de 90 degres');
% un moteur à courant continu : v = R i + L di/dt + K w, K i = J dw/dt + D w
moteur = new_system('moteur');
moteur = add_block(moteur, 'dcvoltagesource', 'V', 'v0', 12);
moteur = add_block(moteur, 'resistor', 'R', 'R', 1);
moteur = add_block(moteur, 'inductor', 'L', 'l', 10, 'l_unit', 'mH', 'g', 0);
moteur = add_block(moteur, 'rotationalelectromechanicalconverter', 'M', 'K', 0.1);
moteur = add_block(moteur, 'inertia', 'J', 'inertia', 0.001);
moteur = add_block(moteur, 'rotationaldamper', 'D', 'D', 1e-4);
moteur = add_block(moteur, 'electricalreference', 'GE');
moteur = add_block(moteur, 'mechanicalrotationalreference', 'GM');
moteur = add_block(moteur, 'solverconfiguration', 'S');
moteur = add_block(moteur, 'idealrotationalmotionsensor', 'W');
moteur = add_block(moteur, 'currentsensor', 'I');
moteur = add_block(add_block(moteur, 'outport', 'w'), 'outport', 'i');
moteur = add_line(moteur, 'V/LConn1', 'I/LConn1');
moteur = add_line(moteur, 'I/RConn1', 'R/LConn1');
moteur = add_line(moteur, 'R/RConn1', 'L/LConn1');
moteur = add_line(moteur, 'L/RConn1', 'M/LConn1');
moteur = add_line(moteur, 'M/LConn2', 'GE/LConn1');
moteur = add_line(moteur, 'V/RConn1', 'GE/LConn1');
moteur = add_line(moteur, 'M/RConn1', 'J/LConn1');
moteur = add_line(moteur, 'M/RConn2', 'GM/LConn1');
moteur = add_line(moteur, 'D/LConn1', 'J/LConn1');
moteur = add_line(moteur, 'D/RConn1', 'GM/LConn1');
moteur = add_line(moteur, 'W/LConn1', 'J/LConn1');
moteur = add_line(moteur, 'W/RConn1', 'GM/LConn1');
moteur = add_line(moteur, 'S/RConn1', 'GE/LConn1');
moteur = add_line(add_line(moteur, 'W/1', 'w'), 'I', 'i');
r = sim(moteur, 'Solver', 'ode15s', 'StopTime', 2, 'RelTol', 1e-8, 'AbsTol', 1e-10);
wFinal = 12 / (0.1 + 1 * 1e-4 / 0.1);
assert(abs(r.yout(end, 1) - wFinal) < 1e-4 && abs(r.yout(end, 2) - 1e-4 * wFinal / 0.1) < 1e-6, ...
       'moteur a courant continu : sa vitesse et son courant en regime etabli');
assert(max(r.yout(:, 2)) > 5, 'au demarrage, le courant monte vers V / R');
[A, B, C, D] = linmod(moteur);
assert(isequal(size(A), [3 3]) && isempty(B), ...
       'LINMOD : courant de la bobine, vitesse de l''inertie, angle du capteur');
fichierMoteur = [tempname() '.slx'];
save_system(moteur, fichierMoteur);
r2 = sim(load_system(fichierMoteur), 'Solver', 'ode15s', 'StopTime', 2, 'RelTol', 1e-8, ...
         'AbsTol', 1e-10);
assert(abs(r2.yout(end, 1) - r.yout(end, 1)) < 1e-6, 'le moteur se relit du .slx');
delete(fichierMoteur);
% ce que Simscape refuse
sansRefMeca = add_line(delete_block(msd, 'G'), 'S/RConn1', 'M/LConn1');
refusMeca = {
    @() add_line(moteur, 'R/RConn1', 'J/LConn1'), ...
        'Simulink:Commands:AddLinePhysicalDomain', 'rotation'
    @() add_line(msd, 'M/LConn1', 'moteur_absent/LConn1'), ...
        'Simulink:Commands:InvSimulinkObjectName', 'moteur_absent'
    @() sim(sansRefMeca, 1), 'Simscape:Network:ReferenceMissing', ...
        'Mechanical Translational Reference'
    @() sim(set_param(msd, 'M', 'mass_unit', 'Ohm'), 1), ...
        'Simulink:Parameters:InvParamSetting', 'kg'
    @() sim(set_param(msd, 'K', 'spr_rate', -1), 1), ...
        'Simulink:Parameters:InvParamSetting', 'msd/K'
    };
for kM = 1:size(refusMeca, 1)
    vu = '';
    message = '';
    try
        evalc('refusMeca{kM, 1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, refusMeca{kM, 2}) && ~isempty(strfind(message, refusMeca{kM, 3})), ...
           sprintf('mecanique, cas %d : %s attendu, %s rendu (%s)', kM, refusMeca{kM, 2}, ...
                   vu, message));
end
fprintf('reseaux mecaniques : %d refus nommes verifies\n', size(refusMeca, 1));
% Le domaine thermique : une température (absolue, en kelvins) est une
% grandeur « à travers », un flux de chaleur une grandeur « traversante ».
% Une masse thermique est un condensateur vers le zéro absolu ; la
% conduction et la convection sont des conductances. La source de
% température impose T(B) - T(A), le capteur mesure T(A) - T(B).
th = new_system('th');
th = add_block(th, 'constant', 'q', 'Value', 50);
th = add_block(th, 'idealheatflowsource', 'Q');
th = add_block(th, 'thermalmass', 'M', 'mass', 2, 'sp_heat', 500, 'T', 20, 'T_unit', 'degC');
th = add_block(th, 'convectiveheattransfer', 'H', 'area', 0.5, 'heat_tr_coeff', 10);
th = add_block(th, 'constant', 'ambiant', 'Value', 293.15);
th = add_block(th, 'idealtemperaturesource', 'Ta');
th = add_block(th, 'thermalreference', 'G');
th = add_block(th, 'solverconfiguration', 'S');
th = add_block(th, 'idealtemperaturesensor', 'T');
th = add_block(th, 'idealheatflowsensor', 'P');
th = add_block(add_block(th, 'outport', 'y'), 'outport', 'perte');
th = add_line(add_line(th, 'q', 'Q'), 'ambiant', 'Ta');
th = add_line(th, 'Q/LConn1', 'G/LConn1');
th = add_line(th, 'Q/RConn1', 'M/LConn1');
th = add_line(th, 'P/LConn1', 'M/LConn1');
th = add_line(th, 'P/RConn1', 'H/LConn1');
th = add_line(th, 'H/RConn1', 'Ta/RConn1');
th = add_line(th, 'Ta/LConn1', 'G/LConn1');
th = add_line(th, 'S/RConn1', 'G/LConn1');
th = add_line(th, 'T/LConn1', 'M/LConn1');
th = add_line(th, 'T/RConn1', 'G/LConn1');
th = add_line(add_line(th, 'T', 'y'), 'P', 'perte');
r = sim(th, 'Solver', 'ode4', 'FixedStep', 1, 'StopTime', 2000);
t = r.tout;
% m c dT/dt = 50 - h S (T - Ta) : T = Ta + 10 (1 - exp(-t / 200))
assert(max(abs(r.yout(:, 1) - (293.15 + 10 * (1 - exp(-t / 200))))) < 1e-6, ...
       'masse chauffee qui perd par convection : T = Ta + 10 (1 - exp(-t/200))');
assert(max(abs(r.yout(:, 2) - 50 * (1 - exp(-t / 200)))) < 1e-6, ...
       'le capteur de flux mesure la chaleur perdue, de A vers B');
% deux masses reliées par une paroi : la chaleur passe de la chaude à la
% froide, et leur énergie se conserve
paroi = new_system('paroi');
paroi = add_block(paroi, 'thermalmass', 'chaud', 'mass', 1, 'sp_heat', 400, ...
                  'T', 212, 'T_unit', 'degF');
paroi = add_block(paroi, 'thermalmass', 'froid', 'mass', 3, 'sp_heat', 400, ...
                  'T', 20, 'T_unit', 'degC');
paroi = add_block(paroi, 'conductiveheattransfer', 'mur', 'area', 20, 'area_unit', 'cm^2', ...
                  'thickness', 5, 'thickness_unit', 'mm', 'th_cond', 50, ...
                  'th_cond_unit', 'W/(K*m)');
paroi = add_block(paroi, 'thermalreference', 'G');
paroi = add_block(paroi, 'solverconfiguration', 'S');
paroi = add_block(paroi, 'idealtemperaturesensor', 'T');
paroi = add_block(paroi, 'outport', 'y');
paroi = add_line(paroi, 'mur/LConn1', 'chaud/LConn1');
paroi = add_line(paroi, 'mur/RConn1', 'froid/LConn1');
paroi = add_line(paroi, 'T/LConn1', 'chaud/LConn1');
paroi = add_line(paroi, 'T/RConn1', 'G/LConn1');
paroi = add_line(paroi, 'S/RConn1', 'G/LConn1');
paroi = add_line(paroi, 'T', 'y');
r = sim(paroi, 'Solver', 'ode45', 'StopTime', 200, 'RelTol', 1e-9, 'AbsTol', 1e-9);
t = r.tout;
% G = 50 * 20e-4 / 5e-3 = 20 W/K ; C1 = 400, C2 = 1200 J/K ; tau = 1 / (G (1/C1 + 1/C2)) = 15 s
tFinal = (400 * 373.15 + 1200 * 293.15) / 1600;
assert(max(abs(r.yout - (tFinal + (373.15 - tFinal) * exp(-t / 15)))) < 1e-5, ...
       'deux masses et une paroi : 212 degF et 20 degC tendent vers leur moyenne ponderee');
fichierParoi = [tempname() '.slx'];
save_system(paroi, fichierParoi);
r2 = sim(load_system(fichierParoi), 'Solver', 'ode45', 'StopTime', 200, 'RelTol', 1e-9, ...
         'AbsTol', 1e-9);
assert(abs(r2.yout(end) - r.yout(end)) < 1e-6, 'le modele thermique se relit du .slx');
delete(fichierParoi);
[A, B, C, D] = linmod(paroi);
assert(isequal(size(A), [2 2]) && abs(max(real(eig(A))) - 0) < 1e-9 && ...
       abs(min(real(eig(A))) + 1 / 15) < 1e-9, ...
       'LINMOD : deux temperatures, un mode conserve, un mode de 15 s');
refusThermique = {
    @() add_line(add_block(th, 'resistor', 'R'), 'M/LConn1', 'R/LConn1'), ...
        'Simulink:Commands:AddLinePhysicalDomain', 'thermique'
    @() sim(set_param(th, 'M', 'T_unit', 'Ohm'), 1), ...
        'Simulink:Parameters:InvParamSetting', 'degC'
    @() sim(set_param(th, 'H', 'area', 0), 1), ...
        'Simulink:Parameters:InvParamSetting', 'th/H'
    @() sim(add_line(delete_block(paroi, 'G'), 'S/RConn1', 'froid/LConn1'), 1), ...
        'Simscape:Network:ReferenceMissing', 'Thermal Reference'
    };
for kT = 1:size(refusThermique, 1)
    vu = '';
    message = '';
    try
        evalc('refusThermique{kT, 1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, refusThermique{kT, 2}) && ...
           ~isempty(strfind(message, refusThermique{kT, 3})), ...
           sprintf('thermique, cas %d : %s attendu, %s rendu (%s)', kT, ...
                   refusThermique{kT, 2}, vu, message));
end
fprintf('reseaux thermiques : %d refus nommes verifies\n', size(refusThermique, 1));

disp('simulink : toutes les verifications passent');

function p = etendreSource(type, p)
    % La même source sur trois voies : chacune décalée de la précédente.
    switch type
        case 'sine'
            p = [p, {'Bias', [0; 0.2; -0.3]}];
        case 'ramp'
            p{2} = [0.7; 0.35; -0.2];
        case 'step'
            p{6} = [-0.6; 0.1; 1.2];
    end
end

function aire = integrerParMorceaux(f, a, b, coupures)
    % L'intégrale d'une fonction qui casse en des instants connus : un
    % morceau lisse après l'autre.
    bornes = unique([a, coupures(coupures > a & coupures < b), b]);
    aire = 0;
    for k = 1:numel(bornes) - 1
        aire = aire + integral(f, bornes(k), bornes(k + 1), 'AbsTol', 1e-13, 'RelTol', 1e-12);
    end
end

% Un modèle : le bloc T, ses entrées nourries par des sources, ses
% sorties vers des OUTPORT ; la première entrée peut venir d'un autre bloc.
function [s, ok] = batterieModele(nom, types, valeur)
    s = new_system(nom);
    ok = false;
    for q = 1:numel(types)
        s = add_block(s, types{q}, sprintf('b%d', q));
    end
    for q = 1:numel(types)
        [ne, ns] = matlibre_sl_ports(s.blocs{q});
        if isnan(ne), ne = 1; end
        if isnan(ns), ns = 1; end
        if q < numel(types) && (ns == 0 || ne == 0 && q > 1)
            return
        end
        premiere = 1 + (q > 1);
        for i = premiere:ne
            source = sprintf('c%d_%d', q, i);
            s = add_block(s, 'constant', source, 'Value', valeur);
            s = add_line(s, [source '/1'], sprintf('b%d/%d', q, i));
        end
        for j = 1 + (q < numel(types)):ns
            puits = sprintf('o%d_%d', q, j);
            s = add_block(s, 'outport', puits);
            s = add_line(s, sprintf('b%d/%d', q, j), [puits '/1']);
        end
        if q < numel(types)
            [ne2, ~] = matlibre_sl_ports(s.blocs{q + 1});
            if ~isnan(ne2) && ne2 == 0
                return
            end
            s = add_line(s, sprintf('b%d/1', q), sprintf('b%d/1', q + 1));
        end
    end
    ok = true;
end

% Simuler, et ne tolérer que les erreurs de Simulink.
function id = batterieSimuler(s, solveur, contexte)
    id = 'ok';
    try
        evalc('sim(s, ''Solver'', solveur, ''FixedStep'', 0.1, ''StopTime'', 0.5);');
    catch err
        id = err.identifier;
        assert(strncmp(id, 'Simulink:', 9) || strncmp(id, 'Stateflow:', 10) || ...
               strncmp(id, 'Simscape:', 9), ...
               sprintf('%s (%s) : erreur interne %s : %s', contexte, solveur, id, err.message));
        assert(~isempty(strfind(err.message, [s.nom '/'])), ...
               sprintf('%s (%s) : le message ne nomme pas de bloc : %s', contexte, ...
                       solveur, err.message));
    end
end

% Un modèle où le bloc T est seul dans un sous-système : activé,
% déclenché, itéré, masqué, ou sous une période discrète.
function m = batterieContexte(type, contexte)
    interne = new_system('dedans');
    interne = add_block(interne, type, 'b');
    [ne, ns] = matlibre_sl_ports(interne.blocs{end});
    if isnan(ne), ne = 1; end
    if isnan(ns), ns = 1; end
    for i = 1:ne
        interne = add_block(interne, 'inport', sprintf('in%d', i));
        interne = add_line(interne, sprintf('in%d/1', i), sprintf('b/%d', i));
    end
    for j = 1:ns
        interne = add_block(interne, 'outport', sprintf('out%d', j));
        interne = add_line(interne, sprintf('b/%d', j), sprintf('out%d/1', j));
    end
    switch contexte
        case 'enable'
            interne = add_block(interne, 'enableport', 'Enable');
        case 'trigger'
            interne = add_block(interne, 'triggerport', 'Trigger');
        case 'for'
            interne = add_block(interne, 'foriterator', 'iteration', 'IterationLimit', 3);
    end
    m = new_system('ctx');
    if strcmp(contexte, 'masque')
        m = add_block(m, 'subsystem', 'sous', 'Model', interne, 'Mask', 'on', ...
                      'MaskVariables', 'k=@1;', 'MaskValueString', '2');
    else
        m = add_block(m, 'subsystem', 'sous', 'Model', interne);
    end
    periode = 0;
    if strcmp(contexte, 'discret'), periode = 0.1; end
    for i = 1:ne
        m = add_block(m, 'sine', sprintf('u%d', i), 'Amplitude', 0.5, 'Bias', 1.5, ...
                      'SampleTime', periode);
        m = add_line(m, sprintf('u%d/1', i), sprintf('sous/%d', i));
    end
    switch contexte
        case 'enable'
            m = add_block(m, 'pulsegenerator', 'porte', 'Period', 0.4, 'PulseWidth', 50);
            m = add_line(m, 'porte/1', 'sous/Enable');
        case 'trigger'
            m = add_block(m, 'pulsegenerator', 'porte', 'Period', 0.2, 'PulseWidth', 50);
            m = add_line(m, 'porte/1', 'sous/Trigger');
    end
    for j = 1:ns
        m = add_block(m, 'outport', sprintf('o%d', j));
        m = add_line(m, sprintf('sous/%d', j), sprintf('o%d/1', j));
    end
end

% Le bloc T, un paramètre mis à une valeur fautive, ses entrées nourries
% par des sinus, ses sorties vers des OUTPORT.
function s = batterieFautif(type, nom, valeur)
    s = new_system('fautif');
    s = add_block(s, type, 'b', nom, valeur);
    [ne, ns] = matlibre_sl_ports(s.blocs{end});
    if isnan(ne), ne = 1; end
    if isnan(ns), ns = 1; end
    for i = 1:ne
        s = add_block(s, 'sine', sprintf('c%d', i), 'Bias', 1.5);
        s = add_line(s, sprintf('c%d/1', i), sprintf('b/%d', i));
    end
    for j = 1:ns
        s = add_block(s, 'outport', sprintf('o%d', j));
        s = add_line(s, sprintf('b/%d', j), sprintf('o%d/1', j));
    end
end

% Un Bus Creator typé TYPE, nourri de constantes aux valeurs VALEURS.
function m = busCreeAvec(type, valeurs)
    m = new_system('mauvais');
    m = add_block(m, 'buscreator', 'bc', 'Inputs', num2str(numel(valeurs)), ...
                  'OutDataTypeStr', type);
    for q = 1:numel(valeurs)
        m = add_block(m, 'constant', sprintf('c%d', q), 'Value', valeurs{q});
        m = add_line(m, sprintf('c%d/1', q), sprintf('bc/%d', q));
    end
    m = add_block(m, 'terminator', 't');
    m = add_line(m, 'bc/1', 't/1');
end

% Un modele ou une S-fonction de niveau 2, NOM, recoit PARAMETRES.
function m = niveau2Avec(nom, parametres)
    m = new_system('mauvais');
    m = add_block(m, 'constant', 'u', 'Value', 1);
    m = add_block(m, 'msfunction', 's', 'FunctionName', nom, 'Parameters', parametres);
    m = add_block(m, 'terminator', 't');
    m = add_line(m, 'u/1', 's/1');
    m = add_line(m, 's/1', 't/1');
end

% Un bloc a deux entrees, nourri de deux constantes.
function m = typesDeux(type, valeurA, valeurB, parametres)
    m = new_system('typesDeux');
    m = add_block(m, 'constant', 'a', 'Value', valeurA);
    m = add_block(m, 'constant', 'b', 'Value', valeurB);
    m = add_block(m, type, 'op', parametres{:});
    m = add_block(m, 'outport', 'y');
    m = add_line(m, 'a/1', 'op/1');
    m = add_line(m, 'b/1', 'op/2');
    m = add_line(m, 'op/1', 'y/1');
end

% Poser une propriété d'un objet — une affectation, qu'une fonction
% anonyme ne peut pas écrire.
function objet = poserPropriete(objet, nom, valeur)
    objet.(nom) = valeur;
end


% Un modèle de la batterie au hasard : les blocs en chaîne, leurs entrées
% de plus nourries de constantes, leurs sorties de plus relevées.
function [m, texte] = aleaBatir(nom, types, cat)
    m = new_system(nom);
    texte = '';
    valeurEntree = 1.5;
    typeEntree = {};
    tirage = rand();
    if tirage < 0.3
        valeurEntree = [0.5; 1.5; 2.5];
        texte = ' entrees=vecteur';
    elseif tirage < 0.45
        valeurEntree = 1.5 - 0.5i;   % un complexe, que bien des blocs refusent
        texte = ' entrees=complexe';
    elseif tirage < 0.6
        typeEntree = {'OutDataTypeStr', 'fixdt(1,16,8)'};   % à virgule fixe
        texte = ' entrees=sfix16_En8';
    end
    for q = 1:numel(types)
        e = cat(strcmp({cat.type}, types{q}));
        reglages = {};
        for i = 1:size(e.params, 1)
            nature = e.params{i, 3};
            if iscell(nature) && rand() < 0.4
                valeur = nature{randi(numel(nature))};
                reglages(end + 1:end + 2) = {e.params{i, 1}, valeur}; %#ok<AGROW>
                texte = sprintf('%s %s.%s=%s', texte, types{q}, e.params{i, 1}, valeur);
            elseif strcmp(nature, 'nombre') && isnumeric(e.params{i, 2}) && ...
                   isscalar(e.params{i, 2}) && rand() < 0.15
                genantes = {0, -1, 2, 0.5, [1 2], 1i};
                valeur = genantes{randi(numel(genantes))};
                reglages(end + 1:end + 2) = {e.params{i, 1}, valeur}; %#ok<AGROW>
                texte = sprintf('%s %s.%s=%s', texte, types{q}, e.params{i, 1}, mat2str(valeur));
            end
        end
        m = add_block(m, types{q}, sprintf('b%d', q), reglages{:});
    end
    for q = 1:numel(types)
        [ne, ns] = matlibre_sl_ports(m.blocs{q});
        if isnan(ne), ne = 1; end
        if isnan(ns), ns = 1; end
        for i = 1 + (q > 1):ne
            source = sprintf('c%d_%d', q, i);
            m = add_block(m, 'constant', source, 'Value', valeurEntree, typeEntree{:});
            m = add_line(m, [source '/1'], sprintf('b%d/%d', q, i));
        end
        for j = 1 + (q < numel(types)):ns
            puits = sprintf('o%d_%d', q, j);
            m = add_block(m, 'outport', puits);
            m = add_line(m, sprintf('b%d/%d', q, j), [puits '/1']);
        end
        if q < numel(types)
            [ne2, ~] = matlibre_sl_ports(m.blocs{q + 1});
            [~, nsq] = matlibre_sl_ports(m.blocs{q});
            if (isnan(ne2) || ne2 >= 1) && (isnan(nsq) || nsq >= 1)
                m = add_line(m, sprintf('b%d/1', q), sprintf('b%d/1', q + 1));
            end
        end
    end
end

function [r, id, message] = aleaSimuler(m, solveur)
    r = [];
    id = '';
    message = '';
    try
        evalc('r = sim(m, ''Solver'', solveur, ''FixedStep'', 0.1, ''StopTime'', 1);');
    catch err
        id = err.identifier;
        message = err.message;
    end
end

% Deux relevés égaux : mêmes tailles, mêmes infinis et mêmes NaN, le reste
% au milliardième près.
function oui = aleaMemesValeurs(a, b)
    oui = isequal(size(a), size(b));
    if ~oui
        return
    end
    a = double(a(:));
    b = double(b(:));
    oui = all(a == b | (isnan(a) & isnan(b)) | abs(a - b) <= 1e-9 * max(1, abs(a)));
end

% Un modèle où un signal complexe arrive sur l'entrée 1 du bloc b ; ses
% autres entrées reçoivent des réels.
function m = aleaRefusComplexe(type, varargin)
    m = new_system('refus');
    m = add_block(m, 'constant', 'c', 'Value', 1 + 1i);
    m = add_block(m, 'constant', 'r', 'Value', 1);
    m = add_block(m, type, 'b', varargin{:});
    [ne, ns] = matlibre_sl_ports(m.blocs{end});
    m = add_line(m, 'c', 'b/1');
    for j = 2:ne
        m = add_line(m, 'r', sprintf('b/%d', j));
    end
    for q = 1:ns
        nom = sprintf('y%d', q);
        m = add_line(add_block(m, 'outport', nom), sprintf('b/%d', q), nom);
    end
end
