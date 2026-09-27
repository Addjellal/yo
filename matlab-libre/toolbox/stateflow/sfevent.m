function machine = sfevent(machine, nom, portee, declencheur)
%SFEVENT Déclare un événement d'entrée ou de sortie du diagramme.
%   MACHINE = SFEVENT(MACHINE,NOM,'Input',DECLENCHEUR) déclare un
%   événement d'entrée. Dans un bloc Chart, les événements d'entrée
%   arrivent par un port de déclenchement, posé après les entrées de
%   données, qui porte un élément par événement, dans l'ordre de leur
%   déclaration. DECLENCHEUR dit ce qui fait l'événement :
%      'Rising'         un front montant de son élément
%      'Falling'        un front descendant
%      'Either'         l'un ou l'autre
%      'Function call'  un appel : l'élément non nul
%   Un diagramme qui a des événements d'entrée ne calcule que quand l'un
%   d'eux survient, une fois par événement : ses transitions étiquetées
%   par cet événement peuvent alors partir, et celles sans événement
%   aussi. Son premier réveil le fait entrer dans son état initial.
%
%   MACHINE = SFEVENT(MACHINE,NOM,'Output',DECLENCHEUR) déclare un
%   événement de sortie, qu'une action émet par « send(NOM) » ou par son
%   nom seul, « NOM; ». Dans un bloc Chart, chaque événement de sortie a
%   son port, après les sorties de données : 'Function call' (le défaut)
%   y met 1 à l'instant où il est émis, de quoi appeler un sous-système
%   appelé par fonction ; 'Either' y bascule entre 0 et 1 à chaque
%   émission, un front que lit un sous-système déclenché.
%
%   Les événements locaux ne sont pas pris en charge : SFEVENT les refuse.
%
%   Exemple :
%      m = sfchart('compteur');
%      m = sfevent(m, 'impulsion', 'Input', 'Rising');
%      m = sfevent(m, 'plein', 'Output', 'Function call');
%      m = sfstate(m, 'compte', 'en: n = 0; du: n = n + 1;');
%      m = sftransition(m, 'compte', 'compte', 'impulsion[n >= 3]{plein;}');
%      numel(m.evenements)                % 2
%
%   Voir aussi SFCHART, SFSTATE, SFTRANSITION, ADD_BLOCK.
    if nargin < 3
        portee = 'Input';
    end
    nom = char(nom);
    if ~isvarname(nom)
        error('Stateflow:Events:InvalidName', ...
              'Le nom d''evenement ''%s'' n''est pas un nom valide.', nom);
    end
    portees = {'Input', 'Output', 'Local'};
    k = find(strcmpi(char(portee), portees), 1);
    if isempty(k)
        error('Stateflow:Events:InvalidScope', ...
              'La portee d''un evenement est ''Input'' ou ''Output'' ; pas ''%s''.', ...
              char(portee));
    end
    portee = portees{k};
    if strcmp(portee, 'Local')
        error('Stateflow:Events:LocalUnsupported', ...
              ['L''evenement ''%s'' est local : MatLibre ne prend en charge que les ' ...
               'evenements d''entree et de sortie.'], nom);
    end
    if strcmp(portee, 'Input')
        admis = {'Rising', 'Falling', 'Either', 'Function call'};
        defaut = 'Rising';
    else
        admis = {'Either', 'Function call'};
        defaut = 'Function call';
    end
    if nargin < 4 || isempty(declencheur)
        declencheur = defaut;
    end
    j = find(strcmpi(regexprep(char(declencheur), '[\s_-]', ''), ...
                     regexprep(admis, '[\s_-]', '')), 1);
    if isempty(j)
        error('Stateflow:Events:InvalidTrigger', ...
              'Le declencheur d''un evenement %s vaut %s ; pas ''%s''.', lower(portee), ...
              strjoin(strcat('''', admis, ''''), ', '), char(declencheur));
    end
    if ~isfield(machine, 'evenements')
        machine.evenements = struct('nom', {}, 'portee', {}, 'declencheur', {});
    end
    if any(strcmp({machine.evenements.nom}, nom))
        error('Stateflow:Events:DuplicateName', ...
              'La machine ''%s'' a deja un evenement ''%s''.', machine.nom, nom);
    end
    etats = cellfun(@(e) e.nom, machine.etats, 'UniformOutput', false);
    if any(strcmp(etats, nom))
        error('Stateflow:Events:DuplicateName', ...
              'La machine ''%s'' a deja un etat ''%s'' : un evenement ne peut s''appeler ainsi.', ...
              machine.nom, nom);
    end
    machine.evenements(end + 1) = struct('nom', nom, 'portee', portee, ...
                                         'declencheur', admis{j});
end
