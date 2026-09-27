function varargout = matlibre_sl_physique(action, varargin)
%MATLIBRE_SL_PHYSIQUE Les réseaux électriques de Simscape dans un schéma.
%   [G,D,E,S] = MATLIBRE_SL_PHYSIQUE('ports',TYPE) rend les ports d'un
%   bloc physique : G ports physiques à gauche (LConn), D à droite (RConn),
%   E entrées et S sorties de signal. Un type qui n'est pas physique rend
%   des zéros, et OUI = MATLIBRE_SL_PHYSIQUE('est',TYPE) le dit.
%
%   MODELE = MATLIBRE_SL_PHYSIQUE('reseaux',MODELE) remplace chaque réseau
%   physique d'un modèle déplié par des blocs ordinaires. Les connexions
%   physiques (MODELE.connexions, une ligne [bloc, port, bloc, port], un
%   port +i pour LConn i, -i pour RConn i) font les nœuds ; les nœuds et
%   les blocs qu'ils relient font les réseaux. Chaque réseau doit avoir
%   un bloc Solver Configuration, et au moins une Electrical Reference,
%   le zéro de ses tensions.
%
%   Les équations du réseau s'écrivent par l'analyse nodale modifiée : une
%   inconnue par nœud, une de plus par source de tension, condensateur et
%   capteur de courant. Ses états sont la tension de chaque condensateur
%   et le courant de chaque bobine ; ses entrées, la valeur de chaque
%   source ; ses sorties, ce que mesure chaque capteur. Le réseau étant
%   linéaire, la réponse à chaque état et à chaque entrée prise seule
%   donne les matrices d'une représentation d'état, et le bloc Solver
%   Configuration devient un bloc State-Space : tous les solveurs de
%   Simulink l'intègrent, et LINMOD le linéarise. Les sources deviennent
%   des Constant et des Sine Wave, les sources commandées et les capteurs
%   des passe-plats, les autres éléments ne calculent plus rien.
%
%   Conventions de Simscape : un courant va du port + (LConn1) au port -
%   (RConn1) à travers le bloc ; une tension est v(+) - v(-).
%
%   V = MATLIBRE_SL_PHYSIQUE('unite',V,UNITE,CHEMIN,NOM) ramène une valeur
%   écrite dans une unité (kOhm, uF, mH, kHz, deg...) à l'unité de base.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi ADD_LINE, MATLIBRE_SL_APLATIR.
    switch action
        case 'ports'
            [varargout{1:4}] = portsDe(varargin{1});
        case 'est'
            varargout{1} = any(strcmp(varargin{1}, tableTypes()));
        case 'reseaux'
            varargout{1} = reseaux(varargin{1});
        case 'unite'
            varargout{1} = unite(varargin{:});
        case 'nomPort'
            varargout{1} = nomPort(varargin{1});
        case 'composant'
            varargout{1} = composant(varargin{1});
        otherwise
            error('Simulink:Physique:Action', 'Action inconnue : %s.', char(action));
    end
end

% Les blocs physiques : type, ports physiques à gauche et à droite,
% entrées et sorties de signal.
function [t, P] = tableTypes()
    T = {
        'resistor',                1, 1, 0, 0
        'capacitor',               1, 1, 0, 0
        'inductor',                1, 1, 0, 0
        'electricalreference',     1, 0, 0, 0
        'solverconfiguration',     0, 1, 0, 0
        'dcvoltagesource',         1, 1, 0, 0
        'dccurrentsource',         1, 1, 0, 0
        'acvoltagesource',         1, 1, 0, 0
        'accurrentsource',         1, 1, 0, 0
        'controlledvoltagesource', 1, 1, 1, 0
        'controlledcurrentsource', 1, 1, 1, 0
        'voltagesensor',           1, 1, 0, 1
        'currentsensor',           1, 1, 0, 1
        };
    t = T(:, 1);
    P = cell2mat(T(:, 2:5));
end

function [g, d, e, s] = portsDe(type)
    [t, P] = tableTypes();
    k = find(strcmp(type, t), 1);
    if isempty(k)
        g = 0; d = 0; e = 0; s = 0;
        return
    end
    g = P(k, 1);
    d = P(k, 2);
    e = P(k, 3);
    s = P(k, 4);
end

function texte = nomPort(code)
    if code > 0
        texte = sprintf('LConn%d', code);
    else
        texte = sprintf('RConn%d', -code);
    end
end

% Le type d'un bloc Simscape par son composant, tel qu'un fichier de
% Simscape le nomme (foundation.electrical.elements.resistor).
function type = composant(chemin)
    table = {
        'foundation.electrical.elements.resistor',            'resistor'
        'foundation.electrical.elements.capacitor',           'capacitor'
        'foundation.electrical.elements.inductor',            'inductor'
        'foundation.electrical.elements.reference',           'electricalreference'
        'foundation.electrical.sources.dc_voltage',           'dcvoltagesource'
        'foundation.electrical.sources.dc_current',           'dccurrentsource'
        'foundation.electrical.sources.ac_voltage',           'acvoltagesource'
        'foundation.electrical.sources.ac_current',           'accurrentsource'
        'foundation.electrical.sources.controlled_voltage',   'controlledvoltagesource'
        'foundation.electrical.sources.controlled_current',   'controlledcurrentsource'
        'foundation.electrical.sensors.voltage',              'voltagesensor'
        'foundation.electrical.sensors.current',              'currentsensor'
        };
    k = find(strcmp(char(chemin), table(:, 1)), 1);
    type = char(chemin);
    if ~isempty(k)
        type = table{k, 2};
    end
end

% --- les unités -------------------------------------------------------------

function v = unite(v, texte, chemin, nom)
    texte = strtrim(char(texte));
    facteurs = {
        'Ohm', 1; 'mOhm', 1e-3; 'kOhm', 1e3; 'MOhm', 1e6
        'F', 1; 'mF', 1e-3; 'uF', 1e-6; 'nF', 1e-9; 'pF', 1e-12
        'H', 1; 'mH', 1e-3; 'uH', 1e-6; 'nH', 1e-9
        'V', 1; 'mV', 1e-3; 'kV', 1e3; 'uV', 1e-6
        'A', 1; 'mA', 1e-3; 'uA', 1e-6; 'kA', 1e3
        'Hz', 1; 'kHz', 1e3; 'MHz', 1e6; 'rad/s', 1 / (2 * pi)
        'deg', 1; 'rad', 180 / pi
        '1/Ohm', 1; 'S', 1; 'mS', 1e-3; 'uS', 1e-6
        's', 1; 'ms', 1e-3; 'us', 1e-6
        };
    k = find(strcmp(texte, facteurs(:, 1)), 1);
    if isempty(k)
        error('Simulink:Parameters:InvParamSetting', ...
              ['L''unite ''%s'' du parametre ''%s'' de ''%s'' est inconnue : Ohm, kOhm, F, ' ...
               'uF, H, mH, V, A, Hz, deg...'], texte, nom, chemin);
    end
    v = v * facteurs{k, 2};
end

% --- les réseaux -------------------------------------------------------------

function modele = reseaux(modele)
    n = numel(modele.blocs);
    physique = false(1, n);
    for k = 1:n
        physique(k) = any(strcmp(modele.blocs{k}.type, tableTypes()));
    end
    if ~any(physique)
        if isfield(modele, 'connexions') && ~isempty(modele.connexions)
            error('Simulink:Physique:ConnexionSansBloc', ...
                  'Le modele ''%s'' porte des connexions physiques sans bloc physique.', ...
                  char(modele.nom));
        end
        return
    end
    connexions = zeros(0, 4);
    if isfield(modele, 'connexions')
        connexions = double(modele.connexions);
    end
    nomModele = char(modele.nom);
    chemin = @(k) [nomModele '/' modele.blocs{k}.nom];
    % chaque port physique, un numéro ; les connexions les unissent en nœuds
    ports = zeros(0, 2);
    for k = find(physique)
        [g, d] = portsDe(modele.blocs{k}.type);
        ports = [ports; repmat(k, g, 1), (1:g)'; repmat(k, d, 1), -(1:d)']; %#ok<AGROW>
    end
    parent = 1:size(ports, 1);
    rang = @(k, p) find(ports(:, 1) == k & ports(:, 2) == p, 1);
    for l = 1:size(connexions, 1)
        a = rang(connexions(l, 1), connexions(l, 2));
        b = rang(connexions(l, 3), connexions(l, 4));
        if isempty(a) || isempty(b)
            error('Simulink:Physique:ConnexionInvalide', ...
                  'Une connexion physique du modele ''%s'' designe un port qui n''existe pas.', ...
                  nomModele);
        end
        parent = unir(parent, a, b);
    end
    noeud = zeros(1, size(ports, 1));
    for i = 1:size(ports, 1)
        noeud(i) = racine(parent, i);
    end
    % les réseaux : les blocs qu'un nœud relie, de proche en proche
    blocsPhysiques = find(physique);
    groupe = 1:numel(blocsPhysiques);
    for i = 1:size(ports, 1)
        for j = i + 1:size(ports, 1)
            if noeud(i) == noeud(j)
                a = find(blocsPhysiques == ports(i, 1), 1);
                b = find(blocsPhysiques == ports(j, 1), 1);
                groupe = unir(groupe, a, b);
            end
        end
    end
    racines = zeros(1, numel(blocsPhysiques));
    for i = 1:numel(blocsPhysiques)
        racines(i) = racine(groupe, i);
    end
    for r = unique(racines)
        membres = blocsPhysiques(racines == r);
        modele = remplacer(modele, membres, ports, noeud, chemin);
    end
    modele.connexions = zeros(0, 4);
end

function parent = unir(parent, a, b)
    ra = racine(parent, a);
    rb = racine(parent, b);
    if ra ~= rb
        parent(max(ra, rb)) = min(ra, rb);
    end
end

function r = racine(parent, i)
    r = i;
    while parent(r) ~= r
        r = parent(r);
    end
end

% Un réseau : ses équations, puis les blocs ordinaires qui les calculent.
function modele = remplacer(modele, membres, ports, noeud, chemin)
    types = cellfun(@(k) modele.blocs{k}.type, num2cell(membres), 'UniformOutput', false);
    noms = strjoin(cellfun(@(k) ['''' chemin(k) ''''], num2cell(membres), ...
                           'UniformOutput', false), ', ');
    config = membres(strcmp(types, 'solverconfiguration'));
    if isempty(config)
        error('Simscape:Network:SolverConfigurationMissing', ...
              ['Le reseau physique de %s n''est relie a aucun bloc Solver Configuration : ' ...
               'chaque reseau physique doit en avoir un.'], noms);
    end
    if numel(config) > 1
        error('Simscape:Network:MultipleSolverConfigurations', ...
              ['Le reseau physique de %s est relie a %d blocs Solver Configuration : il ' ...
               'n''en faut qu''un par reseau.'], noms, numel(config));
    end
    references = membres(strcmp(types, 'electricalreference'));
    if isempty(references)
        error('Simscape:Network:ReferenceMissing', ...
              ['Le reseau electrique de %s n''a pas de bloc Electrical Reference : ses ' ...
               'tensions n''ont pas de zero.'], noms);
    end
    % les nœuds : la référence vaut 0, les autres sont numérotés
    dansReseau = ismember(ports(:, 1), membres);
    masse = unique(noeud(dansReseau & ismember(ports(:, 1), references)));
    autres = setdiff(unique(noeud(dansReseau)), masse);
    numero = @(k, p) numeroNoeud(noeud(find(ports(:, 1) == k & ports(:, 2) == p, 1)), ...
                                 masse, autres);
    nn = numel(autres);
    % les éléments, dans l'ordre des blocs
    el = struct('bloc', {}, 'type', {}, 'p', {}, 'n', {}, 'valeur', {}, 'r', {}, ...
                'g', {}, 'initial', {});
    for k = membres
        type = modele.blocs{k}.type;
        if any(strcmp(type, {'electricalreference', 'solverconfiguration'}))
            continue
        end
        e = struct('bloc', k, 'type', type, 'p', numero(k, 1), 'n', numero(k, -1), ...
                   'valeur', 0, 'r', 0, 'g', 0, 'initial', 0);
        e = lireElement(modele.blocs{k}, e, chemin(k));
        el(end + 1) = e; %#ok<AGROW>
    end
    % les inconnues de branche : sources de tension, condensateurs, capteurs de courant
    tensions = find(ismember({el.type}, {'dcvoltagesource', 'acvoltagesource', ...
                                         'controlledvoltagesource', 'capacitor', ...
                                         'currentsensor'}));
    nb = numel(tensions);
    condensateurs = find(strcmp({el.type}, 'capacitor'));
    bobines = find(strcmp({el.type}, 'inductor'));
    sources = find(ismember({el.type}, {'dcvoltagesource', 'acvoltagesource', ...
                                        'controlledvoltagesource', 'dccurrentsource', ...
                                        'accurrentsource', 'controlledcurrentsource'}));
    capteurs = find(ismember({el.type}, {'voltagesensor', 'currentsensor'}));
    nx = numel(condensateurs) + numel(bobines);
    nu = numel(sources);
    % M z = N w, avec z = [tensions des nœuds ; courants de branche] et
    % w = [états ; entrées]
    M = zeros(nn + nb);
    N = zeros(nn + nb, nx + nu);
    colonneEtat = zeros(1, numel(el));
    colonneEtat(condensateurs) = 1:numel(condensateurs);
    colonneEtat(bobines) = numel(condensateurs) + (1:numel(bobines));
    colonneEntree = zeros(1, numel(el));
    colonneEntree(sources) = nx + (1:nu);
    for i = 1:numel(el)
        e = el(i);
        p = e.p;
        q = e.n;
        switch e.type
            case 'resistor'
                M = conductance(M, p, q, 1 / e.valeur);
            case {'dccurrentsource', 'accurrentsource', 'controlledcurrentsource'}
                % i du + au - à travers la source : il sort par le - dans le réseau
                N = injection(N, p, -1, colonneEntree(i));
                N = injection(N, q, 1, colonneEntree(i));
            case 'inductor'
                M = conductance(M, p, q, e.g);
                N = injection(N, p, -1, colonneEtat(i));
                N = injection(N, q, 1, colonneEtat(i));
            otherwise
                if any(strcmp(e.type, {'voltagesensor'}))
                    continue
                end
                % une branche de tension : v(p) - v(q) - r i = valeur
                b = nn + find(tensions == i, 1);
                if p > 0
                    M(p, b) = M(p, b) + 1;
                    M(b, p) = M(b, p) + 1;
                end
                if q > 0
                    M(q, b) = M(q, b) - 1;
                    M(b, q) = M(b, q) - 1;
                end
                M(b, b) = M(b, b) - e.r;
                switch e.type
                    case 'capacitor'
                        N(b, colonneEtat(i)) = 1;
                        M = conductance(M, p, q, e.g);
                    case 'currentsensor'
                    otherwise
                        N(b, colonneEntree(i)) = 1;
                end
        end
    end
    % un réseau dont tous les nœuds sont à la référence n'a rien à résoudre
    if ~isempty(M) && (rcond(M) < 1e-13 || any(~isfinite(M(:))))
        error('Simscape:Network:SingularNetwork', ...
              ['Les equations du reseau de %s n''ont pas de solution unique : un noeud ' ...
               'flotte, sans chemin vers la reference, ou des sources de tension et des ' ...
               'condensateurs forment une boucle.'], noms);
    end
    Z = zeros(0, nx + nu);
    if ~isempty(M)
        Z = M \ N;   % chaque inconnue, en fonction des états et des entrées
    end
    ligne = @(noeudK) ligneNoeud(Z, noeudK, nx + nu);
    % les dérivées des états
    F = zeros(nx, nx + nu);
    X0 = zeros(nx, 1);
    for i = condensateurs
        k = colonneEtat(i);
        b = nn + find(tensions == i, 1);
        F(k, :) = Z(b, :) / el(i).valeur;
        X0(k) = el(i).initial;
    end
    for i = bobines
        k = colonneEtat(i);
        v = ligne(el(i).p) - ligne(el(i).n);
        v(k) = v(k) - el(i).r;
        F(k, :) = v / el(i).valeur;
        X0(k) = el(i).initial;
    end
    % ce que mesurent les capteurs
    H = zeros(numel(capteurs), nx + nu);
    for j = 1:numel(capteurs)
        i = capteurs(j);
        if strcmp(el(i).type, 'voltagesensor')
            H(j, :) = ligne(el(i).p) - ligne(el(i).n);
        else
            H(j, :) = Z(nn + find(tensions == i, 1), :);
        end
    end
    A = F(:, 1:nx);
    B = F(:, nx + 1:end);
    C = H(:, 1:nx);
    D = H(:, nx + 1:end);
    modele = reecrire(modele, config, el, sources, capteurs, A, B, C, D, X0, membres, chemin);
end

function k = numeroNoeud(racineNoeud, masse, autres)
    if any(racineNoeud == masse)
        k = 0;
    else
        k = find(autres == racineNoeud, 1);
    end
end

function M = conductance(M, p, q, g)
    if g == 0
        return
    end
    if p > 0
        M(p, p) = M(p, p) + g;
    end
    if q > 0
        M(q, q) = M(q, q) + g;
    end
    if p > 0 && q > 0
        M(p, q) = M(p, q) - g;
        M(q, p) = M(q, p) - g;
    end
end

function N = injection(N, noeudK, signe, colonne)
    if noeudK > 0
        N(noeudK, colonne) = N(noeudK, colonne) + signe;
    end
end

function v = ligneNoeud(Z, noeudK, largeur)
    if noeudK == 0
        v = zeros(1, largeur);
    else
        v = Z(noeudK, :);
    end
end

% --- les paramètres d'un élément ------------------------------------------------

function e = lireElement(bloc, e, chemin)
    switch e.type
        case 'resistor'
            e.valeur = positif(bloc, 'R', 1, 'Ohm', chemin);
        case 'capacitor'
            e.valeur = positif(bloc, 'c', 1, 'F', chemin);
            e.r = nombre(bloc, 'r', 1e-6, 'Ohm', chemin);
            e.g = nombre(bloc, 'g', 0, '1/Ohm', chemin);
            e.initial = nombre(bloc, 'vc', 0, 'V', chemin);
        case 'inductor'
            e.valeur = positif(bloc, 'l', 1, 'H', chemin);
            e.r = nombre(bloc, 'r', 0, 'Ohm', chemin);
            e.g = nombre(bloc, 'g', 1e-9, '1/Ohm', chemin);
            e.initial = nombre(bloc, 'iL', 0, 'A', chemin);
    end
end

function v = positif(bloc, nom, defaut, base, chemin)
    v = nombre(bloc, nom, defaut, base, chemin);
    if ~(v > 0)
        error('Simulink:Parameters:InvParamSetting', ...
              'Le parametre ''%s'' de ''%s'' vaut %s : il doit etre positif.', nom, chemin, ...
              mat2str(v, 6));
    end
end

% Un paramètre du bloc : sa valeur, évaluée comme dans le reste du modèle,
% ramenée à l'unité de base par son paramètre NOM_unit.
function v = nombre(bloc, nom, defaut, base, chemin)
    v = valeurParametre(bloc, nom, defaut, chemin);
    champ = [nom '_unit'];
    if isfield(bloc.parametres, champ)
        v = unite(v, bloc.parametres.(champ), chemin, nom);
    elseif ~isempty(base)
        v = double(v);
    end
end

% La valeur écrite d'un paramètre : une expression s'évalue dans l'espace
% du masque qui englobe le bloc, ou dans celui du modèle et de base ; un
% Simulink.Parameter donne sa valeur.
function v = valeurParametre(bloc, nom, defaut, chemin)
    v = defaut;
    noms = fieldnames(bloc.parametres);
    k = find(strcmp(noms, nom), 1);
    if isempty(k)
        return
    end
    v = bloc.parametres.(noms{k});
    if ischar(v) || isstring(v)
        if isfield(bloc, 'espace')
            v = matlibre_sl_masque('evaluer', char(v), bloc.espace, chemin, nom);
        else
            v = matlibre_sl_expression(char(v), chemin, nom);
        end
    end
    if isa(v, 'Simulink.Parameter')
        v = matlibre_sl_parametre('valeur', v, 'la valeur donnee', chemin, nom);
    end
    if ~(isnumeric(v) || islogical(v)) || ~isscalar(v) || ~isreal(v) || ~isfinite(double(v))
        error('Simulink:Parameters:InvParamSetting', ...
              'Le parametre ''%s'' de ''%s'' doit etre un nombre reel fini.', nom, chemin);
    end
    v = double(v);
end

% --- les blocs ordinaires qui calculent le réseau ------------------------------

function modele = reecrire(modele, config, el, sources, capteurs, A, B, C, D, X0, membres, chemin)
    nu = numel(sources);
    ny = numel(capteurs);
    nx = numel(X0);
    base = modele.blocs{config};
    nomReseau = base.nom;
    % les sources
    for j = 1:nu
        e = el(sources(j));
        k = e.bloc;
        bloc = modele.blocs{k};
        switch e.type
            case {'dcvoltagesource', 'dccurrentsource'}
                if strcmp(e.type, 'dcvoltagesource')
                    valeur = nombre(bloc, 'v0', 1, 'V', chemin(k));
                else
                    valeur = nombre(bloc, 'i0', 1, 'A', chemin(k));
                end
                modele.blocs{k} = remplace(bloc, 'constant', struct('Value', valeur));
            case {'acvoltagesource', 'accurrentsource'}
                amplitude = nombre(bloc, 'amp', 1, 'V', chemin(k));
                frequence = nombre(bloc, 'frequency', 60, 'Hz', chemin(k));
                phase = nombre(bloc, 'shift', 0, 'deg', chemin(k));
                modele.blocs{k} = remplace(bloc, 'sine', struct('Amplitude', amplitude, ...
                    'Frequency', 2 * pi * frequence, 'Phase', phase * pi / 180, 'Bias', 0, ...
                    'SampleTime', 0));
            otherwise
                modele.blocs{k} = remplace(bloc, 'signalconversion', struct());
        end
    end
    % les capteurs sont des passe-plats, les autres éléments ne calculent plus
    for j = 1:ny
        k = el(capteurs(j)).bloc;
        modele.blocs{k} = remplace(modele.blocs{k}, 'signalconversion', struct());
    end
    for k = membres
        if any(strcmp(modele.blocs{k}.type, {'resistor', 'capacitor', 'inductor', ...
                                             'electricalreference'}))
            modele.blocs{k} = remplace(modele.blocs{k}, 'ground', struct());
        end
    end
    % le réseau : entrées réunies, représentation d'état, sorties partagées
    n = numel(modele.blocs);
    if nx == 0
        A = 0;
        B = zeros(1, max(nu, 1));
        C = zeros(ny, 1);
        X0 = 0;
    end
    if nu == 0
        B = zeros(size(A, 1), 1);
        D = zeros(ny, 1);
    end
    if ny == 0
        C = zeros(1, size(A, 1));
        D = zeros(1, size(B, 2));
    end
    modele.blocs{config} = remplace(base, 'statespace', struct('A', A, 'B', B, 'C', C, ...
                                                              'D', D, 'X0', X0));
    entrees = struct('type', 'mux', 'nom', [nomReseau '/entrees'], ...
                     'parametres', struct('Inputs', max(nu, 1)));
    sorties = struct('type', 'demux', 'nom', [nomReseau '/sorties'], ...
                     'parametres', struct('Outputs', max(ny, 1)));
    entrees = heriter(entrees, base);
    sorties = heriter(sorties, base);
    modele.blocs{n + 1} = entrees;
    modele.blocs{n + 2} = sorties;
    liens = zeros(0, 4);
    for j = 1:nu
        liens(end + 1, :) = [el(sources(j)).bloc, n + 1, j, 1]; %#ok<AGROW>
    end
    if nu == 0
        masse = heriter(struct('type', 'ground', 'nom', [nomReseau '/zero'], ...
                               'parametres', struct()), base);
        modele.blocs{n + 3} = masse;
        liens(end + 1, :) = [n + 3, n + 1, 1, 1];
    end
    liens(end + 1, :) = [n + 1, config, 1, 1];
    liens(end + 1, :) = [config, n + 2, 1, 1];
    for j = 1:ny
        liens(end + 1, :) = [n + 2, el(capteurs(j)).bloc, 1, j]; %#ok<AGROW>
    end
    modele.liens = [matlibre_sl_liens(modele); liens];
end

% Un bloc qui change de type garde son nom, sa garde et sa place.
function bloc = remplace(bloc, type, parametres)
    ancien = bloc.parametres;
    bloc.type = type;
    bloc.parametres = parametres;
    if isfield(ancien, 'Position')
        bloc.parametres.Position = ancien.Position;
    end
end

function bloc = heriter(bloc, modeleDe)
    for champ = {'garde', 'espace'}
        if isfield(modeleDe, champ{1})
            bloc.(champ{1}) = modeleDe.(champ{1});
        end
    end
end
