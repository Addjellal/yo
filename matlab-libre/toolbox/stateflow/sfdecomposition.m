function machine = sfdecomposition(machine, parent, genre)
%SFDECOMPOSITION Rend les sous-états d'un état exclusifs ou parallèles.
%   MACHINE = SFDECOMPOSITION(MACHINE,PARENT,'parallel') fait de PARENT
%   un état à sous-états parallèles : quand il est actif, tous ses
%   sous-états le sont, et chaque pas les exécute tour à tour, dans
%   l'ordre où ils ont été déclarés. 'exclusive', le défaut, n'en laisse
%   actif qu'un. PARENT vide désigne le diagramme lui-même.
%
%   C'est la décomposition AND et OR de Stateflow : une machine qui surveille
%   deux choses indépendantes en a deux régions parallèles, plutôt que le
%   produit de leurs états.
%
%   Exemple :
%      m = sfchart('voiture');
%      m = sfstate(m, 'phares');
%      m = sfstate(m, 'phares.eteints');
%      m = sfstate(m, 'phares.allumes');
%      m = sfstate(m, 'moteur');
%      m = sfstate(m, 'moteur.arret');
%      m = sfstate(m, 'moteur.marche');
%      m = sfdecomposition(m, '', 'parallel');
%      sfstep(m, '', struct(), 0)      % {'phares.eteints', 'moteur.arret'}
%
%   Voir aussi SFSTATE, SFHISTORY, SFSTEP.
    genre = lower(char(genre));
    if ~any(strcmp(genre, {'parallel', 'exclusive'}))
        error('Stateflow:DecompositionInconnue', ...
              'La decomposition est ''parallel'' ou ''exclusive'' ; pas ''%s''.', genre);
    end
    parent = char(parent);
    if ~isempty(parent) && ~any(cellfun(@(e) strcmp(e.nom, parent), machine.etats))
        error('Stateflow:EtatInconnu', 'La machine n''a pas d''etat ''%s''.', parent);
    end
    if ~isfield(machine, 'paralleles')
        machine.paralleles = {};
    end
    machine.paralleles = machine.paralleles(~strcmp(machine.paralleles, parent));
    if strcmp(genre, 'parallel')
        machine.paralleles{end + 1} = parent;
    end
end
