function machine = sftransition(machine, depuis, vers, garde, action)
%SFTRANSITION Ajoute une transition gardée.
%   MACHINE = SFTRANSITION(MACHINE,DEPUIS,VERS,GARDE,ACTION) ajoute une
%   transition entre deux états. GARDE est une poignée @(contexte,entree)
%   qui rend vrai ou faux ; ACTION, facultative, une poignée @(contexte)
%   qui rend le contexte modifié au passage.
%
%   GARDE peut aussi être l'étiquette d'une transition de Stateflow, en
%   texte : « evenement[condition]{action de condition} ». L'événement
%   est vrai quand l'entrée du pas le nomme (un texte, ou une cellule de
%   textes) ; la condition est une expression du langage d'action, où les
%   champs du contexte sont des variables ; l'action de condition
%   s'exécute dès que la condition est vraie, avant la sortie de l'état.
%   Chaque partie est facultative : 'go', '[n >= 3]', 'go[n > 0]{k = 1;}',
%   '[after(2, sec)]'. ACTION peut de même être un texte : 'fin = 1;'.
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
%      m = sfchart('mesure');
%      m = sfstate(m, 'depart');
%      m = sfstate(m, 'petit');
%      m = sfstate(m, 'grand');
%      m = sftransition(m, 'depart', 'petit', @(c,e) e < 10);
%      m = sftransition(m, 'depart', 'grand', @(c,e) e < 100);
%      sfrun(m, 5)                     % 'petit' : la premiere gagne
%      m = sftransition(m, 'petit', 'depart', 'raz[n > 0]{n = 0;}');
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
