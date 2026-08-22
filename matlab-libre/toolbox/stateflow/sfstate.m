function machine = sfstate(machine, nom, entree, pendant, sortie)
%SFSTATE Ajoute un état.
%   MACHINE = SFSTATE(MACHINE,NOM,ENTREE,PENDANT,SORTIE) où les trois
%   actions sont des poignées de fonction prenant et rendant le contexte
%   (une structure de données de la machine). Passer [] pour aucune action.
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
