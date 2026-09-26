function [courant, contexte] = sfstep(machine, courant, contexte, u)
%SFSTEP Fait faire un pas à une machine à états.
%   [COURANT,CONTEXTE] = SFSTEP(MACHINE,COURANT,CONTEXTE,U) exécute un pas
%   de la machine, comme Stateflow réveille un diagramme. Pour chaque état
%   actif, du plus haut au plus profond : les transitions qui en partent
%   sont essayées dans l'ordre où elles ont été déclarées, et la première
%   dont la garde est vraie est prise — on sort de l'état et de ses
%   sous-états (actions de sortie, du plus profond au plus haut), on
%   exécute l'action de la transition, puis on entre dans la cible et dans
%   ses sous-états par défaut (actions d'entrée, du plus haut au plus
%   profond). Si aucune n'est vraie, l'état exécute son action de séjour,
%   puis on descend dans ses sous-états actifs.
%
%   Un état nommé « parent.enfant » est un sous-état : le premier déclaré
%   de chaque parent est celui où l'on entre par défaut (SFDEFAULT en
%   choisit un autre). Un parent en décomposition parallèle
%   (SFDECOMPOSITION) a tous ses sous-états actifs à la fois ; un parent
%   à historique (SFHISTORY) revient dans le sous-état qu'il a quitté.
%   Une transition qui vise un parent entre dans son sous-état par défaut.
%
%   COURANT est la feuille active — le sous-état le plus profond — ou,
%   s'il y en a plusieurs, la cellule des feuilles actives. COURANT vide
%   veut dire que la machine n'a pas encore démarré : le pas entre alors
%   dans l'état initial et ses sous-états, et exécute leurs actions
%   d'entrée.
%
%   Le contexte porte, dans son champ sf_, ce que la machine doit se
%   rappeler d'un pas à l'autre : les états actifs, le pas où chacun est
%   devenu actif, l'historique. Avant d'essayer les transitions d'un état,
%   le pas pose sf_ticks — le nombre de réveils depuis qu'on y est entré —
%   et, si le contexte porte l'instant sf_t, sf_temps, la durée passée
%   dedans : c'est ce que lisent SFAFTER, SFBEFORE, SFAT et SFEVERY.
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
%   Voir aussi SFRUN, SFCHART, SFSTATE, SFTRANSITION, SFDECOMPOSITION,
%   SFHISTORY, SFAFTER.
    A = arbre(machine);
    avecMemoire = isstruct(contexte);
    R = memoire(A, courant, contexte);
    t = NaN;
    if avecMemoire && isfield(contexte, 'sf_t')
        t = double(contexte.sf_t);
    end
    R.tick = R.tick + 1;
    if isempty(R.actifs)
        [R, contexte] = entrer(A, machine, 0, R, contexte, t, true);
    else
        [R, contexte] = executerEnfants(A, machine, 0, R, contexte, u, t);
    end
    courant = feuilles(A, R);
    if avecMemoire
        contexte.sf_ = R;
    end
end

% --- l'arbre des états ----------------------------------------------------

% Les états, leur parent (0 pour le diagramme), leurs enfants dans l'ordre
% de déclaration, la décomposition et l'historique de chacun. Le rang 0
% est le diagramme lui-même.
function A = arbre(machine)
    n = numel(machine.etats);
    A.noms = cell(1, n);
    for k = 1:n
        A.noms{k} = machine.etats{k}.nom;
    end
    A.parent = zeros(1, n);
    for k = 1:n
        point = find(A.noms{k} == '.', 1, 'last');
        if ~isempty(point)
            p = find(strcmp(A.noms, A.noms{k}(1:point - 1)), 1);
            if isempty(p)
                error('Stateflow:EtatParentAbsent', ...
                      'L''etat ''%s'' n''a pas de parent : declarez ''%s'' d''abord.', ...
                      A.noms{k}, A.noms{k}(1:point - 1));
            end
            A.parent(k) = p;
        end
    end
    A.enfants = cell(1, n + 1);   % A.enfants{p + 1} : les enfants de p
    for k = 1:n
        A.enfants{A.parent(k) + 1}(end + 1) = k;
    end
    A.parallele = false(1, n + 1);
    A.historique = false(1, n + 1);
    A.defaut = zeros(1, n + 1);
    for p = 0:n
        if ~isempty(A.enfants{p + 1})
            A.defaut(p + 1) = A.enfants{p + 1}(1);
        end
    end
    if isfield(machine, 'initial') && ~isempty(machine.initial)
        k = find(strcmp(A.noms, machine.initial), 1);
        if ~isempty(k) && A.parent(k) == 0
            A.defaut(1) = k;
        end
    end
    if isfield(machine, 'paralleles')
        for j = 1:numel(machine.paralleles)
            A.parallele(rang(A, machine.paralleles{j}) + 1) = true;
        end
    end
    if isfield(machine, 'historiques')
        for j = 1:numel(machine.historiques)
            A.historique(rang(A, machine.historiques{j}) + 1) = true;
        end
    end
    if isfield(machine, 'defauts')
        for j = 1:numel(machine.defauts)
            k = rang(A, machine.defauts{j});
            A.defaut(A.parent(k) + 1) = k;
        end
    end
end

function k = rang(A, nom)
    if isempty(nom)
        k = 0;
        return
    end
    k = find(strcmp(A.noms, nom), 1);
    if isempty(k)
        error('Stateflow:EtatInconnu', 'La machine n''a pas d''etat ''%s''.', nom);
    end
end

% La mémoire de la machine : celle que porte le contexte, si elle répond
% au COURANT donné ; sinon rebâtie de COURANT — ses feuilles et tous leurs
% ancêtres —, ou vide pour un démarrage.
function R = memoire(A, courant, contexte)
    R = struct('actifs', zeros(1, 0), 'depuis', zeros(1, 0), 'debut', zeros(1, 0), ...
               'tick', 0, 'hParents', zeros(1, 0), 'hEnfants', zeros(1, 0));
    if isempty(courant)
        return
    end
    if isstruct(contexte) && isfield(contexte, 'sf_')
        memo = contexte.sf_;
        if isequal(feuilles(A, memo), courant)
            R = memo;
            return
        end
    end
    if ischar(courant)
        courant = {courant};
    end
    for j = 1:numel(courant)
        k = rang(A, courant{j});
        while k > 0
            if ~any(R.actifs == k)
                R.actifs(end + 1) = k;
                R.depuis(end + 1) = 0;
                R.debut(end + 1) = NaN;
            end
            k = A.parent(k);
        end
    end
end

% Les feuilles actives : un nom, ou une cellule s'il y en a plusieurs.
function f = feuilles(A, R)
    f = {};
    for k = R.actifs
        enfantsActifs = intersect(A.enfants{k + 1}, R.actifs);
        if isempty(enfantsActifs)
            f{end + 1} = A.noms{k}; %#ok<AGROW>
        end
    end
    % dans l'ordre de déclaration
    [~, ordre] = sort(cellfun(@(nom) find(strcmp(A.noms, nom), 1), f));
    f = f(ordre);
    if numel(f) == 1
        f = f{1};
    elseif isempty(f)
        f = '';
    end
end

% --- l'exécution ----------------------------------------------------------

% Les sous-états actifs de P, chacun à son tour. Un état où l'on vient
% d'entrer, pendant ce pas, n'est pas exécuté : il attend le réveil
% suivant.
function [R, contexte] = executerEnfants(A, machine, p, R, contexte, u, t)
    avant = R.actifs;
    for k = A.enfants{p + 1}
        if any(avant == k) && any(R.actifs == k)
            [R, contexte, ~] = executer(A, machine, k, R, contexte, u, t);
        end
    end
end

% Un état actif : ses transitions d'abord ; aucune, son séjour, puis ses
% sous-états.
function [R, contexte, parti] = executer(A, machine, k, R, contexte, u, t)
    parti = false;
    contexte = poserTemps(contexte, R, k, t);
    for j = 1:numel(machine.transitions)
        tr = machine.transitions{j};
        if ~strcmp(tr.depuis, A.noms{k})
            continue
        end
        [vrai, contexte] = garde(tr, contexte, u);
        if vrai
            [R, contexte] = franchir(A, machine, k, rang(A, tr.vers), tr, R, contexte, t, u);
            parti = true;
            return
        end
    end
    e = machine.etats{k};
    contexte = agir(e.pendant, contexte, u, true);
    [R, contexte] = executerEnfants(A, machine, k, R, contexte, u, t);
end

% Une garde : une poignée @(c, u), ou un texte — une condition, un
% événement que l'entrée nomme, ou une étiquette « evenement[condition]
% {action de condition}/action ». L'action de condition s'exécute dès que
% la condition est vraie, avant la sortie de l'état.
function [vrai, contexte] = garde(tr, contexte, u)
    g = tr.garde;
    if isa(g, 'function_handle')
        vrai = logical(g(contexte, u));
        return
    end
    if isempty(g)
        vrai = true;
        return
    end
    [evenement, condition, actionCondition] = etiquette(char(g));
    vrai = true;
    if ~isempty(evenement)
        vrai = (ischar(u) || isstring(u)) && strcmp(char(u), evenement) || ...
               (iscell(u) && any(strcmp(u, evenement)));
    end
    if vrai && ~isempty(condition)
        [~, valeur] = matlibre_sf_evaluer(condition, contexte, u, true);
        vrai = logical(valeur);
    end
    if vrai && ~isempty(actionCondition)
        contexte = matlibre_sf_evaluer(actionCondition, contexte, u, false);
    end
end

% « e[c]{a} », « [c] », « e » ou une condition nue.
function [evenement, condition, action] = etiquette(texte)
    evenement = '';
    condition = '';
    action = '';
    texte = strtrim(texte);
    jetons = regexp(texte, '^(\w*)\s*\[(.*)\]\s*(\{(.*)\})?\s*$', 'tokens', 'once');
    if ~isempty(jetons)
        evenement = jetons{1};
        condition = jetons{2};
        if numel(jetons) >= 4
            action = jetons{4};
        end
        return
    end
    if ~isempty(regexp(texte, '^[A-Za-z]\w*$', 'once'))
        evenement = texte;   % un nom seul : un événement
        return
    end
    condition = texte;
end

% Une action : une poignée — @(c) pour l'entrée et la sortie, @(c, u)
% pour le séjour — ou un texte du langage d'action.
function contexte = agir(a, contexte, u, avecEntree)
    if isempty(a)
        return
    end
    if isa(a, 'function_handle')
        if avecEntree
            contexte = a(contexte, u);
        else
            contexte = a(contexte);
        end
        return
    end
    contexte = matlibre_sf_evaluer(char(a), contexte, u, false);
end

function contexte = poserTemps(contexte, R, k, t)
    if ~isstruct(contexte)
        return
    end
    i = find(R.actifs == k, 1);
    contexte.sf_ticks = R.tick - R.depuis(i);
    contexte.sf_temps = t - R.debut(i);
end

% Une transition de S vers C : on sort jusqu'à leur ancêtre commun, puis
% on entre jusqu'à la cible. Une transition vers soi-même, ou vers un
% ancêtre, sort de lui et y rentre.
function [R, contexte] = franchir(A, machine, s, c, tr, R, contexte, t, u)
    ancetresS = chemin(A, s);
    ancetresC = chemin(A, c);
    commun = 0;
    for j = 1:min(numel(ancetresS), numel(ancetresC))
        if ancetresS(j) == ancetresC(j)
            commun = ancetresS(j);
        else
            break
        end
    end
    if commun == c || commun == s
        commun = A.parent(commun);   % vers soi, vers un ancêtre, vers un descendant
    end
    if A.parallele(commun + 1)
        error('Stateflow:TransitionEntreParalleles', ...
              ['La transition de ''%s'' vers ''%s'' relie deux etats paralleles : ils ' ...
               'sont actifs ensemble, on ne passe pas de l''un a l''autre.'], ...
              A.noms{s}, A.noms{c});
    end
    % l'enfant de COMMUN du côté de la source, actif, et tout ce qu'il porte
    for k = A.enfants{commun + 1}
        if any(R.actifs == k)
            [R, contexte] = sortir(A, machine, k, R, contexte);
        end
    end
    contexte = agir(tr.action, contexte, u, false);
    % puis de COMMUN jusqu'à la cible, et ses sous-états par défaut
    descente = ancetresC(find(ancetresC == commun, 1) + 1:end);
    if commun == 0
        descente = ancetresC;
    end
    for j = 1:numel(descente) - 1
        [R, contexte] = activer(A, machine, descente(j), R, contexte, t);
    end
    [R, contexte] = entrer(A, machine, c, R, contexte, t, false);
end

% Les ancêtres de K, du plus haut à K lui-même.
function c = chemin(A, k)
    c = k;
    while A.parent(c(1)) > 0
        c = [A.parent(c(1)), c]; %#ok<AGROW>
    end
end

% Entrer dans K — ou, pour K = 0, dans le diagramme — : son action
% d'entrée, puis ses sous-états : tous s'il est parallèle, sinon celui de
% l'historique ou celui par défaut.
function [R, contexte] = entrer(A, machine, k, R, contexte, t, racine)
    if ~(racine && k == 0)
        [R, contexte] = activer(A, machine, k, R, contexte, t);
    end
    enfants = A.enfants{k + 1};
    if isempty(enfants)
        return
    end
    if A.parallele(k + 1)
        for j = enfants
            [R, contexte] = entrer(A, machine, j, R, contexte, t, false);
        end
        return
    end
    suivant = A.defaut(k + 1);
    if A.historique(k + 1)
        h = find(R.hParents == k, 1);
        if ~isempty(h)
            suivant = R.hEnfants(h);
        end
    end
    [R, contexte] = entrer(A, machine, suivant, R, contexte, t, false);
end

function [R, contexte] = activer(A, machine, k, R, contexte, t)
    if any(R.actifs == k)
        return
    end
    R.actifs(end + 1) = k;
    R.depuis(end + 1) = R.tick;
    R.debut(end + 1) = t;
    e = machine.etats{k};
    contexte = agir(e.entree, contexte, [], false);
end

% Sortir de K : ses sous-états d'abord, du plus profond au plus haut, puis
% son action de sortie. Son parent à historique se rappelle de lui.
function [R, contexte] = sortir(A, machine, k, R, contexte)
    enfants = A.enfants{k + 1};
    for j = enfants(end:-1:1)
        if any(R.actifs == j)
            [R, contexte] = sortir(A, machine, j, R, contexte);
        end
    end
    e = machine.etats{k};
    contexte = agir(e.sortie, contexte, [], false);
    i = find(R.actifs == k, 1);
    R.actifs(i) = [];
    R.depuis(i) = [];
    R.debut(i) = [];
    p = A.parent(k);
    if A.historique(p + 1)
        h = find(R.hParents == p, 1);
        if isempty(h)
            R.hParents(end + 1) = p;
            R.hEnfants(end + 1) = k;
        else
            R.hEnfants(h) = k;
        end
    end
end
