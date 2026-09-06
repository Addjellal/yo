function machine = sftransition(machine, depuis, vers, garde, action)
%SFTRANSITION Ajoute une transition gardée.
%   MACHINE = SFTRANSITION(MACHINE,DEPUIS,VERS,GARDE,ACTION) ajoute une
%   transition entre deux états. GARDE est une poignée @(contexte,entree)
%   qui rend vrai ou faux ; ACTION, facultative, une poignée @(contexte)
%   qui rend le contexte modifié au passage.
%
%   Quand plusieurs transitions partent du même état, la première déclarée
%   dont la garde est vraie l'emporte. C'est une règle de priorité, et il
%   faut la connaître : elle décide du comportement quand deux conditions
%   se recouvrent.
%
%   Si aucune garde n'est vraie, la machine reste où elle est. Ne rien
%   faire est un comportement, non une erreur.
%
%   Exemple :
%      m = sftransition(m, 'depart', 'petit', @(c,e) e < 10);
%      m = sftransition(m, 'depart', 'grand', @(c,e) e < 100);
%      sfrun(m, 5)                     % 'petit' : la premiere gagne
%
%   Voir aussi SFCHART, SFSTATE, SFRUN.
    if nargin < 5, action = []; end
    t = struct();
    t.depuis = depuis;
    t.vers = vers;
    t.garde = garde;
    t.action = action;
    machine.transitions{end+1} = t;
end
