function machine = sfdefault(machine, etat)
%SFDEFAULT Choisit le sous-état où l'on entre par défaut.
%   MACHINE = SFDEFAULT(MACHINE,ETAT) fait d'ETAT le sous-état où l'on
%   entre quand on entre dans son parent sans en viser un : c'est la
%   transition par défaut de Stateflow. Sans elle, c'est le premier
%   sous-état déclaré. Pour un état du plus haut niveau, c'est l'état
%   initial de la machine.
%
%   Exemple :
%      m = sfchart('feu');
%      m = sfstate(m, 'rouge');
%      m = sfstate(m, 'vert');
%      m = sfdefault(m, 'vert');
%      sfstep(m, '', struct(), 0)      % 'vert'
%
%   Voir aussi SFSTATE, SFCHART, SFSTEP.
    etat = char(etat);
    if ~any(cellfun(@(e) strcmp(e.nom, etat), machine.etats))
        error('Stateflow:EtatInconnu', 'La machine n''a pas d''etat ''%s''.', etat);
    end
    if ~any(etat == '.')
        machine.initial = etat;
        return
    end
    if ~isfield(machine, 'defauts')
        machine.defauts = {};
    end
    point = find(etat == '.', 1, 'last');
    parent = etat(1:point - 1);
    garder = true(1, numel(machine.defauts));
    for k = 1:numel(machine.defauts)
        d = machine.defauts{k};
        p = find(d == '.', 1, 'last');
        garder(k) = ~strcmp(d(1:p - 1), parent);
    end
    machine.defauts = machine.defauts(garder);
    machine.defauts{end + 1} = etat;
end
