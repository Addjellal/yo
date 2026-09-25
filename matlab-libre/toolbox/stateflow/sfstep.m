function [courant, contexte] = sfstep(machine, courant, contexte, u)
%SFSTEP Fait faire un pas à une machine à états.
%   [COURANT,CONTEXTE] = SFSTEP(MACHINE,COURANT,CONTEXTE,U) exécute un pas
%   de la machine, comme Stateflow réveille un diagramme : les transitions
%   qui partent de l'état COURANT sont essayées dans l'ordre où elles ont
%   été déclarées, et la première dont la garde est vraie est prise — on
%   exécute l'action de sortie de l'état, l'action de la transition, puis
%   l'action d'entrée du nouvel état. Si aucune n'est vraie, l'état reste,
%   et c'est son action de séjour qui s'exécute.
%
%   COURANT vide veut dire que la machine n'a pas encore démarré : le pas
%   entre alors dans l'état initial, et exécute son action d'entrée. C'est
%   ce que fait Stateflow au premier réveil.
%
%   C'est le pas qu'exécutent SFRUN, sur une suite d'entrées, et le bloc
%   Chart d'un schéma Simulink, à chaque instant d'échantillonnage.
%
%   Exemple :
%      m = sfchart('bascule');
%      m = sfstate(m, 'bas');
%      m = sfstate(m, 'haut');
%      m = sftransition(m, 'bas', 'haut', @(c, u) u > 0.5);
%      [e, c] = sfstep(m, '', struct(), 0);     % 'bas' : le démarrage
%      [e, c] = sfstep(m, e, c, 1)               % 'haut'
%
%   Voir aussi SFRUN, SFCHART, SFSTATE, SFTRANSITION.
    if isempty(courant)
        courant = machine.initial;
        contexte = action(machine, courant, 'entree', contexte);
        return
    end
    for t = 1:numel(machine.transitions)
        tr = machine.transitions{t};
        if ~strcmp(tr.depuis, courant)
            continue
        end
        if tr.garde(contexte, u)
            contexte = action(machine, courant, 'sortie', contexte);
            if ~isempty(tr.action)
                contexte = tr.action(contexte);
            end
            courant = tr.vers;
            contexte = action(machine, courant, 'entree', contexte);
            return
        end
    end
    for k = 1:numel(machine.etats)
        e = machine.etats{k};
        if strcmp(e.nom, courant) && ~isempty(e.pendant)
            contexte = e.pendant(contexte, u);
            return
        end
    end
end

function contexte = action(machine, nomEtat, quelle, contexte)
    for k = 1:numel(machine.etats)
        e = machine.etats{k};
        if ~strcmp(e.nom, nomEtat)
            continue
        end
        if strcmp(quelle, 'entree')
            fonction = e.entree;
        else
            fonction = e.sortie;
        end
        if ~isempty(fonction)
            contexte = fonction(contexte);
        end
        return
    end
end
