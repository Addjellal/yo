function machine = sfstate(machine, nom, entree, pendant, sortie)
%SFSTATE Ajoute un état.
%   MACHINE = SFSTATE(MACHINE,NOM,ENTREE,PENDANT,SORTIE) ajoute un état et
%   ses trois actions, chacune une poignée qui prend le contexte et le
%   rend modifié, ou un texte du langage d'action. Passer [] pour aucune
%   action.
%
%   MACHINE = SFSTATE(MACHINE,NOM,ETIQUETTE) donne les trois actions d'un
%   seul texte, comme l'étiquette d'un état de Stateflow :
%      'en: n = 0; du: n = n + u; ex: y = n;'
%   Dans un texte, les champs du contexte sont des variables, u est
%   l'entrée du pas, et toute variable posée devient un champ du contexte.
%   La logique temporelle s'y écrit comme dans Stateflow : after(3, tick),
%   before(0.5, sec), at(2, tick), every(4, tick).
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
%   Un nom « parent.enfant » fait un sous-état : son parent doit être
%   déclaré avant lui, et le premier sous-état déclaré d'un parent est
%   celui où l'on entre par défaut (SFDEFAULT en choisit un autre). Les
%   états s'emboîtent ainsi à toute profondeur ; SFDECOMPOSITION rend les
%   sous-états d'un parent parallèles, SFHISTORY lui donne un historique.
%
%   Le contexte est une structure quelconque que la machine porte d'un pas
%   à l'autre : c'est ce qui lui permet de compter, donc de dépasser la
%   seule mémoire d'état.
%
%   Exemple :
%      m = sfchart('compteur');
%      m = sfstate(m, 'compte', @(c) setfield(c, 'total', c.total + 1));
%      [~, contexte] = sfrun(m, [1 0 1 0 1], struct('total', 0));
%      m = sfstate(m, 'mesure', 'en: n = 0; du: n = n + u;');
%
%   Voir aussi SFCHART, SFTRANSITION, SFRUN, SFDECOMPOSITION, SFHISTORY.
    if nargin < 3, entree = []; end
    point = find(nom == '.', 1, 'last');
    if ~isempty(point) && ~any(cellfun(@(e) strcmp(e.nom, nom(1:point - 1)), machine.etats))
        error('Stateflow:EtatParentAbsent', ...
              'L''etat ''%s'' n''a pas de parent : declarez ''%s'' d''abord.', ...
              nom, nom(1:point - 1));
    end
    if any(cellfun(@(e) strcmp(e.nom, nom), machine.etats))
        error('Stateflow:EtatDouble', 'La machine a deja un etat ''%s''.', nom);
    end
    if nargin < 4, pendant = []; end
    if nargin < 5, sortie = []; end
    % Une étiquette d'état de Stateflow, en un seul texte : « en: x = 0;
    % du: x = x + 1; ex: y = x; ».
    if ischar(entree) && nargin < 4 && ~isempty(regexp(entree, ...
            '(^|[\s;,])(en|entry|du|during|ex|exit)\s*:', 'once'))
        [entree, pendant, sortie] = decouperEtiquette(entree);
    end
    e = struct();
    e.nom = nom;
    e.entree = entree;
    e.pendant = pendant;
    e.sortie = sortie;
    machine.etats{end+1} = e;
    if isempty(machine.initial) && isempty(point)
        machine.initial = nom;
    end
end

% Les trois actions d'une étiquette : ce qui suit « en: », « du: », « ex: »
% (ou entry, during, exit), jusqu'au mot-clé suivant.
function [entree, pendant, sortie] = decouperEtiquette(texte)
    entree = '';
    pendant = '';
    sortie = '';
    [debuts, fins, jetons] = regexp(texte, '(en|entry|du|during|ex|exit)\s*:', ...
                                    'start', 'end', 'tokens');
    for k = 1:numel(debuts)
        if k < numel(debuts)
            corps = texte(fins(k) + 1:debuts(k + 1) - 1);
        else
            corps = texte(fins(k) + 1:end);
        end
        corps = strtrim(corps);
        switch jetons{k}{1}
            case {'en', 'entry'}
                entree = [entree corps]; %#ok<AGROW>
            case {'du', 'during'}
                pendant = [pendant corps]; %#ok<AGROW>
            otherwise
                sortie = [sortie corps]; %#ok<AGROW>
        end
    end
end
