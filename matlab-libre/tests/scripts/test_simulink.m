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
