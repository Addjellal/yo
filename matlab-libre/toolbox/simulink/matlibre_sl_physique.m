function varargout = matlibre_sl_physique(action, varargin)
%MATLIBRE_SL_PHYSIQUE Les réseaux physiques de Simscape dans un schéma.
%   [G,D,E,S] = MATLIBRE_SL_PHYSIQUE('ports',TYPE) rend les ports d'un
%   bloc physique : G ports physiques à gauche (LConn), D à droite (RConn),
%   E entrées et S sorties de signal. Un type qui n'est pas physique rend
%   des zéros, et OUI = MATLIBRE_SL_PHYSIQUE('est',TYPE) le dit.
%   DOM = MATLIBRE_SL_PHYSIQUE('domaine',TYPE,CODE) rend le domaine d'un
%   port physique : 'electrique', 'translation', 'rotation' ou 'thermique'
%   ('' pour le Solver Configuration, qui se relie à tous).
%
%   MODELE = MATLIBRE_SL_PHYSIQUE('reseaux',MODELE) remplace chaque réseau
%   physique d'un modèle déplié par des blocs ordinaires. Les connexions
%   physiques (MODELE.connexions, une ligne [bloc, port, bloc, port], un
%   port +i pour LConn i, -i pour RConn i) font les nœuds ; les nœuds et
%   les blocs qu'ils relient font les réseaux. Chaque réseau doit avoir
%   un bloc Solver Configuration, et une référence dans chacun de ses
%   domaines — Electrical Reference, Mechanical Translational Reference,
%   Mechanical Rotational Reference, Thermal Reference.
%
%   Un réseau s'écrit par l'analyse nodale modifiée, la même dans tous les
%   domaines : une grandeur « à travers » — tension, vitesse, vitesse
%   angulaire, température — par nœud, une grandeur « traversante » —
%   courant, force, couple, flux de chaleur — par branche. Une masse, une
%   inertie, une masse thermique sont des condensateurs vers la référence ;
%   un ressort une bobine ; un amortisseur, une paroi des conductances ;
%   une source de force ou de couple une source de courant.
%   Le convertisseur électromécanique lie les deux domaines : v = K w,
%   couple = K i. Ses états sont les tensions des condensateurs, les
%   vitesses des masses et des inerties, les températures des masses
%   thermiques, les courants des bobines, les
%   efforts des ressorts, et la position que mesure chaque capteur de
%   mouvement. Le réseau étant linéaire, il devient une représentation
%   d'état : le bloc Solver Configuration devient un bloc State-Space, que
%   tous les solveurs intègrent et que LINMOD linéarise.
%
%   Conventions de Simscape : une grandeur traversante va du port de gauche
%   (+, R) au port de droite (-, C) à travers le bloc ; une grandeur à
%   travers est la différence gauche moins droite. Une source de force ou
%   de couple positive agit de C vers R : elle pousse le port R. Une
%   source de température impose T(B) - T(A), ses ports A et B étant à
%   gauche et à droite ; les températures sont absolues.
%
%   V = MATLIBRE_SL_PHYSIQUE('unite',V,UNITE,BASE,CHEMIN,NOM) ramène une
%   valeur écrite dans une unité (kOhm, uF, mH, kHz, deg, rpm, g, mm...) à
%   l'unité BASE du paramètre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi ADD_LINE, MATLIBRE_SL_APLATIR.
    switch action
        case 'ports'
            [varargout{1:4}] = portsDe(varargin{1});
        case 'domaine'
            varargout{1} = domaineDe(varargin{1}, varargin{2});
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

% Les blocs physiques : type, comportement, ports physiques à gauche et à
% droite, entrées et sorties de signal, domaine des ports de chaque bord.
function T = table()
    T = {
        'resistor',                         'conductance',    1, 1, 0, 0, 'e', 'e'
        'capacitor',                        'capacite',       1, 1, 0, 0, 'e', 'e'
        'inductor',                         'inductance',     1, 1, 0, 0, 'e', 'e'
        'electricalreference',              'reference',      1, 0, 0, 0, 'e', ''
        'solverconfiguration',              'config',         0, 1, 0, 0, '', ''
        'dcvoltagesource',                  'sourceAcross',   1, 1, 0, 0, 'e', 'e'
        'dccurrentsource',                  'sourceThrough',  1, 1, 0, 0, 'e', 'e'
        'acvoltagesource',                  'sourceAcross',   1, 1, 0, 0, 'e', 'e'
        'accurrentsource',                  'sourceThrough',  1, 1, 0, 0, 'e', 'e'
        'controlledvoltagesource',          'sourceAcross',   1, 1, 1, 0, 'e', 'e'
        'controlledcurrentsource',          'sourceThrough',  1, 1, 1, 0, 'e', 'e'
        'voltagesensor',                    'capteurAcross',  1, 1, 0, 1, 'e', 'e'
        'currentsensor',                    'capteurThrough', 1, 1, 0, 1, 'e', 'e'
        'mass',                             'capacite',       1, 0, 0, 0, 't', ''
        'translationalspring',              'inductance',     1, 1, 0, 0, 't', 't'
        'translationaldamper',              'conductance',    1, 1, 0, 0, 't', 't'
        'mechanicaltranslationalreference', 'reference',      1, 0, 0, 0, 't', ''
        'idealforcesource',                 'sourceThrough',  1, 1, 1, 0, 't', 't'
        'idealtranslationalvelocitysource', 'sourceAcross',   1, 1, 1, 0, 't', 't'
        'idealtranslationalmotionsensor',   'capteurAcross',  1, 1, 0, 2, 't', 't'
        'idealforcesensor',                 'capteurThrough', 1, 1, 0, 1, 't', 't'
        'inertia',                          'capacite',       1, 0, 0, 0, 'r', ''
        'rotationalspring',                 'inductance',     1, 1, 0, 0, 'r', 'r'
        'rotationaldamper',                 'conductance',    1, 1, 0, 0, 'r', 'r'
        'mechanicalrotationalreference',    'reference',      1, 0, 0, 0, 'r', ''
        'idealtorquesource',                'sourceThrough',  1, 1, 1, 0, 'r', 'r'
        'idealangularvelocitysource',       'sourceAcross',   1, 1, 1, 0, 'r', 'r'
        'idealrotationalmotionsensor',      'capteurAcross',  1, 1, 0, 2, 'r', 'r'
        'idealtorquesensor',                'capteurThrough', 1, 1, 0, 1, 'r', 'r'
        'rotationalelectromechanicalconverter', 'convertisseur', 2, 2, 0, 0, 'e', 'r'
        'thermalmass',                      'capacite',       1, 0, 0, 0, 'h', ''
        'conductiveheattransfer',           'conductance',    1, 1, 0, 0, 'h', 'h'
        'convectiveheattransfer',           'conductance',    1, 1, 0, 0, 'h', 'h'
        'thermalreference',                 'reference',      1, 0, 0, 0, 'h', ''
        'idealtemperaturesource',           'sourceAcross',   1, 1, 1, 0, 'h', 'h'
        'idealheatflowsource',              'sourceThrough',  1, 1, 1, 0, 'h', 'h'
        'idealtemperaturesensor',           'capteurAcross',  1, 1, 0, 1, 'h', 'h'
        'idealheatflowsensor',              'capteurThrough', 1, 1, 0, 1, 'h', 'h'
        };
end

function t = tableTypes()
    T = table();
    t = T(:, 1);
end

function ligne = entreeDe(type)
    T = table();
    k = find(strcmp(type, T(:, 1)), 1);
    ligne = {};
    if ~isempty(k)
        ligne = T(k, :);
    end
end

function c = comportementDe(type)
    ligne = entreeDe(type);
    c = '';
    if ~isempty(ligne)
        c = ligne{2};
    end
end

function [g, d, e, s] = portsDe(type)
    ligne = entreeDe(type);
    if isempty(ligne)
        g = 0; d = 0; e = 0; s = 0;
        return
    end
    [g, d, e, s] = ligne{3:6};
end

function nom = domaineDe(type, code)
    ligne = entreeDe(type);
    noms = struct('e', 'electrique', 't', 'translation', 'r', 'rotation', 'h', 'thermique');
    nom = '';
    if isempty(ligne)
        return
    end
    lettre = ligne{7};
    if code < 0
        lettre = ligne{8};
    end
    if ~isempty(lettre)
        nom = noms.(lettre);
    end
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
        'foundation.mechanical.translational.mass',           'mass'
        'foundation.mechanical.translational.spring',         'translationalspring'
        'foundation.mechanical.translational.damper',         'translationaldamper'
        'foundation.mechanical.translational.reference',      'mechanicaltranslationalreference'
        'foundation.mechanical.rotational.inertia',           'inertia'
        'foundation.mechanical.rotational.spring',            'rotationalspring'
        'foundation.mechanical.rotational.damper',            'rotationaldamper'
        'foundation.mechanical.rotational.reference',         'mechanicalrotationalreference'
        'foundation.thermal.elements.mass',                   'thermalmass'
        'foundation.thermal.elements.conduction',             'conductiveheattransfer'
        'foundation.thermal.elements.convection',             'convectiveheattransfer'
        'foundation.thermal.elements.reference',              'thermalreference'
        };
    k = find(strcmp(char(chemin), table(:, 1)), 1);
    type = char(chemin);
    if ~isempty(k)
        type = table{k, 2};
    end
end

% --- les unités -------------------------------------------------------------

% Une valeur écrite dans UNITE, ramenée à l'unité BASE du paramètre : les
% deux doivent mesurer la même grandeur.
function v = unite(v, texte, base, chemin, nom)
    unites = {
        'Ohm', 'R', 1; 'mOhm', 'R', 1e-3; 'kOhm', 'R', 1e3; 'MOhm', 'R', 1e6
        'F', 'C', 1; 'mF', 'C', 1e-3; 'uF', 'C', 1e-6; 'nF', 'C', 1e-9; 'pF', 'C', 1e-12
        'H', 'L', 1; 'mH', 'L', 1e-3; 'uH', 'L', 1e-6; 'nH', 'L', 1e-9
        'V', 'U', 1; 'mV', 'U', 1e-3; 'kV', 'U', 1e3; 'uV', 'U', 1e-6
        'A', 'I', 1; 'mA', 'I', 1e-3; 'uA', 'I', 1e-6; 'kA', 'I', 1e3
        '1/Ohm', 'G', 1; 'S', 'G', 1; 'mS', 'G', 1e-3; 'uS', 'G', 1e-6
        'Hz', 'f', 1; 'kHz', 'f', 1e3; 'MHz', 'f', 1e6
        'rad', 'a', 1; 'deg', 'a', pi / 180; 'rev', 'a', 2 * pi
        'kg', 'm', 1; 'g', 'm', 1e-3; 't', 'm', 1e3
        'm', 'x', 1; 'cm', 'x', 1e-2; 'mm', 'x', 1e-3; 'km', 'x', 1e3
        'm/s', 'v', 1; 'mm/s', 'v', 1e-3; 'km/h', 'v', 1 / 3.6
        'rad/s', 'w', 1; 'deg/s', 'w', pi / 180; 'rpm', 'w', pi / 30
        'N', 'F', 1; 'kN', 'F', 1e3; 'mN', 'F', 1e-3
        'N*m', 'T', 1; 'mN*m', 'T', 1e-3; 'kN*m', 'T', 1e3
        'N/m', 'k', 1; 'N/mm', 'k', 1e3; 'kN/m', 'k', 1e3
        'N/(m/s)', 'b', 1; 'N*s/m', 'b', 1
        'kg*m^2', 'J', 1; 'g*cm^2', 'J', 1e-7
        'N*m/rad', 'K', 1; 'N*m/deg', 'K', 180 / pi
        'N*m/(rad/s)', 'B', 1; 'N*m*s/rad', 'B', 1
        'V/(rad/s)', 'E', 1; 'V/rpm', 'E', 30 / pi
        's', 's', 1; 'ms', 's', 1e-3; 'us', 's', 1e-6
        'K', 'tK', 1; 'degC', 'tK', 1; 'degF', 'tK', 5 / 9; 'degR', 'tK', 5 / 9
        'W', 'P', 1; 'kW', 'P', 1e3; 'mW', 'P', 1e-3
        'm^2', 'S', 1; 'cm^2', 'S', 1e-4; 'mm^2', 'S', 1e-6
        'W/(m*K)', 'l', 1; 'W/(K*m)', 'l', 1
        'W/(m^2*K)', 'h', 1; 'W/(K*m^2)', 'h', 1
        'J/(kg*K)', 'c', 1; 'J/(K*kg)', 'c', 1; 'kJ/(kg*K)', 'c', 1e3; 'kJ/(K*kg)', 'c', 1e3
        };
    texte = strtrim(char(texte));
    k = find(strcmp(texte, unites(:, 1)), 1);
    b = find(strcmp(base, unites(:, 1)), 1);
    if isempty(k) || isempty(b) || ~strcmp(unites{k, 2}, unites{b, 2})
        attendues = unites(strcmp(unites(:, 2), unites{b, 2}), 1);
        error('Simulink:Parameters:InvParamSetting', ...
              ['L''unite ''%s'' du parametre ''%s'' de ''%s'' ne convient pas : on ' ...
               'attend %s.'], texte, nom, chemin, strjoin(attendues', ', '));
    end
    % une température absolue : l'échelle Celsius ou Fahrenheit se décale
    switch texte
        case 'degC'
            v = v + 273.15;
            return
        case 'degF'
            v = (v - 32) * 5 / 9 + 273.15;
            return
    end
    v = v * unites{k, 3} / unites{b, 3};
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
    % une référence dans chaque domaine du réseau
    references = membres(strcmp(cellfun(@comportementDe, types, 'UniformOutput', false), ...
                                'reference'));
    domaines = {};
    for k = membres
        [g, d] = portsDe(modele.blocs{k}.type);
        for code = [1:g, -(1:d)]
            domaines{end + 1} = domaineDe(modele.blocs{k}.type, code); %#ok<AGROW>
        end
    end
    domaines = setdiff(unique(domaines), {''});
    nomsReference = struct('electrique', 'Electrical Reference', ...
                           'translation', 'Mechanical Translational Reference', ...
                           'rotation', 'Mechanical Rotational Reference', ...
                           'thermique', 'Thermal Reference');
    for i = 1:numel(domaines)
        presente = any(arrayfun(@(k) strcmp(domaineDe(modele.blocs{k}.type, 1), domaines{i}), ...
                                references));
        if ~presente
            error('Simscape:Network:ReferenceMissing', ...
                  ['Le reseau physique de %s n''a pas de bloc %s : les grandeurs du domaine ' ...
                   '%s n''y ont pas de zero.'], noms, nomsReference.(domaines{i}), domaines{i});
        end
    end
    % les nœuds : les références valent 0, les autres sont numérotés
    dansReseau = ismember(ports(:, 1), membres);
    masse = unique(noeud(dansReseau & ismember(ports(:, 1), references)));
    autres = setdiff(unique(noeud(dansReseau)), masse);
    numero = @(k, p) numeroNoeud(noeud(find(ports(:, 1) == k & ports(:, 2) == p, 1)), ...
                                 masse, autres);
    nn = numel(autres);
    % les éléments, dans l'ordre des blocs
    el = struct('bloc', {}, 'type', {}, 'comportement', {}, 'p', {}, 'n', {}, ...
                'valeur', {}, 'r', {}, 'g', {}, 'initial', {}, 'signe', {}, ...
                'sorties', {}, 'position', {}, 'mp', {}, 'mn', {});
    for k = membres
        type = modele.blocs{k}.type;
        ligne = entreeDe(type);
        if any(strcmp(ligne{2}, {'reference', 'config'}))
            continue
        end
        e = struct('bloc', k, 'type', type, 'comportement', ligne{2}, 'p', numero(k, 1), ...
                   'n', 0, 'valeur', 0, 'r', 0, 'g', 0, 'initial', 0, 'signe', 1, ...
                   'sorties', ligne{6}, 'position', 0, 'mp', 0, 'mn', 0);
        if ligne{4} >= 1 && ~strcmp(ligne{2}, 'convertisseur')
            e.n = numero(k, -1);
        end
        if strcmp(ligne{2}, 'convertisseur')
            % + et - à gauche, R et C à droite
            e.n = numero(k, 2);
            e.mp = numero(k, -1);
            e.mn = numero(k, -2);
        end
        e = lireElement(modele.blocs{k}, e, chemin(k));
        el(end + 1) = e; %#ok<AGROW>
    end
    comportements = {el.comportement};
    % les inconnues de branche : sources « à travers », capacités,
    % capteurs de grandeur traversante, convertisseurs
    branches = find(ismember(comportements, {'sourceAcross', 'capacite', 'capteurThrough', ...
                                             'convertisseur'}));
    nb = numel(branches);
    capacites = find(strcmp(comportements, 'capacite'));
    inductances = find(strcmp(comportements, 'inductance'));
    sources = find(ismember(comportements, {'sourceAcross', 'sourceThrough'}));
    capteurs = find(ismember(comportements, {'capteurAcross', 'capteurThrough'}));
    mouvements = capteurs([el(capteurs).sorties] == 2);   % une position à intégrer
    nx = numel(capacites) + numel(inductances);
    nu = numel(sources);
    % M z = N w, avec z = [grandeurs des nœuds ; grandeurs des branches] et
    % w = [états ; entrées]
    M = zeros(nn + nb);
    N = zeros(nn + nb, nx + nu);
    colonneEtat = zeros(1, numel(el));
    colonneEtat(capacites) = 1:numel(capacites);
    colonneEtat(inductances) = numel(capacites) + (1:numel(inductances));
    colonneEntree = zeros(1, numel(el));
    colonneEntree(sources) = nx + (1:nu);
    branche = @(i) nn + find(branches == i, 1);
    for i = 1:numel(el)
        e = el(i);
        p = e.p;
        q = e.n;
        switch e.comportement
            case 'conductance'
                M = conductance(M, p, q, e.valeur);
            case 'sourceThrough'
                % la grandeur traversante va de p à q à travers la source ;
                % SIGNE -1 : elle pousse p (force, couple)
                N = injection(N, p, -e.signe, colonneEntree(i));
                N = injection(N, q, e.signe, colonneEntree(i));
            case 'inductance'
                M = conductance(M, p, q, e.g);
                N = injection(N, p, -1, colonneEtat(i));
                N = injection(N, q, 1, colonneEtat(i));
            case 'capteurAcross'
            case 'convertisseur'
                % v(+) - v(-) = K (w(R) - w(C)) ; le couple K i pousse R
                b = branche(i);
                M = incidence(M, p, q, b);
                M = colonne(M, b, e.mp, -e.valeur);
                M = colonne(M, b, e.mn, e.valeur);
                M = ligneEntree(M, e.mp, b, -e.valeur);
                M = ligneEntree(M, e.mn, b, e.valeur);
            otherwise
                % une branche « à travers » : x(p) - x(q) - r i = valeur
                b = branche(i);
                M = incidence(M, p, q, b);
                M(b, b) = M(b, b) - e.r;
                switch e.comportement
                    case 'capacite'
                        N(b, colonneEtat(i)) = 1;
                        M = conductance(M, p, q, e.g);
                    case 'sourceAcross'
                        % SIGNE -1 : x(q) - x(p) = valeur (température)
                        N(b, colonneEntree(i)) = e.signe;
                end
        end
    end
    if ~isempty(M) && (rcond(M) < 1e-13 || any(~isfinite(M(:))))
        error('Simscape:Network:SingularNetwork', ...
              ['Les equations du reseau de %s n''ont pas de solution unique : un noeud ' ...
               'flotte, sans chemin vers la reference, ou des sources et des elements ' ...
               'a etat forment une boucle.'], noms);
    end
    Z = zeros(0, nx + nu);
    if ~isempty(M)
        Z = M \ N;   % chaque inconnue, en fonction des états et des entrées
    end
    ligne = @(noeudK) ligneNoeud(Z, noeudK, nx + nu);
    % les dérivées des états
    F = zeros(nx, nx + nu);
    X0 = zeros(nx, 1);
    for i = capacites
        k = colonneEtat(i);
        F(k, :) = Z(branche(i), :) / el(i).valeur;
        X0(k) = el(i).initial;
    end
    for i = inductances
        k = colonneEtat(i);
        v = ligne(el(i).p) - ligne(el(i).n);
        v(k) = v(k) - el(i).r;
        F(k, :) = v / el(i).valeur;
        X0(k) = el(i).initial;
    end
    % ce que mesurent les capteurs : la grandeur, puis la position
    H = zeros(0, nx + nu);
    estPosition = false(0, 1);
    for j = 1:numel(capteurs)
        i = capteurs(j);
        if strcmp(el(i).comportement, 'capteurAcross')
            H(end + 1, 1:nx + nu) = ligne(el(i).p) - ligne(el(i).n); %#ok<AGROW>
            estPosition(end + 1, 1) = false; %#ok<AGROW>
            if el(i).sorties == 2
                H(end + 1, 1:nx + nu) = 0; %#ok<AGROW>   % la position, un état de plus
                estPosition(end + 1, 1) = true; %#ok<AGROW>
            end
        else
            H(end + 1, 1:nx + nu) = Z(branche(i), :); %#ok<AGROW>
            estPosition(end + 1, 1) = false; %#ok<AGROW>
        end
    end
    A = F(:, 1:nx);
    B = F(:, nx + 1:end);
    C = H(:, 1:nx);
    D = H(:, nx + 1:end);
    % chaque position est l'intégrale d'une vitesse mesurée : un état de
    % plus, dont la dérivée est la ligne de cette vitesse
    lignesPosition = find(estPosition);
    for j = 1:numel(lignesPosition)
        l = lignesPosition(j);
        vitesseX = C(l - 1, :);
        vitesseU = D(l - 1, :);
        A = [A, zeros(size(A, 1), 1); vitesseX, 0]; %#ok<AGROW>
        B = [B; vitesseU]; %#ok<AGROW>
        C = [C, zeros(size(C, 1), 1)]; %#ok<AGROW>
        C(l, :) = 0;
        C(l, end) = 1;
        D(l, :) = 0;
        X0 = [X0; el(mouvements(j)).position]; %#ok<AGROW>
    end
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

% Une branche de p à q, d'inconnue b : elle quitte p, arrive en q, et son
% équation lit x(p) - x(q).
function M = incidence(M, p, q, b)
    if p > 0
        M(p, b) = M(p, b) + 1;
        M(b, p) = M(b, p) + 1;
    end
    if q > 0
        M(q, b) = M(q, b) - 1;
        M(b, q) = M(b, q) - 1;
    end
end

function M = colonne(M, b, noeudK, valeur)
    if noeudK > 0
        M(b, noeudK) = M(b, noeudK) + valeur;
    end
end

function M = ligneEntree(M, noeudK, b, valeur)
    if noeudK > 0
        M(noeudK, b) = M(noeudK, b) + valeur;
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
            e.valeur = 1 / positif(bloc, 'R', 1, 'Ohm', chemin);
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
        case 'mass'
            e.valeur = positif(bloc, 'mass', 1, 'kg', chemin);
            e.initial = nombre(bloc, 'v', 0, 'm/s', chemin);
        case 'translationalspring'
            raideur = positif(bloc, 'spr_rate', 1000, 'N/m', chemin);
            e.valeur = 1 / raideur;
            e.initial = raideur * nombre(bloc, 'x', 0, 'm', chemin);
        case 'translationaldamper'
            e.valeur = positif(bloc, 'D', 100, 'N/(m/s)', chemin);
        case 'inertia'
            e.valeur = positif(bloc, 'inertia', 0.01, 'kg*m^2', chemin);
            e.initial = nombre(bloc, 'w', 0, 'rad/s', chemin);
        case 'rotationalspring'
            raideur = positif(bloc, 'spr_rate', 10, 'N*m/rad', chemin);
            e.valeur = 1 / raideur;
            e.initial = raideur * nombre(bloc, 'phi', 0, 'rad', chemin);
        case 'rotationaldamper'
            e.valeur = positif(bloc, 'D', 0.001, 'N*m/(rad/s)', chemin);
        case {'idealforcesource', 'idealtorquesource'}
            e.signe = -1;   % un signal positif pousse le port R
        case 'idealtranslationalmotionsensor'
            e.position = nombre(bloc, 'x0', 0, 'm', chemin);
        case 'idealrotationalmotionsensor'
            e.position = nombre(bloc, 'phi0', 0, 'rad', chemin);
        case 'rotationalelectromechanicalconverter'
            e.valeur = nombre(bloc, 'K', 0.1, 'V/(rad/s)', chemin);
        case 'idealtemperaturesource'
            e.signe = -1;   % T(B) - T(A) = s
        case 'thermalmass'
            e.valeur = positif(bloc, 'mass', 1, 'kg', chemin) * ...
                       positif(bloc, 'sp_heat', 447, 'J/(kg*K)', chemin);
            e.initial = nombre(bloc, 'T', 300, 'K', chemin);
        case 'conductiveheattransfer'
            e.valeur = positif(bloc, 'th_cond', 401, 'W/(m*K)', chemin) * ...
                       positif(bloc, 'area', 1e-4, 'm^2', chemin) / ...
                       positif(bloc, 'thickness', 0.1, 'm', chemin);
        case 'convectiveheattransfer'
            e.valeur = positif(bloc, 'heat_tr_coeff', 20, 'W/(m^2*K)', chemin) * ...
                       positif(bloc, 'area', 1e-4, 'm^2', chemin);
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
        v = unite(v, bloc.parametres.(champ), base, chemin, nom);
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
    ny = size(C, 1);
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
                baseAmplitude = 'V';
                if strcmp(e.type, 'accurrentsource')
                    baseAmplitude = 'A';
                end
                amplitude = nombre(bloc, 'amp', 1, baseAmplitude, chemin(k));
                frequence = nombre(bloc, 'frequency', 60, 'Hz', chemin(k));
                phase = nombre(bloc, 'shift', 0, 'deg', chemin(k));
                modele.blocs{k} = remplace(bloc, 'sine', struct('Amplitude', amplitude, ...
                    'Frequency', 2 * pi * frequence, 'Phase', phase * pi / 180, 'Bias', 0, ...
                    'SampleTime', 0));
            otherwise
                modele.blocs{k} = remplace(bloc, 'signalconversion', struct());
        end
    end
    % les capteurs sont des passe-plats, une voie par grandeur mesurée
    for j = 1:numel(capteurs)
        k = el(capteurs(j)).bloc;
        parametres = struct();
        if el(capteurs(j)).sorties > 1
            parametres.NombreDePorts = el(capteurs(j)).sorties;
        end
        modele.blocs{k} = remplace(modele.blocs{k}, 'signalconversion', parametres);
    end
    for k = membres
        type = modele.blocs{k}.type;
        ligne = entreeDe(type);
        if ~isempty(ligne) && any(strcmp(ligne{2}, {'conductance', 'capacite', 'inductance', ...
                                                    'reference', 'convertisseur'}))
            modele.blocs{k} = remplace(modele.blocs{k}, 'ground', struct());
        end
    end
    % le réseau : entrées réunies, représentation d'état, sorties partagées
    n = numel(modele.blocs);
    nx = numel(X0);
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
    entrees = heriter(struct('type', 'mux', 'nom', [nomReseau '/entrees'], ...
                             'parametres', struct('Inputs', max(nu, 1))), base);
    sorties = heriter(struct('type', 'demux', 'nom', [nomReseau '/sorties'], ...
                             'parametres', struct('Outputs', max(ny, 1))), base);
    modele.blocs{n + 1} = entrees;
    modele.blocs{n + 2} = sorties;
    liens = zeros(0, 4);
    for j = 1:nu
        liens(end + 1, :) = [el(sources(j)).bloc, n + 1, j, 1]; %#ok<AGROW>
    end
    if nu == 0
        modele.blocs{n + 3} = heriter(struct('type', 'ground', 'nom', [nomReseau '/zero'], ...
                                             'parametres', struct()), base);
        liens(end + 1, :) = [n + 3, n + 1, 1, 1];
    end
    liens(end + 1, :) = [n + 1, config, 1, 1];
    liens(end + 1, :) = [config, n + 2, 1, 1];
    voie = 0;
    for j = 1:numel(capteurs)
        for q = 1:el(capteurs(j)).sorties
            voie = voie + 1;
            liens(end + 1, :) = [n + 2, el(capteurs(j)).bloc, q, voie]; %#ok<AGROW>
        end
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
