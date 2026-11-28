% test_simulink_catalogue.m — le moteur de Simulink, 2/4 : section 26 bis — les paires
% de blocs du catalogue, les défauts de Simulink et les erreurs.
%
% Chaque vérification porte sur une propriété qui définit le calcul : une
% formule fermée, une invariance, un ordre de convergence mesuré, un
% message d'erreur qui nomme le bloc fautif. Les combinaisons sont
% engendrées : sources, traitements, dimensions, solveurs et périodes se
% croisent, et chaque croisement est comparé au calcul direct.
disp('--- simulink catalogue ---');
% Le test, quinze mille lignes et vingt-cinq minutes d'un bloc, est coupé en
% quatre parts que la batterie fait tourner de front ; leurs fonctions d'aide
% communes vivent dans simulink/.
addpath(fullfile(fileparts(mfilename('fullpath')), 'simulink'));

%% ---------------------- 26 bis. Batteries croisees sur tout le catalogue (suite)
% Les paires de blocs, les défauts de Simulink et les erreurs, sur la même
% liste de types, dans un dossier temporaire à elles. La batterie est
% coupée ici pour que les deux moitiés tiennent chacune dans une part de
% test_simulink : elle en faisait à elle seule la moitié de la durée.
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
    @() add_block(new_system('m'), 'iterateur', 'i'), 'Simulink:Commands:InvalidBlockType', 'internal'
    @() add_block(new_system('m'), 'garde', 'g'), 'Simulink:Commands:InvalidBlockType', 'internal'
    @() sim(add_block(new_system('vide'), 'subsystem', 's')), 'Simulink:Commands:SousSystemeVide', 'vide/s'
    @() sim(add_block(new_system('r'), 'modelreference', 'm')), ...
        'Simulink:modelReference:ModelNameEmpty', 'r/m'
    @() get_param(modeleVoisin, 'absent', 'Value'), 'Simulink:Commands:InvSimulinkObjectName', 'absent'
    @() set_param(modeleVoisin, 'absent', 'Value', 1), 'Simulink:Commands:InvSimulinkObjectName', 'absent'
    @() add_line(modeleVoisin, 'c/1', 'absent/1'), 'Simulink:Commands:InvSimulinkObjectName', 'absent'
    @() get_param(modeleVoisin, 'c', 'Absent'), 'Simulink:Commands:ParamUnknown', 'Absent'
    @() delete_line(modeleVoisin, 'c/1', 'c/1'), 'Simulink:Commands:DeleteLineNoLine', 'c'
    @() sim(modeleVoisin, 'StartTime', 2, 'StopTime', 1), ...
        'Simulink:SolverConfig:StopTimeBeforeStartTime', 'duration'
    @() sim(add_block(new_system('fw'), 'fromworkspace', 'f')), ...
        'Simulink:blocks:FromWorkspaceVariableNotFound', 'fw/f'
    @() sim(add_block(new_system('cplx'), 'saturation', 's', 'UpperLimit', 1 + 2i)), ...
        'Simulink:Parameters:InvParamSetting', 'complex'
    @() sim(add_block(new_system('vide'), 'constant', 'c', 'Value', [])), ...
        'Simulink:Parameters:InvParamSetting', 'vide/c'
    @() sim(add_block(new_system('sg'), 'sum', 's', 'Signs', '+x')), ...
        'Simulink:Parameters:InvParamSetting', 'Signs'
    @() sim(add_block(new_system('pr'), 'product', 'p', 'Inputs', '*+')), ...
        'Simulink:Parameters:InvParamSetting', 'Inputs'
    @() sim(add_block(new_system('st'), 'constant', 'c', 'SampleTime', NaN)), ...
        'Simulink:SampleTime:InvalidSampleTime', 'st/c'
    @() sim(add_block(new_system('po'), 'inport', 'i', 'Port', 0)), ...
        'Simulink:Parameters:InvParamSetting', 'positive integer'
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

disp('simulink catalogue : toutes les verifications passent');
