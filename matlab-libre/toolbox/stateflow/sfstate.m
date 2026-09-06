function machine = sfstate(machine, nom, entree, pendant, sortie)
%SFSTATE Ajoute un état.
%   MACHINE = SFSTATE(MACHINE,NOM,ENTREE,PENDANT,SORTIE) ajoute un état et
%   ses trois actions, chacune une poignée qui prend le contexte et le
%   rend modifié. Passer [] pour aucune action.
%
%   Les trois moments ne sont pas une question de style :
%      ENTREE   s'exécute une fois, quand on entre dans l'état
%      PENDANT  s'exécute à chaque pas passé dans l'état
%      SORTIE   s'exécute une fois, quand on en sort
%
%   Compter les fronts d'un signal demande une action d'entrée ; mesurer
%   la durée d'un mode demande une action de séjour. Les confondre donne
%   des comptes faux.
%
%   Le premier état ajouté est l'état initial de la machine.
%
%   Le contexte est une structure quelconque que la machine porte d'un pas
%   à l'autre : c'est ce qui lui permet de compter, donc de dépasser la
%   seule mémoire d'état.
%
%   Exemple :
%      m = sfstate(m, 'compte', @(c) setfield(c, 'total', c.total + 1));
%      [~, contexte] = sfrun(m, [1 0 1 0 1], struct('total', 0));
%
%   Voir aussi SFCHART, SFTRANSITION, SFRUN.
    if nargin < 3, entree = []; end
    if nargin < 4, pendant = []; end
    if nargin < 5, sortie = []; end
    e = struct();
    e.nom = nom;
    e.entree = entree;
    e.pendant = pendant;
    e.sortie = sortie;
    machine.etats{end+1} = e;
    if isempty(machine.initial)
        machine.initial = nom;
    end
end
