function signaux = matlibre_sl_scenario(fichier, scenario, chemin)
%MATLIBRE_SL_SCENARIO Les signaux d'un scénario du Signal Editor.
%   S = MATLIBRE_SL_SCENARIO(FICHIER,SCENARIO,CHEMIN) lit dans le fichier
%   MAT FICHIER la variable SCENARIO, un Simulink.SimulationData.Dataset
%   dont chaque élément est une timeseries, ou un
%   Simulink.SimulationData.Signal qui en porte une. Rend un tableau de
%   structures, une par signal : nom, temps (colonne), valeurs (une ligne
%   par instant), methode ('linear', ou 'previous' pour une timeseries en
%   tenue d'ordre zéro). CHEMIN nomme le bloc dans les erreurs.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      Scenario = Simulink.SimulationData.Dataset;
%      Scenario = addElement(Scenario, timeseries([0; 1], [0; 1], 'Name', 's'));
%      f = [tempname() '.mat'];
%      save(f, 'Scenario');
%      s = matlibre_sl_scenario(f, 'Scenario', 'm/editeur');
%      s(1).nom                                   % 's'
%      delete(f);
%
%   Voir aussi ADD_BLOCK, SIM.
    if exist(fichier, 'file') ~= 2 && exist([fichier '.mat'], 'file') == 2
        fichier = [fichier '.mat'];
    end
    if exist(fichier, 'file') ~= 2
        error('Simulink:SignalEditor:FileNotFound', ...
              'Le fichier de scenarios ''%s'' du Signal Editor ''%s'' est introuvable.', ...
              fichier, chemin);
    end
    contenu = load(fichier);
    if ~isfield(contenu, scenario)
        noms = fieldnames(contenu);
        error('Simulink:SignalEditor:ScenarioNotFound', ...
              ['Le fichier ''%s'' ne porte pas le scenario ''%s'' que lit ''%s'' ; ses ' ...
               'variables sont : %s.'], fichier, scenario, chemin, strjoin(noms', ', '));
    end
    ds = contenu.(scenario);
    if ~isa(ds, 'Simulink.SimulationData.Dataset')
        error('Simulink:SignalEditor:InvalidScenario', ...
              ['Le scenario ''%s'' que lit ''%s'' est un %s : il faut un ' ...
               'Simulink.SimulationData.Dataset de timeseries.'], scenario, chemin, class(ds));
    end
    n = ds.numElements;
    if n == 0
        error('Simulink:SignalEditor:InvalidScenario', ...
              'Le scenario ''%s'' que lit ''%s'' ne porte aucun signal.', scenario, chemin);
    end
    signaux = struct('nom', {}, 'temps', {}, 'valeurs', {}, 'methode', {});
    for q = 1:n
        element = ds.getElement(q);
        if isa(element, 'Simulink.SimulationData.Signal')
            element = element.Values;
        end
        if ~isa(element, 'timeseries')
            error('Simulink:SignalEditor:InvalidScenario', ...
                  ['Le signal %d du scenario ''%s'' que lit ''%s'' est un %s : il faut une ' ...
                   'timeseries.'], q, scenario, chemin, class(element));
        end
        [temps, valeurs] = matlibre_sl_serie(element);
        if ~isreal(valeurs)
            error('Simulink:DataType:ComplexSignalNotSupported', ...
                  ['Le signal %d du scenario ''%s'' que lit ''%s'' est complexe : MatLibre ne ' ...
                   'simule que des signaux reels.'], q, scenario, chemin);
        end
        methode = 'linear';
        try
            if strcmpi(char(element.DataInfo.Interpolation.Name), 'zoh')
                methode = 'previous';
            end
        catch
        end
        signaux(end + 1) = struct('nom', char(element.Name), 'temps', temps(:), ...
                                  'valeurs', valeurs, 'methode', methode); %#ok<AGROW>
    end
end
