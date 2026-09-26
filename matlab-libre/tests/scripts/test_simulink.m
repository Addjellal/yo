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
    'comparetoconstant', {'relop', '>=', 'const', 0.2},              @(v) double(v >= 0.2),  0.2
    'comparetozero',     {'relop', '>'},                             @(v) double(v > 0),     0
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
% Deux entrées : la comparaison, le plus grand, l'aiguillage.
cas2 = {
    'relational', {'Operator', '<'},       @(v) double(v < 0.1)
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
    @() set_param(m, 'Solver', 'daessc'), 'Simulink:Commands:SolveurInconnu', 'ode15s'
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
    @() set_param(m, 'Solver', 'odeN'), 'Simulink:Commands:SolveurInconnu', 'ode113'
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
