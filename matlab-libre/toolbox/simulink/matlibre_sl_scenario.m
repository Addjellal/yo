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
              'Scenario file ''%s'' of Signal Editor ''%s'' cannot be found.', ...
              fichier, chemin);
    end
    contenu = load(fichier);
    if ~isfield(contenu, scenario)
        noms = fieldnames(contenu);
        error('Simulink:SignalEditor:ScenarioNotFound', ...
              ['File ''%s'' does not contain scenario ''%s'' read by ''%s''; its ' ...
               'variables are: %s.'], fichier, scenario, chemin, strjoin(noms', ', '));
    end
    ds = contenu.(scenario);
    if ~isa(ds, 'Simulink.SimulationData.Dataset')
        error('Simulink:SignalEditor:InvalidScenario', ...
              ['Scenario ''%s'' read by ''%s'' is a %s: it must be a ' ...
               'Simulink.SimulationData.Dataset of timeseries.'], scenario, chemin, class(ds));
    end
    n = ds.numElements;
    if n == 0
        error('Simulink:SignalEditor:InvalidScenario', ...
              'Scenario ''%s'' read by ''%s'' has no signal.', scenario, chemin);
    end
    signaux = struct('nom', {}, 'temps', {}, 'valeurs', {}, 'methode', {});
    for q = 1:n
        element = ds.getElement(q);
        if isa(element, 'Simulink.SimulationData.Signal')
            element = element.Values;
        end
        if ~isa(element, 'timeseries')
            error('Simulink:SignalEditor:InvalidScenario', ...
                  ['Signal %d of scenario ''%s'' read by ''%s'' is a %s: it must be a ' ...
                   'timeseries.'], q, scenario, chemin, class(element));
        end
        [temps, valeurs] = matlibre_sl_serie(element);
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
