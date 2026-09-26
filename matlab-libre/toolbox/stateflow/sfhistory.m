function machine = sfhistory(machine, parent)
%SFHISTORY Donne un historique à un état : il revient où il était.
%   MACHINE = SFHISTORY(MACHINE,PARENT) pose une jonction d'historique
%   dans PARENT : quand on y rentre sans viser un de ses sous-états, on
%   entre dans celui qu'on a quitté la dernière fois, au lieu du sous-état
%   par défaut. PARENT vide désigne le diagramme lui-même.
%
%   Exemple :
%      m = sfchart('lecteur');
%      m = sfstate(m, 'arret');
%      m = sfstate(m, 'lecture');
%      m = sfstate(m, 'lecture.piste1');
%      m = sfstate(m, 'lecture.piste2');
%      m = sfhistory(m, 'lecture');
%      m = sftransition(m, 'lecture.piste1', 'lecture.piste2', @(c, u) u == 1);
%      m = sftransition(m, 'lecture', 'arret', @(c, u) u == 2);
%      m = sftransition(m, 'arret', 'lecture', @(c, u) u == 3);
%      sfrun(m, [3 1 2 3])        % ... 'lecture.piste2' : l'historique
%
%   Voir aussi SFSTATE, SFDECOMPOSITION, SFSTEP.
    parent = char(parent);
    if ~isempty(parent) && ~any(cellfun(@(e) strcmp(e.nom, parent), machine.etats))
        error('Stateflow:EtatInconnu', 'La machine n''a pas d''etat ''%s''.', parent);
    end
    if ~isfield(machine, 'historiques')
        machine.historiques = {};
    end
    if ~any(strcmp(machine.historiques, parent))
        machine.historiques{end + 1} = parent;
    end
end
