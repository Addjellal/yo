% test_simulink_modeles.m — le moteur de Simulink, 4/4 : sections 76 à 111 — les blocs
% complets, les réglages et les fichiers, les références, la forme de MATLAB,
% la linéarisation et les cas de la littérature.
%
% Chaque vérification porte sur une propriété qui définit le calcul : une
% formule fermée, une invariance, un ordre de convergence mesuré, un
% message d'erreur qui nomme le bloc fautif. Les combinaisons sont
% engendrées : sources, traitements, dimensions, solveurs et périodes se
% croisent, et chaque croisement est comparé au calcul direct.
disp('--- simulink modeles ---');
% Le test, quinze mille lignes et vingt-cinq minutes d'un bloc, est coupé en
% quatre parts que la batterie fait tourner de front ; leurs fonctions d'aide
% communes vivent dans simulink/.
addpath(fullfile(fileparts(mfilename('fullpath')), 'simulink'));

%% ------------------------------- 76. Le PID à deux degrés de liberté
% PID Controller (2DOF), comme dans Simulink : deux entrées, la consigne r
% et la mesure y ; la partie proportionnelle lit b r - y, l'intégrale
% r - y, la dérivée filtrée c r - y. Avec b = c = 1, c'est le PID d'un
% degré sur l'écart ; continu ou discret, borné, à remise.
for domaine = {'Continuous-time', 'Discrete-time'}
    solveur76 = {'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 4};
    for poids = {[1 1], [0.5 0], [0 2]}
        b76 = poids{1}(1);
        c76 = poids{1}(2);
        deux76 = sim(boucle76('deux76', b76, c76, domaine{1}, true), solveur76{:});
        trois76 = sim(boucle76('trois76', b76, c76, domaine{1}, false), solveur76{:});
        assert(max(abs(deux76.yout - trois76.yout)) < 1e-9, ...
               sprintf('%s, b = %g, c = %g : le PID 2DOF est P (b r - y) + I (r - y) + D (c r - y)', ...
                       domaine{1}, b76, c76));
    end
end
% la consigne pondérée change la réponse, pas le rejet : b = 0 adoucit
% la montée
doux76 = sim(boucle76('doux76', 0, 0, 'Continuous-time', true), solveur76{:});
vif76 = sim(boucle76('vif76', 1, 1, 'Continuous-time', true), solveur76{:});
assert(max(abs(diff(doux76.yout))) < max(abs(diff(vif76.yout))), ...
       'b = c = 0 : la consigne n''entre que par l''integrale, la montee est douce');
% borné, à remise : quatre entrées, la sortie dans ses bornes
borne76 = new_system('borne76');
borne76 = add_block(borne76, 'step', 'r', 'Time', 0.5, 'After', 10);
borne76 = add_block(borne76, 'constant', 'y', 'Value', 0);
borne76 = add_block(borne76, 'step', 'remise', 'Time', 2);
borne76 = add_block(borne76, 'pidcontroller2dof', 'pid', 'P', 5, 'I', 3, 'D', 0, ...
                    'LimitOutput', 'on', 'UpperSaturationLimit', 2, ...
                    'LowerSaturationLimit', -2, 'AntiWindupMode', 'clamping', ...
                    'ExternalReset', 'rising');
borne76 = add_block(borne76, 'outport', 'u');
borne76 = add_line(add_line(borne76, 'r', 'pid/1'), 'y', 'pid/2');
borne76 = add_line(add_line(borne76, 'remise', 'pid/3'), 'pid', 'u');
r76 = sim(borne76, 'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 3);
assert(all(abs(r76.yout) <= 2 + 1e-12) && abs(r76.yout(end) - 2) < 1e-12, ...
       'le PID 2DOF borne sa sortie');
assert(strcmp(getfield(matlibre_sl_catalogue('type', ...
           'simulink/Discrete/Discrete PID Controller (2DOF)'), 'type'), 'pidcontroller2dof') && ...
       strcmp(get_param(add_block(new_system('d76'), ...
           'simulink/Discrete/Discrete PID Controller (2DOF)', 'p'), 'p', 'TimeDomain'), ...
           'Discrete-time'), 'le Discrete PID Controller (2DOF) de la bibliotheque est discret');
fprintf('PID a deux degres de liberte : ok\n');

%% --------------------------------------------- 77. Le sous-système For Each
% Le For Each Subsystem de Simulink : son modèle calcule une fois par
% tranche de ses entrées découpées (InputPartition, sa dimension, sa
% largeur), chaque tranche avec ses propres états ; les entrées non
% découpées entrent entières, et les sorties sont les tranches concaténées
% (OutputConcatenationDimension). Les découpages impossibles sont refusés
% en nommant le bloc.
dedans77 = new_system('cumul77');
dedans77 = add_block(dedans77, 'inport', 'In1', 'Port', 1);
dedans77 = add_block(dedans77, 'sum', 'paire', 'Signs', '+');
dedans77 = add_block(dedans77, 'sum', 'acc', 'Signs', '++');
dedans77 = add_block(dedans77, 'unitdelay', 'z');
dedans77 = add_block(dedans77, 'outport', 'Out1', 'Port', 1);
dedans77 = add_block(dedans77, 'foreach', 'For Each', 'InputPartition', {'on'}, ...
                     'InputPartitionWidth', {2});
dedans77 = add_line(add_line(dedans77, 'In1', 'paire'), 'paire', 'acc/1');
dedans77 = add_line(add_line(dedans77, 'z', 'acc/2'), 'acc', 'z');
dedans77 = add_line(dedans77, 'acc', 'Out1');
m77 = new_system('chaque77');
m77 = add_block(m77, 'constant', 'u', 'Value', [1 2 3 4], 'SampleTime', 1);
m77 = add_block(m77, 'subsystem', 'fe', 'Model', dedans77);
m77 = add_block(m77, 'outport', 'y');
m77 = add_line(add_line(m77, 'u', 'fe'), 'fe', 'y');
discret77 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 3};
r77 = sim(m77, discret77{:});
assert(isequal(size(r77.yout), [4 2]) && isequal(r77.yout(:, 1), [3; 6; 9; 12]) && ...
       isequal(r77.yout(:, 2), [7; 14; 21; 28]), ...
       'des tranches de deux, sommees puis cumulees, chacune avec son etat');
% l'état de fonctionnement porte les états de chaque tranche
a77 = sim(m77, discret77{:}, 'StopTime', 1, 'SaveFinalState', 'on', 'SaveOperatingPoint', 'on');
b77 = sim(m77, discret77{:}, 'LoadInitialState', 'on', 'InitialState', a77.xFinal);
assert(isequal(b77.yout, r77.yout(2:end, :)), 'un For Each reprend ses tranches et leurs etats');
% une matrice découpée par colonnes, concaténée par colonnes ; une entrée
% entière
colonnes77 = new_system('colonnes77');
colonnes77 = add_block(colonnes77, 'inport', 'In1', 'Port', 1);
colonnes77 = add_block(colonnes77, 'inport', 'In2', 'Port', 2);
colonnes77 = add_block(colonnes77, 'gain', 'g', 'Gain', 2);
colonnes77 = add_block(colonnes77, 'sum', 's', 'Signs', '++');
colonnes77 = add_block(colonnes77, 'outport', 'Out1', 'Port', 1);
colonnes77 = add_block(colonnes77, 'foreach', 'For Each', 'InputPartition', {'on', 'off'}, ...
                       'InputPartitionDimension', {2, 1}, 'OutputConcatenationDimension', {2});
colonnes77 = add_line(add_line(colonnes77, 'In1', 'g'), 'g', 's/1');
colonnes77 = add_line(add_line(colonnes77, 'In2', 's/2'), 's', 'Out1');
c77 = new_system('matrice77');
c77 = add_block(c77, 'constant', 'u', 'Value', [1 2 3; 4 5 6]);
c77 = add_block(c77, 'constant', 'decalage', 'Value', 10);
c77 = add_block(c77, 'subsystem', 'fe', 'Model', colonnes77);
c77 = add_block(c77, 'outport', 'y');
c77 = add_line(add_line(add_line(c77, 'u', 'fe/1'), 'decalage', 'fe/2'), 'fe', 'y');
r77 = sim(c77, discret77{:});
assert(isequal(reshape(r77.yout(end, :), 2, 3), 2 * [1 2 3; 4 5 6] + 10), ...
       'des colonnes doublees, l''entree entiere ajoutee, concatenees par colonnes');
% le For Each Subsystem de la bibliothèque découpe In1 élément par élément
biblio77 = new_system('biblio77');
biblio77 = add_block(biblio77, 'constant', 'u', 'Value', [5 6 7]);
biblio77 = add_block(biblio77, 'simulink/Ports & Subsystems/For Each Subsystem', 'fe');
biblio77 = add_block(biblio77, 'outport', 'y');
biblio77 = add_line(add_line(biblio77, 'u', 'fe'), 'fe', 'y');
r77 = sim(biblio77, discret77{:});
assert(isequal(r77.yout(end, :), [5 6 7]), 'le For Each Subsystem de la bibliotheque');
% ce qui ne se découpe pas
refus77 = {
    {'InputPartition', {'off'}}, 'Simulink:blocks:ForEachNoPartition'
    {'InputPartition', {'on'}, 'InputPartitionWidth', {3}}, 'Simulink:blocks:ForEachPartitionWidth'
    {'InputPartition', {'on'}, 'InputPartitionOffset', {1}}, ...
        'Simulink:blocks:ForEachPartitionOffset'
    };
for q = 1:size(refus77, 1)
    fautif77 = set_param(dedans77, 'For Each', refus77{q, 1}{:});
    vu77 = '';
    message77 = '';
    try
        sim(set_param(m77, 'fe', 'Model', fautif77), discret77{:});
    catch err
        vu77 = err.identifier;
        message77 = err.message;
    end
    assert(strcmp(vu77, refus77{q, 2}) && ~isempty(strfind(message77, 'chaque77/fe/For Each')), ...
           sprintf('For Each, refus %d : %s', q, vu77));
end
deux77 = add_block(set_param(colonnes77, 'For Each', 'InputPartition', {'on', 'on'}), ...
                   'terminator', 't');
vu77 = '';
try
    sim(set_param(c77, 'fe', 'Model', deux77), discret77{:});
catch err
    vu77 = err.identifier;
end
assert(strcmp(vu77, 'Simulink:blocks:ForEachPartitionMismatch'), ...
       'deux entrees decoupees en nombres de tranches differents');
continu77 = add_block(dedans77, 'integrator', 'x');
continu77 = add_line(continu77, 'paire', 'x');
vu77 = '';
try
    sim(set_param(m77, 'fe', 'Model', continu77), 'Solver', 'ode4', 'FixedStep', 1, 'StopTime', 2);
catch err
    vu77 = err.identifier;
end
assert(strcmp(vu77, 'Simulink:blocks:ForEachSubsystemContinuousStates'), ...
       'un etat continu dans un For Each : refuse en le nommant');
fprintf('sous-systeme For Each : ok\n');

%% --------------------- 78. La mémoire des blocs MATLAB Function, et la reprise
% Deux blocs au même code — deux Detect Rise Positive, que MatLibre
% compile en MATLAB Function — ne partagent pas leur mémoire : chaque bloc
% a ses variables persistantes, comme dans Simulink. L'état de
% fonctionnement les porte, et la reprise les retrouve. Une batterie de
% modèles tirés au hasard le vérifie : simulés d'une traite, puis pris à
% un instant et repris de là, ils rendent à pas fixe exactement la même
% chose.
deux78 = new_system('deuxFronts78');
deux78 = add_block(deux78, 'pulsegenerator', 'p1', 'Period', 1, 'PulseWidth', 50);
deux78 = add_block(deux78, 'pulsegenerator', 'p2', 'Period', 1, 'PulseWidth', 50, 'PhaseDelay', 0.3);
deux78 = add_block(deux78, 'detectrisepositive', 'd1');
deux78 = add_block(deux78, 'detectrisepositive', 'd2');
deux78 = add_block(deux78, 'outport', 'y1');
deux78 = add_block(deux78, 'outport', 'y2');
deux78 = add_line(add_line(deux78, 'p1', 'd1'), 'd1', 'y1');
deux78 = add_line(add_line(deux78, 'p2', 'd2'), 'd2', 'y2');
discret78 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1, 'StopTime', 2};
r78 = sim(deux78, discret78{:});
assert(isequal(r78.tout(double(r78.yout(:, 1)) == 1), [0; 1; 2]) && ...
       isequal(abs(r78.tout(double(r78.yout(:, 2)) == 1) - [0.3; 1.3]) < 1e-9, [true; true]), ...
       'deux Detect Rise Positive au meme code ont chacun leur memoire');
% un bloc MATLAB Function à variable persistante : la reprise la retrouve
compte78 = new_system('compte78');
compte78 = add_block(compte78, 'constant', 'u', 'Value', 2, 'SampleTime', 0.1);
compte78 = add_block(compte78, 'matlabfunction', 'f', 'Script', ...
                     sprintf(['function y = fcn(u)\npersistent somme\nif isempty(somme)\n' ...
                              '    somme = 0;\nend\nsomme = somme + u;\ny = somme;\n']));
compte78 = add_block(compte78, 'outport', 'y');
compte78 = add_line(add_line(compte78, 'u', 'f'), 'f', 'y');
entier78 = sim(compte78, discret78{:});
a78 = sim(compte78, discret78{:}, 'StopTime', 1, 'SaveFinalState', 'on', 'SaveOperatingPoint', 'on');
b78 = sim(compte78, discret78{:}, 'LoadInitialState', 'on', 'InitialState', a78.xFinal);
assert(isequal(b78.yout, entier78.yout(entier78.tout >= 1 - 1e-9)) && b78.yout(end) == 42, ...
       'la variable persistante d''un bloc MATLAB Function reprend ou elle etait');
b78bis = sim(compte78, discret78{:}, 'LoadInitialState', 'on', 'InitialState', a78.xFinal);
assert(isequal(b78bis.yout, b78.yout), 'et se reprend autant qu''on veut');
% une source aléatoire de période 0 tient sa valeur entre deux pas
% majeurs : le solveur à pas variable ne piétine pas, même à tolérance
% serrée (la batterie l'a trouvé : il réduisait son pas sans fin)
bruit78 = new_system('bruit78');
bruit78 = add_block(bruit78, 'randomnumber', 'b', 'SampleTime', 0);
bruit78 = add_block(bruit78, 'zeropole', 'h');
bruit78 = add_block(bruit78, 'outport', 'y');
bruit78 = add_line(add_line(bruit78, 'b', 'h'), 'h', 'y');
r78 = sim(bruit78, 'Solver', 'ode45', 'RelTol', 1e-8, 'AbsTol', 1e-10, 'MaxStep', 0.05, ...
          'StopTime', 0.5);
assert(abs(r78.tout(end) - 0.5) < 1e-12 && numel(r78.tout) < 2000, ...
       'une source aleatoire de periode 0 ne fait pas pietiner le solveur');
% la batterie de reprise
rng(78);
catalogue78 = matlibre_sl_catalogue();
exclus78 = {'subsystem', 'modelreference', 'iterateur', 'enableport', 'triggerport', ...
            'actionport', 'if', 'switchcase', 'goto', 'from', 'datastorememory', ...
            'datastoreread', 'datastorewrite', 'chart', 'sfunction', 'msfunction', ...
            'fromfile', 'fromspreadsheet', 'signaleditor', 'fromworkspace', 'variantsource', ...
            'variantsink', 'busselector', 'busassignment', 'inport', 'foriterator', ...
            'whileiterator', 'merge', 'functioncallgenerator', 'tofile', ...
            'algebraicconstraint', 'garde'};
sources78 = {};
blocs78 = {};
for kT = 1:numel(catalogue78)
    entree = catalogue78(kT);
    if any(strcmp(entree.famille, {'Interne', 'Simscape'})) || any(strcmp(entree.type, exclus78))
        continue
    end
    [ne, ns] = matlibre_sl_ports(struct('type', entree.type, 'nom', 'b', ...
                                        'parametres', struct()), entree.type);
    if isnan(ne) || isnan(ns) || ns == 0
        continue
    end
    if ne == 0
        sources78{end + 1} = entree.type; %#ok<SAGROW>
    else
        blocs78{end + 1} = entree.type; %#ok<SAGROW>
    end
end
stats78 = [0 0];   % reprises justes, modèles refusés
% Un modèle tiré au hasard sur quatre environ se simule (les autres sont
% refusés à bon droit : paramètre complexe, type incompatible…) : on tire
% jusqu'à douze reprises, plutôt qu'un nombre fixe de modèles qui
% dépendrait de la graine.
n = 0;
while stats78(1) < 12 && n < 150
    n = n + 1;
    types78 = [sources78(randi(numel(sources78))), ...
               blocs78(randi(numel(blocs78), 1, randi([2 5])))];
    nom78 = sprintf('reprise78_%d', n);
    try
        [m, texte78] = aleaBatir(nom78, types78, catalogue78);
    catch
        continue
    end
    coupe78 = 0.5 + 0.4 * randi(2);
    reglage78 = {'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 2};
    try
        entier = [];
        avant = [];
        apres = [];
        evalc('entier = sim(m, reglage78{:});');
        evalc(['avant = sim(m, reglage78{:}, ''StopTime'', coupe78, ''SaveFinalState'', ' ...
               '''on'', ''SaveOperatingPoint'', ''on'');']);
        evalc(['apres = sim(m, reglage78{:}, ''LoadInitialState'', ''on'', ' ...
               '''InitialState'', avant.xFinal);']);
    catch err
        assert(strncmp(err.identifier, 'Simulink:', 9) && ...
               isempty(strfind(err.identifier, 'OperatingPoint')), ...
               sprintf('%s : %s%s : %s', nom78, strjoin(types78, ' -> '), texte78, err.message));
        stats78(2) = stats78(2) + 1;
        continue
    end
    garde78 = entier.tout >= coupe78 - 1e-9;
    assert(isequal(size(apres.yout), size(entier.yout(garde78, :))) && ...
           aleaMemesValeurs(apres.yout, entier.yout(garde78, :)), ...
           sprintf('%s : %s%s, coupe %g : la reprise differe', nom78, strjoin(types78, ' -> '), ...
                   texte78, coupe78));
    stats78(1) = stats78(1) + 1;
end
assert(stats78(1) >= 10, 'la batterie de reprise simule assez de modeles');
fprintf('memoire des blocs et batterie de reprise : %d reprises exactes, %d refus\n', stats78);

%% ------------------------------------- 79. Les sources à période -1
% Un compteur, un Repeating Sequence Stair ont par défaut la période -1 :
% comme dans Simulink, elle s'hérite en arrière, de ce qu'ils alimentent —
% ici un retard de période 0,5 —, et le diagnostic « Source block
% specifies -1 sample time » le signale (InheritedTsInSrcMsg, 'warning' par
% défaut ; 'none' le tait, 'error' refuse la simulation). Une source d'un
% sous-système conditionnel hérite de sa garde sans rien dire ; dans un
% sous-système atomique, elle prend la période qu'il impose.
m79 = new_system('comptes79');
m79 = add_block(m79, 'counterlimited', 'compte', 'uplimit', 7);
m79 = add_block(m79, 'delay', 'retard', 'SampleTime', 0.5);
m79 = add_block(m79, 'outport', 'y1');
m79 = add_block(m79, 'outport', 'y2');
m79 = add_line(add_line(m79, 'compte', 'retard'), 'retard', 'y1');
m79 = add_line(m79, 'compte', 'y2');
assert(strcmp(get_param(m79, 'InheritedTsInSrcMsg'), 'warning'), ...
       'InheritedTsInSrcMsg vaut warning par defaut, comme dans Simulink');
reglage79 = {'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 2};
lastwarn('');
r79 = [];
evalc('r79 = sim(m79, reglage79{:});');
[texte79, id79] = lastwarn();
assert(strcmp(id79, 'Simulink:SampleTime:SourceInheritedTS') && ...
       ~isempty(strfind(texte79, 'comptes79/compte')) && ...
       ~isempty(strfind(texte79, 'InheritedTsInSrcMsg')), ...
       'le compteur a periode -1 est signale, nomme, et le reglage dit');
rang79 = floor(r79.tout / 0.5 + 1e-9);
assert(isequal(r79.yout(:, 2), mod(rang79, 8)) && ...
       isequal(r79.yout(:, 1), mod(max(rang79 - 1, 0), 8)), ...
       'il herite en arriere la periode 0,5 du retard qu''il alimente');
lastwarn('');
evalc('sim(m79, reglage79{:}, ''InheritedTsInSrcMsg'', ''none'');');
[~, id79] = lastwarn();
assert(isempty(id79), 'InheritedTsInSrcMsg none : rien n''est dit');
vu79 = '';
message79 = '';
try
    sim(m79, reglage79{:}, 'InheritedTsInSrcMsg', 'error');
catch err
    vu79 = err.identifier;
    message79 = err.message;
end
assert(strcmp(vu79, 'Simulink:SampleTime:SourceInheritedTS') && ...
       ~isempty(strfind(message79, 'comptes79/compte')), ...
       'InheritedTsInSrcMsg error : la simulation est refusee, la source nommee');
lastwarn('');
evalc('sim(set_param(m79, ''compte'', ''tsamp'', 0.5), reglage79{:});');
[~, id79] = lastwarn();
assert(isempty(id79), 'un compteur a la periode dite n''est pas signale');
% à pas variable aussi, la période vient du retard
r79 = [];
evalc('r79 = sim(m79, ''Solver'', ''ode45'', ''StopTime'', 2);');
assert(all(r79.yout(:, 2) == mod(floor(r79.tout / 0.5 + 1e-9), 8)), ...
       'a pas variable, le compteur herite aussi la periode 0,5');
% deux lecteurs de périodes différentes : le pas de base
deux79 = add_block(m79, 'delay', 'lent', 'SampleTime', 0.2);
deux79 = add_block(deux79, 'terminator', 'fin');
deux79 = add_line(add_line(deux79, 'compte', 'lent'), 'lent', 'fin');
r79 = [];
evalc('r79 = sim(deux79, reglage79{:});');
assert(isequal(r79.yout(:, 2), mod(floor(r79.tout / 0.1 + 1e-9), 8)), ...
       'deux lecteurs de periodes differentes : le compteur prend le pas de base');
% à travers un bloc qui hérite : le Repeating Sequence Stair, doublé, puis
% retardé
via79 = new_system('via79');
via79 = add_block(via79, 'repeatingsequencestair', 'escalier', 'OutValues', [3 1 4 1 5]);
via79 = add_block(via79, 'gain', 'g', 'Gain', 2);
via79 = add_block(via79, 'delay', 'retard', 'SampleTime', 0.5);
via79 = add_block(via79, 'outport', 'y');
via79 = add_block(via79, 'outport', 'yg');
via79 = add_line(add_line(add_line(via79, 'escalier', 'g'), 'g', 'retard'), 'retard', 'y');
via79 = add_line(via79, 'g', 'yg');
r79 = [];
evalc('r79 = sim(via79, reglage79{:});');
valeurs79 = [3 1 4 1 5];
assert(isequal(r79.yout(:, 2), 2 * valeurs79(mod(floor(r79.tout / 0.5 + 1e-9), 5) + 1).'), ...
       'a travers un gain qui herite, l''escalier prend la periode du retard');
% un bruit à période -1 n'est plus une constante : il tire à chaque pas
bruit79 = new_system('bruit79');
bruit79 = add_block(bruit79, 'randomnumber', 'b', 'SampleTime', -1);
bruit79 = add_block(bruit79, 'outport', 'y');
bruit79 = add_line(bruit79, 'b', 'y');
r79 = [];
evalc('r79 = sim(bruit79, ''Solver'', ''ode4'', ''FixedStep'', 0.1, ''StopTime'', 1);');
assert(numel(unique(r79.yout)) == numel(r79.tout), ...
       'un Random Number a periode -1 tire a chaque pas de base');
% un Pulse Generator réglé par échantillons, à période -1 : celle du
% retard qu'il alimente
impulsion79 = new_system('impulsion79');
impulsion79 = add_block(impulsion79, 'pulsegenerator', 'p', 'PulseType', 'Sample based', ...
                        'Period', 4, 'PulseWidth', 2, 'SampleTime', -1);
impulsion79 = add_block(impulsion79, 'delay', 'retard', 'SampleTime', 0.5);
impulsion79 = add_block(impulsion79, 'outport', 'y');
impulsion79 = add_block(impulsion79, 'outport', 'yp');
impulsion79 = add_line(add_line(impulsion79, 'p', 'retard'), 'retard', 'y');
impulsion79 = add_line(impulsion79, 'p', 'yp');
r79 = [];
evalc('r79 = sim(impulsion79, reglage79{:});');
assert(isequal(r79.yout(:, 2), double(mod(floor(r79.tout / 0.5 + 1e-9), 4) < 2)), ...
       'un Pulse Generator par echantillons herite la periode du retard');
% dans un sous-système activé : rien n'est dit
dedans79 = new_system('compteActive79');
dedans79 = add_block(dedans79, 'counterfreerunning', 'n', 'NumBits', 3);
dedans79 = add_block(dedans79, 'outport', 'Out1', 'Port', 1);
dedans79 = add_block(dedans79, 'enableport', 'Enable');
dedans79 = add_line(dedans79, 'n', 'Out1');
active79 = new_system('active79');
active79 = add_block(active79, 'pulsegenerator', 'porte', 'Period', 1, 'PulseWidth', 50);
active79 = add_block(active79, 'subsystem', 'sous', 'Model', dedans79);
active79 = add_block(active79, 'outport', 'y');
active79 = add_line(add_line(active79, 'porte', 'sous/Enable'), 'sous', 'y');
lastwarn('');
evalc('sim(active79, reglage79{:});');
[~, id79] = lastwarn();
assert(isempty(id79), 'une source d''un sous-systeme active herite sans rien dire');
% dans un sous-système atomique qui impose sa période : il la prend
atome79 = new_system('atome79');
atome79 = add_block(atome79, 'counterlimited', 'compte', 'uplimit', 9);
atome79 = add_block(atome79, 'outport', 'Out1', 'Port', 1);
atome79 = add_line(atome79, 'compte', 'Out1');
a79 = new_system('atomique79');
a79 = add_block(a79, 'simulink/Ports & Subsystems/Atomic Subsystem', 'a', 'Model', atome79, ...
                'SystemSampleTime', 0.3);
a79 = add_block(a79, 'outport', 'y');
a79 = add_line(a79, 'a', 'y');
lastwarn('');
r79 = [];
evalc('r79 = sim(a79, ''Solver'', ''FixedStepDiscrete'', ''FixedStep'', 0.1, ''StopTime'', 1.2);');
[~, id79] = lastwarn();
assert(isempty(id79) && isequal(r79.yout, floor(r79.tout / 0.3 + 1e-9)), ...
       'dans un sous-systeme atomique, le compteur prend la periode imposee');
% la batterie : chaque source qui porte une période, mise à -1, en trois
% lieux — à la racine, dans un sous-système activé, dans un sous-système
% atomique — et aux trois réglages du diagnostic
assignin('base', 'donnees79', [0 0; 1 1; 2 0]);
sources79 = {
    'constant', {'SampleTime', -1}
    'enumeratedconstant', {'SampleTime', -1}
    'step', {'SampleTime', -1}
    'sine', {'SampleTime', -1}
    'digitalclock', {'SampleTime', -1}
    'randomnumber', {'SampleTime', -1}
    'uniformrandomnumber', {'SampleTime', -1}
    'counterfreerunning', {}
    'counterlimited', {}
    'repeatingsequencestair', {}
    'repeatingsequenceinterpolated', {'tsamp', -1}
    'pulsegenerator', {'PulseType', 'Sample based', 'SampleTime', -1}
    'fromworkspace', {'VariableName', 'donnees79', 'SampleTime', -1}
    };
lieux79 = {'racine', 'active', 'atomique'};
niveaux79 = {'none', 'warning', 'error'};
essais79 = 0;
for q = 1:size(sources79, 1)
    for l = 1:numel(lieux79)
        source79 = add_block(new_system('source79'), sources79{q, 1}, 's', sources79{q, 2}{:});
        source79 = add_block(source79, 'outport', 'y');
        source79 = add_line(source79, 's', 'y');
        switch lieux79{l}
            case 'racine'
                modele79 = source79;
                chemin79 = 'source79/s';
            case 'active'
                ss79 = add_block(set_param(source79, 'y', 'Port', 1), 'enableport', 'Enable');
                modele79 = add_block(new_system('lieu79'), 'pulsegenerator', 'porte', ...
                                     'Period', 1, 'PulseWidth', 50);
                modele79 = add_block(modele79, 'subsystem', 'sous', 'Model', ss79);
                modele79 = add_block(modele79, 'outport', 'y');
                modele79 = add_line(add_line(modele79, 'porte', 'sous/Enable'), 'sous', 'y');
            case 'atomique'
                modele79 = add_block(new_system('lieu79'), ...
                                     'simulink/Ports & Subsystems/Atomic Subsystem', 'a', ...
                                     'Model', source79, 'SystemSampleTime', 0.2);
                modele79 = add_block(modele79, 'outport', 'y');
                modele79 = add_line(modele79, 'a', 'y');
        end
        for v = 1:numel(niveaux79)
            lastwarn('');
            vu79 = '';
            message79 = '';
            try
                evalc(['sim(modele79, ''Solver'', ''ode4'', ''FixedStep'', 0.1, ' ...
                       '''StopTime'', 0.6, ''InheritedTsInSrcMsg'', niveaux79{v});']);
            catch err
                vu79 = err.identifier;
                message79 = err.message;
            end
            [texte79, id79] = lastwarn();
            cas79 = sprintf('%s, %s, %s', sources79{q, 1}, lieux79{l}, niveaux79{v});
            if strcmp(lieux79{l}, 'racine') && v > 1
                if v == 2
                    assert(isempty(vu79) && ...
                           strcmp(id79, 'Simulink:SampleTime:SourceInheritedTS') && ...
                           ~isempty(strfind(texte79, chemin79)), ...
                           [cas79 ' : l''avertissement qui nomme la source']);
                else
                    assert(strcmp(vu79, 'Simulink:SampleTime:SourceInheritedTS') && ...
                           ~isempty(strfind(message79, chemin79)), ...
                           [cas79 ' : l''erreur qui nomme la source']);
                end
            else
                assert(isempty(vu79) && ~strcmp(id79, 'Simulink:SampleTime:SourceInheritedTS'), ...
                       sprintf('%s : rien a dire (%s %s)', cas79, vu79, message79));
            end
            essais79 = essais79 + 1;
        end
    end
end
evalin('base', 'clear donnees79');
fprintf('sources a periode -1 : %d essais\n', essais79);

%% ------------------------------------ 80. La bibliothèque Matrix Operations
% Les blocs de la bibliothèque Matrix Operations de Simulink : transposées,
% diagonales, carré u' * u, produit vectoriel, identité, expansion d'un
% scalaire, tests de symétrie et de triangularité, permutation des lignes
% ou des colonnes, sous-matrice. Chacun calcule comme la fonction de
% MATLAB qui lui répond, garde le type de son entrée, et refuse en se
% nommant ce qu'il ne sait pas faire.
A80 = [1 2 3; 4 5 6];
S80 = [2 -1 0; -1 2 -1; 0 -1 2];
blocs80 = {
    'transpose', {}, A80, A80.'
    'hermitiantranspose', {}, [1+2i 3; 4 5-1i], [1+2i 3; 4 5-1i]'
    'creatediagonalmatrix', {}, [1 2 3], diag([1 2 3])
    'extractdiagonal', {}, A80, [1; 5]
    'matrixsquare', {}, A80, A80' * A80
    'issymmetric', {'Mode', 'Symmetric'}, S80, true
    'issymmetric', {'Mode', 'Symmetric'}, A80, false
    'issymmetric', {'Mode', 'Skew-Symmetric'}, [0 1; -1 0], true
    'ishermitian', {'Mode', 'Hermitian'}, [2 1i; -1i 3], true
    'ishermitian', {'Mode', 'Skew-Hermitian'}, [1i 2; -2 0], true
    'istriangular', {'Mode', 'Upper'}, triu(S80), true
    'istriangular', {'Mode', 'Lower'}, triu(S80), false
    'identitymatrix', {'InheritOutputPortAttributes', 'on'}, A80, eye(2, 3)
    'submatrix', {'RowSpan', 'One row', 'RowIdx', 'Last'}, magic(4), [4 14 15 1]
    'submatrix', {'RowSpan', 'Range of rows', 'RowIdx', 'Index', 'RowIndex', 2, ...
                  'RowEndIdx', 'Offset from last', 'RowEndOffset', 1, ...
                  'ColSpan', 'Range of columns', 'ColIdx', 'Middle', 'ColEndIdx', 'Last'}, ...
        magic(4), [10 8; 6 12]
    };
for q = 1:size(blocs80, 1)
    m80 = new_system('matrices80');
    m80 = add_block(m80, 'constant', 'u', 'Value', blocs80{q, 3});
    m80 = add_block(m80, blocs80{q, 1}, 'b', blocs80{q, 2}{:});
    m80 = add_block(m80, 'toworkspace', 'tw', 'VariableName', 'sortie80', 'SaveFormat', 'Array');
    m80 = add_line(add_line(m80, 'u', 'b'), 'b', 'tw');
    r80 = [];
    evalc('r80 = sim(m80, ''Solver'', ''FixedStepDiscrete'', ''FixedStep'', 1, ''StopTime'', 1);');
    vu80 = evalin('base', 'sortie80');
    if ndims(vu80) == 3
        vu80 = vu80(:, :, end);
    else
        vu80 = vu80(end, :);
    end
    attendu = blocs80{q, 4};
    assert(isequal(size(vu80), size(attendu)) || numel(vu80) == numel(attendu), ...
           sprintf('%s (%d) : taille %s au lieu de %s', blocs80{q, 1}, q, mat2str(size(vu80)), ...
                   mat2str(size(attendu))));
    assert(isequal(double(vu80(:)), double(attendu(:))), ...
           sprintf('%s (%d) : %s au lieu de %s', blocs80{q, 1}, q, mat2str(vu80), ...
                   mat2str(attendu)));
end
% le produit vectoriel, deux entrées
p80 = new_system('vectoriel80');
p80 = add_block(p80, 'constant', 'a', 'Value', [1; 0; 0]);
p80 = add_block(p80, 'constant', 'b', 'Value', [0; 1; 0]);
p80 = add_block(p80, 'crossproduct', 'x');
p80 = add_block(p80, 'outport', 'y');
p80 = add_line(add_line(add_line(p80, 'a', 'x/1'), 'b', 'x/2'), 'x', 'y');
r80 = sim(p80, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1);
assert(isequal(r80.yout(end, :), [0 0 1]), 'Cross Product : x par y donne z');
vu80 = '';
message80 = '';
try
    sim(set_param(p80, 'a', 'Value', [1 2]), 'Solver', 'FixedStepDiscrete', 'StopTime', 1);
catch err
    vu80 = err.identifier;
    message80 = err.message;
end
assert(strcmp(vu80, 'Simulink:blocks:CrossProductInputSize') && ...
       ~isempty(strfind(message80, 'vectoriel80/x')), ...
       'Cross Product refuse un vecteur qui n''a pas trois elements, en se nommant');
% l'identité et l'expansion d'un scalaire, sources : leur type, leur période
i80 = new_system('identite80');
i80 = add_block(i80, 'identitymatrix', 'I', 'OutputDimensions', [2 3], 'OutDataTypeStr', 'int8', ...
                'SampleTime', 0.5);
i80 = add_block(i80, 'expandscalar', 'E', 'ElementValue', 7, 'OutputDimensions', 4, ...
                'OutDataTypeStr', 'uint16');
i80 = add_block(i80, 'toworkspace', 'ti', 'VariableName', 'identite80', 'SaveFormat', 'Array');
i80 = add_block(i80, 'toworkspace', 'te', 'VariableName', 'expansion80', 'SaveFormat', 'Array');
i80 = add_line(add_line(i80, 'I', 'ti'), 'E', 'te');
evalc('sim(i80, ''Solver'', ''FixedStepDiscrete'', ''FixedStep'', 0.5, ''StopTime'', 1);');
vi80 = evalin('base', 'identite80');
ve80 = evalin('base', 'expansion80');
assert(isa(vi80, 'int8') && isequal(double(vi80(:, :, end)), eye(2, 3)), ...
       'Identity Matrix : eye(2, 3) en int8');
assert(isa(ve80, 'uint16') && isequal(double(ve80(end, :)), [7 7 7 7]), ...
       'Expand Scalar : quatre fois 7 en uint16');
vu80 = '';
try
    sim(set_param(i80, 'I', 'OutputDimensions', [2 0]), 'Solver', 'FixedStepDiscrete', ...
        'StopTime', 1);
catch err
    vu80 = err.identifier;
end
assert(strcmp(vu80, 'Simulink:Parameters:InvalidValue'), ...
       'Identity Matrix refuse des dimensions qui ne sont pas des entiers positifs');
% le type de l'entrée se garde
t80 = new_system('types80');
t80 = add_block(t80, 'constant', 'u', 'Value', int16([1 2; 3 4]));
t80 = add_block(t80, 'transpose', 'T');
t80 = add_block(t80, 'matrixsquare', 'C');
t80 = add_block(t80, 'toworkspace', 'tt', 'VariableName', 'transposee80', 'SaveFormat', 'Array');
t80 = add_block(t80, 'toworkspace', 'tc', 'VariableName', 'carre80', 'SaveFormat', 'Array');
t80 = add_line(add_line(add_line(t80, 'u', 'T'), 'T', 'tt'), 'u', 'C');
t80 = add_line(t80, 'C', 'tc');
evalc('sim(t80, ''Solver'', ''FixedStepDiscrete'', ''FixedStep'', 1, ''StopTime'', 1);');
vt80 = evalin('base', 'transposee80');
vc80 = evalin('base', 'carre80');
assert(isa(vt80, 'int16') && isequal(vt80(:, :, end), int16([1 3; 2 4])) && ...
       isa(vc80, 'int16') && isequal(vc80(:, :, end), int16([10 14; 14 20])), ...
       'Transpose et Matrix Square gardent le type entier de leur entree');
% Permute Matrix : lignes, colonnes, indices de 0, hors bornes
permutations80 = {
    {'mode', 'Rows'}, [3 1 2], A80([2 1 2], :), ''
    {'mode', 'Columns'}, [3 1], A80(:, [3 1]), ''
    {'mode', 'Columns', 'ZeroOneIdxMode', 'Zero-based'}, [2 0], A80(:, [3 1]), ''
    {'mode', 'Columns', 'errmode', 'Clip and warn'}, [9 -2], A80(:, [3 1]), ...
        'Simulink:blocks:PermuteMatrixIndexClipped'
    {'mode', 'Columns', 'errmode', 'Generate error'}, [9 1], [], ...
        'Simulink:blocks:PermuteMatrixInvalidIndex'
    {'mode', 'Rows', 'checkDims', 'on'}, [1 2 1], [], 'Simulink:blocks:PermuteMatrixLength'
    };
for q = 1:size(permutations80, 1)
    m80 = new_system('permute80');
    m80 = add_block(m80, 'constant', 'A', 'Value', A80);
    m80 = add_block(m80, 'constant', 'P', 'Value', permutations80{q, 2});
    m80 = add_block(m80, 'permutematrix', 'pm', permutations80{q, 1}{:});
    m80 = add_block(m80, 'toworkspace', 'tw', 'VariableName', 'permute80', 'SaveFormat', 'Array');
    m80 = add_line(add_line(add_line(m80, 'A', 'pm/1'), 'P', 'pm/2'), 'pm', 'tw');
    lastwarn('');
    vu80 = '';
    message80 = '';
    try
        evalc('sim(m80, ''Solver'', ''FixedStepDiscrete'', ''FixedStep'', 1, ''StopTime'', 1);');
    catch err
        vu80 = err.identifier;
        message80 = err.message;
    end
    [~, averti80] = lastwarn();
    if isempty(permutations80{q, 3})
        assert(strcmp(vu80, permutations80{q, 4}) && ~isempty(strfind(message80, 'permute80/pm')), ...
               sprintf('Permute Matrix %d : %s', q, vu80));
    else
        assert(isempty(vu80), sprintf('Permute Matrix %d : %s', q, message80));
        vu80 = evalin('base', 'permute80');
        assert(isequal(vu80(:, :, end), permutations80{q, 3}), ...
               sprintf('Permute Matrix %d : %s', q, mat2str(vu80(:, :, end))));
        assert(strcmp(averti80, permutations80{q, 4}), ...
               sprintf('Permute Matrix %d : avertissement %s', q, averti80));
    end
end
% ce que les blocs refusent, en se nommant
refus80 = {
    'creatediagonalmatrix', {}, A80, 'Simulink:blocks:CreateDiagonalMatrixInput'
    'issymmetric', {'Mode', 'Skew-Symmetric'}, uint8([0 1; 1 0]), ...
        'Simulink:blocks:SkewModeUnsignedInput'
    'submatrix', {'RowSpan', 'One row', 'RowIdx', 'Index', 'RowIndex', 5}, A80, ...
        'Simulink:blocks:SubmatrixIndex'
    'submatrix', {'RowSpan', 'Range of rows', 'RowIdx', 'Last', 'ColSpan', ...
                  'Range of columns', 'ColIdx', 'Index', 'ColIndex', 3, 'ColEndIdx', 'Index', ...
                  'ColEndIndex', 1}, A80, 'Simulink:blocks:SubmatrixIndex'
    'submatrix', {'RowSpan', 'One row', 'RowIdx', 'Index', 'RowIndex', 0.5}, A80, ...
        'Simulink:Parameters:InvalidValue'
    };
for q = 1:size(refus80, 1)
    m80 = new_system('refus80');
    m80 = add_block(m80, 'constant', 'u', 'Value', refus80{q, 3});
    m80 = add_block(m80, refus80{q, 1}, 'b', refus80{q, 2}{:});
    m80 = add_block(m80, 'terminator', 't');
    m80 = add_line(add_line(m80, 'u', 'b'), 'b', 't');
    vu80 = '';
    message80 = '';
    try
        sim(m80, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1);
    catch err
        vu80 = err.identifier;
        message80 = err.message;
    end
    assert(strcmp(vu80, refus80{q, 4}) && ~isempty(strfind(message80, 'refus80/b')), ...
           sprintf('%s, refus %d : %s (%s)', refus80{q, 1}, q, vu80, message80));
end
% la bibliothèque les connaît par leurs chemins
assert(strcmp(getfield(matlibre_sl_catalogue('type', ...
           'simulink/Matrix Operations/Submatrix'), 'type'), 'submatrix') && ...
       strcmp(getfield(matlibre_sl_catalogue('type', 'IsTriangular'), 'type'), 'istriangular'), ...
       'les blocs de Matrix Operations se designent par leur chemin et leur nom');
evalin('base', 'clear sortie80 identite80 expansion80 transposee80 carre80 permute80');
fprintf('bibliotheque Matrix Operations : ok\n');

%% ---------------- 81. Increment - Decrement, Descriptor State-Space, contrôles
% Les blocs Increment - Decrement de la bibliothèque Additional Math : un
% de plus ou de moins à la valeur ou à l'entier stocké — un entier, une
% virgule fixe qui débordent se replient, comme dans Simulink —, et sans
% descendre sous zéro. Le Descriptor State-Space, E dx/dt = A x + B u, même
% quand E est singulière. Check Discrete Gradient et Check Input
% Resolution, qui arrêtent ou avertissent en nommant le bloc et l'instant.
increments81 = {
    'incrementrealworld', int8([126 127 -128]), int8([127 -128 -127])
    'decrementrealworld', int8([-127 -128 0]), int8([-128 127 -1])
    'incrementstoredinteger', uint8([254 255]), uint8([255 0])
    'decrementstoredinteger', uint8([1 0]), uint8([0 255])
    'incrementrealworld', [0.5 -2], [1.5 -1]
    'decrementtozero', [3 0.5 -2], [2 0 0]
    'decrementtozero', uint8([0 5]), uint8([0 4])
    'incrementstoredinteger', fi(0.5, 1, 8, 4), fi(0.5625, 1, 8, 4)
    'incrementrealworld', fi(7.5, 1, 8, 4), fi(-7.5, 1, 8, 4)
    'decrementstoredinteger', fi(-8, 1, 8, 4), fi(7.9375, 1, 8, 4)
    };
for q = 1:size(increments81, 1)
    m81 = new_system('increment81');
    m81 = add_block(m81, 'constant', 'u', 'Value', increments81{q, 2});
    m81 = add_block(m81, increments81{q, 1}, 'b');
    m81 = add_block(m81, 'toworkspace', 'tw', 'VariableName', 'sortie81', 'SaveFormat', 'Array');
    m81 = add_line(add_line(m81, 'u', 'b'), 'b', 'tw');
    evalc('sim(m81, ''Solver'', ''FixedStepDiscrete'', ''FixedStep'', 1, ''StopTime'', 1);');
    vu81 = evalin('base', 'sortie81');
    attendu = increments81{q, 3};
    assert(strcmp(class(vu81), class(attendu)) && ...
           isequal(double(vu81(end, :)), double(attendu(:).')), ...
           sprintf('%s (%d) : %s au lieu de %s', increments81{q, 1}, q, mat2str(double(vu81(end, :))), ...
                   mat2str(double(attendu))));
end
% Decrement Time To Zero retire sa période, jusqu'à zéro
d81 = new_system('compteRebours81');
d81 = add_block(d81, 'constant', 'depart', 'Value', 1);
d81 = add_block(d81, 'sum', 's', 'Signs', '+-');
d81 = add_block(d81, 'delay', 'z', 'InitialCondition', 0.5, 'SampleTime', 0.2);
d81 = add_block(d81, 'decrementtimetozero', 'd');
d81 = add_block(d81, 'outport', 'y');
d81 = add_line(add_line(d81, 'z', 'd'), 'd', 'y');
d81 = add_line(add_line(d81, 'depart', 's/1'), 'd', 's/2');
d81 = add_line(d81, 's', 'z');
r81 = sim(d81, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.2, 'StopTime', 0.4);
assert(abs(r81.yout(1) - 0.3) < 1e-12, 'Decrement Time To Zero retire sa periode, 0,2');
vu81 = '';
try
    sim(set_param(d81, 'z', 'SampleTime', -1), 'Solver', 'ode4', 'FixedStep', 0.2, 'StopTime', 0.4);
catch err
    vu81 = err.identifier;
end
assert(isempty(vu81) || strncmp(vu81, 'Simulink:', 9), 'Decrement Time To Zero : refus nomme');
c81 = new_system('continu81');
c81 = add_block(c81, 'sine', 'u');
c81 = add_block(c81, 'decrementtimetozero', 'd');
c81 = add_block(c81, 'outport', 'y');
c81 = add_line(add_line(c81, 'u', 'd'), 'd', 'y');
vu81 = '';
message81 = '';
try
    sim(c81, 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 1);
catch err
    vu81 = err.identifier;
    message81 = err.message;
end
assert(strcmp(vu81, 'Simulink:blocks:DecrementTimeToZeroSampleTime') && ...
       ~isempty(strfind(message81, 'continu81/d')), ...
       'Decrement Time To Zero refuse une periode continue, en se nommant');
vu81 = '';
try
    sim(add_line(add_block(add_block(new_system('booleen81'), 'constant', 'u', 'Value', true), ...
                           'incrementrealworld', 'b'), 'u', 'b'), 'Solver', 'FixedStepDiscrete', ...
        'StopTime', 1);
catch err
    vu81 = err.identifier;
end
assert(strcmp(vu81, 'Simulink:DataType:InputPortDataTypeMismatch'), ...
       'un booleen ne s''incremente pas');
% Descriptor State-Space : E inversible, puis singulière (une équation
% algébrique), comparés à ce qu'ils valent
regle81 = {'Solver', 'ode45', 'RelTol', 1e-8, 'AbsTol', 1e-10, 'StopTime', 2};
e81 = new_system('descripteur81');
e81 = add_block(e81, 'step', 'u', 'Time', 0);
e81 = add_block(e81, 'descriptorstatespace', 'g', 'E', 2, 'A', -4, 'B', 2, 'C', 1, 'D', 0, ...
                'InitialCondition', 1);
e81 = add_block(e81, 'outport', 'y');
e81 = add_line(add_line(e81, 'u', 'g'), 'g', 'y');
r81 = sim(e81, regle81{:});
% 2 dx/dt = -4 x + 2 : x = 1/2 + (1/2) exp(-2 t)
assert(max(abs(r81.yout - (0.5 + 0.5 * exp(-2 * r81.tout)))) < 1e-6, ...
       'Descriptor State-Space, E inversible : le premier ordre attendu');
% dx1/dt = -x1 + x2, 0 = -x2 + u : x2 = u, x1 -> 1 - exp(-t) ; y = [x1; x2]
s81 = set_param(e81, 'g', 'E', [1 0; 0 0], 'A', [-1 1; 0 -1], 'B', [0; 1], 'C', eye(2), ...
                'D', [0; 0], 'InitialCondition', [0; 0]);
r81 = sim(s81, regle81{:});
assert(max(abs(r81.yout(:, 1) - (1 - exp(-r81.tout)))) < 1e-6 && ...
       max(abs(r81.yout(:, 2) - 1)) < 1e-12, ...
       'Descriptor State-Space, E singuliere : l''equation algebrique est tenue');
refus81 = {
    {'E', [1 0; 0 0], 'A', [-1 1; 0 0], 'B', [0; 1], 'C', eye(2), 'D', [0; 0], ...
     'InitialCondition', [0; 0]}, 'Simulink:blocks:DescriptorStateSpaceIndex'
    {'E', eye(3), 'A', -eye(2)}, 'Simulink:blocks:DescriptorStateSpaceDimension'
    {'InitialCondition', NaN}, 'Simulink:Parameters:InvalidValue'
    };
for q = 1:size(refus81, 1)
    vu81 = '';
    message81 = '';
    try
        sim(set_param(e81, 'g', refus81{q, 1}{:}), regle81{:});
    catch err
        vu81 = err.identifier;
        message81 = err.message;
    end
    assert(strcmp(vu81, refus81{q, 2}) && ~isempty(strfind(message81, 'descripteur81/g')), ...
           sprintf('Descriptor State-Space, refus %d : %s', q, vu81));
end
% Check Discrete Gradient : un saut trop grand arrête, ou avertit ; la
% sortie dit si l'assertion tient
g81 = new_system('gradient81');
g81 = add_block(g81, 'step', 'u', 'Time', 0.5, 'After', 3, 'SampleTime', 0.1);
g81 = add_block(g81, 'checkdiscretegradient', 'cg', 'gradient', 2);
g81 = add_line(g81, 'u', 'cg');
vu81 = '';
message81 = '';
try
    sim(g81, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1, 'StopTime', 1);
catch err
    vu81 = err.identifier;
    message81 = err.message;
end
assert(strcmp(vu81, 'Simulink:blocks:AssertionAssert') && ...
       ~isempty(strfind(message81, 'gradient81/cg')) && ~isempty(strfind(message81, '0.5')), ...
       'Check Discrete Gradient arrete au saut de 3, en nommant le bloc et l''instant');
assignin('base', 'echecs81', 0);
g81 = set_param(g81, 'cg', 'stopWhenAssertionFail', 'off', 'export', 'on', ...
                'callback', 'echecs81 = echecs81 + 1;');
g81 = add_line(add_block(g81, 'outport', 'y'), 'cg', 'y');
lastwarn('');
r81 = [];
evalc('r81 = sim(g81, ''Solver'', ''FixedStepDiscrete'', ''FixedStep'', 0.1, ''StopTime'', 1);');
[~, id81] = lastwarn();
assert(strcmp(id81, 'Simulink:blocks:AssertionAssert') && ...
       isequal(double(r81.yout(:).'), double(abs(r81.tout(:).' - 0.5) > 1e-9)) && ...
       evalin('base', 'echecs81') == 1, ...
       'sans s''arreter : l''avertissement, la sortie fausse a l''instant du saut, le rappel');
assert(isequal(sim(set_param(g81, 'cg', 'gradient', 5), 'Solver', 'FixedStepDiscrete', ...
                   'FixedStep', 0.1, 'StopTime', 1).yout, true(11, 1)), ...
       'un gradient de 5 laisse passer le saut de 3');
evalin('base', 'clear echecs81');
% Check Input Resolution : un multiple de la résolution, ou l'une de ses
% valeurs
resolutions81 = {
    0.25, [0.5 1.75], true
    0.25, 0.3, false
    [1 2 5], 2, true
    [1 2 5], 3, false
    };
for q = 1:size(resolutions81, 1)
    m81 = new_system('resolution81');
    m81 = add_block(m81, 'constant', 'u', 'Value', resolutions81{q, 2});
    m81 = add_block(m81, 'checkinputresolution', 'cr', 'resolution', resolutions81{q, 1});
    m81 = add_line(m81, 'u', 'cr');
    vu81 = '';
    try
        sim(m81, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1);
    catch err
        vu81 = err.identifier;
    end
    assert(isempty(vu81) == resolutions81{q, 3} && ...
           (isempty(vu81) || strcmp(vu81, 'Simulink:blocks:AssertionAssert')), ...
           sprintf('Check Input Resolution %d : %s', q, vu81));
end
fprintf('Increment - Decrement, Descriptor State-Space, controles : ok\n');

%% ------------------------------------ 82. Le Second-Order Integrator complet
% Le Second-Order Integrator de Simulink en entier : x et dx/dt bornés —
% x à sa borne y tient, dx/dt s'annule, et x repart quand u l'en écarte —,
% x enroulé, conditions initiales lues sur des entrées, remise par une
% entrée, réinitialisation de dx/dt quand x atteint sa borne — de quoi
% faire rebondir une balle —, une seule sortie si l'on veut. Les réglages
% impossibles sont refusés en nommant le bloc.
precis82 = {'Solver', 'ode45', 'RelTol', 1e-9, 'AbsTol', 1e-12, 'MaxStep', 0.01};
% libre : x = -t^2/2
m82 = new_system('soi82');
m82 = add_block(m82, 'constant', 'u', 'Value', -1);
m82 = add_block(m82, 'secondorderintegrator', 's');
m82 = add_block(m82, 'outport', 'x');
m82 = add_block(m82, 'outport', 'v');
m82 = add_line(add_line(add_line(m82, 'u', 's'), 's/1', 'x'), 's/2', 'v');
r82 = sim(m82, precis82{:}, 'StopTime', 2);
assert(max(abs(r82.yout(:, 1) + r82.tout .^ 2 / 2)) < 1e-9 && ...
       max(abs(r82.yout(:, 2) + r82.tout)) < 1e-9, 'libre, il integre deux fois');
% la variante bornée de la bibliothèque : x entre 0 et 1, u = 1
b82 = add_block(new_system('borne82'), 'step', 'u', 'Time', 2, 'Before', 1, 'After', -1);
b82 = add_block(b82, 'simulink/Continuous/Integrator, Second-Order Limited', 's');
b82 = add_block(b82, 'outport', 'x');
b82 = add_block(b82, 'outport', 'v');
b82 = add_line(add_line(add_line(b82, 'u', 's'), 's/1', 'x'), 's/2', 'v');
assert(strcmp(get_param(b82, 's', 'LimitX'), 'on') && ...
       get_param(b82, 's', 'UpperLimitX') == 1, 'la variante bornee : x entre 0 et 1');
for solveur = {'ode45', 'ode4'}
    r82 = sim(b82, 'Solver', solveur{1}, 'FixedStep', 0.001, 'RelTol', 1e-9, 'AbsTol', 1e-12, ...
              'MaxStep', 0.01, 'StopTime', 3);
    x82 = @(t) interp1(r82.tout, r82.yout(:, 1), t);
    v82 = @(t) interp1(r82.tout, r82.yout(:, 2), t);
    % x = t^2/2 jusqu'à 1 en t = sqrt(2) ; tenu à 1, dx/dt nul ; repart à t = 2
    assert(abs(x82(1) - 0.5) < 1e-3 && abs(v82(1) - 1) < 1e-3, ...
           [solveur{1} ' : avant la borne, x = t^2/2']);
    assert(abs(x82(1.8) - 1) < 1e-9 && abs(v82(1.8)) < 1e-9, ...
           [solveur{1} ' : a la borne, x tient et dx/dt est nul']);
    assert(abs(x82(2.5) - (1 - 0.125)) < 2e-3 && abs(v82(2.5) + 0.5) < 2e-3, ...
           [solveur{1} ' : u l''en ecarte, x repart de sa borne']);
    assert(all(r82.yout(:, 1) <= 1 + 1e-12) && all(r82.yout(:, 1) >= -1e-12), ...
           [solveur{1} ' : x ne sort pas de ses bornes']);
end
% dx/dt borné à 0,5 : x = t^2/2 jusqu'en t = 0,5, puis x croît de 0,5 par seconde
d82 = set_param(m82, 'u', 'Value', 1);
d82 = set_param(d82, 's', 'LimitDXDT', 'on', 'UpperLimitDXDT', 0.5, 'LowerLimitDXDT', -0.5);
r82 = sim(d82, precis82{:}, 'StopTime', 2);
assert(abs(r82.yout(end, 1) - (0.125 + 0.5 * 1.5)) < 1e-6 && ...
       abs(r82.yout(end, 2) - 0.5) < 1e-12, 'dx/dt tenu a sa borne, x croit lineairement');
% x enroulé dans [-pi, pi[ : dx/dt = 1 constant
e82 = set_param(m82, 'u', 'Value', 0);
e82 = set_param(e82, 's', 'ICDXDT', 1, 'WrapX', 'on');
r82 = sim(e82, precis82{:}, 'StopTime', 4);
attendu82 = mod(r82.tout + pi, 2 * pi) - pi;
assert(max(abs(r82.yout(:, 1) - attendu82)) < 1e-6 && all(r82.yout(:, 1) < pi), ...
       'x enroule entre -pi et pi');
% la balle qui rebondit : x au-dessus de 0, dx/dt réinitialisé à -0,8 fois
% la vitesse d'arrivée, lue sur l'entrée dx0
balle82 = new_system('balle82');
balle82 = add_block(balle82, 'constant', 'g', 'Value', -9.81);
balle82 = add_block(balle82, 'secondorderintegrator', 's', 'ICX', 10, ...
                    'ICSourceDXDT', 'external', 'LimitX', 'on', 'LowerLimitX', 0, ...
                    'ReinitDXDTwhenXreachesSaturation', 'on');
balle82 = add_block(balle82, 'gain', 'e', 'Gain', -0.8);
balle82 = add_block(balle82, 'outport', 'x');
balle82 = add_line(add_line(balle82, 'g', 's/1'), 's/1', 'x');
balle82 = add_line(add_line(balle82, 's/2', 'e'), 'e', 's/2');
r82 = sim(balle82, 'Solver', 'ode45', 'RelTol', 1e-10, 'AbsTol', 1e-12, 'MaxStep', 0.005, ...
          'StopTime', 3.5);
t1 = sqrt(2 * 10 / 9.81);
apres82 = r82.tout > t1 + 0.1 & r82.tout < t1 + 2 * 0.8 * 9.81 * t1 / 9.81 - 0.1;
assert(all(r82.yout(:, 1) >= -1e-9), 'la balle ne passe pas sous le sol');
assert(abs(max(r82.yout(apres82, 1)) - 6.4) < 5e-3, ...
       'apres le rebond, la balle remonte a 0,64 fois sa hauteur');
% les conditions initiales lues sur leurs entrées, la remise au front montant
c82 = new_system('externe82');
c82 = add_block(c82, 'constant', 'u', 'Value', 0);
c82 = add_block(c82, 'constant', 'x0', 'Value', 3);
c82 = add_block(c82, 'constant', 'v0', 'Value', 2);
c82 = add_block(c82, 'step', 'r', 'Time', 1);
c82 = add_block(c82, 'secondorderintegrator', 's', 'ICSourceX', 'external', ...
                'ICSourceDXDT', 'external', 'ExternalReset', 'rising');
c82 = add_block(c82, 'outport', 'x');
c82 = add_line(add_line(add_line(c82, 'u', 's/1'), 'x0', 's/2'), 'v0', 's/3');
c82 = add_line(add_line(c82, 'r', 's/4'), 's/1', 'x');
c82 = add_block(c82, 'terminator', 'fin');
c82 = add_line(c82, 's/2', 'fin');
r82 = sim(c82, precis82{:}, 'StopTime', 1.5);
xr82 = @(t) interp1(r82.tout, r82.yout(:, 1), t);
assert(abs(r82.yout(1, 1) - 3) < 1e-12 && abs(xr82(0.9) - (3 + 2 * 0.9)) < 1e-6 && ...
       abs(r82.yout(end, 1) - (3 + 2 * 0.5)) < 1e-6, ...
       'x0 et dx0 lus sur leurs entrees, et la remise au front les reprend');
% une seule sortie : dx/dt
u82 = set_param(m82, 's', 'ShowOutput', 'dxdt');
u82 = delete_line(u82, 's/2', 'v');
u82 = delete_block(u82, 'v');
r82 = sim(u82, precis82{:}, 'StopTime', 1);
assert(size(r82.yout, 2) == 1 && abs(r82.yout(end) + 1) < 1e-9, ...
       'ShowOutput dxdt : une seule sortie, dx/dt');
% l'état de fonctionnement d'un intégrateur borné reprend où il était
reglage82 = {'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 3};
entier82 = sim(b82, reglage82{:});
a82 = sim(b82, reglage82{:}, 'StopTime', 1.7, 'SaveFinalState', 'on', 'SaveOperatingPoint', 'on');
s82 = sim(b82, reglage82{:}, 'LoadInitialState', 'on', 'InitialState', a82.xFinal);
garde82 = entier82.tout >= 1.7 - 1e-9;
assert(max(max(abs(s82.yout - entier82.yout(garde82, :)))) < 1e-12, ...
       'un Second-Order Integrator borne reprend son etat');
% ce qui est refusé
refus82 = {
    {'LimitX', 'on', 'UpperLimitX', 0, 'LowerLimitX', 1}, 'Simulink:blocks:SecondOrderIntegratorLimits'
    {'LimitX', 'on', 'LimitDXDT', 'on', 'UpperLimitDXDT', 0}, ...
        'Simulink:blocks:SecondOrderIntegratorLimits'
    {'WrapX', 'on', 'WrappedUpperValueX', -4}, 'Simulink:blocks:SecondOrderIntegratorLimits'
    {'ICX', NaN}, 'Simulink:Parameters:InvalidValue'
    {'ICX', [1 2], 'ICDXDT', [1 2 3]}, 'Simulink:Engine:DimensionMismatch'
    };
for q = 1:size(refus82, 1)
    vu82 = '';
    message82 = '';
    try
        sim(set_param(m82, 's', refus82{q, 1}{:}), precis82{:}, 'StopTime', 1);
    catch err
        vu82 = err.identifier;
        message82 = err.message;
    end
    assert(strcmp(vu82, refus82{q, 2}) && ~isempty(strfind(message82, 'soi82/s')), ...
           sprintf('Second-Order Integrator, refus %d : %s (%s)', q, vu82, message82));
end
fprintf('Second-Order Integrator complet : ok\n');

%% ------ 83. Transfer Fcn Direct Form II, Data Type Scaling Strip, Function-Call Split
% Transfer Fcn Direct Form II rend ce que rend un Discrete Filter de mêmes
% coefficients, part de ses états vinit, range son résultat dans le type
% de son entrée — arrondi, saturé ou replié — et refuse d'hériter d'un
% signal continu. Data Type Scaling Strip rend l'entier stocké d'une
% virgule fixe. Function-Call Split partage l'appel d'un générateur entre
% deux sous-systèmes appelés, et refuse d'appeler autre chose.
valeurs83 = [1 -2 0.5 3 0 -1 2 4 -3 1];
num83 = [0.2 0.3 0.2];
den83 = [-0.9 0.6];
f83 = new_system('forme83');
f83 = add_block(f83, 'repeatingsequencestair', 'u', 'OutValues', valeurs83, 'tsamp', 0.1);
f83 = add_block(f83, 'transferfcndirectformii', 'd', 'NumCoefVec', num83, 'DenCoefVec', den83);
f83 = add_block(f83, 'discretefilter', 'r', 'Numerator', num83, 'Denominator', [1 den83], ...
                'SampleTime', 0.1);
f83 = add_block(f83, 'outport', 'yd');
f83 = add_block(f83, 'outport', 'yr');
f83 = add_line(add_line(add_line(f83, 'u', 'd'), 'u', 'r'), 'd', 'yd');
f83 = add_line(f83, 'r', 'yr');
r83 = sim(f83, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1, 'StopTime', 0.9);
assert(max(abs(r83.yout(:, 1) - r83.yout(:, 2))) < 1e-12, ...
       'la forme directe II rend ce que rend le Discrete Filter');
% les états partent de vinit : y(0) = b0 w0 + b1 v + b2 v, w0 = u0 - a1 v - a2 v
v83 = 0.5;
r83 = sim(set_param(f83, 'd', 'vinit', v83), 'Solver', 'FixedStepDiscrete', ...
          'FixedStep', 0.1, 'StopTime', 0.1);
w0 = valeurs83(1) - (den83(1) + den83(2)) * v83;
assert(abs(r83.yout(1, 1) - (num83(1) * w0 + (num83(2) + num83(3)) * v83)) < 1e-12, ...
       'les etats de la forme directe II partent de vinit');
% un entier : arrondi, puis saturé ou replié
e83 = new_system('entier83');
e83 = add_block(e83, 'constant', 'u', 'Value', int16(400), 'SampleTime', 1);
e83 = add_block(e83, 'transferfcndirectformii', 'd', 'NumCoefVec', 100, 'DenCoefVec', 0);
e83 = add_block(e83, 'outport', 'y');
e83 = add_line(add_line(e83, 'u', 'd'), 'd', 'y');
regle83 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1};
replie83 = sim(e83, regle83{:});
sature83 = sim(set_param(e83, 'd', 'DoSatur', 'on'), regle83{:});
assert(isa(replie83.yout, 'int16') && replie83.yout(1) == int16(40000 - 65536) && ...
       sature83.yout(1) == intmax('int16'), 'un entier deborde : replie, ou sature (DoSatur)');
a83 = sim(set_param(set_param(e83, 'u', 'Value', int16(3)), 'd', 'NumCoefVec', 0.5), regle83{:});
c83 = sim(set_param(set_param(set_param(e83, 'u', 'Value', int16(3)), 'd', 'NumCoefVec', 0.5), ...
                    'd', 'RndMeth', 'Ceiling'), regle83{:});
assert(a83.yout(1) == 1 && c83.yout(1) == 2, '1,5 arrondi selon RndMeth : Floor 1, Ceiling 2');
vu83 = '';
message83 = '';
try
    sim(set_param(f83, 'u', 'tsamp', 0), 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 1);
    s83 = new_system('continu83');
    s83 = add_block(s83, 'sine', 'u');
    s83 = add_block(s83, 'transferfcndirectformii', 'd');
    s83 = add_line(add_block(add_line(s83, 'u', 'd'), 'outport', 'y'), 'd', 'y');
    sim(s83, 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 1);
catch err
    vu83 = err.identifier;
    message83 = err.message;
end
assert(strcmp(vu83, 'Simulink:SampleTime:DiscreteBlockContinuous') && ...
       ~isempty(strfind(message83, 'continu83/d')), ...
       'la forme directe II refuse un signal continu, en se nommant');
% Data Type Scaling Strip : l'entier stocké
t83 = new_system('strip83');
t83 = add_block(t83, 'constant', 'u', 'Value', 2.5, 'OutDataTypeStr', 'fixdt(1,16,8)');
t83 = add_block(t83, 'datatypescalingstrip', 's');
t83 = add_block(t83, 'constant', 'v', 'Value', 3.7);
t83 = add_block(t83, 'datatypescalingstrip', 's2');
t83 = add_block(t83, 'outport', 'y');
t83 = add_block(t83, 'outport', 'y2');
t83 = add_line(add_line(add_line(t83, 'u', 's'), 's', 'y'), 'v', 's2');
t83 = add_line(t83, 's2', 'y2');
r83 = sim(t83, regle83{:});
assert(r83.yout(1, 1) == 640 && abs(r83.yout(1, 2) - 3.7) < 1e-15, ...
       'Data Type Scaling Strip : 2,5 en fixdt(1,16,8) est l''entier 640 ; un double passe');
% Function-Call Split : un générateur, deux compteurs appelés
compteur83 = new_system('compteur83');
compteur83 = add_block(compteur83, 'constant', 'un', 'Value', 1);
compteur83 = add_block(compteur83, 'sum', 'plus', 'Signs', '++');
compteur83 = add_block(compteur83, 'delay', 'avant', 'InitialCondition', 0);
compteur83 = add_block(compteur83, 'outport', 'n', 'Port', 1);
compteur83 = add_block(compteur83, 'triggerport', 'f', 'TriggerType', 'function-call');
compteur83 = add_line(add_line(compteur83, 'un', 'plus', 1), 'avant', 'plus', 2);
compteur83 = add_line(add_line(compteur83, 'plus', 'avant'), 'plus', 'n');
p83 = new_system('partage83');
p83 = add_block(p83, 'functioncallgenerator', 'horloge', 'sample_time', 0.5);
p83 = add_block(p83, 'functioncallsplit', 'partage');
p83 = add_block(p83, 'subsystem', 'a', 'Model', compteur83);
p83 = add_block(p83, 'subsystem', 'b', 'Model', compteur83);
p83 = add_block(p83, 'outport', 'ya');
p83 = add_block(p83, 'outport', 'yb');
p83 = add_line(add_line(p83, 'horloge', 'partage'), 'partage/1', 'a/Trigger');
p83 = add_line(add_line(p83, 'partage/2', 'b/Trigger'), 'a', 'ya');
p83 = add_line(p83, 'b', 'yb');
for solveur = {'ode4', 'ode45'}
    r83 = sim(p83, 'Solver', solveur{1}, 'FixedStep', 0.1, 'StopTime', 2);
    assert(isequal(r83.yout(end, :), [5 5]), ...
           [solveur{1} ' : chaque sous-systeme est appele a chaque appel du generateur']);
end
base83 = new_system('partage83');
base83 = add_block(base83, 'functioncallgenerator', 'horloge', 'sample_time', 0.5);
base83 = add_block(base83, 'functioncallsplit', 'partage');
base83 = add_block(base83, 'subsystem', 'a', 'Model', compteur83);
base83 = add_block(base83, 'gain', 'g');
base83 = add_block(base83, 'constant', 'k');
base83 = add_line(base83, 'partage/1', 'a/Trigger');
refus83 = {
    add_line(add_line(base83, 'horloge', 'partage'), 'partage/2', 'g'), ...
        'Simulink:blocks:FcnCallOutputToNonFcnCallInput', 'partage83/partage'
    add_line(base83, 'k', 'partage'), 'Simulink:blocks:FcnCallSubsystemInputNotFcnCall', ...
        'partage83/a'
    };
for q = 1:size(refus83, 1)
    vu83 = '';
    message83 = '';
    try
        sim(refus83{q, 1}, 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 1);
    catch err
        vu83 = err.identifier;
        message83 = err.message;
    end
    assert(strcmp(vu83, refus83{q, 2}) && ~isempty(strfind(message83, refus83{q, 3})), ...
           sprintf('Function-Call Split, refus %d : %s (%s)', q, vu83, message83));
end
fprintf('Transfer Fcn Direct Form II, Data Type Scaling Strip, Function-Call Split : ok\n');

%% --------------------- 84. DocBlock, Model Info, et les nouveaux blocs en .slx
% Un modèle de Simulink porte souvent un DocBlock ou un Model Info : des
% notes, qui ne calculent rien. Un .slx qui en contient se lit et simule.
% Les blocs de bibliothèque des derniers lots s'écrivent dans un .slx en
% Reference, comme Simulink les range, et se relisent ; la variante bornée
% du Second-Order Integrator y garde ses bornes.
dossier84 = tempname();
mkdir(fullfile(dossier84, 'simulink', 'systems'));
mkdir(fullfile(dossier84, '_rels'));
parties84 = {
    '[Content_Types].xml', ['<?xml version="1.0" encoding="utf-8"?><Types xmlns="http://' ...
        'schemas.openxmlformats.org/package/2006/content-types"><Default Extension="xml" ' ...
        'ContentType="application/vnd.mathworks.simulink.model+xml"/></Types>']
    fullfile('simulink', 'blockdiagram.xml'), ['<?xml version="1.0" encoding="utf-8"?>' ...
        '<ModelInformation Version="1.0"><Model Name="notes84"><P Name="Version">10.4</P>' ...
        '<System Ref="system_root"/></Model></ModelInformation>']
    fullfile('simulink', 'systems', 'system_root.xml'), ['<?xml version="1.0" encoding="utf-8"?>' ...
        '<System><Block BlockType="Constant" Name="Constant" SID="1"><P Name="Value">3</P></Block>' ...
        '<Block BlockType="Gain" Name="Gain" SID="2"><P Name="Gain">2</P></Block>' ...
        '<Block BlockType="Outport" Name="Out1" SID="3"/>' ...
        '<Block BlockType="Reference" Name="DocBlock" SID="4"><P Name="SourceBlock">' ...
        'simulink/Model-Wide&#xA;Utilities/DocBlock</P><P Name="SourceType">DocBlock</P>' ...
        '<P Name="DocumentType">Text</P></Block>' ...
        '<Block BlockType="Reference" Name="Model Info" SID="5"><P Name="SourceBlock">' ...
        'simulink/Model-Wide&#xA;Utilities/Model Info</P><P Name="SourceType">CMBlock</P>' ...
        '</Block>' ...
        '<Line><P Name="Src">1#out:1</P><P Name="Dst">2#in:1</P></Line>' ...
        '<Line><P Name="Src">2#out:1</P><P Name="Dst">3#in:1</P></Line></System>']
    };
for q = 1:size(parties84, 1)
    f84 = fopen(fullfile(dossier84, parties84{q, 1}), 'w');
    fprintf(f84, '%s', parties84{q, 2});
    fclose(f84);
end
fichier84 = [tempname() '.slx'];
zip(fichier84, {'[Content_Types].xml', 'simulink'}, dossier84);
if exist([fichier84 '.zip'], 'file')
    movefile([fichier84 '.zip'], fichier84);
end
notes84 = load_system(fichier84);
r84 = sim(notes84, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1);
assert(r84.yout(end) == 6 && strcmp(get_param(notes84, 'DocBlock', 'BlockType'), 'docblock') && ...
       strcmp(get_param(notes84, 'Model Info', 'BlockType'), 'modelinfo'), ...
       'un .slx qui porte un DocBlock et un Model Info se lit et simule');
delete(fichier84);
rmdir(dossier84, 's');
% les nouveaux blocs s'écrivent en Reference, et se relisent
n84 = new_system('nouveaux84');
n84 = add_block(n84, 'constant', 'u', 'Value', [1 2; 3 4]);
n84 = add_block(n84, 'transpose', 't');
n84 = add_block(n84, 'incrementrealworld', 'i');
n84 = add_block(n84, 'docblock', 'note');
n84 = add_block(n84, 'constant', 'a', 'Value', 1);
n84 = add_block(n84, 'secondorderintegratorlimited', 's');
n84 = add_block(n84, 'outport', 'y');
n84 = add_block(n84, 'outport', 'x');
n84 = add_block(n84, 'terminator', 'fin');
n84 = add_line(add_line(add_line(n84, 'u', 't'), 't', 'i'), 'i', 'y');
n84 = add_line(add_line(add_line(n84, 'a', 's'), 's/1', 'x'), 's/2', 'fin');
fichier84 = [tempname() '.slx'];
save_system(n84, fichier84);
dossier84 = tempname();
unzip(fichier84, dossier84);
xml84 = fileread(fullfile(dossier84, 'simulink', 'blockdiagram.xml'));
assert(~isempty(strfind(xml84, 'simulink/Matrix Operations/Transpose')) && ...
       ~isempty(strfind(xml84, 'Increment Real World')) && ...
       ~isempty(strfind(xml84, 'simulink/Model-Wide Utilities/DocBlock')) && ...
       ~isempty(strfind(xml84, '<P Name="LimitX">on</P>')), ...
       'les blocs de bibliotheque s''ecrivent en Reference ; la variante bornee dit ses bornes');
relu84 = load_system(fichier84);
regle84 = {'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 2};
avant84 = sim(n84, regle84{:});
apres84 = sim(relu84, regle84{:});
assert(isequal(avant84.yout, apres84.yout) && max(apres84.yout(:, end)) == 1, ...
       'relu du .slx, le modele simule de meme, x tenu a sa borne 1');
delete(fichier84);
rmdir(dossier84, 's');
fprintf('DocBlock, Model Info et nouveaux blocs en .slx : ok\n');

%% ----------------------- 85. Les ports d'élément de bus : In et Out Bus Element
% In Bus Element et Out Bus Element, les ports de bus des sous-systèmes de
% Simulink : les In Bus Element de même nom de port sont une seule entrée,
% chacun en reprenant un élément par son nom — chemin pointé pour un bus
% emboîté, le bus entier si l'élément est vide — ; les Out Bus Element de
% même nom forment ensemble le bus d'une seule sortie.
dedans85 = new_system('dedans85');
dedans85 = add_block(dedans85, 'inbuselement', 'a', 'PortName', 'InBus', 'Element', 'a');
dedans85 = add_block(dedans85, 'inbuselement', 'b', 'PortName', 'InBus', 'Element', 'b');
dedans85 = add_block(dedans85, 'gain', 'ga', 'Gain', 2);
dedans85 = add_block(dedans85, 'gain', 'gb', 'Gain', 3);
dedans85 = add_block(dedans85, 'outbuselement', 'x', 'PortName', 'OutBus', 'Element', 'x');
dedans85 = add_block(dedans85, 'outbuselement', 'y', 'PortName', 'OutBus', 'Element', 'y');
dedans85 = add_line(add_line(dedans85, 'a', 'ga'), 'b', 'gb');
dedans85 = add_line(add_line(dedans85, 'ga', 'x'), 'gb', 'y');
m85 = new_system('bus85');
m85 = add_block(m85, 'constant', 'c1', 'Value', 1);
m85 = add_block(m85, 'constant', 'c2', 'Value', 2);
m85 = add_block(m85, 'buscreator', 'bc', 'Inputs', 'a,b');
m85 = add_block(m85, 'subsystem', 's', 'Model', dedans85);
m85 = add_block(m85, 'busselector', 'bs', 'OutputSignals', 'y,x');
m85 = add_block(m85, 'outport', 'oy');
m85 = add_block(m85, 'outport', 'ox');
m85 = add_line(add_line(m85, 'c1', 'bc/1'), 'c2', 'bc/2');
m85 = add_line(add_line(m85, 'bc', 's'), 's', 'bs');
m85 = add_line(add_line(m85, 'bs/1', 'oy'), 'bs/2', 'ox');
[ne85, ns85] = matlibre_sl_ports(m85.blocs{4});
assert(ne85 == 1 && ns85 == 1, 'deux In Bus Element et deux Out Bus Element : un port de chaque');
regle85 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1};
r85 = sim(m85, regle85{:});
assert(isequal(r85.yout(end, :), [6 2]), ...
       'les elements a et b lus par leur nom, x et y ecrits dans le bus de sortie');
% un bus emboîté : l'élément n.c ; le bus entier quand l'élément est vide
emboite85 = new_system('emboite85');
emboite85 = add_block(emboite85, 'inbuselement', 'nc', 'PortName', 'B', 'Element', 'n.c');
emboite85 = add_block(emboite85, 'inbuselement', 'tout', 'PortName', 'B', 'Element', '');
emboite85 = add_block(emboite85, 'busselector', 'sel', 'OutputSignals', 'e');
emboite85 = add_block(emboite85, 'outport', 'o1', 'Port', 1);
emboite85 = add_block(emboite85, 'outport', 'o2', 'Port', 2);
emboite85 = add_line(add_line(emboite85, 'nc', 'o1'), 'tout', 'sel');
emboite85 = add_line(emboite85, 'sel', 'o2');
e85 = new_system('externe85');
e85 = add_block(e85, 'constant', 'c', 'Value', 5);
e85 = add_block(e85, 'constant', 'd', 'Value', 6);
e85 = add_block(e85, 'constant', 'e', 'Value', 7);
e85 = add_block(e85, 'buscreator', 'n', 'Inputs', 'c,d');
e85 = add_block(e85, 'buscreator', 'haut', 'Inputs', 'n,e');
e85 = add_block(e85, 'subsystem', 's', 'Model', emboite85);
e85 = add_block(e85, 'outport', 'y1');
e85 = add_block(e85, 'outport', 'y2');
e85 = add_line(add_line(add_line(e85, 'c', 'n/1'), 'd', 'n/2'), 'n', 'haut/1');
e85 = add_line(add_line(e85, 'e', 'haut/2'), 'haut', 's');
e85 = add_line(add_line(e85, 's/1', 'y1'), 's/2', 'y2');
r85 = sim(e85, regle85{:});
assert(isequal(r85.yout(end, :), [5 7]), ...
       'l''element n.c d''un bus emboite, et le bus entier quand l''element est vide');
% deux ports de bus et une entrée ordinaire, par leur rang
mixte85 = new_system('mixte85');
mixte85 = add_block(mixte85, 'inport', 'u', 'Port', 2);
mixte85 = add_block(mixte85, 'inbuselement', 'p', 'PortName', 'P', 'Element', 'a', 'Port', 1);
mixte85 = add_block(mixte85, 'sum', 's', 'Signs', '+-');
mixte85 = add_block(mixte85, 'outport', 'o');
mixte85 = add_line(add_line(add_line(mixte85, 'p', 's/1'), 'u', 's/2'), 's', 'o');
x85 = new_system('rangs85');
x85 = add_block(x85, 'constant', 'k', 'Value', 10);
x85 = add_block(x85, 'buscreator', 'bc', 'Inputs', 'a,b');
x85 = add_block(x85, 'constant', 'm', 'Value', 4);
x85 = add_block(x85, 'subsystem', 's', 'Model', mixte85);
x85 = add_block(x85, 'outport', 'y');
x85 = add_line(add_line(x85, 'k', 'bc/1'), 'k', 'bc/2');
x85 = add_line(add_line(add_line(x85, 'bc', 's/1'), 'm', 's/2'), 's', 'y');
r85 = sim(x85, regle85{:});
assert(r85.yout(end) == 6, 'le port de bus au rang 1, l''entree ordinaire au rang 2');
% le .slx garde les ports d'élément de bus
fichier85 = [tempname() '.slx'];
save_system(m85, fichier85);
dossier85 = tempname();
unzip(fichier85, dossier85);
xml85 = fileread(fullfile(dossier85, 'simulink', 'blockdiagram.xml'));
assert(~isempty(strfind(xml85, 'IsBusElementPort')), ...
       'le .slx ecrit les ports d''element de bus comme Simulink');
relu85 = load_system(fichier85);
assert(isequal(sim(relu85, regle85{:}).yout, sim(m85, regle85{:}).yout), ...
       'relu du .slx, le modele aux ports de bus simule de meme');
delete(fichier85);
rmdir(dossier85, 's');
% ce qui est refusé
refus85 = {
    set_param(dedans85, 'y', 'Element', 'x'), 'Simulink:blocks:BusElementPortDuplicate'
    set_param(dedans85, 'y', 'Element', 'z.w'), 'Simulink:blocks:BusElementPortNested'
    set_param(dedans85, 'b', 'Element', 'absent'), 'Simulink:'
    };
for q = 1:size(refus85, 1)
    vu85 = '';
    message85 = '';
    try
        sim(set_param(m85, 's', 'Model', refus85{q, 1}), regle85{:});
    catch err
        vu85 = err.identifier;
        message85 = err.message;
    end
    assert(strncmp(vu85, refus85{q, 2}, numel(refus85{q, 2})) && ...
           ~isempty(strfind(message85, 'bus85/s')), ...
           sprintf('ports de bus, refus %d : %s (%s)', q, vu85, message85));
end
fprintf('ports d''element de bus : ok\n');

%% ---------------------------- 86. Simulink Function et Function Caller
% Un Simulink Function est une fonction faite de blocs, que les Function
% Caller appellent par son nom et son prototype — y = f(u), [s, d] =
% sd(a, b) — ; une fonction « scoped » se voit dans son système et ses
% sous-systèmes, et s'appelle qualifiée d'ailleurs (A.f). Une fonction
% introuvable, un prototype qui ne s'accorde pas, une fonction à états
% appelée de plusieurs endroits — que MatLibre ne partage pas encore —
% sont refusés en nommant le bloc.
m86 = new_system('fonctions86');
m86 = add_block(m86, 'Simulink Function', 'double');
corps86 = get_param(m86, 'double', 'Model');
corps86 = set_param(corps86, 'f', 'FunctionName', 'timestwo');
corps86 = add_block(corps86, 'gain', 'g', 'Gain', 2);
corps86 = delete_line(corps86, 'u', 'y');
corps86 = add_line(add_line(corps86, 'u', 'g'), 'g', 'y');
m86 = set_param(m86, 'double', 'Model', corps86);
[ne86, ns86] = matlibre_sl_ports(m86.blocs{1});
assert(ne86 == 0 && ns86 == 0, 'un Simulink Function n''a pas de port : on l''appelle');
m86 = add_block(m86, 'constant', 'a', 'Value', 3);
m86 = add_block(m86, 'constant', 'b', 'Value', 5);
m86 = add_block(m86, 'functioncaller', 'appel1', 'FunctionPrototype', 'y = timestwo(u)');
m86 = add_block(m86, 'functioncaller', 'appel2', 'FunctionPrototype', 'z = timestwo(x)');
m86 = add_block(m86, 'outport', 'y1');
m86 = add_block(m86, 'outport', 'y2');
m86 = add_line(add_line(m86, 'a', 'appel1'), 'appel1', 'y1');
m86 = add_line(add_line(m86, 'b', 'appel2'), 'appel2', 'y2');
regle86 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 3};
r86 = sim(m86, regle86{:});
assert(isequal(r86.yout(end, :), [6 10]), 'deux appels de timestwo : 6 et 10');
% deux arguments d'entrée, deux de sortie, appariés par leur nom
sd86 = new_system('sd86');
sd86 = add_block(sd86, 'triggerport', 'f', 'TriggerType', 'function-call', ...
                 'IsSimulinkFunction', 'on', 'FunctionName', 'sd');
sd86 = add_block(sd86, 'argin', 'a', 'ArgumentName', 'a', 'Port', 1);
sd86 = add_block(sd86, 'argin', 'b', 'ArgumentName', 'b', 'Port', 2);
sd86 = add_block(sd86, 'sum', 'plus', 'Signs', '++');
sd86 = add_block(sd86, 'sum', 'moins', 'Signs', '+-');
sd86 = add_block(sd86, 'argout', 's', 'ArgumentName', 's', 'Port', 1);
sd86 = add_block(sd86, 'argout', 'd', 'ArgumentName', 'd', 'Port', 2);
sd86 = add_line(add_line(sd86, 'a', 'plus/1'), 'b', 'plus/2');
sd86 = add_line(add_line(sd86, 'a', 'moins/1'), 'b', 'moins/2');
sd86 = add_line(add_line(sd86, 'plus', 's'), 'moins', 'd');
p86 = new_system('prototype86');
p86 = add_block(p86, 'subsystem', 'fonction', 'Model', sd86);
p86 = add_block(p86, 'constant', 'x', 'Value', 7);
p86 = add_block(p86, 'constant', 'w', 'Value', 2);
p86 = add_block(p86, 'functioncaller', 'appel', 'FunctionPrototype', '[d, s] = sd(b, a)');
p86 = add_block(p86, 'outport', 'o1');
p86 = add_block(p86, 'outport', 'o2');
p86 = add_line(add_line(p86, 'x', 'appel/1'), 'w', 'appel/2');
p86 = add_line(add_line(p86, 'appel/1', 'o1'), 'appel/2', 'o2');
r86 = sim(p86, regle86{:});
% b = 7, a = 2 : d = a - b = -5, s = 9
assert(isequal(r86.yout(end, :), [-5 9]), 'les arguments s''apparient par leur nom');
% une fonction à états, appelée d'un seul endroit : elle compte
compte86 = new_system('compte86');
compte86 = add_block(compte86, 'triggerport', 'f', 'TriggerType', 'function-call', ...
                     'IsSimulinkFunction', 'on', 'FunctionName', 'compte');
compte86 = add_block(compte86, 'argin', 'u', 'ArgumentName', 'u');
compte86 = add_block(compte86, 'sum', 's', 'Signs', '++');
compte86 = add_block(compte86, 'delay', 'z', 'SampleTime', 1);
compte86 = add_block(compte86, 'argout', 'y', 'ArgumentName', 'y');
compte86 = add_line(add_line(compte86, 'u', 's/1'), 'z', 's/2');
compte86 = add_line(add_line(compte86, 's', 'z'), 's', 'y');
c86 = new_system('etats86');
c86 = add_block(c86, 'subsystem', 'fonction', 'Model', compte86);
c86 = add_block(c86, 'constant', 'un', 'Value', 1, 'SampleTime', 1);
c86 = add_block(c86, 'functioncaller', 'appel', 'FunctionPrototype', 'y = compte(u)');
c86 = add_block(c86, 'outport', 'y');
c86 = add_line(add_line(c86, 'un', 'appel'), 'appel', 'y');
r86 = sim(c86, regle86{:});
assert(isequal(r86.yout(:).', [1 2 3 4]), 'une fonction a etats, appelee d''un endroit, compte');
% une fonction « scoped » dans un sous-système : invisible d'ailleurs sans
% qualifiant, visible qualifiée
boite86 = new_system('A');
boite86 = add_block(boite86, 'subsystem', 'fonction', 'Model', corps86);
boite86 = add_block(boite86, 'inport', 'In1');
boite86 = add_block(boite86, 'outport', 'Out1');
boite86 = add_line(boite86, 'In1', 'Out1');
q86 = new_system('portee86');
q86 = add_block(q86, 'subsystem', 'A', 'Model', boite86);
q86 = add_block(q86, 'constant', 'k', 'Value', 4);
q86 = add_block(q86, 'functioncaller', 'appel', 'FunctionPrototype', 'y = timestwo(u)', ...
                'ScopedFunctionName', 'A.timestwo');
q86 = add_block(q86, 'outport', 'y');
q86 = add_block(q86, 'terminator', 't');
q86 = add_line(add_line(add_line(q86, 'k', 'appel'), 'appel', 'y'), 'k', 'A');
q86 = add_line(q86, 'A', 't');
r86 = sim(q86, regle86{:});
assert(r86.yout(end) == 8, 'une fonction scoped, appelee qualifiee : A.timestwo');
refus86 = {
    set_param(q86, 'appel', 'ScopedFunctionName', ''), 'Simulink:SimulinkFunction:FunctionNotFound', ...
        'portee86/appel'
    set_param(m86, 'appel1', 'FunctionPrototype', 'y = absente(u)'), ...
        'Simulink:SimulinkFunction:FunctionNotFound', 'fonctions86/appel1'
    add_line(add_block(add_block(set_param(p86, 'appel', 'FunctionPrototype', ...
                                           '[d, s] = sd(b, a, c)'), 'constant', 'c3'), ...
                       'terminator', 't3'), 'c3', 'appel/3'), ...
        'Simulink:SimulinkFunction:PrototypeMismatch', 'prototype86/appel'
    add_line(add_block(add_block(c86, 'functioncaller', 'autre', 'FunctionPrototype', ...
                                 'y = compte(u)'), 'terminator', 'fin'), 'autre', 'fin'), ...
        'Simulink:SimulinkFunction:SharedStateNotSupported', 'etats86/fonction'
    add_block(new_system('seul86'), 'argin', 'u'), ...
        'Simulink:SimulinkFunction:ArgumentOutsideFunction', 'seul86/u'
    };
for q = 1:size(refus86, 1)
    vu86 = '';
    message86 = '';
    try
        evalc('sim(refus86{q, 1}, regle86{:});');
    catch err
        vu86 = err.identifier;
        message86 = err.message;
    end
    assert(strcmp(vu86, refus86{q, 2}) && ~isempty(strfind(message86, refus86{q, 3})), ...
           sprintf('Simulink Function, refus %d : %s (%s)', q, vu86, message86));
end
% le .slx garde la fonction et ses appels
fichier86 = [tempname() '.slx'];
save_system(m86, fichier86);
relu86 = load_system(fichier86);
assert(isequal(sim(relu86, regle86{:}).yout(end, :), [6 10]), ...
       'relu du .slx, le modele appelle sa fonction de meme');
delete(fichier86);
fprintf('Simulink Function et Function Caller : ok\n');

%% --------------------------- 87. Les accès aux mémoires partagées, diagnostiqués
% Les diagnostics d'accès de Simulink aux mémoires partagées : dans un pas,
% une lecture avant toute écriture (ReadBeforeWriteMsg), une écriture
% après une lecture (WriteAfterReadMsg), une seconde écriture
% (WriteAfterWriteMsg). Chaque Data Store Memory a son réglage — rien,
% rien, avertissement par défaut — ; le modèle les laisse faire
% (UseLocalSettings), les tait tous, ou les fait tous avertir ou refuser.
m87 = new_system('memoire87');
m87 = add_block(m87, 'datastorememory', 'mem', 'DataStoreName', 'A', 'InitialValue', 0);
m87 = add_block(m87, 'constant', 'c1', 'Value', 1, 'SampleTime', 1);
m87 = add_block(m87, 'constant', 'c2', 'Value', 2, 'SampleTime', 1);
m87 = add_block(m87, 'datastorewrite', 'w1', 'DataStoreName', 'A');
m87 = add_block(m87, 'datastorewrite', 'w2', 'DataStoreName', 'A');
m87 = add_line(add_line(m87, 'c1', 'w1'), 'c2', 'w2');
regle87 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 2};
assert(strcmp(get_param(m87, 'WriteAfterWriteMsg'), 'UseLocalSettings') && ...
       strcmp(get_param(m87, 'mem', 'WriteAfterWriteMsg'), 'warning'), ...
       'par defaut, le reglage du bloc ; une seconde ecriture avertit');
lastwarn('');
evalc('sim(m87, regle87{:});');
[texte87, id87] = lastwarn();
assert(strcmp(id87, 'Simulink:DataStores:WriteAfterWrite') && ...
       ~isempty(strfind(texte87, 'memoire87/w1')) && ~isempty(strfind(texte87, 'memoire87/w2')), ...
       'deux ecritures dans un pas : l''avertissement nomme les deux blocs');
vu87 = '';
try
    sim(m87, regle87{:}, 'WriteAfterWriteMsg', 'EnableAllAsError');
catch err
    vu87 = err.identifier;
end
assert(strcmp(vu87, 'Simulink:DataStores:WriteAfterWrite'), 'EnableAllAsError : refuse');
lastwarn('');
evalc('sim(m87, regle87{:}, ''WriteAfterWriteMsg'', ''DisableAll'');');
[~, id87] = lastwarn();
assert(isempty(id87), 'DisableAll : rien n''est dit');
lastwarn('');
evalc('sim(set_param(m87, ''mem'', ''WriteAfterWriteMsg'', ''none''), regle87{:});');
[~, id87] = lastwarn();
assert(isempty(id87), 'le bloc a none : rien n''est dit');
% une lecture avant l'écriture du pas, une écriture après une lecture
l87 = new_system('lecture87');
l87 = add_block(l87, 'datastorememory', 'mem', 'DataStoreName', 'B', ...
                'ReadBeforeWriteMsg', 'error', 'WriteAfterReadMsg', 'warning');
l87 = add_block(l87, 'datastoreread', 'r', 'DataStoreName', 'B', 'SampleTime', 1);
l87 = add_block(l87, 'gain', 'g', 'Gain', 2);
l87 = add_block(l87, 'datastorewrite', 'w', 'DataStoreName', 'B');
l87 = add_block(l87, 'outport', 'y');
l87 = add_line(add_line(add_line(l87, 'r', 'g'), 'g', 'w'), 'r', 'y');
vu87 = '';
message87 = '';
try
    sim(l87, regle87{:});
catch err
    vu87 = err.identifier;
    message87 = err.message;
end
assert(strcmp(vu87, 'Simulink:DataStores:ReadBeforeWrite') && ...
       ~isempty(strfind(message87, 'lecture87/r')), ...
       'une lecture avant toute ecriture du pas : refusee (ReadBeforeWriteMsg error)');
lastwarn('');
evalc('sim(set_param(l87, ''mem'', ''ReadBeforeWriteMsg'', ''none''), regle87{:});');
[texte87, id87] = lastwarn();
assert(strcmp(id87, 'Simulink:DataStores:WriteAfterRead') && ...
       ~isempty(strfind(texte87, 'lecture87/w')), ...
       'une ecriture apres une lecture du pas : l''avertissement');
% une mémoire globale (Simulink.Signal) ne se signale pas, sauf à tout
% activer
assignin('base', 'G87', Simulink.Signal);
g87 = new_system('globale87');
g87 = add_block(g87, 'constant', 'c1', 'Value', 1, 'SampleTime', 1);
g87 = add_block(g87, 'constant', 'c2', 'Value', 2, 'SampleTime', 1);
g87 = add_block(g87, 'datastorewrite', 'w1', 'DataStoreName', 'G87');
g87 = add_block(g87, 'datastorewrite', 'w2', 'DataStoreName', 'G87');
g87 = add_line(add_line(g87, 'c1', 'w1'), 'c2', 'w2');
lastwarn('');
evalc('sim(g87, regle87{:});');
[~, id87] = lastwarn();
vu87 = '';
try
    sim(g87, regle87{:}, 'WriteAfterWriteMsg', 'EnableAllAsError');
catch err
    vu87 = err.identifier;
end
assert(isempty(id87) && strcmp(vu87, 'Simulink:DataStores:WriteAfterWrite'), ...
       'une memoire globale : rien par defaut, refusee quand tout est active');
evalin('base', 'clear G87');
fprintf('acces aux memoires partagees : ok\n');

%% ---------------------------- 88. Un produit qui inverse une matrice singulière
% Le diagnostic « Division by singular matrix » de Simulink
% (CheckMatrixSingularityMsg) : un Product en multiplication matricielle
% qui inverse une entrée singulière ne dit rien par défaut, avertit en se
% nommant, ou arrête la simulation. Une entrée inversible ne dit jamais
% rien.
m88 = new_system('singulier88');
m88 = add_block(m88, 'constant', 'A', 'Value', [1 2; 2 4]);
m88 = add_block(m88, 'constant', 'B', 'Value', eye(2));
m88 = add_block(m88, 'product', 'p', 'Inputs', '*/', 'Multiplication', 'Matrix(*)');
m88 = add_block(m88, 'terminator', 't');
m88 = add_line(add_line(add_line(m88, 'B', 'p/1'), 'A', 'p/2'), 'p', 't');
regle88 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1};
assert(strcmp(get_param(m88, 'CheckMatrixSingularityMsg'), 'none'), ...
       'CheckMatrixSingularityMsg vaut none par defaut, comme dans Simulink');
lastwarn('');
evalc('sim(m88, regle88{:});');
[~, id88] = lastwarn();
assert(~strcmp(id88, 'Simulink:blocks:ProductSingularMatrix'), 'none : rien n''est dit');
lastwarn('');
evalc('sim(m88, regle88{:}, ''CheckMatrixSingularityMsg'', ''warning'');');
[texte88, id88] = lastwarn();
assert(strcmp(id88, 'Simulink:blocks:ProductSingularMatrix') && ...
       ~isempty(strfind(texte88, 'singulier88/p')), 'warning : l''avertissement nomme le bloc');
vu88 = '';
try
    evalc('sim(m88, regle88{:}, ''CheckMatrixSingularityMsg'', ''error'');');
catch err
    vu88 = err.identifier;
end
assert(strcmp(vu88, 'Simulink:blocks:ProductSingularMatrix'), 'error : la simulation s''arrete');
lastwarn('');
evalc(['sim(set_param(m88, ''A'', ''Value'', [2 1; 1 3]), regle88{:}, ' ...
       '''CheckMatrixSingularityMsg'', ''error'');']);
[~, id88] = lastwarn();
assert(~strcmp(id88, 'Simulink:blocks:ProductSingularMatrix'), 'une matrice inversible : rien');
fprintf('produit matriciel singulier : ok\n');

%% ------------------------------------ 89. L'intégrateur à état enroulé
% WrapState : l'état de l'intégrateur s'enroule entre deux valeurs — un
% angle entre -pi et pi —, sans passage par zéro, comme dans Simulink.
% Borner et enrouler à la fois est refusé, comme des valeurs inversées.
m89 = new_system('angle89');
m89 = add_block(m89, 'constant', 'w', 'Value', 1);
m89 = add_block(m89, 'integrator', 'theta', 'WrapState', 'on');
m89 = add_block(m89, 'outport', 'y');
m89 = add_line(add_line(m89, 'w', 'theta'), 'theta', 'y');
for solveur = {'ode45', 'ode4'}
    r89 = sim(m89, 'Solver', solveur{1}, 'FixedStep', 0.01, 'RelTol', 1e-9, 'AbsTol', 1e-12, ...
              'StopTime', 10);
    attendu89 = mod(r89.tout + pi, 2 * pi) - pi;
    assert(max(abs(r89.yout - attendu89)) < 1e-6 && all(r89.yout < pi) && ...
           all(r89.yout >= -pi), [solveur{1} ' : l''angle s''enroule entre -pi et pi']);
end
r89 = sim(set_param(m89, 'theta', 'WrappedStateUpperValue', 1, 'WrappedStateLowerValue', 0), ...
          'Solver', 'ode45', 'RelTol', 1e-9, 'AbsTol', 1e-12, 'StopTime', 3.5);
assert(abs(r89.yout(end) - 0.5) < 1e-6, 'enroule entre 0 et 1 : 3,5 devient 0,5');
refus89 = {
    {'LimitOutput', 'on'}, 'Simulink:blocks:IntegratorWrapAndLimit'
    {'WrappedStateUpperValue', -4}, 'Simulink:blocks:IntegratorWrapValues'
    };
for q = 1:size(refus89, 1)
    vu89 = '';
    message89 = '';
    try
        sim(set_param(m89, 'theta', refus89{q, 1}{:}), 'Solver', 'ode45', 'StopTime', 1);
    catch err
        vu89 = err.identifier;
        message89 = err.message;
    end
    assert(strcmp(vu89, refus89{q, 2}) && ~isempty(strfind(message89, 'angle89/theta')), ...
           sprintf('integrateur enroule, refus %d : %s', q, vu89));
end
fprintf('integrateur a etat enroule : ok\n');

%% --------------------------------------------- 90. Le Selector en entier
% Le Selector de Simulink : une option d'indices par dimension — tout,
% indices donnés ou lus sur un port, plage d'une taille donnée à partir
% d'un indice donné ou lu —, comptés de 1 ou de 0. Les anciens Indices
% restent compris. Un indice hors de l'entrée est refusé en nommant le
% bloc, à la compilation comme pendant la simulation.
M90 = magic(4);
regle90 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1};
cas90 = {
    {'Indices', [3 1]}, (1:6)', [3; 1]
    {'NumberOfDimensions', 1, 'IndexOptionArray', {'Index vector (dialog)'}, ...
     'IndexParamArray', {[2 4]}}, (10:15)', [11; 13]
    {'NumberOfDimensions', 1, 'IndexMode', 'Zero-based', ...
     'IndexOptionArray', {'Starting index (dialog)'}, 'IndexParamArray', {1}, ...
     'OutputSizeArray', {3}}, (10:15)', [11; 12; 13]
    {'NumberOfDimensions', 2, 'IndexOptionArray', {'Select all', 'Index vector (dialog)'}, ...
     'IndexParamArray', {[], [4 1]}}, M90, M90(:, [4 1])
    {'NumberOfDimensions', 2, 'IndexOptionArray', ...
     {'Starting index (dialog)', 'Select all'}, 'IndexParamArray', {2, []}, ...
     'OutputSizeArray', {2, []}}, M90, M90(2:3, :)
    };
for q = 1:size(cas90, 1)
    m90 = new_system('selecteur90');
    m90 = add_block(m90, 'constant', 'u', 'Value', cas90{q, 2});
    m90 = add_block(m90, 'selector', 's', cas90{q, 1}{:});
    m90 = add_block(m90, 'toworkspace', 'tw', 'VariableName', 'sortie90', 'SaveFormat', 'Array');
    m90 = add_line(add_line(m90, 'u', 's'), 's', 'tw');
    evalc('sim(m90, regle90{:});');
    vu90 = evalin('base', 'sortie90');
    if ndims(vu90) == 3
        vu90 = vu90(:, :, end);
    else
        vu90 = vu90(end, :);
    end
    assert(isequal(double(vu90(:)), double(cas90{q, 3}(:))), ...
           sprintf('Selector %d : %s au lieu de %s', q, mat2str(vu90), mat2str(cas90{q, 3})));
end
% des indices lus sur des ports, une ligne et une plage de colonnes
p90 = new_system('ports90');
p90 = add_block(p90, 'constant', 'u', 'Value', M90);
p90 = add_block(p90, 'constant', 'ligne', 'Value', 3);
p90 = add_block(p90, 'constant', 'debut', 'Value', 2);
p90 = add_block(p90, 'selector', 's', 'NumberOfDimensions', 2, ...
                'IndexOptionArray', {'Index vector (port)', 'Starting index (port)'}, ...
                'OutputSizeArray', {1, 2});
p90 = add_block(p90, 'outport', 'y');
p90 = add_line(add_line(add_line(p90, 'u', 's/1'), 'ligne', 's/2'), 'debut', 's/3');
p90 = add_line(p90, 's', 'y');
[ne90, ~] = matlibre_sl_ports(p90.blocs{4});
assert(ne90 == 3, 'un port d''indices par option (port)');
r90 = sim(p90, regle90{:});
assert(isequal(r90.yout(end, :), M90(3, 2:3)), 'la ligne 3, les colonnes 2 et 3, lues sur leurs ports');
% ce qui est refusé
vu90 = '';
message90 = '';
try
    sim(set_param(p90, 'ligne', 'Value', 7), regle90{:});
catch err
    vu90 = err.identifier;
    message90 = err.message;
end
assert(strcmp(vu90, 'Simulink:Selector:IndexOutOfRange') && ~isempty(strfind(message90, 'ports90/s')), ...
       'un indice lu hors de l''entree arrete la simulation, en nommant le bloc');
refus90 = {
    {'NumberOfDimensions', 1, 'IndexOptionArray', {'Index vector (dialog)'}, ...
     'IndexParamArray', {9}}, 'Simulink:Selector:IndexOutOfRange'
    {'NumberOfDimensions', 1, 'IndexOptionArray', {'Starting and ending indices (port)'}}, ...
        'Simulink:blocks:SelectorVariableSize'
    {'NumberOfDimensions', 3}, 'Simulink:blocks:SelectorDimensions'
    {'NumberOfDimensions', 1, 'IndexOptionArray', {'Choix inconnu'}}, ...
        'Simulink:blocks:SelectorIndexOptions'
    };
for q = 1:size(refus90, 1)
    m90 = new_system('refus90');
    m90 = add_block(m90, 'constant', 'u', 'Value', (1:4)');
    m90 = add_block(m90, 'selector', 's', refus90{q, 1}{:});
    m90 = add_block(m90, 'terminator', 't');
    m90 = add_line(add_line(m90, 'u', 's'), 's', 't');
    vu90 = '';
    message90 = '';
    try
        sim(m90, regle90{:});
    catch err
        vu90 = err.identifier;
        message90 = err.message;
    end
    assert(strcmp(vu90, refus90{q, 2}) && ~isempty(strfind(message90, 'refus90/s')), ...
           sprintf('Selector, refus %d : %s (%s)', q, vu90, message90));
end
% la forme des fichiers de Simulink, une valeur par dimension séparées de
% virgules, se lit ; un .slx écrit les options ainsi, et se relit
f90 = new_system('fichier90');
f90 = add_block(f90, 'constant', 'u', 'Value', M90);
f90 = add_block(f90, 'selector', 's', 'NumberOfDimensions', 2, ...
                'IndexOptions', 'Select all,Index vector (dialog)', 'Indices', '1,[4 1]', ...
                'OutputSizes', '1,1');
f90 = add_block(f90, 'outport', 'y');
f90 = add_line(add_line(f90, 'u', 's'), 's', 'y');
r90 = sim(f90, regle90{:});
assert(isequal(reshape(r90.yout(end, :), 4, 2), M90(:, [4 1])), 'IndexOptions et Indices a virgules');
g90 = new_system('fichier91');
g90 = add_block(g90, 'constant', 'u', 'Value', M90);
g90 = add_block(g90, 'constant', 'i', 'Value', 2);
g90 = add_block(g90, 'selector', 's', 'NumberOfDimensions', 2, ...
                'IndexOptionArray', {'Starting index (port)', 'Index vector (dialog)'}, ...
                'IndexParamArray', {[], [1 3]}, 'OutputSizeArray', {2, []});
g90 = add_block(g90, 'outport', 'y');
g90 = add_line(add_line(add_line(g90, 'u', 's/1'), 'i', 's/2'), 's', 'y');
slx90 = [tempname '.slx'];
save_system(g90, slx90);
h90 = load_system(slx90);
delete(slx90);
parametres90 = h90.blocs{strcmp(cellfun(@(b) b.nom, h90.blocs, 'UniformOutput', false), 's')}.parametres;
assert(strcmp(parametres90.IndexOptionArray, 'Starting index (port),Index vector (dialog)') && ...
       strcmp(parametres90.Indices, '1,[1 3]'), 'le .slx range les options comme Simulink');
r90 = sim(h90, regle90{:});
assert(isequal(reshape(r90.yout(end, :), 2, 2), M90(2:3, [1 3])), 'le Selector relu du .slx');
evalin('base', 'clear sortie90');
fprintf('Selector en entier : ok\n');

%% --------------------------------------------- 91. Le volet Solveur au complet
% Les réglages du volet Solveur de Simulink qui manquaient : la tolérance
% absolue à l'échelle des états, la tolérance en temps des passages par
% zéro de suite, la contrainte des périodes et sa liste imposée ; le
% jacobien, la remise, la préservation de la forme et les réglages de la
% génération de code sont acceptés, rangés, relus d'un .slx.
m91 = new_system('solveur91');
defauts91 = {'AutoScaleAbsTol', 'on'; 'ShapePreserveControl', 'DisableAll'; ...
             'SolverJacobianMethodControl', 'auto'; 'SolverResetMethod', 'Fast'; ...
             'ConsecutiveZCsStepRelTol', '10*128*eps'; ...
             'SampleTimeConstraint', 'Unconstrained'; 'PositivePriorityOrder', 'off'; ...
             'ConcurrentTasks', 'off'};
for q = 1:size(defauts91, 1)
    assert(isequal(get_param(m91, defauts91{q, 1}), defauts91{q, 2}), ...
           sprintf('%s vaut %s par defaut', defauts91{q, 1}, defauts91{q, 2}));
end
assert(isempty(get_param(m91, 'SampleTimeProperty')), 'aucune periode imposee par defaut');
% la casse ne compte pas, une valeur inconnue est refusee en nommant ce qui vaut
assert(strcmp(get_param(set_param(m91, 'solverresetmethod', 'robust'), 'SolverResetMethod'), ...
              'Robust'), 'Robust, quelle que soit la casse');
mauvais91 = {'AutoScaleAbsTol', 'oui'; 'ShapePreserveControl', 'Partiel'; ...
             'SolverJacobianMethodControl', 'Exact'; 'SolverResetMethod', 'Lent'; ...
             'SampleTimeConstraint', 'Libre'; 'SampleTimeProperty', 5; ...
             'PositivePriorityOrder', 2};
for q = 1:size(mauvais91, 1)
    vu91 = '';
    try
        set_param(m91, mauvais91{q, 1}, mauvais91{q, 2});
    catch err
        vu91 = err.identifier;
    end
    assert(strcmp(vu91, 'Simulink:Config:InvalidValue'), ...
           sprintf('%s refuse une valeur inconnue (%s)', mauvais91{q, 1}, vu91));
end

% AutoScaleAbsTol : avec AbsTol 'auto', la tolérance de chaque état suit
% son plus grand module ; sans l'échelle, elle reste fine, et un
% oscillateur d'amplitude 100 demande bien plus de pas
o91 = new_system('oscillateur91');
o91 = add_block(o91, 'integrator', 'v', 'InitialCondition', 0);
o91 = add_block(o91, 'integrator', 'x', 'InitialCondition', 100);
o91 = add_block(o91, 'gain', 'g', 'Gain', -1);
o91 = add_block(o91, 'outport', 'y');
o91 = add_line(add_line(add_line(add_line(o91, 'v', 'x'), 'x', 'g'), 'g', 'v'), 'x', 'y');
regle91 = {'Solver', 'ode45', 'StopTime', 20, 'MaxStep', 10, 'RelTol', 1e-5};
avec91 = sim(o91, regle91{:});
sans91 = sim(o91, regle91{:}, 'AutoScaleAbsTol', 'off');
assert(numel(sans91.tout) > numel(avec91.tout), ...
       sprintf('sans l''echelle, plus de pas (%d contre %d)', numel(sans91.tout), ...
               numel(avec91.tout)));
assert(max(abs(sans91.yout - 100 * cos(sans91.tout))) < 0.01 && ...
       max(abs(avec91.yout - 100 * cos(avec91.tout))) < 0.02, 'les deux suivent 100 cos t');
% une tolérance absolue donnée ne suit pas l'échelle
donnee91 = sim(o91, regle91{:}, 'AbsTol', 1e-4);
donneeSans91 = sim(o91, regle91{:}, 'AbsTol', 1e-4, 'AutoScaleAbsTol', 'off');
assert(isequal(donnee91.tout, donneeSans91.tout), 'AbsTol donnee : l''echelle n''y change rien');

% ConsecutiveZCsStepRelTol : des passages par zéro espacés de pi/1000 ne se
% suivent pas pour la tolérance par défaut ; avec 1e-2, ils se suivent
% dès que l'instant dépasse 0,32, et le sixième arrête la simulation
z91 = new_system('passages91');
z91 = add_block(z91, 'sine', 'u', 'Frequency', 1000);
z91 = add_block(z91, 'sign', 's');
z91 = add_block(z91, 'outport', 'y');
z91 = add_line(add_line(z91, 'u', 's'), 's', 'y');
regle91 = {'Solver', 'ode45', 'StopTime', 1, 'MaxConsecutiveZCs', 5};
r91 = sim(z91, regle91{:});
assert(abs(r91.tout(end) - 1) < 1e-12, 'la tolerance par defaut : la simulation va a son terme');
vu91 = '';
message91 = '';
try
    sim(z91, regle91{:}, 'ConsecutiveZCsStepRelTol', 1e-2);
catch err
    vu91 = err.identifier;
    message91 = err.message;
end
assert(strcmp(vu91, 'Simulink:Engine:SolverConsecutiveZCNum') && ...
       ~isempty(strfind(message91, '5 consecutive zero crossings')), ...
       'une tolerance en temps large : les passages se suivent, le diagnostic tombe');
vu91 = '';
try
    sim(z91, regle91{:}, 'ConsecutiveZCsStepRelTol', -1);
catch err
    vu91 = err.identifier;
end
assert(strcmp(vu91, 'Simulink:Config:InvalidValue'), 'une tolerance negative est refusee');

% SampleTimeConstraint 'STIndependent' : le modèle hérite ses périodes
s91 = new_system('independant91');
s91 = add_block(s91, 'constant', 'c', 'Value', 2);
s91 = add_block(s91, 'gain', 'g', 'Gain', 3);
s91 = add_block(s91, 'outport', 'y');
s91 = add_line(add_line(s91, 'c', 'g'), 'g', 'y');
s91 = set_param(s91, 'Solver', 'FixedStepDiscrete', 'FixedStep', 'auto', ...
                'SampleTimeConstraint', 'STIndependent', 'StopTime', 1);
r91 = sim(s91);
assert(all(r91.yout == 6), 'des periodes heritees : le modele se simule');
refus91 = {};
try
    sim(s91, 'FixedStep', 0.1);
catch err
    refus91{end + 1} = err.identifier;
end
d91 = add_block(s91, 'unitdelay', 'd', 'SampleTime', 0.1);
d91 = add_block(d91, 'outport', 'y2');
d91 = add_line(add_line(d91, 'g', 'd'), 'd', 'y2');
message91 = '';
try
    sim(d91);
catch err
    refus91{end + 1} = err.identifier;
    message91 = err.message;
end
assert(isequal(refus91, {'Simulink:SampleTime:STIndependentFixedStep', ...
                         'Simulink:SampleTime:STIndependentExplicitTs'}) && ...
       ~isempty(strfind(message91, 'independant91/d')), ...
       'STIndependent : un pas fixe donne, un bloc a periode propre, refuses');
r91 = sim(set_param(d91, 'd', 'SampleTime', -1));
assert(numel(r91.tout) == 51, 'le Unit Delay a periode -1 herite : accepte');
% a pas variable, la contrainte ne vaut pas
r91 = sim(d91, 'Solver', 'VariableStepDiscrete');
assert(abs(r91.yout(end, 2) - 6) < 1e-12, 'a pas variable, la contrainte ne vaut pas');

% SampleTimeConstraint 'Specified' : les périodes du modèle sont celles de
% la liste, et le pas 'auto' leur plus grand commun diviseur
p91 = new_system('imposees91');
p91 = add_block(p91, 'constant', 'c', 'Value', 1);
p91 = add_block(p91, 'unitdelay', 'lent', 'SampleTime', 0.2);
p91 = add_block(p91, 'outport', 'y');
p91 = add_line(add_line(p91, 'c', 'lent'), 'lent', 'y');
p91 = set_param(p91, 'Solver', 'FixedStepDiscrete', 'FixedStep', 'auto', 'StopTime', 1);
r91 = sim(p91);
assert(abs(r91.tout(2) - 0.2) < 1e-12, 'sans contrainte, le pas fondamental est 0,2');
liste91 = struct('SamplePeriod', {0.05, 0.2}, 'Offset', {0, 0}, 'Priority', {40, 41});
q91 = set_param(p91, 'SampleTimeConstraint', 'Specified', 'SampleTimeProperty', liste91);
r91 = sim(q91);
assert(abs(r91.tout(2) - 0.05) < 1e-12 && abs(r91.yout(end) - 1) < 1e-12, ...
       'Specified : le pas est le plus grand commun diviseur des periodes imposees');
r91 = sim(set_param(q91, 'SampleTimeProperty', ...
                    'struct(''SamplePeriod'', {0.05, 0.2}, ''Offset'', {0, 0})'));
assert(abs(r91.tout(2) - 0.05) < 1e-12, 'la liste donnee par son expression');
refus91 = {};
messages91 = {};
cas91 = {set_param(add_block(q91, 'unitdelay', 'autre', 'SampleTime', 0.3), 'StopTime', 1), ...
         set_param(p91, 'SampleTimeConstraint', 'Specified'), ...
         set_param(q91, 'SampleTimeProperty', struct('SamplePeriod', {0.2, 0.05})), ...
         set_param(q91, 'SampleTimeProperty', struct('SamplePeriod', {0.05, 0.2}, ...
                                                     'Offset', {0, 0.3}))};
for q = 1:numel(cas91)
    try
        sim(cas91{q});
        refus91{end + 1} = ''; %#ok<AGROW>
    catch err
        refus91{end + 1} = err.identifier; %#ok<AGROW>
        messages91{end + 1} = err.message; %#ok<AGROW>
    end
end
assert(isequal(refus91, {'Simulink:SampleTime:NotInSampleTimeProperty', ...
                         'Simulink:SampleTime:InvalidSampleTimeProperty', ...
                         'Simulink:SampleTime:InvalidSampleTimeProperty', ...
                         'Simulink:SampleTime:InvalidSampleTimeProperty'}) && ...
       ~isempty(strfind(messages91{1}, 'imposees91/autre')), ...
       sprintf('Specified : une periode absente, une liste vide, desordonnee ou fausse (%s)', ...
               strjoin(refus91, ', ')));

% le jacobien, la remise, la forme et la génération de code ne changent pas
% ce que calcule un solveur implicite
k91 = new_system('raide91');
k91 = add_block(k91, 'integrator', 'x', 'InitialCondition', 1);
k91 = add_block(k91, 'gain', 'g', 'Gain', -1000);
k91 = add_block(k91, 'outport', 'y');
k91 = add_line(add_line(add_line(k91, 'x', 'g'), 'g', 'x'), 'x', 'y');
base91 = sim(k91, 'Solver', 'ode15s', 'StopTime', 0.1);
autre91 = sim(k91, 'Solver', 'ode15s', 'StopTime', 0.1, ...
              'SolverJacobianMethodControl', 'FullAnalytical', 'SolverResetMethod', 'Robust', ...
              'ShapePreserveControl', 'EnableAll', 'PositivePriorityOrder', 'on', ...
              'ConcurrentTasks', 'on');
assert(isequal(base91.tout, autre91.tout) && isequal(base91.yout, autre91.yout), ...
       'jacobien, remise, forme et generation de code : les memes pas, les memes valeurs');

% un .slx range ces réglages, et les relit
e91 = set_param(p91, 'SampleTimeConstraint', 'Specified', 'SampleTimeProperty', liste91, ...
                'AutoScaleAbsTol', 'off', 'ShapePreserveControl', 'EnableAll', ...
                'SolverJacobianMethodControl', 'SparsePerturbation', ...
                'ConsecutiveZCsStepRelTol', 1e-9);
slx91 = [tempname '.slx'];
save_system(e91, slx91);
f91 = load_system(slx91);
delete(slx91);
assert(strcmp(get_param(f91, 'SampleTimeConstraint'), 'Specified') && ...
       strcmp(get_param(f91, 'AutoScaleAbsTol'), 'off') && ...
       strcmp(get_param(f91, 'ShapePreserveControl'), 'EnableAll') && ...
       strcmp(get_param(f91, 'SolverJacobianMethodControl'), 'SparsePerturbation') && ...
       isequal(get_param(f91, 'ConsecutiveZCsStepRelTol'), 1e-9), 'le .slx relit les reglages');
relue91 = evalin('base', get_param(f91, 'SampleTimeProperty'));
assert(isequal([relue91.SamplePeriod], [0.05 0.2]) && isequal([relue91.Priority], [40 41]), ...
       'la liste des periodes imposees, relue du .slx');
r91 = sim(f91);
assert(abs(r91.tout(2) - 0.05) < 1e-12, 'le modele relu se simule sous sa contrainte');
fprintf('volet Solveur au complet : ok\n');

%% ------------------------------------------- 92. Les références de sous-système
% Un fichier de sous-système — NEW_SYSTEM(NOM, 'Subsystem') — ne se simule
% pas seul : des blocs Subsystem Reference le désignent par son nom
% (ReferencedSubsystem), et la compilation le déroule à leur place, chaque
% instance avec ses états. Il se relit à chaque simulation, s'écrit et se
% relit en .slx et en .m ; ce qui n'en est pas un est refusé en nommant le
% bloc.
double92 = new_system('double92', 'Subsystem');
double92 = add_block(double92, 'inport', 'u');
double92 = add_block(double92, 'gain', 'g', 'Gain', 2);
double92 = add_block(double92, 'integrator', 'x', 'InitialCondition', 0);
double92 = add_block(double92, 'outport', 'y');
double92 = add_block(double92, 'outport', 'somme');
double92 = add_line(add_line(add_line(double92, 'u', 'g'), 'g', 'y'), 'g', 'x');
double92 = add_line(double92, 'x', 'somme');
assert(strcmp(get_param(double92, 'BlockDiagramType'), 'subsystem'), ...
       'NEW_SYSTEM(NOM, ''Subsystem'') : un fichier de sous-systeme');
vu92 = '';
try
    sim(double92);
catch err
    vu92 = err.identifier;
end
assert(strcmp(vu92, 'Simulink:SubsystemReference:CannotSimulateSubsystemFile'), ...
       'un fichier de sous-systeme ne se simule pas seul');
% deux instances, chacune ses états
m92 = new_system('reference92');
m92 = add_block(m92, 'constant', 'a', 'Value', 3);
m92 = add_block(m92, 'constant', 'b', 'Value', -1);
m92 = add_block(m92, 'subsystemreference', 'r1', 'ReferencedSubsystem', 'double92');
m92 = add_block(m92, 'subsystemreference', 'r2', 'ReferencedSubsystem', 'double92');
for q = 1:4
    m92 = add_block(m92, 'outport', sprintf('y%d', q));
end
m92 = add_line(add_line(m92, 'a', 'r1'), 'b', 'r2');
m92 = add_line(add_line(m92, 'r1/1', 'y1'), 'r1/2', 'y2');
m92 = add_line(add_line(m92, 'r2/1', 'y3'), 'r2/2', 'y4');
[ne92, ns92] = matlibre_sl_ports(m92.blocs{3});
assert(ne92 == 1 && ns92 == 2, 'les ports d''une reference : ceux du fichier');
regle92 = {'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 1};
r92 = sim(m92, regle92{:});
assert(max(abs(r92.yout(end, :) - [6 6 -2 -2])) < 1e-9, ...
       'deux instances, deux entrees, deux integrateurs');
% le fichier change : la référence suit
double92 = set_param(double92, 'g', 'Gain', 5);
r92 = sim(m92, regle92{:});
assert(max(abs(r92.yout(end, :) - [15 15 -5 -5])) < 1e-9, 'relu a chaque simulation');
% ce qui est refusé, en nommant le bloc
modele92 = new_system('modele92');
modele92 = add_block(modele92, 'inport', 'u');
modele92 = add_block(modele92, 'outport', 'y');
modele92 = add_line(modele92, 'u', 'y');
refus92 = {'', 'Simulink:SubsystemReference:EmptyReference'; ...
           'inexistant92', 'Simulink:SubsystemReference:SubsystemNotFound'; ...
           'modele92', 'Simulink:SubsystemReference:NotASubsystemFile'};
for q = 1:size(refus92, 1)
    f92 = new_system('refus92');
    f92 = add_block(f92, 'subsystemreference', 'r', 'ReferencedSubsystem', refus92{q, 1});
    vu92 = '';
    message92 = '';
    try
        sim(f92, regle92{:});
    catch err
        vu92 = err.identifier;
        message92 = err.message;
    end
    assert(strcmp(vu92, refus92{q, 2}) && ~isempty(strfind(message92, 'refus92/r')), ...
           sprintf('reference ''%s'' : %s (%s)', refus92{q, 1}, vu92, message92));
end
f92 = new_system('refus92');
f92 = add_block(f92, 'constant', 'c', 'Value', 1);
f92 = add_block(f92, 'modelreference', 'm', 'ModelName', 'double92');
f92 = add_block(f92, 'terminator', 't1');
f92 = add_block(f92, 'terminator', 't2');
f92 = add_line(add_line(add_line(f92, 'c', 'm'), 'm/1', 't1'), 'm/2', 't2');
vu92 = '';
try
    sim(f92, regle92{:});
catch err
    vu92 = err.identifier;
end
assert(strcmp(vu92, 'Simulink:modelReference:SubsystemFileReferenced'), ...
       'un bloc Model ne reference pas un fichier de sous-systeme');
vu92 = '';
try
    new_system('autre92', 'Autre');
catch err
    vu92 = err.message;
end
assert(~isempty(strfind(vu92, 'Subsystem')), 'NEW_SYSTEM dit les trois types');
% le fichier et le modèle s'écrivent et se relisent : .slx et .m
dossier92 = tempname();
mkdir(dossier92);
avant92 = pwd();
cd(dossier92);
save_system(double92, fullfile(dossier92, 'double92.slx'));
relu92 = load_system(fullfile(dossier92, 'double92.slx'));
assert(strcmp(get_param(relu92, 'BlockDiagramType'), 'subsystem'), ...
       'le .slx garde le genre du diagramme');
save_system(m92, fullfile(dossier92, 'reference92.slx'));
clear double92
mr92 = load_system(fullfile(dossier92, 'reference92.slx'));
types92 = cellfun(@(b) b.type, mr92.blocs, 'UniformOutput', false);
assert(sum(strcmp(types92, 'subsystemreference')) == 2, 'les Subsystem Reference relus du .slx');
r92 = sim(mr92, regle92{:});
assert(max(abs(r92.yout(end, :) - [15 15 -5 -5])) < 1e-9, ...
       'le modele relu deroule le fichier de sous-systeme relu du dossier');
delete(fullfile(dossier92, 'double92.slx'));
save_system(relu92, fullfile(dossier92, 'double92.m'));
r92 = sim(mr92, regle92{:});
assert(max(abs(r92.yout(end, :) - [15 15 -5 -5])) < 1e-9, 'le fichier de sous-systeme en .m');
cd(avant92);
rmdir(dossier92, 's');
fprintf('references de sous-systeme : ok\n');

%% ------------------------------------------ 93. Batterie des réglages du modèle
% Chaque réglage du modèle, mis à une valeur qu'on pourrait taper par
% erreur, est refusé par SET_PARAM ou par SIM d'une erreur de Simulink, ou
% accepté et simulé : jamais une erreur interne. Puis chaque solveur, sur
% des modèles dont on connaît la solution — linéaire, raide, passage par
% zéro, multicadence, boucle algébrique —, croisé avec les options des
% passages par zéro, de la tolérance et des instants de sortie : il
% rend la solution, ou il est refusé en nommant ce qui l'empêche.
b93 = new_system('reglages93');
b93 = add_block(b93, 'sine', 'u');
b93 = add_block(b93, 'integrator', 'x');
b93 = add_block(b93, 'unitdelay', 'd', 'SampleTime', 0.1);
b93 = add_block(b93, 'outport', 'y1');
b93 = add_block(b93, 'outport', 'y2');
b93 = add_line(add_line(add_line(b93, 'u', 'x'), 'x', 'y1'), 'u', 'd');
b93 = add_line(b93, 'd', 'y2');
b93 = set_param(b93, 'StopTime', 0.5);
noms93 = fieldnames(matlibre_sl_config('defauts'));
fautes93 = {'variableInexistante', NaN, [], [1 2; 3 4], -1, 1 + 2i, 'texte (', {}, ...
            struct('a', 1), Inf};
nSimules93 = 0;
nRefuses93 = 0;
for kN = 1:numel(noms93)
    for kF = 1:numel(fautes93)
        contexte93 = sprintf('%s = %s', noms93{kN}, strtrim(evalc('disp(fautes93{kF})')));
        try
            m93 = set_param(b93, noms93{kN}, fautes93{kF});
        catch err
            assert(strncmp(err.identifier, 'Simulink:', 9), ...
                   sprintf('%s : SET_PARAM, erreur interne %s : %s', contexte93, ...
                           err.identifier, err.message));
            nRefuses93 = nRefuses93 + 1;
            continue
        end
        if strcmp(noms93{kN}, 'StopTime') && isequal(fautes93{kF}, Inf)
            nRefuses93 = nRefuses93 + 1;   % sans fin, et sans Stop Simulation
            continue
        end
        try
            evalc('sim(m93);');
            nSimules93 = nSimules93 + 1;
        catch err
            assert(strncmp(err.identifier, 'Simulink:', 9) && ...
                   (~isempty(strfind(err.message, 'reglages93')) || ...
                    ~isempty(strfind(err.message, noms93{kN}))), ...
                   sprintf('%s : SIM, erreur interne ou anonyme %s : %s', contexte93, ...
                           err.identifier, err.message));
            nRefuses93 = nRefuses93 + 1;
        end
    end
end
fprintf('batterie des reglages, valeurs fautives : %d simulations, %d refus nommes\n', ...
        nSimules93, nRefuses93);

% Les modèles de référence, et leur solution à l'instant final.
modeles93 = cell(1, 5);
attendus93 = zeros(1, 5);
fins93 = [2 2 5 2 2];
% x' = 1 - 2x
m93 = new_system('lineaire93');
m93 = add_block(m93, 'constant', 'c', 'Value', 1);
m93 = add_block(m93, 'sum', 's', 'Inputs', '+-');
m93 = add_block(m93, 'gain', 'g', 'Gain', 2);
m93 = add_block(m93, 'integrator', 'x');
m93 = add_block(m93, 'outport', 'y');
m93 = add_line(add_line(add_line(m93, 'c', 's/1'), 's', 'x'), 'x', 'g');
m93 = add_line(add_line(m93, 'g', 's/2'), 'x', 'y');
modeles93{1} = m93;
attendus93(1) = 0.5 * (1 - exp(-4));
% raide : x' = 1000 (cos t - x)
m93 = new_system('raide93');
m93 = add_block(m93, 'clock', 't');
m93 = add_block(m93, 'trigonometry', 'cos', 'Operator', 'cos');
m93 = add_block(m93, 'sum', 's', 'Inputs', '+-');
m93 = add_block(m93, 'gain', 'g', 'Gain', 1000);
m93 = add_block(m93, 'integrator', 'x', 'InitialCondition', 1);
m93 = add_block(m93, 'outport', 'y');
m93 = add_line(add_line(add_line(m93, 't', 'cos'), 'cos', 's/1'), 's', 'g');
m93 = add_line(add_line(add_line(m93, 'g', 'x'), 'x', 's/2'), 'x', 'y');
modeles93{2} = m93;
attendus93(2) = (1e6 * cos(2) + 1e3 * sin(2)) / (1e6 + 1);
% passage par zéro : l'intégrale de |sin t|, qui se coude en pi
m93 = new_system('coude93');
m93 = add_block(m93, 'sine', 'u');
m93 = add_block(m93, 'abs', 'a');
m93 = add_block(m93, 'integrator', 'x');
m93 = add_block(m93, 'outport', 'y');
m93 = add_line(add_line(add_line(m93, 'u', 'a'), 'a', 'x'), 'x', 'y');
modeles93{3} = m93;
attendus93(3) = 3 + cos(5);
% multicadence : x = t, tenu tous les 0,25 s, et un retard à 0,1 s
m93 = new_system('cadences93');
m93 = add_block(m93, 'constant', 'c', 'Value', 1);
m93 = add_block(m93, 'integrator', 'x');
m93 = add_block(m93, 'zoh', 'h', 'SampleTime', 0.25);
m93 = add_block(m93, 'unitdelay', 'd', 'SampleTime', 0.1);
m93 = add_block(m93, 'sum', 's', 'Inputs', '++');
m93 = add_block(m93, 'outport', 'y');
m93 = add_line(add_line(add_line(m93, 'c', 'x'), 'x', 'h'), 'c', 'd');
m93 = add_line(add_line(add_line(m93, 'h', 's/1'), 'd', 's/2'), 's', 'y');
modeles93{4} = m93;
attendus93(4) = 3;
% boucle algébrique : y = x - y/2, x = t
m93 = new_system('boucle93');
m93 = add_block(m93, 'constant', 'c', 'Value', 1);
m93 = add_block(m93, 'integrator', 'x');
m93 = add_block(m93, 'sum', 's', 'Inputs', '+-');
m93 = add_block(m93, 'gain', 'g', 'Gain', 0.5);
m93 = add_block(m93, 'outport', 'y');
m93 = add_line(add_line(add_line(m93, 'c', 'x'), 'x', 's/1'), 's', 'g');
m93 = add_line(add_line(m93, 'g', 's/2'), 's', 'y');
modeles93{5} = m93;
attendus93(5) = 2 / 1.5;

solveurs93 = matlibre_sl_config('solveurs');
liste93 = [solveurs93.fixe, solveurs93.variable];
zc93 = {'UseLocalSettings', 'EnableAll', 'DisableAll'};
algo93 = {'Nonadaptive', 'Adaptive'};
echelle93 = {'on', 'off'};
sorties93 = {{'OutputOption', 'RefineOutputTimes', 'Refine', 1}, ...
             {'OutputOption', 'RefineOutputTimes', 'Refine', 3}, ...
             {'OutputOption', 'AdditionalOutputTimes', 'OutputTimes', '[0.5 1 1.5]'}, ...
             {'OutputOption', 'SpecifiedOutputTimes', 'OutputTimes', '[0.5 1 1.5]'}};
nSimules93 = 0;
nRefuses93 = 0;
for kS = 1:numel(liste93)
    solveur93 = liste93{kS};
    variable93 = any(strcmp(solveur93, solveurs93.variable));
    for kM = 1:numel(modeles93)
        k93 = kS + kM;
        regle93 = {'Solver', solveur93, 'StopTime', fins93(kM), ...
                   'ZeroCrossControl', zc93{1 + mod(k93, 3)}, ...
                   'ZeroCrossAlgorithm', algo93{1 + mod(k93, 2)}, ...
                   'AutoScaleAbsTol', echelle93{1 + mod(floor(k93 / 2), 2)}};
        if variable93
            regle93 = [regle93, {'RelTol', 1e-5, 'MaxStep', 0.05}, ...
                       sorties93{1 + mod(k93, 4)}]; %#ok<AGROW>
        else
            regle93 = [regle93, {'FixedStep', 2e-3}]; %#ok<AGROW>
        end
        contexte93 = sprintf('%s sous %s', modeles93{kM}.nom, strjoin(cellfun(@(v) ...
                             strtrim(evalc('disp(v)')), regle93, 'UniformOutput', false), ' '));
        try
            evalc('r93 = sim(modeles93{kM}, regle93{:});');
        catch err
            discret93 = any(strcmp(solveur93, {'FixedStepDiscrete', 'VariableStepDiscrete'}));
            assert(discret93 && strcmp(err.identifier, ...
                                       'Simulink:Engine:DiscreteSolverContinuousStates'), ...
                   sprintf('%s : %s (%s)', contexte93, err.identifier, err.message));
            nRefuses93 = nRefuses93 + 1;
            continue
        end
        assert(abs(r93.tout(end) - fins93(kM)) < 1e-9 && all(isfinite(r93.yout(:))), ...
               sprintf('%s : la simulation s''arrete a %g', contexte93, r93.tout(end)));
        ecart93 = abs(r93.yout(end, 1) - attendus93(kM));
        tolerance93 = 2e-2 * max(1, abs(attendus93(kM)));
        assert(ecart93 < tolerance93, sprintf('%s : %g au lieu de %g', contexte93, ...
                                             r93.yout(end, 1), attendus93(kM)));
        if variable93 && strcmp(regle93{end - 2}, 'SpecifiedOutputTimes')
            assert(isequal(r93.tout(:).', [0 0.5 1 1.5 fins93(kM)]), ...
                   sprintf('%s : les instants demandes seuls', contexte93));
        end
        nSimules93 = nSimules93 + 1;
    end
end
fprintf('batterie des solveurs croises : %d simulations, %d refus nommes\n', ...
        nSimules93, nRefuses93);

%% ------------------------------------- 94. Batterie des allers-retours en fichier
% Chaque type de bloc du catalogue, seul, réglé par défaut puis sur un
% autre de ses choix : écrit en .slx et relu, écrit en programme .m et
% rebâti, il doit se simuler exactement comme avant — ou être refusé de
% la même erreur. Un paramètre qu'un fichier perdrait, ou relirait
% autrement, se voit ainsi.
dossier94 = tempname();
mkdir(dossier94);
avant94 = pwd();
cd(dossier94);
catalogue94 = matlibre_sl_catalogue();
types94 = {};
for kT = 1:numel(catalogue94)
    if ~strcmp(catalogue94(kT).famille, 'Interne')
        types94{end + 1} = catalogue94(kT).type; %#ok<SAGROW>
    end
end
regle94 = {'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 0.5};
nCompares94 = 0;
echecs94 = {};
for kT = 1:numel(types94)
    entree94 = matlibre_sl_catalogue('type', types94{kT});
    for variante94 = 1:2
        decrit94 = types94{kT};
        reglage94 = {};
        if variante94 == 2
            % chaque choix à sa deuxième valeur
            for q = 1:size(entree94.params, 1)
                nature94 = entree94.params{q, 3};
                if iscell(nature94) && numel(nature94) >= 2
                    reglage94 = [reglage94, entree94.params(q, 1), nature94(2)]; %#ok<AGROW>
                end
            end
            if isempty(reglage94)
                continue
            end
            decrit94 = [types94{kT} ' (choix seconds)'];
        end
        try
            [s94, ok94] = allerModele(types94{kT}, reglage94, 0.5);
        catch
            continue   % un réglage que le bloc refuse : la batterie des paramètres en répond
        end
        if ~ok94
            continue
        end
        [y94, id94] = allerSimuler(s94, regle94);
        if any(strcmp(id94, {'refus', 'Simulink:Commands:SousSystemeVide'}))
            % un sous-système sans modèle : MatLibre le refuse, un fichier le
            % relit vide, ce que Simulink simule
            continue
        end
        for format94 = {'.slx', '.m'}
            fichier94 = fullfile(dossier94, ['aller94' format94{1}]);
            try
                save_system(s94, fichier94);
                if strcmp(format94{1}, '.slx')
                    r94 = load_system(fichier94);
                else
                    clear aller94
                    r94 = feval('aller94');
                end
                delete(fichier94);
            catch err
                echecs94{end + 1} = sprintf('%s %s : ecriture ou relecture : %s %s', ...
                                            decrit94, format94{1}, err.identifier, err.message); %#ok<SAGROW>
                if exist(fichier94, 'file')
                    delete(fichier94);
                end
                continue
            end
            [z94, idr94] = allerSimuler(r94, regle94);
            if ~strcmp(id94, idr94) || (strcmp(id94, 'ok') && ...
                                        ~(isequal(size(y94), size(z94)) && ...
                                          all(y94(:) == z94(:) | abs(y94(:) - z94(:)) <= 1e-9 | ...
                                              (isnan(y94(:)) & isnan(z94(:))))))
                echecs94{end + 1} = sprintf('%s %s : %s puis %s', decrit94, format94{1}, ...
                                            id94, idr94); %#ok<SAGROW>
            end
            nCompares94 = nCompares94 + 1;
        end
    end
end
cd(avant94);
rmdir(dossier94, 's');
assert(isempty(echecs94), sprintf('allers-retours en fichier : %s', strjoin(echecs94, ' ; ')));
fprintf('allers-retours en fichier : %d comparaisons, sans ecart\n', nCompares94);
%% ----------------------------------- 95. Batterie : get_param puis set_param
% Ce que GET_PARAM rend d'un paramètre se repose par SET_PARAM tel quel —
% c'est ainsi qu'un script copie le réglage d'un bloc sur un autre — et
% le modèle se simule exactement comme avant. Chaque paramètre de chaque
% type de bloc du catalogue, et chaque réglage du modèle.
catalogue95 = matlibre_sl_catalogue();
regle95 = {'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 0.5};
nReposes95 = 0;
echecs95 = {};
for kT = 1:numel(catalogue95)
    entree95 = catalogue95(kT);
    if strcmp(entree95.famille, 'Interne')
        continue
    end
    try
        [s95, ok95] = allerModele(entree95.type, {}, 0.5);
    catch
        continue
    end
    if ~ok95
        continue
    end
    [y95, id95] = allerSimuler(s95, regle95);
    for q = 1:size(entree95.params, 1)
        nom95 = entree95.params{q, 1};
        contexte95 = sprintf('%s.%s', entree95.type, nom95);
        try
            v95 = get_param(s95, 'b1', nom95);
        catch err
            echecs95{end + 1} = sprintf('%s : GET_PARAM %s', contexte95, err.identifier); %#ok<SAGROW>
            continue
        end
        try
            t95 = set_param(s95, 'b1', nom95, v95);
        catch err
            echecs95{end + 1} = sprintf('%s : SET_PARAM de ce que GET_PARAM rend %s : %s', ...
                                        contexte95, err.identifier, err.message); %#ok<SAGROW>
            continue
        end
        [z95, idr95] = allerSimuler(t95, regle95);
        if ~strcmp(id95, idr95) || (strcmp(id95, 'ok') && ...
                                    ~(isequal(size(y95), size(z95)) && ...
                                      all(y95(:) == z95(:) | abs(y95(:) - z95(:)) <= 1e-12 | ...
                                          (isnan(y95(:)) & isnan(z95(:))))))
            echecs95{end + 1} = sprintf('%s : %s puis %s', contexte95, id95, idr95); %#ok<SAGROW>
        end
        nReposes95 = nReposes95 + 1;
    end
end
% les réglages du modèle
m95 = new_system('reglages95');
for nom95 = fieldnames(matlibre_sl_config('defauts')).'
    try
        v95 = get_param(m95, nom95{1});
        m95 = set_param(m95, nom95{1}, v95);
        nReposes95 = nReposes95 + 1;
    catch err
        echecs95{end + 1} = sprintf('reglage %s : %s : %s', nom95{1}, err.identifier, ...
                                    err.message); %#ok<SAGROW>
    end
end
assert(isempty(echecs95), sprintf('get_param puis set_param : %s', strjoin(echecs95, ' ; ')));
fprintf('get_param puis set_param : %d parametres et reglages reposes, sans ecart\n', nReposes95);

%% ------------------------------- 96. Modèles référencés : espace de travail, arguments
% Les blocs d'un modèle référencé ne voient que son espace de travail —
% non celui du modèle qui le référence —, puis l'espace de base. Ses
% arguments (ParameterArgumentNames), des variables de cet espace,
% prennent la valeur que chaque bloc Model leur donne
% (ParameterArgumentValues, InstanceParameters), évaluée là où le bloc
% se trouve ; sans valeur, celle de l'espace du modèle référencé.
enfant96 = new_system('enfant96');
enfant96 = add_block(enfant96, 'inport', 'u');
enfant96 = add_block(enfant96, 'gain', 'g', 'Gain', 'K');
enfant96 = add_block(enfant96, 'outport', 'y');
enfant96 = add_line(add_line(enfant96, 'u', 'g'), 'g', 'y');
assignin(get_param(enfant96, 'ModelWorkspace'), 'K', 7);
parent96 = new_system('parent96');
parent96 = add_block(parent96, 'constant', 'c', 'Value', 2);
parent96 = add_block(parent96, 'modelreference', 'm', 'ModelName', 'enfant96');
parent96 = add_block(parent96, 'outport', 'y');
parent96 = add_line(add_line(parent96, 'c', 'm'), 'm', 'y');
K = 3; %#ok<NASGU>
assignin(get_param(parent96, 'ModelWorkspace'), 'K', 5);
r96 = sim(parent96, 'StopTime', 0.1);
assert(r96.yout(end) == 14, 'le modele reference lit son K (7), non celui du parent ni de base');
clear K
% une variable du seul espace du parent ne se voit pas dans l'enfant
enfant96 = set_param(enfant96, 'g', 'Gain', 'Q');
assignin(get_param(parent96, 'ModelWorkspace'), 'Q', 4);
vu96 = '';
message96 = '';
try
    sim(parent96, 'StopTime', 0.1);
catch err
    vu96 = err.identifier;
    message96 = err.message;
end
assert(strcmp(vu96, 'Simulink:Commands:ParametreNonEvalue') && ...
       ~isempty(strfind(message96, 'parent96/m/g')), ...
       'l''espace du parent ne fuit pas dans le modele reference');
enfant96 = set_param(enfant96, 'g', 'Gain', 'K');
% les arguments : trois blocs Model, trois valeurs
enfant96 = set_param(enfant96, 'ParameterArgumentNames', 'K');
assert(strcmp(get_param(enfant96, 'ParameterArgumentNames'), 'K'), 'les arguments du modele');
assignin(get_param(parent96, 'ModelWorkspace'), 'J96', 4);
parent96 = add_block(parent96, 'modelreference', 'm2', 'ModelName', 'enfant96', ...
                     'ParameterArgumentValues', struct('K', '5'));
parent96 = add_block(parent96, 'modelreference', 'm3', 'ModelName', 'enfant96', ...
                     'InstanceParameters', struct('Name', 'K', 'Value', '2*J96'));
parent96 = add_block(parent96, 'outport', 'y2');
parent96 = add_block(parent96, 'outport', 'y3');
parent96 = add_line(add_line(parent96, 'c', 'm2'), 'm2', 'y2');
parent96 = add_line(add_line(parent96, 'c', 'm3'), 'm3', 'y3');
r96 = sim(parent96, 'StopTime', 0.1);
assert(isequal(r96.yout(end, :), [14 10 16]), ...
       'sans valeur, 7 ; ParameterArgumentValues 5 ; InstanceParameters 2*J96 du parent, 8');
% ce qui est refusé
refus96 = {set_param(parent96, 'm2', 'ParameterArgumentValues', struct('Z', '1')), ...
           'Simulink:modelReference:NotAnArgument', 'parent96/m2'};
enfantFaux96 = set_param(enfant96, 'ParameterArgumentNames', 'K, absent');
vu96 = '';
try
    set_param(enfant96, 'ParameterArgumentNames', '1x');
catch err
    vu96 = err.identifier;
end
assert(strcmp(vu96, 'Simulink:Config:InvalidValue'), 'un argument se nomme comme une variable');
vu96 = '';
message96 = '';
try
    sim(refus96{1}, 'StopTime', 0.1);
catch err
    vu96 = err.identifier;
    message96 = err.message;
end
assert(strcmp(vu96, refus96{2}) && ~isempty(strfind(message96, refus96{3})), ...
       sprintf('un argument inconnu : %s (%s)', vu96, message96));
gardeEnfant96 = enfant96;
enfant96 = enfantFaux96;
vu96 = '';
try
    sim(parent96, 'StopTime', 0.1);
catch err
    vu96 = err.identifier;
end
assert(strcmp(vu96, 'Simulink:modelReference:ArgumentNotInWorkspace'), ...
       'un argument qui n''est pas dans l''espace du modele reference');
enfant96 = gardeEnfant96;
% .slx et .m gardent les arguments
dossier96 = tempname();
mkdir(dossier96);
avant96 = pwd();
cd(dossier96);
save_system(parent96, fullfile(dossier96, 'rebati96.m'));
clear rebati96
q96 = feval('rebati96');
r96 = sim(q96, 'StopTime', 0.1);
assert(isequal(r96.yout(end, :), [14 10 16]), 'les arguments rebatis du .m');
save_system(parent96, fullfile(dossier96, 'parent96.slx'));
p96 = load_system(fullfile(dossier96, 'parent96.slx'));
r96 = sim(p96, 'StopTime', 0.1);
assert(isequal(r96.yout(end, :), [14 10 16]), 'les arguments relus du .slx, l''espace du parent compris');
% une cellule mêlée s'écrit aussi en .m : les indices d'un Selector
g96 = new_system('selecteur96');
g96 = add_block(g96, 'constant', 'u', 'Value', magic(4));
g96 = add_block(g96, 'selector', 's', 'NumberOfDimensions', 2, ...
                'IndexOptionArray', {'Select all', 'Index vector (dialog)'}, ...
                'IndexParamArray', {[], [4 1]});
g96 = add_block(g96, 'outport', 'y');
g96 = add_line(add_line(g96, 'u', 's'), 's', 'y');
save_system(g96, fullfile(dossier96, 'selecteur96.m'));
clear selecteur96
h96 = feval('selecteur96');
r96 = sim(h96, 'StopTime', 0.1);
M96 = magic(4);
assert(isequal(reshape(r96.yout(end, :), 4, 2), M96(:, [4 1])), ...
       'le Selector aux indices mels, rebati de son .m');
cd(avant96);
rmdir(dossier96, 's');
fprintf('modeles references, espace et arguments : ok\n');

%% ------------------------------------ 97. L'espace de travail du modèle dans un .slx
% Un .slx écrit par MatLibre porte l'espace de travail du modèle — ses
% variables, objets Simulink.Parameter compris, sa source et son code —,
% et LOAD_SYSTEM le rend : le modèle relu se simule comme avant.
e97 = new_system('espace97');
e97 = add_block(e97, 'constant', 'c', 'Value', 'P');
e97 = add_block(e97, 'gain', 'g', 'Gain', 'K');
e97 = add_block(e97, 'outport', 'y');
e97 = add_line(add_line(e97, 'c', 'g'), 'g', 'y');
hws97 = get_param(e97, 'ModelWorkspace');
assignin(hws97, 'K', 7);
p97 = Simulink.Parameter(3);
p97.DataType = 'int8';
assignin(hws97, 'P', p97);
assignin(hws97, 'S', struct('a', {1, 2}));
r97 = sim(e97, 'StopTime', 0.1);
assert(double(r97.yout(end)) == 21, 'avant : 3 fois 7');
fichier97 = [tempname '.slx'];
save_system(e97, fichier97);
e97 = new_system('espace97');   % un modèle neuf du même nom : espace vide
neuf97 = get_param(e97, 'ModelWorkspace');
assert(isempty(fieldnames(neuf97.Donnees)), 'un espace neuf est vide');
f97 = load_system(fichier97);
delete(fichier97);
hws97 = get_param(f97, 'ModelWorkspace');
P97 = getVariable(hws97, 'P');
S97 = getVariable(hws97, 'S');
assert(getVariable(hws97, 'K') == 7 && isa(P97, 'Simulink.Parameter') && ...
       strcmp(P97.DataType, 'int8') && S97(2).a == 2, 'les variables relues, objets compris');
r97 = sim(f97, 'StopTime', 0.1);
assert(double(r97.yout(end)) == 21 && isa(r97.yout, 'int8'), 'le modele relu se simule comme avant');
% la source et le code de l'espace
hws97.DataSource = 'MATLAB Code';
hws97.MATLABCode = 'K = 2;';
save_system(f97, fichier97);
bdclose('espace97');   % ferme le modele relu, et vide son espace
g97 = load_system(fichier97);
delete(fichier97);
h97 = get_param(g97, 'ModelWorkspace');
assert(strcmp(h97.DataSource, 'MATLAB Code') && strcmp(h97.MATLABCode, 'K = 2;'), ...
       'la source et le code de l''espace');
fprintf('espace de travail dans le .slx : ok\n');

%% ----------------------------------------- 98. Batterie de linéarisations
% Des systèmes linéaires tirés au hasard — fonctions de transfert,
% représentations d'état, zéros-pôles, gains, intégrateurs, et leurs
% pendants discrets —, assemblés en série, en parallèle, en contre-
% réaction, et en série d'une contre-réaction : LINMOD et DLINMOD doivent
% rendre la réponse en fréquence que donne l'assemblage des réponses des
% blocs, à l'arrondi près, quel que soit l'ordre des états.
rng(98);
pulsations98 = [0.1 1 3 10];
Ts98 = 0.1;
nCas98 = 0;
echecs98 = {};
for discret98 = [false true]
    for topologie98 = 1:4
        for tirage98 = 1:6
            blocs98 = cell(1, 3);
            for q = 1:3
                % le retour (2) est strictement propre : pas de boucle algébrique
                blocs98{q} = lineaireAuHasard(discret98, q == 2, Ts98);
            end
            m98 = new_system('lineaire98');
            m98 = add_block(m98, 'inport', 'u', 'Port', 1);
            m98 = add_block(m98, 'outport', 'y', 'Port', 1);
            for q = 1:3
                m98 = add_block(m98, blocs98{q}.type, sprintf('G%d', q), blocs98{q}.parametres{:});
            end
            switch topologie98
                case 1   % série : G2 G1
                    m98 = add_line(add_line(add_line(m98, 'u', 'G1'), 'G1', 'G2'), 'G2', 'y');
                    m98 = add_block(m98, 'terminator', 't3');
                    m98 = add_block(m98, 'ground', 'g3');
                    m98 = add_line(add_line(m98, 'g3', 'G3'), 'G3', 't3');
                    nom98 = 'serie';
                case 2   % parallèle : G1 + G2
                    m98 = add_block(m98, 'sum', 's', 'Inputs', '++');
                    m98 = add_line(add_line(m98, 'u', 'G1'), 'u', 'G2');
                    m98 = add_line(add_line(add_line(m98, 'G1', 's/1'), 'G2', 's/2'), 's', 'y');
                    m98 = add_block(m98, 'terminator', 't3');
                    m98 = add_block(m98, 'ground', 'g3');
                    m98 = add_line(add_line(m98, 'g3', 'G3'), 'G3', 't3');
                    nom98 = 'parallele';
                otherwise   % contre-réaction G1 / (1 + G1 G2), suivie de G3 en 4
                    m98 = add_block(m98, 'sum', 's', 'Inputs', '+-');
                    m98 = add_line(add_line(m98, 'u', 's/1'), 's', 'G1');
                    m98 = add_line(add_line(m98, 'G1', 'G2'), 'G2', 's/2');
                    if topologie98 == 3
                        m98 = add_line(m98, 'G1', 'y');
                        m98 = add_block(m98, 'terminator', 't3');
                        m98 = add_block(m98, 'ground', 'g3');
                        m98 = add_line(add_line(m98, 'g3', 'G3'), 'G3', 't3');
                        nom98 = 'contre-reaction';
                    else
                        m98 = add_line(add_line(m98, 'G1', 'G3'), 'G3', 'y');
                        nom98 = 'serie d''une contre-reaction';
                    end
            end
            if discret98
                z98 = exp(1i * pulsations98 * Ts98);
            else
                z98 = 1i * pulsations98;
            end
            H98 = zeros(3, numel(z98));
            for q = 1:3
                H98(q, :) = blocs98{q}.reponse(z98);
            end
            switch topologie98
                case 1
                    attendu98 = H98(2, :) .* H98(1, :);
                case 2
                    attendu98 = H98(1, :) + H98(2, :);
                case 3
                    attendu98 = H98(1, :) ./ (1 + H98(1, :) .* H98(2, :));
                otherwise
                    attendu98 = H98(3, :) .* H98(1, :) ./ (1 + H98(1, :) .* H98(2, :));
            end
            contexte98 = sprintf('%s %s (%s, %s, %s)', nom98, ...
                                 char(string(discret98) + ""), blocs98{1}.type, ...
                                 blocs98{2}.type, blocs98{3}.type);
            try
                if discret98
                    [A98, B98, C98, D98] = dlinmod(m98, Ts98);
                else
                    [A98, B98, C98, D98] = linmod(m98);
                end
            catch err
                echecs98{end + 1} = sprintf('%s : %s %s', contexte98, err.identifier, ...
                                            err.message); %#ok<SAGROW>
                continue
            end
            n98 = size(A98, 1);
            obtenu98 = zeros(1, numel(z98));
            for k = 1:numel(z98)
                obtenu98(k) = C98 * ((z98(k) * eye(n98) - A98) \ B98) + D98;
            end
            ecart98 = max(abs(obtenu98 - attendu98) ./ max(1, abs(attendu98)));
            if ~(ecart98 < 1e-5)
                echecs98{end + 1} = sprintf('%s : ecart relatif %g', contexte98, ecart98); %#ok<SAGROW>
            end
            nCas98 = nCas98 + 1;
        end
    end
end
assert(isempty(echecs98), sprintf('linearisations : %s', strjoin(echecs98, ' ; ')));
% le retard d'un pas : z^-1, exactement
d98 = new_system('retard98');
d98 = add_block(d98, 'inport', 'u', 'Port', 1);
d98 = add_block(d98, 'unitdelay', 'd', 'SampleTime', 0.1);
d98 = add_block(d98, 'outport', 'y', 'Port', 1);
d98 = add_line(add_line(d98, 'u', 'd'), 'd', 'y');
[A98, B98, C98, D98] = dlinmod(d98, 0.1);
assert(isequal([A98 B98; C98 D98], [0 1; 1 0]), 'Unit Delay : z^-1');
% un bloc discret d'une autre période est refusé en le nommant
vu98 = '';
message98 = '';
try
    dlinmod(d98, 0.2);
catch err
    vu98 = err.identifier;
    message98 = err.message;
end
assert(strcmp(vu98, 'Simulink:Commands:DlinmodPeriode') && ~isempty(strfind(message98, 'retard98/d')), ...
       'DLINMOD ne reechantillonne pas un bloc discret');
fprintf('linearisations : %d systemes tires au hasard, et le retard d''un pas : ok\n', nCas98);

%% ---------------------------------------------- 99. Batterie des diagnostics
% Chaque diagnostic du modèle, sur un modèle qui le déclenche, réglé à
% chacun de ses niveaux : à none, la simulation se tait et va à son
% terme ; à warning, elle avertit et va à son terme ; à error, elle
% s'arrête d'une erreur de Simulink qui nomme le bloc ou le modèle — et
% l'avertissement et l'erreur portent le même identifiant.
declencheurs99 = struct('reglage', {}, 'modele', {}, 'regle', {});
% boucle algébrique
m99 = new_system('boucle99');
m99 = add_block(m99, 'constant', 'c', 'Value', 1);
m99 = add_block(m99, 'sum', 's', 'Inputs', '+-');
m99 = add_block(m99, 'gain', 'g', 'Gain', 0.5);
m99 = add_block(m99, 'outport', 'y');
m99 = add_line(add_line(add_line(m99, 'c', 's/1'), 's', 'g'), 'g', 's/2');
m99 = add_line(m99, 's', 'y');
declencheurs99(end + 1) = struct('reglage', 'AlgebraicLoopMsg', 'modele', m99, 'regle', {{}});
% entrée non reliée, sortie non reliée
m99 = new_system('nonrelie99');
m99 = add_block(m99, 'gain', 'g', 'Gain', 2);
m99 = add_block(m99, 'outport', 'y');
m99 = add_line(m99, 'g', 'y');
declencheurs99(end + 1) = struct('reglage', 'UnconnectedInputMsg', 'modele', m99, 'regle', {{}});
m99 = new_system('nonrelie99');
m99 = add_block(m99, 'constant', 'c', 'Value', 1);
m99 = add_block(m99, 'gain', 'g', 'Gain', 2);
m99 = add_line(m99, 'c', 'g');
declencheurs99(end + 1) = struct('reglage', 'UnconnectedOutputMsg', 'modele', m99, 'regle', {{}});
% infini
m99 = new_system('infini99');
m99 = add_block(m99, 'constant', 'a', 'Value', 1);
m99 = add_block(m99, 'constant', 'b', 'Value', 0);
m99 = add_block(m99, 'product', 'p', 'Inputs', '*/');
m99 = add_block(m99, 'outport', 'y');
m99 = add_line(add_line(add_line(m99, 'a', 'p/1'), 'b', 'p/2'), 'p', 'y');
declencheurs99(end + 1) = struct('reglage', 'SignalInfNanChecking', 'modele', m99, 'regle', {{}});
% entiers qui débordent, repliés ou saturés
m99 = new_system('entiers99');
m99 = add_block(m99, 'constant', 'a', 'Value', 'int8(100)');
m99 = add_block(m99, 'constant', 'b', 'Value', 'int8(100)');
m99 = add_block(m99, 'sum', 's', 'Inputs', '++');
m99 = add_block(m99, 'outport', 'y');
m99 = add_line(add_line(add_line(m99, 'a', 's/1'), 'b', 's/2'), 's', 'y');
declencheurs99(end + 1) = struct('reglage', 'IntegerOverflowMsg', 'modele', m99, 'regle', {{}});
declencheurs99(end + 1) = struct('reglage', 'IntegerSaturationMsg', 'modele', ...
                                 set_param(m99, 's', 'SaturateOnIntegerOverflow', 'on'), ...
                                 'regle', {{}});
% plage de sortie
m99 = new_system('plage99');
m99 = add_block(m99, 'constant', 'c', 'Value', 2);
m99 = add_block(m99, 'gain', 'g', 'Gain', 1, 'OutMax', 1);
m99 = add_block(m99, 'outport', 'y');
m99 = add_line(add_line(m99, 'c', 'g'), 'g', 'y');
declencheurs99(end + 1) = struct('reglage', 'SignalRangeChecking', 'modele', m99, 'regle', {{}});
% matrice singulière inversée
m99 = new_system('singuliere99');
m99 = add_block(m99, 'constant', 'a', 'Value', eye(2));
m99 = add_block(m99, 'constant', 'b', 'Value', [1 2; 2 4]);
m99 = add_block(m99, 'product', 'p', 'Inputs', '*/', 'Multiplication', 'Matrix(*)');
m99 = add_block(m99, 'outport', 'y');
m99 = add_line(add_line(add_line(m99, 'a', 'p/1'), 'b', 'p/2'), 'p', 'y');
declencheurs99(end + 1) = struct('reglage', 'CheckMatrixSingularityMsg', 'modele', m99, ...
                                 'regle', {{}});
% source à période -1
m99 = new_system('source99');
m99 = add_block(m99, 'counterfreerunning', 'n', 'SampleTime', -1);
m99 = add_block(m99, 'outport', 'y');
m99 = add_line(m99, 'n', 'y');
declencheurs99(end + 1) = struct('reglage', 'InheritedTsInSrcMsg', 'modele', m99, 'regle', {{}});
% paramètres rangés dans un type étroit
m99 = new_system('parametres99');
m99 = add_block(m99, 'constant', 'c', 'Value', 2.3, 'OutDataTypeStr', 'int8');
m99 = add_block(m99, 'outport', 'y');
m99 = add_line(m99, 'c', 'y');
declencheurs99(end + 1) = struct('reglage', 'ParameterPrecisionLossMsg', 'modele', m99, ...
                                 'regle', {{}});
declencheurs99(end + 1) = struct('reglage', 'ParameterOverflowMsg', 'modele', ...
                                 set_param(m99, 'c', 'Value', 300), 'regle', {{}});
declencheurs99(end + 1) = struct('reglage', 'ParameterDowncastMsg', 'modele', ...
                                 set_param(m99, 'c', 'Value', 'int32(5)'), 'regle', {{}});
declencheurs99(end + 1) = struct('reglage', 'ParameterUnderflowMsg', 'modele', ...
                                 set_param(m99, 'c', 'Value', 1e-6, 'OutDataTypeStr', ...
                                           'fixdt(1,16,4)'), 'regle', {{}});
% passages par zéro sans fin : Zénon
m99 = new_system('zenon99');
m99 = add_block(m99, 'integrator', 'x', 'InitialCondition', 1);
m99 = add_block(m99, 'sign', 's');
m99 = add_block(m99, 'gain', 'g', 'Gain', -1);
m99 = add_block(m99, 'outport', 'y');
m99 = add_line(add_line(add_line(add_line(m99, 'x', 's'), 's', 'g'), 'g', 'x'), 'x', 'y');
declencheurs99(end + 1) = struct('reglage', 'MaxConsecutiveZCsMsg', 'modele', m99, ...
                                 'regle', {{'Solver', 'ode45', 'StopTime', 1.1, ...
                                            'MaxConsecutiveZCs', 20}});
% transition de cadence sans Rate Transition, en monotâche
m99 = new_system('cadences99');
m99 = add_block(m99, 'constant', 'c', 'Value', 1);
m99 = add_block(m99, 'unitdelay', 'rapide', 'SampleTime', 0.1);
m99 = add_block(m99, 'unitdelay', 'lent', 'SampleTime', 0.2);
m99 = add_block(m99, 'outport', 'y');
m99 = add_line(add_line(add_line(m99, 'c', 'rapide'), 'rapide', 'lent'), 'lent', 'y');
declencheurs99(end + 1) = struct('reglage', 'SingleTaskRateTransMsg', 'modele', m99, ...
                                 'regle', {{'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1}});
regleCommune99 = {'StopTime', 0.5};
nEssais99 = 0;
echecs99 = {};
for kD = 1:numel(declencheurs99)
    d99 = declencheurs99(kD);
    regle99 = [regleCommune99, d99.regle];
    ids99 = struct('warning', '', 'error', '');
    for niveau99 = {'none', 'warning', 'error'}
        contexte99 = sprintf('%s = %s', d99.reglage, niveau99{1});
        lastwarn('');
        vu99 = '';
        message99 = '';
        try
            evalc('sim(d99.modele, regle99{:}, d99.reglage, niveau99{1});');
        catch err
            vu99 = err.identifier;
            message99 = err.message;
        end
        [~, averti99] = lastwarn();
        switch niveau99{1}
            case 'none'
                if ~isempty(vu99)
                    echecs99{end + 1} = sprintf('%s : arrete (%s : %s)', contexte99, vu99, ...
                                                message99); %#ok<SAGROW>
                end
                ids99.none = averti99;
            case 'warning'
                if ~isempty(vu99)
                    echecs99{end + 1} = sprintf('%s : arrete (%s : %s)', contexte99, vu99, ...
                                                message99); %#ok<SAGROW>
                elseif isempty(averti99)
                    echecs99{end + 1} = sprintf('%s : aucun avertissement', contexte99); %#ok<SAGROW>
                end
                ids99.warning = averti99;
            case 'error'
                if isempty(vu99)
                    echecs99{end + 1} = sprintf('%s : la simulation va a son terme', contexte99); %#ok<SAGROW>
                elseif ~strncmp(vu99, 'Simulink:', 9) || isempty(strfind(message99, d99.modele.nom))
                    echecs99{end + 1} = sprintf('%s : erreur anonyme %s : %s', contexte99, vu99, ...
                                                message99); %#ok<SAGROW>
                end
                ids99.error = vu99;
        end
        nEssais99 = nEssais99 + 1;
    end
    if ~isempty(ids99.none) && strcmp(ids99.none, ids99.warning)
        echecs99{end + 1} = sprintf('%s = none avertit encore (%s)', d99.reglage, ids99.none); %#ok<SAGROW>
    end
    if ~isempty(ids99.warning) && ~isempty(ids99.error) && ~strcmp(ids99.warning, ids99.error)
        echecs99{end + 1} = sprintf('%s : avertissement %s, erreur %s', d99.reglage, ...
                                    ids99.warning, ids99.error); %#ok<SAGROW>
    end
end
assert(isempty(echecs99), sprintf('diagnostics : %s', strjoin(echecs99, ' ; ')));
% le diagnostic de Zénon nomme le bloc qui bascule
message99 = '';
try
    sim(declencheurs99(strcmp({declencheurs99.reglage}, 'MaxConsecutiveZCsMsg')).modele, ...
        'Solver', 'ode45', 'StopTime', 1.1, 'MaxConsecutiveZCs', 20);
catch err
    message99 = err.message;
end
assert(~isempty(strfind(message99, 'zenon99/s')), 'Zenon : le Sign qui bascule est nomme');
fprintf('diagnostics : %d essais, chacun se tait, avertit ou arrete comme il le doit\n', ...
        nEssais99);

%% ------------------------------------------- 100. Batterie des noms de blocs
% Simulink admet dans un nom de bloc des espaces, des accents, des
% apostrophes, des guillemets, des retours à la ligne, des chiffres en
% tête, et la barre oblique, qu'un chemin double (« a//b »). Chaque nom
% de la liste, donné à un gain entre une constante et une sortie, doit
% se relier, se régler, se simuler, s'écrire en .slx et en .m et se
% relire, et nommer le bloc dans les erreurs.
listeNoms100 = {'mon gain', 'gain é à ù', 'l''apostrophe', 'guillemets "x"', ...
           ['deux' char(10) 'lignes'], '2gain', 'a//b', 'tab	ulation', 'é', ...
           'signe+moins-', 'parenthèses (k)', 'virgule, point.', 'Gain'};
dossier100 = tempname();
mkdir(dossier100);
avant100 = pwd();
cd(dossier100);
echecs100 = {};
for kN = 1:numel(listeNoms100)
    nom100 = listeNoms100{kN};
    affiche100 = strrep(nom100, char(10), '\n');
    try
        m100 = new_system('noms100');
        m100 = add_block(m100, 'constant', 'c', 'Value', 3);
        m100 = add_block(m100, 'gain', nom100, 'Gain', 2);
        m100 = add_block(m100, 'outport', 'y');
        m100 = add_line(add_line(m100, 'c', nom100), nom100, 'y');
        % un bloc que MatLibre écrit en MATLAB Function, nommé de même : son
        % code porte le nom
        m100 = add_block(m100, 'selector', [nom100 ' s'], 'IndexOptionArray', ...
                         {'Index vector (dialog)'}, 'IndexParamArray', {1});
        m100 = add_block(m100, 'outport', 'y2');
        m100 = add_line(add_line(m100, 'c', [nom100 ' s']), [nom100 ' s'], 'y2');
        m100 = set_param(m100, nom100, 'Gain', 5);
        if get_param(m100, nom100, 'Gain') ~= 5
            echecs100{end + 1} = sprintf('%s : set_param puis get_param', affiche100); %#ok<SAGROW>
        end
        r100 = sim(m100, 'StopTime', 0.1);
        if ~isequal(r100.yout(end, :), [15 3])
            echecs100{end + 1} = sprintf('%s : %s au lieu de [15 3]', affiche100, ...
                                         mat2str(r100.yout(end, :))); %#ok<SAGROW>
        end
    catch err
        echecs100{end + 1} = sprintf('%s : %s %s', affiche100, err.identifier, err.message); %#ok<SAGROW>
        continue
    end
    % les fichiers
    for format100 = {'.slx', '.m'}
        try
            fichier100 = fullfile(dossier100, ['noms100' format100{1}]);
            save_system(m100, fichier100);
            if strcmp(format100{1}, '.slx')
                relu100 = load_system(fichier100);
            else
                clear noms100
                relu100 = feval('noms100');
            end
            delete(fichier100);
            r100 = sim(relu100, 'StopTime', 0.1);
            trouve100 = any(cellfun(@(b) strcmp(b.nom, nom100), relu100.blocs));
            if ~isequal(r100.yout(end, :), [15 3]) || ~trouve100
                echecs100{end + 1} = sprintf('%s %s : relu autrement', affiche100, ...
                                             format100{1}); %#ok<SAGROW>
            end
        catch err
            echecs100{end + 1} = sprintf('%s %s : %s %s', affiche100, format100{1}, ...
                                         err.identifier, err.message); %#ok<SAGROW>
            if exist(fichier100, 'file')
                delete(fichier100);
            end
        end
    end
    % une erreur nomme le bloc par son chemin
    try
        sim(set_param(m100, nom100, 'Gain', 'inconnue100'), 'StopTime', 0.1);
        echecs100{end + 1} = sprintf('%s : un gain inconnu passe', affiche100); %#ok<SAGROW>
    catch err
        if isempty(strfind(err.message, ['noms100/' nom100]))
            echecs100{end + 1} = sprintf('%s : l''erreur ne nomme pas le bloc : %s', ...
                                         affiche100, err.message); %#ok<SAGROW>
        end
    end
end
% un texte sur plusieurs lignes, apostrophe comprise : le code d'un bloc
% MATLAB Function s'écrit en .m et se relit
f100 = new_system('code100');
f100 = add_block(f100, 'constant', 'c', 'Value', 3);
f100 = add_block(f100, 'matlabfunction', 'f', 'Script', ...
                 sprintf('function y = fcn(u)\n%% l''apostrophe\ny = 2*u;'));
f100 = add_block(f100, 'outport', 'y');
f100 = add_line(add_line(f100, 'c', 'f'), 'f', 'y');
save_system(f100, fullfile(dossier100, 'code100.m'));
clear code100
g100 = feval('code100');
r100 = sim(g100, 'StopTime', 0.1);
if r100.yout(end) ~= 6 || ~strcmp(get_param(g100, 'f', 'Script'), get_param(f100, 'f', 'Script'))
    echecs100{end + 1} = 'le code d''un bloc MATLAB Function sur plusieurs lignes, en .m';
end
cd(avant100);
rmdir(dossier100, 's');
assert(isempty(echecs100), sprintf('noms de blocs : %s', strjoin(echecs100, ' ; ')));
fprintf('noms de blocs : %d noms difficiles, relies, regles, simules, ecrits et relus\n', ...
        numel(listeNoms100));

%% ------------------------------------------- 101. Simulink.SimulationOutput
% SIM rend un Simulink.SimulationOutput, comme Simulink : ses variables
% se lisent par leur nom ou par get, who les nomme, SimulationMetadata
% dit le modèle, ses instants, son solveur, comment la simulation s'est
% arrêtée et ce qu'elle a duré, ErrorMessage est vide si elle a abouti.
% PARSIM et SIM d'un tableau de SimulationInput en rendent un tableau.
m101 = new_system('sortie101');
m101 = add_block(m101, 'constant', 'c', 'Value', 3);
m101 = add_block(m101, 'integrator', 'x');
m101 = add_block(m101, 'outport', 'y');
m101 = add_line(add_line(m101, 'c', 'x'), 'x', 'y');
out101 = sim(m101, 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 2);
assert(isa(out101, 'Simulink.SimulationOutput'), 'SIM rend un Simulink.SimulationOutput');
assert(abs(out101.yout(end) - 6) < 1e-9 && isequal(out101.get('yout'), out101.yout) && ...
       isequal(out101.find('tout'), out101.tout), 'les variables, par leur nom, get et find');
noms101 = out101.who;
assert(iscell(noms101) && any(strcmp(noms101, 'tout')) && any(strcmp(noms101, 'yout')) && ...
       isfield(out101, 'yout') && ~isfield(out101, 'absent'), 'who et isfield');
md101 = out101.SimulationMetadata;
assert(strcmp(md101.ModelInfo.ModelName, 'sortie101') && md101.ModelInfo.StopTime == 2 && ...
       strcmp(md101.ModelInfo.SolverInfo.Solver, 'ode4') && ...
       strcmp(md101.ExecutionInfo.StopEvent, 'ReachedStopTime') && ...
       md101.TimingInfo.TotalElapsedWallTime >= 0 && isempty(out101.ErrorMessage), ...
       'les metadonnees de la simulation');
assert(isequal(out101.getSimulationMetadata(), md101), 'getSimulationMetadata');
etiquete101 = out101.setUserString('essai');
etiquete101 = etiquete101.setUserData(struct('n', 4));
assert(strcmp(etiquete101.SimulationMetadata.UserString, 'essai') && ...
       etiquete101.SimulationMetadata.UserData.n == 4 && ...
       isempty(out101.SimulationMetadata.UserString), 'setUserString et setUserData rendent une copie');
s101 = struct(out101);
assert(isstruct(s101) && isfield(s101, 'yout') && isfield(s101, 'ErrorMessage'), 'struct');
vu101 = '';
try
    out101.absent; %#ok<VUNUS>
catch err
    vu101 = err.identifier;
end
assert(strcmp(vu101, 'MATLAB:noSuchMethodOrField'), 'une variable absente, comme dans MATLAB');
vu101 = '';
try
    out101.get('absent');
catch err
    vu101 = err.identifier;
end
assert(strcmp(vu101, 'Simulink:Simulation:UnknownVariable'), 'get d''une variable absente');
affiche101 = evalc('disp(out101)');
assert(~isempty(strfind(affiche101, 'Simulink.SimulationOutput:')) && ...
       ~isempty(strfind(affiche101, 'SimulationMetadata')) && ...
       ~isempty(strfind(affiche101, 'ErrorMessage')), 'l''affichage de Simulink');
% arrêtée par un bloc Stop Simulation
a101 = add_block(m101, 'comparetoconstant', 'cmp', 'relop', '>=', 'const', 3);
a101 = add_block(a101, 'stopsimulation', 'stop');
a101 = add_line(add_line(a101, 'x', 'cmp'), 'cmp', 'stop');
out101 = sim(a101, 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 2);
assert(strcmp(out101.SimulationMetadata.ExecutionInfo.StopEvent, 'StopCommand') && ...
       out101.tout(end) < 2, 'Stop Simulation : StopCommand');
% sans sortie : out dans l'espace de base
evalin('base', 'clear out');
sim(m101, 'StopTime', 0.5);
assert(isa(evalin('base', 'out'), 'Simulink.SimulationOutput'), 'out dans l''espace de base');
evalin('base', 'clear out');
% un tableau de SimulationInput : un tableau de SimulationOutput
in101 = Simulink.SimulationInput('sortie101');
in101(2) = Simulink.SimulationInput('sortie101');
in101(1) = in101(1).setBlockParameter('sortie101/c', 'Value', '5');
in101(2) = in101(2).setBlockParameter('sortie101/c', 'Value', 'inexistante101');
sortie101 = m101; %#ok<NASGU>   % le modele, sous son nom, dans l'espace de base
assignin('base', 'sortie101', m101);
outs101 = sim(in101, 'ShowProgress', 'off');
assert(isa(outs101, 'Simulink.SimulationOutput') && isequal(size(outs101), [1 2]), ...
       'un tableau de SimulationOutput');
assert(isempty(outs101(1).ErrorMessage) && ~isempty(outs101(2).ErrorMessage) && ...
       strcmp(outs101(2).SimulationMetadata.ExecutionInfo.StopEvent, 'DiagnosticError'), ...
       'la simulation en erreur porte son message');
evalin('base', 'clear sortie101');
% la structure d'avant se lit toujours : la liste des signaux, les noms
out101 = sim(m101, 'StopTime', 0.5);
etiquettes101 = {out101.signals.label};
assert(numel(etiquettes101) == numel(out101.signals) && numel(etiquettes101) >= 2, ...
       'une liste lue dans un SimulationOutput');
noms101 = fieldnames(out101);
assert(isequal(noms101(end - 1:end)', {'ErrorMessage', 'SimulationMetadata'}), ...
       'FIELDNAMES : les variables, puis ErrorMessage et SimulationMetadata');
for k101 = 1:numel(noms101)
    valeur101 = out101.(noms101{k101}); %#ok<NASGU>   % chaque nom se lit
end
fprintf('Simulink.SimulationOutput : ok\n');

%% ------------------------------- 102. Ce que la compilation sait des blocs
% GET_PARAM lit ce que la compilation sait d'un bloc — sa période, la
% largeur, les dimensions, le type et la complexité de ses ports —, et
% SIMULINK.BLOCKDIAGRAM.GETSAMPLETIMES les périodes du modèle, comme la
% légende de Simulink : D1, D2..., Cont, FiM, Inf. Un bloc qui hérite
% d'une période décalée en hérite le décalage. ObjectParameters décrit
% tous les paramètres d'un bloc ; Mask et MaskType valent 'off' et ''
% sans masque.
m102 = new_system('compile102');
m102 = add_block(m102, 'constant', 'c', 'Value', 'int8(4)');
m102 = add_block(m102, 'constant', 'mat', 'Value', ones(2, 3));
m102 = add_block(m102, 'unitdelay', 'd', 'SampleTime', [0.2 0.1]);
m102 = add_block(m102, 'gain', 'g', 'Gain', 1);
m102 = add_block(m102, 'integrator', 'x');
m102 = add_block(m102, 'constant', 'k', 'Value', 1);
m102 = add_block(m102, 'mux', 'mx', 'Inputs', 3);
m102 = add_block(m102, 'constant', 'z', 'Value', 1 + 2i);
for q = 1:4
    m102 = add_block(m102, 'outport', sprintf('y%d', q));
end
m102 = add_line(add_line(add_line(m102, 'c', 'd'), 'd', 'g'), 'g', 'y1');
m102 = add_line(add_line(m102, 'mat', 'y2'), 'k', 'x');
m102 = add_line(add_line(add_line(m102, 'x', 'mx/1'), 'k', 'mx/2'), 'k', 'mx/3');
m102 = add_line(add_line(m102, 'mx', 'y3'), 'z', 'y4');
assert(isequal(get_param(m102, 'd', 'CompiledSampleTime'), [0.2 0.1]) && ...
       isequal(get_param(m102, 'g', 'CompiledSampleTime'), [0.2 0.1]) && ...
       isequal(get_param(m102, 'x', 'CompiledSampleTime'), [0 0]) && ...
       isequal(get_param(m102, 'k', 'CompiledSampleTime'), [Inf 0]), ...
       'les periodes compilees, le decalage herite compris');
w102 = get_param(m102, 'mx', 'CompiledPortWidths');
assert(isequal(w102.Inport, [1 1 1]) && w102.Outport == 3, 'les largeurs');
d102 = get_param(m102, 'mat', 'CompiledPortDimensions');
assert(isempty(d102.Inport) && isequal(d102.Outport, [2 2 3]), 'les dimensions');
t102 = get_param(m102, 'compile102/g', 'CompiledPortDataTypes');
assert(isequal(t102.Inport, {'int8'}) && isequal(t102.Outport, {'int8'}), 'les types');
x102 = get_param(m102, 'z', 'CompiledPortComplexSignals');
assert(x102.Outport == true, 'la complexite');
p102 = Simulink.BlockDiagram.getSampleTimes(m102);
assert(isa(p102, 'Simulink.SampleTime') && numel(p102) == 3 && ...
       isequal(p102(1).Value, [0.2 0.1]) && strcmp(p102(1).Annotation, 'D1') && ...
       strcmp(p102(1).Description, 'Discrete 1') && strcmp(p102(2).Annotation, 'Cont') && ...
       strcmp(p102(3).Annotation, 'Inf'), 'les periodes du modele, comme la legende');
% le gain qui hérite tient sa valeur entre ses instants décalés : la
r102 = sim(m102, 'Solver', 'ode4', 'FixedStep', 0.05, 'StopTime', 0.4);
y102 = double(r102.yout(:, 1));
% sa condition initiale jusqu'à l'instant 0,3, l'entrée échantillonnée en 0,1 ensuite
assert(all(y102(r102.tout < 0.3 - 1e-12) == 0) && all(y102(r102.tout > 0.3 - 1e-12) == 4), ...
       'le retard decale, et le gain qui en herite');
o102 = get_param(m102, 'x', 'ObjectParameters');
assert(strcmp(o102.InitialCondition.Type, 'string') && ...
       isequal(o102.Parent.Attributes, {'read-only'}) && ...
       strcmp(get_param(m102, 'x', 'MaskType'), '') && strcmp(get_param(m102, 'x', 'Mask'), 'off'), ...
       'ObjectParameters, Mask et MaskType');
assert(isempty(gcb), 'hors de l''editeur, aucun bloc courant');
vu102 = '';
try
    get_param(m102, 'absent', 'CompiledSampleTime');
catch err
    vu102 = err.identifier;
end
assert(strcmp(vu102, 'Simulink:Commands:InvSimulinkObjectName'), 'un bloc absent');
fprintf('compilation lue par get_param, periodes du modele : ok\n');

%% ----------------------------------- 103. Les réglages qu'emploient les scripts
% Les réglages du modèle que les scripts de Simulink posent couramment se
% lisent et se règlent : FastRestart, Description, la génération de code,
% l'affichage, la couverture — rangés, la simulation n'en dépend pas —,
% et LoggingToFile, qui écrit aussi le journal en Dataset dans un fichier
% MAT. SimulationStatus, SimulationTime et BlockDiagramType se lisent
% sans se régler.
m103 = new_system('reglages103');
m103 = add_block(m103, 'sine', 'u');
m103 = add_block(m103, 'gain', 'g', 'Gain', 2);
m103 = add_block(m103, 'outport', 'y');
m103 = add_line(add_line(m103, 'u', 'g'), 'g', 'y');
defauts103 = {'FastRestart', 'off'; 'Description', ''; 'SignalLoggingSaveFormat', 'Dataset'; ...
              'LoggingToFile', 'off'; 'LoggingFileName', 'out.mat'; 'EnablePacing', 'off'; ...
              'PacingRate', 1; 'ArrayBoundsChecking', 'none'; 'StrictBusMsg', 'ErrorLevel1'; ...
              'DefaultParameterBehavior', 'Tunable'; 'InlineParams', 'off'; ...
              'SystemTargetFile', 'grt.tlc'; 'TargetLang', 'C'; 'GenerateReport', 'off'; ...
              'Lock', 'off'; 'SampleTimeColors', 'off'; 'ShowPortDataTypes', 'off'; ...
              'RecordCoverage', 'off'; 'SimulationStatus', 'stopped'; 'SimulationTime', 0; ...
              'BlockDiagramType', 'model'};
for q = 1:size(defauts103, 1)
    assert(isequal(get_param(m103, defauts103{q, 1}), defauts103{q, 2}), ...
           sprintf('%s par defaut', defauts103{q, 1}));
end
assert(strcmp(get_param(new_system('bib103', 'Library'), 'BlockDiagramType'), 'library'), ...
       'BlockDiagramType d''une bibliotheque');
base103 = sim(m103, 'StopTime', 1);
regle103 = set_param(m103, 'FastRestart', 'on', 'Description', 'un gain', 'InlineParams', 'on', ...
                     'DefaultParameterBehavior', 'Inlined', 'TargetLang', 'C++', ...
                     'SampleTimeColors', 'on', 'EnablePacing', 'on', 'PacingRate', 2);
assert(strcmp(get_param(regle103, 'Description'), 'un gain') && ...
       strcmp(get_param(regle103, 'TargetLang'), 'C++'), 'les reglages poses se relisent');
autre103 = sim(regle103, 'StopTime', 1);
assert(isequal(base103.yout, autre103.yout), 'la simulation n''en depend pas');
refus103 = {'FastRestart', 'oui'; 'TargetLang', 'Fortran'; 'PacingRate', -1; ...
            'Description', 5; 'SignalLoggingSaveFormat', 'ModelDataLogs'; ...
            'SimulationStatus', 'running'; 'BlockDiagramType', 'library'};
for q = 1:size(refus103, 1)
    vu103 = '';
    try
        set_param(m103, refus103{q, 1}, refus103{q, 2});
    catch err
        vu103 = err.identifier;
    end
    assert(any(strcmp(vu103, {'Simulink:Config:InvalidValue', ...
                              'Simulink:Commands:SetParamReadOnly'})), ...
           sprintf('%s refuse %s (%s)', refus103{q, 1}, ...
                   strtrim(evalc('disp(refus103{q, 2})')), vu103));
end
% LoggingToFile : le journal en Dataset, aussi dans le fichier
fichier103 = [tempname '.mat'];
j103 = set_param(m103, 'SaveFormat', 'Dataset', 'LoggingToFile', 'on', 'LoggingFileName', fichier103);
p103 = get_param(j103, 'g', 'PortHandles');
j103 = set_param(j103, p103.Outport(1), 'DataLogging', 'on', 'Name', 'double103');
out103 = sim(j103, 'StopTime', 1);
assert(exist(fichier103, 'file') == 2, 'LoggingToFile ecrit le fichier');
lu103 = load(fichier103);
delete(fichier103);
assert(isa(lu103.logsout, 'Simulink.SimulationData.Dataset') && ...
       isa(lu103.yout, 'Simulink.SimulationData.Dataset') && ...
       isequal(lu103.logsout.getElement('double103').Values.Data, ...
               out103.logsout.getElement('double103').Values.Data), ...
       'le journal et les sorties, en Dataset, dans le fichier');
vu103 = '';
try
    sim(set_param(j103, 'LoggingFileName', fullfile(tempname, 'absent', 'x.mat')), 'StopTime', 0.1);
catch err
    vu103 = err.identifier;
end
assert(strcmp(vu103, 'Simulink:Logging:CannotWriteFile'), 'un fichier qui ne s''ecrit pas');
fprintf('reglages des scripts : ok\n');

%% ------------------------------------ 104. Batterie : chaque choix de chaque bloc
% Chaque valeur de chaque paramètre à choix de chaque type de bloc, l'une
% après l'autre : le bloc, seul entre des constantes et des sorties, se
% simule, ou il est refusé d'une erreur de Simulink qui le nomme — jamais
% d'une erreur interne.
catalogue104 = matlibre_sl_catalogue();
regle104 = {'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 0.3};
nEssais104 = 0;
nRefus104 = 0;
echecs104 = {};
dossier104 = tempname();
mkdir(dossier104);
avant104 = pwd();
cd(dossier104);
for kT = 1:numel(catalogue104)
    entree104 = catalogue104(kT);
    if strcmp(entree104.famille, 'Interne')
        continue
    end
    for q = 1:size(entree104.params, 1)
        nature104 = entree104.params{q, 3};
        if ~iscell(nature104)
            continue
        end
        for v = 1:numel(nature104)
            contexte104 = sprintf('%s.%s = %s', entree104.type, entree104.params{q, 1}, ...
                                  nature104{v});
            nEssais104 = nEssais104 + 1;
            try
                [s104, ok104] = allerModele(entree104.type, ...
                                            {entree104.params{q, 1}, nature104{v}}, 0.5);
            catch err
                if ~strncmp(err.identifier, 'Simulink:', 9)
                    echecs104{end + 1} = sprintf('%s : ADD_BLOCK, erreur interne %s : %s', ...
                                                 contexte104, err.identifier, err.message); %#ok<SAGROW>
                end
                nRefus104 = nRefus104 + 1;
                continue
            end
            if ~ok104
                continue
            end
            try
                evalc('sim(s104, regle104{:});');
            catch err
                if ~(strncmp(err.identifier, 'Simulink:', 9) || ...
                     strncmp(err.identifier, 'Stateflow:', 10) || ...
                     strncmp(err.identifier, 'Simscape:', 9)) || ...
                   isempty(strfind(err.message, 'aller94'))
                    echecs104{end + 1} = sprintf('%s : SIM, %s : %s', contexte104, ...
                                                 err.identifier, err.message); %#ok<SAGROW>
                end
                nRefus104 = nRefus104 + 1;
            end
        end
    end
end
cd(avant104);
rmdir(dossier104, 's');
assert(isempty(echecs104), sprintf('chaque choix : %s', strjoin(echecs104, ' ; ')));
fprintf('chaque choix de chaque bloc : %d essais, %d refus nommes\n', nEssais104, nRefus104);

%% ------------------------- 105. La forme de MATLAB : le modèle désigné par son nom
% Dans MATLAB, un modèle est un objet de la session : NEW_SYSTEM('nom') l'y
% met, et tout le reste le désigne par son nom, ses blocs par leur chemin
% « modele/bloc », l'un et l'autre par leur poignée. Les mêmes fonctions
% que par valeur, sur le registre de la session.
bdclose('all');
fin105 = @(r) r.yout{1}.Values.Data(end);
new_system('nom105');
assert(bdIsLoaded('nom105'), 'NEW_SYSTEM sans sortie met le modele dans la session');
assert(strcmp(get_param('nom105', 'Solver'), 'VariableStepAuto') && ...
       strcmp(get_param('nom105', 'SaveFormat'), 'Dataset') && ...
       strcmp(get_param('nom105', 'Dirty'), 'off') && isempty(get_param('nom105', 'FileName')), ...
       'il y part des reglages d''un modele neuf de Simulink, sans fichier');
h105 = add_block('simulink/Sources/Step', 'nom105/echelon', 'Time', '0');
add_block('simulink/Math Operations/Sum', 'nom105/ecart', 'Inputs', '+-');
add_block('simulink/Continuous/Transfer Fcn', 'nom105/procede', ...
          'Numerator', '1', 'Denominator', '[1 2 1]');
add_block('built-in/Outport', 'nom105/y');
l105 = add_line('nom105', {'echelon/1', 'ecart/1', 'procede/1', 'procede/1'}, ...
                {'ecart/1', 'procede/1', 'y/1', 'ecart/2'});
assert(numel(l105) == 4 && l105(3) == l105(4), 'une ligne par port de depart');
assert(strcmp(get_param('nom105', 'Dirty'), 'on'), 'le modele a change : Dirty le dit');
r105 = sim('nom105', 'StopTime', '30');
assert(isa(r105.yout, 'Simulink.SimulationData.Dataset') && abs(fin105(r105) - 0.5) < 1e-3, ...
       'la boucle fermee de 1/(s+1)^2 tend vers 1/2 ; la sortie, en Dataset');

% lire : le type de Simulink, les parametres en texte, les poignees
assert(strcmp(get_param('nom105/procede', 'BlockType'), 'TransferFcn'), 'BlockType de Simulink');
assert(strcmp(get_param('nom105/procede', 'Type'), 'block') && ...
       strcmp(get_param('nom105', 'Type'), 'block_diagram'), 'Type');
assert(strcmp(get_param('nom105/procede', 'Denominator'), '[1 2 1]'), 'le texte donne');
assert(strcmp(get_param('nom105/echelon', 'After'), '1'), 'un defaut numerique, en texte');
assert(strcmp(get_param('nom105/ecart', 'Parent'), 'nom105') && ...
       isempty(get_param('nom105', 'Parent')), 'Parent');
assert(get_param('nom105/echelon', 'Handle') == h105 && ...
       strcmp(get_param(h105, 'Name'), 'echelon') && ...
       strcmp(getfullname(h105), 'nom105/echelon'), 'la poignee d''un bloc');
assert(strcmp(getfullname(get_param('nom105', 'Handle')), 'nom105') && ...
       strcmp(bdroot(h105), 'nom105'), 'la poignee du modele');
assert(isequal(get_param('nom105', 'Blocks'), {'echelon'; 'ecart'; 'procede'; 'y'}), 'Blocks');
assert(isequal(get_param({'nom105/echelon', 'nom105/y'}, 'BlockType'), {'Step', 'Outport'}), ...
       'plusieurs objets a la fois');

% regler : un bloc, le modele
set_param('nom105/echelon', 'After', '2');
set_param('nom105', 'StopTime', '40');
assert(strcmp(get_param('nom105', 'StopTime'), '40'), 'un reglage du modele, en texte');
r105 = sim('nom105');
assert(r105.tout(end) == 40 && abs(fin105(r105) - 1) < 1e-3, 'l''echelon de 2 mene a 1');
% les reglages que tout bloc porte : leur defaut, et Position en pixels
libre105 = get_param('nom105/procede', 'Position');
assert(isnumeric(libre105) && numel(libre105) == 4 && libre105(3) > libre105(1) && ...
       libre105(4) > libre105(2) && isequal(libre105, round(libre105)), ...
       'sans Position posee, le cadre de la mise en place, en pixels');
assert(strcmp(get_param('nom105/procede', 'Orientation'), 'right') && ...
       strcmp(get_param('nom105/procede', 'BackgroundColor'), 'white') && ...
       strcmp(get_param('nom105/procede', 'ShowName'), 'on') && ...
       strcmp(get_param('nom105/procede', 'Commented'), 'off') && ...
       isempty(get_param('nom105/procede', 'Tag')), 'les defauts de Simulink');
set_param('nom105/procede', 'Position', [200 100 260 140]);
assert(isequal(get_param('nom105/procede', 'Position'), [200 100 260 140]), 'Position posee, relue');

% les ports et les lignes
ph105 = get_param('nom105/procede', 'PortHandles');
ligne105 = get_param(ph105.Outport(1), 'Line');
assert(ligne105 == l105(3) && strcmp(get_param(ligne105, 'Type'), 'line') && ...
       strcmp(get_param(ph105.Outport(1), 'Type'), 'port'), 'la ligne d''un port');
assert(get_param(ligne105, 'SrcBlockHandle') == get_param('nom105/procede', 'Handle') && ...
       get_param(ligne105, 'SrcPortHandle') == ph105.Outport(1) && ...
       numel(get_param(ligne105, 'DstPortHandle')) == 2, 'les bouts d''une ligne');
set_param(ligne105, 'Name', 'sortie105');
assert(strcmp(get_param(ph105.Outport(1), 'Name'), 'sortie105') && ...
       strcmp(get_param(ligne105, 'Name'), 'sortie105'), 'le nom d''une ligne est celui du signal');
lh105 = get_param('nom105/ecart', 'LineHandles');
assert(isequal(lh105.Inport, [l105(1), ligne105]) && lh105.Outport == l105(2), 'LineHandles');
pc105 = get_param('nom105/ecart', 'PortConnectivity');
assert(numel(pc105) == 3 && pc105(1).SrcBlock == h105 && pc105(1).SrcPort == 0 && ...
       pc105(3).DstBlock == get_param('nom105/procede', 'Handle'), 'PortConnectivity');
assert(get_param(get_param('nom105/y', 'PortHandles').Inport(1), 'Line') == ligne105, ...
       'la ligne qui arrive sur une entree');

% chercher
assert(isequal(find_system('nom105'), {'nom105'; 'nom105/echelon'; 'nom105/ecart'; ...
                                      'nom105/procede'; 'nom105/y'}), ...
       'FIND_SYSTEM : le systeme, puis ses blocs');
assert(isequal(find_system('nom105', 'BlockType', 'Sum'), {'nom105/ecart'}), 'par type');
assert(isequal(find_system('nom105', 'RegExp', 'on', 'Name', '^e'), ...
               {'nom105/echelon'; 'nom105/ecart'}), 'par expression reguliere');
assert(isequal(find_system('nom105', 'CaseSensitive', 'off', 'Name', 'ECART'), ...
               {'nom105/ecart'}) && isempty(find_system('nom105', 'Name', 'ECART')), 'la casse');
assert(isequal(find_system('nom105', 'SearchDepth', 0), {'nom105'}), 'SearchDepth 0');
assert(isequal(find_system('type', 'block_diagram'), {'nom105'}) && ...
       isequal(find_system('SearchDepth', 0), {'nom105'}), 'les modeles ouverts');
assert(isequal(sort(find_system('nom105', 'FindAll', 'on', 'Type', 'line')), sort(l105(1:3))), ...
       'FindAll rend les poignees des lignes');
assert(isequal(find_system(get_param('nom105', 'Handle'), 'BlockType', 'Step'), h105), ...
       'depuis une poignee, des poignees');

% un sous-systeme, bati par ses chemins
add_block('built-in/Subsystem', 'nom105/regul');
add_block('built-in/Inport', 'nom105/regul/e');
add_block('built-in/Gain', 'nom105/regul/k', 'Gain', '4');
add_block('built-in/Outport', 'nom105/regul/u');
add_line('nom105/regul', 'e/1', 'k/1');
add_line('nom105/regul', 'k/1', 'u/1');
delete_line('nom105', 'ecart/1', 'procede/1');
add_line('nom105', 'ecart/1', 'regul/1', 'autorouting', 'on');
phr105 = get_param('nom105/regul', 'PortHandles');
add_line('nom105', phr105.Outport(1), ph105.Inport(1));
r105 = sim('nom105');
assert(abs(fin105(r105) - 1.6) < 1e-3, 'un gain de 4 dans la boucle : 2 x 4/5');
assert(strcmp(get_param('nom105/regul/k', 'Parent'), 'nom105/regul') && ...
       strcmp(bdroot('nom105/regul/k'), 'nom105'), 'le parent d''un bloc interieur');
assert(numel(find_system('nom105')) == 9 && numel(find_system('nom105', 'SearchDepth', 1)) == 6 && ...
       isequal(find_system('nom105/regul', 'BlockType', 'Gain'), {'nom105/regul/k'}), ...
       'la recherche descend dans les sous-systemes');
set_param('nom105/regul/k', 'Gain', '9');
r105 = sim('nom105');
assert(abs(fin105(r105) - 1.8) < 1e-3, 'un gain de 9 : 2 x 9/10');

% un sous-systeme pose vide ne touche pas au modele qui porte son nom
new_system('regul105');
hws105 = get_param('regul105', 'ModelWorkspace');
assignin(hws105, 'k105', 3);
add_block('built-in/Subsystem', 'nom105/regul105');
add_block('built-in/Gain', 'nom105/regul105/g');     % le contenu vide se cree ici
assert(hasVariable(get_param('regul105', 'ModelWorkspace'), 'k105'), ...
       'un sous-systeme rempli par son chemin : l''espace du modele homonyme reste');
delete_block('nom105/regul105');
add_block('simulink/Ports & Subsystems/Subsystem', 'nom105/regul105');
assert(hasVariable(get_param('regul105', 'ModelWorkspace'), 'k105'), ...
       'le Subsystem de la bibliotheque : l''espace du modele homonyme reste');
delete_block('nom105/regul105');
bdclose('regul105');

% recopier, nommer sans collision, retirer, remplacer
add_block('nom105/regul/k', 'nom105/copie');
assert(strcmp(get_param('nom105/copie', 'Gain'), '9'), 'un bloc recopie garde ses parametres');
c105 = add_block('built-in/Gain', 'nom105/copie', 'MakeNameUnique', 'on');
assert(strcmp(get_param(c105, 'Name'), 'copie1'), 'MakeNameUnique');
delete_block(c105);
delete_block({'nom105/copie'});
assert(numel(get_param('nom105', 'Blocks')) == 5, 'DELETE_BLOCK, par poignee et par chemin');
add_block('built-in/Gain', 'nom105/libre');
add_block('built-in/Terminator', 'nom105/fin');
fil105 = add_line('nom105', 'libre/1', 'fin/1');
delete_line(fil105);
lh105 = get_param('nom105/fin', 'LineHandles');
assert(lh105.Inport == -1, 'DELETE_LINE par poignee ; un port libre rend -1');
delete_block('nom105/fin');
remplaces105 = replace_block('nom105', 'Gain', 'built-in/Abs', 'noprompt');
assert(isequal(sort(remplaces105), {'nom105/libre'; 'nom105/regul/k'}) && ...
       strcmp(get_param('nom105/regul/k', 'BlockType'), 'Abs'), 'REPLACE_BLOCK, a tous les niveaux');
delete_block('nom105/libre');
r105 = sim('nom105');
assert(abs(fin105(r105) - 1) < 1e-3, '|e| a la place du gain : 2/2');

% le Subsystem de la bibliotheque arrive garni ; une copie se nomme sans collision
add_block('simulink/Ports & Subsystems/Subsystem', 'nom105/garni');
assert(isequal(find_system('nom105/garni'), ...
               {'nom105/garni'; 'nom105/garni/In1'; 'nom105/garni/Out1'}), ...
       'le Subsystem de la bibliotheque : une entree reliee a une sortie');
d105 = add_block('nom105/garni', 'nom105/garni', 'MakeNameUnique', 'on');
assert(strcmp(getfullname(d105), 'nom105/garni1'), 'MakeNameUnique sur une copie');
delete_block({'nom105/garni', 'nom105/garni1'});

% enregistrer sous un autre nom, fermer, relire
dossier105 = tempname;
mkdir(dossier105);
fichier105 = fullfile(dossier105, 'relu105.slx');
save_system('nom105', fichier105);
assert(exist(fichier105, 'file') == 2 && bdIsLoaded('relu105') && ~bdIsLoaded('nom105'), ...
       'enregistre sous un autre nom, le modele le prend');
assert(strcmp(get_param('relu105', 'Dirty'), 'off') && ...
       strcmp(get_param('relu105', 'FileName'), fichier105), 'enregistre : Dirty retombe, FileName dit ou');
set_param('relu105', 'Dirty', 'on');
assert(strcmp(get_param('relu105', 'Dirty'), 'on'), 'Dirty se regle aussi a la main');
close_system('relu105', 0);
assert(~bdIsLoaded('relu105'), 'CLOSE_SYSTEM(NOM,0) ferme sans enregistrer');
load_system(fichier105);
assert(strcmp(get_param('relu105', 'Dirty'), 'off') && ...
       strcmp(get_param('relu105', 'FileName'), fichier105), 'relu : intact, et son fichier connu');
assert(numel(find_system('relu105')) == 9 && ...
       strcmp(get_param('relu105/procede', 'Denominator'), '[1 2 1]'), 'relu du fichier');
assert(isequal(get_param('relu105/procede', 'Position'), [200 100 260 140]) && ...
       strcmp(get_param('relu105', 'Solver'), 'VariableStepAuto'), ...
       'la position, en pixels dans le fichier, et le solveur en reviennent');
relu105 = sim('relu105');
assert(isequal(relu105.tout, r105.tout) && ...
       max(abs(relu105.yout{1}.Values.Data - r105.yout{1}.Values.Data)) < 1e-12, ...
       'et il se simule de meme');
[A105, B105, C105, D105] = linmod('relu105'); %#ok<ASGLU>
assert(isequal(size(A105), [2 2]), 'LINMOD par le nom');
rmdir(dossier105, 's');

% ce qui se refuse, et comment
refus105 = {@() evalc('new_system(''relu105'');'), 'Simulink:Commands:NewSysAlreadyExists'; ...
            @() get_param('absent105/b', 'Gain'), 'Simulink:Commands:InvSimulinkObjectName'; ...
            @() get_param('relu105/absent', 'Gain'), 'Simulink:Commands:InvSimulinkObjectName'; ...
            @() add_block('built-in/Gain', 'relu105'), 'Simulink:Commands:AddBlockInvalidDest'; ...
            @() get_param(123456.5, 'Name'), 'Simulink:Commands:InvSimulinkObjectHandle'; ...
            @() set_param('relu105/procede', 'Absent', '1'), 'Simulink:Commands:ParamUnknown'; ...
            @() set_param('relu105/procede', 'Position', [1 2 3]), 'Simulink:Commands:InvalidPosition'; ...
            @() set_param('relu105', 'FileName', 'ailleurs.slx'), 'Simulink:Commands:SetParamReadOnly'; ...
            @() set_param('relu105', 'Dirty', 'peut-etre'), 'Simulink:Data:InvalidValue'; ...
            @() add_line('relu105', 'procede/1', 'absent/1'), 'Simulink:Commands:InvSimulinkObjectName'};
for q = 1:size(refus105, 1)
    vu105 = '';
    try
        refus105{q, 1}();
    catch err
        vu105 = err.identifier;
    end
    assert(strcmp(vu105, refus105{q, 2}), sprintf('refus %d : %s', q, vu105));
end

% la forme par valeur reste ce qu'elle etait : un modele repris dans une
% variable n'entre pas dans la session
valeur105 = new_system('valeur105');
assert(~bdIsLoaded('valeur105') && isstruct(valeur105), 'NEW_SYSTEM avec sortie rend la valeur');
bdclose('all');
assert(isempty(find_system()), 'BDCLOSE(''all'') vide la session');
fprintf('le modele par son nom : ok\n');

%% ---------------------------------- 106. Les jeux de configuration, et findBlocks
% Le jeu actif d'un modèle de la session lui reste lié : le régler règle
% le modèle. Un jeu libre s'attache, s'active, se détache ; ses réglages
% deviennent ceux que SIM applique.
bdclose('all');
new_system('jeux106');
add_block('simulink/Sources/Clock', 'jeux106/t');
add_block('built-in/Outport', 'jeux106/y');
add_line('jeux106', 't/1', 'y/1');
cs106 = getActiveConfigSet('jeux106');
assert(isa(cs106, 'Simulink.ConfigSet') && strcmp(cs106.Name, 'Configuration') && ...
       cs106.isActive() && strcmp(cs106.getModel(), 'jeux106'), 'le jeu actif, lie au modele');
assert(strcmp(get_param(cs106, 'StopTime'), '10') && ...
       strcmp(get_param(cs106, 'Solver'), 'VariableStepAuto'), ...
       'ses reglages, ceux d''un modele neuf de Simulink, en texte');
set_param(cs106, 'StopTime', '5', 'Solver', 'ode1');
assert(strcmp(get_param('jeux106', 'StopTime'), '5'), 'regler le jeu actif regle le modele');
set_param('jeux106', 'FixedStep', '0.5');
assert(strcmp(get_param(cs106, 'FixedStep'), '0.5'), 'et regler le modele se lit dans le jeu');
r106 = sim('jeux106');
assert(r106.tout(end) == 5 && numel(r106.tout) == 11, 'SIM applique le jeu actif');

% un jeu libre : regle, copie, attache, active
libre106 = Simulink.ConfigSet;
assert(strcmp(get_param(libre106, 'Solver'), 'VariableStepAuto') && ...
       strcmp(get_param(libre106, 'SaveFormat'), 'Dataset'), 'un jeu neuf : les memes reglages');
libre106.Name = 'Rapide';
set_param(libre106, 'StopTime', '2', 'Solver', 'ode4', 'FixedStep', '0.25');
double106 = copy(libre106);
set_param(double106, 'StopTime', '99');
assert(strcmp(get_param(libre106, 'StopTime'), '2') && isempty(libre106.getModel()) && ...
       ~libre106.isActive(), 'la copie est independante, le jeu libre n''est a personne');
attachConfigSet('jeux106', libre106);
assert(isequal(getConfigSets('jeux106'), {'Configuration'; 'Rapide'}) && ...
       strcmp(libre106.getModel(), 'jeux106') && ~libre106.isActive(), 'attache, pas encore actif');
assert(strcmp(get_param('jeux106', 'StopTime'), '5'), 'attacher ne change pas le modele');
set_param(libre106, 'StopTime', '3');
assert(strcmp(get_param(getConfigSet('jeux106', 'Rapide'), 'StopTime'), '3'), ...
       'un jeu attache se regle dans le modele');
setActiveConfigSet('jeux106', 'Rapide');
assert(libre106.isActive() && ~cs106.isActive() && ...
       strcmp(get_param('jeux106', 'Solver'), 'ode4') && ...
       strcmp(get_param(cs106, 'StopTime'), '5'), 'active : ses reglages sont ceux du modele');
r106 = sim('jeux106');
assert(r106.tout(end) == 3 && numel(r106.tout) == 13, 'SIM applique le nouveau jeu actif');
setActiveConfigSet('jeux106', 'Configuration');
r106 = sim('jeux106');
assert(r106.tout(end) == 5 && numel(r106.tout) == 11 && ...
       strcmp(get_param('jeux106', 'Solver'), 'ode1'), 'et l''ancien, reactive, revient entier');

% la copie d'un jeu, d'un modele a l'autre ; renommer ; detacher
new_system('autre106');
copie106 = attachConfigSetCopy('autre106', cs106, true);
assert(strcmp(copie106.Name, 'Configuration1') && strcmp(copie106.getModel(), 'autre106') && ...
       strcmp(cs106.getModel(), 'jeux106'), 'la copie renommee, l''original reste chez lui');
setActiveConfigSet('autre106', 'Configuration1');
assert(strcmp(get_param('autre106', 'StopTime'), '5') && ...
       strcmp(get_param('autre106', 'FixedStep'), '0.5'), 'les reglages ont suivi');
copie106.Name = 'Recu';
copie106.Description = 'venu de jeux106';
assert(isequal(getConfigSets('autre106'), {'Recu'; 'Configuration'}) && ...
       strcmp(getActiveConfigSet('autre106').Description, 'venu de jeux106'), 'renommer un jeu lie');
detache106 = detachConfigSet('jeux106', 'Rapide');
assert(isequal(getConfigSets('jeux106'), {'Configuration'}) && isempty(detache106.getModel()) && ...
       strcmp(get_param(detache106, 'StopTime'), '3'), 'detache, il garde ses reglages');

% par valeur : les memes fonctions rendent le modele
v106 = new_system('valeur106');
v106 = attachConfigSet(v106, detache106);
v106 = setActiveConfigSet(v106, 'Rapide');
assert(get_param(v106, 'StopTime') == 3 && strcmp(get_param(v106, 'Solver'), 'ode4') && ...
       isequal(getConfigSets(v106), {'Rapide'; 'Configuration'}), 'par valeur');
[v106, rendu106] = detachConfigSet(setActiveConfigSet(v106, 'Configuration'), 'Rapide');
assert(get_param(v106, 'StopTime') == 10 && strcmp(rendu106.Name, 'Rapide'), 'et detache par valeur');

% ce qui se refuse
refus106 = {@() set_param(cs106, 'Solver', 'ode99'), 'Simulink:Commands:SolveurInconnu'; ...
            @() set_param(cs106, 'Absent', '1'), 'Simulink:Commands:ParamUnknown'; ...
            @() get_param(cs106, 'Absent'), 'Simulink:Commands:ParamUnknown'; ...
            @() attachConfigSet('jeux106', copy(cs106)), 'Simulink:ConfigSet:ConfigSetNameNotUnique'; ...
            @() attachConfigSet('autre106', cs106), 'Simulink:ConfigSet:ConfigSetAlreadyAttached'; ...
            @() detachConfigSet('jeux106', 'Configuration'), ...
                'Simulink:ConfigSet:ActiveConfigSetCannotBeDetached'; ...
            @() setActiveConfigSet('jeux106', 'Absent'), 'Simulink:ConfigSet:ConfigSetNotFound'; ...
            @() attachConfigSet('jeux106', 3), 'Simulink:ConfigSet:InvalidConfigSet'};
for q = 1:size(refus106, 1)
    vu106 = '';
    try
        refus106{q, 1}();
    catch err
        vu106 = err.identifier;
    end
    assert(strcmp(vu106, refus106{q, 2}), sprintf('refus %d : %s', q, vu106));
end

% Simulink.findBlocks : des poignees, a tous les niveaux, sous les masques
add_block('simulink/Ports & Subsystems/Subsystem', 'jeux106/S');
add_block('built-in/Gain', 'jeux106/S/k', 'Gain', '4');
add_block('built-in/Gain', 'jeux106/K', 'Gain', '4');
tous106 = Simulink.findBlocks('jeux106');
assert(isequal(sort(getfullname(tous106)), sort({'jeux106/t'; 'jeux106/y'; 'jeux106/S'; ...
       'jeux106/S/In1'; 'jeux106/S/Out1'; 'jeux106/S/k'; 'jeux106/K'})), 'tous les blocs');
assert(isequal(getfullname(Simulink.findBlocks('jeux106/S')), ...
               {'jeux106/S/In1'; 'jeux106/S/Out1'; 'jeux106/S/k'}), ...
       'un sous-systeme n''est pas l''un de ses blocs');
assert(numel(Simulink.findBlocks('jeux106', 'Gain', '4')) == 2 && ...
       numel(Simulink.findBlocksOfType('jeux106', 'Gain')) == 2 && ...
       isequal(Simulink.findBlocksOfType('jeux106', 'Gain', Simulink.FindOptions('SearchDepth', 1)), ...
               get_param('jeux106/K', 'Handle')), 'par parametre, par type, a un niveau');
assert(isequal(Simulink.findBlocks('jeux106', 'Name', '^[kK]$', ...
                                   Simulink.FindOptions('RegExp', true, 'SearchDepth', 1)), ...
               get_param('jeux106/K', 'Handle')) && ...
       numel(Simulink.findBlocks('jeux106', 'Name', 'k', ...
                                 Simulink.FindOptions('CaseSensitive', false))) == 2, ...
       'les options : expression reguliere, casse');
assert(getSimulinkBlockHandle('jeux106/K') == get_param('jeux106/K', 'Handle') && ...
       getSimulinkBlockHandle('jeux106/absent') == -1 && ...
       getSimulinkBlockHandle('ferme106/b') == -1, 'getSimulinkBlockHandle');
bdclose('all');
fprintf('jeux de configuration, findBlocks : ok\n');

%% ------------------------------------------------------ 107. LINIO et LINEARIZE
% LINEARIZE lit sur le schéma d'une boucle fermée ce que LINMOD ne donne
% qu'entre les ports du modèle : chaque point d'analyse de LINIO ajoute
% une entrée, mesure une sortie ou coupe la boucle, où qu'il soit posé.
% La boucle : r -> (+-) -> C (un gain de 4, dans un sous-système) -> P =
% 1/(s+1)^2 -> y, P revenant sur la sommation.
bdclose('all');
rep107 = @(s, w) arrayfun(@(x) s.C * ((1i * x * eye(size(s.A, 1)) - s.A) \ s.B) + s.D, w);
w107 = [0.3 2 7];
G107 = 1 ./ (1i * w107 + 1) .^ 2;
proche107 = @(s, attendu) max(abs(rep107(s, w107) - attendu)) < 1e-8;
new_system('lin107');
add_block('simulink/Sources/In1', 'lin107/r');
add_block('simulink/Math Operations/Sum', 'lin107/e', 'Inputs', '+-');
add_block('built-in/Subsystem', 'lin107/C');
add_block('built-in/Inport', 'lin107/C/in');
add_block('built-in/Gain', 'lin107/C/k', 'Gain', '4');
add_block('built-in/Outport', 'lin107/C/out');
add_line('lin107/C', {'in/1', 'k/1'}, {'k/1', 'out/1'});
add_block('simulink/Continuous/Transfer Fcn', 'lin107/P', 'Numerator', '1', ...
          'Denominator', '[1 2 1]');
add_block('built-in/Outport', 'lin107/y');
add_line('lin107', {'r/1', 'e/1', 'C/1', 'P/1', 'P/1'}, {'e/1', 'C/1', 'P/1', 'y/1', 'e/2'});

% sans point : des ports aux ports, comme LINMOD
[A107, B107, C107, D107] = linmod('lin107');
s107 = linearize('lin107');
assert(isa(s107, 'ss') && isequal(s107.A, A107) && isequal(s107.B, B107) && ...
       isequal(s107.C, C107) && isequal(s107.D, D107) && s107.Ts == 0, 'sans point, LINMOD');
assert(isequal(s107.InputName, {'r'}) && isequal(s107.OutputName, {'y'}) && ...
       isequal(s107.StateName, {'P(1)', 'P(2)'}), 'les voies et les etats portent leur nom');

% les huit points, chacun contre sa formule
clear io107
io107(1) = linio('lin107/r', 1, 'input');
io107(2) = linio('lin107/P', 1, 'output');
[s107, point107] = linearize('lin107', io107);
assert(proche107(s107, 4 * G107 ./ (1 + 4 * G107)) && abs(dcgain(s107) - 0.8) < 1e-9, ...
       'input et output : la boucle fermee');
assert(isequal(s107.InputName, {'r'}) && isequal(s107.OutputName, {'P'}) && ...
       isequal(point107.x, [0; 0]) && isequal(point107.u, 0), 'les noms, le point de fonctionnement');
io107(1) = linio('lin107/C/k', 1, 'openinput');
assert(proche107(linearize('lin107', io107), G107), ...
       'openinput, pose dans le sous-systeme : le procede seul');
clear io107
io107(1) = linio('lin107/C/in', 1, 'input');
io107(2) = linio('lin107/C/k', 1, 'openoutput');
s107 = linearize('lin107', io107);
assert(isequal(s107.D, 4) && proche107(s107, 4 * ones(1, 3)), 'openoutput : le regulateur seul');
assert(proche107(linearize('lin107', linio('lin107/P', 1, 'looptransfer')), -4 * G107), ...
       'looptransfer : la boucle, avec le signe du schema');
assert(proche107(linearize('lin107', linio('lin107/C', 1, 'looptransfer')), -4 * G107), ...
       'le meme, pose sur la sortie du sous-systeme');
assert(proche107(linearize('lin107', linio('lin107/P', 1, 'sensitivity')), 1 ./ (1 + 4 * G107)), ...
       'sensitivity : 1/(1+L)');
assert(proche107(linearize('lin107', linio('lin107/P', 1, 'compsensitivity')), ...
                 -4 * G107 ./ (1 + 4 * G107)), 'compsensitivity : -L/(1+L)');
clear io107
io107(1) = linio('lin107/r', 1, 'input');
io107(2) = linio('lin107/e', 1, 'output');
io107(3) = linio('lin107/P', 1, 'loopbreak');
s107 = linearize('lin107', io107);
assert(isequal(s107.D, 1) && proche107(s107, ones(1, 3)), 'loopbreak : l''ecart suit la consigne');
io107(3).Active = 'off';
assert(proche107(linearize('lin107', io107), 1 ./ (1 + 4 * G107)), 'un point inactif est ignore');

% deux points sur le meme signal se suivent dans l'ordre donne
clear io107
io107(1) = linio('lin107/P', 1, 'input');
io107(2) = linio('lin107/P', 1, 'output');
assert(proche107(linearize('lin107', io107), 1 ./ (1 + 4 * G107)), 'une entree puis une sortie');
io107 = io107([2 1]);
assert(proche107(linearize('lin107', io107), -4 * G107 ./ (1 + 4 * G107)), ...
       'une sortie puis une entree');

% l'ancienne ecriture, OpenLoop, une poignee, un modele par valeur
ancien107 = linio('lin107/P', 1, 'outin', 'on');
assert(strcmp(ancien107.Type, 'looptransfer') && strcmp(ancien107.OpenLoop, 'on') && ...
       strcmp(getfield(linio('lin107/P', 1), 'Type'), 'input') && ...
       strcmp(getfield(linio('lin107/P', 1, 'inout'), 'Type'), 'sensitivity') && ...
       strcmp(getfield(linio('lin107/P', 1, 'out', 'on'), 'Type'), 'openoutput'), ...
       'les types d''hier');
clear io107
io107(1) = linio(get_param('lin107/C', 'Handle'), 1, 'input');
io107(2) = linio('lin107/P', 1, 'output');
assert(strcmp(io107(1).Block, 'lin107/C') && proche107(linearize('lin107', io107), ...
       G107 ./ (1 + 4 * G107)), 'une poignee designe le bloc');
io107(1).OpenLoop = 'on';
assert(proche107(linearize('lin107', io107), G107), 'OpenLoop coupe la boucle au point');
valeur107 = matlibre_sl_ouverts('lire', 'lin107');
io107(1) = linio('C/k', 1, 'openinput');
io107(2) = linio('P', 1, 'output');
assert(proche107(linearize(valeur107, io107), G107), 'un modele par valeur, des chemins sans le modele');

% des signaux vecteurs : une voie par element
new_system('vec107');
add_block('built-in/Inport', 'vec107/u', 'PortDimensions', '2');
add_block('built-in/Gain', 'vec107/K', 'Gain', '[1 2; 3 4]', 'Multiplication', 'Matrix(K*u)');
add_block('built-in/Integrator', 'vec107/x');
add_block('built-in/Outport', 'vec107/y');
add_line('vec107', {'u/1', 'K/1', 'x/1'}, {'K/1', 'x/1', 'y/1'});
s107 = linearize('vec107');
assert(isequal(s107.B, [1 2; 3 4]) && isequal(s107.InputName, {'u(1)', 'u(2)'}) && ...
       isequal(s107.OutputName, {'y(1)', 'y(2)'}), 'sans point, les voies d''un port vecteur');
clear io107
io107(1) = linio('vec107/K', 1, 'input');
io107(2) = linio('vec107/x', 1, 'output');
s107 = linearize('vec107', io107);
assert(isequal(s107.A, zeros(2)) && isequal(s107.B, eye(2)) && isequal(s107.C, eye(2)) && ...
       isequal(s107.InputName, {'K(1)', 'K(2)'}) && isequal(s107.OutputName, {'x(1)', 'x(2)'}), ...
       'une entree vecteur ajoutee au signal');
io107(1) = linio('vec107/u', 1, 'openinput');
io107(2) = linio('vec107/K', 1, 'openoutput');
s107 = linearize('vec107', io107);
assert(isequal(s107.D, [1 2; 3 4]) && isequal(s107.B, zeros(2)), 'le gain matriciel, isole');
set_param(get_param('vec107/K', 'PortHandles').Outport(1), 'Name', 'commande');
s107 = linearize('vec107', io107);
assert(isequal(s107.OutputName, {'commande(1)', 'commande(2)'}), 'un signal nomme donne son nom');

% un modele echantillonne : DLINMOD, a la periode des blocs discrets
new_system('ech107');
add_block('built-in/Constant', 'ech107/src', 'SampleTime', '0.1');
add_block('built-in/Sum', 'ech107/s', 'Inputs', '++');
add_block('simulink/Discrete/Unit Delay', 'ech107/retard', 'SampleTime', '0.1');
add_block('built-in/Gain', 'ech107/g', 'Gain', '0.5');
add_line('ech107', {'src/1', 's/1', 'retard/1', 'g/1'}, {'s/1', 'retard/1', 'g/1', 's/2'});
clear io107
io107(1) = linio('ech107/src', 1, 'input');
io107(2) = linio('ech107/retard', 1, 'output');
s107 = linearize('ech107', io107);
assert(s107.Ts == 0.1 && max(abs([s107.A s107.B s107.C s107.D] - [0.5 1 1 0])) < 1e-9, ...
       'x+ = u + x/2, a la periode du retard');
io107(3) = linio('ech107/g', 1, 'loopbreak');
s107 = linearize('ech107', io107);
assert(s107.Ts == 0.1 && max(abs([s107.A s107.B s107.C s107.D] - [0 1 1 0])) < 1e-9, ...
       'la boucle coupee : un retard pur');
% un retard qui herite sa periode du signal la garde quand un point s'y pose
new_system('her107');
add_block('built-in/Constant', 'her107/src', 'SampleTime', '0.1');
add_block('simulink/Discrete/Unit Delay', 'her107/retard', 'SampleTime', '-1');
add_block('built-in/Gain', 'her107/g', 'Gain', '0.5');
add_block('built-in/Outport', 'her107/y');
add_line('her107', {'src/1', 'retard/1', 'g/1'}, {'retard/1', 'g/1', 'y/1'});
assert(isequal(get_param('her107/retard', 'CompiledSampleTime'), [0.1 0]), 'la periode heritee');
clear io107
io107(1) = linio('her107/src', 1, 'input');
io107(2) = linio('her107/g', 1, 'output');
s107 = linearize('her107', io107);
assert(s107.Ts == 0.1 && max(abs([s107.A s107.B s107.C s107.D] - [0 1 0.5 0])) < 1e-9, ...
       'une entree ajoutee n''entraine pas le retard a sa cadence');
io107(1).Type = 'openinput';
s107 = linearize('her107', io107);
assert(s107.Ts == 0.1 && max(abs([s107.A s107.B s107.C s107.D] - [0 1 0.5 0])) < 1e-9, ...
       'ni une coupure');
% un point qui changerait la periode d'un etat discret est refuse, plutot
% que de rendre la linearisation d'un autre modele
new_system('inf107');
add_block('built-in/Constant', 'inf107/src');
add_block('simulink/Discrete/Unit Delay', 'inf107/retard', 'SampleTime', '-1');
add_block('built-in/Outport', 'inf107/y');
add_line('inf107', {'src/1', 'retard/1'}, {'retard/1', 'y/1'});
clear io107
io107(1) = linio('inf107/src', 1, 'input');
io107(2) = linio('inf107/retard', 1, 'output');
vu107 = '';
try
    linearize('inf107', io107);
catch err
    vu107 = err.identifier;
    assert(~isempty(strfind(err.message, 'inf107/retard')), 'le refus nomme le bloc');
end
assert(strcmp(vu107, 'Simulink:Linearize:SampleTimeChanged'), ['periode changee : ' vu107]);

% ce qui se refuse
refus107 = {@() linearize('lin107', linio('lin107/absent', 1, 'input')), ...
                'Simulink:Commands:InvSimulinkObjectName'; ...
            @() linearize('lin107', linio('lin107/P', 2, 'input')), 'Simulink:Linearize:InvalidPort'; ...
            @() linearize('lin107', linio('lin107/P', 1, 'input')), 'Simulink:Linearize:NoIO'; ...
            @() linearize('lin107', linio('lin107/P', 1, 'sensitivity'), 3), ...
                'Simulink:Linearize:OperatingPointUnsupported'; ...
            @() linearize('lin107', 5), 'Simulink:Linearize:InvalidIO'; ...
            @() linearize('lin107', setfield(linio('lin107/P', 1, 'sensitivity'), 'OpenLoop', 'on')), ...
                'Simulink:Linearize:LinioType'; ...
            @() linio('lin107/P', 1, 'entree'), 'Simulink:Linearize:LinioType'; ...
            @() linio('lin107/P', 0), 'Simulink:Linearize:LinioPort'; ...
            @() linio('lin107/P', 1, 'input', 'peut-etre'), 'Simulink:Linearize:LinioOpenLoop'; ...
            @() linio(5, 1), 'Simulink:Linearize:LinioBlock'; ...
            @() linio('lin107/P', 1, 'input', 'off', 'a.b'), 'Simulink:Linearize:LinioBusElement'};
for q = 1:size(refus107, 1)
    vu107 = '';
    try
        refus107{q, 1}();
    catch err
        vu107 = err.identifier;
    end
    assert(strcmp(vu107, refus107{q, 2}), sprintf('refus %d : %s', q, vu107));
end
bdclose('all');
fprintf('linio et linearize : ok\n');

%% --------------------------------------------- 108. Les blocs mis en commentaire
% Commented vaut 'off', 'on' ou 'through'. Un bloc commenté reste dans le
% modèle — GET_PARAM le lit, FIND_SYSTEM le trouve à la demande — mais ne
% calcule plus : 'on', ce qu'il alimentait lit zéro ; 'through', chaque
% sortie rend l'entrée de même rang.
bdclose('all');
m108 = new_system('com108');
m108 = add_block(m108, 'constant', 'c', 'Value', 3);
m108 = add_block(m108, 'gain', 'g', 'Gain', 2);
m108 = add_block(m108, 'gain', 'h', 'Gain', 5);
m108 = add_block(m108, 'outport', 'y');
m108 = add_line(add_line(add_line(m108, 'c', 'g'), 'g', 'h'), 'h', 'y');
dernier108 = @(v) v(end);
fin108 = @(m) dernier108(subsref(sim(m, 'StopTime', 0.1), substruct('.', 'yout')));
assert(strcmp(get_param(m108, 'g', 'Commented'), 'off') && fin108(m108) == 30, ...
       'sans commentaire : 3 x 2 x 5');
assert(fin108(set_param(m108, 'g', 'Commented', 'through')) == 15, 'g traverse : 3 x 5');
assert(fin108(set_param(m108, 'g', 'Commented', 'on')) == 0, 'g retire : h lit zero');
assert(fin108(set_param(set_param(m108, 'g', 'Commented', 'through'), 'h', 'Commented', ...
                        'through')) == 3, 'deux blocs traverses de suite');
assert(fin108(set_param(set_param(m108, 'g', 'Commented', 'on'), 'h', 'Commented', ...
                        'through')) == 0, 'un bloc traverse derriere un bloc retire');
assert(fin108(set_param(m108, 'c', 'Commented', 'on')) == 0, 'une source retiree vaut zero');
assert(fin108(add_block(m108, 'gain', 'libre', 'Commented', 'on')) == 30, ...
       'ADD_BLOCK le pose aussi ; un bloc sans lien part sans rien changer');
sansSortie108 = sim(set_param(m108, 'y', 'Commented', 'on'), 'StopTime', 0.1);
assert(isempty(sansSortie108.yout), 'la sortie du modele, commentee, n''en est plus une');
% le modele garde le bloc : c'est le calcul qui l'ignore
commente108 = set_param(m108, 'g', 'Commented', 'on');
assert(numel(commente108.blocs) == 4 && strcmp(get_param(commente108, 'g', 'Commented'), 'on') && ...
       numel(matlibre_sl_commentes(commente108).blocs) == 4 && ...
       ~any(strcmp(cellfun(@(b) b.nom, matlibre_sl_commentes(commente108).blocs, ...
                           'UniformOutput', false), 'g')), ...
       'le bloc reste dans le modele ; un Ground le remplace au calcul');
% LINMOD le voit comme SIM
l108 = new_system('lin108');
l108 = add_block(l108, 'inport', 'u');
l108 = add_block(l108, 'gain', 'k', 'Gain', 7);
l108 = add_block(l108, 'outport', 'y');
l108 = add_line(add_line(l108, 'u', 'k'), 'k', 'y');
[~, ~, ~, D108] = linmod(l108);
[~, ~, ~, Dt108] = linmod(set_param(l108, 'k', 'Commented', 'through'));
[~, ~, ~, Do108] = linmod(set_param(l108, 'k', 'Commented', 'on'));
assert(D108 == 7 && Dt108 == 1 && Do108 == 0, 'LINMOD : 7, puis 1 traverse, puis 0 retire');

% un sous-systeme : commente entier, traverse, ou un bloc dedans
dedans108 = new_system('dedans');
dedans108 = add_block(dedans108, 'inport', 'e');
dedans108 = add_block(dedans108, 'gain', 'k', 'Gain', 10);
dedans108 = add_block(dedans108, 'bias', 'b', 'Bias', 1);
dedans108 = add_block(dedans108, 'outport', 's');
dedans108 = add_line(add_line(add_line(dedans108, 'e', 'k'), 'k', 'b'), 'b', 's');
s108 = new_system('sous108');
s108 = add_block(s108, 'constant', 'c', 'Value', 3);
s108 = add_block(s108, 'subsystem', 'S', 'Model', dedans108);
s108 = add_block(s108, 'outport', 'y');
s108 = add_line(add_line(s108, 'c', 'S'), 'S', 'y');
assert(fin108(s108) == 31, 'le sous-systeme : 3 x 10 + 1');
assert(fin108(set_param(s108, 'S', 'Commented', 'on')) == 0 && ...
       fin108(set_param(s108, 'S', 'Commented', 'through')) == 3, ...
       'le sous-systeme entier, retire puis traverse');
assert(fin108(set_param(s108, 'S/k', 'Commented', 'through')) == 4 && ...
       fin108(set_param(s108, 'S/k', 'Commented', 'on')) == 1 && ...
       fin108(set_param(s108, 'S/b', 'Commented', 'through')) == 30, ...
       'un bloc commente dans le sous-systeme');

% ce qui se refuse, en nommant le bloc
deux108 = add_block(m108, 'sum', 'somme', 'Signs', '++');
deux108 = add_line(add_line(deux108, 'c', 'somme', 1), 'g', 'somme', 2);
deux108 = add_block(deux108, 'outport', 'z', 'Port', 2);
deux108 = add_line(deux108, 'somme', 'z');
refus108 = {@() sim(set_param(deux108, 'somme', 'Commented', 'through'), 'StopTime', 0.1), ...
                'Simulink:Commands:CommentThroughPorts', 'somme'; ...
            @() sim(set_param(s108, 'S/e', 'Commented', 'on'), 'StopTime', 0.1), ...
                'Simulink:Commands:CommentPortBlock', 'e'; ...
            @() set_param(m108, 'g', 'Commented', 'oui'), 'Simulink:Data:InvalidValue', 'Commented'; ...
            @() add_block(m108, 'gain', 'x', 'Commented', 3), 'Simulink:Data:InvalidValue', 'Commented'};
for q = 1:size(refus108, 1)
    vu108 = '';
    dit108 = '';
    try
        refus108{q, 1}();
    catch err
        vu108 = err.identifier;
        dit108 = err.message;
    end
    assert(strcmp(vu108, refus108{q, 2}) && ~isempty(strfind(dit108, refus108{q, 3})), ...
           sprintf('refus %d : %s, %s', q, vu108, dit108));
end

% la forme de MATLAB : regler, simuler, chercher, enregistrer
new_system('nom108');
add_block('simulink/Sources/Constant', 'nom108/c', 'Value', '3');
add_block('simulink/Math Operations/Gain', 'nom108/g', 'Gain', '2');
add_block('simulink/Ports & Subsystems/Subsystem', 'nom108/S');
add_block('simulink/Math Operations/Gain', 'nom108/S/k', 'Gain', '10');
delete_line('nom108/S', 'In1/1', 'Out1/1');
add_line('nom108/S', {'In1/1', 'k/1'}, {'k/1', 'Out1/1'});
add_block('simulink/Sinks/Out1', 'nom108/y');
add_line('nom108', {'c/1', 'g/1', 'S/1'}, {'g/1', 'S/1', 'y/1'});
out108 = sim('nom108', 'StopTime', '0.1');
assert(out108.yout{1}.Values.Data(end) == 60, '3 x 2 x 10');
set_param('nom108/g', 'Commented', 'through');
out108 = sim('nom108', 'StopTime', '0.1');
assert(strcmp(get_param('nom108/g', 'Commented'), 'through') && ...
       out108.yout{1}.Values.Data(end) == 30, 'le gain traverse : 3 x 10');
set_param('nom108/g', 'Commented', 'off');
set_param('nom108/S', 'Commented', 'on');
out108 = sim('nom108', 'StopTime', '0.1');
assert(out108.yout{1}.Values.Data(end) == 0, 'le sous-systeme retire : la sortie lit zero');
% FIND_SYSTEM ne voit un bloc commente, et ce qu'il contient, qu'a la demande
assert(isequal(find_system('nom108'), {'nom108'; 'nom108/c'; 'nom108/g'; 'nom108/y'}) && ...
       numel(find_system('nom108', 'IncludeCommented', 'on')) == 8 && ...
       isequal(find_system('nom108', 'IncludeCommented', 'on', 'Commented', 'on'), {'nom108/S'}), ...
       'IncludeCommented');
assert(numel(Simulink.findBlocks('nom108')) == 7 && ...
       numel(Simulink.findBlocks('nom108', Simulink.FindOptions('IncludeCommented', false))) == 3, ...
       'Simulink.findBlocks les voit, sauf a dire le contraire');
% le reglage va dans le fichier, et en revient
dossier108 = tempname;
mkdir(dossier108);
save_system('nom108', fullfile(dossier108, 'nom108.slx'));
close_system('nom108', 0);
load_system(fullfile(dossier108, 'nom108.slx'));
assert(strcmp(get_param('nom108/S', 'Commented'), 'on') && ...
       strcmp(get_param('nom108/g', 'Commented'), 'off'), 'Commented, relu du fichier');
out108 = sim('nom108', 'StopTime', '0.1');
assert(out108.yout{1}.Values.Data(end) == 0, 'et le modele relu calcule de meme');
rmdir(dossier108, 's');
bdclose('all');
fprintf('blocs commentes : ok\n');

%% ------------------------- 109. Restructurer un modèle : regrouper, déplier, vider
% Simulink.BlockDiagram.createSubsystem range des blocs dans un
% sous-système neuf et rebranche les liens ; expandSubsystem fait
% l'inverse ; arrangeSystem rend la place à la mise en place automatique ;
% deleteContents et copyContentsTo... vident et remplissent. Le calcul ne
% change pas : la linéarisation du modèle le prouve à chaque étape.
bdclose('all');
new_system('rst109');
add_block('built-in/Inport', 'rst109/u');
add_block('built-in/Constant', 'rst109/c', 'Value', '2');
add_block('built-in/Sum', 'rst109/s', 'Inputs', '++');
add_block('built-in/Gain', 'rst109/g', 'Gain', '3');
add_block('built-in/Gain', 'rst109/h', 'Gain', '5');
add_block('built-in/Outport', 'rst109/y');
add_block('built-in/Outport', 'rst109/z');
add_line('rst109', {'u/1', 'c/1', 's/1', 'g/1', 'g/1', 'u/1'}, ...
         {'s/1', 's/2', 'g/1', 'y/1', 'h/1', 'z/1'});
[~, ~, ~, D109] = linmod('rst109');
assert(max(abs(D109 - [3; 1])) < 1e-9, 'avant : y = 3(u+2), z = u');
% regrouper s et g : deux entrees (u, c), une sortie (g, qui alimente y et h)
Simulink.BlockDiagram.createSubsystem([get_param('rst109/s', 'Handle'), ...
                                       get_param('rst109/g', 'Handle')]);
assert(isequal(find_system('rst109/Subsystem'), {'rst109/Subsystem'; 'rst109/Subsystem/s'; ...
       'rst109/Subsystem/g'; 'rst109/Subsystem/In1'; 'rst109/Subsystem/In2'; ...
       'rst109/Subsystem/Out1'}) && isequal(get_param('rst109/Subsystem', 'Ports'), ...
       [2 1 0 0 0 0 0 0]), 'un signal par entree, une sortie pour g');
[~, ~, ~, D109] = linmod('rst109');
assert(max(abs(D109 - [3; 1])) < 1e-9, 'regroupe : le calcul ne change pas');
Simulink.BlockDiagram.expandSubsystem('rst109/Subsystem');
assert(isequal(sort(get_param('rst109', 'Blocks')), sort({'u'; 'c'; 's'; 'g'; 'h'; 'y'; 'z'})), ...
       'deplie : les blocs reviennent, sous leur nom');
[~, ~, ~, D109] = linmod('rst109');
assert(max(abs(D109 - [3; 1])) < 1e-9, 'deplie : le calcul ne change pas');
% tout le modele, Inport et Outport compris : ils partent dedans, et des
% ports de meme nom et de meme rang les remplacent dehors
Simulink.BlockDiagram.createSubsystem(Simulink.findBlocks('rst109'), 'Name', 'tout');
assert(isequal(sort(get_param('rst109', 'Blocks')), sort({'tout'; 'u'; 'y'; 'z'})) && ...
       strcmp(get_param('rst109/y', 'Port'), '1') && strcmp(get_param('rst109/z', 'Port'), '2'), ...
       'les ports du modele gardent leur rang');
[~, ~, ~, D109] = linmod('rst109');
assert(max(abs(D109 - [3; 1])) < 1e-9, 'tout regroupe : le calcul ne change pas');
% le nom pris : le rang libre suivant, ou un refus
Simulink.BlockDiagram.createSubsystem(get_param('rst109/u', 'Handle'), 'Name', 'tout');
assert(any(strcmp(get_param('rst109', 'Blocks'), 'tout1')), 'MakeNameUnique, par defaut');
Simulink.BlockDiagram.expandSubsystem('rst109/tout1');
Simulink.BlockDiagram.expandSubsystem('rst109/tout');
[~, ~, ~, D109] = linmod('rst109');
assert(max(abs(D109 - [3; 1])) < 1e-9 && numel(get_param('rst109', 'Blocks')) == 7, ...
       'deplie deux fois : le modele de depart');
% deplier : un nom deja pris prend le rang libre suivant, les priorites partent
new_system('dep109');
add_block('built-in/Constant', 'dep109/c', 'Value', '1');
add_block('built-in/Gain', 'dep109/g', 'Gain', '7');
add_block('simulink/Ports & Subsystems/Subsystem', 'dep109/S');
delete_line('dep109/S', 'In1/1', 'Out1/1');
add_block('built-in/Gain', 'dep109/S/g', 'Gain', '2', 'Priority', '1');
add_line('dep109/S', {'In1/1', 'g/1'}, {'g/1', 'Out1/1'});
add_block('built-in/Outport', 'dep109/y');
add_line('dep109', {'c/1', 'g/1', 'S/1'}, {'g/1', 'S/1', 'y/1'});
avant109 = sim('dep109', 'StopTime', '1');
Simulink.BlockDiagram.expandSubsystem('dep109/S', 'CreateArea', 'off');
assert(isequal(sort(get_param('dep109', 'Blocks')), sort({'c'; 'g'; 'g1'; 'y'})) && ...
       strcmp(get_param('dep109/g1', 'Gain'), '2') && ...
       isempty(get_param('dep109/g1', 'Priority')), 'g devient g1, sa priorite part');
apres109 = sim('dep109', 'StopTime', '1');
assert(apres109.yout{1}.Values.Data(end) == 14 && ...
       isequal(apres109.yout{1}.Values.Data, avant109.yout{1}.Values.Data), '1 x 7 x 2, avant et apres');
% un Inport relie droit a l'Outport : la ligne traverse
new_system('tra109');
add_block('built-in/Constant', 'tra109/c', 'Value', '5');
add_block('simulink/Ports & Subsystems/Subsystem', 'tra109/S');
add_block('built-in/Outport', 'tra109/y');
add_line('tra109', {'c/1', 'S/1'}, {'S/1', 'y/1'});
Simulink.BlockDiagram.expandSubsystem('tra109/S');
assert(isequal(get_param('tra109', 'Blocks'), {'c'; 'y'}), 'les ports partent');
r109 = sim('tra109', 'StopTime', '1');
assert(r109.yout{1}.Values.Data(end) == 5, 'c va droit a y');

% arrangeSystem : la mise en place reprend la main, a ce niveau seulement
new_system('arr109');
add_block('built-in/Constant', 'arr109/c', 'Position', [300 300 330 330]);
add_block('built-in/Gain', 'arr109/g', 'Position', [20 20 50 50]);
add_block('simulink/Ports & Subsystems/Subsystem', 'arr109/S', 'Position', [100 300 140 340]);
set_param('arr109/S/In1', 'Position', [500 500 530 530]);
add_line('arr109', {'c/1', 'g/1'}, {'g/1', 'S/1'});
Simulink.BlockDiagram.arrangeSystem('arr109', 'FullLayout', 'true');
p109 = get_param('arr109/c', 'Position');
q109 = get_param('arr109/g', 'Position');
assert(p109(3) < q109(1) && isequal(get_param('arr109/S/In1', 'Position'), [500 500 530 530]), ...
       'la source a gauche ; le sous-systeme n''est pas touche');
Simulink.BlockDiagram.arrangeSystem('arr109/S');
assert(~isequal(get_param('arr109/S/In1', 'Position'), [500 500 530 530]), ...
       'range par son chemin, le sous-systeme l''est');
v109 = Simulink.BlockDiagram.arrangeSystem(add_block(new_system('val109'), 'gain', 'g', ...
                                            'Position', [1 2 3 4]));
assert(~isfield(v109.blocs{1}.parametres, 'Position'), 'un modele par valeur');

% vider, copier
new_system('src109');
add_block('built-in/Inport', 'src109/u');
add_block('built-in/Gain', 'src109/g', 'Gain', '4');
add_block('built-in/Outport', 'src109/y');
add_line('src109', {'u/1', 'g/1'}, {'g/1', 'y/1'});
new_system('cib109');
add_block('built-in/Constant', 'cib109/c', 'Value', '3');
add_block('simulink/Ports & Subsystems/Subsystem', 'cib109/S');
add_block('built-in/Outport', 'cib109/y');
add_line('cib109', {'c/1', 'S/1'}, {'S/1', 'y/1'});
Simulink.SubSystem.deleteContents('cib109/S');
assert(isequal(find_system('cib109/S'), {'cib109/S'}) && ...
       isequal(get_param('cib109/S', 'Ports'), [0 0 0 0 0 0 0 0]) && ...
       isempty(get_param('cib109', 'Lines')), 'vide : ses ports et les liens qui y tenaient partent');
Simulink.BlockDiagram.copyContentsToSubsystem('src109', 'cib109/S');
add_line('cib109', {'c/1', 'S/1'}, {'S/1', 'y/1'});
r109 = sim('cib109', 'StopTime', '1');
assert(r109.yout{1}.Values.Data(end) == 12, 'le sous-systeme rempli : 3 x 4');
set_param('src109', 'StopTime', '7');
Simulink.BlockDiagram.deleteContents('src109');
assert(isempty(get_param('src109', 'Blocks')) && strcmp(get_param('src109', 'StopTime'), '7'), ...
       'le modele vide garde sa configuration');
Simulink.SubSystem.copyContentsToBlockDiagram('cib109/S', 'src109');
[~, ~, ~, D109] = linmod('src109');
assert(D109 == 4 && numel(find_system('cib109')) == 7, 'recopie : le gain seul, l''original intact');

% ce qui se refuse, en nommant le bloc
new_system('ref109');
add_block('simulink/Ports & Subsystems/Subsystem', 'ref109/S');
add_block('simulink/Ports & Subsystems/Subsystem', 'ref109/S/T');
add_block('simulink/Ports & Subsystems/Enabled Subsystem', 'ref109/E');
add_block('simulink/Ports & Subsystems/Subsystem', 'ref109/A', 'TreatAsAtomicUnit', 'on');
add_block('simulink/Ports & Subsystems/Subsystem', 'ref109/M', 'Mask', 'on', ...
          'MaskVariables', 'k=@1;', 'MaskValueString', '2');
add_block('simulink/Ports & Subsystems/Subsystem', 'ref109/K', 'Commented', 'on');
add_block('built-in/Gain', 'ref109/g');
refus109 = {@() Simulink.BlockDiagram.expandSubsystem('ref109/E'), ...
                'Simulink:BlockDiagram:ExpandSubsystemNotAllowed', 'conditional'; ...
            @() Simulink.BlockDiagram.expandSubsystem('ref109/A'), ...
                'Simulink:BlockDiagram:ExpandSubsystemNotAllowed', 'atomic'; ...
            @() Simulink.BlockDiagram.expandSubsystem('ref109/M'), ...
                'Simulink:BlockDiagram:ExpandSubsystemNotAllowed', 'masked'; ...
            @() Simulink.BlockDiagram.expandSubsystem('ref109/K'), ...
                'Simulink:BlockDiagram:ExpandSubsystemNotAllowed', 'commented out'; ...
            @() Simulink.BlockDiagram.expandSubsystem('ref109/g'), ...
                'Simulink:BlockDiagram:ExpandSubsystemNotSubsystem', 'ref109/g'; ...
            @() Simulink.BlockDiagram.createSubsystem([get_param('ref109/g', 'Handle'), ...
                                                       get_param('ref109/S/T', 'Handle')]), ...
                'Simulink:BlockDiagram:CreateSubsystemDifferentParents', 'ref109/S/T'; ...
            @() Simulink.BlockDiagram.createSubsystem(get_param('ref109/E/Enable', 'Handle')), ...
                'Simulink:BlockDiagram:CreateSubsystemControlPort', 'Enable'; ...
            @() Simulink.BlockDiagram.createSubsystem(get_param('ref109/g', 'Handle'), ...
                'Name', 'S', 'MakeNameUnique', 'off'), 'Simulink:Commands:AddBlockCantAdd', 'S'; ...
            @() Simulink.BlockDiagram.createSubsystem(), ...
                'Simulink:BlockDiagram:CreateSubsystemNoSelection', 'selection'; ...
            @() Simulink.BlockDiagram.copyContentsToSubsystem('src109', 'cib109/S'), ...
                'Simulink:SubSystem:SubsystemNotEmpty', 'cib109/S'; ...
            @() Simulink.SubSystem.copyContentsToBlockDiagram('cib109/S', 'src109'), ...
                'Simulink:SubSystem:CopyContentsTargetNotEmpty', 'src109'; ...
            @() Simulink.BlockDiagram.copyContentsToSubsystem('ref109', 'ref109/S'), ...
                'Simulink:BlockDiagram:CopyContentsSourceContainsTarget', 'ref109'; ...
            @() Simulink.BlockDiagram.expandSubsystem('ref109/S', 'CreateArea', 'oui'), ...
                'Simulink:BlockDiagram:ExpandSubsystemArguments', 'CreateArea'};
for q = 1:size(refus109, 1)
    vu109 = '';
    dit109 = '';
    try
        refus109{q, 1}();
    catch err
        vu109 = err.identifier;
        dit109 = err.message;
    end
    assert(strcmp(vu109, refus109{q, 2}) && ~isempty(strfind(dit109, refus109{q, 3})), ...
           sprintf('refus %d : %s, %s', q, vu109, dit109));
end
bdclose('all');
fprintf('restructurer un modele : ok\n');

%% ----------------------------------------------- 110. Cas de la littérature
% Chaque fonction ajoutée depuis la section 105, éprouvée sur un cas dont
% la littérature donne le résultat ; les valeurs attendues ont été
% recoupées par un calcul indépendant (SciPy).
bdclose('all');

% A. Le moteur à courant continu de « Control Tutorials for MATLAB and
% Simulink » (Université du Michigan, DC Motor Speed) : J = 0.01, b = 0.1,
% K = 0.01, R = 1, L = 0.5. Bâti bloc par bloc sous la forme de MATLAB,
% les paramètres dans l'espace de travail du modèle. Le tutoriel donne la
% transmittance 0.01/(0.005 s^2 + 0.06 s + 0.1001), ses pôles -2.0025 et
% -9.9975, un temps de montée de 1.14 s et un temps d'établissement de
% 2.07 s.
moteur110('moteur110');
sortie110 = sim('moteur110', 'StopTime', '3');
assert(strcmp(get_param('moteur110', 'Solver'), 'VariableStepAuto'), 'le solveur de Simulink');
t110 = sortie110.yout{1}.Values.Time;
w110 = sortie110.yout{1}.Values.Data;
p110 = roots([0.005 0.06 0.1001]);
exact110 = @(t) (0.01 / 0.1001) * (1 - (p110(2) * exp(p110(1) * t) - ...
                                       p110(1) * exp(p110(2) * t)) / (p110(2) - p110(1)));
assert(max(abs(w110 - exact110(t110))) < 1e-5, 'A : la reponse indicielle, aux reglages de Simulink');
set_param('moteur110', 'RelTol', '1e-10', 'AbsTol', '1e-12');
sortie110 = sim('moteur110', 'StopTime', '3');
assert(max(abs(sortie110.yout{1}.Values.Data - exact110(sortie110.yout{1}.Values.Time))) < 1e-8, ...
       'A : la reponse indicielle, serree');
set_param('moteur110', 'Solver', 'ode4', 'FixedStep', '1e-3');
sortie110 = sim('moteur110', 'StopTime', '3');
[montee110, etablissement110] = tempsDeReponse110(sortie110.yout{1}.Values.Time, ...
                                                  sortie110.yout{1}.Values.Data, 0.01 / 0.1001);
assert(abs(montee110 - 1.1350) < 2e-3 && abs(etablissement110 - 2.0652) < 2e-3, ...
       sprintf('A : montee %.4f s, etablissement %.4f s', montee110, etablissement110));
% le tutoriel extrait le modele lineaire en remplacant l'echelon par un In1
replace_block('moteur110', 'Step', 'built-in/Inport', 'noprompt');
[A110, B110, C110, D110] = linmod('moteur110');
[num110, den110] = ss2tf(A110, B110, C110, D110);
assert(max(abs(sort(eig(A110)) - sort(p110))) < 1e-9 && ...
       max(abs(num110 / den110(1) - [0 0 2])) < 1e-9 && ...
       max(abs(den110 / den110(1) - [1 12 20.02])) < 1e-9 && ...
       abs(dcgain(ss(A110, B110, C110, D110)) - 0.01 / 0.1001) < 1e-12, ...
       'A : la transmittance du tutoriel, par LINMOD');

% B. L'oscillateur de Van der Pol, mu = 1 : son cycle limite a pour
% période 6.6632868593 et pour amplitude 2.0086198601. Deux jeux de
% configuration attachés au même modèle, un pas variable serré et un
% Runge-Kutta à pas fixe, s'activent tour à tour.
vdp110('vdp110');
precis110 = Simulink.ConfigSet;
precis110.Name = 'Precis';
set_param(precis110, 'Solver', 'ode45', 'RelTol', '1e-10', 'AbsTol', '1e-12', ...
          'MaxStep', '0.01', 'StopTime', '40');
grossier110 = copy(precis110);
grossier110.Name = 'Grossier';
set_param(grossier110, 'Solver', 'ode4', 'FixedStep', '0.1');
attachConfigSet('vdp110', precis110);
attachConfigSet('vdp110', grossier110);
setActiveConfigSet('vdp110', 'Precis');
fin110 = sim('vdp110');
[T110, A110v] = cycle110(fin110);
assert(abs(T110 - 6.6632868593) < 1e-5 && abs(A110v - 2.0086198601) < 1e-4, ...
       sprintf('B : periode %.10f, amplitude %.10f', T110, A110v));
setActiveConfigSet('vdp110', 'Grossier');
gros110 = sim('vdp110');
[Tg110, Ag110] = cycle110(gros110);
assert(numel(gros110.tout) == 401 && abs(Tg110 - 6.6632868593) < 5e-3 && ...
       abs(Ag110 - 2.0086198601) < 5e-3, ...
       sprintf('B : ode4 au pas de 0.1, periode %.6f, amplitude %.6f', Tg110, Ag110));
assert(strcmp(get_param('vdp110', 'Solver'), 'ode4') && ...
       strcmp(get_param(getConfigSet('vdp110', 'Precis'), 'Solver'), 'ode45'), ...
       'B : le jeu actif est celui que SIM applique');

% C. Ogata, « Modern Control Engineering » : G(s) = K/(s(s+1)(s+2)) en
% boucle fermée unitaire. Pour K = 1, marge de gain 6 à w = sqrt(2) rad/s
% et marge de phase 53.41 degrés à w = 0.4457 rad/s ; Routh : la boucle
% oscille pour K = 6, ses pôles en +/- j sqrt(2) et -3.
ogata110('ogata110');
L110 = linearize('ogata110', linio('ogata110/G', 1, 'looptransfer'));
[Gm110, Pm110, Wcg110, Wcp110] = margin(-L110);
assert(abs(Gm110 - 6) < 1e-6 && abs(Wcg110 - sqrt(2)) < 1e-6 && ...
       abs(Pm110 - 53.4107861777) < 1e-5 && abs(Wcp110 - 0.4457479596) < 1e-6, ...
       sprintf('C : GM %.8f a %.8f, PM %.8f a %.8f', Gm110, Wcg110, Pm110, Wcp110));
io110 = [linio('ogata110/r', 1, 'input'), linio('ogata110/G', 1, 'output')];
T110f = linearize('ogata110', io110);
pf110 = sort(eig(T110f.A));
assert(max(abs(sort(pf110) - sort(roots([1 3 2 1])))) < 1e-8, 'C : K = 1, les poles en boucle fermee');
assignin(get_param('ogata110', 'ModelWorkspace'), 'K', 6);
T110f = linearize('ogata110', io110);
pf110 = eig(T110f.A);
assert(min(abs(pf110 + 3)) < 1e-8 && min(abs(pf110 - 1i * sqrt(2))) < 1e-8 && ...
       min(abs(pf110 + 1i * sqrt(2))) < 1e-8, 'C : K = 6, des poles en +/- j sqrt(2)');
set_param('ogata110', 'RelTol', '1e-10', 'AbsTol', '1e-12', 'MaxStep', '0.01');
o110 = sim('ogata110', 'StopTime', '40');
y110 = o110.yout{1}.Values.Data - 1;
t110 = o110.yout{1}.Values.Time;
k110 = find(y110(1:end - 1) < 0 & y110(2:end) >= 0 & t110(1:end - 1) > 10);
tc110 = t110(k110) - y110(k110) .* (t110(k110 + 1) - t110(k110)) ./ (y110(k110 + 1) - y110(k110));
assert(abs(mean(diff(tc110)) - 2 * pi / sqrt(2)) < 1e-3, 'C : K = 6, la boucle oscille a 2 pi / sqrt(2)');

% D. Le régulateur de vitesse de « Control Tutorials » (Cruise Control) :
% m = 1000 kg, b = 50 N.s/m, consigne 10 m/s, PI Kp = 800, Ki = 40. Ki/Kp
% = b/m : le zéro du PI compense le pôle de la voiture, et la boucle
% fermée est exactement 10 (1 - exp(-0.8 t)). Commenter l'intégrale laisse
% le P seul, qui s'établit à 10 Kp/(b + Kp) = 9.4118 m/s ; traverser le
% capteur rend le retour unitaire.
croisiere110('croisiere110');
set_param('croisiere110', 'RelTol', '1e-10', 'AbsTol', '1e-12', 'MaxStep', '0.05');
set_param('croisiere110/capteur', 'Commented', 'through');
c110 = sim('croisiere110', 'StopTime', '20');
tc110 = c110.yout{1}.Values.Time;
assert(max(abs(c110.yout{1}.Values.Data - 10 * (1 - exp(-0.8 * tc110)))) < 1e-6, ...
       'D : le capteur traverse, la boucle PI du tutoriel');
set_param('croisiere110/Ki', 'Commented', 'on');
c110 = sim('croisiere110', 'StopTime', '20');
tc110 = c110.yout{1}.Values.Time;
assert(max(abs(c110.yout{1}.Values.Data - 10 * 800 / 850 * (1 - exp(-0.85 * tc110)))) < 1e-6 && ...
       abs(c110.yout{1}.Values.Data(end) - 9.4117647059) < 1e-6, ...
       'D : l''integrale commentee, le P seul et son erreur statique');
set_param('croisiere110/Ki', 'Commented', 'off');
set_param('croisiere110/capteur', 'Commented', 'off');
% les sorties aux instants memes ou STEP calcule
set_param('croisiere110', 'OutputOption', 'SpecifiedOutputTimes', 'OutputTimes', '0:0.01:20');
c110 = sim('croisiere110', 'StopTime', '20');
tc110 = (0:0.01:20)';
H110 = feedback(tf([800 40], [1 0]) * tf(1, [1000 50]), tf(1, [0.5 1]));
assert(isequal(size(c110.yout{1}.Values.Data), size(tc110)) && ...
       max(abs(c110.yout{1}.Values.Data - 10 * step(H110, tc110))) < 1e-6, ...
       'D : avec le capteur, la boucle que donne FEEDBACK');

% E. Le moteur de A en boucle PI, Kp = 100, Ki = 200 (Control Tutorials,
% DC Motor Speed: PID) : pôles -1.99978 et -5.00011 +/- 13.22954j,
% dépassement de 30.5 %. Les blocs du moteur se regroupent dans un
% sous-système, puis se déplient : rien ne change, que les chemins.
boucle110('boucle110');
set_param('boucle110', 'RelTol', '1e-10', 'AbsTol', '1e-12', 'MaxStep', '0.002');
avant110 = sim('boucle110', 'StopTime', '3');
blocs110 = {'somme_e', '1_L', 'i', 'R', 'Kt', 'somme_m', '1_J', 'w', 'b', 'Ke'};
Simulink.BlockDiagram.createSubsystem(cellfun(@(n) get_param(['boucle110/' n], 'Handle'), ...
                                              blocs110), 'Name', 'Moteur');
assert(isequal(get_param('boucle110/Moteur', 'Ports'), [1 1 0 0 0 0 0 0]) && ...
       numel(find_system('boucle110/Moteur', 'SearchDepth', 1)) == 13, ...
       'E : le moteur, une entree (la tension) et une sortie (la vitesse)');
groupe110 = sim('boucle110', 'StopTime', '3');
assert(isequal(groupe110.tout, avant110.tout) && ...
       max(abs(groupe110.yout{1}.Values.Data - avant110.yout{1}.Values.Data)) < 1e-12, ...
       'E : regroupe, la boucle calcule de meme');
assert(abs(max(groupe110.yout{1}.Values.Data) - 1.3049072878) < 1e-4, 'E : le depassement de 30.5 %');
T110e = linearize('boucle110', [linio('boucle110/consigne', 1, 'input'), ...
                                linio('boucle110/Moteur', 1, 'output')]);
attendus110 = [-1.9997826339; -5.0001086831 + 13.2295371096i; -5.0001086831 - 13.2295371096i];
pe110 = eig(T110e.A);
assert(all(arrayfun(@(p) min(abs(pe110 - p)), attendus110) < 1e-6), ...
       'E : les poles de la boucle, par un point pose sur le sous-systeme');
Simulink.BlockDiagram.expandSubsystem('boucle110/Moteur');
assert(isempty(setxor(get_param('boucle110', 'Blocks'), ...
                      [blocs110, {'consigne', 'erreur', 'Kp', 'integrale', 'Ki', 'u', ...
                                  'vitesse'}])), 'E : deplie, les blocs reviennent sous leur nom');
deplie110 = sim('boucle110', 'StopTime', '3');
assert(max(abs(deplie110.yout{1}.Values.Data - avant110.yout{1}.Values.Data)) < 1e-12, ...
       'E : deplie, la boucle calcule de meme');
bdclose('all');
fprintf('cas de la litterature : ok\n');

%% ------------------- 111. Nom=valeur, et les noms de Simulink.FindOptions d'aujourd'hui
% Les scripts de MATLAB récent écrivent « add_block(..., Gain="2") » et
% « Simulink.FindOptions(SearchUnderMasks="none") » : la forme nom=valeur,
% et les noms que FindOptions porte depuis R2024 — les anciens restent
% admis. Ce que MatLibre ne parcourt pas est refusé en le disant.
bdclose('all');
new_system('nv111');
add_block('built-in/Constant', 'nv111/c', Value='3');
add_block('built-in/Gain', 'nv111/g', Gain="2");
add_block('simulink/Ports & Subsystems/Subsystem', 'nv111/S');
add_block('built-in/Gain', 'nv111/S/k', Gain='3');
add_block('built-in/Outport', 'nv111/y');
add_line('nv111', {'c/1', 'g/1'}, {'g/1', 'y/1'});
set_param('nv111/g', Gain='5');
r111 = sim('nv111', StopTime="2");
assert(r111.tout(end) == 2 && r111.yout{1}.Values.Data(end) == 15, ...
       'nom=valeur dans add_block, set_param et sim');
o111 = Simulink.FindOptions(SearchDepth=1, RegExp=true);
assert(isequal(sort(getfullname(Simulink.findBlocks('nv111', 'Name', '^[cg]$', o111))), ...
               {'nv111/c'; 'nv111/g'}), 'FindOptions par nom=valeur');
o111 = Simulink.FindOptions(SearchUnderMasks="none", SearchInsideLibraryLinks=true);
assert(strcmp(o111.LookUnderMasks, 'none') && o111.FollowLinks == true, ...
       'les noms d''aujourd''hui, lus sous les anciens');
o111 = Simulink.FindOptions('LookUnderMasks', 'functional', 'FollowLinks', false);
assert(strcmp(o111.SearchUnderMasks, 'functional') && ~o111.SearchInsideLibraryLinks, ...
       'les anciens noms, lus sous ceux d''aujourd''hui');
o111 = Simulink.FindOptions(MatchFilter=@(h) strcmp(get_param(h, 'BlockType'), 'Gain') && ...
                                             strcmp(get_param(h, 'Gain'), '3'));
assert(strcmp(getfullname(Simulink.findBlocks('nv111', o111)), 'nv111/S/k'), ...
       'MatchFilter garde les blocs pour lesquels il rend vrai');
refus111 = {{'SearchInsideModelReferences', true}, 'Simulink:FindOptions:NotSupported'; ...
            {'Variants', 'ActiveVariants'}, 'Simulink:FindOptions:NotSupported'; ...
            {'SearchUnderMasks', 'dessous'}, 'Simulink:Data:InvalidValue'; ...
            {'MatchFilter', 3}, 'Simulink:FindOptions:InvalidMatchFilter'; ...
            {'Inconnue', 1}, 'Simulink:FindOptions:UnknownOption'};
for q = 1:size(refus111, 1)
    vu111 = '';
    try
        Simulink.FindOptions(refus111{q, 1}{:});
    catch err
        vu111 = err.identifier;
    end
    assert(strcmp(vu111, refus111{q, 2}), sprintf('FindOptions refuse %d : %s', q, vu111));
end
bdclose('all');
fprintf('nom=valeur et FindOptions : ok\n');

disp('simulink modeles : toutes les verifications passent');
