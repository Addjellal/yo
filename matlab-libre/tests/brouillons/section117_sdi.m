%% ----------------------------------------- 117. Le Simulation Data Inspector
% Simulink.sdi range des runs de signaux — tirés de timeseries, de
% Dataset, de sorties de SIM, de structures avec temps, de matrices — et
% les compare d'un run à l'autre, avec des tolérances absolue, relative
% et en temps, comme le Simulation Data Inspector.
bdclose('all');
Simulink.sdi.clear;
assert(Simulink.sdi.getRunCount == 0 && isempty(Simulink.sdi.getAllRunIDs), 'CLEAR : plus de run');
t117 = (0:0.1:2)';
x117 = timeseries(sin(t117), t117, 'Name', 'x');
y117 = timeseries(cos(t117), t117);
[id117, rang117, signaux117] = Simulink.sdi.createRun('premier', 'vars', x117, y117);
run117 = Simulink.sdi.getRun(id117);
assert(isa(run117, 'Simulink.sdi.Run') && strcmp(run117.Name, 'premier') && rang117 == 1 && ...
       run117.SignalCount == 2 && numel(signaux117) == 2 && run117.RunIndex == 1, ...
       'CREATERUN : un run de deux signaux');
s117 = getSignalByIndex(run117, 2);
assert(isa(s117, 'Simulink.sdi.Signal') && strcmp(s117.Name, 'y117') && s117.RunID == id117 && ...
       isequal(s117.Values.Data, cos(t117)) && s117.ID == signaux117(2), ...
       'un timeseries sans nom prend celui de sa variable');
assert(strcmp(Simulink.sdi.getSignal(signaux117(1)).Name, 'x') && ...
       numel(getSignalsByName(run117, 'x')) == 1 && isempty(getSignalIDsByName(run117, 'z')) && ...
       isequal(getAllSignalIDs(run117), signaux117), 'les signaux par leur nom, par leur identifiant');
run117.Name = 'base';
run117.Description = 'la reference';
assert(strcmp(Simulink.sdi.getRun(id117).Name, 'base') && ...
       strcmp(Simulink.sdi.getRun(id117).Description, 'la reference'), 'NAME et DESCRIPTION se posent');
add(run117, 'vars', timeseries(t117, t117, 'Name', 'rampe'));
ds117 = export(run117);
assert(run117.SignalCount == 3 && isa(ds117, 'Simulink.SimulationData.Dataset') && ...
       numElements(ds117) == 3, 'ADD ajoute un signal, EXPORT rend un Dataset');
% les autres sources
nv117 = Simulink.sdi.createRun('nv', 'namevalue', {'a', 'b'}, {x117, [t117, 2 * t117]});
assignin('base', 'vb117', y117);
base117 = Simulink.sdi.createRun('base', 'base', {'vb117'});
evalin('base', 'clear vb117');
fichier117 = [tempname() '.mat'];
f117 = x117; %#ok<NASGU>
save(fichier117, 'f117');
fi117 = Simulink.sdi.createRun('fichier', 'file', fichier117);
delete(fichier117);
assert(Simulink.sdi.getRun(nv117).SignalCount == 2 && ...
       strcmp(getSignalByIndex(Simulink.sdi.getRun(nv117), 2).Name, 'b') && ...
       Simulink.sdi.getRun(base117).SignalCount == 1 && Simulink.sdi.getRun(fi117).SignalCount == 1, ...
       '''namevalue'', ''base'' et ''file''');
dernier117 = Simulink.sdi.Run.getLatest();
assert(dernier117.ID == fi117 && Simulink.sdi.getRunCount == 4 && ...
       Simulink.sdi.getRunIDByIndex(2) == nv117, 'GETLATEST, GETRUNIDBYINDEX');
% les sorties d'une simulation : le journal des signaux, les sorties en
% matrice avec le temps, la structure avec temps
new_system('sdi117');
add_block('built-in/Sin', 'sdi117/s');
add_block('built-in/Gain', 'sdi117/g', 'Gain', '2');
add_block('built-in/Outport', 'sdi117/y');
add_line('sdi117', 's/1', 'g/1');
add_line('sdi117', 'g/1', 'y/1');
ph117 = get_param('sdi117/s', 'PortHandles');
set_param(ph117.Outport(1), 'DataLogging', 'on', 'Name', 'sinus');
set_param('sdi117', 'Solver', 'ode4', 'FixedStep', '0.01', 'StopTime', '2');
out117 = sim('sdi117');
simu117 = Simulink.sdi.createRun('simulation', 'vars', out117);
noms117 = arrayfun(@(k) getSignalByIndex(Simulink.sdi.getRun(simu117), k).Name, ...
                   1:Simulink.sdi.getRun(simu117).SignalCount, 'UniformOutput', false);
assert(any(strcmp(noms117, 'sinus')) && any(strcmp(noms117, 'yout(:,1)')), ...
       'une sortie de SIM : son journal et ses sorties');
set_param('sdi117', 'SaveFormat', 'StructureWithTime');
out117b = sim('sdi117');
struct117 = Simulink.sdi.createRun('structure', 'vars', out117b.yout);
assert(Simulink.sdi.getRun(struct117).SignalCount == 1, 'une structure avec temps');
% deux simulations, l'une au gain changé : la comparaison le voit
set_param('sdi117', 'SaveFormat', 'Array');
set_param('sdi117/g', 'Gain', '2.01');
out117c = sim('sdi117');
simu117c = Simulink.sdi.createRun('simulation 2', 'vars', out117c);
d117 = Simulink.sdi.compareRuns(simu117, simu117c);
assert(isa(d117, 'Simulink.sdi.DiffRunResult') && d117.Count == 2 && ...
       d117.Summary.WithinTolerance == 1 && d117.Summary.OutOfTolerance == 1 && ~d117.Match, ...
       'COMPARERUNS : le journal identique, la sortie au gain change');
r117 = getResultsByName(d117, 'yout(:,1)');
assert(r117.Status == Simulink.sdi.ComparisonSignalStatus.OutOfTolerance && ...
       abs(r117.MaxDifference - 0.01) < 1e-6 && isa(r117.Diff, 'timeseries'), ...
       'l''ecart maximal : 0,01 fois le sinus');
d117 = Simulink.sdi.compareRuns(simu117, simu117c, 'AbsTol', 0.02);
assert(d117.Match && d117.Summary.WithinTolerance == 2, 'une tolerance globale l''absorbe');
sr117 = Simulink.sdi.getSignal(r117.SignalID1);
sr117.RelTol = 0.01;
d117 = Simulink.sdi.compareRuns(simu117, simu117c);
assert(d117.Match, 'la tolerance relative du signal de base vaut quand rien ne la remplace');
bdclose('sdi117');
% les signaux sans pendant, vides, sans instants communs, de largeurs
% différentes ; l'interpolation qui tient la dernière valeur
a117 = Simulink.sdi.createRun('a', 'vars', timeseries(t117, t117, 'Name', 'commun'), ...
                              timeseries(t117, t117, 'Name', 'seulA'));
b117 = Simulink.sdi.createRun('b', 'vars', timeseries(t117, t117, 'Name', 'commun'), ...
                              timeseries(t117, t117, 'Name', 'seulB'));
d117 = Simulink.sdi.compareRuns(a117, b117);
assert(d117.Count == 3 && d117.Summary.Unaligned == 2 && d117.Summary.WithinTolerance == 1, ...
       'deux signaux sans pendant : Unaligned');
[~, ~, i1] = Simulink.sdi.createRun('c', 'vars', timeseries(t117, t117, 'Name', 'tot'));
[~, ~, i2] = Simulink.sdi.createRun('d', 'vars', timeseries(t117, t117 + 5, 'Name', 'tard'));
[~, ~, i3] = Simulink.sdi.createRun('e', 'vars', timeseries([t117, t117], t117, 'Name', 'deux'));
[~, ~, i4] = Simulink.sdi.createRun('f', 'vars', timeseries(zeros(0, 1), zeros(0, 1), 'Name', 'vide'));
assert(Simulink.sdi.compareSignals(i1, i2).Status == Simulink.sdi.ComparisonSignalStatus.EmptySynced && ...
       Simulink.sdi.compareSignals(i1, i3).Status == Simulink.sdi.ComparisonSignalStatus.Unsupported && ...
       Simulink.sdi.compareSignals(i1, i4).Status == Simulink.sdi.ComparisonSignalStatus.Empty, ...
       'EmptySynced, Unsupported, Empty');
marche117 = timeseries([0; 1; 1], [0; 1; 2], 'Name', 'm');
[~, ~, j1] = Simulink.sdi.createRun('g', 'vars', marche117);
[~, ~, j2] = Simulink.sdi.createRun('h', 'vars', timeseries([0; 0.5; 1; 1; 1], [0; 0.5; 1; 1.5; 2], 'Name', 'm'));
assert(Simulink.sdi.compareSignals(j1, j2).Match && ...
       ~Simulink.sdi.compareSignals(j1, j2, 'InterpMethod', 'zoh').Match, ...
       'l''interpolation lineaire, puis la tenue de la derniere valeur');
% les refus
Simulink.sdi.getSignal(i1).AbsTol = 0;
refus117 = {
    @() Simulink.sdi.getRun(999999), 'SDI:sdi:InvalidRunID'
    @() Simulink.sdi.getSignal(999999), 'SDI:sdi:InvalidSignalID'
    @() Simulink.sdi.deleteRun(999999), 'SDI:sdi:InvalidRunID'
    @() getSignalByIndex(Simulink.sdi.getRun(a117), 3), 'SDI:sdi:IndexOutOfRange'
    @() Simulink.sdi.getRunIDByIndex(0), 'SDI:sdi:IndexOutOfRange'
    @() Simulink.sdi.createRun('x', 'vars', {1, 2}), 'SDI:sdi:InvalidSourceType'
    @() Simulink.sdi.createRun('x', 'sources', 1), 'SDI:sdi:InvalidSourceType'
    @() Simulink.sdi.createRun('x', 'namevalue', {'a'}, {1, 2}), 'SDI:sdi:InvalidSourceType'
    @() Simulink.sdi.createRun('x', 'base', {'absente117'}), 'SDI:sdi:VariableNotFound'
    @() Simulink.sdi.createRun('x', 'file', '/nulle/part.mat'), 'SDI:sdi:FileNotFound'
    @() Simulink.sdi.compareRuns(a117, b117, 'AbsTol', -1), 'SDI:sdi:InvalidTolerance'
    @() Simulink.sdi.compareRuns(a117, b117, 'Couleur', 1), 'SDI:sdi:InvalidOption'
    @() Simulink.sdi.compareSignals(i1, i2, 'SyncMethod', 'moyenne'), 'SDI:sdi:InvalidValue'
    @() poserPropriete(Simulink.sdi.getSignal(i1), 'RelTol', NaN), 'SDI:sdi:InvalidTolerance'
    @() poserPropriete(Simulink.sdi.getSignal(i1), 'InterpMethod', 'cubic'), 'SDI:sdi:InvalidValue'
    @() getResultByIndex(Simulink.sdi.compareRuns(a117, b117), 4), 'SDI:sdi:IndexOutOfRange'
    };
for k = 1:size(refus117, 1)
    vu117 = '';
    try
        refus117{k, 1}();
    catch err
        vu117 = err.identifier;
    end
    assert(strcmp(vu117, refus117{k, 2}), sprintf('refus %d : %s attendu, %s rendu', k, ...
                                                  refus117{k, 2}, vu117));
end
Simulink.sdi.deleteRun(a117);
assert(~any(Simulink.sdi.getAllRunIDs == a117), 'DELETERUN');
Simulink.sdi.clear;
vu117 = '';
try
    Simulink.sdi.Run.getLatest();
catch err
    vu117 = err.identifier;
end
assert(strcmp(vu117, 'SDI:sdi:NoRuns'), 'GETLATEST sans run');

% Batterie : une base sin(t) sur [-1, 3], comparée sur [0, 2] à elle-même
% décalée de 0,1, multipliée par 1,1 ou retardée de 0,1, échantillonnée
% sur la même grille ou sur une autre, sous une tolérance absolue,
% relative ou en temps, double ou moitié de la perturbation : l'issue que
% la règle du Simulation Data Inspector donne.
tb117 = (-1:0.01:3)';
[~, ~, base117] = Simulink.sdi.createRun('base', 'vars', timeseries(sin(tb117), tb117, 'Name', 'x'));
perturbations117 = {'decalage', @(t) sin(t) + 0.1; 'gain', @(t) 1.1 * sin(t); ...
                    'retard', @(t) sin(t - 0.1)};
attendus117 = struct('decalage', [1 0 0 0 0 0], 'gain', [1 0 1 0 0 0], ...
                     'retard', [1 0 0 0 1 0]);
tolerances117 = {'AbsTol', 0.2; 'AbsTol', 0.05; 'RelTol', 0.2; 'RelTol', 0.05; ...
                 'TimeTol', 0.2; 'TimeTol', 0.05};
grilles117 = {(0:0.01:2)', (0:0.013:2)'};
nCas117 = 0;
for kP = 1:size(perturbations117, 1)
    for kG = 1:numel(grilles117)
        tg = grilles117{kG};
        [~, ~, autre] = Simulink.sdi.createRun('autre', 'vars', ...
                                               timeseries(perturbations117{kP, 2}(tg), tg, 'Name', 'x'));
        for kT = 1:size(tolerances117, 1)
            d = Simulink.sdi.compareSignals(base117, autre, tolerances117{kT, :});
            attendu = attendus117.(perturbations117{kP, 1})(kT);
            assert(d.Match == attendu, sprintf('%s, grille %d, %s = %g : %d attendu, %s rendu', ...
                                               perturbations117{kP, 1}, kG, tolerances117{kT, :}, ...
                                               attendu, char(d.Status)));
            assert(d.Sig1.Time(1) == 0 && abs(d.Sig1.Time(end) - 2) < 1e-12, ...
                   'la comparaison porte sur les instants communs, [0, 2]');
            nCas117 = nCas117 + 1;
        end
    end
end
Simulink.sdi.clear;
fprintf('Simulation Data Inspector : %d comparaisons croisees\n', nCas117);

