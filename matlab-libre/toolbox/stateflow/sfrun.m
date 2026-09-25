function [historique, contexte] = sfrun(machine, entrees, contexte)
%SFRUN Exécute la machine sur une suite d'entrées.
%   [HISTORIQUE,CONTEXTE] = SFRUN(MACHINE,ENTREES) rend la suite des états
%   visités, un par pas, et le contexte final. SFRUN(MACHINE,ENTREES,
%   CONTEXTE) part du contexte donné.
%
%   La machine démarre dans son état initial, puis fait un pas par entrée,
%   avec la règle de Stateflow que SFSTEP applique : une transition valide
%   est prise — sortie, action de la transition, entrée —, sinon l'état
%   exécute son action de séjour.
%
%   Exemple :
%      m = sfchart('tourniquet');
%      m = sfstate(m, 'verrouille');
%      m = sfstate(m, 'ouvert');
%      m = sftransition(m, 'verrouille', 'ouvert', @(c,e) strcmp(e, 'piece'));
%      sfrun(m, {'pousse', 'piece'})     % 'ouvert'
%
%   Voir aussi SFSTEP, SFCHART, SFSTATE, SFTRANSITION.
    if nargin < 3
        contexte = struct();
    end
    % Le démarrage entre dans l'état initial ; chaque entrée fait ensuite
    % un pas, avec la règle de Stateflow : une transition si l'une est
    % valide, sinon l'action de séjour.
    [courant, contexte] = sfstep(machine, '', contexte, []);
    historique = cell(1, numel(entrees));
    for k = 1:numel(entrees)
        if iscell(entrees)
            u = entrees{k};
        else
            u = entrees(k);
        end
        [courant, contexte] = sfstep(machine, courant, contexte, u);
        historique{k} = courant;
    end
end
