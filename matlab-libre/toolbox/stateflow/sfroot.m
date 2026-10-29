function rt = sfroot()
%SFROOT La racine de Stateflow.
%   RT = SFROOT rend un Stateflow.Root, d'où FIND cherche les modèles
%   chargés, leurs diagrammes et ce qu'ils contiennent.
%
%   Exemple :
%      sfnew('sfrootEssai');
%      ch = find(sfroot, '-isa', 'Stateflow.Chart');
%      class(ch)                          % 'Stateflow.Chart'
%      close_system('sfrootEssai', 0);
%
%   Voir aussi SFNEW, STATEFLOW.ROOT, STATEFLOW.CHART.
    rt = Stateflow.Root;
end
