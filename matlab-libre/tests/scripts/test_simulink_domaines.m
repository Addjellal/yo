% test_simulink_domaines.m — le moteur de Simulink, 3/4 : sections 27 à 75 — types de
% données, bus, Stateflow, journal et parsim, variantes, Simscape, énumérations.
%
% Chaque vérification porte sur une propriété qui définit le calcul : une
% formule fermée, une invariance, un ordre de convergence mesuré, un
% message d'erreur qui nomme le bloc fautif. Les combinaisons sont
% engendrées : sources, traitements, dimensions, solveurs et périodes se
% croisent, et chaque croisement est comparé au calcul direct.
disp('--- simulink domaines ---');
% Le test, quinze mille lignes et vingt-cinq minutes d'un bloc, est coupé en
% quatre parts que la batterie fait tourner de front ; leurs fonctions d'aide
% communes vivent dans simulink/.
addpath(fullfile(fileparts(mfilename('fullpath')), 'simulink'));

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
        'from 1 to 5'
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
        'expects 1'
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
    @() sfrun(boucle, [0 0]), 'Stateflow:BoucleDeJonctions', 'form a loop'
    @() sfjunction(sfjunction(sfchart('x'), 'j'), 'j'), 'Stateflow:JonctionDouble', 'j'
    @() sfstate(sfjunction(sfchart('x'), 'j'), 'j'), 'Stateflow:EtatDouble', 'j'
    @() sffunction(sfchart('x'), 'f', 3), 'Stateflow:FonctionInvalide', 'function handle'
    @() sftruthtable(sfchart('x'), 't', {'x'}, {'y'}, {'x > 0', 'x < 0'}, 'TF', {'y=1;', 'y=2;'}), ...
        'Stateflow:TableDeVeriteInvalide', 'one per condition'
    @() sftruthtable(sfchart('x'), 't', {'x'}, {'y'}, {'x > 0'}, 'TX', {'y=1;', 'y=2;'}), ...
        'Stateflow:TableDeVeriteInvalide', 'don''t care'
    @() table.fonctions.f(1, 2), 'Stateflow:TableDeVeriteArguments', 'takes 1'
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
    @() timeseries([1 2 3], [0 2 1]), 'MATLAB:timeseries:TimeNotMonotonic', 'increasing'
    @() timeseries([1; 2; 3], [0 1]), 'MATLAB:timeseries:SizeMismatch', '2 time'
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
    @() poserProprieteSl(Simulink.Parameter, 'DataType', '12x'), ...
        'Simulink:Data:InvalidDataType', '12x'
    @() poserProprieteSl(Simulink.Parameter, 'Min', 'a'), 'Simulink:Data:InvalidMinMax', 'Min'
    @() poserProprieteSl(Simulink.Parameter, 'Value', {1}), ...
        'Simulink:Data:InvalidParameterValue', 'cell'
    @() poserProprieteSl(Simulink.Signal, 'Dimensions', 0), ...
        'Simulink:Data:InvalidDimensions', 'Dimensions'
    @() poserProprieteSl(Simulink.Signal, 'Complexity', 'imaginaire'), ...
        'Simulink:Data:InvalidValue', 'Complexity'
    @() sim(set_param(t, 'c', 'Value', 'Hors'), 1), 'Simulink:Data:ParameterOutOfRange', ...
        'typeParametre/c'
    @() sim(set_param(t, 'c', 'Value', 'Debord'), 1), 'Simulink:Data:ParameterOverflow', ...
        '-128 to 127'
    @() sim(set_param(t, 'c', 'Value', 'Alias'), 1), 'Simulink:DataType:UnknownDataType', ...
        'MonAlias'
    @() sim(set_param(t, 'c', 'Value', 'BusFaux'), 1), ...
        'Simulink:Data:ParameterTypeMismatch', 'structure'
    @() sim(gMauvaise), 'Simulink:DataStores:InvalidInitialValue', '3 element'
    @() sim(set_param(h, 'LoadInitialState', 'on', 'InitialState', [1 2])), ...
        'Simulink:SimInput:InitialStateDimensions', '2 value'
    @() set_param(h, 'FinalStateName', '1x'), 'Simulink:Config:InvalidValue', 'FinalStateName'
    @() Simulink.SimulationInput(''), 'Simulink:Simulation:InvalidModelName', 'NEW_SYSTEM'
    @() un.setVariable('1a', 3), 'Simulink:Simulation:InvalidVariableName', 'name'
    @() un.setBlockParameter('entree/g', 'Gain'), ...
        'Simulink:Simulation:InvalidNumberOfArguments', 'triplets'
    @() un.setModelParameter('StopTime'), 'Simulink:Simulation:InvalidNumberOfArguments', ...
        'pairs'
    @() un.getVariable('absente'), 'Simulink:Simulation:VariableNotFound', 'absente'
    @() un.setPreSimFcn(3), 'Simulink:Simulation:InvalidFunctionHandle', 'PreSimFcn'
    @() validate(un.setBlockParameter('entree/zz', 'Gain', '3')), ...
        'Simulink:Commands:InvSimulinkObjectName', 'entree/zz'
    @() validate(un.setBlockParameter('autre/g', 'Gain', '3')), ...
        'Simulink:Commands:InvSimulinkObjectName', 'starts with'
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
        'Simulink:Commands:SetParamInvalidValue', '''off'' or ''on'''
    @() set_param(jr, pg.Outport(1), 'Couleur', 'rouge'), 'Simulink:Commands:ParamUnknown', ...
        'Couleur'
    @() set_param(jr, pg.Inport(1), 'DataLogging', 'on'), 'Simulink:Commands:ParamReadOnly', ...
        'output port'
    @() set_param(jr, 12345.5, 'Name', 'x'), 'Simulink:Commands:InvalidPortHandle', ...
        'PortHandles'
    @() set_param(autre, pg.Outport(1), 'Name', 'x'), 'Simulink:Commands:InvalidPortHandle', ...
        'journalise'
    @() set_param(jr, pg.Outport(1), 'DataLoggingDecimation', 0), ...
        'Simulink:Commands:SetParamInvalidValue', 'integer'
    @() set_param(jr, pg.Outport(1), 'Name'), 'Simulink:Commands:SetParamArguments', 'pairs'
    @() set_param(jr, pg.Outport(1), 'DataLoggingNameMode', 'Auto'), ...
        'Simulink:Commands:SetParamInvalidValue', 'Custom'
    @() get_param(jr, pg.Outport(1)), 'Simulink:Commands:GetParamArguments', 'parameter'
    @() get_param(jr, pg.Outport(1), 'Couleur'), 'Simulink:Commands:ParamUnknown', 'Couleur'
    @() get_param(jr, 'absent', 'PortHandles'), 'Simulink:Commands:InvSimulinkObjectName', ...
        'absent'
    @() set_param(sansGain, pg.Outport(1), 'Name', 'x'), ...
        'Simulink:Commands:InvSimulinkObjectName', 'no longer has a block'
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
        'Simulink:Variants:InvalidVariantControl', '2 values'
    @() sim(set_param(va, 'V', 'VariantControlMode', 'label'), 1), ...
        'Simulink:Variants:NoActiveLabel', 'LabelModeActiveChoice'
    @() sim(set_param(va, 'V', 'VariantControlMode', 'label', 'LabelModeActiveChoice', 'x'), 1), ...
        'Simulink:Variants:InvalidLabel', '''x'''
    @() sim(set_param(set_param(va, 'V/Double', 'VariantControl', '(default)'), 'V/Triple', ...
                      'VariantControl', '(default)'), 1), 'Simulink:Variants:MultipleDefaults', ...
        'default'
    @() sim(set_param(va, 'V', 'Model', intrus), 1), ...
        'Simulink:Variants:InvalidBlockInVariant', '''g'''
    @() sim(set_param(va, 'V', 'Model', new_system('vide')), 1), ...
        'Simulink:Variants:NoVariantChoices', 'variantes/V'
    @() sim(set_param(va, 'V', 'Model', mauvaisPort), 1), 'Simulink:Variants:PortMismatch', ...
        'autre'
    @() Simulink.Variant(3), 'Simulink:Variants:InvalidCondition', 'text'
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
    @() poserProprieteSl(hwsErreurs, 'DataSource', 'Disquette'), 'Simulink:Data:InvalidValue', ...
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
        'Simulink:blocks:CombinatorialLogicRows', 'power of two'
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
    @() sim(verif, reglage{:}), 'Simulink:blocks:AssertionAssert', 'verif/cs'' at time 3'
    @() sim(set_param(verif, 'cs', 'max_included', 'off', 'max', 2), reglage{:}), ...
        'Simulink:blocks:AssertionAssert', 'verif/cs'' at time 2'
    @() sim(set_param(verif, 'cs', 'min', 3, 'max', 1), 1), ...
        'Simulink:blocks:CheckBoundsOrder', 'verif/cs'
    @() sim(ecart, reglage{:}), 'Simulink:blocks:AssertionAssert', 'ecart/cg'' at time 1.5'
    @() sim(bornes, reglage{:}), 'Simulink:blocks:AssertionAssert', 'bornes/lo'' at time 2.5'
    @() sim(dyn, reglage{:}), 'Simulink:blocks:AssertionAssert', 'dyn/cr'' at time 2.5'
    @() sim(dynEcart, reglage{:}), 'Simulink:blocks:AssertionAssert', 'dyn/cr'' at time 2'
    @() sim(dynBas, 'Solver', 'ode1', 'FixedStep', 0.25, 'StopTime', 5), ...
        'Simulink:blocks:AssertionAssert', 'dynBas/cl'' at time 1'
    @() sim(dynLarge, 1), 'Simulink:Engine:DimensionMismatch', 'min has dimensions 3'
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
rlc = versSimulink(rlc, 'VS', 'y');
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
ac = versSimulink(ac, 'VS', 'y');
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
interne = versSimulink(interne, 'VS', 'y');
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
court = versSimulink(add_block(court, 'outport', 'y'), 'VS', 'y');
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
msd = versSimulink(versSimulink(msd, 'X/1', 'v'), 'X/2', 'x');
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
rot = versPhysique(rot, 'c', 'T');
rot = add_line(rot, 'T/LConn1', 'J/LConn1');
rot = add_line(rot, 'T/RConn1', 'G/LConn1');
rot = add_line(rot, 'D/LConn1', 'J/LConn1');
rot = add_line(rot, 'D/RConn1', 'G/LConn1');
rot = add_line(rot, 'S/RConn1', 'G/LConn1');
rot = add_line(rot, 'W/LConn1', 'J/LConn1');
rot = add_line(rot, 'W/RConn1', 'G/LConn1');
rot = versSimulink(versSimulink(rot, 'W/1', 'w'), 'W/2', 'a');
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
moteur = versSimulink(versSimulink(moteur, 'W/1', 'w'), 'I', 'i');
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
th = versPhysique(versPhysique(th, 'q', 'Q'), 'ambiant', 'Ta');
th = add_line(th, 'Q/LConn1', 'G/LConn1');
th = add_line(th, 'Q/RConn1', 'M/LConn1');
th = add_line(th, 'P/LConn1', 'M/LConn1');
th = add_line(th, 'P/RConn1', 'H/LConn1');
th = add_line(th, 'H/RConn1', 'Ta/RConn1');
th = add_line(th, 'Ta/LConn1', 'G/LConn1');
th = add_line(th, 'S/RConn1', 'G/LConn1');
th = add_line(th, 'T/LConn1', 'M/LConn1');
th = add_line(th, 'T/RConn1', 'G/LConn1');
th = versSimulink(versSimulink(th, 'T', 'y'), 'P', 'perte');
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
paroi = versSimulink(paroi, 'T', 'y');
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

%% ------------------------------------ 52. Éléments solidaires, mécanismes, amplificateurs
% Deux inerties sur un même arbre, deux masses thermiques sur un même nœud,
% un ressort au bout libre : leurs états ne sont pas indépendants, et le
% réseau se réduit aux combinaisons d'états qu'il laisse libres. Le
% transformateur, le réducteur, la roue et l'essieu lient deux grandeurs à
% travers ; l'amplificateur opérationnel égale ses entrées.
arbre = new_system('arbre');
arbre = add_block(arbre, 'constant', 'c', 'Value', 1);
arbre = add_block(arbre, 'idealtorquesource', 'T');
arbre = add_block(arbre, 'inertia', 'J1', 'inertia', 0.01);
arbre = add_block(arbre, 'inertia', 'J2', 'inertia', 0.03);
arbre = add_block(arbre, 'rotationaldamper', 'D', 'D', 0.1);
arbre = add_block(arbre, 'mechanicalrotationalreference', 'G');
arbre = add_block(arbre, 'solverconfiguration', 'S');
arbre = add_block(arbre, 'idealrotationalmotionsensor', 'W');
arbre = add_block(arbre, 'outport', 'w');
arbre = add_line(versPhysique(arbre, 'c', 'T'), 'T/LConn1', 'J1/LConn1');
arbre = add_line(arbre, 'T/RConn1', 'G/LConn1');
arbre = add_line(arbre, 'J2/LConn1', 'J1/LConn1');
arbre = add_line(arbre, 'D/LConn1', 'J1/LConn1');
arbre = add_line(arbre, 'D/RConn1', 'G/LConn1');
arbre = add_line(arbre, 'S/RConn1', 'G/LConn1');
arbre = add_line(arbre, 'W/LConn1', 'J1/LConn1');
arbre = add_line(arbre, 'W/RConn1', 'G/LConn1');
arbre = versSimulink(arbre, 'W/1', 'w');
r = sim(arbre, 'Solver', 'ode45', 'StopTime', 1, 'RelTol', 1e-10, 'AbsTol', 1e-12);
assert(max(abs(r.yout - 10 * (1 - exp(-r.tout / 0.4)))) < 1e-8, ...
       'deux inerties solidaires : une seule, de 0.04 kg.m^2');
[A, B, C, D] = linmod(arbre);
assert(isequal(size(A), [2 2]) && abs(min(eig(A)) + 2.5) < 1e-9, ...
       'LINMOD : la vitesse commune et l''angle, le mode de 0.4 s');
% deux masses thermiques sur un même nœud, chauffées ensemble
chauffe = new_system('chauffe');
chauffe = add_block(chauffe, 'constant', 'q', 'Value', 10);
chauffe = add_block(chauffe, 'idealheatflowsource', 'Q');
chauffe = add_block(chauffe, 'thermalmass', 'M1', 'mass', 1, 'sp_heat', 100, 'T', 300);
chauffe = add_block(chauffe, 'thermalmass', 'M2', 'mass', 1, 'sp_heat', 300, 'T', 300);
chauffe = add_block(chauffe, 'thermalreference', 'G');
chauffe = add_block(chauffe, 'solverconfiguration', 'S');
chauffe = add_block(chauffe, 'idealtemperaturesensor', 'T');
chauffe = add_block(chauffe, 'outport', 'y');
chauffe = add_line(versPhysique(chauffe, 'q', 'Q'), 'Q/LConn1', 'G/LConn1');
chauffe = add_line(chauffe, 'Q/RConn1', 'M1/LConn1');
chauffe = add_line(chauffe, 'M2/LConn1', 'M1/LConn1');
chauffe = add_line(chauffe, 'T/LConn1', 'M1/LConn1');
chauffe = add_line(chauffe, 'T/RConn1', 'G/LConn1');
chauffe = add_line(chauffe, 'S/RConn1', 'G/LConn1');
chauffe = versSimulink(chauffe, 'T', 'y');
r = sim(chauffe, 'Solver', 'ode45', 'StopTime', 10);
assert(abs(r.yout(end) - 300.25) < 1e-9, 'deux masses sur un noeud : 100 J pour 400 J/K');
% un ressort au bout libre ne porte aucun effort
libre = new_system('libre');
libre = add_block(libre, 'constant', 'f', 'Value', 2);
libre = add_block(libre, 'idealforcesource', 'F');
libre = add_block(libre, 'mass', 'M', 'mass', 1);
libre = add_block(libre, 'translationalspring', 'K', 'spr_rate', 100);
libre = add_block(libre, 'translationalfreeend', 'L');
libre = add_block(libre, 'mechanicaltranslationalreference', 'G');
libre = add_block(libre, 'solverconfiguration', 'S');
libre = add_block(libre, 'idealtranslationalmotionsensor', 'X');
libre = add_block(add_block(libre, 'outport', 'v'), 'outport', 'x');
libre = add_line(versPhysique(libre, 'f', 'F'), 'F/LConn1', 'M/LConn1');
libre = add_line(libre, 'F/RConn1', 'G/LConn1');
libre = add_line(libre, 'K/LConn1', 'M/LConn1');
libre = add_line(libre, 'K/RConn1', 'L/LConn1');
libre = add_line(libre, 'S/RConn1', 'G/LConn1');
libre = add_line(libre, 'X/LConn1', 'M/LConn1');
libre = add_line(libre, 'X/RConn1', 'G/LConn1');
libre = versSimulink(versSimulink(libre, 'X/1', 'v'), 'X/2', 'x');
r = sim(libre, 'Solver', 'ode45', 'StopTime', 1, 'RelTol', 1e-10, 'AbsTol', 1e-12);
assert(max(abs(r.yout(:, 1) - 2 * r.tout)) < 1e-9 && max(abs(r.yout(:, 2) - r.tout .^ 2)) < 1e-9, ...
       'un ressort au bout libre : la masse accelere seule');
% deux inerties solidaires lancées à des vitesses différentes : leur
% vitesse commune conserve le moment cinétique, et un avertissement le dit
contraires = new_system('contraires');
contraires = add_block(contraires, 'inertia', 'J1', 'inertia', 1, 'w', 10);
contraires = add_block(contraires, 'inertia', 'J2', 'inertia', 3, 'w', 0);
contraires = add_block(contraires, 'mechanicalrotationalreference', 'G');
contraires = add_block(contraires, 'solverconfiguration', 'S');
contraires = add_block(contraires, 'idealrotationalmotionsensor', 'W');
contraires = add_block(contraires, 'outport', 'w');
contraires = add_line(contraires, 'J2/LConn1', 'J1/LConn1');
contraires = add_line(contraires, 'W/LConn1', 'J1/LConn1');
contraires = add_line(contraires, 'W/RConn1', 'G/LConn1');
contraires = add_line(contraires, 'S/RConn1', 'G/LConn1');
contraires = versSimulink(contraires, 'W/1', 'w');
lastwarn('');
texte52 = evalc('r = sim(contraires, 1);');
[~, identifiant] = lastwarn();
assert(~isempty(strfind(texte52, 'contraires/J2')), 'l''avertissement nomme les inerties');
assert(abs(r.yout(end) - 2.5) < 1e-12 && ...
       strcmp(identifiant, 'Simscape:Network:InconsistentInitialConditions'), ...
       'etats initiaux contradictoires : 2.5 rad/s, et un avertissement');
% des inductances couplées : un secondaire ouvert, puis chargé
couple = new_system('couple');
couple = add_block(couple, 'acvoltagesource', 'V', 'amp', 10, 'frequency', 50);
couple = add_block(couple, 'resistor', 'R1', 'R', 1);
couple = add_block(couple, 'mutualinductor', 'T', 'L1', 0.1, 'L2', 0.4, 'k', 0.8);
couple = add_block(couple, 'electricalreference', 'G');
couple = add_block(couple, 'electricalreference', 'G2');
couple = add_block(couple, 'solverconfiguration', 'S');
couple = add_block(couple, 'voltagesensor', 'V2');
couple = add_block(couple, 'voltagesensor', 'V1');
couple = add_block(add_block(couple, 'outport', 'y2'), 'outport', 'y1');
couple = add_line(couple, 'V/LConn1', 'R1/LConn1');
couple = add_line(couple, 'R1/RConn1', 'T/LConn1');
couple = add_line(couple, 'T/LConn2', 'G/LConn1');
couple = add_line(couple, 'V/RConn1', 'G/LConn1');
couple = add_line(couple, 'S/RConn1', 'G/LConn1');
couple = add_line(couple, 'T/RConn2', 'G2/LConn1');
couple = add_line(couple, 'V2/LConn1', 'T/RConn1');
couple = add_line(couple, 'V2/RConn1', 'G2/LConn1');
couple = add_line(couple, 'V1/LConn1', 'T/LConn1');
couple = add_line(couple, 'V1/RConn1', 'G/LConn1');
couple = versSimulink(versSimulink(couple, 'V2', 'y2'), 'V1', 'y1');
r = sim(couple, 'Solver', 'ode45', 'StopTime', 0.1, 'RelTol', 1e-10, 'AbsTol', 1e-12);
assert(max(abs(r.yout(:, 1) - 1.6 * r.yout(:, 2))) < 1e-9, ...
       'secondaire ouvert : v2 = M / L1 v1');
charge = add_block(couple, 'resistor', 'R2', 'R', 5);
charge = add_line(add_line(charge, 'R2/LConn1', 'T/RConn1'), 'R2/RConn1', 'G2/LConn1');
r = sim(charge, 'Solver', 'ode45', 'StopTime', 0.1, 'RelTol', 1e-10, 'AbsTol', 1e-12);
% L [i1' ; i2'] = [v - R1 i1 ; -R2 i2], v2 = -R2 i2
L = [0.1, 0.8 * 0.2; 0.8 * 0.2, 0.4];
temoin = new_system('temoin');
temoin = add_block(temoin, 'sine', 'v', 'Amplitude', 10, 'Frequency', 2 * pi * 50);
temoin = add_block(temoin, 'statespace', 'i', 'A', -L \ diag([1 5]), 'B', L \ [1; 0], ...
                   'C', [0 -5], 'D', 0);
temoin = add_block(temoin, 'outport', 'y');
temoin = add_line(add_line(temoin, 'v', 'i'), 'i', 'y');
r2 = sim(temoin, 'Solver', 'ode45', 'StopTime', 0.1, 'RelTol', 1e-10, 'AbsTol', 1e-12);
assert(abs(interp1(r.tout, r.yout(:, 1), 0.0777) - interp1(r2.tout, r2.yout, 0.0777)) < 1e-4, ...
       'secondaire charge : la tension que donnent les equations des inductances couplees');
% une source de vitesse sur une masse : il faut dériver sa commande
vitesse = new_system('vitesse');
vitesse = add_block(vitesse, 'step', 'u', 'Time', 0.1, 'After', 1);
vitesse = add_block(vitesse, 'simulinkpsconverter', 'SP');
vitesse = add_block(vitesse, 'idealtranslationalvelocitysource', 'V');
vitesse = add_block(vitesse, 'mass', 'M', 'mass', 2);
vitesse = add_block(vitesse, 'mechanicaltranslationalreference', 'G');
vitesse = add_block(vitesse, 'solverconfiguration', 'S');
vitesse = add_block(vitesse, 'idealforcesensor', 'F');
vitesse = add_block(vitesse, 'outport', 'f');
vitesse = add_line(add_line(vitesse, 'u', 'SP'), 'SP', 'V');
vitesse = add_line(vitesse, 'V/RConn1', 'G/LConn1');
vitesse = add_line(vitesse, 'V/LConn1', 'F/LConn1');
vitesse = add_line(vitesse, 'F/RConn1', 'M/LConn1');
vitesse = add_line(vitesse, 'S/RConn1', 'G/LConn1');
vitesse = versSimulink(vitesse, 'F', 'f');
filtre = set_param(vitesse, 'SP', 'FilteringAndDerivatives', ...
                   'Filter input, derivatives calculated', 'InputFilterTimeConstant', 10, ...
                   'InputFilterTimeConstant_unit', 'ms');
r = sim(filtre, 'Solver', 'ode15s', 'StopTime', 0.3, 'RelTol', 1e-8, 'AbsTol', 1e-10);
t = r.tout;
apres = t > 0.105;
assert(max(abs(r.yout(apres) - 200 * exp(-(t(apres) - 0.1) / 0.01))) < 1e-3, ...
       'une commande filtree : F = m v'', v = 1 - exp(-(t - 0.1) / 0.01)');
r = sim(set_param(vitesse, 'SP', 'FilteringAndDerivatives', ...
                  'Zero derivatives (piecewise constant)'), 0.3);
assert(max(abs(r.yout)) == 0, 'une commande constante par morceaux : sa derivee est nulle');
% transformateur, amplificateurs, réducteur, roue, inerteur, moteur linéaire
transfo = new_system('transfo');
transfo = add_block(transfo, 'dcvoltagesource', 'V', 'v0', 10);
transfo = add_block(transfo, 'idealtransformer', 'T', 'n', 2);
transfo = add_block(transfo, 'resistor', 'R', 'R', 10);
transfo = add_block(transfo, 'electricalreference', 'G');
transfo = add_block(transfo, 'electricalreference', 'G2');
transfo = add_block(transfo, 'solverconfiguration', 'S');
transfo = add_block(transfo, 'currentsensor', 'I1');
transfo = add_block(transfo, 'voltagesensor', 'V2');
transfo = add_block(add_block(transfo, 'outport', 'i1'), 'outport', 'v2');
transfo = add_line(transfo, 'V/LConn1', 'I1/LConn1');
transfo = add_line(transfo, 'I1/RConn1', 'T/LConn1');
transfo = add_line(transfo, 'T/LConn2', 'G/LConn1');
transfo = add_line(transfo, 'V/RConn1', 'G/LConn1');
transfo = add_line(transfo, 'S/RConn1', 'G/LConn1');
transfo = add_line(transfo, 'T/RConn1', 'R/LConn1');
transfo = add_line(transfo, 'R/RConn1', 'G2/LConn1');
transfo = add_line(transfo, 'T/RConn2', 'G2/LConn1');
transfo = add_line(transfo, 'V2/LConn1', 'R/LConn1');
transfo = add_line(transfo, 'V2/RConn1', 'G2/LConn1');
transfo = versSimulink(versSimulink(transfo, 'I1', 'i1'), 'V2', 'v2');
r = sim(transfo, 1);
assert(abs(r.yout(end, 1) - 0.25) < 1e-12 && abs(r.yout(end, 2) - 5) < 1e-12, ...
       'transformateur ideal : v2 = v1 / n, i1 = i2 / n');
for inverseur = [true false]
    ao = new_system('ao');
    ao = add_block(ao, 'dcvoltagesource', 'V', 'v0', 1);
    ao = add_block(ao, 'resistor', 'R1', 'R', 1, 'R_unit', 'kOhm');
    ao = add_block(ao, 'resistor', 'Rf', 'R', 10, 'R_unit', 'kOhm');
    ao = add_block(ao, 'opamp', 'A');
    ao = add_block(ao, 'electricalreference', 'G');
    ao = add_block(ao, 'solverconfiguration', 'S');
    ao = add_block(ao, 'voltagesensor', 'VS');
    ao = add_block(ao, 'outport', 'y');
    ao = add_line(ao, 'V/RConn1', 'G/LConn1');
    ao = add_line(ao, 'S/RConn1', 'G/LConn1');
    ao = add_line(ao, 'Rf/LConn1', 'A/LConn2');
    ao = add_line(ao, 'Rf/RConn1', 'A/RConn1');
    ao = add_line(ao, 'R1/RConn1', 'A/LConn2');
    if inverseur
        ao = add_line(ao, 'V/LConn1', 'R1/LConn1');
        ao = add_line(ao, 'A/LConn1', 'G/LConn1');
    else
        ao = add_line(ao, 'R1/LConn1', 'G/LConn1');
        ao = add_line(ao, 'V/LConn1', 'A/LConn1');
    end
    ao = add_line(ao, 'VS/LConn1', 'A/RConn1');
    ao = add_line(ao, 'VS/RConn1', 'G/LConn1');
    ao = versSimulink(ao, 'VS', 'y');
    r = sim(ao, 1);
    assert(abs(r.yout(end) - (inverseur * -10 + ~inverseur * 11)) < 1e-9, ...
           'amplificateur operationnel : -Rf/R1 en inverseur, 1 + Rf/R1 sinon');
end
reducteur = new_system('reducteur');
reducteur = add_block(reducteur, 'constant', 'c', 'Value', 1);
reducteur = add_block(reducteur, 'idealtorquesource', 'T');
reducteur = add_block(reducteur, 'gearbox', 'R', 'ratio', 4);
reducteur = add_block(reducteur, 'inertia', 'J', 'inertia', 0.16);
reducteur = add_block(reducteur, 'mechanicalrotationalreference', 'G');
reducteur = add_block(reducteur, 'solverconfiguration', 'S');
reducteur = add_block(reducteur, 'idealrotationalmotionsensor', 'We');
reducteur = add_block(reducteur, 'outport', 'we');
reducteur = add_line(versPhysique(reducteur, 'c', 'T'), 'T/RConn1', 'G/LConn1');
reducteur = add_line(reducteur, 'T/LConn1', 'R/LConn1');
reducteur = add_line(reducteur, 'R/RConn1', 'J/LConn1');
reducteur = add_line(reducteur, 'S/RConn1', 'G/LConn1');
reducteur = add_line(reducteur, 'We/LConn1', 'R/LConn1');
reducteur = add_line(reducteur, 'We/RConn1', 'G/LConn1');
reducteur = versSimulink(reducteur, 'We/1', 'we');
r = sim(reducteur, 'Solver', 'ode45', 'StopTime', 1);
assert(max(abs(r.yout - 100 * r.tout)) < 1e-9, ...
       'reducteur de rapport 4 : l''inertie vue de l''entree est divisee par 16');
roue = new_system('roue');
roue = add_block(roue, 'constant', 'c', 'Value', 0.5);
roue = add_block(roue, 'idealtorquesource', 'T');
roue = add_block(roue, 'wheelandaxle', 'W', 'radius', 10, 'radius_unit', 'cm');
roue = add_block(roue, 'mass', 'M', 'mass', 5);
roue = add_block(roue, 'mechanicalrotationalreference', 'GR');
roue = add_block(roue, 'mechanicaltranslationalreference', 'GT');
roue = add_block(roue, 'solverconfiguration', 'S');
roue = add_block(roue, 'idealtranslationalmotionsensor', 'X');
roue = add_block(roue, 'outport', 'v');
roue = add_line(versPhysique(roue, 'c', 'T'), 'T/RConn1', 'GR/LConn1');
roue = add_line(roue, 'T/LConn1', 'W/LConn1');
roue = add_line(roue, 'W/RConn1', 'M/LConn1');
roue = add_line(roue, 'S/RConn1', 'GR/LConn1');
roue = add_line(roue, 'X/LConn1', 'M/LConn1');
roue = add_line(roue, 'X/RConn1', 'GT/LConn1');
roue = versSimulink(roue, 'X/1', 'v');
r = sim(roue, 'Solver', 'ode45', 'StopTime', 1);
r2 = sim(set_param(roue, 'W', 'orientation', 'Drives in negative direction'), ...
         'Solver', 'ode45', 'StopTime', 1);
assert(max(abs(r.yout - r.tout)) < 1e-12 && max(abs(r2.yout + r2.tout)) < 1e-12, ...
       'roue et essieu : F = T / r, dans un sens ou dans l''autre');
inerteur = new_system('inerteur');
inerteur = add_block(inerteur, 'constant', 'f', 'Value', 3);
inerteur = add_block(inerteur, 'idealforcesource', 'F');
inerteur = add_block(inerteur, 'mass', 'M', 'mass', 1);
inerteur = add_block(inerteur, 'translationalinerter', 'B', 'B', 2);
inerteur = add_block(inerteur, 'mechanicaltranslationalreference', 'G');
inerteur = add_block(inerteur, 'solverconfiguration', 'S');
inerteur = add_block(inerteur, 'idealtranslationalmotionsensor', 'X');
inerteur = add_block(inerteur, 'outport', 'v');
inerteur = add_line(versPhysique(inerteur, 'f', 'F'), 'F/LConn1', 'M/LConn1');
inerteur = add_line(inerteur, 'F/RConn1', 'G/LConn1');
inerteur = add_line(inerteur, 'B/LConn1', 'M/LConn1');
inerteur = add_line(inerteur, 'B/RConn1', 'G/LConn1');
inerteur = add_line(inerteur, 'S/RConn1', 'G/LConn1');
inerteur = add_line(inerteur, 'X/LConn1', 'M/LConn1');
inerteur = add_line(inerteur, 'X/RConn1', 'G/LConn1');
inerteur = versSimulink(inerteur, 'X/1', 'v');
r = sim(inerteur, 'Solver', 'ode45', 'StopTime', 1);
assert(max(abs(r.yout - r.tout)) < 1e-12, 'un inerteur de 2 kg s''ajoute a la masse');
lineaire = new_system('lineaire');
lineaire = add_block(lineaire, 'dcvoltagesource', 'V', 'v0', 2);
lineaire = add_block(lineaire, 'resistor', 'R', 'R', 1);
lineaire = add_block(lineaire, 'translationalelectromechanicalconverter', 'C', 'K', 2);
lineaire = add_block(lineaire, 'translationaldamper', 'D', 'D', 4);
lineaire = add_block(lineaire, 'electricalreference', 'GE');
lineaire = add_block(lineaire, 'mechanicaltranslationalreference', 'GM');
lineaire = add_block(lineaire, 'solverconfiguration', 'S');
lineaire = add_block(lineaire, 'idealtranslationalmotionsensor', 'X');
lineaire = add_block(lineaire, 'outport', 'v');
lineaire = add_line(lineaire, 'V/LConn1', 'R/LConn1');
lineaire = add_line(lineaire, 'R/RConn1', 'C/LConn1');
lineaire = add_line(lineaire, 'C/LConn2', 'GE/LConn1');
lineaire = add_line(lineaire, 'V/RConn1', 'GE/LConn1');
lineaire = add_line(lineaire, 'S/RConn1', 'GE/LConn1');
lineaire = add_line(lineaire, 'C/RConn1', 'D/LConn1');
lineaire = add_line(lineaire, 'C/RConn2', 'GM/LConn1');
lineaire = add_line(lineaire, 'D/RConn1', 'GM/LConn1');
lineaire = add_line(lineaire, 'X/LConn1', 'D/LConn1');
lineaire = add_line(lineaire, 'X/RConn1', 'GM/LConn1');
lineaire = versSimulink(lineaire, 'X/1', 'v');
r = sim(lineaire, 1);
assert(abs(r.yout(end) - 0.5) < 1e-12, 'moteur lineaire : 2 = i + 2 v et 2 i = 4 v');
% les sources commandées, et les unités des convertisseurs
commandees = new_system('commandees');
commandees = add_block(commandees, 'dcvoltagesource', 'V', 'v0', 3);
commandees = add_block(commandees, 'resistor', 'R1', 'R', 2);
commandees = add_block(commandees, 'voltagecontrolledvoltagesource', 'E', 'K', 5);
commandees = add_block(commandees, 'currentcontrolledvoltagesource', 'H', 'K', 7);
commandees = add_block(commandees, 'resistor', 'R2', 'R', 1);
commandees = add_block(commandees, 'resistor', 'R3', 'R', 1);
commandees = add_block(commandees, 'electricalreference', 'G');
commandees = add_block(commandees, 'solverconfiguration', 'S');
commandees = add_block(commandees, 'voltagesensor', 'VE');
commandees = add_block(commandees, 'voltagesensor', 'VH');
commandees = add_block(add_block(commandees, 'outport', 'ye'), 'outport', 'yh');
commandees = add_line(commandees, 'V/LConn1', 'E/LConn1');
commandees = add_line(commandees, 'E/LConn2', 'G/LConn1');
commandees = add_line(commandees, 'V/RConn1', 'G/LConn1');
commandees = add_line(commandees, 'S/RConn1', 'G/LConn1');
commandees = add_line(commandees, 'E/RConn1', 'R2/LConn1');
commandees = add_line(commandees, 'R2/RConn1', 'G/LConn1');
commandees = add_line(commandees, 'E/RConn2', 'G/LConn1');
commandees = add_line(commandees, 'VE/LConn1', 'R2/LConn1');
commandees = add_line(commandees, 'VE/RConn1', 'G/LConn1');
commandees = add_line(commandees, 'V/LConn1', 'R1/LConn1');
commandees = add_line(commandees, 'R1/RConn1', 'H/LConn1');
commandees = add_line(commandees, 'H/LConn2', 'G/LConn1');
commandees = add_line(commandees, 'H/RConn1', 'R3/LConn1');
commandees = add_line(commandees, 'R3/RConn1', 'G/LConn1');
commandees = add_line(commandees, 'H/RConn2', 'G/LConn1');
commandees = add_line(commandees, 'VH/LConn1', 'R3/LConn1');
commandees = add_line(commandees, 'VH/RConn1', 'G/LConn1');
commandees = versSimulink(versSimulink(commandees, 'VE', 'ye'), 'VH', 'yh');
r = sim(commandees, 1);
assert(abs(r.yout(end, 1) - 15) < 1e-12 && abs(r.yout(end, 2) - 10.5) < 1e-12, ...
       'sources commandees : 5 x 3 V, et 7 Ohm x 1.5 A');
unites = new_system('unites');
unites = add_block(unites, 'constant', 'c', 'Value', 500);
unites = add_block(unites, 'simulinkpsconverter', 'SP', 'InputSignalUnit', 'mA');
unites = add_block(unites, 'controlledcurrentsource', 'I');
unites = add_block(unites, 'resistor', 'R', 'R', 4);
unites = add_block(unites, 'electricalreference', 'G');
unites = add_block(unites, 'solverconfiguration', 'S');
unites = add_block(unites, 'currentsensor', 'A');
unites = add_block(unites, 'pssimulinkconverter', 'PS', 'OutputSignalUnit', 'mA');
unites = add_block(unites, 'voltagesensor', 'VS');
unites = add_block(unites, 'pssimulinkconverter', 'PV', 'Unit', 'kV');
unites = add_block(add_block(unites, 'outport', 'i'), 'outport', 'v');
unites = add_line(add_line(unites, 'c', 'SP'), 'SP', 'I');
unites = add_line(unites, 'I/LConn1', 'G/LConn1');
unites = add_line(unites, 'I/RConn1', 'A/LConn1');
unites = add_line(unites, 'A/RConn1', 'R/LConn1');
unites = add_line(unites, 'R/RConn1', 'G/LConn1');
unites = add_line(unites, 'S/RConn1', 'G/LConn1');
unites = add_line(unites, 'VS/LConn1', 'R/LConn1');
unites = add_line(unites, 'VS/RConn1', 'G/LConn1');
unites = add_line(add_line(unites, 'A', 'PS'), 'PS', 'i');
unites = add_line(add_line(unites, 'VS', 'PV'), 'PV', 'v');
r = sim(unites, 1);
assert(abs(r.yout(end, 1) - 500) < 1e-9 && abs(r.yout(end, 2) - 0.002) < 1e-15, ...
       'unites des convertisseurs : 500 mA commandes, mesures en mA et en kV');
degres = new_system('degres');
degres = add_block(degres, 'thermalmass', 'M', 'T', 25, 'T_unit', 'degC');
degres = add_block(degres, 'thermalreference', 'G');
degres = add_block(degres, 'solverconfiguration', 'S');
degres = add_block(degres, 'idealtemperaturesensor', 'T');
degres = add_block(degres, 'perfectinsulator', 'I');
degres = add_block(degres, 'pssimulinkconverter', 'PC', 'OutputSignalUnit', 'degC', ...
                   'ApplyAffineConversion', 'on');
degres = add_block(degres, 'pssimulinkconverter', 'PK');
degres = add_block(add_block(degres, 'outport', 'c'), 'outport', 'k');
degres = add_line(degres, 'T/LConn1', 'M/LConn1');
degres = add_line(degres, 'I/LConn1', 'M/LConn1');
degres = add_line(degres, 'T/RConn1', 'G/LConn1');
degres = add_line(degres, 'S/RConn1', 'G/LConn1');
degres = add_line(add_line(degres, 'T', 'PC'), 'PC', 'c');
degres = add_line(add_line(degres, 'T', 'PK'), 'PK', 'k');
r = sim(degres, 1);
assert(abs(r.yout(end, 1) - 25) < 1e-12 && abs(r.yout(end, 2) - 298.15) < 1e-12, ...
       'une temperature rendue en degC par la conversion affine, en K sinon');
% ces blocs passent par un .slx
fichier52 = [tempname() '.slx'];
save_system(reducteur, fichier52);
r = sim(load_system(fichier52), 'Solver', 'ode45', 'StopTime', 1);
assert(max(abs(r.yout - 100 * r.tout)) < 1e-9, 'le reducteur se relit du .slx');
save_system(set_param(unites, 'SP', 'FilteringAndDerivatives', ...
                      'Filter input, derivatives calculated'), fichier52);
relu = load_system(fichier52);
r = sim(relu, 'Solver', 'ode15s', 'StopTime', 1);
assert(abs(r.yout(end, 1) - 500) < 1e-6, 'l''unite et le filtre des convertisseurs aussi');
delete(fichier52);
% ce que Simscape refuse
% un secondaire sans référence : son potentiel n'est pas déterminé
flottant52 = delete_block(transfo, 'G2');
flottant52 = add_line(add_line(flottant52, 'R/RConn1', 'T/RConn2'), 'V2/RConn1', 'T/RConn2');
refus52 = {
    @() sim(vitesse, 1), 'Simscape:Network:SingularNetwork', 'differentiated'
    @() sim(set_param(couple, 'T', 'k', 1), 1), 'Simulink:Parameters:InvParamSetting', ...
        'couple/T'
    @() sim(set_param(reducteur, 'R', 'ratio', 0), 1), ...
        'Simulink:Parameters:InvParamSetting', 'reducteur/R'
    @() sim(set_param(unites, 'SP', 'InputSignalUnit', 'furlong'), 1), ...
        'Simulink:Parameters:InvParamSetting', 'furlong'
    @() sim(set_param(unites, 'SP', 'FilteringAndDerivatives', 'filtrer'), 1), ...
        'Simulink:Parameters:InvParamSetting', 'unites/SP'
    @() sim(set_param(unites, 'SP', 'ProvidedSignals', 'Input and first derivative'), 1), ...
        'Simulink:Parameters:InvParamSetting', 'ProvidedSignals'
    @() sim(flottant52, 1), 'Simscape:Network:SingularNetwork', 'transfo/T'
    @() add_line(add_block(reducteur, 'mass', 'M'), 'R/RConn1', 'M/LConn1'), ...
        'Simulink:Commands:AddLinePhysicalDomain', 'translation'
    @() add_line(add_block(roue, 'inertia', 'J'), 'W/RConn1', 'J/LConn1'), ...
        'Simulink:Commands:AddLinePhysicalDomain', 'rotation'
    };
for k52 = 1:size(refus52, 1)
    vu = '';
    message = '';
    try
        evalc('refus52{k52, 1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, refus52{k52, 2}) && ~isempty(strfind(message, refus52{k52, 3})), ...
           sprintf('lot 36, cas %d : %s attendu, %s rendu (%s)', k52, refus52{k52, 2}, vu, ...
                   message));
end
fprintf('elements solidaires et mecanismes : %d refus nommes verifies\n', size(refus52, 1));

%% ------------------------------------------------ 53. Signaux physiques de Simscape
% Les blocs de la bibliothèque Physical Signals calculent sur des signaux
% physiques, en unités SI : un PS Gain, un PS Add, un PS Integrator
% deviennent le Gain, le Sum, l'Integrator de Simulink.
ps = new_system('ps');
ps = add_block(ps, 'step', 'u', 'Time', 0, 'After', 1);
ps = add_block(ps, 'simulinkpsconverter', 'SP');
ps = add_block(ps, 'psgain', 'K', 'Gain', 2);
ps = add_block(ps, 'psconstant', 'C', 'Constant', 500, 'Constant_unit', 'mN');
ps = add_block(ps, 'psadd', 'somme');
ps = add_block(ps, 'idealforcesource', 'F');
ps = add_block(ps, 'mass', 'M', 'mass', 1);
ps = add_block(ps, 'translationaldamper', 'D', 'D', 1);
ps = add_block(ps, 'mechanicaltranslationalreference', 'G');
ps = add_block(ps, 'solverconfiguration', 'S');
ps = add_block(ps, 'idealtranslationalmotionsensor', 'X');
ps = add_block(ps, 'psintegrator', 'I', 'InitialCondition', 10, ...
               'InitialCondition_unit', 'cm');
ps = add_block(ps, 'pssubtract', 'ecart');
ps = add_block(ps, 'psterminator', 'fin');
ps = add_block(ps, 'pssimulinkconverter', 'PX');
ps = add_block(ps, 'pssimulinkconverter', 'PE');
ps = add_block(add_block(ps, 'outport', 'x'), 'outport', 'e');
ps = add_line(add_line(ps, 'u', 'SP'), 'SP', 'K');
ps = add_line(add_line(ps, 'K', 'somme', 1), 'C', 'somme', 2);
ps = add_line(ps, 'somme', 'F');
ps = add_line(ps, 'F/LConn1', 'M/LConn1');
ps = add_line(ps, 'F/RConn1', 'G/LConn1');
ps = add_line(ps, 'D/LConn1', 'M/LConn1');
ps = add_line(ps, 'D/RConn1', 'G/LConn1');
ps = add_line(ps, 'S/RConn1', 'G/LConn1');
ps = add_line(ps, 'X/LConn1', 'M/LConn1');
ps = add_line(ps, 'X/RConn1', 'G/LConn1');
% la vitesse intégrée par le PS Integrator, et la position du capteur
ps = add_line(add_line(ps, 'X/1', 'I'), 'I', 'ecart', 1);
ps = add_line(ps, 'X/2', 'ecart', 2);
ps = add_line(add_line(ps, 'ecart', 'PE'), 'PE', 'e');
ps = add_line(add_line(ps, 'X/2', 'PX'), 'PX', 'x');
ps = add_line(ps, 'somme', 'fin');
r = sim(ps, 'Solver', 'ode45', 'StopTime', 3, 'RelTol', 1e-10, 'AbsTol', 1e-12);
t = r.tout;
% F = 2 + 0.5 = 2.5 N ; v' = 2.5 - v : x = 2.5 (t - 1 + exp(-t))
assert(max(abs(r.yout(:, 1) - 2.5 * (t - 1 + exp(-t)))) < 1e-8, ...
       'PS Gain, PS Constant en mN et PS Add commandent la force');
assert(max(abs(r.yout(:, 2) - 0.1)) < 1e-8, ...
       'le PS Integrator part de 10 cm et suit la position');
% les fonctions, les non-linéarités, l'aiguillage, le retard
fonctions = {
    'psabs', {}, @(u) abs(u)
    'pssign', {}, @(u) sign(u)
    'psceil', {}, @(u) ceil(u)
    'psfloor', {}, @(u) floor(u)
    'psround', {}, @(u) round(u)
    'psfix', {}, @(u) fix(u)
    'psmathfunction', {'Function', 'exp(u)'}, @(u) exp(u)
    'psmathfunction', {'Function', 'cos(u)'}, @(u) cos(u)
    'psmathfunction', {'Function', 'u.^2'}, @(u) u .^ 2
    'psmathfunction', {'Function', '1./u'}, @(u) 1 ./ u
    'psmathfunction', {'Function', 'u.^v', 'v', 3}, @(u) u .^ 3
    'pssaturation', {'UpperLimit', 1, 'LowerLimit', -0.5}, @(u) min(max(u, -0.5), 1)
    'psdeadzone', {'UpperLimit', 1, 'LowerLimit', -0.5}, ...
        @(u) (u >= 1) .* (u - 1) + (u <= -0.5) .* (u + 0.5)
    'psgain', {'Gain', 3, 'Gain_unit', 'mm'}, @(u) 0.003 * u
    };
for k53 = 1:size(fonctions, 1)
    f = new_system('f');
    f = add_block(f, 'ramp', 'rampe', 'Slope', 1, 'InitialOutput', -2.3);
    f = add_block(f, fonctions{k53, 1}, 'bloc', fonctions{k53, 2}{:});
    f = add_block(f, 'outport', 'y');
    f = versSimulink(versPhysique(f, 'rampe', 'bloc'), 'bloc', 'y');
    r = sim(f, 'Solver', 'ode45', 'StopTime', 4.2, 'MaxStep', 0.1);
    u = r.tout - 2.3;
    attendu = fonctions{k53, 3}(u);
    garde = abs(u) > 1e-6 & abs(u - round(u)) > 1e-6 & abs(u - round(u) - 0.5) > 1e-6 & ...
            abs(u - 1) > 1e-6 & abs(u + 0.5) > 1e-6;
    assert(max(abs(r.yout(garde) - attendu(garde))) < 1e-9, ...
           sprintf('%s %s : la fonction de son signal', fonctions{k53, 1}, ...
                   strjoin(cellfun(@num2str, fonctions{k53, 2}, 'UniformOutput', false), ' ')));
end
choix53 = new_system('choix53');
choix53 = add_block(choix53, 'constant', 'a', 'Value', 7);
choix53 = add_block(choix53, 'clock', 'horloge');
choix53 = add_block(choix53, 'constant', 'b', 'Value', -7);
choix53 = add_block(choix53, 'psswitch', 'aiguille', 'Threshold', 1);
choix53 = add_block(choix53, 'psmax', 'haut');
choix53 = add_block(choix53, 'psmin', 'bas');
choix53 = add_block(choix53, 'psconstantdelay', 'retard', 'DelayTime', 500, ...
                    'DelayTime_unit', 'ms', 'InputHistory', -1);
choix53 = add_block(choix53, 'psdivide', 'quotient');
choix53 = add_block(choix53, 'psproduct', 'produit');
choix53 = add_block(choix53, 'mux', 'tout', 'Inputs', 5);
choix53 = add_block(choix53, 'outport', 'y');
choix53 = versPhysique(choix53, 'a', 'aiguille', 1);
choix53 = versPhysique(choix53, 'horloge', 'aiguille', 2);
choix53 = versPhysique(choix53, 'b', 'aiguille', 3);
choix53 = versPhysique(versPhysique(choix53, 'horloge', 'haut', 1), 'b', 'haut', 2);
choix53 = versPhysique(versPhysique(choix53, 'horloge', 'bas', 1), 'a', 'bas', 2);
choix53 = versPhysique(choix53, 'horloge', 'retard');
choix53 = versPhysique(versPhysique(choix53, 'a', 'quotient', 1), 'b', 'quotient', 2);
choix53 = versPhysique(versPhysique(choix53, 'a', 'produit', 1), 'horloge', 'produit', 2);
for k = 1:5
    noms53 = {'aiguille', 'haut', 'bas', 'retard', 'quotient'};
    choix53 = versSimulink(choix53, noms53{k}, 'tout', k);
end
choix53 = add_line(choix53, 'tout', 'y');
r = sim(choix53, 'Solver', 'ode45', 'StopTime', 2, 'MaxStep', 0.01);
t = r.tout;
apres = t > 1.01;
avant = t < 0.99;
assert(all(r.yout(apres, 1) == 7) && all(r.yout(avant, 1) == -7), ...
       'PS Switch : I1 quand la commande atteint le seuil, I3 sinon');
assert(max(abs(r.yout(:, 2) - t)) < 1e-12 && max(abs(r.yout(:, 3) - t)) < 1e-12, ...
       'PS Max et PS Min');
tard = t > 0.51;
assert(max(abs(r.yout(tard, 4) - (t(tard) - 0.5))) < 1e-6 && all(r.yout(t < 0.49, 4) == -1), ...
       'PS Constant Delay : 500 ms, et l''historique d''entree avant');
assert(all(abs(r.yout(:, 5) + 1) < 1e-15), 'PS Divide : I1 / I2');
% un intégrateur borné, remis à zéro par un front
borne = new_system('borne');
borne = add_block(borne, 'constant', 'un', 'Value', 1);
borne = add_block(borne, 'pulsegenerator', 'remise', 'Period', 1, 'PulseWidth', 50, ...
                  'PhaseDelay', 0.5);
borne = add_block(borne, 'psintegrator', 'I', 'ExternalReset', 'Rising', ...
                  'LimitOutput', 'Upper', 'UpperLimit', 0.3);
borne = add_block(borne, 'outport', 'y');
borne = versPhysique(versPhysique(borne, 'un', 'I', 1), 'remise', 'I', 2);
borne = versSimulink(borne, 'I', 'y');
r = sim(borne, 'Solver', 'ode45', 'StopTime', 1, 'MaxStep', 0.01);
t = r.tout;
assert(max(r.yout) <= 0.3 + 1e-12 && abs(interp1(t, r.yout, 0.2) - 0.2) < 1e-9 && ...
       abs(interp1(t, r.yout, 0.6) - 0.1) < 1e-6, ...
       'PS Integrator : borne haute, remise au front montant');
% les tables : linéaires ou lisses (Akima modifié), prolongées, bornées
table53 = new_system('table53');
table53 = add_block(table53, 'ramp', 'r', 'Slope', 1, 'InitialOutput', -1);
table53 = add_block(table53, 'pslookuptable1d', 'T', 'x', [0 1 2 3], 'f', [0 1 4 9]);
table53 = add_block(table53, 'outport', 'y');
table53 = versSimulink(versPhysique(table53, 'r', 'T'), 'T', 'y');
r = sim(table53, 'Solver', 'ode45', 'StopTime', 5, 'MaxStep', 0.1);
u = r.tout - 1;
lineaire = interp1([0 1 2 3], [0 1 4 9], min(max(u, 0), 3));
lineaire(u < 0) = u(u < 0);
lineaire(u > 3) = 9 + 5 * (u(u > 3) - 3);
assert(max(abs(r.yout - lineaire)) < 1e-12, ...
       'PS Lookup Table (1D) : lineaire, prolongee par ses deux points extremes');
r = sim(set_param(table53, 'T', 'InterpolationMethod', 'Smooth', ...
                  'ExtrapolationMethod', 'Nearest'), 'Solver', 'ode45', 'StopTime', 5, ...
        'MaxStep', 0.1);
assert(max(abs(r.yout - interp1([0 1 2 3], [0 1 4 9], min(max(u, 0), 3), 'makima'))) < 1e-12, ...
       'PS Lookup Table (1D) : lisse, bornee aux valeurs du bord');
table2 = new_system('table2');
table2 = add_block(table2, 'constant', 'a', 'Value', 1.5);
table2 = add_block(table2, 'constant', 'b', 'Value', 2.5);
table2 = add_block(table2, 'pslookuptable2d', 'T', 'x1', [1 2 3], 'x2', [1 2 3 4], ...
                   'f', [1 2 3 4; 5 6 7 8; 9 10 11 12]);
table2 = add_block(table2, 'outport', 'y');
table2 = versSimulink(versPhysique(versPhysique(table2, 'a', 'T', 1), 'b', 'T', 2), 'T', 'y');
r = sim(table2, 1);
assert(abs(r.yout(end) - 4.5) < 1e-12, 'PS Lookup Table (2D) : f(x1, x2), x1 le long des lignes');
fichier53 = [tempname() '.slx'];
save_system(ps, fichier53);
r = sim(load_system(fichier53), 'Solver', 'ode45', 'StopTime', 3, 'RelTol', 1e-10, ...
        'AbsTol', 1e-12);
assert(max(abs(r.yout(:, 1) - 2.5 * (r.tout - 1 + exp(-r.tout)))) < 1e-8, ...
       'les signaux physiques se relisent du .slx');
delete(fichier53);
refus53 = {
    @() sim(set_param(ps, 'I', 'LimitOutput', 'Both', 'LimitOutputSource', 'External'), 1), ...
        'Simulink:Parameters:InvParamSetting', 'ps/I'
    @() sim(set_param(ps, 'K', 'Gain_unit', 'furlong'), 1), ...
        'Simulink:Parameters:InvParamSetting', 'furlong'
    @() set_param(ps, 'K', 'Gian', 3), 'Simulink:Commands:ParamUnknown', 'Gian'
    @() add_line(ps, 'C', 'somme', 3), 'Simulink:Commands:AddLineInvalidPort', 'somme'
    @() sim(set_param(table53, 'T', 'ExtrapolationMethod', 'Error'), 'Solver', 'ode45', ...
            'StopTime', 5), 'Simscape:Lookup:OutOfRange', 'table53/T'
    @() sim(set_param(table53, 'T', 'x', [0 2 1 3]), 1), ...
        'Simulink:Parameters:InvParamSetting', 'increasing'
    @() sim(set_param(table2, 'T', 'f', [1 2 3; 4 5 6]), 1), ...
        'Simulink:Parameters:InvParamSetting', 'table2/T'
    };
for k53 = 1:size(refus53, 1)
    vu = '';
    message = '';
    try
        evalc('refus53{k53, 1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, refus53{k53, 2}) && ~isempty(strfind(message, refus53{k53, 3})), ...
           sprintf('signaux physiques, cas %d : %s attendu, %s rendu (%s)', k53, ...
                   refus53{k53, 2}, vu, message));
end
fprintf('signaux physiques : %d refus nommes verifies\n', size(refus53, 1));

%% ------------------------------------ 54. Batterie de réseaux physiques tirés au hasard
% Des réseaux en échelle tirés au hasard — électriques, mécaniques,
% thermiques, électromécaniques (une échelle électrique qui entraîne une
% échelle en rotation), d'éléments idéaux — dont la
% transmittance se calcule par les impédances complexes, sans passer par
% la mise en équations : LINMOD doit la retrouver. Leur réponse
% indicielle, exacte par EXPM, doit sortir de SIM avec un solveur tiré au
% hasard. Puis chacun reçoit une faute d'utilisateur tirée au hasard, que
% Simulink doit refuser en nommant ce qui ne va pas.
solveurs54 = {'ode45', 'ode23', 'ode113', 'ode15s', 'ode23s', 'ode23t', 'ode23tb', ...
              'daessc', 'ode4', 'ode5', 'ode8', 'ode3'};
simulations54 = 0;
refus54 = 0;
for graine54 = 1:30
    [echelle, transmittance, description] = matlibre_essai_echelle(graine54);
    [A, B, C, D] = linmod(echelle);
    for w = [0.05 0.3 1 3 20]
        hModele = C * ((1i * w * eye(size(A, 1)) - A) \ B) + D;
        hImpedances = transmittance(1i * w);
        assert(abs(hModele - hImpedances) <= 1e-8 * max(abs(hImpedances), 1e-6), ...
               sprintf('reseau %d (%s) : la transmittance a %g rad/s', graine54, ...
                       description, w));
    end
    rng(1000 + graine54);
    solveur = solveurs54{randi(numel(solveurs54))};
    indiciel = add_line(add_block(delete_block(echelle, 'u'), 'constant', 'u', 'Value', 1), ...
                        'u', 'SP');
    nx = size(A, 1);
    if any(strcmp(solveur, {'ode4', 'ode5', 'ode8', 'ode3'}))
        pas54 = min(0.2 / max([abs(eig(A)); 0.1]), 0.01);
        r = sim(indiciel, 'Solver', solveur, 'FixedStep', pas54, 'StopTime', 3);
    else
        r = sim(indiciel, 'Solver', solveur, 'StopTime', 3, 'RelTol', 1e-9, 'AbsTol', 1e-11);
    end
    exact = zeros(size(r.tout));
    for k = 1:numel(r.tout)
        E = expm([A, B; zeros(1, nx + 1)] * r.tout(k));
        exact(k) = C * E(1:nx, nx + 1) + D;
    end
    assert(max(abs(r.yout - exact)) <= 1e-3 * max(1, max(abs(exact))), ...
           sprintf('reseau %d (%s) : la reponse indicielle par %s', graine54, description, ...
                   solveur));
    simulations54 = simulations54 + 1;
    % une faute d'utilisateur, et l'erreur qui la nomme
    nomModele = sprintf('echelle%d', graine54);
    physiques = cellfun(@(b) b.nom, echelle.blocs, 'UniformOutput', false);
    premier = physiques{find(strncmp(physiques, 'd', 1), 1)};
    typePremier = echelle.blocs{strcmp(physiques, premier)}.type;
    parametre = struct('resistor', 'R', 'inductor', 'l', 'capacitor', 'c', ...
                       'translationaldamper', 'D', 'translationalspring', 'spr_rate', ...
                       'mass', 'mass', 'conductiveheattransfer', 'th_cond', ...
                       'thermalmass', 'mass', 'rotationaldamper', 'D', ...
                       'rotationalspring', 'spr_rate', 'inertia', 'inertia');
    etranger = 'inertia';
    if ~isempty(strfind(description, 'rotation'))
        etranger = 'resistor';
    end
    fautes = {
        @() sim(add_line(delete_block(echelle, 'G'), 'S/RConn1', [premier '/LConn1']), 1), ...
            'Simscape:Network:ReferenceMissing', [nomModele '/source']
        @() sim(delete_block(echelle, 'S'), 1), ...
            'Simscape:Network:SolverConfigurationMissing', nomModele
        @() sim(delete_line(echelle, 'S/RConn1', 'G/LConn1'), 1), ...
            'Simscape:Network:SolverConfigurationMissing', [nomModele '/source']
        @() sim(add_line(add_block(echelle, 'solverconfiguration', 'S2'), 'S2/RConn1', ...
                         'G/LConn1'), 1), ...
            'Simscape:Network:MultipleSolverConfigurations', [nomModele '/S2']
        @() add_line(add_block(echelle, etranger, 'intrus'), 'intrus/LConn1', ...
                     [premier '/LConn1']), 'Simulink:Commands:AddLinePhysicalDomain', 'intrus'
        @() sim(set_param(echelle, premier, parametre.(typePremier), -1), 1), ...
            'Simulink:Parameters:InvParamSetting', [nomModele '/' premier]
        @() sim(set_param(echelle, premier, [parametre.(typePremier) '_unit'], 'furlong'), 1), ...
            'Simulink:Parameters:InvParamSetting', 'furlong'
        };
    faute = fautes(randi(size(fautes, 1)), :);
    vu = '';
    message = '';
    try
        evalc('faute{1}();');
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, faute{2}) && ~isempty(strfind(message, faute{3})), ...
           sprintf('reseau %d (%s) : %s attendu, %s rendu (%s)', graine54, description, ...
                   faute{2}, vu, message));
    refus54 = refus54 + 1;
end
fprintf('reseaux physiques tires au hasard : %d simulations, %d refus nommes\n', ...
        simulations54, refus54);

%% ----------------------------------------------------------- 55. Types énumérés
% Un signal énuméré porte un membre d'une énumération entière — dérivée de
% Simulink.IntEnumType ou d'un entier — : il se retarde, s'aiguille, se
% compare à un membre du même type et se convertit en entier, mais ne se
% calcule pas. Chaque faute est refusée en nommant le bloc.

% Enumerated Constant : SlDemoSign.Positive, d'emblée.
m55 = new_system('enumConstante');
m55 = add_block(m55, 'enumeratedconstant', 'c');
m55 = add_block(m55, 'toworkspace', 'tw', 'VariableName', 'signes55');
m55 = add_line(m55, 'c/1', 'tw/1');
sim(m55, 'StopTime', 0.05);
assert(isa(signes55, 'SlDemoSign') && all(signes55 == SlDemoSign.Positive), ...
       'enumeres : Enumerated Constant rend SlDemoSign.Positive');
m55 = set_param(m55, 'c', 'OutDataTypeStr', 'Enum: JourEssai', 'Value', 'JourEssai.Mercredi');
sim(m55, 'StopTime', 0.05);
assert(isa(signes55, 'JourEssai') && all(signes55 == JourEssai.Mercredi), ...
       'enumeres : une autre enumeration');

% Les comparaisons : deux membres d'un même type, par leurs valeurs.
m55 = new_system('enumCompare');
m55 = add_block(m55, 'constant', 'a', 'Value', 'JourEssai.Mardi');
m55 = add_block(m55, 'constant', 'b', 'Value', JourEssai.Mercredi);   % le membre même
operateurs55 = {'==', '~=', '<', '>='};
attendus55 = [0 1 1 0];
for q = 1:numel(operateurs55)
    m55 = add_block(m55, 'relational', sprintf('r%d', q), 'Operator', operateurs55{q});
    m55 = add_block(m55, 'outport', sprintf('y%d', q), 'Port', q);
    m55 = add_line(m55, 'a/1', sprintf('r%d/1', q));
    m55 = add_line(m55, 'b/1', sprintf('r%d/2', q));
    m55 = add_line(m55, sprintf('r%d/1', q), sprintf('y%d/1', q));
end
m55 = add_block(m55, 'comparetoconstant', 'cc', 'relop', '==', 'const', 'JourEssai.Mardi');
m55 = add_block(m55, 'outport', 'y5', 'Port', 5);
m55 = add_line(m55, 'a/1', 'cc/1');
m55 = add_line(m55, 'cc/1', 'y5/1');
r55 = sim(m55, 'StopTime', 0.02);
assert(isequal(double(r55.yout(1, :)), [attendus55 1]), ...
       'enumeres : ==, ~=, <, >= et Compare To Constant');

% Multiport Switch : une commande énumérée désigne ses ports par des
% membres ; des indices entiers se groupent, et le cas par défaut prend
% un port de plus.
m55 = new_system('enumAiguillage');
m55 = add_block(m55, 'constant', 'j', 'Value', 'JourEssai.Mercredi');
for q = 1:3
    m55 = add_block(m55, 'constant', sprintf('d%d', q), 'Value', 10 * q);
end
m55 = add_block(m55, 'multiportswitch', 'ms', 'DataPortOrder', 'Specify indices', ...
                'DataPortIndices', '{JourEssai.Lundi, JourEssai.Mardi, JourEssai.Mercredi}');
m55 = add_block(m55, 'outport', 'y');
m55 = add_line(m55, 'j/1', 'ms/1');
for q = 1:3
    m55 = add_line(m55, sprintf('d%d/1', q), sprintf('ms/%d', q + 1));
end
m55 = add_line(m55, 'ms/1', 'y/1');
[ne55, ns55] = matlibre_sl_ports(struct('type', 'multiportswitch', 'nom', 'ms', ...
    'parametres', struct('DataPortOrder', 'Specify indices', ...
                         'DataPortIndices', '{1, [2 3]}', ...
                         'DataPortForDefault', 'Additional data port')));
assert(ne55 == 4 && ns55 == 1, 'enumeres : la commande, deux ports de donnees, le defaut');
r55 = sim(m55, 'StopTime', 0.02);
assert(r55.yout(1) == 30, 'enumeres : Mercredi designe le troisieme port');
m55 = new_system('indicesGroupes');
m55 = add_block(m55, 'clock', 't');
m55 = add_block(m55, 'rounding', 'r', 'Operator', 'floor');
m55 = add_block(m55, 'constant', 'a', 'Value', 10);
m55 = add_block(m55, 'constant', 'b', 'Value', 20);
m55 = add_block(m55, 'constant', 'd', 'Value', -1);
m55 = add_block(m55, 'multiportswitch', 'ms', 'DataPortOrder', 'Specify indices', ...
                'DataPortIndices', '{1, [2 3]}', 'DataPortForDefault', 'Additional data port', ...
                'DiagnosticForDefault', 'None');
m55 = add_block(m55, 'outport', 'y');
m55 = add_line(m55, 't/1', 'r/1');
m55 = add_line(m55, 'r/1', 'ms/1');
m55 = add_line(m55, 'a/1', 'ms/2');
m55 = add_line(m55, 'b/1', 'ms/3');
m55 = add_line(m55, 'd/1', 'ms/4');
m55 = add_line(m55, 'ms/1', 'y/1');
m55 = set_param(m55, 'Solver', 'ode1', 'FixedStep', 1, 'StopTime', 5);
r55 = sim(m55);
assert(isequal(r55.yout(:)', [-1 10 20 20 -1 -1]), ...
       'enumeres : des indices groupes, et un port pour le cas par defaut');
% le programme engendré aiguille de même
dossier55 = tempname();
mkdir(dossier55);
ancien55 = pwd();
cd(dossier55);
matlibre_sl_ecrire(m55, 'indicesProg55.m');
rehash;
programme55 = indicesProg55(5, 1);
cd(ancien55);
rmdir(dossier55, 's');
assert(isequal(programme55.signaux.ms, r55.signaux.ms), ...
       'enumeres : le programme engendre aiguille comme SIM');
% le cas par défaut averti
m55 = set_param(m55, 'ms', 'DiagnosticForDefault', 'Warning', ...
                'DataPortForDefault', 'Last data port');
m55 = delete_line(m55, 'd/1', 'ms/4');
m55 = delete_block(m55, 'd');
lastwarn('');
r55 = sim(m55);
[~, idAvert55] = lastwarn();
assert(strcmp(idAvert55, 'Simulink:blocks:MultiPortSwitchIndexOutOfRange') && ...
       isequal(r55.yout(:)', [20 10 20 20 20 20]), ...
       'enumeres : le dernier port pour le cas par defaut, avec un avertissement');

% Switch Case : des cas qui sont des membres.
m55 = new_system('enumCas');
m55 = add_block(m55, 'constant', 'j', 'Value', 'JourEssai.Mercredi');
m55 = add_block(m55, 'switchcase', 'selon', 'CaseConditions', ...
                '{JourEssai.Lundi, [JourEssai.Mardi JourEssai.Mercredi]}', 'ShowDefaultCase', 'off');
m55 = add_line(m55, 'j', 'selon');
for q = 1:2
    branche55 = new_system(sprintf('casEnum%d', q));
    branche55 = add_block(branche55, 'constant', 'v', 'Value', 10 * q);
    branche55 = add_block(branche55, 'outport', 'y', 'Port', 1);
    branche55 = add_block(branche55, 'actionport', 'Action');
    branche55 = add_line(branche55, 'v', 'y');
    m55 = add_block(m55, 'subsystem', sprintf('c%d', q), 'Model', branche55);
    m55 = add_line(m55, sprintf('selon/%d', q), sprintf('c%d/Ifaction', q));
end
m55 = add_block(m55, 'merge', 'fusion', 'Inputs', 2);
m55 = add_line(m55, 'c1', 'fusion', 1);
m55 = add_line(m55, 'c2', 'fusion', 2);
r55 = sim(m55, 'Solver', 'ode1', 'StopTime', 0.2, 'FixedStep', 0.1);
assert(all(r55.signaux.fusion == 20), 'enumeres : Mercredi est dans le second cas');

% Data Type Conversion : d'un entier à un membre, et retour.
m55 = new_system('enumConversion');
m55 = add_block(m55, 'constant', 'n', 'Value', 'int32(10)');
m55 = add_block(m55, 'datatypeconversion', 'versEnum', 'OutDataTypeStr', 'Enum: NiveauEssai');
m55 = add_block(m55, 'datatypeconversion', 'versEntier', 'OutDataTypeStr', 'int32');
m55 = add_block(m55, 'toworkspace', 'tw', 'VariableName', 'niveaux55');
m55 = add_block(m55, 'outport', 'y');
m55 = add_line(m55, 'n/1', 'versEnum/1');
m55 = add_line(m55, 'versEnum/1', 'tw/1');
m55 = add_line(m55, 'versEnum/1', 'versEntier/1');
m55 = add_line(m55, 'versEntier/1', 'y/1');
r55 = sim(m55, 'StopTime', 0.02);
assert(isa(niveaux55, 'NiveauEssai') && niveaux55(1) == NiveauEssai.Haut && ...
       isa(r55.yout, 'int32') && r55.yout(1) == 10, 'enumeres : int32(10) est Haut, et revient');

% Une machine à états : un retard énuméré et une MATLAB Function qui rend
% l'état suivant. Dans la boucle, le retard prend le type de sa condition
% initiale.
m55 = new_system('feuTricolore');
m55 = add_block(m55, 'delay', 'etat', 'InitialCondition', 'LumiereEssai.Rouge', 'SampleTime', 1);
m55 = add_block(m55, 'matlabfunction', 'suivante', 'Script', sprintf([ ...
    'function s = suivante(e)\nswitch e\n    case LumiereEssai.Rouge\n' ...
    '        s = LumiereEssai.Vert;\n    case LumiereEssai.Vert\n' ...
    '        s = LumiereEssai.Orange;\n    otherwise\n        s = LumiereEssai.Rouge;\nend']));
m55 = add_block(m55, 'constant', 'rouge', 'Value', 'LumiereEssai.Rouge');
m55 = add_block(m55, 'relational', 'arret', 'Operator', '==');
m55 = add_block(m55, 'toworkspace', 'tw', 'VariableName', 'feux55');
m55 = add_block(m55, 'outport', 'y');
m55 = add_line(m55, 'etat/1', 'suivante/1');
m55 = add_line(m55, 'suivante/1', 'etat/1');
m55 = add_line(m55, 'etat/1', 'tw/1');
m55 = add_line(m55, 'etat/1', 'arret/1');
m55 = add_line(m55, 'rouge/1', 'arret/2');
m55 = add_line(m55, 'arret/1', 'y/1');
pe55 = get_param(m55, 'etat', 'PortHandles');
m55 = set_param(m55, pe55.Outport(1), 'Name', 'feu', 'DataLogging', 'on');
r55 = sim(m55, 'Solver', 'FixedStepDiscrete', 'StopTime', 5, 'FixedStep', 1);
cycle55 = [LumiereEssai.Rouge; LumiereEssai.Vert; LumiereEssai.Orange];
assert(isequal(feux55, [cycle55; cycle55]), 'enumeres : rouge, vert, orange, et ainsi de suite');
assert(isequal(double(r55.yout(:)'), [1 0 0 1 0 0]), 'enumeres : l''arret au rouge');
journal55 = r55.logsout.getElement('feu');
assert(isa(journal55.Values.Data, 'LumiereEssai') && ...
       isequal(journal55.Values.Data, [cycle55; cycle55]), ...
       'enumeres : le journal garde les membres');
r55 = sim(m55, 'Solver', 'FixedStepDiscrete', 'StopTime', 1, 'FixedStep', 1, ...
          'SaveFormat', 'Dataset');
assert(isa(r55.yout.getElement(1).Values.Data, 'logical'), 'enumeres : yout en Dataset');

% Un sous-système activé qui revient à sa sortie initiale : le membre par
% défaut, celui que rend getDefaultValue.
m55 = new_system('enumActive');
m55 = add_block(m55, 'pulsegenerator', 'p', 'Period', 2, 'PulseWidth', 50);
interne55 = new_system('interne55');
interne55 = add_block(interne55, 'constant', 'v', 'Value', 'LumiereEssai.Orange');
interne55 = add_block(interne55, 'outport', 'y', 'Port', 1, 'OutputWhenDisabled', 'reset');
interne55 = add_block(interne55, 'enableport', 'Enable');
interne55 = add_line(interne55, 'v', 'y');
m55 = add_block(m55, 'subsystem', 's', 'Model', interne55);
m55 = add_line(m55, 'p', 's/Enable');
m55 = add_block(m55, 'toworkspace', 'tw', 'VariableName', 'active55');
m55 = add_line(m55, 's/1', 'tw/1');
sim(m55, 'Solver', 'ode1', 'FixedStep', 0.5, 'StopTime', 3);
O55 = LumiereEssai.Orange;
V55 = LumiereEssai.Vert;
assert(isequal(active55, [O55; O55; V55; V55; O55; O55; V55]), ...
       'enumeres : a l''arret, le membre par defaut');

% Un membre donné en objet s'enregistre en texte, comme Simulink range ses
% paramètres, et se relit.
m55 = new_system('enumSauve');
m55 = add_block(m55, 'constant', 'c', 'Value', JourEssai.Mercredi);
m55 = add_block(m55, 'outport', 'y');
m55 = add_line(m55, 'c/1', 'y/1');
dossier55 = tempname();
mkdir(dossier55);
ancien55 = pwd();
cd(dossier55);
for ext55 = {'.slx', '.m'}
    save_system(m55, ['enumSauve' ext55{1}]);
    rehash;
    relu55 = load_system(['enumSauve' ext55{1}]);
    r55 = sim(relu55, 'StopTime', 0.02);
    assert(isa(r55.yout, 'JourEssai') && r55.yout(1) == JourEssai.Mercredi && ...
           strcmp(get_param(relu55, 'c', 'Value'), 'JourEssai.Mercredi'), ...
           sprintf('enumeres : le membre s''enregistre et se relit (%s)', ext55{1}));
end
cd(ancien55);
rmdir(dossier55, 's');

% Ce que Simulink refuse, et nomme.
refus55 = {
    @() enumDeux('==', 'JourEssai.Mardi', 2), 'Simulink:DataType:EnumTypeMismatch', 'deux/op'
    @() enumDeux('<', 'JourEssai.Mardi', 'NiveauEssai.Haut'), ...
        'Simulink:DataType:EnumTypeMismatch', 'Enum: NiveauEssai'
    @() enumApres('gain', {'Gain', 2}), 'Simulink:DataType:EnumTypeNotSupported', 'apres/b'
    @() enumApres('integrator', {}), 'Simulink:DataType:EnumTypeNotSupported', 'apres/b'
    @() enumApres('delay', {'SampleTime', 0.1}), 'Simulink:DataType:EnumParameterMismatch', ...
        'InitialCondition'
    @() enumApres('switchcase', {'CaseConditions', '{1, 2}'}), ...
        'Simulink:DataType:EnumTypeMismatch', 'apres/b'
    @() enumApres('datatypeconversion', {'OutDataTypeStr', 'Enum: NiveauEssai'}), ...
        'Simulink:DataType:EnumTypeMismatch', 'apres/b'
    @() enumApres('comparetoconstant', {'const', 'NiveauEssai.Bas', 'relop', '=='}), ...
        'Simulink:DataType:EnumParameterMismatch', 'NiveauEssai'
    @() sim(add_line(add_block(add_block(add_block(add_block(new_system('sw'), 'constant', ...
        'a', 'Value', 1), 'constant', 'c', 'Value', 'JourEssai.Mardi'), 'switch', 'sw'), ...
        'outport', 'y'), 'c/1', 'sw/2')), 'Simulink:DataType:EnumTypeNotSupported', 'sw/sw'
    @() sim(add_line(add_block(add_block(new_system('mx'), 'constant', 'a', 'Value', ...
        'JourEssai.Mardi'), 'mux', 'x', 'Inputs', 2), 'a/1', 'x/1')), ...
        'Simulink:DataType:EnumTypeMismatch', 'mx/x'
    @() enumSource('Value', 2, 'OutDataTypeStr', 'Enum: JourEssai'), ...
        'Simulink:DataType:EnumParameterMismatch', 'JourEssai.Lundi'
    @() enumSource('Value', 'JourEssai.Mardi', 'OutDataTypeStr', 'Enum: Inconnue'), ...
        'Simulink:DataType:EnumTypeUndefined', 'Inconnue'
    @() enumSource('Value', 'JourEssai.Mardi', 'OutDataTypeStr', 'int32'), ...
        'Simulink:DataType:EnumParameterMismatch', 'source/c'
    @() enumSource('Value', 'CouleurEssai.Rouge'), 'Simulink:DataType:EnumTypeNotInteger', ...
        'CouleurEssai'
    @() sim(add_line(add_line(add_block(add_block(add_block(new_system('gainMembre'), ...
        'constant', 'a', 'Value', 1), 'gain', 'g', 'Gain', 'JourEssai.Mardi'), 'outport', ...
        'y'), 'a/1', 'g/1'), 'g/1', 'y/1')), 'Simulink:DataType:EnumParameterMismatch', ...
        'gainMembre/g'
    @() sim(add_line(add_line(add_block(add_block(add_block(new_system('manuel'), ...
        'constant', 'a', 'Value', 'JourEssai.Mardi'), 'constant', 'b', 'Value', 2), ...
        'manualswitch', 'sw'), 'a/1', 'sw/1'), 'b/1', 'sw/2')), ...
        'Simulink:DataType:EnumTypeMismatch', 'manuel/sw'
    @() enumCommande('One-based contiguous', '{1,2}'), 'Simulink:DataType:EnumTypeMismatch', ...
        'Specify indices'
    @() enumCommande('Specify indices', '{1, 2}'), 'Simulink:DataType:EnumTypeMismatch', ...
        'DataPortIndices'
    @() enumCommande('Specify indices', '{JourEssai.Lundi, [JourEssai.Lundi JourEssai.Mardi]}'), ...
        'Simulink:blocks:MultiPortSwitchInvalidIndices', 'multi/ms'
    @() enumCommande('Specify indices', '{JourEssai.Lundi, NiveauEssai.Bas}'), ...
        'Simulink:blocks:MultiPortSwitchInvalidIndices', 'NiveauEssai'
    @() enumCommande('Specify indices', '{JourEssai.Lundi, JourEssai.Mercredi}'), ...
        'Simulink:blocks:MultiPortSwitchIndexOutOfRange', 'JourEssai.Mardi'
    @() sim(add_line(add_line(add_block(add_block(add_block(new_system('conv'), 'constant', ...
        'n', 'Value', 'int32(3)'), 'datatypeconversion', 'e', 'OutDataTypeStr', ...
        'Enum: NiveauEssai'), 'outport', 'y'), 'n/1', 'e/1'), 'e/1', 'y/1'), 'StopTime', 0.02), ...
        'Simulink:DataType:EnumInvalidValue', 'conv/e'
    };
for kE = 1:size(refus55, 1)
    vu = '';
    message = '';
    try
        refus55{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, refus55{kE, 2}) && ~isempty(strfind(message, refus55{kE, 3})), ...
           sprintf('types enumeres, cas %d : %s attendu, %s rendu (%s)', kE, ...
                   refus55{kE, 2}, vu, message));
end
fprintf('types enumeres : %d refus nommes verifies\n', size(refus55, 1));

%% ------------------------------- 56. Batterie croisée des blocs et des types
% Chaque type de bloc du catalogue, nourri de chacun des types de données
% — double, single, entiers, booléen, virgule fixe, énuméré, complexe —,
% se simule ou est refusé par une erreur qui nomme le bloc, jamais par une
% erreur interne. Là où il se simule, la classe de sa sortie suit les
% règles de Simulink : un aiguillage, un retard, une conversion de signal
% rendent le type de leur entrée ; un calcul garde un entier ou une virgule
% fixe et fait d'un booléen un double ; une comparaison rend un booléen ;
% une fonction en virgule flottante garde la simple précision et refuse
% un entier ; un bloc de signaux physiques refuse un signal de Simulink.
genres56 = {'double', '0.5', 'double'; 'single', 'single(0.5)', 'single'; ...
            'int8', 'int8(3)', 'int8'; 'uint16', 'uint16(3)', 'uint16'; ...
            'int32', 'int32(-3)', 'int32'; 'boolean', 'true', 'logical'; ...
            'fixdt', 'fi(0.5, 1, 16, 8)', 'embedded.fi'; ...
            'enum', 'JourEssai.Mardi', 'JourEssai'; 'complexe', '0.5 + 0.25i', 'double'};
nG56 = size(genres56, 1);
catalogue56 = matlibre_sl_catalogue();
types56 = {};
for kT = 1:numel(catalogue56)
    if ~strcmp(catalogue56(kT).famille, 'Interne')
        types56{end + 1} = catalogue56(kT).type; %#ok<SAGROW>
    end
end
% pour chaque type de bloc et chaque genre : la classe de la sortie, ou
% l'identifiant du refus
classes56 = containers.Map();
refus56 = containers.Map();
nSimules56 = 0;
for kT = 1:numel(types56)
    for kG = 1:nG56
        m56 = batterieType(types56{kT}, genres56{kG, 2});
        cle = [types56{kT} '|' genres56{kG, 1}];
        try
            r56 = [];
            evalc('r56 = sim(m56, ''Solver'', ''ode1'', ''FixedStep'', 0.1, ''StopTime'', 0.3);');
            nSimules56 = nSimules56 + 1;
            classe = '';
            if isfield(r56, 'yout') && ~isempty(r56.yout)
                classe = class(r56.yout);
                if isnumeric(r56.yout) && ~isreal(r56.yout)
                    classe = [classe ' complexe'];
                end
            end
            classes56(cle) = classe;
        catch err
            id = err.identifier;
            assert((strncmp(id, 'Simulink:', 9) || strncmp(id, 'Stateflow:', 10) || ...
                    strncmp(id, 'Simscape:', 9)) && ~isempty(strfind(err.message, 'bt/')), ...
                   sprintf('%s sur un %s : erreur interne %s : %s', types56{kT}, ...
                           genres56{kG, 1}, id, err.message));
            refus56(cle) = id;
        end
    end
end
% les règles, genre par genre ; « = » : la classe de l'entrée, « - » : un
% refus, quel qu'il soit
attendu56 = @(type, genre) [type '|' genre];
passe56 = {'zoh', 'memory', 'delay', 'ratetransition', 'signalconversion', ...
           'signalspecification', 'reshape', 'mux', 'concatenate', 'manualswitch', 'outport', ...
           'ic', 'selector', 'merge'};
for kT = 1:numel(passe56)
    for kG = 1:nG56
        cle = attendu56(passe56{kT}, genres56{kG, 1});
        if strcmp(genres56{kG, 1}, 'enum') && any(strcmp(passe56{kT}, {'memory', 'delay', 'ic'}))
            % leur condition initiale numérique ne vaut pas pour un membre
            assert(isKey(refus56, cle) && strcmp(refus56(cle), ...
                   'Simulink:DataType:EnumParameterMismatch'), ...
                   sprintf('%s : une condition initiale numerique sur un membre', cle));
            continue
        end
        vu = '';
        if isKey(classes56, cle), vu = classes56(cle); end
        voulu = genres56{kG, 3};
        if strcmp(genres56{kG, 1}, 'complexe'), voulu = 'double complexe'; end
        assert(strcmp(vu, voulu), sprintf('%s : %s attendu, %s rendu', cle, voulu, vu));
    end
end
calcul56 = {'gain', 'sum', 'product', 'abs', 'unaryminus', 'bias', 'sign', 'rounding', ...
            'saturation', 'deadzone', 'quantizer', 'difference', 'ratelimiter', 'backlash'};
for kT = 1:numel(calcul56)
    for kG = 1:7
        cle = attendu56(calcul56{kT}, genres56{kG, 1});
        voulu = genres56{kG, 3};
        if strcmp(genres56{kG, 1}, 'boolean'), voulu = 'double'; end
        vu = '';
        if isKey(classes56, cle), vu = classes56(cle); end
        assert(strcmp(vu, voulu), sprintf('%s : %s attendu, %s rendu', cle, voulu, vu));
    end
    cle = attendu56(calcul56{kT}, 'enum');
    assert(isKey(refus56, cle) && strcmp(refus56(cle), 'Simulink:DataType:EnumTypeNotSupported'), ...
           sprintf('%s : un calcul refuse un membre', cle));
end
comparaison56 = {'relational', 'comparetoconstant', 'comparetozero', 'logic', 'detectchange', ...
                 'detectincrease', 'detectdecrease', 'intervaltest'};
for kT = 1:numel(comparaison56)
    for kG = 1:7
        cle = attendu56(comparaison56{kT}, genres56{kG, 1});
        vu = '';
        if isKey(classes56, cle), vu = classes56(cle); end
        assert(strcmp(vu, 'logical'), sprintf('%s : logical attendu, %s rendu', cle, vu));
    end
end
assert(strcmp(classes56('relational|enum'), 'logical'), 'deux membres se comparent');
for type = {'trigonometry', 'polynomial', 'math', 'sqrt'}
    assert(strcmp(classes56([type{1} '|double']), 'double') && ...
           strcmp(classes56([type{1} '|single']), 'single'), ...
           sprintf('%s garde la simple precision', type{1}));
end
for type = {'trigonometry', 'polynomial'}
    for kG = 3:7
        cle = attendu56(type{1}, genres56{kG, 1});
        assert(isKey(refus56, cle) && strcmp(refus56(cle), ...
               'Simulink:DataType:InputPortDataTypeMismatch'), ...
               sprintf('%s : un calcul en virgule flottante seulement', cle));
    end
end
for kG = 3:7
    cle = attendu56('magnitudeangletocomplex', genres56{kG, 1});
    assert(isKey(refus56, cle) && strcmp(refus56(cle), ...
           'Simulink:DataType:InputPortDataTypeMismatch'), sprintf('%s : refuse', cle));
end
assert(strcmp(refus56('realimagtocomplex|fixdt'), 'Simulink:DataType:InputPortDataTypeMismatch'), ...
       'pas de complexe a virgule fixe');
assert(strcmp(classes56('realimagtocomplex|single'), 'single complexe'), ...
       'Real-Imag to Complex en simple precision');
signauxPhysiques56 = {'psgain', 'psadd', 'psabs', 'psintegrator', 'psswitch', ...
                      'pslookuptable1d', 'pssimulinkconverter'};
for kT = 1:numel(signauxPhysiques56)
    for kG = 1:nG56
        cle = attendu56(signauxPhysiques56{kT}, genres56{kG, 1});
        assert(isKey(refus56, cle) && strcmp(refus56(cle), ...
               'Simscape:Network:SimulinkToPhysicalSignal'), ...
               sprintf('%s : un signal de Simulink n''entre pas dans un port physique', cle));
    end
end
for type = {'psconstant', 'simulinkpsconverter'}
    cle = attendu56(type{1}, 'double');
    assert(isKey(refus56, cle) && strcmp(refus56(cle), ...
           'Simscape:Network:PhysicalSignalToSimulink'), ...
           sprintf('%s : un signal physique ne sort pas vers Simulink sans convertisseur', cle));
end
fprintf('blocs et types : %d simulations, %d refus nommes\n', nSimules56, refus56.Count);

% Un signal physique qui passe les ports d'un sous-système reste physique :
% il ne se lit pas hors du réseau sans PS-Simulink Converter.
dedans56 = new_system('dedans56');
dedans56 = add_block(dedans56, 'psconstant', 'k', 'Constant', 2);
dedans56 = add_block(dedans56, 'outport', 's');
dedans56 = add_line(dedans56, 'k', 's');
m56 = new_system('dehors56');
m56 = add_block(m56, 'subsystem', 'sous', 'Model', dedans56);
m56 = add_block(m56, 'gain', 'g', 'Gain', 3);
m56 = add_block(m56, 'outport', 'y');
m56 = add_line(add_line(m56, 'sous/1', 'g/1'), 'g/1', 'y/1');
vu = '';
try
    sim(m56, 1);
catch err
    vu = err.identifier;
    message = err.message;
end
assert(strcmp(vu, 'Simscape:Network:PhysicalSignalToSimulink') && ...
       ~isempty(strfind(message, 'dehors56/sous/k')) && ~isempty(strfind(message, 'dehors56/g')), ...
       'le signal physique traverse le sous-systeme, et le Gain le refuse');
m56 = add_block(delete_line(m56, 'sous/1', 'g/1'), 'pssimulinkconverter', 'convertit');
m56 = add_line(add_line(m56, 'sous/1', 'convertit/1'), 'convertit/1', 'g/1');
r56 = sim(m56, 1);
assert(abs(r56.yout(end) - 6) < 1e-12, 'avec le convertisseur, le Gain lit le signal physique');
% Un signal physique est un double : le Simulink-PS Converter y ramène un
% entier, dans son unité, et le PS-Simulink Converter le rend en double.
m56 = new_system('versDouble56');
m56 = add_block(m56, 'constant', 'c', 'Value', 'int8(3)');
m56 = add_block(m56, 'simulinkpsconverter', 'sp', 'InputSignalUnit', 'mA');
m56 = add_block(m56, 'psgain', 'g', 'Gain', 2);
m56 = add_block(m56, 'pssimulinkconverter', 'ps', 'OutputSignalUnit', 'mA');
m56 = add_block(m56, 'outport', 'y');
m56 = add_line(add_line(m56, 'c/1', 'sp/1'), 'sp/1', 'g/1');
m56 = add_line(add_line(m56, 'g/1', 'ps/1'), 'ps/1', 'y/1');
r56 = sim(m56, 1);
assert(isa(r56.yout, 'double') && abs(r56.yout(end) - 6) < 1e-12, ...
       'le signal physique est un double, en unites SI');
m56 = set_param(set_param(m56, 'sp', 'InputSignalUnit', '1'), 'ps', 'OutputSignalUnit', '1');
r56 = sim(m56, 1);
assert(isa(r56.yout, 'double') && r56.yout(end) == 6, 'sans unite aussi');

% Chaque type de bloc nourri d'un scalaire, d'une ligne, d'une colonne et
% d'une matrice : un calcul élément par élément garde la forme de son
% entrée, un produit scalaire ou une largeur rendent un scalaire, et une
% forme qu'un bloc ne prend pas est refusée en le nommant.
formes56 = {'scalaire', '0.5', 1; 'ligne', '[0.5 1.5 2.5]', 3; ...
            'colonne', '[0.5; 1.5; 2.5]', 3; 'matrice', '[0.5 1.5; 2.5 3.5]', 4};
tailles56 = containers.Map();
refusFormes56 = containers.Map();
for kT = 1:numel(catalogue56)
    if any(strcmp(catalogue56(kT).famille, {'Interne', 'Simscape'}))
        continue
    end
    type = catalogue56(kT).type;
    for kF = 1:size(formes56, 1)
        m56 = batterieType(type, formes56{kF, 2});
        cle = [type '|' formes56{kF, 1}];
        try
            r56 = [];
            evalc('r56 = sim(m56, ''Solver'', ''ode1'', ''FixedStep'', 0.1, ''StopTime'', 0.3);');
            if isfield(r56, 'yout') && ~isempty(r56.yout)
                tailles56(cle) = size(r56.yout);
            end
        catch err
            id = err.identifier;
            assert((strncmp(id, 'Simulink:', 9) || strncmp(id, 'Stateflow:', 10) || ...
                    strncmp(id, 'Simscape:', 9)) && ~isempty(strfind(err.message, 'bt/')), ...
                   sprintf('%s sur une %s : erreur interne %s : %s', type, formes56{kF, 1}, ...
                           id, err.message));
            refusFormes56(cle) = id;
        end
    end
end
elements56 = {'gain', 'sum', 'product', 'abs', 'sign', 'bias', 'unaryminus', 'rounding', ...
              'saturation', 'deadzone', 'relay', 'quantizer', 'logic', 'relational', 'switch', ...
              'manualswitch', 'zoh', 'memory', 'delay', 'integrator', 'discreteintegrator', ...
              'discretetransferfcn', 'math', 'trigonometry', 'sqrt', 'lookup', ...
              'signalconversion', 'datatypeconversion', 'ic', 'merge', 'outport'};
for kT = 1:numel(elements56)
    for kF = 1:size(formes56, 1)
        cle = [elements56{kT} '|' formes56{kF, 1}];
        assert(isKey(tailles56, cle) && isequal(tailles56(cle), [4 formes56{kF, 3}]), ...
               sprintf('%s : element par element, la forme de l''entree', cle));
    end
end
for type = {'dotproduct', 'width'}
    for kF = 1:size(formes56, 1)
        cle = [type{1} '|' formes56{kF, 1}];
        assert(isequal(tailles56(cle), [4 1]), sprintf('%s : un scalaire', cle));
    end
end
assert(strcmp(refusFormes56('switchcase|ligne'), 'Simulink:blocks:SwitchCaseInputNotScalar') && ...
       strcmp(refusFormes56('tappeddelay|ligne'), 'Simulink:Engine:DimensionMismatch') && ...
       strcmp(refusFormes56('transferfcn|colonne'), 'Simulink:Engine:DimensionMismatch'), ...
       'les formes qu''un bloc ne prend pas');
fprintf('blocs et formes : %d simulations, %d refus nommes\n', tailles56.Count, ...
        refusFormes56.Count);

%% ---------------------------------------------------------- 57. Bus typés
% Un bus garde le type de chacun de ses éléments : un Bus Selector rend
% celui de l'élément qu'il choisit, un bus traverse un retard, une mémoire,
% un bloqueur ou un aiguillage, et un type de bus déclare le type de ses
% éléments, que Bus Creator et Bus Assignment doivent respecter.
m57 = new_system('busMeles');
m57 = add_block(m57, 'constant', 'a', 'Value', 'int8(5)');
m57 = add_block(m57, 'constant', 'b', 'Value', 'true');
m57 = add_block(m57, 'constant', 'c', 'Value', 'JourEssai.Mardi');
m57 = add_block(m57, 'constant', 'd', 'Value', 2.5);
m57 = add_block(m57, 'buscreator', 'bc', 'Inputs', 'a,b,c,d');
m57 = add_block(m57, 'busselector', 'bs', 'OutputSignals', 'a,b,c,d');
noms57 = {'a', 'b', 'c', 'd'};
for q = 1:4
    m57 = add_line(m57, sprintf('%s/1', noms57{q}), sprintf('bc/%d', q));
    m57 = add_block(m57, 'toworkspace', sprintf('tw%d', q), 'VariableName', ...
                    sprintf('busMele%d', q));
    m57 = add_line(m57, sprintf('bs/%d', q), sprintf('tw%d/1', q));
end
m57 = add_line(m57, 'bc/1', 'bs/1');
sim(m57, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 0.2);
assert(isa(busMele1, 'int8') && busMele1(1) == 5 && islogical(busMele2) && ...
       isa(busMele3, 'JourEssai') && busMele3(1) == JourEssai.Mardi && ...
       isa(busMele4, 'double') && busMele4(1) == 2.5, ...
       'bus types : chaque element garde son type');

% Un bus traverse un retard, une mémoire, un bloqueur, un aiguillage.
for passage57 = {'delay', 'memory', 'zoh', 'ratetransition', 'manualswitch'}
    m57 = new_system('busPasse');
    m57 = add_block(m57, 'constant', 'a', 'Value', 'int8(5)');
    m57 = add_block(m57, 'constant', 'b', 'Value', 2.5);
    m57 = add_block(m57, 'buscreator', 'bc', 'Inputs', 'a,b');
    if strcmp(passage57{1}, 'delay')
        m57 = add_block(m57, 'delay', 'p', 'SampleTime', 0.1, 'InitialCondition', 0);
    else
        m57 = add_block(m57, passage57{1}, 'p');
    end
    m57 = add_block(m57, 'busselector', 'bs', 'OutputSignals', 'a,b');
    m57 = add_block(m57, 'outport', 'ya');
    m57 = add_block(m57, 'outport', 'yb');
    m57 = add_line(add_line(m57, 'a/1', 'bc/1'), 'b/1', 'bc/2');
    m57 = add_line(add_line(m57, 'bc/1', 'p/1'), 'p/1', 'bs/1');
    if strcmp(passage57{1}, 'manualswitch')
        m57 = add_line(m57, 'bc/1', 'p/2');
    end
    m57 = add_line(add_line(m57, 'bs/1', 'ya/1'), 'bs/2', 'yb/1');
    r57 = sim(m57, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 0.3);
    assert(isequal(r57.yout(end, :), [5 2.5]), ...
           sprintf('un bus traverse %s', passage57{1}));
end

% Un type de bus déclare le type de ses éléments.
e57a = Simulink.BusElement;
e57a.Name = 'a';
e57a.DataType = 'int8';
e57b = Simulink.BusElement;
e57b.Name = 'b';
e57j = Simulink.BusElement;
e57j.Name = 'jour';
e57j.DataType = 'Enum: JourEssai';
Capteurs57 = Simulink.Bus;
Capteurs57.Elements = [e57a e57b e57j];
assignin('base', 'Capteurs57', Capteurs57);
m57 = new_system('busType');
m57 = add_block(m57, 'constant', 'a', 'Value', 'int8(5)');
m57 = add_block(m57, 'constant', 'b', 'Value', 2.5);
m57 = add_block(m57, 'constant', 'j', 'Value', 'JourEssai.Mercredi');
m57 = add_block(m57, 'buscreator', 'bc', 'Inputs', 'a,b,jour', 'OutDataTypeStr', ...
                'Bus: Capteurs57');
m57 = add_block(m57, 'busselector', 'bs', 'OutputSignals', 'a,jour');
m57 = add_block(m57, 'outport', 'ya');
m57 = add_block(m57, 'toworkspace', 'tw', 'VariableName', 'jourDuBus57');
m57 = add_line(add_line(add_line(m57, 'a/1', 'bc/1'), 'b/1', 'bc/2'), 'j/1', 'bc/3');
m57 = add_line(add_line(m57, 'bc/1', 'bs/1'), 'bs/1', 'ya/1');
m57 = add_line(m57, 'bs/2', 'tw/1');
r57 = sim(m57, 1);
assert(isa(r57.yout, 'int8') && r57.yout(end) == 5 && isa(jourDuBus57, 'JourEssai') && ...
       jourDuBus57(end) == JourEssai.Mercredi, 'le type de bus : int8 et JourEssai');
% une entrée du modèle typée par le bus
m57 = new_system('busEntre');
m57 = add_block(m57, 'inport', 'e', 'OutDataTypeStr', 'Bus: Capteurs57');
m57 = add_block(m57, 'busselector', 'bs', 'OutputSignals', 'a');
m57 = add_block(m57, 'outport', 'y');
m57 = add_line(add_line(m57, 'e/1', 'bs/1'), 'bs/1', 'y/1');
r57 = sim(m57, 1);
assert(isa(r57.yout, 'int8'), 'une entree de type Bus: Capteurs57 rend ses elements types');
% des bus emboîtés
e57i = Simulink.BusElement;
e57i.Name = 'interne';
e57i.DataType = 'Bus: Capteurs57';
e57c = Simulink.BusElement;
e57c.Name = 'c';
Exterieur57 = Simulink.Bus;
Exterieur57.Elements = [e57i e57c];
assignin('base', 'Exterieur57', Exterieur57);
m57 = new_system('busEmboite');
m57 = add_block(m57, 'constant', 'a', 'Value', 'int8(5)');
m57 = add_block(m57, 'constant', 'b', 'Value', 2.5);
m57 = add_block(m57, 'constant', 'j', 'Value', 'JourEssai.Lundi');
m57 = add_block(m57, 'constant', 'c', 'Value', 7);
m57 = add_block(m57, 'buscreator', 'dedans', 'Inputs', 'a,b,jour');
m57 = add_block(m57, 'buscreator', 'dehors', 'Inputs', 'interne,c', 'OutDataTypeStr', ...
                'Bus: Exterieur57');
m57 = add_block(m57, 'busselector', 'bs', 'OutputSignals', 'interne.a,c');
m57 = add_block(m57, 'outport', 'ya');
m57 = add_block(m57, 'outport', 'yc');
m57 = add_line(add_line(add_line(m57, 'a/1', 'dedans/1'), 'b/1', 'dedans/2'), 'j/1', 'dedans/3');
m57 = add_line(add_line(m57, 'dedans/1', 'dehors/1'), 'c/1', 'dehors/2');
m57 = add_line(add_line(add_line(m57, 'dehors/1', 'bs/1'), 'bs/1', 'ya/1'), 'bs/2', 'yc/1');
r57 = sim(m57, 1);
assert(isequal(double(r57.yout(end, :)), [5 7]), 'le bus emboite garde interne.a');
% le Bus Assignment garde le type de l'élément
m57 = new_system('busAffecte');
m57 = add_block(m57, 'constant', 'a', 'Value', 'int8(5)');
m57 = add_block(m57, 'constant', 'b', 'Value', 2.5);
m57 = add_block(m57, 'constant', 'n', 'Value', 'int8(-3)');
m57 = add_block(m57, 'buscreator', 'bc', 'Inputs', 'a,b');
m57 = add_block(m57, 'busassignment', 'ba', 'AssignedSignals', 'a');
m57 = add_block(m57, 'busselector', 'bs', 'OutputSignals', 'a');
m57 = add_block(m57, 'outport', 'y');
m57 = add_line(add_line(m57, 'a/1', 'bc/1'), 'b/1', 'bc/2');
m57 = add_line(add_line(m57, 'bc/1', 'ba/1'), 'n/1', 'ba/2');
m57 = add_line(add_line(m57, 'ba/1', 'bs/1'), 'bs/1', 'y/1');
r57 = sim(m57, 1);
assert(isa(r57.yout, 'int8') && r57.yout(end) == -3, 'Bus Assignment : un int8 remplace un int8');

refus57 = {
    @() sim(set_param(busTypeAvec('a', 5), 'bc', 'OutDataTypeStr', 'Bus: Capteurs57'), 1), ...
        'Simulink:Bus:ElementDataTypeMismatch', 'type int8'
    @() sim(busTypeAvec('jour', 3), 1), 'Simulink:Bus:ElementDataTypeMismatch', 'Enum: JourEssai'
    @() sim(set_param(m57, 'n', 'Value', 7), 1), 'Simulink:Bus:AssignmentDataTypeMismatch', ...
        'busAffecte/ba'
    @() sim(set_param(busEmboiteAvec(5), 'dehors', 'OutDataTypeStr', 'Bus: Exterieur57'), 1), ...
        'Simulink:Bus:ElementDataTypeMismatch', 'interne.a'
    };
for kE = 1:size(refus57, 1)
    vu = '';
    message = '';
    try
        refus57{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, refus57{kE, 2}) && ~isempty(strfind(message, refus57{kE, 3})), ...
           sprintf('bus types, cas %d : %s attendu, %s rendu (%s)', kE, refus57{kE, 2}, vu, ...
                   message));
end
fprintf('bus types : %d refus nommes verifies\n', size(refus57, 1));

%% ------------------------------------------------ 58. Cadences et solveurs
% Chaque type de bloc nourri d'un signal échantillonné : un modèle discret
% ne dépend pas du solveur à pas fixe qui le fait avancer — FixedStepDiscrete,
% ode1, ode3 et ode4 en rendent exactement les mêmes valeurs. Un bloc à
% état continu refuse FixedStepDiscrete ; une période qui n'est pas un
% multiple du pas est refusée en nommant le bloc.
solveurs58 = {'FixedStepDiscrete', 'ode1', 'ode3', 'ode4'};
comparaisons58 = 0;
for kT = 1:numel(catalogue56)
    if any(strcmp(catalogue56(kT).famille, {'Interne', 'Simscape'}))
        continue
    end
    type = catalogue56(kT).type;
    m58 = batterieCadence(type, 0.1);
    reference58 = [];
    for kS = 1:numel(solveurs58)
        try
            r58 = [];
            evalc(['r58 = sim(m58, ''Solver'', solveurs58{kS}, ''FixedStep'', 0.1, ' ...
                   '''StopTime'', 1);']);
        catch err
            id = err.identifier;
            assert((strncmp(id, 'Simulink:', 9) || strncmp(id, 'Stateflow:', 10)) && ...
                   ~isempty(strfind(err.message, 'bc/')), ...
                   sprintf('%s sous %s : erreur interne %s : %s', type, solveurs58{kS}, id, ...
                           err.message));
            if kS == 1
                break   % un état continu : le modèle n'est pas discret
            end
            continue
        end
        if ~isfield(r58, 'yout') || isempty(r58.yout)
            break
        end
        if kS == 1
            reference58 = double(r58.yout);   % FixedStepDiscrete : la référence
            continue
        end
        comparaisons58 = comparaisons58 + 1;
        assert(isequal(size(double(r58.yout)), size(reference58)) && ...
               max(abs(double(r58.yout(:)) - reference58(:))) < 1e-12, ...
               sprintf('%s : %s rend d''autres valeurs que FixedStepDiscrete', type, ...
                       solveurs58{kS}));
    end
end
fprintf('cadences et solveurs : %d comparaisons de modeles discrets\n', comparaisons58);
% un état continu refuse FixedStepDiscrete ; une période hors du pas est
% refusée ; deux cadences se mêlent
refus58 = {
    @() sim(batterieCadence('integrator', 0.1), 'Solver', 'FixedStepDiscrete', ...
            'FixedStep', 0.1, 'StopTime', 1), 'Simulink:', 'bc/b'
    @() sim(batterieCadence('gain', 0.15), 'Solver', 'ode1', 'FixedStep', 0.1, ...
            'StopTime', 1), 'Simulink:SampleTime:NotMultipleOfFixedStep', 'bc/'
    };
for kE = 1:size(refus58, 1)
    vu = '';
    message = '';
    try
        refus58{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strncmp(vu, refus58{kE, 2}, numel(refus58{kE, 2})) && ...
           ~isempty(strfind(message, refus58{kE, 3})), ...
           sprintf('cadences, cas %d : %s attendu, %s rendu (%s)', kE, refus58{kE, 2}, vu, ...
                   message));
end
m58 = batterieCadence('zoh', 0.1);
m58 = set_param(m58, 'b', 'SampleTime', 0.2);
r58 = sim(m58, 'Solver', 'ode1', 'FixedStep', 0.1, 'StopTime', 1);
assert(all(r58.yout(2:2:end) == r58.yout(1:2:end - 1)), ...
       'un bloqueur a 0,2 s tient deux pas d''une source a 0,1 s');

%% ------------------------------------------ 59. Stateflow et types énumérés
% Un diagramme Stateflow calcule sur des membres d'énumération : une sortie
% dont la valeur initiale est un membre est un signal énuméré, et une entrée
% énumérée arrive au diagramme en membre, qu'il compare aux siens.
f59 = sfchart('feu59');
f59 = sfstate(f59, 'rouge', 'en: feu = LumiereEssai.Rouge;');
f59 = sfstate(f59, 'vert', 'en: feu = LumiereEssai.Vert;');
f59 = sfstate(f59, 'orange', 'en: feu = LumiereEssai.Orange;');
f59 = sftransition(f59, 'rouge', 'vert', '[after(2, tick)]');
f59 = sftransition(f59, 'vert', 'orange', '[after(2, tick)]');
f59 = sftransition(f59, 'orange', 'rouge', '[after(1, tick)]');
m59 = new_system('feux59');
m59 = add_block(m59, 'chart', 'feux', 'Chart', f59, 'Inputs', 0, 'Outputs', {'feu'}, ...
                'InitialContext', struct('feu', LumiereEssai.Rouge), 'SampleTime', 1);
m59 = add_block(m59, 'toworkspace', 'tw', 'VariableName', 'feux59');
m59 = add_line(m59, 'feux/1', 'tw/1');
sim(m59, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 6);
R59 = LumiereEssai.Rouge;
V59 = LumiereEssai.Vert;
O59 = LumiereEssai.Orange;
assert(isequal(feux59, [R59; R59; V59; V59; O59; R59; R59]), ...
       'Stateflow : le feu rend des membres, dans l''ordre de ses etats');
j59 = sfchart('jour59');
j59 = sfstate(j59, 'repos', 'en: y = 0;');
j59 = sfstate(j59, 'travail', 'en: y = 1;');
j59 = sftransition(j59, 'repos', 'travail', '[u == JourEssai.Mardi]');
j59 = sftransition(j59, 'travail', 'repos', '[u ~= JourEssai.Mardi]');
m59 = new_system('jour59');
m59 = add_block(m59, 'constant', 'j', 'Value', 'JourEssai.Mardi');
m59 = add_block(m59, 'chart', 'c', 'Chart', j59, 'Inputs', 1, 'Outputs', {'y'}, ...
                'InitialContext', struct('y', 0), 'SampleTime', 1);
m59 = add_block(m59, 'outport', 'o');
m59 = add_line(add_line(m59, 'j/1', 'c/1'), 'c/1', 'o/1');
r59 = sim(m59, 'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 3);
assert(isequal(r59.yout(:)', [0 1 1 1]), 'Stateflow : Mardi, le membre recu, fait passer');
r59 = sim(set_param(m59, 'j', 'Value', 'JourEssai.Lundi'), 'Solver', 'FixedStepDiscrete', ...
          'FixedStep', 1, 'StopTime', 3);
assert(all(r59.yout == 0), 'Stateflow : Lundi ne fait pas passer');

%% ------------------------ 60. Retards à tampon extensible, pas fixe et pas variable
% Le tampon d'un Variable Transport Delay n'a que MaximumPoints pour taille
% initiale : il grandit au besoin, comme celui de Simulink, et un petit pas
% garde toute l'histoire que le retard demande. FixedBuffer le fige : il
% écrase alors ses plus anciens échantillons et extrapole ce qu'il n'a
% plus. Une remise vide le tampon ; une simulation sans fin le garde d'une
% tranche à l'autre.
u60 = @(s) (s >= 0) .* (0.8 * sin(2 * s) + 0.3);
tau60 = @(s) 0.3 * sin(2 * s) + 0.5;
instants60 = (0:0.05:2)';
genres60 = {'Variable transport delay', 'Variable time delay'};
for g = 1:2
    m60 = new_system('tampon60');
    m60 = add_block(m60, 'variabletransportdelay', 'b', 'VariableDelayType', genres60{g}, ...
                    'MaximumPoints', 16);
    m60 = add_block(m60, 'sine', 'c1', 'Amplitude', 0.8, 'Bias', 0.3, 'Frequency', 2);
    m60 = add_block(m60, 'sine', 'c2', 'Amplitude', 0.3, 'Bias', 0.5, 'Frequency', 2);
    m60 = add_line(add_line(m60, 'c1/1', 'b/1'), 'c2/1', 'b/2');
    m60 = add_line(add_block(m60, 'outport', 'o'), 'b/1', 'o/1');
    exacte60 = zeros(size(instants60));
    for i = 1:numel(instants60)
        t = instants60(i);
        if g == 1   % transport : l'échantillon entré en s sort en s + tau(s)
            s = t - 0.5;
            for it = 1:40
                s = s - (s + tau60(s) - t) / (1 + 0.6 * cos(2 * s));
            end
        else        % time delay : le retard lu à la sortie
            s = t - tau60(t);
        end
        exacte60(i) = u60(s);
    end
    garde60 = instants60 > 0.8;   % avant, la sortie initiale tient
    r60 = sim(m60, 'Solver', 'ode4', 'FixedStep', 1e-3, 'StopTime', 2);
    [~, rangs60] = ismember(round(instants60 * 1e3), round(r60.tout * 1e3));
    assert(max(abs(r60.yout(rangs60(garde60)) - exacte60(garde60))) < 1e-5, ...
           [genres60{g} ' : 2000 pas dans un tampon de 16, qui grandit']);
    r60 = sim(m60, instants60, simset('Solver', 'ode45', 'RelTol', 1e-8, 'AbsTol', 1e-10, ...
                                      'MaxStep', 0.01));
    assert(max(abs(r60.yout(garde60) - exacte60(garde60))) < 1e-4, ...
           [genres60{g} ' : a pas variable, contre la solution exacte']);
end
assert(strcmp(get_param(m60, 'b', 'FixedBuffer'), 'off'), 'FixedBuffer vaut off d''office');
% FixedBuffer : 16 échantillons de t^2, les plus anciens écrasés ; t - 0,5
% tombe avant eux, et la sortie prolonge la droite des deux plus anciens.
% Avant le premier échantillon, la sortie initiale tient toujours.
fixe60 = new_system('fixe60');
fixe60 = add_block(fixe60, 'clock', 't');
fixe60 = add_block(fixe60, 'math', 'carre', 'Operator', 'square');
fixe60 = add_block(fixe60, 'constant', 'tau', 'Value', 0.5);
fixe60 = add_block(fixe60, 'variabletransportdelay', 'd', 'VariableDelayType', ...
                   'Variable time delay', 'MaximumPoints', 16, 'InitialOutput', -1);
fixe60 = add_block(fixe60, 'outport', 'y');
fixe60 = add_line(add_line(fixe60, 't', 'carre'), 'carre', 'd', 1);
fixe60 = add_line(add_line(fixe60, 'tau', 'd', 2), 'd', 'y');
libre60 = sim(fixe60, 'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 1.5);
t60 = libre60.tout;
apres60 = t60 > 0.505;
assert(max(abs(libre60.yout(apres60) - (t60(apres60) - 0.5) .^ 2)) < 1e-12 && ...
       all(libre60.yout(t60 < 0.495) == -1), 'le tampon qui grandit garde toute l''histoire');
fixe60 = set_param(fixe60, 'd', 'FixedBuffer', 'on');
fige60 = sim(fixe60, 'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 1.5);
a60 = t60 - 0.16;   % les deux plus anciens échantillons gardés
extrapole60 = a60 .^ 2 + (t60 - 0.5 - a60) .* (2 * a60 + 0.01);
assert(max(abs(fige60.yout(apres60) - extrapole60(apres60))) < 1e-9 && ...
       all(fige60.yout(t60 < 0.495) == -1), ...
       'FixedBuffer : la droite des deux plus anciens echantillons, pas la sortie initiale');
dossier60 = fullfile(tempdir(), 'tampon60');
if ~exist(dossier60, 'dir')
    mkdir(dossier60);
end
relu60 = load_system(save_system(fixe60, fullfile(dossier60, 'fixe60.slx')));
assert(strcmp(get_param(relu60, 'd', 'FixedBuffer'), 'on'), 'FixedBuffer voyage dans le .slx');
% Le retard pur à pas variable : même tampon, même règle.
pur60 = new_system('pur60');
pur60 = add_block(pur60, 'clock', 't');
pur60 = add_block(pur60, 'math', 'carre', 'Operator', 'square');
pur60 = add_block(pur60, 'transportdelay', 'd', 'DelayTime', 0.5, 'BufferSize', 16);
pur60 = add_block(pur60, 'outport', 'y');
pur60 = add_line(add_line(add_line(pur60, 't', 'carre'), 'carre', 'd'), 'd', 'y');
reglage60 = simset('Solver', 'ode45', 'MaxStep', 0.01);
r60 = sim(pur60, [0 1 1.5], reglage60);
assert(max(abs(r60.yout(2:3) - [0.25; 1])) < 1e-4, 'retard pur : le tampon grandit');
r60 = sim(set_param(pur60, 'd', 'FixedBuffer', 'on'), [0 1 1.5], reglage60);
assert(all(abs(r60.yout(2:3) - [0.25; 1]) > 1e-3) && all(isfinite(r60.yout)), ...
       'retard pur, FixedBuffer : il a perdu ses anciens echantillons et extrapole');
% Une remise vide le tampon : le sous-système activé repart de sa sortie
% initiale pendant le retard.
interne60 = new_system('interne60');
interne60 = add_block(interne60, 'inport', 'e', 'Port', 1);
interne60 = add_block(interne60, 'constant', 'tau', 'Value', 0.2);
interne60 = add_block(interne60, 'variabletransportdelay', 'd', 'VariableDelayType', ...
                      'Variable time delay', 'InitialOutput', 5);
interne60 = add_block(interne60, 'outport', 's', 'Port', 1);
interne60 = add_block(interne60, 'enableport', 'Enable', 'StatesWhenEnabling', 'reset');
interne60 = add_line(add_line(interne60, 'e', 'd', 1), 'tau', 'd', 2);
interne60 = add_line(interne60, 'd', 's');
remis60 = new_system('remis60');
remis60 = add_block(remis60, 'clock', 'horloge');
remis60 = add_block(remis60, 'pulsegenerator', 'porte', 'Period', 2, 'PulseWidth', 50);
remis60 = add_block(remis60, 'subsystem', 'sous', 'Model', interne60);
remis60 = add_block(remis60, 'outport', 'y');
remis60 = add_line(add_line(remis60, 'horloge', 'sous/1'), 'porte', 'sous/Enable');
remis60 = add_line(remis60, 'sous', 'y');
for solveur = {'ode4', 'ode45'}
    r60 = sim(remis60, 'Solver', solveur{1}, 'FixedStep', 0.01, 'MaxStep', 0.01, ...
              'StopTime', 3);
    t60 = r60.tout;
    y60 = r60.yout;
    actif60 = (t60 > 0.21 & t60 < 0.99) | (t60 > 2.21 & t60 < 2.99);
    assert(max(abs(y60(actif60) - (t60(actif60) - 0.2))) < 1e-6 && ...
           all(y60(t60 < 0.19) == 5) && all(y60(t60 > 2.01 & t60 < 2.19) == 5), ...
           [solveur{1} ' : remis, le tampon repart vide et la sortie initiale revient']);
end
% Une simulation sans fin avance par tranches de 4096 pas : le tampon
% passe de l'une à l'autre.
fin60 = new_system('fin60');
fin60 = add_block(fin60, 'clock', 't');
fin60 = add_block(fin60, 'constant', 'tau', 'Value', 0.5);
fin60 = add_block(fin60, 'variabletransportdelay', 'd', 'VariableDelayType', ...
                  'Variable time delay');
fin60 = add_block(fin60, 'comparetoconstant', 'assez', 'relop', '>=', 'const', 8.5);
fin60 = add_block(fin60, 'stopsimulation', 'stop');
fin60 = add_block(fin60, 'outport', 'y');
fin60 = add_line(add_line(fin60, 't', 'd', 1), 'tau', 'd', 2);
fin60 = add_line(add_line(add_line(fin60, 't', 'assez'), 'assez', 'stop'), 'd', 'y');
fin60 = set_param(fin60, 'Solver', 'ode4', 'FixedStep', 2e-3, 'StopTime', Inf);
r60 = sim(fin60);
t60 = r60.tout;
assert(abs(t60(end) - 8.5) < 1e-9 && ...
       max(abs(r60.yout(t60 > 0.505) - (t60(t60 > 0.505) - 0.5))) < 1e-9, ...
       'sans fin : 4250 pas, le tampon traverse les tranches');
fprintf('retards a tampon extensible : ok\n');

%% ------------------------------------------ 61. Batterie des solveurs à pas variable
% Chaque type de bloc nourri de sinus, simulé par ode45, ode23 et ode15s à
% tolérances fines, rend aux instants demandés ce que rend ode4 à pas fin.
% Les blocs qui ne calculent qu'aux pas majeurs — compteurs, limiteurs de
% pente, dérivée, mémoire, et les blocs discrets qui héritent de leur
% entrée une période continue — dépendent des pas par nature, comme dans
% Simulink : ils sont mis à part. C'est cette batterie qui a trouvé le
% tampon trop court du retard variable (section 60).
solveurs61 = {'ode45', 'ode23', 'ode15s'};
instants61 = (0:0.05:1)';
parPas61 = {'counterfreerunning', 'counterlimited', 'ratelimiter', 'ratelimiterdynamic', ...
            'derivative', 'delay', 'memory', 'zoh', 'discreteintegrator', ...
            'discretetransferfcn', 'discretefilter', 'discretefirfilter', ...
            'transferfcnfirstorder', 'transferfcnleadorlag', 'transferfcnrealzero', ...
            'discretezeropole'};
comparaisons61 = 0;
for kT = 1:numel(catalogue56)
    type = catalogue56(kT).type;
    if any(strcmp(catalogue56(kT).famille, {'Interne', 'Simscape'})) || ...
       any(strcmp(type, parPas61))
        continue
    end
    m61 = batterieSinus(type);
    try
        ref61 = [];
        evalc('ref61 = sim(m61, ''Solver'', ''ode4'', ''FixedStep'', 1e-3, ''StopTime'', 1);');
    catch
        continue   % refusé à pas fixe : la batterie des types en répond
    end
    if ~isfield(ref61, 'yout') || isempty(ref61.yout)
        continue
    end
    [~, rangs61] = ismember(round(instants61 * 1e3), round(ref61.tout * 1e3));
    yref61 = double(ref61.yout(rangs61, :));
    for kS = 1:numel(solveurs61)
        r61 = [];
        try
            evalc(['r61 = sim(m61, instants61, simset(''Solver'', solveurs61{kS}, ' ...
                   '''RelTol'', 1e-8, ''AbsTol'', 1e-10, ''MaxStep'', 0.01));']);
        catch err
            assert((strncmp(err.identifier, 'Simulink:', 9) || ...
                    strncmp(err.identifier, 'Stateflow:', 10)) && ...
                   ~isempty(strfind(err.message, 'bv/')), ...
                   sprintf('%s sous %s : erreur interne %s : %s', type, solveurs61{kS}, ...
                           err.identifier, err.message));
            continue
        end
        assert(numel(r61.tout) == numel(instants61) && ...
               max(abs(r61.tout(:) - instants61)) < 1e-9, ...
               sprintf('%s sous %s : les instants demandes, et eux seuls', type, ...
                       solveurs61{kS}));
        comparaisons61 = comparaisons61 + 1;
        y61 = double(r61.yout);
        assert(max(abs(y61(:) - yref61(:))) < 1e-3 * max(1, max(abs(yref61(:)))), ...
               sprintf('%s sous %s : ecart de %g avec ode4 a pas fin', type, solveurs61{kS}, ...
                       max(abs(y61(:) - yref61(:)))));
    end
end
fprintf('solveurs a pas variable : %d comparaisons\n', comparaisons61);
assert(comparaisons61 > 250, 'la batterie a pas variable compare assez de modeles');

%% ------------------------------------------------ 62. Import/Export des données
% Ce que la simulation relève se règle comme dans le volet « Data
% Import/Export » de Simulink : les champs du résultat et leurs noms, la
% décimation, les derniers instants, et à pas variable l'affinage entre
% deux pas (Refine) ou des instants de sortie (OutputTimes), ajoutés aux
% pas du solveur ou seuls relevés.
m62 = new_system('export62');
m62 = add_block(m62, 'clock', 't');
m62 = add_block(m62, 'trigonometricfunction', 'cos', 'Operator', 'cos');
m62 = add_block(m62, 'integrator', 'x');
m62 = add_block(m62, 'outport', 'y');
m62 = add_line(add_line(add_line(m62, 't', 'cos'), 'cos', 'x'), 'x', 'y');
m62 = set_param(m62, 'Solver', 'ode45', 'StopTime', 2, 'MaxStep', 0.1);
r62 = sim(m62);
assert(isfield(r62, 'tout') && isfield(r62, 'yout') && ~isfield(r62, 'xout'), ...
       'par defaut : le temps et les sorties, pas les etats (SaveState off)');
assert(strcmp(get_param(m62, 'OutputOption'), 'RefineOutputTimes') && ...
       get_param(m62, 'Refine') == 1 && get_param(m62, 'Decimation') == 1 && ...
       strcmp(get_param(m62, 'LimitDataPoints'), 'off') && ...
       get_param(m62, 'MaxDataPoints') == 1000 && strcmp(get_param(m62, 'SaveState'), 'off'), ...
       'les reglages d''export, a leur defaut de Simulink');
pas62 = r62.tout;
% Refine : trois instants de plus entre deux pas, calculés sur l'état
% interpolé ; Refine 2 relève le milieu de chaque pas.
r62 = sim(m62, 'Refine', 4);
assert(numel(r62.tout) == 4 * (numel(pas62) - 1) + 1 && all(ismember(pas62, r62.tout)), ...
       'Refine 4 : chaque pas du solveur, et trois instants entre deux');
assert(max(abs(r62.yout - sin(r62.tout))) < 1e-4, 'les instants affines suivent la solution');
r62 = sim(m62, 'Refine', 2);
assert(max(abs(r62.tout(2:2:end) - (pas62(1:end - 1) + pas62(2:end)) / 2)) < 1e-12, ...
       'Refine 2 : le milieu de chaque pas');
% AdditionalOutputTimes : les pas, et des instants que le solveur atteint
r62 = sim(m62, 'OutputOption', 'AdditionalOutputTimes', 'OutputTimes', '[0.25 0.5 0.77]');
assert(all(ismember([0.25 0.5 0.77], r62.tout)) && numel(r62.tout) >= numel(pas62) && ...
       max(abs(r62.yout - sin(r62.tout))) < 1e-4, ...
       'AdditionalOutputTimes : les pas et les instants demandes');
% SpecifiedOutputTimes : le début, la fin, et les instants demandés de
% l'intervalle — une expression de l'espace de travail
instants62 = [0.3 0.6 5];
r62 = sim(m62, 'OutputOption', 'SpecifiedOutputTimes', 'OutputTimes', 'instants62');
assert(isequal(r62.tout(:)', [0 0.3 0.6 2]) && max(abs(r62.yout - sin(r62.tout))) < 1e-4, ...
       'SpecifiedOutputTimes : le debut, les instants de l''intervalle, la fin');
% À pas fixe, OutputOption ne vaut pas : chaque pas est relevé.
r62 = sim(m62, 'Solver', 'ode4', 'FixedStep', 0.1, 'OutputOption', ...
          'SpecifiedOutputTimes', 'OutputTimes', [0.3 0.6]);
assert(numel(r62.tout) == 21, 'a pas fixe, chaque pas est releve');
% Decimation, LimitDataPoints et MaxDataPoints
r62 = sim(m62, 'Solver', 'ode4', 'FixedStep', 0.1, 'Decimation', 3);
assert(max(abs(r62.tout(:)' - (0:0.3:1.8))) < 1e-12 && numel(r62.yout) == 7, ...
       'Decimation 3 : un instant sur trois, le premier compris');
r62 = sim(m62, 'Solver', 'ode4', 'FixedStep', 0.1, 'LimitDataPoints', 'on', ...
          'MaxDataPoints', 4);
assert(max(abs(r62.tout(:)' - (1.7:0.1:2))) < 1e-12 && numel(r62.yout) == 4, ...
       'MaxDataPoints 4 : les quatre derniers instants');
assert(numel(r62.temps) == 21, 'RESULTAT.temps garde tous les instants');
r62 = sim(m62, 'Solver', 'ode4', 'FixedStep', 0.1, 'Decimation', 2, 'SaveFormat', 'Dataset');
assert(numel(r62.yout{1}.Values.Time) == 11 && numel(r62.yout{1}.Values.Data) == 11, ...
       'la decimation vaut pour chaque forme de yout, Dataset compris');
r62 = sim(m62, 'Solver', 'ode4', 'FixedStep', 0.1, 'Decimation', 2, 'SaveFormat', ...
          'StructureWithTime');
assert(numel(r62.yout.time) == 11 && numel(r62.yout.signals(1).values) == 11, ...
       'et pour la structure avec le temps');
% Les champs et leurs noms
r62 = sim(m62, 'SaveState', 'on', 'StateSaveName', 'etats62', 'TimeSaveName', 'instants', ...
          'SaveOutput', 'off');
assert(isfield(r62, 'etats62') && isfield(r62, 'instants') && ~isfield(r62, 'tout') && ...
       ~isfield(r62, 'yout') && isequal(size(r62.etats62), [numel(r62.instants), 1]), ...
       'SaveState, StateSaveName, TimeSaveName et SaveOutput');
evalin('base', 'clear instants62b sorties62b');
sim(m62, 'ReturnWorkspaceOutputs', 'off', 'TimeSaveName', 'instants62b', ...
    'OutputSaveName', 'sorties62b', 'Solver', 'ode4', 'FixedStep', 0.5);
assert(isequal(evalin('base', 'instants62b(:)'''), 0:0.5:2) && ...
       numel(evalin('base', 'sorties62b')) == 5, ...
       'sans sortie, ReturnWorkspaceOutputs off : le temps et les sorties sous leurs noms');
evalin('base', 'clear instants62b sorties62b');
% SIMSET porte les mêmes réglages sous leurs noms anciens.
r62 = sim(m62, 2, simset('Solver', 'ode45', 'MaxStep', 0.1, 'Refine', 2));
assert(numel(r62.tout) == 2 * (numel(pas62) - 1) + 1, 'simset Refine');
r62 = sim(m62, [0 0.5 1], simset('Solver', 'ode45', 'MaxStep', 0.1, 'OutputPoints', 'all'));
assert(all(ismember([0 0.5 1], r62.tout)) && numel(r62.tout) > 3, ...
       'OutputPoints all : les instants donnes et chaque pas');
r62 = sim(m62, [0 0.5 1], simset('Solver', 'ode45', 'MaxStep', 0.1));
assert(isequal(r62.tout(:)', [0 0.5 1]), 'OutputPoints specified : les instants donnes seuls');
r62 = sim(m62, 2, simset('Solver', 'ode4', 'FixedStep', 0.1, 'Decimation', 4, ...
                         'MaxDataPoints', 3));
assert(max(abs(r62.tout(:)' - [1.2 1.6 2])) < 1e-12, 'simset Decimation et MaxDataPoints');
[t62, x62, y62] = sim(m62, 2, simset('Solver', 'ode4', 'FixedStep', 0.5, 'Decimation', 2));
assert(isequal(t62(:)', [0 1 2]) && isequal(size(x62), [3 1]) && isequal(size(y62), [3 1]), ...
       '[T,X,Y] = SIM(...) : les etats toujours, decimes eux aussi');
% Les valeurs refusées, en disant pourquoi
refus62 = {
    @() set_param(m62, 'Refine', 0), 'Simulink:Config:InvalidValue', 'Refine'
    @() set_param(m62, 'Decimation', 1.5), 'Simulink:Config:InvalidValue', 'Decimation'
    @() set_param(m62, 'OutputOption', 'Tout'), 'Simulink:Config:InvalidValue', 'OutputOption'
    @() set_param(m62, 'StateSaveName', '2etats'), 'Simulink:Config:InvalidValue', ...
        'StateSaveName'
    @() sim(m62, 'OutputOption', 'SpecifiedOutputTimes', 'OutputTimes', '[1 2; 3 4]'), ...
        'Simulink:Config:InvalidValue', 'export62'
    @() sim(m62, 'OutputOption', 'SpecifiedOutputTimes', 'OutputTimes', '''texte'''), ...
        'Simulink:Commands:ParametreNonNumerique', 'OutputTimes'
    @() simset('OutputPoints', 'quelques'), 'Simulink:Config:InvalidValue', 'OutputPoints'
    @() simset('Trace', 'minstep'), 'Simulink:Commands:SimsetInconnue', 'Trace'
    };
for kE = 1:size(refus62, 1)
    vu = '';
    message = '';
    try
        refus62{kE, 1}();
    catch err
        vu = err.identifier;
        message = err.message;
    end
    assert(strcmp(vu, refus62{kE, 2}) && ~isempty(strfind(message, refus62{kE, 3})), ...
           sprintf('export, cas %d : %s attendu, %s rendu (%s)', kE, refus62{kE, 2}, vu, ...
                   message));
end
% Les réglages d'export voyagent dans le .slx.
dossier62 = fullfile(tempdir(), 'export62');
if ~exist(dossier62, 'dir')
    mkdir(dossier62);
end
m62 = set_param(m62, 'OutputOption', 'AdditionalOutputTimes', 'OutputTimes', '[0.25 0.5]', ...
                'Decimation', 2, 'SaveState', 'on', 'Refine', 3);
relu62 = load_system(save_system(m62, fullfile(dossier62, 'export62.slx')));
assert(strcmp(get_param(relu62, 'OutputOption'), 'AdditionalOutputTimes') && ...
       strcmp(get_param(relu62, 'OutputTimes'), '[0.25 0.5]') && ...
       get_param(relu62, 'Decimation') == 2 && strcmp(get_param(relu62, 'SaveState'), 'on') && ...
       get_param(relu62, 'Refine') == 3, 'les reglages d''export voyagent dans le .slx');
fprintf('import et export des donnees : ok\n');

%% ------------------------------------------ 63. Diagnostics de la simulation
% Les diagnostics de Simulink, réglés comme dans sa boîte de configuration
% : none, warning — un avertissement par bloc et par simulation — ou
% error. Une sortie de bloc qui vaut Inf ou NaN (SignalInfNanChecking) ;
% un entier ou une virgule fixe qui déborde de son type, replié
% (IntegerOverflowMsg) ou saturé (IntegerSaturationMsg) ; à pas variable,
% trop de passages par zéro de suite (MaxConsecutiveZCs,
% MaxConsecutiveZCsMsg), trop de pas de suite au pas minimal qui ne tient
% pas la tolérance (MaxConsecutiveMinStep, MinStepSizeMsg).
m63 = new_system('infini63');
m63 = add_block(m63, 'clock', 't');
m63 = add_block(m63, 'constant', 'un', 'Value', 1);
m63 = add_block(m63, 'product', 'div', 'Inputs', '*/');
m63 = add_block(m63, 'gain', 'g', 'Gain', 2);
m63 = add_block(m63, 'outport', 'y');
m63 = add_line(add_line(m63, 'un', 'div', 1), 't', 'div', 2);
m63 = add_line(add_line(m63, 'div', 'g'), 'g', 'y');
assert(strcmp(get_param(m63, 'SignalInfNanChecking'), 'none') && ...
       strcmp(get_param(m63, 'IntegerOverflowMsg'), 'warning') && ...
       strcmp(get_param(m63, 'IntegerSaturationMsg'), 'warning') && ...
       strcmp(get_param(m63, 'MinStepSizeMsg'), 'warning') && ...
       get_param(m63, 'MaxConsecutiveMinStep') == 1 && ...
       get_param(m63, 'MaxConsecutiveZCs') == 1000 && ...
       strcmp(get_param(m63, 'MaxConsecutiveZCsMsg'), 'error'), ...
       'les diagnostics, a leur defaut de Simulink');
lastwarn('');
r63 = sim(m63, 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 0.3);
[~, id63] = lastwarn();
assert(isempty(id63) && isinf(r63.yout(1)), 'SignalInfNanChecking none : 1/0 passe sans rien dire');
lastwarn('');
sim(m63, 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 0.3, 'SignalInfNanChecking', 'warning');
[message63, id63] = lastwarn();
assert(strcmp(id63, 'Simulink:Engine:BlockOutputInfNaN') && ~isempty(strfind(message63, 'Inf')), ...
       'SignalInfNanChecking warning : un avertissement qui nomme le bloc et l''infini');
for solveur63 = {'ode4', 'ode45'}
    vu63 = '';
    message63 = '';
    try
        sim(m63, 'Solver', solveur63{1}, 'FixedStep', 0.1, 'StopTime', 0.3, ...
            'SignalInfNanChecking', 'error');
    catch err
        vu63 = err.identifier;
        message63 = err.message;
    end
    assert(strcmp(vu63, 'Simulink:Engine:BlockOutputInfNaN') && ...
           ~isempty(strfind(message63, 'infini63/div')) && ...
           ~isempty(strfind(message63, 't = 0')), ...
           [solveur63{1} ' : SignalInfNanChecking error nomme le bloc d''ou l''infini part']);
end
nan63 = set_param(m63, 'un', 'Value', 0);
vu63 = '';
message63 = '';
try
    sim(nan63, 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 0.3, ...
        'SignalInfNanChecking', 'error');
catch err
    vu63 = err.identifier;
    message63 = err.message;
end
assert(strcmp(vu63, 'Simulink:Engine:BlockOutputInfNaN') && ~isempty(strfind(message63, 'NaN')), ...
       'SignalInfNanChecking : 0/0 rend NaN');
% Un entier qui déborde : replié, ou saturé
m63 = new_system('repli63');
m63 = add_block(m63, 'constant', 'a', 'Value', 'int8(100)');
m63 = add_block(m63, 'constant', 'b', 'Value', 'int8(100)');
m63 = add_block(m63, 'sum', 'somme');
m63 = add_block(m63, 'outport', 'y');
m63 = add_line(add_line(add_line(m63, 'a', 'somme', 1), 'b', 'somme', 2), 'somme', 'y');
reglage63 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 2};
lastwarn('');
r63 = sim(m63, reglage63{:});
[message63, id63] = lastwarn();
assert(isequal(double(r63.yout(:)'), [-56 -56 -56]) && ...
       strcmp(id63, 'Simulink:Engine:WrapOnOverflow') && ...
       ~isempty(strfind(message63, 'repli63/somme')) && ~isempty(strfind(message63, 'int8')), ...
       'IntegerOverflowMsg warning : 100 + 100 se replie en -56, en le disant');
lastwarn('');
r63 = sim(set_param(m63, 'somme', 'SaturateOnIntegerOverflow', 'on'), reglage63{:});
[message63, id63] = lastwarn();
assert(isequal(double(r63.yout(:)'), [127 127 127]) && ...
       strcmp(id63, 'Simulink:Engine:SaturateOnOverflow') && ...
       ~isempty(strfind(message63, 'repli63/somme')), ...
       'IntegerSaturationMsg warning : 100 + 100 sature a 127, en le disant');
lastwarn('');
r63 = sim(m63, reglage63{:}, 'IntegerOverflowMsg', 'none');
[~, id63] = lastwarn();
assert(isempty(id63) && isequal(double(r63.yout(:)'), [-56 -56 -56]), ...
       'IntegerOverflowMsg none : le repli se tait');
vu63 = '';
try
    sim(m63, reglage63{:}, 'IntegerOverflowMsg', 'error');
catch err
    vu63 = err.identifier;
end
assert(strcmp(vu63, 'Simulink:Engine:WrapOnOverflow'), 'IntegerOverflowMsg error : l''arret');
conv63 = new_system('conv63');
conv63 = add_block(conv63, 'constant', 'a', 'Value', 300);
conv63 = add_block(conv63, 'datatypeconversion', 'c', 'OutDataTypeStr', 'uint8');
conv63 = add_block(conv63, 'outport', 'y');
conv63 = add_line(add_line(conv63, 'a', 'c'), 'c', 'y');
lastwarn('');
r63 = sim(conv63, reglage63{:});
[message63, id63] = lastwarn();
assert(all(double(r63.yout) == 44) && strcmp(id63, 'Simulink:Engine:WrapOnOverflow') && ...
       ~isempty(strfind(message63, 'conv63/c')), ...
       'Data Type Conversion : 300 en uint8 se replie en 44, en le disant');
% Zénon : x' = -signe(x) bascule sans fin quand x atteint zéro
m63 = new_system('zenon63');
m63 = add_block(m63, 'integrator', 'x', 'InitialCondition', 1);
m63 = add_block(m63, 'sign', 's');
m63 = add_block(m63, 'gain', 'g', 'Gain', -1);
m63 = add_block(m63, 'outport', 'y');
m63 = add_line(add_line(add_line(add_line(m63, 'x', 's'), 's', 'g'), 'g', 'x'), 'x', 'y');
vu63 = '';
message63 = '';
try
    sim(m63, 'Solver', 'ode45', 'StopTime', 1.1, 'MaxConsecutiveZCs', 20);
catch err
    vu63 = err.identifier;
    message63 = err.message;
end
assert(strcmp(vu63, 'Simulink:Engine:SolverConsecutiveZCNum') && ...
       ~isempty(strfind(message63, '20 consecutive zero crossings')), ...
       'MaxConsecutiveZCs 20 : l''arret, au vingt et unieme');
lastwarn('');
r63 = sim(m63, 'Solver', 'ode45', 'StopTime', 1.1, 'MaxConsecutiveZCs', 20, ...
          'MaxConsecutiveZCsMsg', 'warning');
[~, id63] = lastwarn();
assert(strcmp(id63, 'Simulink:Engine:SolverConsecutiveZCNum') && ...
       abs(r63.tout(end) - 1.1) < 1e-12 && abs(r63.yout(end)) < 0.05, ...
       'MaxConsecutiveZCsMsg warning : le diagnostic, puis la simulation va a son terme');
% Le pas minimal : x' = -100 x, qu'un pas de 0,05 ne suit pas
m63 = new_system('raide63');
m63 = add_block(m63, 'integrator', 'x', 'InitialCondition', 1);
m63 = add_block(m63, 'gain', 'g', 'Gain', -100);
m63 = add_block(m63, 'outport', 'y');
m63 = add_line(add_line(add_line(m63, 'x', 'g'), 'g', 'x'), 'x', 'y');
reglage63 = {'Solver', 'ode45', 'StopTime', 0.2, 'MinStep', 0.05, 'RelTol', 1e-6};
lastwarn('');
r63 = sim(m63, reglage63{:});
[message63, id63] = lastwarn();
assert(numel(r63.tout) == 5 && strcmp(id63, 'Simulink:Engine:SolverMinStepViolation') && ...
       ~isempty(strfind(message63, '2 consecutive times')), ...
       'MinStep 0,05 tenu ; au deuxieme pas minimal de suite, l''avertissement');
lastwarn('');
sim(m63, reglage63{:}, 'MaxConsecutiveMinStep', 10);
[~, id63] = lastwarn();
assert(isempty(id63), 'MaxConsecutiveMinStep 10 : quatre pas minimaux passent');
vu63 = '';
try
    sim(m63, reglage63{:}, 'MinStepSizeMsg', 'error');
catch err
    vu63 = err.identifier;
end
assert(strcmp(vu63, 'Simulink:Engine:SolverMinStepViolation'), 'MinStepSizeMsg error : l''arret');
% Les valeurs refusées
refus63 = {
    @() set_param(m63, 'SignalInfNanChecking', 'oui'), 'SignalInfNanChecking'
    @() set_param(m63, 'MinStepSizeMsg', 'none'), 'MinStepSizeMsg'
    @() set_param(m63, 'MaxConsecutiveZCs', 0), 'MaxConsecutiveZCs'
    @() set_param(m63, 'MaxConsecutiveMinStep', 2.5), 'MaxConsecutiveMinStep'
    };
for kE = 1:size(refus63, 1)
    vu63 = '';
    message63 = '';
    try
        refus63{kE, 1}();
    catch err
        vu63 = err.identifier;
        message63 = err.message;
    end
    assert(strcmp(vu63, 'Simulink:Config:InvalidValue') && ...
           ~isempty(strfind(message63, refus63{kE, 2})), ...
           sprintf('diagnostics, cas %d : %s rendu (%s)', kE, vu63, message63));
end
fprintf('diagnostics de la simulation : ok\n');

%% ------------------------------------------------ 64. Le pas fixe automatique
% FixedStep 'auto', comme dans Simulink : le pas fondamental — le plus grand
% commun diviseur des périodes d'échantillonnage et de leurs décalages — ;
% sans période, la durée en cinquante pas, 0,2 s sans fin, au plus le
% tiers de la période du sinus le plus rapide.
m64 = new_system('auto64');
m64 = add_block(m64, 'sine', 's1', 'SampleTime', 0.1);
m64 = add_block(m64, 'sine', 's2', 'SampleTime', 0.25);
m64 = add_block(m64, 'outport', 'y1');
m64 = add_block(m64, 'outport', 'y2');
m64 = add_line(add_line(m64, 's1', 'y1'), 's2', 'y2');
r64 = sim(m64, 'Solver', 'FixedStepDiscrete', 'FixedStep', 'auto', 'StopTime', 1);
assert(max(abs(r64.tout(:)' - (0:0.05:1))) < 1e-12, 'le pas fondamental de 0,1 et 0,25 : 0,05');
r64 = sim(set_param(m64, 's2', 'SampleTime', [0.2 0.05]), 'Solver', 'FixedStepDiscrete', ...
          'FixedStep', 'auto', 'StopTime', 1);
assert(max(abs(r64.tout(:)' - (0:0.05:1))) < 1e-12, 'un decalage compte aussi : 0,2 decale de 0,05');
% un état continu et une période : la période l'emporte sur la durée
m64 = new_system('mixte64');
m64 = add_block(m64, 'constant', 'un', 'Value', 1);
m64 = add_block(m64, 'integrator', 'x');
m64 = add_block(m64, 'sine', 's', 'SampleTime', 0.1);
m64 = add_block(m64, 'outport', 'y1');
m64 = add_block(m64, 'outport', 'y2');
m64 = add_line(add_line(add_line(m64, 'un', 'x'), 'x', 'y1'), 's', 'y2');
r64 = sim(m64, 'Solver', 'ode3', 'FixedStep', 'auto', 'StopTime', 10);
assert(numel(r64.tout) == 101 && abs(r64.tout(2) - 0.1) < 1e-12 && ...
       abs(r64.yout(end, 1) - 10) < 1e-9, ...
       'une periode de 0,1 et dix secondes : cent pas, et non cinquante qu''elle refuserait');
% sans période : la durée en cinquante pas, au plus le tiers de la période
% du sinus le plus rapide
r64 = sim(delete_block(delete_block(m64, 's'), 'y2'), 'Solver', 'ode3', 'FixedStep', 'auto', ...
          'StopTime', 5);
assert(numel(r64.tout) == 51 && abs(r64.tout(2) - 0.1) < 1e-12, 'sans periode : 5 s en cinquante pas');
m64 = new_system('rapide64');
m64 = add_block(m64, 'sine', 's', 'Frequency', 20);
m64 = add_block(m64, 'integrator', 'x');
m64 = add_block(m64, 'outport', 'y');
m64 = add_line(add_line(m64, 's', 'x'), 'x', 'y');
r64 = sim(m64, 'Solver', 'ode4', 'FixedStep', 'auto', 'StopTime', 10);
assert(abs(r64.tout(2) - 2 * pi / 60) < 1e-12, ...
       'un sinus de 20 rad/s : au plus le tiers de sa periode, 2 pi / 60');
m64 = new_system('sansFin64');
m64 = add_block(m64, 'clock', 't');
m64 = add_block(m64, 'integrator', 'x');
m64 = add_block(m64, 'comparetoconstant', 'assez', 'relop', '>=', 'const', 1);
m64 = add_block(m64, 'stopsimulation', 'stop');
m64 = add_line(add_line(add_line(m64, 't', 'x'), 't', 'assez'), 'assez', 'stop');
r64 = sim(m64, 'Solver', 'ode3', 'FixedStep', 'auto', 'StopTime', Inf);
assert(max(abs(r64.tout(:)' - (0:0.2:1))) < 1e-12, 'sans fin et sans periode : 0,2 s');
fprintf('pas fixe automatique : ok\n');

%% ----------------------------------------- 65. Plages de sortie, OutMin et OutMax
% Un bloc de calcul borne sa sortie par OutMin et OutMax, un Outport son
% entrée ; SignalRangeChecking dit ce que fait une valeur qui en sort —
% rien, un avertissement par bloc, ou l'arrêt, en nommant le bloc,
% l'instant et l'élément. La valeur d'un Constant doit s'y tenir, dès la
% compilation.
m65 = new_system('plage65');
m65 = add_block(m65, 'clock', 't');
m65 = add_block(m65, 'gain', 'g', 'Gain', 1, 'OutMax', 1.5);
m65 = add_block(m65, 'outport', 'y');
m65 = add_line(add_line(m65, 't', 'g'), 'g', 'y');
assert(isempty(get_param(m65, 'y', 'OutMin')) && get_param(m65, 'g', 'OutMax') == 1.5 && ...
       strcmp(get_param(m65, 'SignalRangeChecking'), 'none'), ...
       'OutMin et OutMax, vides par defaut ; SignalRangeChecking a none');
reglage65 = {'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 2};
lastwarn('');
r65 = sim(m65, reglage65{:});
[~, id65] = lastwarn();
assert(isempty(id65) && abs(r65.yout(end) - 2) < 1e-12, ...
       'SignalRangeChecking none : la plage ne borne rien, elle se verifie');
lastwarn('');
sim(m65, reglage65{:}, 'SignalRangeChecking', 'warning');
[message65, id65] = lastwarn();
assert(strcmp(id65, 'Simulink:Engine:SignalRangeViolation') && ...
       ~isempty(strfind(message65, 'plage65/g')) && ~isempty(strfind(message65, 't = 1.6')) && ...
       ~isempty(strfind(message65, '[-Inf, 1.5]')), ...
       'SignalRangeChecking warning : le bloc, l''instant, la plage');
vu65 = '';
try
    sim(m65, reglage65{:}, 'Solver', 'ode45', 'SignalRangeChecking', 'error');
catch err
    vu65 = err.identifier;
end
assert(strcmp(vu65, 'Simulink:Engine:SignalRangeViolation'), ...
       'SignalRangeChecking error, a pas variable : l''arret');
% par élément, et à l'entrée d'un Outport
m65 = new_system('vecteur65');
m65 = add_block(m65, 'clock', 't');
m65 = add_block(m65, 'gain', 'g', 'Gain', [1; 2], 'OutMax', [10 1]);
m65 = add_block(m65, 'outport', 'y', 'OutMin', -1, 'OutMax', 5);
m65 = add_line(add_line(m65, 't', 'g'), 'g', 'y');
vu65 = '';
message65 = '';
try
    sim(m65, reglage65{:}, 'SignalRangeChecking', 'error');
catch err
    vu65 = err.identifier;
    message65 = err.message;
end
assert(strcmp(vu65, 'Simulink:Engine:SignalRangeViolation') && ...
       ~isempty(strfind(message65, 'vecteur65/g')) && ~isempty(strfind(message65, 'element 2')) && ...
       ~isempty(strfind(message65, 't = 0.6')), ...
       'une plage par element : le second, borne a 1, sort le premier, a t = 0,6');
m65 = set_param(m65, 'g', 'OutMax', []);
message65 = '';
try
    sim(m65, reglage65{:}, 'StopTime', 3, 'SignalRangeChecking', 'error');
catch err
    message65 = err.message;
end
assert(~isempty(strfind(message65, 'vecteur65/y')) && ~isempty(strfind(message65, 't = 2.6')), ...
       'l''Outport verifie son entree : 2 t depasse 5 a t = 2,6');
% Les refus de la compilation
m65 = new_system('constante65');
m65 = add_block(m65, 'constant', 'c', 'Value', 5, 'OutMax', 3);
m65 = add_block(m65, 'outport', 'y');
m65 = add_line(m65, 'c', 'y');
refus65 = {
    @() sim(m65, reglage65{:}), 'Simulink:Parameters:ValueOutsideOutMinMax', 'constante65/c'
    @() sim(set_param(m65, 'c', 'OutMax', [], 'OutMin', 6), reglage65{:}), ...
        'Simulink:Parameters:ValueOutsideOutMinMax', '[6, Inf]'
    @() sim(set_param(m65, 'c', 'OutMin', 4, 'OutMax', 3), reglage65{:}), ...
        'Simulink:blocks:InvalidOutMinMax', 'constante65/c'
    @() sim(set_param(m65, 'c', 'OutMax', [7 8 9]), reglage65{:}), ...
        'Simulink:blocks:InvalidOutMinMax', 'constante65/c'
    };
for kE = 1:size(refus65, 1)
    vu65 = '';
    message65 = '';
    try
        refus65{kE, 1}();
    catch err
        vu65 = err.identifier;
        message65 = err.message;
    end
    assert(strcmp(vu65, refus65{kE, 2}) && ~isempty(strfind(message65, refus65{kE, 3})), ...
           sprintf('plages, cas %d : %s attendu, %s rendu (%s)', kE, refus65{kE, 2}, vu65, ...
                   message65));
end
% Les plages voyagent dans le .slx.
dossier65 = fullfile(tempdir(), 'plage65');
if ~exist(dossier65, 'dir')
    mkdir(dossier65);
end
m65 = set_param(m65, 'c', 'Value', 2, 'OutMin', 0, 'OutMax', 3);
relu65 = load_system(save_system(m65, fullfile(dossier65, 'constante65.slx')));
assert(strcmp(num2str(get_param(relu65, 'c', 'OutMin')), '0') && ...
       strcmp(num2str(get_param(relu65, 'c', 'OutMax')), '3'), ...
       'OutMin et OutMax voyagent dans le .slx');
vu65 = '';
try
    sim(set_param(relu65, 'c', 'Value', 3.5), reglage65{:});
catch err
    vu65 = err.identifier;
end
assert(strcmp(vu65, 'Simulink:Parameters:ValueOutsideOutMinMax'), ...
       'relue, la plage borne encore la valeur du Constant');
fprintf('plages de sortie : ok\n');

%% ------------------------------------------------------ 66. Data Type Override
% DataTypeOverride remplace, le temps d'une simulation, les types
% numériques des signaux et des paramètres par le double ou le single —
% pour voir un modèle entier ou à virgule fixe sans ses débordements —,
% sur tous les types ou sur les seuls flottants, ou les seuls entiers et
% virgules fixes ; les booléens et les énumérations restent ce qu'ils
% sont.
m66 = new_system('surcharge66');
m66 = add_block(m66, 'constant', 'a', 'Value', 'int8(100)');
m66 = add_block(m66, 'constant', 'b', 'Value', 'int8(100)');
m66 = add_block(m66, 'sum', 'somme');
m66 = add_block(m66, 'relationaloperator', 'plus', 'Operator', '>');
m66 = add_block(m66, 'outport', 'y');
m66 = add_block(m66, 'toworkspace', 'tw', 'VariableName', 'plus66', 'SaveFormat', 'Array');
m66 = add_line(add_line(add_line(m66, 'a', 'somme', 1), 'b', 'somme', 2), 'somme', 'y');
m66 = add_line(add_line(add_line(m66, 'somme', 'plus', 1), 'a', 'plus', 2), 'plus', 'tw');
reglage66 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1, ...
             'IntegerOverflowMsg', 'none'};
assert(strcmp(get_param(m66, 'DataTypeOverride'), 'UseLocalSettings') && ...
       strcmp(get_param(m66, 'DataTypeOverrideAppliesTo'), 'AllNumericTypes'), ...
       'DataTypeOverride, a son defaut de Simulink');
r66 = sim(m66, reglage66{:});
assert(isequal(double(r66.yout(:)'), [-56 -56]) && isa(r66.yout, 'int8'), ...
       'sans surcharge : 100 + 100 se replie en int8');
for mode66 = {'Double', 'ScaledDouble'}
    r66 = sim(m66, reglage66{:}, 'DataTypeOverride', mode66{1});
    assert(isequal(r66.yout(:)', [200 200]) && isa(r66.yout, 'double') && ...
           isa(evalin('base', 'plus66'), 'logical'), ...
           [mode66{1} ' : la somme en double, sans repli ; le booleen reste booleen']);
end
r66 = sim(m66, reglage66{:}, 'DataTypeOverride', 'Double', ...
          'DataTypeOverrideAppliesTo', 'Floating-point');
assert(isa(r66.yout, 'int8'), 'Floating-point : les entiers ne sont pas touches');
r66 = sim(m66, reglage66{:}, 'DataTypeOverride', 'Off');
assert(isa(r66.yout, 'int8'), 'Off : rien n''est remplace');
evalin('base', 'clear plus66');
% Un tiers en double, en single sous la surcharge
m66 = new_system('flottant66');
m66 = add_block(m66, 'constant', 'c', 'Value', 1);
m66 = add_block(m66, 'gain', 'g', 'Gain', 1/3);
m66 = add_block(m66, 'outport', 'y');
m66 = add_line(add_line(m66, 'c', 'g'), 'g', 'y');
r66 = sim(m66, reglage66{:}, 'DataTypeOverride', 'Single');
assert(isa(r66.yout, 'single') && r66.yout(1) == single(1/3), 'Single : un tiers en simple precision');
r66 = sim(m66, reglage66{:}, 'DataTypeOverride', 'Single', ...
          'DataTypeOverrideAppliesTo', 'Fixed-point');
assert(isa(r66.yout, 'double'), 'Fixed-point : les flottants ne sont pas touches');
% Une virgule fixe dans un bloc continu : refusée, sauf sous la surcharge
m66 = new_system('continu66');
m66 = add_block(m66, 'constant', 'c', 'Value', 1, 'OutDataTypeStr', 'fixdt(1,16,8)');
m66 = add_block(m66, 'integrator', 'x');
m66 = add_block(m66, 'outport', 'y');
m66 = add_line(add_line(m66, 'c', 'x'), 'x', 'y');
vu66 = '';
try
    sim(m66, 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 1);
catch err
    vu66 = err.identifier;
end
assert(strncmp(vu66, 'Simulink:', 9), 'un integrateur refuse une virgule fixe');
r66 = sim(m66, 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 1, 'DataTypeOverride', 'Double');
assert(abs(r66.yout(end) - 1) < 1e-12, 'sous la surcharge, la virgule fixe devient un double');
% Les valeurs refusées
refus66 = {
    @() set_param(m66, 'DataTypeOverride', 'Tout'), 'DataTypeOverride'
    @() set_param(m66, 'DataTypeOverrideAppliesTo', 'Integer'), 'DataTypeOverrideAppliesTo'
    };
for kE = 1:size(refus66, 1)
    vu66 = '';
    message66 = '';
    try
        refus66{kE, 1}();
    catch err
        vu66 = err.identifier;
        message66 = err.message;
    end
    assert(strcmp(vu66, 'Simulink:Config:InvalidValue') && ...
           ~isempty(strfind(message66, refus66{kE, 2})), ...
           sprintf('surcharge, cas %d : %s rendu (%s)', kE, vu66, message66));
end
% la surcharge ne survit pas à sa simulation
assert(isequal(matlibre_sl_types('surcharge'), [0 1]), 'la surcharge se leve apres la simulation');
fprintf('data type override : ok\n');

%% ---------------------------------------------- 67. Journal des oscilloscopes
% Un Scope dont DataLogging vaut 'on' journalise ses entrées, comme dans
% Simulink : dans ScopeData — ou le nom qu'on lui donne —, un Dataset par
% défaut, une structure avec ou sans le temps, ou une matrice [t, u1,
% u2...] ; aux instants de sa période, décimé ou limité aux derniers
% instants si on le demande. Les noms anciens SaveToWorkspace, SaveName,
% DataFormat... valent aussi.
m67 = new_system('oscillo67');
m67 = add_block(m67, 'clock', 't');
m67 = add_block(m67, 'gain', 'g', 'Gain', 2);
m67 = add_block(m67, 'scope', 'sc', 'NumInputPorts', 2);
m67 = add_line(add_line(add_line(m67, 't', 'g'), 't', 'sc', 1), 'g', 'sc', 2);
reglage67 = {'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 1};
assert(strcmp(get_param(m67, 'sc', 'DataLogging'), 'off') && ...
       strcmp(get_param(m67, 'sc', 'DataLoggingVariableName'), 'ScopeData') && ...
       strcmp(get_param(m67, 'sc', 'DataLoggingSaveFormat'), 'Dataset'), ...
       'le Scope ne journalise pas d''office ; ScopeData, en Dataset');
evalin('base', 'clear ScopeData');
r67 = sim(m67, reglage67{:});
assert(~isfield(r67, 'ScopeData') && ~evalin('base', 'exist(''ScopeData'', ''var'')'), ...
       'DataLogging off : pas de journal');
m67 = set_param(m67, 'sc', 'DataLogging', 'on');
r67 = sim(m67, reglage67{:});
ds67 = r67.ScopeData;
assert(isa(ds67, 'Simulink.SimulationData.Dataset') && ds67.numElements == 2 && ...
       max(abs(ds67{2}.Values.Data(:) - 2 * (0:0.1:1)')) < 1e-12 && ...
       numel(ds67{1}.Values.Time) == 11 && ...
       isa(evalin('base', 'ScopeData'), 'Simulink.SimulationData.Dataset'), ...
       'Dataset : un element par entree, dans le resultat et l''espace de travail');
r67 = sim(set_param(m67, 'sc', 'DataLoggingSaveFormat', 'StructureWithTime', ...
                    'DataLoggingVariableName', 'donnees67'), reglage67{:});
assert(isequal(size(r67.donnees67.time), [11 1]) && numel(r67.donnees67.signals) == 2 && ...
       max(abs(r67.donnees67.signals(2).values - 2 * r67.donnees67.time)) < 1e-12 && ...
       strcmp(r67.donnees67.blockName, 'oscillo67/sc'), ...
       'StructureWithTime : time et signals(k).values');
m67 = set_param(m67, 'sc', 'DataLoggingSaveFormat', 'Array', ...
                'DataLoggingVariableName', 'tableau67', 'DataLoggingDecimateData', 'on', ...
                'DataLoggingDecimation', 5);
r67 = sim(m67, reglage67{:});
assert(isequal(size(r67.tableau67), [3 3]) && max(abs(r67.tableau67(:, 1)' - [0 0.5 1])) < 1e-12 && ...
       max(abs(r67.tableau67(:, 3) - 2 * r67.tableau67(:, 1))) < 1e-12, ...
       'Array decime : [t, u1, u2], un instant sur cinq');
r67 = sim(set_param(m67, 'sc', 'DataLoggingDecimateData', 'off', ...
                    'DataLoggingLimitDataPoints', 'on', 'DataLoggingMaxPoints', 3), reglage67{:});
assert(max(abs(r67.tableau67(:, 1)' - [0.8 0.9 1])) < 1e-12, 'les trois derniers instants');
% la période du Scope, et les noms anciens
m67 = new_system('ancien67');
m67 = add_block(m67, 'clock', 't');
m67 = add_block(m67, 'scope', 'sc', 'SaveToWorkspace', 'on', 'SaveName', 'vieux67', ...
                'DataFormat', 'Array', 'SampleTime', 0.2);
m67 = add_line(m67, 't', 'sc');
r67 = sim(m67, reglage67{:});
assert(max(abs(r67.vieux67(:, 1)' - (0:0.2:1))) < 1e-12 && ...
       strcmp(get_param(m67, 'sc', 'DataLogging'), 'on'), ...
       'SaveToWorkspace, SaveName, DataFormat ; une periode de 0,2 s');
% un entier garde sa classe
m67 = new_system('entier67');
m67 = add_block(m67, 'constant', 'c', 'Value', 'int8(7)');
m67 = add_block(m67, 'scope', 'sc', 'DataLogging', 'on', 'DataLoggingSaveFormat', ...
                'StructureWithTime');
m67 = add_line(m67, 'c', 'sc');
r67 = sim(m67, reglage67{:});
assert(isa(r67.ScopeData.signals(1).values, 'int8'), 'un signal int8 se journalise en int8');
evalin('base', 'clear ScopeData donnees67 tableau67 vieux67');
fprintf('journal des oscilloscopes : ok\n');

%% ------------------------------------------- 68. Passages par zéro adaptatifs
% ZeroCrossAlgorithm 'Adaptive', comme dans Simulink : un bloc qui bascule
% sans cesse — x' = -signe(x) quand x atteint zéro — n'est plus localisé,
% jusqu'au pas qui ne bascule pas ; la simulation va à son terme sans le
% diagnostic des passages par zéro de suite. Un passage isolé reste
% localisé exactement. ZcThreshold ignore les traversées de sa bande.
m68 = new_system('adaptatif68');
m68 = add_block(m68, 'integrator', 'x', 'InitialCondition', 1);
m68 = add_block(m68, 'sign', 's');
m68 = add_block(m68, 'gain', 'g', 'Gain', -1);
m68 = add_block(m68, 'outport', 'y');
m68 = add_line(add_line(add_line(add_line(m68, 'x', 's'), 's', 'g'), 'g', 'x'), 'x', 'y');
assert(strcmp(get_param(m68, 'ZeroCrossAlgorithm'), 'Nonadaptive') && ...
       strcmp(get_param(m68, 'ZcThreshold'), 'auto'), 'Nonadaptive et auto, par defaut');
vu68 = '';
try
    sim(m68, 'Solver', 'ode45', 'StopTime', 1.5, 'MaxConsecutiveZCs', 20);
catch err
    vu68 = err.identifier;
end
assert(strcmp(vu68, 'Simulink:Engine:SolverConsecutiveZCNum'), ...
       'Nonadaptive : le modele qui bascule s''arrete sur le diagnostic');
lastwarn('');
r68 = sim(m68, 'Solver', 'ode45', 'StopTime', 1.5, 'MaxConsecutiveZCs', 20, ...
          'ZeroCrossAlgorithm', 'Adaptive');
[~, id68] = lastwarn();
assert(isempty(id68) && abs(r68.tout(end) - 1.5) < 1e-12 && ...
       max(abs(r68.yout(r68.tout > 1.05))) < 0.05, ...
       'Adaptive : la simulation va a son terme, x reste pres de zero');
iZero68 = find(abs(r68.tout - 1) < 1e-9, 1);
assert(~isempty(iZero68) && abs(r68.yout(iZero68)) < 1e-9, ...
       'le premier passage par zero, isole, reste localise exactement a t = 1');
% un passage isolé : le même instant que sans l'algorithme adaptatif
m68 = new_system('isole68');
m68 = add_block(m68, 'sine', 's');
m68 = add_block(m68, 'abs', 'a');
m68 = add_block(m68, 'integrator', 'x');
m68 = add_block(m68, 'outport', 'y');
m68 = add_line(add_line(add_line(m68, 's', 'a'), 'a', 'x'), 'x', 'y');
r1 = sim(m68, 'Solver', 'ode45', 'StopTime', 7, 'RelTol', 1e-8);
r2 = sim(m68, 'Solver', 'ode45', 'StopTime', 7, 'RelTol', 1e-8, 'ZeroCrossAlgorithm', 'Adaptive');
assert(abs(r1.yout(end) - r2.yout(end)) < 1e-9 && abs(r2.yout(end) - (4 + 1 - cos(7))) < 1e-5, ...
       'Adaptive : l''integrale de |sin| est la meme, ses passages localises');
vu68 = '';
try
    set_param(m68, 'ZeroCrossAlgorithm', 'Parfois');
catch err
    vu68 = err.identifier;
end
assert(strcmp(vu68, 'Simulink:Config:InvalidValue'), 'ZeroCrossAlgorithm : deux valeurs seulement');
fprintf('passages par zero adaptatifs : ok\n');

%% ------------------------------------------------------- 69. Simulink.AliasType
% Un Simulink.AliasType donne un autre nom à un type : rangé dans l'espace
% de travail, il se pose sur un bloc par ce nom, et vaut son type de base —
% un type intégré, une virgule fixe, un Simulink.NumericType ou un autre
% alias. Une chaîne d'alias qui revient sur elle-même est refusée.
Vitesse69 = Simulink.AliasType('int16');
assert(strcmp(Vitesse69.BaseType, 'int16') && strcmp(Simulink.AliasType().BaseType, 'double'), ...
       'BaseType : le type de base, double par defaut');
m69 = new_system('alias69');
m69 = add_block(m69, 'constant', 'c', 'Value', 300, 'OutDataTypeStr', 'Vitesse69');
m69 = add_block(m69, 'outport', 'y');
m69 = add_line(m69, 'c', 'y');
reglage69 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1};
r69 = sim(m69, reglage69{:});
assert(isa(r69.yout, 'int16') && all(r69.yout == 300), 'un alias de int16 vaut int16');
Rapide69 = Simulink.AliasType('Vitesse69');
r69 = sim(set_param(m69, 'c', 'OutDataTypeStr', 'Rapide69'), reglage69{:});
assert(isa(r69.yout, 'int16'), 'un alias d''alias vaut le type au bout de la chaine');
Fixe69 = Simulink.AliasType('fixdt(1,16,4)');
r69 = sim(set_param(m69, 'c', 'OutDataTypeStr', 'Fixe69', 'Value', 3.3), reglage69{:});
assert(abs(double(r69.yout(1)) - 3.3125) < 1e-12, ...
       'un alias de virgule fixe : 3,3 arrondi au seizieme le plus proche par defaut');
Boucle69a = Simulink.AliasType('Boucle69b');
Boucle69b = Simulink.AliasType('Boucle69a');
vu69 = '';
message69 = '';
try
    sim(set_param(m69, 'c', 'OutDataTypeStr', 'Boucle69a'), reglage69{:});
catch err
    vu69 = err.identifier;
    message69 = err.message;
end
assert(strcmp(vu69, 'Simulink:DataType:UnknownDataType') && ...
       ~isempty(strfind(message69, 'alias69/c')), ...
       'une chaine d''alias qui boucle est un type inconnu, refuse en nommant le bloc');
vu69 = '';
try
    Simulink.AliasType(16);
catch err
    vu69 = err.identifier;
end
assert(strcmp(vu69, 'Simulink:DataType:AliasBaseType'), 'le type de base est un nom');
clear Vitesse69 Rapide69 Fixe69 Boucle69a Boucle69b
fprintf('alias de types : ok\n');

%% ------------------------------------------------- 70. Transitions de cadence
% Un bloc discret qui lit un bloc discret d'une autre cadence : permis en
% monotâche — SingleTaskRateTransMsg peut le dire —, illégal en multitâche
% (EnableMultiTasking) sans Rate Transition entre eux, ou un Zero-Order
% Hold du rapide au lent, comme dans Simulink. MultiTaskRateTransMsg en
% fait une erreur ou un avertissement qui nomme les deux blocs ;
% AutoInsertRateTranBlk pose les Rate Transition qui manquent, et le modèle
% simule comme si on les avait posés. Les blocs virtuels se traversent.
m70 = new_system('cadences70');
m70 = add_block(m70, 'sine', 'lent', 'SampleTime', 0.2);
m70 = add_block(m70, 'gain', 'rapide', 'Gain', 2, 'SampleTime', 0.1);
m70 = add_block(m70, 'outport', 'y');
m70 = add_line(add_line(m70, 'lent', 'rapide'), 'rapide', 'y');
reglage70 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1, 'StopTime', 1};
assert(strcmp(get_param(m70, 'EnableMultiTasking'), 'off') && ...
       strcmp(get_param(m70, 'MultiTaskRateTransMsg'), 'error') && ...
       strcmp(get_param(m70, 'SingleTaskRateTransMsg'), 'none') && ...
       strcmp(get_param(m70, 'AutoInsertRateTranBlk'), 'off'), ...
       'monotache, et les diagnostics de cadence a leur defaut de Simulink');
lastwarn('');
direct70 = sim(m70, reglage70{:});
[~, id70] = lastwarn();
assert(isempty(id70), 'en monotache, la transition est permise sans rien dire');
vu70 = '';
message70 = '';
try
    sim(m70, reglage70{:}, 'EnableMultiTasking', 'on');
catch err
    vu70 = err.identifier;
    message70 = err.message;
end
assert(strcmp(vu70, 'Simulink:SampleTime:IllegalRateTransition') && ...
       ~isempty(strfind(message70, 'cadences70/lent')) && ...
       ~isempty(strfind(message70, 'cadences70/rapide')), ...
       'en multitache : la transition illegale, qui nomme les deux blocs');
lastwarn('');
sim(m70, reglage70{:}, 'EnableMultiTasking', 'on', 'MultiTaskRateTransMsg', 'warning');
[~, id70] = lastwarn();
assert(strcmp(id70, 'Simulink:SampleTime:IllegalRateTransition'), ...
       'MultiTaskRateTransMsg warning : l''avertissement');
vu70 = '';
try
    sim(m70, reglage70{:}, 'SingleTaskRateTransMsg', 'error');
catch err
    vu70 = err.identifier;
end
assert(strcmp(vu70, 'Simulink:SampleTime:IllegalRateTransition'), ...
       'SingleTaskRateTransMsg error : l''erreur en monotache aussi');
% AutoInsertRateTranBlk : comme un Rate Transition posé à la main
auto70 = sim(m70, reglage70{:}, 'EnableMultiTasking', 'on', 'AutoInsertRateTranBlk', 'on');
main70 = new_system('main70');
main70 = add_block(main70, 'sine', 'lent', 'SampleTime', 0.2);
main70 = add_block(main70, 'ratetransition', 'rt', 'OutPortSampleTime', 0.1);
main70 = add_block(main70, 'gain', 'rapide', 'Gain', 2, 'SampleTime', 0.1);
main70 = add_block(main70, 'outport', 'y');
main70 = add_line(add_line(add_line(main70, 'lent', 'rt'), 'rt', 'rapide'), 'rapide', 'y');
posee70 = sim(main70, reglage70{:}, 'EnableMultiTasking', 'on');
assert(isequal(auto70.yout, posee70.yout) && ~isequal(auto70.yout, direct70.yout), ...
       'AutoInsertRateTranBlk : le Rate Transition pose simule comme celui qu''on pose');
% un Zero-Order Hold du rapide au lent ; un Mux se traverse
zoh70 = new_system('bloqueur70');
zoh70 = add_block(zoh70, 'sine', 'rapide', 'SampleTime', 0.1);
zoh70 = add_block(zoh70, 'zoh', 'z', 'SampleTime', 0.2);
zoh70 = add_block(zoh70, 'outport', 'y');
zoh70 = add_line(add_line(zoh70, 'rapide', 'z'), 'z', 'y');
r70 = sim(zoh70, reglage70{:}, 'EnableMultiTasking', 'on');
assert(numel(r70.yout) == 11, 'un Zero-Order Hold passe du rapide au lent en multitache');
mux70 = new_system('mux70');
mux70 = add_block(mux70, 'sine', 'lent', 'SampleTime', 0.2);
mux70 = add_block(mux70, 'constant', 'c', 'Value', 1);
mux70 = add_block(mux70, 'mux', 'm', 'Inputs', 2);
mux70 = add_block(mux70, 'gain', 'rapide', 'Gain', 2, 'SampleTime', 0.1);
mux70 = add_block(mux70, 'outport', 'y');
mux70 = add_line(add_line(mux70, 'lent', 'm', 1), 'c', 'm', 2);
mux70 = add_line(add_line(mux70, 'm', 'rapide'), 'rapide', 'y');
message70 = '';
try
    sim(mux70, reglage70{:}, 'EnableMultiTasking', 'on');
catch err
    message70 = err.message;
end
assert(~isempty(strfind(message70, 'mux70/lent')) && ~isempty(strfind(message70, 'mux70/rapide')), ...
       'a travers un Mux, la transition est entre les blocs qui calculent');
% dans un sous-système, AutoInsertRateTranBlk pose le Rate Transition dedans
interne70 = new_system('interne70');
interne70 = add_block(interne70, 'inport', 'e', 'Port', 1);
interne70 = add_block(interne70, 'gain', 'rapide', 'Gain', 2, 'SampleTime', 0.1);
interne70 = add_block(interne70, 'outport', 's', 'Port', 1);
interne70 = add_line(add_line(interne70, 'e', 'rapide'), 'rapide', 's');
sous70 = new_system('sous70');
sous70 = add_block(sous70, 'sine', 'lent', 'SampleTime', 0.2);
sous70 = add_block(sous70, 'subsystem', 'sys', 'Model', interne70);
sous70 = add_block(sous70, 'outport', 'y');
sous70 = add_line(add_line(sous70, 'lent', 'sys/1'), 'sys', 'y');
r70 = sim(sous70, reglage70{:}, 'EnableMultiTasking', 'on', 'AutoInsertRateTranBlk', 'on');
assert(isequal(r70.yout, posee70.yout), ...
       'dans un sous-systeme, le Rate Transition se pose sur l''entree du bloc qui lit');
vu70 = '';
try
    set_param(m70, 'MultiTaskRateTransMsg', 'none');
catch err
    vu70 = err.identifier;
end
assert(strcmp(vu70, 'Simulink:Config:InvalidValue'), 'MultiTaskRateTransMsg : warning ou error');
fprintf('transitions de cadence : ok\n');

%% ------------------------------------------ 71. Noms des éléments d'un bus typé
% Un signal nommé qui entre dans un Bus Creator typé sous un autre nom que
% celui de son élément : BusObjectLabelMismatch en décide, comme dans
% Simulink — un avertissement d'office, rien, ou l'arrêt —, en nommant le
% bloc, le signal et l'élément. Un signal sans nom prend celui de
% l'élément.
clear elements71
elements71(1) = Simulink.BusElement;
elements71(1).Name = 'vitesse';
elements71(2) = Simulink.BusElement;
elements71(2).Name = 'position';
Mesures71 = Simulink.Bus;
Mesures71.Elements = elements71;
assignin('base', 'Mesures71', Mesures71);
m71 = new_system('noms71');
m71 = add_block(m71, 'constant', 'v', 'Value', 3);
m71 = add_block(m71, 'constant', 'p', 'Value', 4);
m71 = add_block(m71, 'buscreator', 'bc', 'Inputs', '2', 'OutDataTypeStr', 'Bus: Mesures71');
m71 = add_block(m71, 'busselector', 'bs', 'OutputSignals', 'position');
m71 = add_block(m71, 'outport', 'y');
m71 = add_line(add_line(m71, 'v/1', 'bc/1'), 'p/1', 'bc/2');
m71 = add_line(add_line(m71, 'bc/1', 'bs/1'), 'bs/1', 'y/1');
reglage71 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1};
assert(strcmp(get_param(m71, 'BusObjectLabelMismatch'), 'warning'), ...
       'BusObjectLabelMismatch, a warning par defaut');
lastwarn('');
r71 = sim(m71, reglage71{:});
[~, id71] = lastwarn();
assert(isempty(id71) && all(r71.yout == 4), 'des signaux sans nom prennent ceux des elements');
pv71 = get_param(m71, 'v', 'PortHandles');
m71 = set_param(m71, pv71.Outport(1), 'Name', 'vitesse');
lastwarn('');
sim(m71, reglage71{:});
[~, id71] = lastwarn();
assert(isempty(id71), 'un signal nomme comme son element ne dit rien');
m71 = set_param(m71, pv71.Outport(1), 'Name', 'vitese');
lastwarn('');
r71 = sim(m71, reglage71{:});
[message71, id71] = lastwarn();
assert(strcmp(id71, 'Simulink:Bus:ElementNameMismatch') && ...
       ~isempty(strfind(message71, 'noms71/bc')) && ~isempty(strfind(message71, 'vitese')) && ...
       ~isempty(strfind(message71, 'vitesse')) && all(r71.yout == 4), ...
       'un signal mal nomme : l''avertissement, et la simulation continue');
vu71 = '';
try
    sim(m71, reglage71{:}, 'BusObjectLabelMismatch', 'error');
catch err
    vu71 = err.identifier;
end
assert(strcmp(vu71, 'Simulink:Bus:ElementNameMismatch'), 'BusObjectLabelMismatch error : l''arret');
lastwarn('');
sim(m71, reglage71{:}, 'BusObjectLabelMismatch', 'none');
[~, id71] = lastwarn();
assert(isempty(id71), 'BusObjectLabelMismatch none : rien');
evalin('base', 'clear Mesures71');
fprintf('noms des elements d''un bus : ok\n');

%% ------------------------------------------- 72. Diagnostics des paramètres
% Un paramètre rangé dans un type entier ou à virgule fixe — la valeur
% d'un Constant, le gain d'un Gain dont ParamDataTypeStr est dit — se
% quantifie comme dans Simulink : arrondi au plus proche, sous quatre
% diagnostics — ParameterDowncastMsg (un paramètre typé rangé dans un type
% plus étroit), ParameterOverflowMsg (hors des bornes, saturé si l'on ne
% s'arrête pas), ParameterUnderflowMsg (une valeur que le type annule) et
% ParameterPrecisionLossMsg (une valeur que le type arrondit) —, chacun
% nommant le bloc, le paramètre et la valeur.
m72 = new_system('parametres72');
m72 = add_block(m72, 'constant', 'c', 'Value', 2.7, 'OutDataTypeStr', 'int8');
m72 = add_block(m72, 'outport', 'y');
m72 = add_line(m72, 'c', 'y');
reglage72 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 1, 'StopTime', 1};
assert(strcmp(get_param(m72, 'ParameterDowncastMsg'), 'error') && ...
       strcmp(get_param(m72, 'ParameterOverflowMsg'), 'error') && ...
       strcmp(get_param(m72, 'ParameterUnderflowMsg'), 'none') && ...
       strcmp(get_param(m72, 'ParameterPrecisionLossMsg'), 'warning'), ...
       'les diagnostics des parametres a leur defaut de Simulink');
% la perte de précision : un avertissement d'office, la valeur arrondie
lastwarn('');
r72 = sim(m72, reglage72{:});
[message72, id72] = lastwarn();
assert(strcmp(id72, 'Simulink:Parameters:ParamPrecisionLoss') && ...
       ~isempty(strfind(message72, 'parametres72/c')) && ~isempty(strfind(message72, '2.7')) && ...
       isa(r72.yout, 'int8') && all(r72.yout == 3), ...
       'une valeur que le type arrondit : l''avertissement, et la valeur arrondie');
lastwarn('');
sim(m72, reglage72{:}, 'ParameterPrecisionLossMsg', 'none');
[~, id72] = lastwarn();
assert(isempty(id72), 'ParameterPrecisionLossMsg none : rien');
vu72 = '';
try
    sim(m72, reglage72{:}, 'ParameterPrecisionLossMsg', 'error');
catch err
    vu72 = err.identifier;
end
assert(strcmp(vu72, 'Simulink:Parameters:ParamPrecisionLoss'), ...
       'ParameterPrecisionLossMsg error : l''arret');
lastwarn('');
m72 = set_param(m72, 'c', 'Value', 3);
sim(m72, reglage72{:});
[~, id72] = lastwarn();
assert(isempty(id72), 'une valeur que le type porte exactement ne dit rien');
% le débordement : l'arrêt d'office, sinon la saturation
m72 = set_param(m72, 'c', 'Value', [300 -5]);
vu72 = '';
message72 = '';
try
    sim(m72, reglage72{:});
catch err
    vu72 = err.identifier;
    message72 = err.message;
end
assert(strcmp(vu72, 'Simulink:Parameters:ParamOverflow') && ...
       ~isempty(strfind(message72, 'parametres72/c')) && ~isempty(strfind(message72, '300')) && ...
       ~isempty(strfind(message72, 'int8')), 'une valeur hors des bornes : l''arret');
lastwarn('');
r72 = sim(m72, reglage72{:}, 'ParameterOverflowMsg', 'warning');
[~, id72] = lastwarn();
assert(strcmp(id72, 'Simulink:Parameters:ParamOverflow') && isequal(r72.yout(1, :), int8([127 -5])), ...
       'ParameterOverflowMsg warning : l''avertissement, et la valeur saturee');
r72 = sim(m72, reglage72{:}, 'ParameterOverflowMsg', 'none', 'DataTypeOverride', 'Double');
assert(isa(r72.yout, 'double') && isequal(r72.yout(1, :), [300 -5]), ...
       'sous le Data Type Override, la valeur reste ce qu''elle est');
% une virgule fixe : la valeur que le type annule
m72 = set_param(m72, 'c', 'Value', 0.01, 'OutDataTypeStr', 'fixdt(1,16,4)');
lastwarn('');
r72 = sim(m72, reglage72{:});
[~, id72] = lastwarn();
assert(isempty(id72) && double(r72.yout(1)) == 0, ...
       'ParameterUnderflowMsg none, le defaut : la valeur devient 0 sans rien dire');
lastwarn('');
sim(m72, reglage72{:}, 'ParameterUnderflowMsg', 'warning');
[message72, id72] = lastwarn();
assert(strcmp(id72, 'Simulink:Parameters:ParamUnderflow') && ...
       ~isempty(strfind(message72, 'fix16_En4')), 'ParameterUnderflowMsg warning');
m72 = set_param(m72, 'c', 'Value', 0.5);
lastwarn('');
r72 = sim(m72, reglage72{:});
[~, id72] = lastwarn();
assert(isempty(id72) && double(r72.yout(1)) == 0.5, 'une valeur sur la grille ne dit rien');
% le rétrécissement : un paramètre typé dans un type plus étroit
m72 = set_param(m72, 'c', 'Value', 'int32(5)', 'OutDataTypeStr', 'int8');
vu72 = '';
try
    sim(m72, reglage72{:});
catch err
    vu72 = err.identifier;
end
assert(strcmp(vu72, 'Simulink:Parameters:ParamDowncast'), ...
       'un int32 range en int8 : le retrecissement, refuse d''office');
r72 = sim(m72, reglage72{:}, 'ParameterDowncastMsg', 'none');
assert(isequal(r72.yout(1), int8(5)), 'ParameterDowncastMsg none : la valeur passe');
m72 = set_param(m72, 'c', 'Value', 'int8(5)', 'OutDataTypeStr', 'int16');
r72 = sim(m72, reglage72{:});
assert(isequal(r72.yout(1), int16(5)), 'un int8 range en int16 s''elargit sans rien dire');
% le gain d'un Gain, dans son ParamDataTypeStr
g72 = new_system('gain72');
g72 = add_block(g72, 'constant', 'c', 'Value', 2, 'OutDataTypeStr', 'int8');
g72 = add_block(g72, 'gain', 'k', 'Gain', 2.6, 'ParamDataTypeStr', 'int8', ...
                'OutDataTypeStr', 'int16');
g72 = add_block(g72, 'outport', 'y');
g72 = add_line(add_line(g72, 'c', 'k'), 'k', 'y');
lastwarn('');
r72 = sim(g72, reglage72{:});
[message72, id72] = lastwarn();
assert(strcmp(id72, 'Simulink:Parameters:ParamPrecisionLoss') && ...
       ~isempty(strfind(message72, 'Gain')) && ~isempty(strfind(message72, 'gain72/k')) && ...
       isequal(r72.yout(1), int16(6)), 'le gain arrondi dans son type : 3 fois 2');
g72 = set_param(g72, 'k', 'Gain', 1000);
vu72 = '';
try
    sim(g72, reglage72{:});
catch err
    vu72 = err.identifier;
end
assert(strcmp(vu72, 'Simulink:Parameters:ParamOverflow'), 'un gain qui deborde de son type');
g72 = set_param(g72, 'k', 'ParamDataTypeStr', 'int16');
r72 = sim(g72, reglage72{:});
assert(isequal(r72.yout(1), int16(2000)), 'dans un type assez large, le gain passe');
vu72 = '';
try
    set_param(m72, 'ParameterOverflowMsg', 'oui');
catch err
    vu72 = err.identifier;
end
assert(strcmp(vu72, 'Simulink:Config:InvalidValue'), 'ParameterOverflowMsg : none, warning ou error');
fprintf('diagnostics des parametres : ok\n');

%% ------------------------------------------- 73. L'état de fonctionnement
% SaveOperatingPoint, comme dans Simulink : l'état final est l'état de
% fonctionnement complet, un Simulink.op.ModelOperatingPoint — états
% continus et discrets, sorties tenues, tampons des retards, générateurs
% aléatoires —, et la simulation qui le charge reprend à son instant. À
% pas fixe, la reprise rend exactement la simulation d'une traite ; les
% états continus seuls (xFinal sans SaveOperatingPoint) n'y suffisent pas
% dès qu'un bloc discret tient un état. Il ne se charge que dans le modèle
% d'où il vient, tel qu'il était.
m73 = new_system('reprise73');
m73 = add_block(m73, 'step', 's', 'Time', 0.3);
m73 = add_block(m73, 'transferfcn', 'tf', 'Numerator', 1, 'Denominator', [1 1]);
m73 = add_block(m73, 'unitdelay', 'z', 'SampleTime', 0.1, 'InitialCondition', 0.5);
m73 = add_block(m73, 'discreteintegrator', 'di', 'SampleTime', 0.05);
m73 = add_block(m73, 'transportdelay', 'td', 'DelayTime', 0.25);
m73 = add_block(m73, 'randomnumber', 'bruit', 'SampleTime', 0.1, 'Seed', 7);
m73 = add_block(m73, 'sum', 'som', 'Signs', '++++');
m73 = add_block(m73, 'outport', 'y');
m73 = add_line(m73, 's', 'tf');
m73 = add_line(add_line(add_line(m73, 'tf', 'z'), 'tf', 'td'), 'tf', 'di');
m73 = add_line(add_line(m73, 'z', 'som', 1), 'td', 'som', 2);
m73 = add_line(add_line(m73, 'di', 'som', 3), 'bruit', 'som', 4);
m73 = add_line(m73, 'som', 'y');
fixe73 = {'Solver', 'ode4', 'FixedStep', 0.01};
assert(strcmp(get_param(m73, 'SaveOperatingPoint'), 'off'), 'SaveOperatingPoint, off par defaut');
entier73 = sim(m73, fixe73{:}, 'StopTime', 2);
a73 = sim(m73, fixe73{:}, 'StopTime', 1, 'SaveFinalState', 'on', 'SaveOperatingPoint', 'on');
op73 = a73.xFinal;
assert(isa(op73, 'Simulink.op.ModelOperatingPoint') && strcmp(op73.modelName, 'reprise73') && ...
       op73.snapshotTime == 1 && op73.startTime == 0, ...
       'l''etat final est l''etat de fonctionnement, pris a la fin');
assert(~isempty(strfind(evalc('disp(op73)'), 'ModelOperatingPoint with properties')) && ...
       ~isempty(strfind(evalc('disp(op73)'), 'snapshotTime: 1')), 'il s''affiche comme dans Simulink');
b73 = sim(m73, fixe73{:}, 'StopTime', 2, 'LoadInitialState', 'on', 'InitialState', op73);
garde73 = entier73.tout >= 1 - 1e-12;
assert(abs(b73.tout(1) - 1) < 1e-12 && isequal(b73.yout, entier73.yout(garde73)) && ...
       max(abs(b73.tout - entier73.tout(garde73))) < 1e-12, ...
       'a pas fixe, la reprise rend exactement la simulation d''une traite');
b73bis = sim(m73, fixe73{:}, 'StopTime', 2, 'LoadInitialState', 'on', 'InitialState', op73);
assert(isequal(b73bis.yout, b73.yout), 'un etat de fonctionnement se reprend autant qu''on veut');
% les états continus seuls ne suffisent pas : le retard unitaire repart
% de sa condition initiale
x73 = sim(m73, fixe73{:}, 'StopTime', 1, 'SaveFinalState', 'on');
assert(isnumeric(x73.xFinal), 'sans SaveOperatingPoint, xFinal porte les etats continus');
c73 = sim(m73, fixe73{:}, 'StartTime', 1, 'StopTime', 2, 'LoadInitialState', 'on', ...
          'InitialState', x73.xFinal);
assert(~isequal(c73.yout, entier73.yout(garde73)), ...
       'les etats continus seuls ne reprennent pas les blocs discrets');
% par son nom dans l'espace de travail, et par un SimulationInput
assignin('base', 'op73base', op73);
d73 = sim(m73, fixe73{:}, 'StopTime', 2, 'LoadInitialState', 'on', 'InitialState', 'op73base');
assert(isequal(d73.yout, b73.yout), 'l''etat de fonctionnement par son nom');
evalin('base', 'clear op73base');
reprise73 = m73;   % SIM(IN) trouve le modele sous son nom
in73 = Simulink.SimulationInput('reprise73');
in73 = in73.setModelParameter('Solver', 'ode4', 'FixedStep', '0.01', 'StopTime', '2');
in73 = in73.setInitialState(op73);
e73 = sim(in73);
assert(isequal(e73.yout, b73.yout), 'l''etat de fonctionnement dans un SimulationInput');
% à pas variable : la reprise suit la simulation d'une traite, le solveur
% repartant de son premier pas
variable73 = {'Solver', 'ode45', 'RelTol', 1e-8, 'AbsTol', 1e-10, 'MaxStep', 0.01};
entierV73 = sim(m73, variable73{:}, 'StopTime', 2);
aV73 = sim(m73, variable73{:}, 'StopTime', 1, 'SaveFinalState', 'on', 'SaveOperatingPoint', 'on');
bV73 = sim(m73, variable73{:}, 'StopTime', 2, 'LoadInitialState', 'on', ...
           'InitialState', aV73.xFinal);
assert(abs(bV73.tout(1) - 1) < 1e-12 && abs(bV73.tout(end) - 2) < 1e-12 && ...
       abs(bV73.yout(end) - entierV73.yout(end)) < 1e-6, ...
       'a pas variable, la reprise rejoint la simulation d''une traite');
% un diagramme Stateflow reprend dans son état, son horloge comprise
graphe73 = sfchart('clignoteur73');
graphe73 = sfstate(graphe73, 'eteint', @(c) setfield(c, 'lampe', 0));
graphe73 = sfstate(graphe73, 'allume', @(c) setfield(c, 'lampe', 1));
graphe73 = sftransition(graphe73, 'eteint', 'allume', @(c, u) sfafter(c, 0.5, 'sec'));
graphe73 = sftransition(graphe73, 'allume', 'eteint', @(c, u) sfafter(c, 0.5, 'sec'));
clignote73 = new_system('clignote73');
clignote73 = add_block(clignote73, 'chart', 'lampe', 'Chart', graphe73, 'Inputs', 0, ...
                       'Outputs', {'lampe'}, 'InitialContext', struct('lampe', 0), ...
                       'SampleTime', 0.1);
clignote73 = add_line(add_block(clignote73, 'outport', 'y'), 'lampe', 'y');
discret73 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1};
toutG73 = sim(clignote73, discret73{:}, 'StopTime', 2);
aG73 = sim(clignote73, discret73{:}, 'StopTime', 0.7, 'SaveFinalState', 'on', ...
           'SaveOperatingPoint', 'on');
bG73 = sim(clignote73, discret73{:}, 'StopTime', 2, 'LoadInitialState', 'on', ...
           'InitialState', aG73.xFinal);
assert(isequal(bG73.yout, toutG73.yout(toutG73.tout >= 0.7 - 1e-9)) && ...
       numel(unique(bG73.yout)) == 2, 'un diagramme reprend dans son etat, a son heure');
% ce qui ne se charge pas
decale73 = sim(m73, fixe73{:}, 'StopTime', 1.03, 'SaveFinalState', 'on', ...
               'SaveOperatingPoint', 'on');
decale73 = decale73.xFinal;   % pris a t = 1,03 : pas un pas de 0,05
autre73 = new_system('autre73');
autre73 = add_line(add_block(add_block(autre73, 'constant', 'c'), 'outport', 'y'), 'c', 'y');
refus73 = {
    @() sim(autre73, 'LoadInitialState', 'on', 'InitialState', op73), ...
        'Simulink:SimInput:OperatingPointModelMismatch', 'reprise73'
    @() sim(add_block(m73, 'gain', 'neuf'), fixe73{:}, 'StopTime', 2, ...
            'LoadInitialState', 'on', 'InitialState', op73), ...
        'Simulink:SimInput:OperatingPointModelMismatch', 'reprise73'
    @() sim(m73, fixe73{:}, 'StopTime', 1, 'LoadInitialState', 'on', 'InitialState', op73), ...
        'Simulink:SimInput:OperatingPointStopTime', 'StopTime'
    @() sim(m73, fixe73{:}, 'StartTime', 0.5, 'StopTime', 2, 'LoadInitialState', 'on', ...
            'InitialState', op73), 'Simulink:SimInput:OperatingPointStartTime', 'StartTime'
    @() sim(m73, 'Solver', 'ode4', 'FixedStep', 0.05, 'StopTime', 2, 'LoadInitialState', 'on', ...
            'InitialState', decale73), 'Simulink:SimInput:OperatingPointStep', 'reprise73'
    @() sim(m73, fixe73{:}, 'StopTime', 2, 'LoadInitialState', 'on', ...
            'InitialState', Simulink.op.ModelOperatingPoint()), ...
        'Simulink:SimInput:InvalidOperatingPoint', 'reprise73'
    @() sim(m73, variable73{:}, 'StopTime', 2, 'LoadInitialState', 'on', 'InitialState', op73), ...
        'Simulink:SimInput:OperatingPointSolver', 'reprise73'
    @() set_param(m73, 'SaveOperatingPoint', 'oui'), 'Simulink:Config:InvalidValue', ...
        'SaveOperatingPoint'
    };
for q = 1:size(refus73, 1)
    vu73 = '';
    message73 = '';
    try
        refus73{q, 1}();
    catch err
        vu73 = err.identifier;
        message73 = err.message;
    end
    assert(strcmp(vu73, refus73{q, 2}) && ~isempty(strfind(message73, refus73{q, 3})), ...
           sprintf('etat de fonctionnement, refus %d : %s', q, vu73));
end
f73 = sim(m73, fixe73{:}, 'StopTime', 1, 'SaveOperatingPoint', 'on');
assert(~isfield(f73, 'xFinal'), 'SaveOperatingPoint sans SaveFinalState : pas d''etat final');
fprintf('etat de fonctionnement : ok\n');

%% -------------------------- 74. Sous-systèmes remettables, atomiques, étiquettes
% Le Resettable Subsystem de Simulink : un port Reset, et au front — ou au
% niveau — de son signal, tous les états du dedans reviennent à leurs
% conditions initiales, continus comme discrets. L'Atomic Subsystem :
% SystemSampleTime impose sa période aux blocs qui l'héritent, et refuse
% en les nommant ceux qui en ont une autre, ou qui sont continus. Le Goto
% Tag Visibility ouvre la portée d'un Goto « scoped » à son système. Le
% Floating Scope n'a pas d'entrée.
interne74 = new_system('compteur74');
interne74 = add_block(interne74, 'inport', 'In1', 'Port', 1);
interne74 = add_block(interne74, 'discreteintegrator', 'somme', 'SampleTime', 0.1);
interne74 = add_block(interne74, 'unitdelay', 'retard', 'SampleTime', 0.1, 'InitialCondition', -1);
interne74 = add_block(interne74, 'outport', 'Out1', 'Port', 1);
interne74 = add_block(interne74, 'outport', 'Out2', 'Port', 2);
interne74 = add_block(interne74, 'resetport', 'Reset', 'ResetTriggerType', 'rising');
interne74 = add_line(add_line(interne74, 'In1', 'somme'), 'somme', 'Out1');
interne74 = add_line(add_line(interne74, 'In1', 'retard'), 'retard', 'Out2');
m74 = new_system('remise74');
m74 = add_block(m74, 'constant', 'un', 'Value', 1);
m74 = add_block(m74, 'pulsegenerator', 'horloge', 'Period', 1, 'PulseWidth', 50);
m74 = add_block(m74, 'subsystem', 'sous', 'Model', interne74);
m74 = add_block(m74, 'outport', 'y');
m74 = add_block(m74, 'outport', 'y2');
m74 = add_line(add_line(m74, 'un', 'sous/1'), 'horloge', 'sous/Reset');
m74 = add_line(add_line(m74, 'sous/1', 'y'), 'sous/2', 'y2');
reglage74 = {'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1, 'StopTime', 2.5};
r74 = sim(m74, reglage74{:});
a74 = @(r, t) r.yout(abs(r.tout - t) < 1e-9, :);
assert(all(abs(a74(r74, 0.9) - [0.9 1]) < 1e-12), 'avant le front, la somme monte');
assert(all(abs(a74(r74, 1) - [0 -1]) < 1e-12) && all(abs(a74(r74, 1.5) - [0.5 1]) < 1e-12) && ...
       all(abs(a74(r74, 2) - [0 -1]) < 1e-12), ...
       'au front montant du Reset, les etats du dedans reviennent a leurs conditions initiales');
% au front descendant, puis dans les deux sens
interne74 = set_param(interne74, 'Reset', 'ResetTriggerType', 'falling');
r74 = sim(set_param(m74, 'sous', 'Model', interne74), reglage74{:});
assert(abs(a74(r74, 0.5) * [1; 0]) < 1e-12 && abs(a74(r74, 1.4) * [1; 0] - 0.9) < 1e-12 && ...
       abs(a74(r74, 1.5) * [1; 0]) < 1e-12, 'Reset falling : au front descendant');
interne74 = set_param(interne74, 'Reset', 'ResetTriggerType', 'either');
r74 = sim(set_param(m74, 'sous', 'Model', interne74), reglage74{:});
assert(abs(a74(r74, 0.5) * [1; 0]) < 1e-12 && abs(a74(r74, 1) * [1; 0]) < 1e-12 && ...
       abs(a74(r74, 1.4) * [1; 0] - 0.4) < 1e-12, 'Reset either : aux deux fronts');
% au niveau : tant que le signal n'est pas nul, et quand il retombe
interne74 = set_param(interne74, 'Reset', 'ResetTriggerType', 'level hold');
r74 = sim(set_param(m74, 'sous', 'Model', interne74), reglage74{:});
assert(abs(a74(r74, 0.4) * [1; 0]) < 1e-12 && abs(a74(r74, 0.9) * [1; 0] - 0.5) < 1e-12, ...
       'Reset level hold : remis tant que le signal est haut');
interne74 = set_param(interne74, 'Reset', 'ResetTriggerType', 'level');
r74 = sim(set_param(m74, 'sous', 'Model', interne74), reglage74{:});
assert(abs(a74(r74, 0.4) * [1; 0]) < 1e-12 && abs(a74(r74, 0.9) * [1; 0] - 0.4) < 1e-12, ...
       'Reset level : remis tant que le signal est haut, et quand il retombe');
% un intégrateur continu se remet aussi
continu74 = new_system('continu74');
continu74 = add_block(continu74, 'inport', 'In1', 'Port', 1);
continu74 = add_block(continu74, 'integrator', 'x', 'InitialCondition', 2);
continu74 = add_block(continu74, 'outport', 'Out1', 'Port', 1);
continu74 = add_block(continu74, 'resetport', 'Reset');
continu74 = add_line(add_line(continu74, 'In1', 'x'), 'x', 'Out1');
c74 = new_system('remiseContinue74');
c74 = add_block(c74, 'constant', 'un', 'Value', 1);
c74 = add_block(c74, 'step', 'front', 'Time', 1);
c74 = add_block(c74, 'subsystem', 'sous', 'Model', continu74);
c74 = add_block(c74, 'outport', 'y');
c74 = add_line(add_line(add_line(c74, 'un', 'sous/1'), 'front', 'sous/Reset'), 'sous', 'y');
r74 = sim(c74, 'Solver', 'ode4', 'FixedStep', 0.01, 'StopTime', 2);
assert(abs(a74(r74, 0.99) - 2.99) < 1e-9 && abs(a74(r74, 1) - 2) < 1e-9 && ...
       abs(a74(r74, 2) - 3) < 1e-9, 'l''etat continu revient a sa condition initiale au front');
% le sous-système de la bibliothèque arrive garni de son port Reset, et
% se relit d'un .slx
biblio74 = add_block(new_system('biblio74'), 'simulink/Ports & Subsystems/Resettable Subsystem', ...
                     'r');
garni74 = matlibre_sl_modele(get_param(biblio74, 'r', 'Model'));
assert(any(cellfun(@(b) strcmp(b.type, 'resetport'), garni74.blocs)), ...
       'le Resettable Subsystem porte son port Reset');
fichier74 = save_system(m74, fullfile(tempdir(), 'remise74.slx'));
relu74 = load_system(fichier74);
r74 = sim(m74, reglage74{:});
assert(isequal(sim(relu74, reglage74{:}).yout, r74.yout), 'un sous-systeme remettable se relit du .slx');
delete(fichier74);
% le sous-système atomique et sa période
dedans74 = new_system('atome74');
dedans74 = add_block(dedans74, 'inport', 'In1', 'Port', 1);
dedans74 = add_block(dedans74, 'unitdelay', 'z');
dedans74 = add_block(dedans74, 'outport', 'Out1', 'Port', 1);
dedans74 = add_line(add_line(dedans74, 'In1', 'z'), 'z', 'Out1');
t74 = new_system('atomique74');
t74 = add_block(t74, 'clock', 'horloge');
t74 = add_block(t74, 'simulink/Ports & Subsystems/Atomic Subsystem', 'a', 'Model', dedans74, ...
                'SystemSampleTime', 0.5);
t74 = add_block(t74, 'outport', 'y');
t74 = add_line(add_line(t74, 'horloge', 'a'), 'a', 'y');
assert(strcmp(get_param(t74, 'a', 'TreatAsAtomicUnit'), 'on'), ...
       'l''Atomic Subsystem de la bibliotheque est atomique');
r74 = sim(t74, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1, 'StopTime', 2);
assert(abs(a74(r74, 0.7) - 0) < 1e-12 && abs(a74(r74, 1.2) - 0.5) < 1e-12 && ...
       abs(a74(r74, 1.9) - 1) < 1e-12, ...
       'SystemSampleTime : le retard du dedans tient sa valeur une demi-seconde');
refus74 = {
    set_param(dedans74, 'z', 'SampleTime', 0.2), ...
        'Simulink:SampleTime:AtomicSubsystemSampleTimeMismatch', 'atomique74/a/z'
    add_line(add_block(add_block(new_system('atome74'), 'inport', 'In1', 'Port', 1), ...
                       'integrator', 'x'), 'In1', 'x'), ...
        'Simulink:SampleTime:AtomicSubsystemContinuousBlock', 'atomique74/a/x'
    };
for q = 1:size(refus74, 1)
    vu74 = '';
    message74 = '';
    try
        sim(set_param(t74, 'a', 'Model', refus74{q, 1}), 'Solver', 'ode4', 'FixedStep', 0.1, ...
            'StopTime', 1);
    catch err
        vu74 = err.identifier;
        message74 = err.message;
    end
    assert(strcmp(vu74, refus74{q, 2}) && ~isempty(strfind(message74, refus74{q, 3})), ...
           sprintf('sous-systeme atomique, refus %d : %s', q, vu74));
end
% le Goto Tag Visibility
b74 = new_system('B74');
b74 = add_block(b74, 'constant', 'c', 'Value', 5);
b74 = add_block(b74, 'goto', 'g', 'GotoTag', 'X', 'TagVisibility', 'scoped');
b74 = add_line(b74, 'c', 'g');
dessus74 = new_system('A74');
dessus74 = add_block(dessus74, 'subsystem', 'B', 'Model', b74);
dessus74 = add_block(dessus74, 'from', 'f', 'GotoTag', 'X');
dessus74 = add_block(dessus74, 'outport', 'o', 'Port', 1);
dessus74 = add_line(dessus74, 'f', 'o');
g74 = new_system('etiquette74');
g74 = add_block(g74, 'subsystem', 'A', 'Model', dessus74);
g74 = add_block(g74, 'outport', 'y');
g74 = add_line(g74, 'A', 'y');
vu74 = '';
try
    sim(g74, 'Solver', 'FixedStepDiscrete', 'StopTime', 1);
catch err
    vu74 = err.identifier;
end
assert(strcmp(vu74, 'Simulink:Engine:GotoTagMissing'), ...
       'sans Goto Tag Visibility, un Goto scoped ne se voit pas de plus haut');
dessus74 = add_block(dessus74, 'simulink/Signal Routing/Goto Tag Visibility', 'v', ...
                     'GotoTag', 'X');
r74 = sim(set_param(g74, 'A', 'Model', dessus74), 'Solver', 'FixedStepDiscrete', 'StopTime', 1);
assert(all(r74.yout == 5), 'le Goto Tag Visibility ouvre la portee a son systeme');
% le Floating Scope, sans entrée
f74 = add_block(t74, 'simulink/Sinks/Floating Scope', 'flottant');
assert(strcmp(get_param(f74, 'flottant', 'Floating'), 'on'), 'un Floating Scope flotte');
sim(f74, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.1, 'StopTime', 1);
assert(strcmp(getfield(matlibre_sl_catalogue('type', ...
           'simulink/Continuous/Second-Order Integrator'), 'type'), 'secondorderintegrator'), ...
       'le Second-Order Integrator sous son nom de bibliotheque');
fprintf('sous-systemes remettables et atomiques : ok\n');

%% ----------------------------------------- 75. Attributs des signaux
% Le Probe mesure son entrée comme dans Simulink : sa largeur, sa période
% [Ts, décalage], sa complexité et ses dimensions, celles que ses réglages
% demandent. Le Data Type Duplicate exige que ses entrées soient d'un même
% type, et le dit en nommant les deux. Le Data Type Conversion Inherited
% convertit sa première entrée dans le type de la seconde.
m75 = new_system('sonde75');
m75 = add_block(m75, 'constant', 'c', 'Value', [1 2 3; 4 5 6], 'SampleTime', 0.5);
m75 = add_block(m75, 'probe', 'p', 'ProbeSignalDimensions', 'on');
m75 = add_block(m75, 'outport', 'largeur', 'Port', 1);
m75 = add_block(m75, 'outport', 'periode', 'Port', 2);
m75 = add_block(m75, 'outport', 'complexe', 'Port', 3);
m75 = add_block(m75, 'outport', 'dims', 'Port', 4);
m75 = add_line(m75, 'c', 'p');
m75 = add_line(add_line(m75, 'p/1', 'largeur/1'), 'p/2', 'periode/1');
m75 = add_line(add_line(m75, 'p/3', 'complexe/1'), 'p/4', 'dims/1');
r75 = sim(m75, 'Solver', 'FixedStepDiscrete', 'FixedStep', 0.5, 'StopTime', 1, ...
          'SaveFormat', 'Structure');
assert(isequal(r75.yout.signals(1).values(end, :), 6) && ...
       isequal(r75.yout.signals(2).values(end, :), [0.5 0]) && ...
       isequal(r75.yout.signals(3).values(end, :), 0) && ...
       isequal(r75.yout.signals(4).values(end, :), [2 3]), ...
       'le Probe : largeur 6, periode [0,5 0], reel, dimensions [2 3]');
continu75 = new_system('sondeContinue75');
continu75 = add_block(continu75, 'sine', 's');
continu75 = add_block(continu75, 'gain', 'g', 'Gain', 1i);
continu75 = add_block(continu75, 'probe', 'p', 'ProbeWidth', 'off');
continu75 = add_block(continu75, 'outport', 'periode', 'Port', 1);
continu75 = add_block(continu75, 'outport', 'complexe', 'Port', 2);
continu75 = add_line(add_line(continu75, 's', 'g'), 'g', 'p');
continu75 = add_line(add_line(continu75, 'p/1', 'periode/1'), 'p/2', 'complexe/1');
r75 = sim(continu75, 'Solver', 'ode4', 'FixedStep', 0.1, 'StopTime', 0.5, 'SaveFormat', 'Structure');
assert(isequal(r75.yout.signals(1).values(end, :), [0 0]) && ...
       r75.yout.signals(2).values(end) == 1 && isreal(r75.yout.signals(2).values), ...
       'un signal continu et complexe : periode [0 0], complexe 1, en reel');
% le Data Type Duplicate
d75 = new_system('doublon75');
d75 = add_block(d75, 'constant', 'a', 'Value', 1, 'OutDataTypeStr', 'int16');
d75 = add_block(d75, 'constant', 'b', 'Value', 2, 'OutDataTypeStr', 'int16');
d75 = add_block(d75, 'datatypeduplicate', 'meme');
d75 = add_line(add_line(d75, 'a', 'meme/1'), 'b', 'meme/2');
sim(d75, 'Solver', 'FixedStepDiscrete', 'StopTime', 1);
vu75 = '';
message75 = '';
try
    sim(set_param(d75, 'b', 'OutDataTypeStr', 'int8'), 'Solver', 'FixedStepDiscrete', 'StopTime', 1);
catch err
    vu75 = err.identifier;
    message75 = err.message;
end
assert(strcmp(vu75, 'Simulink:DataType:DataTypeDuplicateMismatch') && ...
       ~isempty(strfind(message75, 'doublon75/meme')) && ~isempty(strfind(message75, 'int8')) && ...
       ~isempty(strfind(message75, 'int16')), ...
       'deux types differents au Data Type Duplicate : refuses en les nommant');
% le Data Type Conversion Inherited
h75 = new_system('herite75');
h75 = add_block(h75, 'constant', 'u', 'Value', 300.7);
h75 = add_block(h75, 'constant', 'ref', 'Value', 0, 'OutDataTypeStr', 'uint8');
h75 = add_block(h75, 'simulink/Signal Attributes/Data Type Conversion Inherited', 'conv', ...
                'SaturateOnIntegerOverflow', 'on');
h75 = add_block(h75, 'outport', 'y');
h75 = add_line(add_line(add_line(h75, 'u', 'conv/1'), 'ref', 'conv/2'), 'conv', 'y');
r75 = sim(h75, 'Solver', 'FixedStepDiscrete', 'StopTime', 1);
assert(isa(r75.yout, 'uint8') && all(r75.yout == 255), ...
       'Data Type Conversion Inherited : le type de la reference, sature');
h75 = set_param(set_param(h75, 'u', 'Value', 7.9), 'ref', 'OutDataTypeStr', 'int8');
r75 = sim(h75, 'Solver', 'FixedStepDiscrete', 'StopTime', 1);
assert(isa(r75.yout, 'int8') && all(r75.yout == 7), ...
       'Data Type Conversion Inherited arrondit vers le bas (Floor) par defaut');
fprintf('attributs des signaux : ok\n');

disp('simulink domaines : toutes les verifications passent');
