function machine = sfjunction(machine, nom)
%SFJUNCTION Ajoute une jonction de connexion.
%   MACHINE = SFJUNCTION(MACHINE,NOM) ajoute une jonction : un point où
%   des transitions se rejoignent et se séparent, comme les jonctions de
%   connexion de Stateflow. Une transition peut aller d'un état à une
%   jonction, d'une jonction à une autre, et d'une jonction à un état.
%
%   Une transition qui mène à une jonction n'est prise que si un chemin
%   complet, fait de segments dont les gardes sont vraies, va de la
%   jonction jusqu'à un état. Les segments qui partent d'une jonction
%   s'essaient dans l'ordre de leur déclaration ; un segment sans garde
%   est le chemin par défaut, et se déclare en dernier. Un segment dont
%   la suite échoue est abandonné, et l'on essaie le suivant. Les actions
%   de condition ({...}) s'exécutent à mesure que les gardes sont vraies ;
%   les actions de transition, une fois le chemin trouvé, dans l'ordre des
%   segments.
%
%   Exemple :
%      m = sfchart('tri');
%      m = sfstate(m, 'attente');
%      m = sfstate(m, 'petit');
%      m = sfstate(m, 'grand');
%      m = sfjunction(m, 'j');
%      m = sftransition(m, 'attente', 'j', 'mesure');
%      m = sftransition(m, 'j', 'petit', '[x < 10]');
%      m = sftransition(m, 'j', 'grand', '');
%      [h, c] = sfrun(m, {'rien', 'mesure'}, struct('x', 42));
%      h{end}                      % 'grand'
%
%   Voir aussi SFTRANSITION, SFSTATE, SFCHART.
    nom = char(nom);
    if ~isvarname(strrep(nom, '.', '_'))
        error('Stateflow:NomInvalide', 'Le nom de jonction ''%s'' n''est pas un nom valide.', nom);
    end
    if ~isfield(machine, 'jonctions')
        machine.jonctions = {};
    end
    etats = cellfun(@(e) e.nom, machine.etats, 'UniformOutput', false);
    if any(strcmp(machine.jonctions, nom)) || any(strcmp(etats, nom))
        error('Stateflow:JonctionDouble', ...
              'La machine ''%s'' a deja un etat ou une jonction nomme ''%s''.', machine.nom, nom);
    end
    machine.jonctions{end + 1} = nom;
end
