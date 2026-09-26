function sorties = parsim(entrees, varargin)
%PARSIM Fait toute une série de simulations, décrites par des SimulationInput.
%   OUT = PARSIM(IN) simule chaque élément du tableau IN de
%   SIMULINK.SIMULATIONINPUT — un même modèle avec d'autres variables,
%   d'autres paramètres de blocs, d'autres réglages — et rend OUT, le
%   tableau de même taille de leurs résultats. Chacun porte ce que rend
%   SIM, plus ErrorMessage — vide si la simulation a abouti — et
%   SimulationMetadata (le modèle, ses instants, son solveur, la durée).
%
%   Une simulation qui échoue n'arrête pas les autres : son résultat
%   porte le message de l'erreur dans ErrorMessage, et ses autres champs
%   sont vides. Après chaque simulation, l'espace de travail de base
%   retrouve les variables qu'il avait.
%
%   Simulink répartit les simulations sur les cœurs d'un pool parallèle ;
%   MatLibre, qui n'en a pas, les fait l'une après l'autre, et les
%   résultats sont les mêmes.
%
%   OUT = PARSIM(IN,NOM,VALEUR,...) :
%      'ShowProgress'  'on' (défaut) : une ligne par simulation terminée
%      'StopOnError'   'off' (défaut) ; 'on' : après une erreur, les
%                      simulations suivantes ne se font pas, et leur
%                      ErrorMessage le dit
%      'SetupFcn'      @f, appelée une fois avant les simulations
%      'CleanupFcn'    @f, appelée une fois après, même sur une erreur
%      'TransferBaseWorkspaceVariables', 'UseFastRestart',
%      'ShowSimulationManager', 'AttachedFiles', 'ManageDependencies'
%                      admises, sans effet : tout se passe dans la même
%                      session, qui voit déjà l'espace de travail
%      'RunInBackground'  'off' seulement
%
%   Exemple :
%      pd = new_system('pd');
%      pd = add_block(pd, 'constant', 'c', 'Value', 'K');
%      pd = add_block(pd, 'outport', 'y');
%      pd = add_line(pd, 'c', 'y');
%      in(1:3) = Simulink.SimulationInput('pd');
%      for k = 1:3
%          in(k) = in(k).setVariable('K', 10 * k);
%      end
%      out = parsim(in, 'ShowProgress', 'off');
%      out(2).yout(end)                   % 20
%
%   Voir aussi SIMULINK.SIMULATIONINPUT, SIM.
    if nargin < 1 || ~isa(entrees, 'Simulink.SimulationInput')
        error('Simulink:parsim:InvalidInput', ...
              ['PARSIM(IN) simule un tableau de Simulink.SimulationInput ; pour un ' ...
               'modele seul, SIM(NOM) suffit.']);
    end
    % Le modèle de chaque simulation : une variable de l'appelant qui en
    % porte le nom, comme pour SIM(NOM).
    modeles = cell(1, numel(entrees));
    for k = 1:numel(entrees)
        nom = entrees(k).ModelName;
        if isvarname(nom) && evalin('caller', sprintf('exist(''%s'', ''var'')', nom)) == 1
            candidat = evalin('caller', nom);
            if isstruct(candidat) && isfield(candidat, 'blocs')
                modeles{k} = candidat;
            end
        end
    end
    sorties = matlibre_sl_lot('parsim', entrees, modeles, varargin{:});
end
