classdef ModelOperatingPoint
%MODELOPERATINGPOINT L'état de fonctionnement complet d'une simulation.
%   SIM le rend comme état final quand SaveFinalState et SaveOperatingPoint
%   valent 'on' : l'instant où la simulation s'arrête et tout ce qu'il
%   faut pour la reprendre là exactement — les états continus, les états
%   discrets, les sorties tenues, les tampons des retards, l'état des
%   diagrammes Stateflow et des sous-systèmes itérés.
%
%   Donné à InitialState, LoadInitialState à 'on', il fait reprendre la
%   simulation à son instant, snapshotTime : à pas fixe, la reprise rend
%   exactement ce qu'aurait rendu la simulation d'une traite ; à pas
%   variable, le solveur repart de son premier pas.
%
%   Propriétés : modelName, le modèle d'où il vient ; snapshotTime,
%   l'instant où il a été pris ; startTime, le début de la simulation
%   d'origine ; description, un texte libre.
%
%   On ne le construit pas soi-même : il vient de SIM.
%
%   Exemple :
%      m = new_system('reprise');
%      m = add_block(m, 'step', 's');
%      m = add_block(m, 'unitdelay', 'z', 'SampleTime', 0.1);
%      m = add_block(m, 'outport', 'y');
%      m = add_line(add_line(m, 's', 'z'), 'z', 'y');
%      a = sim(m, 'StopTime', 1, 'SaveFinalState', 'on', ...
%              'SaveOperatingPoint', 'on', 'Solver', 'FixedStepDiscrete');
%      a.xFinal.snapshotTime                       % 1
%      b = sim(m, 'StopTime', 2, 'LoadInitialState', 'on', ...
%              'InitialState', a.xFinal, 'Solver', 'FixedStepDiscrete');
%      b.tout(1)                                   % 1
%
%   Voir aussi SIM, SIMULINK.SIMULATIONINPUT.
    properties
        modelName = ''
        snapshotTime = 0
        startTime = 0
        description = ''
    end
    properties (Hidden)
        % tout ce que la reprise lit, rangé par SIM
        Etat = []
    end
    methods
        function op = ModelOperatingPoint(nom, instant, debut, etat)
            if nargin == 4
                op.modelName = char(nom);
                op.snapshotTime = instant;
                op.startTime = debut;
                op.Etat = etat;
            end
        end
        function op = set.description(op, texte)
            if ~(ischar(texte) || isstring(texte))
                error('Simulink:SimInput:InvalidOperatingPoint', ...
                      'La description d''un etat de fonctionnement est un texte.');
            end
            op.description = char(texte);
        end
        function disp(op)
            fprintf(['  ModelOperatingPoint with properties:\n\n       modelName: ''%s''\n' ...
                     '    snapshotTime: %s\n       startTime: %s\n     description: ''%s''\n\n'], ...
                    op.modelName, num2str(op.snapshotTime, 10), num2str(op.startTime, 10), ...
                    op.description);
        end
    end
end
