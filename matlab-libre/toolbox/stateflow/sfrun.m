function [historique, contexte] = sfrun(machine, entrees, contexte)
%SFRUN Exécute la machine sur une suite d'entrées.
%   [HISTORIQUE,CONTEXTE] = SFRUN(MACHINE,ENTREES) rend la suite des états
%   visités, un par pas, et le contexte final.
    if nargin < 3
        contexte = struct();
    end
    courant = machine.initial;
    contexte = executerAction(machine, courant, 'entree', contexte);
    historique = {};
    for k = 1:numel(entrees)
        if iscell(entrees)
            u = entrees{k};
        else
            u = entrees(k);
        end
        contexte = executerActionPendant(machine, courant, contexte, u);
        for t = 1:numel(machine.transitions)
            tr = machine.transitions{t};
            if ~strcmp(tr.depuis, courant)
                continue;
            end
            if tr.garde(contexte, u)
                contexte = executerAction(machine, courant, 'sortie', contexte);
                if ~isempty(tr.action)
                    contexte = tr.action(contexte);
                end
                courant = tr.vers;
                contexte = executerAction(machine, courant, 'entree', contexte);
                break;
            end
        end
        historique{end+1} = courant;
    end
end

function contexte = executerAction(machine, nomEtat, quelle, contexte)
    for k = 1:numel(machine.etats)
        e = machine.etats{k};
        if ~strcmp(e.nom, nomEtat)
            continue;
        end
        action = [];
        if strcmp(quelle, 'entree')
            action = e.entree;
        elseif strcmp(quelle, 'sortie')
            action = e.sortie;
        end
        if ~isempty(action)
            contexte = action(contexte);
        end
        return;
    end
end

function contexte = executerActionPendant(machine, nomEtat, contexte, u)
    for k = 1:numel(machine.etats)
        e = machine.etats{k};
        if strcmp(e.nom, nomEtat) && ~isempty(e.pendant)
            contexte = e.pendant(contexte, u);
            return;
        end
    end
end
