function c = matlibre_sl_compiler(modele, options)
%MATLIBRE_SL_COMPILER Prépare un modèle pour la simulation.
%   C = MATLIBRE_SL_COMPILER(MODELE,OPTIONS) fait ce que Simulink fait
%   avant de simuler : il déplie les sous-systèmes, résout le type et les
%   paramètres de chaque bloc — les expressions s'évaluent alors dans
%   l'espace de travail de base —, vérifie le câblage port par port,
%   propage les dimensions des signaux, attribue à chaque bloc sa période
%   d'échantillonnage, range les états, ordonne le calcul, et détecte les
%   boucles algébriques pour les résoudre.
%
%   OPTIONS porte les champs pas (le pas de base, 0,01 par défaut),
%   tDebut, tFinal et config (la configuration du modèle, que lit
%   MATLIBRE_SL_CONFIG). Le champ silencieux, vrai, tait les diagnostics
%   de connexion et de boucle — LINMOD s'en sert, qui compile plusieurs
%   fois le même modèle. Le champ variable, vrai, prépare un solveur à
%   pas variable : les périodes n'ont plus à diviser un pas, le retard
%   pur garde les instants avec les valeurs, et les blocs à cassure sont
%   marqués pour la détection des passages par zéro (c.zc).
%
%   Chaque erreur nomme le bloc par son chemin, « modele/bloc », comme
%   Simulink le fait : un port qui n'existe pas, deux liens vers une même
%   entrée, des dimensions qui ne s'accordent pas, une période
%   d'échantillonnage qui n'est pas un multiple du pas, un Goto
%   introuvable. Une entrée non reliée ou une boucle algébrique donnent un
%   avertissement ou une erreur selon les réglages UnconnectedInputMsg et
%   AlgebraicLoopMsg du modèle.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = add_block(new_system('m'), 'constant', 'c', 'Value', [1 2 3]);
%      m = add_line(add_block(m, 'gain', 'k', 'Gain', 2), 'c', 'k');
%      c = matlibre_sl_compiler(m, struct('silencieux', true));
%      c.dims{c.portDebut(2)}                 % [3 1] : un vecteur de trois
%
%   Voir aussi SIM, MATLIBRE_SL_SORTIES, MATLIBRE_SL_CATALOGUE.
    if nargin < 2 || isempty(options)
        options = struct();
    end
    pas = champ(options, 'pas', 0.01);
    tDebut = champ(options, 'tDebut', 0);
    tFinal = champ(options, 'tFinal', 10);
    silencieux = champ(options, 'silencieux', false);
    variable = champ(options, 'variable', false);
    config = champ(options, 'config', []);
    if isempty(config)
        config = matlibre_sl_config('lire', modele);
    end

    nomModele = char(modele.nom);
    modele = matlibre_sl_aplatir(modele);
    n = numel(modele.blocs);

    c = struct();
    c.nom = nomModele;
    c.n = n;
    c.pas = pas;
    c.variable = variable;
    c.tDebut = tDebut;
    c.tFinal = tFinal;
    c.config = config;
    c.noms = cell(1, n);
    c.chemins = cell(1, n);
    c.types = cell(1, n);
    c.code = zeros(1, n);
    c.p = cell(1, n);
    c.nIn = zeros(1, n);
    c.nOut = zeros(1, n);
    % La garde de chaque bloc — le rang du bloc qui dit si son sous-système
    % conditionnel calcule, 0 hors d'eux —, et la conduite des sorties d'un
    % sous-système conditionnel.
    c.garde = zeros(1, n);
    c.sortieCond = cell(1, n);

    % --- 1. types et paramètres ---------------------------------------------
    for k = 1:n
        bloc = modele.blocs{k};
        c.noms{k} = char(bloc.nom);
        c.chemins{k} = [nomModele '/' c.noms{k}];
        try
            entree = matlibre_sl_catalogue('type', bloc.type);
        catch
            error('Simulink:Commands:InvalidBlockType', ...
                  ['Le bloc ''%s'' est d''un type inconnu : ''%s''. Voir ADD_BLOCK ' ...
                   'pour la liste des types reconnus.'], c.chemins{k}, char(bloc.type));
        end
        c.types{k} = entree.type;
        c.code(k) = codeDe(entree.type);
        if isfield(bloc, 'garde')
            c.garde(k) = bloc.garde;
        end
        if isfield(bloc, 'sortieConditionnelle')
            c.sortieCond{k} = bloc.sortieConditionnelle;
        end
        c.p{k} = lireParametres(entree, bloc, c.chemins{k});
        [ne, ns] = matlibre_sl_ports(struct('type', entree.type, 'nom', bloc.nom, ...
                                            'parametres', c.p{k}), entree.type);
        if ~(isfinite(ne) && ne >= 0 && ne == round(ne) && isfinite(ns) && ...
             ns >= 0 && ns == round(ns))
            error('Simulink:Parameters:InvalidPortCount', ...
                  ['Le bloc ''%s'' demande un nombre de ports qui n''est pas un ' ...
                   'entier positif : verifiez ses parametres Inputs, Outputs, ' ...
                   'NumInputs ou NumInputPorts.'], c.chemins{k});
        end
        c.nIn(k) = ne;
        c.nOut(k) = ns;
    end

    % Les blocs de code : leur fonction se prépare une fois, ici — une
    % expression devient une poignée, un texte de MATLAB Function un
    % fichier, une S-fonction dit ses tailles.
    c.fonctions = cell(1, n);
    for k = 1:n
        c.fonctions{k} = preparerCode(c, k);
    end

    % --- 2. ports de sortie, numérotés d'un bout à l'autre du modèle --------
    c.portDebut = zeros(1, n);
    c.proprio = zeros(1, 0);
    c.rang = zeros(1, 0);
    total = 0;
    for k = 1:n
        c.portDebut(k) = total + 1;
        c.proprio(total + (1:c.nOut(k))) = k;
        c.rang(total + (1:c.nOut(k))) = 1:c.nOut(k);
        total = total + c.nOut(k);
    end
    c.nPorts = total;

    % --- 3. câblage --------------------------------------------------------
    c.entrees = cell(1, n);
    for k = 1:n
        c.entrees{k} = zeros(1, c.nIn(k));
    end
    liens = matlibre_sl_liens(modele);
    for l = 1:size(liens, 1)
        a = liens(l, 1);
        b = liens(l, 2);
        pe = liens(l, 3);
        ps = liens(l, 4);
        if a < 1 || a > n || b < 1 || b > n
            error('Simulink:Commands:InvalidModel', ...
                  'Le lien %d designe un bloc qui n''existe pas dans ''%s''.', l, nomModele);
        end
        if ps > c.nOut(a)
            if c.nOut(a) == 0
                error('Simulink:Engine:InvalidPort', ...
                      'Le bloc ''%s'' n''a pas de port de sortie ; un lien en part pourtant.', ...
                      c.chemins{a});
            end
            error('Simulink:Engine:InvalidPort', ...
                  ['Le bloc ''%s'' n''a que %d port(s) de sortie ; un lien part de son ' ...
                   'port %d.'], c.chemins{a}, c.nOut(a), ps);
        end
        if pe > c.nIn(b)
            if c.nIn(b) == 0
                error('Simulink:Engine:InvalidPort', ...
                      'Le bloc ''%s'' n''a pas de port d''entree ; un lien y arrive pourtant.', ...
                      c.chemins{b});
            end
            error('Simulink:Engine:InvalidPort', ...
                  ['Le bloc ''%s'' n''a que %d port(s) d''entree ; un lien arrive sur son ' ...
                   'port %d.'], c.chemins{b}, c.nIn(b), pe);
        end
        if c.entrees{b}(pe) ~= 0
            error('Simulink:Engine:MultipleSources', ...
                  ['Le port d''entree %d de ''%s'' recoit deux liens : une entree ne ' ...
                   'recoit qu''un signal.'], pe, c.chemins{b});
        end
        c.entrees{b}(pe) = c.portDebut(a) + ps - 1;
    end

    % --- 4. Goto et From ----------------------------------------------------
    c = resoudreGoto(c);

    % --- 5. transmission directe -------------------------------------------
    c.direct = true(1, n);
    for k = 1:n
        c.direct(k) = transmissionDirecte(c, k);
    end

    % --- 6. dimensions ------------------------------------------------------
    c.dims = propagerDimensions(c);
    c.dimsCourants = c.dims;   % la forme des bus se lit sur les dimensions
    c.largeur = zeros(1, c.nPorts);
    for gp = 1:c.nPorts
        c.largeur(gp) = prod(c.dims{gp});
    end

    % --- 7. tampon des valeurs : V(1) est la masse, puis chaque port ---------
    c.vA = zeros(1, c.nPorts);
    c.vB = zeros(1, c.nPorts);
    suivant = 2;
    for gp = 1:c.nPorts
        c.vA(gp) = suivant;
        c.vB(gp) = suivant + c.largeur(gp) - 1;
        suivant = suivant + c.largeur(gp);
    end
    c.nV = suivant - 1;
    c.inA = cell(1, n);
    c.inB = cell(1, n);
    c.inDims = cell(1, n);
    c.inMat = cell(1, n);
    c.oA = zeros(1, n);
    c.oB = zeros(1, n);
    for k = 1:n
        e = c.entrees{k};
        c.inA{k} = ones(1, numel(e));
        c.inB{k} = ones(1, numel(e));
        c.inDims{k} = cell(1, numel(e));
        c.inMat{k} = false(1, numel(e));
        for j = 1:numel(e)
            if e(j) > 0
                c.inA{k}(j) = c.vA(e(j));
                c.inB{k}(j) = c.vB(e(j));
                c.inDims{k}{j} = c.dims{e(j)};
                c.inMat{k}(j) = all(c.dims{e(j)} > 1);
            else
                c.inDims{k}{j} = [1 1];
            end
        end
        if c.nOut(k) >= 1
            c.oA(k) = c.vA(c.portDebut(k));
            c.oB(k) = c.vB(c.portDebut(k));
        end
    end

    % --- 8. périodes d'échantillonnage -------------------------------------
    c = periodes(c, pas);

    % --- 9. ce que le calcul lira : paramètres et états ---------------------
    c = abaisser(c, pas, tDebut);
    % Un sous-système déclenché ne calcule qu'aux fronts : un état continu
    % n'y aurait rien à intégrer entre deux, et Simulink le refuse.
    c.declenche = false(1, n);
    for k = 1:n
        g = c.garde(k);
        while g > 0
            if ~strcmp(c.p{g}.Trigger, 'none')
                c.declenche(k) = true;
                break
            end
            g = c.garde(g);
        end
        if c.declenche(k) && c.xA(k) > 0
            error('Simulink:blocks:TriggeredSubsystemContinuousStates', ...
                  ['Le bloc ''%s'' a des etats continus, mais il est dans un ' ...
                   'sous-systeme declenche, qui ne calcule qu''aux fronts de son ' ...
                   'entree Trigger. Prenez un bloc discret, ou un sous-systeme ' ...
                   'active par Enable.'], c.chemins{k});
        end
    end

    % --- 10. ordre de calcul et boucles algébriques --------------------------
    c = ordonner(c);

    % --- 11. passages par zéro ------------------------------------------------
    c.zc = passagesParZero(c);

    % --- 12. diagnostics ----------------------------------------------------
    if ~silencieux
        diagnostiquer(c);
    end
end

% === paramètres ===============================================================

function v = champ(s, nom, defaut)
    if isfield(s, nom) && ~isempty(s.(nom))
        v = s.(nom);
    else
        v = defaut;
    end
end

% Les paramètres d'un bloc, sous leur nom canonique, avec le défaut de ceux
% qu'on n'a pas écrits. Un nom inconnu est refusé en le nommant, comme
% Simulink le fait : rangé, il n'aurait été lu par personne.
function p = lireParametres(entree, bloc, chemin)
    p = struct();
    for i = 1:size(entree.params, 1)
        p.(entree.params{i, 1}) = entree.params{i, 2};
    end
    communs = matlibre_sl_catalogue('communs');
    ecrits = fieldnames(bloc.parametres);
    for i = 1:numel(ecrits)
        canon = matlibre_sl_catalogue('parametre', entree, ecrits{i});
        if isempty(canon)
            error('Simulink:Commands:ParamUnknown', ...
                  ['Le bloc ''%s'' (%s) n''a pas de parametre nomme ''%s''. Ses ' ...
                   'parametres sont : %s.'], chemin, entree.affiche, ecrits{i}, ...
                  strjoin(entree.params(:, 1)', ', '));
        end
        if any(strcmp(canon, communs))
            continue
        end
        p.(canon) = bloc.parametres.(ecrits{i});
    end
    for i = 1:size(entree.params, 1)
        nom = entree.params{i, 1};
        nature = entree.params{i, 3};
        v = p.(nom);
        if iscell(nature)
            p.(nom) = choisir(v, nature, chemin, nom);
        elseif strcmp(nature, 'nombre')
            if (ischar(v) || isstring(v)) && isfield(bloc, 'espace')
                v = matlibre_sl_masque('evaluer', char(v), bloc.espace, chemin, nom);
            elseif ischar(v) || isstring(v)
                v = matlibre_sl_expression(char(v), chemin, nom);
            end
            if ~(isnumeric(v) || islogical(v))
                error('Simulink:Parameters:InvalidValue', ...
                      'Le parametre ''%s'' du bloc ''%s'' doit etre numerique.', nom, chemin);
            end
            p.(nom) = double(v);
        elseif strcmp(nature, 'texte')
            if isnumeric(v)
                p.(nom) = v;
            else
                p.(nom) = char(v);
            end
        end
    end
end

% Un choix se compare sans la casse ni les espaces : « u2>=Threshold » et
% « u2 >= Threshold » disent la même chose.
function v = choisir(v, admis, chemin, nom)
    if isnumeric(v) && isscalar(v)
        v = num2str(v);
    end
    cle = lower(regexprep(char(v), '\s', ''));
    for i = 1:numel(admis)
        if strcmp(cle, lower(regexprep(admis{i}, '\s', '')))
            v = admis{i};
            return
        end
    end
    error('Simulink:Parameters:InvalidValue', ...
          ['Le parametre ''%s'' du bloc ''%s'' vaut ''%s'' ; les valeurs admises ' ...
           'sont : %s.'], nom, chemin, char(v), strjoin(admis, ', '));
end

% Le code numérique de chaque type : c'est lui que la boucle de calcul
% aiguille, plus vite qu'une chaîne. La table est la seule : les fichiers
% d'exécution citent le type en commentaire de chaque cas.
function x = codeDe(type)
    persistent table
    if isempty(table)
        noms = {'constant', 1; 'step', 2; 'ramp', 3; 'sine', 4; 'clock', 5; ...
                'digitalclock', 6; 'pulsegenerator', 7; 'ground', 8; ...
                'repeatingsequence', 9; 'randomnumber', 10; ...
                'uniformrandomnumber', 11; 'inport', 12; 'fromworkspace', 13; ...
                'from', 14; ...
                'gain', 20; 'sum', 21; 'product', 22; 'abs', 23; 'sign', 24; ...
                'math', 25; 'trigonometry', 26; 'minmax', 27; 'bias', 28; ...
                'dotproduct', 29; 'unaryminus', 30; 'rounding', 31; ...
                'polynomial', 32; 'sqrt', 33; ...
                'saturation', 40; 'deadzone', 41; 'relay', 42; 'quantizer', 43; ...
                'ratelimiter', 44; 'hitcrossing', 45; 'backlash', 46; ...
                'coulombfriction', 47; 'lookup', 48; 'lookup2d', 49; ...
                'logic', 50; 'relational', 51; 'comparetoconstant', 52; ...
                'comparetozero', 53; 'detectchange', 54; 'detectincrease', 55; ...
                'detectdecrease', 56; ...
                'switch', 60; 'multiportswitch', 61; 'mux', 62; 'demux', 63; ...
                'selector', 64; 'concatenate', 65; 'reshape', 66; 'goto', 67; ...
                'signalconversion', 68; ...
                'integrator', 70; 'derivative', 71; 'transferfcn', 72; ...
                'statespace', 73; 'zeropole', 74; 'transportdelay', 75; ...
                'pidcontroller', 76; ...
                'delay', 80; 'memory', 81; 'zoh', 82; 'discreteintegrator', 83; ...
                'discretetransferfcn', 84; 'discretefilter', 85; ...
                'discretestatespace', 86; ...
                'outport', 90; 'scope', 91; 'display', 92; 'toworkspace', 93; ...
                'terminator', 94; 'stopsimulation', 95; 'assertion', 96; ...
                'subsystem', 99; ...
                'if', 110; 'switchcase', 111; 'merge', 112; 'garde', 113; ...
                'enableport', 114; 'triggerport', 115; 'actionport', 116; ...
                'fcn', 100; 'matlabfunction', 101; 'interpretedmatlabfunction', 102; ...
                'sfunction', 103; 'chart', 104; ...
                'buscreator', 62; 'busselector', 63; 'datatypeconversion', 34};
        table = containers.Map(noms(:, 1)', noms(:, 2)');
    end
    x = table(type);
end

% === Goto et From ==============================================================
%
% Un From rend le signal qui entre dans le Goto de même étiquette. La
% portée suit TagVisibility : « local », le même système ; « global »,
% tout le modèle ; « scoped », le système du Goto et ceux qu'il contient.
% Le From lit donc, sans lien visible, le port qui alimente le Goto.
function c = resoudreGoto(c)
    gotos = find(strcmp(c.types, 'goto'));
    froms = find(strcmp(c.types, 'from'));
    for f = froms
        etiquette = char(c.p{f}.GotoTag);
        systemeFrom = parent(c.noms{f});
        candidats = [];
        for g = gotos
            if ~strcmp(char(c.p{g}.GotoTag), etiquette)
                continue
            end
            systemeGoto = parent(c.noms{g});
            switch c.p{g}.TagVisibility
                case 'global'
                    visible = true;
                case 'scoped'
                    visible = strncmp(systemeFrom, systemeGoto, numel(systemeGoto));
                otherwise
                    visible = strcmp(systemeFrom, systemeGoto);
            end
            if visible
                candidats(end + 1) = g; %#ok<AGROW>
            end
        end
        if isempty(candidats)
            error('Simulink:Engine:GotoTagMissing', ...
                  ['Le bloc From ''%s'' lit l''etiquette ''%s'', qu''aucun bloc Goto ' ...
                   'visible depuis lui ne porte.'], c.chemins{f}, etiquette);
        end
        if numel(candidats) > 1
            error('Simulink:Engine:GotoTagDuplicate', ...
                  ['L''etiquette ''%s'' que lit ''%s'' est portee par plusieurs blocs ' ...
                   'Goto : %s.'], etiquette, c.chemins{f}, ...
                  strjoin(c.chemins(candidats), ', '));
        end
        % Le From lit ce qui entre dans le Goto : une entrée invisible, que
        % le calcul et l'ordre traitent comme un lien.
        c.entrees{f} = c.entrees{candidats}(1);
        c.nIn(f) = 1;
    end
end

function s = parent(nom)
    barre = find(nom == '/', 1, 'last');
    if isempty(barre)
        s = '';
    else
        s = nom(1:barre - 1);
    end
end

% === transmission directe =====================================================
%
% Un bloc transmet directement quand sa sortie à l'instant t dépend de son
% entrée à l'instant t. C'est ce qui ordonne le calcul — il vient après ce
% qui l'alimente — et ce qui fait qu'une boucle sans autre bloc est
% algébrique.
function d = transmissionDirecte(c, k)
    p = c.p{k};
    switch c.types{k}
        case {'integrator', 'delay', 'memory'}
            d = strcmp(c.types{k}, 'delay') && p.DelayLength == 0;
        case {'statespace', 'discretestatespace'}
            d = any(p.D(:) ~= 0);
        case 'transferfcn'
            [num, den] = transmittance(p.Numerator, p.Denominator, c.chemins{k});
            d = numel(num) == numel(den) && num(1) ~= 0;
        case 'zeropole'
            d = numel(p.Zeros) == numel(p.Poles) && p.Gain ~= 0;
        case 'transportdelay'
            d = p.DelayTime == 0;
        case 'discreteintegrator'
            d = ~strcmp(p.IntegratorMethod, 'ForwardEuler');
        case 'sfunction'
            d = c.fonctions{k}.tailles(6) ~= 0;
        case {'discretetransferfcn', 'discretefilter'}
            [b, ~] = filtreDiscret(p.Numerator, p.Denominator, ...
                                   strcmp(c.types{k}, 'discretetransferfcn'), c.chemins{k});
            d = b(1) ~= 0;
        otherwise
            d = true;
    end
end

% Une transmittance continue : le numérateur ne doit pas être de degré plus
% haut que le dénominateur, sans quoi elle n'a pas de réalisation d'état.
function [num, den] = transmittance(num, den, chemin)
    num = double(num(:)).';
    den = double(den(:)).';
    while numel(num) > 1 && num(1) == 0
        num(1) = [];
    end
    while numel(den) > 1 && den(1) == 0
        den(1) = [];
    end
    if isempty(den) || all(den == 0)
        error('Simulink:blocks:TransferFcnZeroDenominator', ...
              'Le denominateur de ''%s'' est nul.', chemin);
    end
    if numel(num) > numel(den)
        error('Simulink:blocks:TransferFcnImproper', ...
              ['La transmittance de ''%s'' a un numerateur de degre %d et un ' ...
               'denominateur de degre %d : elle n''est pas propre, et n''a pas de ' ...
               'realisation d''etat.'], chemin, numel(num) - 1, numel(den) - 1);
    end
end

% Un filtre discret ramené à deux vecteurs de même longueur, en puissances
% croissantes de z^-1, le premier coefficient du dénominateur valant un.
% « Discrete Transfer Fcn » s'écrit en puissances de z : le polynôme court
% se complète à gauche. « Discrete Filter » s'écrit en puissances de z^-1 :
% il se complète à droite. Les deux coïncident quand les longueurs sont
% égales.
function [b, a] = filtreDiscret(num, den, enZ, chemin)
    b = double(num(:)).';
    a = double(den(:)).';
    if enZ
        while numel(a) > 1 && a(1) == 0
            a(1) = [];
        end
    end
    if isempty(a) || a(1) == 0
        error('simulink:sim:denominateurNul', ...
              ['Le bloc ''%s'' a un denominateur dont le premier coefficient ' ...
               'est nul : la recurrence ne se resout pas.'], chemin);
    end
    if enZ && numel(b) > numel(a)
        error('Simulink:blocks:TransferFcnImproper', ...
              ['La transmittance discrete de ''%s'' a un numerateur de degre plus ' ...
               'haut que son denominateur : elle demanderait l''entree future.'], chemin);
    end
    L = max(numel(a), numel(b));
    if enZ
        b = [zeros(1, L - numel(b)), b];
        a = [a, zeros(1, L - numel(a))];
    else
        b = [b, zeros(1, L - numel(b))];
        a = [a, zeros(1, L - numel(a))];
    end
    b = b / a(1);
    a = a / a(1);
end

% === dimensions ================================================================
%
% On part des sources, dont les paramètres disent la taille, et l'on
% avance jusqu'à ce que plus rien ne change. Une boucle dont aucun bloc ne
% fixe la taille — un intégrateur de condition initiale scalaire bouclé
% sur un gain — reste alors indéterminée : les blocs à état y prennent la
% taille de leur condition initiale, et l'on repart.
function dims = propagerDimensions(c)
    dims = cell(1, c.nPorts);
    connu = false(1, c.nPorts);
    forcer = false;
    for tour = 1:(4 * c.n + 10)
        progres = false;
        for k = 1:c.n
            if c.nOut(k) == 0
                continue
            end
            ports = c.portDebut(k) + (0:c.nOut(k) - 1);
            if all(connu(ports))
                continue
            end
            [dimsE, complet] = dimsEntrees(c, k, dims, connu);
            if strcmp(c.types{k}, 'busselector')
                c.dimsCourants = dims;   % il lit la forme du bus en amont
            end
            sortie = regleDims(c, k, dimsE, complet, forcer);
            if isempty(sortie) || any(cellfun(@isempty, sortie))
                continue
            end
            for q = 1:numel(ports)
                dims{ports(q)} = sortie{q};
                connu(ports(q)) = true;
            end
            progres = true;
        end
        if all(connu)
            break
        end
        if ~progres
            if forcer
                % Plus rien ne se détermine : ce qui reste est scalaire.
                for gp = find(~connu)
                    dims{gp} = [1 1];
                    connu(gp) = true;
                end
                break
            end
            forcer = true;
        end
    end
    % Une fois tout connu, chaque bloc vérifie ses entrées : c'est là que
    % tombent les désaccords de dimensions.
    c.dimsCourants = dims;
    for k = 1:c.n
        [dimsE, ~] = dimsEntrees(c, k, dims, connu);
        sortie = regleDims(c, k, dimsE, true, true);
        if c.nOut(k) == 0
            continue
        end
        ports = c.portDebut(k) + (0:c.nOut(k) - 1);
        for q = 1:numel(ports)
            if ~isequal(dims{ports(q)}, sortie{q})
                error('Simulink:Engine:DimensionMismatch', ...
                      ['Erreur de dimensions : la sortie %d de ''%s'' devrait etre de ' ...
                       'dimension %s, mais la boucle ou elle se trouve lui impose %s.'], ...
                      q, c.chemins{k}, texteDims(sortie{q}), texteDims(dims{ports(q)}));
            end
        end
    end
end

function [dimsE, complet] = dimsEntrees(c, k, dims, connu)
    e = c.entrees{k};
    dimsE = cell(1, numel(e));
    complet = true;
    for j = 1:numel(e)
        if e(j) == 0
            dimsE{j} = [1 1];     % une entrée en l'air vaut un zéro scalaire
        elseif connu(e(j))
            dimsE{j} = dims{e(j)};
        else
            dimsE{j} = [];
            complet = false;
        end
    end
end

function t = texteDims(d)
    if isempty(d)
        t = '(inconnue)';
    elseif prod(d) == 1
        t = 'scalaire';
    elseif d(2) == 1
        t = sprintf('%d (vecteur)', d(1));
    else
        t = sprintf('[%d %d]', d(1), d(2));
    end
end

% La taille d'un paramètre devenu signal : un vecteur, ligne ou colonne,
% est un vecteur ; une matrice reste une matrice.
function d = dimsDe(v)
    if numel(v) <= 1
        d = [1 1];
    elseif isvector(v)
        d = [numel(v) 1];
    else
        d = size(v);
        d = d(1:2);
    end
end

% Des dimensions qui doivent s'accorder : égales, ou l'une scalaire, qui
% s'étend aux autres. C'est la règle des blocs élément par élément.
function d = accorder(liste, c, k, quoi)
    d = [1 1];
    premiere = 0;
    for j = 1:numel(liste)
        x = liste{j};
        if isempty(x) || prod(x) == 1
            continue
        end
        if prod(d) == 1
            d = x;
            premiere = j;
        elseif ~isequal(x, d)
            if numel(quoi) >= max(j, premiere)
                a = quoi{premiere};
                b = quoi{j};
            else
                a = sprintf('l''entree %d', premiere);
                b = sprintf('l''entree %d', j);
            end
            error('Simulink:Engine:DimensionMismatch', ...
                  ['Erreur de dimensions dans ''%s'' : %s est de dimension %s et %s ' ...
                   'de dimension %s. Elles doivent etre egales, ou l''une scalaire.'], ...
                  c.chemins{k}, a, texteDims(d), b, texteDims(x));
        end
    end
end

function q = nomsEntrees(n)
    q = cell(1, n);
    for j = 1:n
        q{j} = sprintf('l''entree %d', j);
    end
end

% Les dimensions des sorties d'un bloc, d'après ses paramètres et celles
% de ses entrées. Rend {} quand il faut attendre une entrée inconnue.
function s = regleDims(c, k, dE, complet, forcer)
    p = c.p{k};
    t = c.types{k};
    s = {};
    switch t
        % --- sources ---
        case 'constant'
            s = {dimsDe(p.Value)};
        case 'step'
            s = {accorder({dimsDe(p.Time), dimsDe(p.Before), dimsDe(p.After)}, c, k, ...
                          {'Time', 'Before', 'After'})};
        case 'ramp'
            s = {accorder({dimsDe(p.Slope), dimsDe(p.Start), dimsDe(p.InitialOutput)}, ...
                          c, k, {'Slope', 'Start', 'InitialOutput'})};
        case 'sine'
            s = {accorder({dimsDe(p.Amplitude), dimsDe(p.Frequency), dimsDe(p.Phase), ...
                           dimsDe(p.Bias)}, c, k, ...
                          {'Amplitude', 'Frequency', 'Phase', 'Bias'})};
        case {'clock', 'digitalclock', 'ground', 'repeatingsequence'}
            s = {[1 1]};
        case {'enableport', 'triggerport', 'actionport'}
            s = {};
        case 'pulsegenerator'
            s = {accorder({dimsDe(p.Amplitude), dimsDe(p.Period), dimsDe(p.PulseWidth), ...
                           dimsDe(p.PhaseDelay)}, c, k, ...
                          {'Amplitude', 'Period', 'PulseWidth', 'PhaseDelay'})};
        case 'randomnumber'
            s = {accorder({dimsDe(p.Mean), dimsDe(p.Variance), dimsDe(p.Seed)}, c, k, ...
                          {'Mean', 'Variance', 'Seed'})};
        case 'uniformrandomnumber'
            s = {accorder({dimsDe(p.Minimum), dimsDe(p.Maximum), dimsDe(p.Seed)}, c, k, ...
                          {'Minimum', 'Maximum', 'Seed'})};
        case 'inport'
            if isnumeric(p.PortDimensions) && all(p.PortDimensions > 0)
                d = double(p.PortDimensions);
                if isscalar(d), d = [d 1]; end
                s = {d(1:2)};
            else
                s = {dimsDe(p.Value)};
            end
        case 'fromworkspace'
            [~, valeurs] = lireSignalEspace(p.VariableName, c.chemins{k});
            s = {dimsDe(zeros(size(valeurs, 2), 1))};
        case 'from'
            if isempty(c.entrees{k}) || c.entrees{k}(1) == 0
                s = {[1 1]};
            elseif complet || ~isempty(dE)
                if isempty(dE) || isempty(dE{1})
                    return
                end
                s = dE(1);
            end
        otherwise
            if ~complet && ~forcer && ~ismember(t, {'statespace', 'transferfcn', ...
                    'zeropole', 'discretetransferfcn', 'discretefilter', ...
                    'discretestatespace', 'integrator', 'delay', 'memory', ...
                    'discreteintegrator', 'sfunction'})
                return
            end
            s = regleTraitement(c, k, dE, complet, forcer);
    end
end

function s = regleTraitement(c, k, dE, complet, forcer)
    p = c.p{k};
    t = c.types{k};
    s = {};
    q = nomsEntrees(numel(dE));
    switch t
        case 'gain'
            K = p.Gain;
            switch p.Multiplication
                case 'Element-wise(K.*u)'
                    s = {accorder({dimsDe(K), dE{1}}, c, k, {'le gain', 'l''entree'})};
                case {'Matrix(K*u)', 'Matrix(K*u) (u vector)'}
                    if prod(dE{1}) ~= size(K, 2) && ~(isscalar(K))
                        erreurMatrice(c, k, sprintf(['le gain a %d colonne(s) et ' ...
                            'l''entree %d element(s)'], size(K, 2), prod(dE{1})));
                    end
                    if isscalar(K), s = dE(1); else, s = {[size(K, 1) 1]}; end
                case 'Matrix(u*K)'
                    if prod(dE{1}) ~= size(K, 1) && ~isscalar(K)
                        erreurMatrice(c, k, sprintf(['le gain a %d ligne(s) et ' ...
                            'l''entree %d element(s)'], size(K, 1), prod(dE{1})));
                    end
                    if isscalar(K), s = dE(1); else, s = {[size(K, 2) 1]}; end
            end
        case {'sum', 'product', 'minmax'}
            if numel(dE) == 1 && ~(strcmp(t, 'product') && ...
                    strcmp(p.Multiplication, 'Matrix(*)'))
                s = {[1 1]};     % une seule entrée : sur ses éléments
            elseif strcmp(t, 'product') && strcmp(p.Multiplication, 'Matrix(*)')
                s = {produitMatriciel(c, k, dE)};
            else
                s = {accorder(dE, c, k, q)};
            end
        case {'abs', 'sign', 'unaryminus', 'rounding', 'polynomial', 'sqrt', ...
              'quantizer', 'hitcrossing', 'coulombfriction', 'lookup', ...
              'comparetozero', 'detectchange', 'detectincrease', 'detectdecrease', ...
              'derivative', 'zoh', 'signalconversion'}
            if strcmp(t, 'signalconversion')
                s = dE;
                if isempty(s), s = {[1 1]}; end
            else
                s = dE(1);
            end
        case 'math'
            switch p.Operator
                case {'pow', 'hypot', 'rem', 'mod'}
                    s = {accorder(dE, c, k, q)};
                case {'transpose', 'hermitian'}
                    d = dE{1};
                    s = {[d(2) d(1)]};
                otherwise
                    s = dE(1);
            end
        case 'trigonometry'
            if strcmp(p.Operator, 'atan2')
                s = {accorder(dE, c, k, q)};
            elseif strcmp(p.Operator, 'sincos')
                s = {dE{1}, dE{1}};
            else
                s = dE(1);
            end
        case 'bias'
            s = {accorder({dE{1}, dimsDe(p.Bias)}, c, k, {'l''entree', 'Bias'})};
        case 'dotproduct'
            accorder(dE, c, k, q);
            s = {[1 1]};
        case 'saturation'
            s = {accorder({dE{1}, dimsDe(p.UpperLimit), dimsDe(p.LowerLimit)}, c, k, ...
                          {'l''entree', 'UpperLimit', 'LowerLimit'})};
        case 'deadzone'
            s = {accorder({dE{1}, dimsDe(p.UpperValue), dimsDe(p.LowerValue)}, c, k, ...
                          {'l''entree', 'UpperValue', 'LowerValue'})};
        case 'relay'
            s = {accorder({dE{1}, dimsDe(p.OnSwitch), dimsDe(p.OffSwitch), ...
                           dimsDe(p.OnOutput), dimsDe(p.OffOutput)}, c, k, ...
                          {'l''entree', 'OnSwitch', 'OffSwitch', 'OnOutput', 'OffOutput'})};
        case 'ratelimiter'
            s = {accorder({dE{1}, dimsDe(p.InitialOutput)}, c, k, ...
                          {'l''entree', 'InitialOutput'})};
        case 'backlash'
            s = {accorder({dE{1}, dimsDe(p.InitialOutput)}, c, k, ...
                          {'l''entree', 'InitialOutput'})};
        case 'lookup2d'
            s = {accorder(dE, c, k, q)};
        case {'logic'}
            if numel(dE) == 1 && ~strcmp(p.Operator, 'NOT')
                s = {[1 1]};
            else
                s = {accorder(dE, c, k, q)};
            end
        case 'relational'
            s = {accorder(dE, c, k, q)};
        case 'comparetoconstant'
            s = {accorder({dE{1}, dimsDe(p.const)}, c, k, {'l''entree', 'const'})};
        case 'switch'
            s = {accorder(dE, c, k, q)};
        case 'multiportswitch'
            if prod(dE{1}) ~= 1
                error('Simulink:Engine:DimensionMismatch', ...
                      'L''entree de commande de ''%s'' doit etre scalaire.', c.chemins{k});
            end
            s = {accorder(dE(2:end), c, k, q(2:end))};
        case 'buscreator'
            s = {[sum(cellfun(@prod, dE)) 1]};
        case 'busselector'
            choix = elementsChoisis(c, k);
            if isempty(choix)
                return   % la forme du bus n'est pas encore connue
            end
            if strcmp(p.OutputAsBus, 'on')
                s = {[sum([choix.largeur]) 1]};
            else
                s = arrayfun(@(e) e.dims, choix, 'UniformOutput', false);
            end
        case 'datatypeconversion'
            s = dE(1);
        case 'mux'
            largeurs = cellfun(@prod, dE);
            attendues = double(p.Inputs);
            if ~isscalar(attendues)
                for j = 1:numel(attendues)
                    if attendues(j) > 0 && attendues(j) ~= largeurs(j)
                        error('Simulink:Engine:DimensionMismatch', ...
                              ['L''entree %d de ''%s'' est de largeur %d ; le parametre ' ...
                               'Inputs en attend %d.'], j, c.chemins{k}, largeurs(j), ...
                              attendues(j));
                    end
                end
            end
            s = {[sum(largeurs) 1]};
        case 'demux'
            W = prod(dE{1});
            parts = double(p.Outputs);
            if isscalar(parts)
                if mod(W, parts) ~= 0
                    error('Simulink:Engine:DimensionMismatch', ...
                          ['L''entree de ''%s'' est de largeur %d, qui ne se partage pas en ' ...
                           '%d sorties egales ; donnez leurs largeurs dans Outputs.'], ...
                          c.chemins{k}, W, parts);
                end
                largeurs = repmat(W / parts, 1, parts);
            else
                largeurs = parts;
                libres = find(largeurs < 0);
                if numel(libres) == 1
                    largeurs(libres) = W - sum(largeurs(largeurs > 0));
                end
                if sum(largeurs) ~= W || any(largeurs < 1)
                    error('Simulink:Engine:DimensionMismatch', ...
                          ['Les largeurs demandees par ''%s'' (%s) ne font pas la largeur ' ...
                           'de son entree (%d).'], c.chemins{k}, mat2str(parts), W);
                end
            end
            s = cell(1, numel(largeurs));
            for j = 1:numel(largeurs)
                s{j} = [largeurs(j) 1];
            end
        case 'selector'
            W = prod(dE{1});
            indices = double(p.Indices(:));
            if any(indices < 1) || any(indices ~= round(indices)) || any(indices > W)
                error('Simulink:Selector:IndexOutOfRange', ...
                      ['Les indices de ''%s'' (%s) sortent de son entree, de largeur %d.'], ...
                      c.chemins{k}, mat2str(indices.'), W);
            end
            s = {dimsDe(indices)};
        case 'concatenate'
            if strcmp(p.Mode, 'Vector')
                s = {[sum(cellfun(@prod, dE)) 1]};
            else
                dim = double(p.ConcatenateDimension);
                modele = zeros(dE{1});
                for j = 2:numel(dE)
                    try
                        modele = cat(dim, modele, zeros(dE{j}));
                    catch
                        error('Simulink:Engine:DimensionMismatch', ...
                              ['Les entrees de ''%s'' ne se concatenent pas selon la ' ...
                               'dimension %d : %s et %s.'], c.chemins{k}, dim, ...
                              texteDims(dE{1}), texteDims(dE{j}));
                    end
                end
                s = {size(modele)};
            end
        case 'reshape'
            W = prod(dE{1});
            switch p.OutputDimensionality
                case {'1-D array', 'Column vector (2-D)'}
                    s = {[W 1]};
                case 'Row vector (2-D)'
                    s = {[1 W]};
                otherwise
                    d = double(p.OutputDimensions);
                    if isscalar(d), d = [d 1]; end
                    if prod(d) ~= W
                        error('Simulink:Engine:DimensionMismatch', ...
                              ['''%s'' ne peut donner la forme %s a une entree de %d ' ...
                               'elements.'], c.chemins{k}, mat2str(d), W);
                    end
                    s = {d(1:2)};
            end
        case 'integrator'
            s = {dimsAvecEtat(dE, p.InitialCondition, complet, forcer)};
        case {'delay', 'memory'}
            s = {dimsAvecEtat(dE, p.InitialCondition, complet, forcer)};
        case 'discreteintegrator'
            s = {dimsAvecEtat(dE, p.InitialCondition, complet, forcer)};
        case {'transferfcn', 'zeropole', 'discretetransferfcn', 'discretefilter'}
            if complet && prod(dE{1}) ~= 1
                error('Simulink:Engine:DimensionMismatch', ...
                      ['L''entree de ''%s'' est de largeur %d : une transmittance ne ' ...
                       'traite qu''un signal scalaire. Un State-Space traite un vecteur.'], ...
                      c.chemins{k}, prod(dE{1}));
            end
            s = {[1 1]};
        case {'statespace', 'discretestatespace'}
            [~, B, C, D] = matricesEtat(p, c.chemins{k});
            if complet
                w = prod(dE{1});
                attendu = size(B, 2);
                if size(B, 1) == 0, attendu = size(D, 2); end
                if w ~= attendu && ~(w == 1)
                    error('Simulink:Engine:DimensionMismatch', ...
                          ['L''entree de ''%s'' est de largeur %d, mais la matrice B a %d ' ...
                           'colonne(s) : il faut autant d''entrees que de colonnes.'], ...
                          c.chemins{k}, w, attendu);
                end
            end
            s = {[size(C, 1) 1]};
        case 'transportdelay'
            s = {accorder({dE{1}, dimsDe(p.InitialOutput)}, c, k, ...
                          {'l''entree', 'InitialOutput'})};
        case 'pidcontroller'
            s = dE(1);
        case {'garde', 'if', 'switchcase'}
            s = repmat({[1 1]}, 1, c.nOut(k));
        case 'fcn'
            s = {[1 1]};
        case 'interpretedmatlabfunction'
            d = double(p.OutputDimensions);
            if isequal(d, -1)
                s = dE(1);
            else
                if isscalar(d), d = [d 1]; end
                s = {d(1:2)};
            end
        case 'matlabfunction'
            s = dimsFonction(c, k, dE);
        case 'chart'
            s = c.fonctions{k}.dims;
        case 'sfunction'
            ny = c.fonctions{k}.tailles(3);
            if ny < 0
                s = dE(1);   % dimensionnée par son entrée
            else
                s = {[ny 1]};
            end
        case 'merge'
            s = {accorder([dE, {dimsDe(p.InitialOutput)}], c, k, [q, {'InitialOutput'}])};
    end
end

% Un bloc à état prend la taille de sa condition initiale quand elle n'est
% pas scalaire ; sinon celle de son entrée ; et, dans une boucle où rien ne
% la fixe, celle de sa condition initiale, scalaire.
function d = dimsAvecEtat(dE, ci, complet, forcer)
    if numel(ci) > 1
        d = dimsDe(ci);
        return
    end
    if complet && ~isempty(dE) && ~isempty(dE{1})
        d = dE{1};
        return
    end
    if forcer
        d = [1 1];
        return
    end
    d = [];
    if isempty(d)
        d = [];
    end
end

function d = produitMatriciel(c, k, dE)
    d = dE{1};
    for j = 2:numel(dE)
        e = dE{j};
        if d(2) ~= e(1)
            if prod(d) == 1 || prod(e) == 1
                d = e .* (prod(d) == 1) + d .* (prod(d) ~= 1);
                continue
            end
            erreurMatrice(c, k, sprintf('%s multiplie %s', texteDims(d), texteDims(e)));
        end
        d = [d(1) e(2)];
    end
end

function erreurMatrice(c, k, detail)
    error('Simulink:Engine:DimensionMismatch', ...
          'Produit matriciel impossible dans ''%s'' : %s.', c.chemins{k}, detail);
end

% Les matrices d'une représentation d'état, vérifiées : A carrée, B, C et D
% de tailles accordées. D donnée scalaire nulle s'étend.
function [A, B, C, D] = matricesEtat(p, chemin)
    A = double(p.A);
    B = double(p.B);
    C = double(p.C);
    D = double(p.D);
    n = size(A, 1);
    if size(A, 2) ~= n
        error('Simulink:blocks:StateSpaceANotSquare', ...
              'La matrice A de ''%s'' doit etre carree ; elle est de taille %s.', ...
              chemin, mat2str(size(A)));
    end
    if n > 0
        if size(B, 1) ~= n
            error('Simulink:blocks:StateSpaceBDimension', ...
                  'La matrice B de ''%s'' doit avoir %d ligne(s), autant que A.', chemin, n);
        end
        if size(C, 2) ~= n
            error('Simulink:blocks:StateSpaceCDimension', ...
                  'La matrice C de ''%s'' doit avoir %d colonne(s), autant que A.', chemin, n);
        end
    end
    if isscalar(D) && D == 0 && ~(size(C, 1) == 1 && size(B, 2) == 1)
        D = zeros(size(C, 1), size(B, 2));
    end
    if n > 0 && ~isequal(size(D), [size(C, 1), size(B, 2)])
        error('Simulink:blocks:StateSpaceDDimension', ...
              'La matrice D de ''%s'' doit etre de taille %s.', chemin, ...
              mat2str([size(C, 1), size(B, 2)]));
    end
end

% === périodes d'échantillonnage ===============================================
%
% Chaque bloc a une cadence : 0 s'il est continu, une période s'il est
% échantillonné, Inf s'il est constant. Les blocs qui n'en disent rien
% héritent de ce qui les alimente : continus si une entrée l'est, sinon au
% rythme de l'entrée la plus rapide. Une période qui n'est pas un multiple
% du pas fixe est refusée, comme dans Simulink : le bloc tomberait entre
% deux pas.
function c = periodes(c, pas)
    n = c.n;
    c.cadence = -ones(1, n);
    c.decalage = zeros(1, n);
    c.majeurSeul = false(1, n);
    for k = 1:n
        p = c.p{k};
        t = c.types{k};
        switch t
            case {'constant', 'ground'}
                c.cadence(k) = Inf;
                if isfield(p, 'SampleTime') && isfinite(p.SampleTime(1)) && p.SampleTime(1) > 0
                    c.cadence(k) = p.SampleTime(1);
                end
            case {'step', 'ramp', 'sine', 'clock', 'repeatingsequence', 'inport', ...
                  'fromworkspace'}
                c.cadence(k) = 0;
                if isfield(p, 'SampleTime') && p.SampleTime(1) > 0
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
                end
                % À pas variable, une source qui casse ne change qu'aux pas
                % majeurs : le solveur s'arrête sur chaque cassure, et les
                % pas mineurs du pas qui y mène ne voient pas la valeur
                % d'après — comme le mode figé d'un bloc de Simulink.
                if c.variable && (strcmp(t, 'step') || ...
                                  (strcmp(t, 'fromworkspace') && strcmp(p.Interpolate, 'off')))
                    c.majeurSeul(k) = true;
                end
            case 'pulsegenerator'
                c.cadence(k) = 0;
                if strcmp(p.PulseType, 'Sample based')
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
                elseif c.variable
                    c.majeurSeul(k) = true;   % comme l'échelon
                end
            case {'digitalclock', 'randomnumber', 'uniformrandomnumber'}
                [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
            case {'integrator', 'transferfcn', 'statespace', 'zeropole', 'pidcontroller'}
                c.cadence(k) = 0;
            case {'garde', 'if', 'switchcase'}
                % La condition d'un sous-système se décide aux pas majeurs :
                % entre deux, il garde son état, comme dans Simulink.
                c.cadence(k) = 0;
                c.majeurSeul(k) = true;
            case {'enableport', 'triggerport', 'actionport'}
                c.cadence(k) = Inf;   % hors d'un sous-système : sans effet
            case 'sfunction'
                ts = c.fonctions{k}.ts;
                if ts(1) == -1
                    c.cadence(k) = -1;
                elseif ts(1) == 0
                    c.cadence(k) = 0;
                    c.majeurSeul(k) = numel(ts) >= 2 && ts(2) == 1;   % [0 1] : aux pas majeurs
                else
                    [c.cadence(k), c.decalage(k)] = lirePeriode(ts);
                end
            case 'chart'
                % Un diagramme fait un pas par instant d'échantillonnage : à
                % ses instants s'il en a, sinon à chaque pas majeur.
                c.cadence(k) = -1;
                if p.SampleTime(1) ~= -1
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
                end
                c.majeurSeul(k) = true;
            case 'matlabfunction'
                c.cadence(k) = -1;
                if p.SampleTime(1) ~= -1
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
                end
                % Une fonction qui garde un état entre deux appels ne se
                % rappelle qu'aux pas majeurs : un pas mineur ne doit pas
                % faire avancer sa mémoire.
                if c.fonctions{k}.persistante
                    c.majeurSeul(k) = true;
                end
            case {'derivative', 'transportdelay', 'memory', 'ratelimiter', 'relay', ...
                  'backlash', 'hitcrossing', 'detectchange', 'detectincrease', ...
                  'detectdecrease'}
                % Continus pour ce qui les suit, mais calculés aux seuls pas
                % majeurs : ils comparent l'entrée à celle du pas précédent.
                % Le retard pur à pas variable fait exception : il lit son
                % tampon à chaque passe, pas mineurs compris, comme Simulink.
                c.cadence(k) = 0;
                c.majeurSeul(k) = ~(c.variable && strcmp(t, 'transportdelay'));
            case {'delay', 'discreteintegrator', 'discretetransferfcn', ...
                  'discretefilter', 'discretestatespace', 'zoh'}
                periode = p.SampleTime;
                if isempty(periode)
                    if strcmp(t, 'zoh')
                        periode = 10 * pas;
                    else
                        periode = pas;
                    end
                end
                if periode(1) == -1
                    c.cadence(k) = -1;
                elseif periode(1) == 0
                    error('Simulink:SampleTime:DiscreteBlockContinuous', ...
                          ['Le bloc ''%s'' est discret : sa periode d''echantillonnage ' ...
                           'ne peut pas etre nulle.'], c.chemins{k});
                else
                    [c.cadence(k), c.decalage(k)] = lirePeriode(periode);
                end
            otherwise
                if isfield(p, 'SampleTime') && ~isempty(p.SampleTime) && p.SampleTime(1) ~= -1
                    if p.SampleTime(1) == 0
                        c.cadence(k) = 0;
                    else
                        [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
                    end
                end
        end
    end
    % Dans un sous-système conditionnel, rien n'est constant : ce qui ne
    % change jamais doit encore se calculer quand le sous-système s'éveille.
    % Une constante y prend donc la cadence de sa garde, aux pas majeurs —
    % comme Simulink, où elle hérite de celle du sous-système.
    for k = find(c.garde > 0 & isinf(c.cadence))
        c.cadence(k) = 0;
        c.majeurSeul(k) = true;
    end
    % L'héritage : on propage jusqu'à ce que plus rien ne change.
    for tour = 1:(n + 2)
        change = false;
        for k = find(c.cadence == -1)
            e = c.entrees{k};
            e = e(e > 0);
            if isempty(e)
                c.cadence(k) = Inf;
                if c.garde(k) > 0
                    c.cadence(k) = 0;
                    c.majeurSeul(k) = true;
                end
                change = true;
                continue
            end
            sources = c.proprio(e);
            cad = c.cadence(sources);
            if any(cad == 0)
                c.cadence(k) = 0;
            elseif any(cad == -1)
                continue
            elseif all(isinf(cad))
                c.cadence(k) = Inf;
                if c.garde(k) > 0
                    c.cadence(k) = 0;
                    c.majeurSeul(k) = true;
                end
            else
                finies = cad(isfinite(cad) & cad > 0);
                c.cadence(k) = min(finies);
            end
            change = true;
        end
        if ~change
            break
        end
    end
    c.cadence(c.cadence == -1) = 0;   % une boucle d'héritiers : continue

    c.periodePas = zeros(1, n);
    c.decalagePas = zeros(1, n);
    for k = 1:n
        if c.cadence(k) > 0 && isfinite(c.cadence(k)) && ...
           (c.decalage(k) < 0 || c.decalage(k) >= c.cadence(k))
            error('Simulink:SampleTime:InvalidOffset', ...
                  ['Le decalage %g de la periode de ''%s'' doit etre positif et ' ...
                   'inferieur a la periode %g : [periode, decalage] avec 0 <= decalage ' ...
                   '< periode.'], c.decalage(k), c.chemins{k}, c.cadence(k));
        end
        if c.variable && c.cadence(k) > 0 && isfinite(c.cadence(k))
            % À pas variable, le solveur s'arrête sur chaque instant
            % d'échantillonnage : une période n'a rien à diviser.
            c.majeurSeul(k) = true;
        elseif c.cadence(k) > 0 && isfinite(c.cadence(k))
            rapport = c.cadence(k) / pas;
            if abs(rapport - round(rapport)) > 1e-9 * max(1, rapport) || round(rapport) < 1
                error('Simulink:SampleTime:NotMultipleOfFixedStep', ...
                      ['La periode d''echantillonnage %g de ''%s'' n''est pas un multiple ' ...
                       'entier du pas fixe %g du modele ''%s''. Choisissez un pas qui la ' ...
                       'divise.'], c.cadence(k), c.chemins{k}, pas, c.nom);
            end
            c.periodePas(k) = round(rapport);
            decal = c.decalage(k) / pas;
            if abs(decal - round(decal)) > 1e-9 * max(1, decal)
                error('Simulink:SampleTime:NotMultipleOfFixedStep', ...
                      ['Le decalage %g de la periode de ''%s'' n''est pas un multiple ' ...
                       'entier du pas fixe %g.'], c.decalage(k), c.chemins{k}, pas);
            end
            c.decalagePas(k) = round(decal);
            c.majeurSeul(k) = true;
        elseif isinf(c.cadence(k))
            c.majeurSeul(k) = true;
        end
    end
end

function [periode, decalage] = lirePeriode(v)
    v = double(v);
    periode = v(1);
    decalage = 0;
    if numel(v) >= 2
        decalage = v(2);
    end
end

% === ce que le calcul lira ===================================================
%
% Chaque bloc est ramené à des nombres : un segment de paramètres (SEG),
% un code d'opération (SUB), et deux sortes d'états. Les états continus
% forment un seul vecteur, celui qu'intègre le solveur. Les autres —
% tampons des retards, valeurs tenues, modes des relais — forment un
% second vecteur, que la mise à jour fait avancer aux pas majeurs. Tout
% est vérifié ici, une fois : pendant la simulation il ne reste que de
% l'arithmétique.
%
% La disposition de chaque segment est décrite à côté du bloc ; c'est
% celle que lit MATLIBRE_SL_EXECUTER.
function c = abaisser(c, pas, tDebut)
    n = c.n;
    c.objets = cell(1, n);
    c.xA = zeros(1, n);
    c.xB = zeros(1, n);
    c.x0 = zeros(0, 1);
    c.seg = cell(1, n);
    c.sub = zeros(1, n);
    c.z0 = cell(1, n);
    for k = 1:n
        p = c.p{k};
        w = sortieLargeur(c, k);
        ch = c.chemins{k};
        seg = zeros(0, 1);
        z0 = zeros(0, 1);
        sub = 0;
        switch c.types{k}
            % --- sources ---
            case 'constant'
                seg = double(p.Value(:));
            case 'step'                   % [Time; Before; After], w chacun
                seg = [etendre(p.Time, w, ch, 'Time'); etendre(p.Before, w, ch, 'Before'); ...
                       etendre(p.After, w, ch, 'After')];
            case 'ramp'                   % [Slope; Start; InitialOutput]
                seg = [etendre(p.Slope, w, ch, 'Slope'); etendre(p.Start, w, ch, 'Start'); ...
                       etendre(p.InitialOutput, w, ch, 'InitialOutput')];
            case 'sine'                   % [Amplitude; Frequency; Phase; Bias]
                seg = [etendre(p.Amplitude, w, ch, 'Amplitude'); ...
                       etendre(p.Frequency, w, ch, 'Frequency'); ...
                       etendre(p.Phase, w, ch, 'Phase'); etendre(p.Bias, w, ch, 'Bias')];
            case 'pulsegenerator'         % [Amplitude; Period; PulseWidth; PhaseDelay; Ts]
                periode = etendre(p.Period, w, ch, 'Period');
                largeur = etendre(p.PulseWidth, w, ch, 'PulseWidth');
                if any(periode <= 0)
                    error('Simulink:Parameters:InvalidValue', ...
                          'La periode du generateur d''impulsions ''%s'' doit etre positive.', ch);
                end
                sub = 1 + strcmp(p.PulseType, 'Sample based');
                if sub == 1 && any(largeur < 0 | largeur > 100)
                    error('Simulink:Parameters:InvalidValue', ...
                          ['La largeur d''impulsion de ''%s'' est un pourcentage de la ' ...
                           'periode, entre 0 et 100.'], ch);
                end
                seg = [etendre(p.Amplitude, w, ch, 'Amplitude'); periode; largeur; ...
                       etendre(p.PhaseDelay, w, ch, 'PhaseDelay'); c.cadence(k)];
            case 'repeatingsequence'      % [n; instants; valeurs]
                tv = double(p.rep_seq_t(:));
                yv = double(p.rep_seq_y(:));
                if numel(tv) ~= numel(yv) || numel(tv) < 2 || any(diff(tv) < 0) || ...
                        tv(end) <= tv(1)
                    error('Simulink:Parameters:InvalidValue', ...
                          ['Les instants et les valeurs de ''%s'' doivent avoir la meme ' ...
                           'longueur, au moins deux points, et des instants croissants.'], ch);
                end
                seg = [numel(tv); tv; yv];
            case {'randomnumber', 'uniformrandomnumber'}
                % Le tirage suit Park et Miller, un générateur que tout le
                % monde peut refaire : l'état de chaque élément est dans Z,
                % avec la valeur courante. SEG : [gaussien; moyenne ou
                % minimum; variance ou maximum], w chacun.
                gaussien = strcmp(c.types{k}, 'randomnumber');
                if gaussien
                    un = etendre(p.Mean, w, ch, 'Mean');
                    deux = etendre(p.Variance, w, ch, 'Variance');
                    if any(deux < 0)
                        error('Simulink:Parameters:InvalidValue', ...
                              'La variance de ''%s'' ne peut pas etre negative.', ch);
                    end
                else
                    un = etendre(p.Minimum, w, ch, 'Minimum');
                    deux = etendre(p.Maximum, w, ch, 'Maximum');
                end
                seg = [double(gaussien); un; deux];
                graines = etendre(p.Seed, w, ch, 'Seed');
                etatsPM = mod(floor(abs(graines)), 2147483646) + 1;
                [valeurs, etatsPM] = matlibre_sl_hasard(etatsPM, gaussien, un, deux);
                z0 = [etatsPM; valeurs];
            case 'inport'
                seg = etendre(p.Value, w, ch, 'Value');
            case 'fromworkspace'          % [n; w; interpole; apres; temps; valeurs]
                [temps, valeurs] = lireSignalEspace(p.VariableName, ch);
                apres = find(strcmp(p.OutputAfterFinalValue, ...
                                    {'Setting to zero', 'Holding final value', ...
                                     'Extrapolation'})) - 1;
                seg = [numel(temps); size(valeurs, 2); strcmp(p.Interpolate, 'on'); apres; ...
                       temps; valeurs(:)];
                z0 = 1;   % le rang du dernier instant atteint, pour ne pas chercher
            % --- opérations ---
            case 'gain'                   % [lignes; colonnes; K(:)]
                K = double(p.Gain);
                sub = find(strcmp(p.Multiplication, {'Element-wise(K.*u)', 'Matrix(K*u)', ...
                                                     'Matrix(u*K)', 'Matrix(K*u) (u vector)'}));
                seg = [size(K, 1); size(K, 2); K(:)];
            case 'sum'                    % [n; signes]
                signes = signesDe(p.Signs, '+-', c.nIn(k));
                if numel(signes) ~= c.nIn(k)
                    signes = ones(1, c.nIn(k));
                end
                seg = [c.nIn(k); signes(:)];
            case 'product'                % [n; operations; matriciel; dimensions]
                ops = signesDe(p.Inputs, '*/', c.nIn(k));
                if numel(ops) ~= c.nIn(k)
                    ops = ones(1, c.nIn(k));
                end
                matriciel = strcmp(p.Multiplication, 'Matrix(*)');
                d = zeros(2 * c.nIn(k), 1);
                for j = 1:c.nIn(k)
                    d(2 * j - 1:2 * j) = c.inDims{k}{j}(:);
                end
                seg = [c.nIn(k); ops(:); matriciel; d];
                sub = 1 + matriciel;
            case 'math'
                sub = find(strcmp(p.Operator, {'exp', 'log', '10^u', 'log10', 'magnitude^2', ...
                                               'square', 'sqrt', 'pow', 'conj', 'reciprocal', ...
                                               'hypot', 'rem', 'mod', 'transpose', 'hermitian'}));
                d = c.inDims{k}{1};
                seg = d(:);
            case 'trigonometry'
                sub = find(strcmp(p.Operator, {'sin', 'cos', 'tan', 'asin', 'acos', 'atan', ...
                                               'atan2', 'sinh', 'cosh', 'tanh', 'asinh', ...
                                               'acosh', 'atanh', 'sincos'}));
            case 'minmax'
                sub = 1 + strcmp(p.Function, 'max');
                seg = c.nIn(k);
            case 'bias'
                seg = etendre(p.Bias, w, ch, 'Bias');
            case 'rounding'
                sub = find(strcmp(p.Operator, {'floor', 'ceil', 'round', 'fix'}));
            case 'polynomial'
                coefs = double(p.coefs(:));
                if isempty(coefs)
                    coefs = 0;
                end
                seg = [numel(coefs); coefs];
            case 'sqrt'
                sub = find(strcmp(p.Operator, {'sqrt', 'signedSqrt', 'rSqrt'}));
            % --- non-linéarités ---
            case 'saturation'             % [haut; bas]
                haut = etendre(p.UpperLimit, w, ch, 'UpperLimit');
                bas = etendre(p.LowerLimit, w, ch, 'LowerLimit');
                if any(bas > haut)
                    error('Simulink:blocks:SaturationLimits', ...
                          ['La limite basse de ''%s'' depasse sa limite haute : la ' ...
                           'saturation n''a pas de sens.'], ch);
                end
                seg = [haut; bas];
            case 'deadzone'               % [haut; bas]
                haut = etendre(p.UpperValue, w, ch, 'UpperValue');
                bas = etendre(p.LowerValue, w, ch, 'LowerValue');
                if any(bas > haut)
                    error('Simulink:blocks:DeadZoneLimits', ...
                          'Le debut de la zone morte de ''%s'' depasse sa fin.', ch);
                end
                seg = [haut; bas];
            case 'relay'                  % [marche; arret; sortieMarche; sortieArret]
                marche = etendre(p.OnSwitch, w, ch, 'OnSwitch');
                arret = etendre(p.OffSwitch, w, ch, 'OffSwitch');
                if any(arret > marche)
                    error('Simulink:blocks:RelayOnOffSwitch', ...
                          ['Le seuil de marche de ''%s'' doit etre au-dessus de son seuil ' ...
                           'd''arret.'], ch);
                end
                seg = [marche; arret; etendre(p.OnOutput, w, ch, 'OnOutput'); ...
                       etendre(p.OffOutput, w, ch, 'OffOutput')];
                z0 = zeros(w, 1);
            case 'quantizer'
                q = etendre(p.QuantizationInterval, w, ch, 'QuantizationInterval');
                if any(q <= 0)
                    error('Simulink:Parameters:InvalidValue', ...
                          'Le pas de quantification de ''%s'' doit etre positif.', ch);
                end
                seg = q;
            case 'ratelimiter'            % [montee; descente]  Z : [parti; t; y]
                montee = etendre(p.RisingSlewLimit, w, ch, 'RisingSlewLimit');
                descente = etendre(p.FallingSlewLimit, w, ch, 'FallingSlewLimit');
                if any(montee < descente)
                    error('Simulink:Parameters:InvalidValue', ...
                          ['La pente de montee de ''%s'' doit etre au-dessus de sa pente ' ...
                           'de descente.'], ch);
                end
                seg = [montee; descente];
                z0 = [0; tDebut; etendre(p.InitialOutput, w, ch, 'InitialOutput')];
            case 'hitcrossing'            % [seuil]  Z : [parti; ecart precedent]
                seg = etendre(p.HitCrossingOffset, w, ch, 'HitCrossingOffset');
                sub = find(strcmp(p.HitCrossingDirection, {'rising', 'falling', 'either'}));
                z0 = [0; zeros(w, 1)];
            case 'backlash'               % [largeur]  Z : sortie tenue
                largeur = etendre(p.BacklashWidth, w, ch, 'BacklashWidth');
                if any(largeur < 0)
                    error('Simulink:Parameters:InvalidValue', ...
                          'La largeur du jeu de ''%s'' ne peut pas etre negative.', ch);
                end
                seg = largeur;
                z0 = etendre(p.InitialOutput, w, ch, 'InitialOutput');
            case 'coulombfriction'        % [offset; gain]
                seg = [etendre(p.offset, w, ch, 'Offset'); etendre(p.gain, w, ch, 'Gain')];
            case 'lookup'                 % [n; interpolation; extrapolation; x; y]
                x = double(p.BreakpointsData(:));
                y = double(p.TableData(:));
                if numel(x) ~= numel(y)
                    error('simulink:sim:tableIncoherente', ...
                          ['Le bloc ''%s'' porte %d abscisses et %d valeurs : ' ...
                           'il en faut autant.'], ch, numel(x), numel(y));
                end
                if numel(x) < 2
                    error('simulink:sim:tableIncoherente', ...
                          'La table de ''%s'' demande au moins deux points.', ch);
                end
                if any(diff(x) <= 0)
                    error('Simulink:blocks:LookupBreakpointsNotMonotonic', ...
                          ['Les abscisses de la table de ''%s'' doivent etre strictement ' ...
                           'croissantes.'], ch);
                end
                interpolation = find(strcmp(p.InterpMethod, {'Linear point-slope', ...
                                                             'Flat', 'Nearest'}));
                if isempty(interpolation)
                    interpolation = 1;   % « Linear », l'ancien nom de Simulink
                end
                seg = [numel(x); interpolation; 1 + strcmp(p.ExtrapMethod, 'Linear'); x; y];
            case 'lookup2d'               % [nr; ns; r; s; table(:)]
                r = double(p.BreakpointsForDimension1(:));
                s = double(p.BreakpointsForDimension2(:));
                T = double(p.Table);
                if ~isequal(size(T), [numel(r), numel(s)])
                    error('simulink:sim:tableIncoherente', ...
                          ['La table de ''%s'' est de taille %s ; ses abscisses en ' ...
                           'demandent %s.'], ch, mat2str(size(T)), mat2str([numel(r), numel(s)]));
                end
                if numel(r) < 2 || numel(s) < 2 || any(diff(r) <= 0) || any(diff(s) <= 0)
                    error('Simulink:blocks:LookupBreakpointsNotMonotonic', ...
                          ['Les abscisses de la table de ''%s'' doivent etre au moins deux ' ...
                           'par dimension, et strictement croissantes.'], ch);
                end
                seg = [numel(r); numel(s); r; s; T(:)];
            % --- logique ---
            case 'logic'
                sub = find(strcmp(p.Operator, {'AND', 'OR', 'NAND', 'NOR', 'XOR', 'NXOR', 'NOT'}));
                seg = c.nIn(k);
            case 'relational'
                sub = find(strcmp(p.Operator, {'==', '~=', '<', '<=', '>=', '>'}));
            case 'comparetoconstant'
                sub = find(strcmp(p.relop, {'==', '~=', '<', '<=', '>=', '>'}));
                seg = etendre(p.const, w, ch, 'Constant');
            case 'comparetozero'
                sub = find(strcmp(p.relop, {'==', '~=', '<', '<=', '>=', '>'}));
            case {'detectchange', 'detectincrease', 'detectdecrease'}
                z0 = etendre(p.vinit, w, ch, 'InitialCondition');
            % --- aiguillage ---
            case 'switch'                 % [n; seuil]
                sub = find(strcmp(p.Criteria, {'u2 >= Threshold', 'u2 > Threshold', 'u2 ~= 0'}));
                seuil = double(p.Threshold(:));
                seg = [numel(seuil); seuil];
            case 'multiportswitch'        % [nombre de donnees; base zero]
                seg = [c.nIn(k) - 1; strcmp(p.DataPortOrder, 'Zero-based contiguous')];
            case 'demux'                  % [debut; fin] par sortie
                bornes = zeros(2 * c.nOut(k), 1);
                debut = 1;
                for q = 1:c.nOut(k)
                    L = c.largeur(c.portDebut(k) + q - 1);
                    bornes(2 * q - 1:2 * q) = [debut; debut + L - 1];
                    debut = debut + L;
                end
                seg = bornes;
            case 'busselector'            % comme un Demux, ou comme un Selector
                choix = elementsChoisis(c, k);
                if strcmp(p.OutputAsBus, 'on')
                    indices = [];
                    for q = 1:numel(choix)
                        indices = [indices, choix(q).debut:choix(q).debut + ...
                                   choix(q).largeur - 1]; %#ok<AGROW>
                    end
                    c.code(k) = 64;
                    seg = [numel(indices); indices(:)];
                else
                    bornes = zeros(2 * numel(choix), 1);
                    for q = 1:numel(choix)
                        bornes(2 * q - 1:2 * q) = [choix(q).debut; ...
                                                   choix(q).debut + choix(q).largeur - 1];
                    end
                    seg = bornes;
                end
            case 'datatypeconversion'     % [type; arrondi; saturation]
                types = {'Inherit: Inherit via back propagation', 'double', 'single', ...
                         'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'boolean'};
                arrondis = {'Zero', 'Nearest', 'Round', 'Floor', 'Ceiling', 'Convergent', ...
                            'Simplest'};
                seg = [find(strcmp(types, p.OutDataTypeStr)); ...
                       find(strcmp(arrondis, p.RndMeth)); ...
                       strcmp(p.SaturateOnIntegerOverflow, 'on')];
            case 'selector'               % [n; indices]
                indices = double(p.Indices(:));
                seg = [numel(indices); indices];
            case 'concatenate'            % [dimension; n; dimensions des entrees]
                sub = 1 + strcmp(p.Mode, 'Multidimensional array');
                d = zeros(2 * c.nIn(k), 1);
                for j = 1:c.nIn(k)
                    d(2 * j - 1:2 * j) = c.inDims{k}{j}(:);
                end
                seg = [double(p.ConcatenateDimension); c.nIn(k); d];
            case 'signalconversion'
                seg = c.nIn(k);
            % --- continu ---
            case 'integrator'             % [borne; haut; bas]
                x0 = etendre(p.InitialCondition, w, ch, 'InitialCondition');
                haut = etendre(p.UpperSaturationLimit, w, ch, 'UpperSaturationLimit');
                bas = etendre(p.LowerSaturationLimit, w, ch, 'LowerSaturationLimit');
                borne = strcmp(p.LimitOutput, 'on');
                if borne && any(bas > haut)
                    error('Simulink:blocks:IntegratorLimits', ...
                          'La borne basse de ''%s'' depasse sa borne haute.', ch);
                end
                if borne
                    x0 = min(max(x0, bas), haut);
                end
                c = ajouterEtat(c, k, x0);
                seg = [borne; haut; bas];
            case 'derivative'             % Z : [parti; t; u]
                z0 = [0; tDebut; zeros(largeurEntree(c, k, 1), 1)];
            case {'transferfcn', 'zeropole', 'statespace'}   % [nx; ny; nu; A; B; C; D]
                switch c.types{k}
                    case 'transferfcn'
                        [num, den] = transmittance(p.Numerator, p.Denominator, ch);
                        [A, B, C, D] = tf2ss(num, den);
                        x0 = zeros(size(A, 1), 1);
                    case 'zeropole'
                        lesZeros = double(p.Zeros(:));
                        lesPoles = double(p.Poles(:));
                        if numel(lesZeros) > numel(lesPoles)
                            error('Simulink:blocks:TransferFcnImproper', ...
                                  ['''%s'' porte plus de zeros que de poles : elle n''est ' ...
                                   'pas propre.'], ch);
                        end
                        [A, B, C, D] = zp2ss(lesZeros, lesPoles, double(p.Gain));
                        x0 = zeros(size(A, 1), 1);
                    otherwise
                        [A, B, C, D] = matricesEtat(p, ch);
                        x0 = double(p.X0(:));
                        if isempty(x0)
                            x0 = zeros(size(A, 1), 1);
                        elseif numel(x0) == 1 && size(A, 1) > 1
                            x0 = repmat(x0, size(A, 1), 1);
                        elseif numel(x0) ~= size(A, 1)
                            error('Simulink:blocks:StateSpaceX0Dimension', ...
                                  ['La condition initiale de ''%s'' porte %d valeur(s) pour ' ...
                                   '%d etat(s).'], ch, numel(x0), size(A, 1));
                        end
                end
                c = ajouterEtat(c, k, x0);
                seg = matricesSegment(A, B, C, D);
            case 'transportdelay'         % [retard; longueur; sortie initiale]  Z : [n; tampon]
                if p.DelayTime < 0
                    error('simulink:sim:retardNegatif', ...
                          'Le bloc ''%s'' demande un retard negatif.', ch);
                end
                if c.variable
                    % À pas variable, le tampon garde les instants avec les
                    % valeurs, et grandit au besoin : il vit hors de Z, dans
                    % les tampons du simulateur. Sa longueur est la taille
                    % initiale, BufferSize.
                    longueur = max(16, round(double(p.BufferSize)));
                    seg = [p.DelayTime; longueur; ...
                           etendre(p.InitialOutput, w, ch, 'InitialOutput')];
                else
                    longueur = ceil(p.DelayTime / pas - 1e-9) + 2;
                    seg = [p.DelayTime; longueur; ...
                           etendre(p.InitialOutput, w, ch, 'InitialOutput')];
                    z0 = [0; zeros(w * longueur, 1)];
                end
            case 'pidcontroller'          % [P; I; D; N], w chacun
                N = etendre(p.N, w, ch, 'N');
                if any(N <= 0)
                    error('simulink:sim:filtreDerive', ...
                          ['Le bloc ''%s'' demande un coefficient de filtre N ' ...
                           'strictement positif : une derivee non filtree ne ' ...
                           's''integre pas.'], ch);
                end
                xi = etendre(p.InitialConditionForIntegrator, w, ch, ...
                             'InitialConditionForIntegrator');
                xd = etendre(p.InitialConditionForFilter, w, ch, 'InitialConditionForFilter');
                c = ajouterEtat(c, k, [xi; xd]);
                seg = [etendre(p.P, w, ch, 'P'); etendre(p.I, w, ch, 'I'); ...
                       etendre(p.D, w, ch, 'D'); N];
            % --- discret ---
            case 'delay'                  % [L]  Z : [tete; tampon w x L]
                L = double(p.DelayLength);
                if ~(isscalar(L) && L >= 0 && L == round(L))
                    error('Simulink:Parameters:InvalidValue', ...
                          'La longueur de retard de ''%s'' est un entier positif ou nul.', ch);
                end
                seg = L;
                if L > 0
                    ci = double(p.InitialCondition);
                    if numel(ci) == w * L && L > 1
                        tampon = reshape(ci, w, L);
                    else
                        tampon = repmat(etendre(ci, w, ch, 'InitialCondition'), 1, L);
                    end
                    z0 = [1; tampon(:)];
                end
            case 'memory'
                z0 = etendre(p.InitialCondition, w, ch, 'InitialCondition');
            case 'discreteintegrator'     % [K T; methode]
                methode = find(strcmp(p.IntegratorMethod, ...
                                      {'ForwardEuler', 'BackwardEuler', 'Trapezoidal'}));
                seg = [double(p.Gain) * c.cadence(k); methode];
                z0 = etendre(p.InitialCondition, w, ch, 'InitialCondition');
            case {'discretetransferfcn', 'discretefilter'}   % [m; b; a]
                [b, a] = filtreDiscret(p.Numerator, p.Denominator, ...
                                       strcmp(c.types{k}, 'discretetransferfcn'), ch);
                seg = [numel(a) - 1; b(:); a(:)];
                z0 = zeros(numel(a) - 1, 1);
            case 'discretestatespace'     % [nx; ny; nu; A; B; C; D]  Z : x
                [A, B, C, D] = matricesEtat(p, ch);
                x0 = double(p.X0(:));
                if isempty(x0)
                    x0 = zeros(size(A, 1), 1);
                elseif numel(x0) == 1 && size(A, 1) > 1
                    x0 = repmat(x0, size(A, 1), 1);
                elseif numel(x0) ~= size(A, 1)
                    error('Simulink:blocks:StateSpaceX0Dimension', ...
                          'La condition initiale de ''%s'' porte %d valeur(s) pour %d etat(s).', ...
                          ch, numel(x0), size(A, 1));
                end
                seg = matricesSegment(A, B, C, D);
                z0 = x0;
            % --- sorties ---
            case 'toworkspace'
                if ~isvarname(char(p.VariableName))
                    error('simulink:sim:nomVariable', ...
                          ['Le bloc ''%s'' veut ecrire dans ''%s'', qui n''est ' ...
                           'pas un nom de variable.'], ch, char(p.VariableName));
                end
            case 'assertion'              % [active; arreter]
                seg = [strcmp(p.Enabled, 'on'); strcmp(p.StopWhenAssertionFail, 'on')];
            % --- sous-systèmes conditionnels ---
            case 'garde'                  % [enable; front; action; remise; largeur du front]
                % Z : [amorcée; active au pas d'avant; front d'avant]
                fronts = struct('none', 0, 'rising', 1, 'falling', 2, 'either', 3);
                largeurFront = 0;
                if ~strcmp(p.Trigger, 'none')
                    largeurFront = largeurEntree(c, k, 1 + (p.Enable ~= 0));
                end
                seg = [p.Enable ~= 0; fronts.(p.Trigger); p.Action ~= 0; p.Reset ~= 0; ...
                       largeurFront];
                z0 = [0; 0; zeros(largeurFront, 1)];
            case 'if'                     % [entrées; conditions; sinon]
                [c.objets{k}, nCond] = conditionsSi(p, c.nIn(k), ch, c, k);
                seg = [c.nIn(k); nCond; strcmpi(p.ShowElse, 'on')];
            case 'switchcase'             % [cas; défaut]
                c.objets{k} = casDe(p.CaseConditions, ch);
                seg = [numel(c.objets{k}); strcmpi(p.ShowDefaultCase, 'on')];
            case {'fcn', 'interpretedmatlabfunction'}   % [largeur d'entrée]  poignée dans objets
                c.objets{k} = c.fonctions{k}.h;
                verifierCode(c, k, w);
                seg = largeurEntree(c, k, 1);
            case 'chart'                  % [entrées; sorties]  machine dans objets
                c.objets{k} = c.fonctions{k};
                seg = [c.nIn(k); c.nOut(k)];
            case 'matlabfunction'         % [entrées; sorties]  poignée dans objets
                c.objets{k} = c.fonctions{k}.h;
                seg = [c.nIn(k); c.nOut(k)];
            case 'sfunction'              % [continus; discrets; sorties; entrées]
                T0 = c.fonctions{k};
                nc = T0.tailles(1);
                nd = T0.tailles(2);
                c.objets{k} = struct('f', T0.h, 'p', {T0.parametres});
                c = ajouterEtat(c, k, T0.x0(1:nc));
                z0 = T0.x0(nc + 1:nc + nd);
                seg = [nc; nd; w * (c.nOut(k) > 0); T0.tailles(4)];
            case 'merge'                  % [entrées; valeur initiale (w); garde de chaque source]
                seg = [c.nIn(k); etendre(p.InitialOutput, w, ch, 'InitialOutput'); ...
                       gardesDesSources(c, k)];
        end
        c.seg{k} = double(seg(:));
        c.sub(k) = sub;
        c.z0{k} = double(z0(:));
    end
end

% Une représentation d'état en un segment : ses tailles, puis ses quatre
% matrices par colonnes.
function seg = matricesSegment(A, B, C, D)
    nx = size(A, 1);
    ny = size(C, 1);
    nu = size(B, 2);
    if nx == 0
        ny = size(D, 1);
        nu = size(D, 2);
    end
    if isscalar(D) && (ny ~= 1 || nu ~= 1)
        D = repmat(D, ny, nu);
    end
    seg = [nx; ny; nu; A(:); B(:); C(:); D(:)];
end

function c = ajouterEtat(c, k, x0)
    if isempty(x0)
        return   % une transmittance réduite à un gain n'a pas d'état
    end
    debut = numel(c.x0) + 1;
    c.x0 = [c.x0; x0(:)];
    c.xA(k) = debut;
    c.xB(k) = numel(c.x0);
end

function w = sortieLargeur(c, k)
    if c.nOut(k) >= 1
        w = c.largeur(c.portDebut(k));
    elseif c.nIn(k) >= 1
        w = largeurEntree(c, k, 1);
    else
        w = 1;
    end
end

function w = largeurEntree(c, k, j)
    e = c.entrees{k};
    if j > numel(e) || e(j) == 0
        w = 1;
    else
        w = c.largeur(e(j));
    end
end

% Une valeur donnée scalaire s'étend à toute la largeur du signal ; donnée
% vecteur, elle doit en avoir la largeur.
function v = etendre(v, w, chemin, nom)
    v = double(v(:));
    if numel(v) == 1
        v = repmat(v, w, 1);
    elseif numel(v) ~= w
        error('Simulink:Engine:DimensionMismatch', ...
              ['Le parametre %s de ''%s'' porte %d valeur(s) pour un signal de ' ...
               'largeur %d.'], nom, chemin, numel(v), w);
    end
end

% Les signes d'une sommation ou d'un produit, en +1 et -1 : « +- » donne
% [1 -1], « **/ » donne [1 1 -1].
function s = signesDe(v, admis, n)
    if isnumeric(v)
        s = ones(1, n);
        return
    end
    texte = char(v);
    valeur = str2double(texte);
    if ~isnan(valeur) && all(ismember(texte, '0123456789 '))
        s = ones(1, n);
        return
    end
    texte = texte(ismember(texte, admis));
    s = ones(1, numel(texte));
    s(texte == admis(2)) = -1;
end

% === ordre de calcul et boucles algébriques ===================================
%
% Le graphe des dépendances va d'un bloc à ceux qui lisent sa sortie à
% l'instant même. Ses composantes fortement connexes sont les boucles
% algébriques ; hors d'elles, un tri topologique ordonne le calcul. Chaque
% boucle est coupée en quelques blocs, dont les sorties deviennent les
% inconnues qu'une méthode de Newton ajuste à chaque pas.
function c = ordonner(c)
    n = c.n;
    succ = cell(1, n);
    for k = 1:n
        succ{k} = [];
    end
    for k = 1:n
        if ~c.direct(k)
            continue
        end
        e = c.entrees{k};
        for j = 1:numel(e)
            if e(j) > 0
                a = c.proprio(e(j));
                succ{a}(end + 1) = k;
            end
        end
        % Un bloc gardé lit la garde de son sous-système : elle calcule
        % avant lui. Un Merge lit celles de ses sources.
        if c.garde(k) > 0
            succ{c.garde(k)}(end + 1) = k;
        end
        if strcmp(c.types{k}, 'merge')
            for g = unique(c.seg{k}(end - c.nIn(k) + 1:end)).'
                if g > 0
                    succ{g}(end + 1) = k;
                end
            end
        end
    end
    composantes = tarjan(succ, n);
    % Tarjan rend les composantes dans l'ordre topologique inverse.
    composantes = composantes(end:-1:1);
    c.etapes = {};
    c.boucles = {};
    courant = [];
    for i = 1:numel(composantes)
        comp = composantes{i};
        estBoucle = numel(comp) > 1 || any(succ{comp(1)} == comp(1));
        if ~estBoucle
            courant(end + 1) = comp(1); %#ok<AGROW>
            continue
        end
        if ~isempty(courant)
            c.etapes{end + 1} = courant;
            courant = [];
        end
        boucle = decouper(c, comp, succ);
        c.boucles{end + 1} = boucle;
        c.etapes{end + 1} = boucle;
    end
    if ~isempty(courant)
        c.etapes{end + 1} = courant;
    end
end

function composantes = tarjan(succ, n)
    indice = zeros(1, n);
    bas = zeros(1, n);
    surPile = false(1, n);
    pile = zeros(1, n);
    sommet = 0;
    compteur = 0;
    composantes = {};
    % Une version itérative : la récursion profonde d'un grand modèle
    % épuiserait la pile de l'interpréteur.
    for depart = 1:n
        if indice(depart) ~= 0
            continue
        end
        travail = [depart, 1];
        compteur = compteur + 1;
        indice(depart) = compteur;
        bas(depart) = compteur;
        sommet = sommet + 1;
        pile(sommet) = depart;
        surPile(depart) = true;
        while ~isempty(travail)
            v = travail(end, 1);
            i = travail(end, 2);
            s = succ{v};
            if i <= numel(s)
                travail(end, 2) = i + 1;
                w = s(i);
                if indice(w) == 0
                    compteur = compteur + 1;
                    indice(w) = compteur;
                    bas(w) = compteur;
                    sommet = sommet + 1;
                    pile(sommet) = w;
                    surPile(w) = true;
                    travail(end + 1, :) = [w, 1]; %#ok<AGROW>
                elseif surPile(w)
                    bas(v) = min(bas(v), indice(w));
                end
            else
                if bas(v) == indice(v)
                    comp = [];
                    while true
                        w = pile(sommet);
                        sommet = sommet - 1;
                        surPile(w) = false;
                        comp(end + 1) = w; %#ok<AGROW>
                        if w == v
                            break
                        end
                    end
                    composantes{end + 1} = sort(comp); %#ok<AGROW>
                end
                travail(end, :) = [];
                if ~isempty(travail)
                    u = travail(end, 1);
                    bas(u) = min(bas(u), bas(v));
                end
            end
        end
    end
end

% Couper une boucle : on retire des blocs jusqu'à ce que ce qui reste soit
% sans cycle. Chaque fois, celui qui a le plus de voisins dans la boucle —
% c'est lui qui en coupe le plus. Les sorties des blocs retirés sont les
% inconnues ; le calcul range les autres dans l'ordre, puis les retirés.
function boucle = decouper(c, comp, succ)
    dans = false(1, c.n);
    dans(comp) = true;
    dechires = [];
    restants = comp;
    for tour = 1:numel(comp)
        sousSucc = cell(1, c.n);
        for v = restants
            s = succ{v};
            sousSucc{v} = s(dans(s) & ~ismember(s, dechires));
        end
        cyclique = [];
        for v = restants
            for w = sousSucc{v}
                if w == v
                    cyclique(end + 1) = v; %#ok<AGROW>
                end
            end
        end
        sousComp = tarjan(sousSucc, c.n);
        for i = 1:numel(sousComp)
            sc = sousComp{i};
            sc = sc(ismember(sc, restants));
            if numel(sc) > 1
                cyclique = [cyclique, sc]; %#ok<AGROW>
            end
        end
        cyclique = unique(cyclique);
        if isempty(cyclique)
            break
        end
        meilleur = cyclique(1);
        score = -1;
        for v = cyclique
            sortants = sum(ismember(sousSucc{v}, cyclique));
            entrants = 0;
            for w = cyclique
                entrants = entrants + sum(sousSucc{w} == v);
            end
            if sortants * entrants > score
                score = sortants * entrants;
                meilleur = v;
            end
        end
        dechires(end + 1) = meilleur; %#ok<AGROW>
        restants(restants == meilleur) = [];
    end
    % L'ordre des blocs qui restent, les sorties des retirés tenues pour
    % connues.
    sousSucc = cell(1, c.n);
    for v = restants
        s = succ{v};
        sousSucc{v} = s(ismember(s, restants));
    end
    ordreRestants = [];
    comps = tarjan(sousSucc, c.n);
    comps = comps(end:-1:1);
    for i = 1:numel(comps)
        sc = comps{i};
        sc = sc(ismember(sc, restants));
        ordreRestants = [ordreRestants, sc]; %#ok<AGROW>
    end
    zA = [];
    zB = [];
    for d = dechires
        for q = 1:c.nOut(d)
            gp = c.portDebut(d) + q - 1;
            zA(end + 1) = c.vA(gp); %#ok<AGROW>
            zB(end + 1) = c.vB(gp); %#ok<AGROW>
        end
    end
    indices = [];
    for i = 1:numel(zA)
        indices = [indices, zA(i):zB(i)]; %#ok<AGROW>
    end
    boucle = struct('blocs', comp, 'ordre', [ordreRestants, dechires], ...
                    'dechires', dechires, 'z', indices);
end

% === blocs de code ============================================================

function code = preparerCode(c, k)
    code = [];
    p = c.p{k};
    ch = c.chemins{k};
    switch c.types{k}
        case 'fcn'
            code.h = matlibre_sl_fonction('expression', p.Expr, ch);
        case 'interpretedmatlabfunction'
            code.h = matlibre_sl_fonction('expression', p.MATLABFcn, ch);
        case 'chart'
            code = preparerGraphe(p, ch);
        case 'matlabfunction'
            code.h = matlibre_sl_fonction('installer', p.Script, ch);
            code.persistante = ~isempty(regexp(char(p.Script), '(^|\n)\s*persistent\s', 'once'));
        case 'sfunction'
            parametres = p.Parameters;
            if ischar(parametres) || isstring(parametres)
                try
                    parametres = evalin('base', ['{' char(parametres) '}']);
                catch err
                    error('Simulink:blocks:SFunctionParameters', ...
                          'Les parametres ''%s'' du bloc ''%s'' ne s''evaluent pas : %s', ...
                          char(p.Parameters), ch, err.message);
                end
            elseif ~iscell(parametres)
                parametres = {parametres};
            end
            [code.tailles, code.x0, code.ts] = matlibre_sl_fonction('sfonction', ...
                                                                    p.FunctionName, parametres, ch);
            code.h = str2func(char(p.FunctionName));
            code.parametres = parametres;
            if any(code.tailles(1:2) < 0)
                error('Simulink:blocks:SFunctionSizes', ...
                      'La S-fonction du bloc ''%s'' annonce un nombre d''etats negatif.', ch);
            end
    end
end

% Un diagramme Stateflow : la machine bâtie par SFCHART, les champs du
% contexte qu'il rend — « etat », le rang de l'état actif —, et leurs
% dimensions, lues au démarrage de la machine.
function code = preparerGraphe(p, chemin)
    machine = p.Chart;
    if ~isstruct(machine) || ~isfield(machine, 'etats') || ~isfield(machine, 'transitions')
        error('Simulink:blocks:ChartMachineMissing', ...
              ['Le bloc Chart ''%s'' ne porte pas de machine : donnez-lui celle que ' ...
               'batissent SFCHART, SFSTATE et SFTRANSITION, par son parametre Chart.'], ...
              chemin);
    end
    if isempty(machine.etats)
        error('Simulink:blocks:ChartNoState', 'La machine du bloc ''%s'' n''a pas d''etat.', ...
              chemin);
    end
    sorties = p.Outputs;
    if ischar(sorties) || isstring(sorties)
        sorties = cellstr(sorties);
    end
    contexte = p.InitialContext;
    if isempty(contexte)
        contexte = struct();
    end
    try
        [courant, contexte] = sfstep(machine, '', contexte, []);
    catch err
        error('Simulink:blocks:ChartError', ...
              'La machine du bloc ''%s'' echoue en entrant dans son etat initial : %s', ...
              chemin, err.message);
    end
    code = struct('machine', machine, 'sorties', {sorties}, 'contexte', contexte, ...
                  'initial', p.InitialContext);
    code.noms = cellfun(@(e) e.nom, machine.etats, 'UniformOutput', false);
    code.dims = cell(1, numel(sorties));
    for q = 1:numel(sorties)
        if strcmp(sorties{q}, 'etat')
            code.dims{q} = [1 1];
            continue
        end
        if ~isfield(contexte, sorties{q})
            error('Simulink:blocks:ChartOutputMissing', ...
                  ['La sortie ''%s'' du bloc Chart ''%s'' n''est pas un champ du contexte ' ...
                   'de sa machine ; donnez-le dans InitialContext, ou par une action ' ...
                   'd''entree de l''etat initial ''%s''.'], sorties{q}, chemin, courant);
        end
        v = contexte.(sorties{q});
        if ~(isnumeric(v) || islogical(v)) || isempty(v) || ndims(v) > 2
            error('Simulink:blocks:ChartOutputType', ...
                  'La sortie ''%s'' du bloc Chart ''%s'' n''est pas un tableau de nombres.', ...
                  sorties{q}, chemin);
        end
        code.dims{q} = size(v);
    end
end

% Une expression de Fcn ou d'Interpreted MATLAB Function s'essaie sur des
% zéros : ce qu'elle rend doit avoir la largeur de la sortie.
function verifierCode(c, k, w)
    u = zeros(max(1, largeurEntree(c, k, 1)), 1);
    try
        y = c.objets{k}(u);
    catch err
        error('Simulink:blocks:FcnEvaluationError', ...
              'Le bloc ''%s'' echoue sur une entree de %d zero(s) : %s', c.chemins{k}, ...
              numel(u), err.message);
    end
    if ~(isnumeric(y) || islogical(y)) || numel(y) ~= w
        if strcmp(c.types{k}, 'fcn')
            detail = 'un Fcn rend un scalaire';
        else
            detail = sprintf('OutputDimensions en annonce %d', w);
        end
        error('Simulink:blocks:FcnOutputDimension', ...
              'Le bloc ''%s'' rend %d valeur(s) : %s.', c.chemins{k}, numel(y), detail);
    end
end

% Les dimensions des sorties d'une MATLAB Function : un appel d'essai sur
% des zéros, puis ses variables persistantes remises à zéro.
function s = dimsFonction(c, k, dE)
    h = c.fonctions{k}.h;
    u = cell(1, c.nIn(k));
    for j = 1:c.nIn(k)
        u{j} = zeros(dE{j});
    end
    sorties = cell(1, c.nOut(k));
    try
        [sorties{:}] = h(u{:});
    catch err
        error('Simulink:blocks:MATLABFunctionError', ...
              'La fonction du bloc ''%s'' echoue sur des entrees nulles : %s', ...
              c.chemins{k}, err.message);
    end
    clear(func2str(h));
    s = cell(1, c.nOut(k));
    for q = 1:c.nOut(k)
        if ~(isnumeric(sorties{q}) || islogical(sorties{q})) || ndims(sorties{q}) > 2
            error('Simulink:blocks:MATLABFunctionOutput', ...
                  ['La sortie %d du bloc ''%s'' n''est pas un tableau de nombres a deux ' ...
                   'dimensions.'], q, c.chemins{k});
        end
        d = size(sorties{q});
        if prod(d) == 0
            error('Simulink:blocks:MATLABFunctionOutput', ...
                  'La sortie %d du bloc ''%s'' est vide.', q, c.chemins{k});
        end
        s{q} = d;
    end
end

% === bus =======================================================================
%
% La forme d'un bus : ses éléments, chacun avec son nom, ses dimensions, sa
% place dans le vecteur qui les porte bout à bout, et, s'il est lui-même
% un bus, sa forme. On la lit en remontant du port jusqu'au Bus Creator,
% à travers les passe-plats — un sous-système déplié, un Goto et son
% From.
function forme = formeBus(c, gp)
    forme = [];
    for pas = 1:c.n
        if gp == 0
            return
        end
        a = c.proprio(gp);
        switch c.types{a}
            case 'buscreator'
                break
            case {'signalconversion', 'from'}
                gp = c.entrees{a}(max(1, min(c.rang(gp), c.nIn(a))));
            otherwise
                return
        end
    end
    noms = nomsDuBus(c.p{a}.Inputs, c.nIn(a));
    forme = struct('nom', {}, 'dims', {}, 'largeur', {}, 'debut', {}, 'sous', {});
    debut = 1;
    for j = 1:c.nIn(a)
        source = c.entrees{a}(j);
        d = [1 1];
        if source > 0
            if ~isfield(c, 'dimsCourants') || isempty(c.dimsCourants{source})
                forme = [];
                return
            end
            d = c.dimsCourants{source};
        end
        w = prod(d);
        forme(end + 1) = struct('nom', noms{j}, 'dims', d, 'largeur', w, 'debut', debut, ...
                                'sous', {formeBus(c, source)}); %#ok<AGROW>
        debut = debut + w;
    end
end

function noms = nomsDuBus(entrees, n)
    texte = strtrim(char(num2str(entrees)));
    if isnan(str2double(texte))
        noms = strtrim(strsplit(texte, ','));
    else
        noms = arrayfun(@(j) sprintf('signal%d', j), 1:n, 'UniformOutput', false);
    end
end

% Les éléments qu'un Bus Selector reprend, dans l'ordre de OutputSignals ;
% « mesures.vitesse » descend dans un bus emboîté.
function choix = elementsChoisis(c, k)
    choix = [];
    forme = formeBus(c, c.entrees{k}(1));
    if isempty(forme)
        if c.entrees{k}(1) == 0 || (isfield(c, 'dimsCourants') && ...
                                    ~isempty(c.dimsCourants{c.entrees{k}(1)}))
            error('Simulink:Bus:SelectorInputNotBus', ...
                  ['L''entree du Bus Selector ''%s'' n''est pas un bus : il lui faut le ' ...
                   'signal d''un Bus Creator.'], c.chemins{k});
        end
        return
    end
    demandes = strtrim(strsplit(char(c.p{k}.OutputSignals), ','));
    choix = struct('nom', {}, 'dims', {}, 'largeur', {}, 'debut', {});
    for q = 1:numel(demandes)
        parties = strsplit(demandes{q}, '.');
        niveau = forme;
        decalage = 0;
        element = [];
        for i = 1:numel(parties)
            rang = find(strcmp({niveau.nom}, parties{i}), 1);
            if isempty(rang)
                error('Simulink:Bus:SelectorElementNotFound', ...
                      ['Le Bus Selector ''%s'' demande ''%s'', que le bus ne porte pas ; ' ...
                       'ses elements sont : %s.'], c.chemins{k}, demandes{q}, ...
                      strjoin({niveau.nom}, ', '));
            end
            element = niveau(rang);
            decalage = decalage + element.debut - 1;
            if i < numel(parties)
                if isempty(element.sous)
                    error('Simulink:Bus:SelectorElementNotFound', ...
                          ['Le Bus Selector ''%s'' demande ''%s'', mais ''%s'' n''est ' ...
                           'pas un bus.'], c.chemins{k}, demandes{q}, parties{i});
                end
                niveau = element.sous;
            end
        end
        choix(end + 1) = struct('nom', demandes{q}, 'dims', element.dims, ...
                                'largeur', element.largeur, 'debut', decalage + 1); %#ok<AGROW>
    end
end

% === sous-systèmes conditionnels ================================================
%
% Les conditions d'un bloc If deviennent des fonctions de u1, u2... : la
% première qui vaut vrai choisit sa sortie. Chacune est essayée à la
% compilation sur des zéros, pour qu'une faute de frappe se dise en
% nommant le bloc, non au milieu de la simulation.
function [conditions, nCond] = conditionsSi(p, nIn, chemin, c, k)
    textes = [{char(p.IfExpression)}, expressionsSinonSi(p.ElseIfExpressions)];
    nCond = numel(textes);
    arguments = strjoin(arrayfun(@(j) sprintf('u%d', j), 1:nIn, 'UniformOutput', false), ',');
    essai = cell(1, nIn);
    for j = 1:nIn
        essai{j} = zeros(max(1, largeurEntree(c, k, j)), 1);
    end
    conditions = cell(1, nCond);
    for i = 1:nCond
        if isempty(strtrim(textes{i}))
            error('Simulink:blocks:IfExpressionEmpty', ...
                  'La condition %d du bloc If ''%s'' est vide.', i, chemin);
        end
        try
            conditions{i} = str2func(sprintf('@(%s) %s', arguments, textes{i}));
            r = conditions{i}(essai{:});
            if ~(isnumeric(r) || islogical(r)) || numel(r) ~= 1
                error('Simulink:blocks:IfExpressionNotScalar', 'pas scalaire');
            end
        catch err
            error('Simulink:blocks:IfExpressionInvalid', ...
                  ['La condition ''%s'' du bloc If ''%s'' ne s''evalue pas en un booleen ' ...
                   'scalaire de ses entrees u1 a u%d : %s'], textes{i}, chemin, nIn, ...
                  err.message);
        end
    end
end

function liste = expressionsSinonSi(texte)
    liste = {};
    texte = char(texte);
    if isempty(strtrim(texte))
        return
    end
    profondeur = 0;
    debut = 1;
    for i = 1:numel(texte)
        switch texte(i)
            case {'(', '[', '{'}
                profondeur = profondeur + 1;
            case {')', ']', '}'}
                profondeur = profondeur - 1;
            case ','
                if profondeur == 0
                    liste{end + 1} = strtrim(texte(debut:i - 1)); %#ok<AGROW>
                    debut = i + 1;
                end
        end
    end
    liste{end + 1} = strtrim(texte(debut:end));
end

% Les cas d'un Switch Case : une cellule de valeurs entières, écrite comme
% dans Simulink, « {1, [2 3], 7} ».
function cas = casDe(texte, chemin)
    cas = texte;
    if ischar(cas) || isstring(cas)
        try
            cas = evalin('base', char(cas));
        catch err
            error('Simulink:blocks:SwitchCaseConditionsInvalid', ...
                  'Les cas de ''%s'' ne s''evaluent pas : %s', chemin, err.message);
        end
    end
    if isnumeric(cas)
        cas = num2cell(cas);
    end
    if ~iscell(cas) || isempty(cas) || ...
       ~all(cellfun(@(v) isnumeric(v) && ~isempty(v) && all(v(:) == round(v(:))), cas))
        error('Simulink:blocks:SwitchCaseConditionsInvalid', ...
              ['Les cas de ''%s'' sont une cellule de valeurs entieres, comme ' ...
               '{1, [2 3], 7}.'], chemin);
    end
    cas = cellfun(@(v) double(v(:)), cas, 'UniformOutput', false);
end

% Pour chaque entrée d'un Merge, la garde du sous-système d'où vient son
% signal — en remontant les passe-plats —, ou 0 s'il n'en vient d'aucun.
function gardes = gardesDesSources(c, k)
    gardes = zeros(c.nIn(k), 1);
    for j = 1:c.nIn(k)
        gp = c.entrees{k}(j);
        for pas = 1:c.n
            if gp == 0
                break
            end
            a = c.proprio(gp);
            if c.garde(a) > 0
                gardes(j) = c.garde(a);
                break
            end
            if ~strcmp(c.types{a}, 'signalconversion')
                break
            end
            gp = c.entrees{a}(c.rang(gp));
        end
    end
end

% === passages par zéro ========================================================
%
% Les blocs dont la sortie casse quand un signal franchit un seuil : leur
% entrée, comparée au seuil, est surveillée par le solveur à pas
% variable, qui localise l'instant du franchissement au lieu de le
% sauter. C'est la liste de Simulink, et son réglage : ZeroCrossControl
% vaut UseLocalSettings (le paramètre ZeroCross de chaque bloc décide),
% EnableAll ou DisableAll.
function zc = passagesParZero(c)
    zc = false(1, c.n);
    capables = {'abs', 'sign', 'comparetozero', 'comparetoconstant', 'relational', ...
                'minmax', 'saturation', 'deadzone', 'relay', 'hitcrossing', 'switch', ...
                'integrator', 'backlash', 'coulombfriction', 'garde'};
    controle = 'UseLocalSettings';
    if isstruct(c.config) && isfield(c.config, 'ZeroCrossControl')
        controle = char(c.config.ZeroCrossControl);
    end
    if strcmpi(controle, 'DisableAll')
        return
    end
    for k = 1:c.n
        type = c.types{k};
        if ~any(strcmp(type, capables))
            continue
        end
        p = c.p{k};
        switch type
            case 'integrator'
                if c.seg{k}(1) == 0
                    continue   % sans bornes, rien ne casse
                end
            case 'minmax'
                if c.nIn(k) < 2
                    continue
                end
            case 'garde'
                if c.nIn(k) == 0 || p.Action ~= 0
                    continue   % une action se décide au pas majeur, par le If
                end
        end
        if strcmpi(controle, 'EnableAll')
            zc(k) = true;
        else
            zc(k) = ~isfield(p, 'ZeroCross') || strcmpi(char(p.ZeroCross), 'on');
        end
    end
end

% === diagnostics ===============================================================

function diagnostiquer(c)
    niveau = lower(char(c.config.UnconnectedInputMsg));
    if ~strcmp(niveau, 'none')
        for k = 1:c.n
            if strcmp(c.types{k}, 'from')
                continue
            end
            for j = find(c.entrees{k} == 0)
                signaler(niveau, 'Simulink:Engine:InputNotConnected', ...
                         ['Le port d''entree %d de ''%s'' n''est pas relie : il vaut ' ...
                          'zero.'], j, c.chemins{k});
            end
        end
    end
    niveau = lower(char(c.config.UnconnectedOutputMsg));
    if ~strcmp(niveau, 'none')
        lus = false(1, c.nPorts);
        for k = 1:c.n
            e = c.entrees{k};
            lus(e(e > 0)) = true;
        end
        for gp = find(~lus)
            k = c.proprio(gp);
            signaler(niveau, 'Simulink:Engine:OutputNotConnected', ...
                     'Le port de sortie %d de ''%s'' n''est relie a rien.', ...
                     c.rang(gp), c.chemins{k});
        end
    end
    niveau = lower(char(c.config.AlgebraicLoopMsg));
    if ~strcmp(niveau, 'none') && ~isempty(c.boucles)
        textes = cell(1, numel(c.boucles));
        for i = 1:numel(c.boucles)
            textes{i} = strjoin(c.chemins(c.boucles{i}.blocs), ', ');
        end
        signaler(niveau, 'Simulink:Engine:AlgebraicLoop', ...
                 ['Le modele ''%s'' contient %d boucle(s) algebrique(s) : %s. Elle(s) ' ...
                  'est (sont) resolue(s) a chaque pas par la methode de Newton ; le ' ...
                  'reglage AlgebraicLoopMsg du modele regle ce message.'], ...
                 c.nom, numel(c.boucles), strjoin(textes, ' ; '));
    end
end

function signaler(niveau, identifiant, format, varargin)
    if strcmp(niveau, 'error')
        error(identifiant, format, varargin{:});
    else
        warning(identifiant, format, varargin{:});
    end
end

% === l'espace de travail =======================================================

% Un bloc « depuis l'espace de travail » lit une variable de l'espace de
% base : une matrice [temps valeurs...], dont chaque colonne après la
% première est un élément du signal, ou la structure à temps que SIM
% journalise.
function [temps, valeurs] = lireSignalEspace(nomVariable, nomBloc)
    nomVariable = char(nomVariable);
    if isempty(nomVariable)
        error('simulink:sim:variableAbsente', ...
              ['Le bloc ''%s'' ne dit pas quelle variable lire : donnez-lui ' ...
               'un parametre VariableName.'], nomBloc);
    end
    if ~isvarname(nomVariable)
        donnees = matlibre_sl_expression(nomVariable, nomBloc, 'VariableName');
    elseif evalin('base', sprintf('exist(''%s'', ''var'')', nomVariable)) ~= 1
        error('simulink:sim:variableAbsente', ...
              ['Le bloc ''%s'' lit la variable ''%s'', qui n''existe pas dans ' ...
               'l''espace de travail de base.'], nomBloc, nomVariable);
    else
        donnees = evalin('base', nomVariable);
    end
    if isstruct(donnees) && isfield(donnees, 'time') && isfield(donnees, 'signals')
        temps = double(donnees.time(:));
        valeurs = double(donnees.signals(1).values);
        if isvector(valeurs)
            valeurs = valeurs(:);
        end
    elseif isnumeric(donnees) && ismatrix(donnees) && size(donnees, 2) >= 2 && ...
            (size(donnees, 1) >= 2 || size(donnees, 2) == 2)
        % Une seule ligne de plus de deux nombres serait ambiguë : un
        % instant et plusieurs valeurs, ou une suite de valeurs écrite en
        % ligne ? On la refuse plutôt que de deviner.
        temps = double(donnees(:, 1));
        valeurs = double(donnees(:, 2:end));
    else
        error('simulink:sim:signalMalForme', ...
              ['La variable ''%s'' que lit le bloc ''%s'' doit porter au moins deux ' ...
               'colonnes — le temps puis une valeur par element du signal — ou la ' ...
               'structure a temps que SIM journalise. Elle est de taille %s.'], ...
              nomVariable, nomBloc, mat2str(size(donnees)));
    end
    if numel(temps) ~= size(valeurs, 1)
        error('simulink:sim:signalMalForme', ...
              'La variable ''%s'' porte %d instants et %d valeurs.', ...
              nomVariable, numel(temps), size(valeurs, 1));
    end
end
