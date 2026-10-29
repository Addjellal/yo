classdef Root < handle
%ROOT La racine de Stateflow : les modèles chargés et leurs diagrammes.
%   RT = SFROOT la rend. FIND(RT,'-isa',CLASSE,'Propriete',VALEUR,...)
%   cherche parmi les modèles chargés (Simulink.BlockDiagram), leurs
%   diagrammes (Stateflow.Chart) et ce qu'ils contiennent
%   (Stateflow.State, Transition, Junction, Data, Event).
%
%   Exemple :
%      sfnew('racineEssai');
%      rt = sfroot;
%      m = rt.find('-isa', 'Simulink.BlockDiagram', 'Name', 'racineEssai');
%      ch = m.find('-isa', 'Stateflow.Chart');
%      ch.Path                            % 'racineEssai/Chart'
%      close_system('racineEssai', 0);
%
%   Voir aussi SFROOT, SFNEW, STATEFLOW.CHART.
    methods
        function v = find(rt, varargin) %#ok<INUSL>
            v = matlibre_sf_api('trouver', 'racine', varargin);
        end
        function disp(rt) %#ok<MANU>
            fprintf('  Stateflow.Root : %d modele(s) charge(s)\n\n', ...
                    numel(matlibre_sl_ouverts('noms')));
        end
    end
end
