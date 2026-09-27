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
%   couple = K i ; le transformateur idéal, le réducteur, la roue et
%   l'essieu lient de même deux grandeurs à travers et deux efforts.
%   L'amplificateur opérationnel idéal égale ses deux entrées sans y
%   laisser passer de courant. Ses états sont les tensions des condensateurs, les
%   vitesses des masses et des inerties, les températures des masses
%   thermiques, les courants des bobines, les
%   efforts des ressorts, et la position que mesure chaque capteur de
%   mouvement. Le réseau étant linéaire, il devient une représentation
%   d'état : le bloc Solver Configuration devient un bloc State-Space, que
%   tous les solveurs intègrent et que LINMOD linéarise.
%
%   Des éléments à état solidaires — deux inerties sur un même arbre, deux
%   masses thermiques sur un même nœud, un ressort au bout libre, un
%   enroulement ouvert — n'ont pas d'états indépendants : les équations
%   algébriques du réseau sont alors singulières, et le système
%   algébro-différentiel se réduit, contrainte après contrainte, aux
%   combinaisons d'états qu'il laisse libres. Une source qui impose l'état
%   d'un élément (une source de vitesse sur une masse) demande la dérivée
%   de sa commande : le Simulink-PS Converter la fournit en filtrant son
%   entrée (FilteringAndDerivatives), ou la dit nulle (constante par
%   morceaux). Les convertisseurs lisent l'unité de leur signal (mA, rpm,
%   degC...) et la ramènent aux unités SI dans lesquelles le réseau calcule.
%
%   Conventions de Simscape : une grandeur traversante va du port de gauche
%   (+, R) au port de droite (-, C) à travers le bloc ; une grandeur à
%   travers est la différence gauche moins droite. Une source de force ou
%   de couple positive agit de C vers R : elle pousse le port R. Une
%   source de température impose T(B) - T(A), ses ports A et B étant à
%   gauche et à droite ; les températures sont absolues.
%
%   Les blocs de signaux physiques — PS Gain, PS Add, PS Subtract, PS
%   Product, PS Divide, PS Abs, PS Sign, PS Ceil, PS Floor, PS Round, PS
%   Fix, PS Max, PS Min, PS Constant, PS Math Function, PS Integrator, PS
%   Saturation, PS Dead Zone, PS Switch, PS Constant Delay, PS Terminator,
%   PS Lookup Table (1D) et (2D) —
%   calculent sur des signaux, en unités SI : chacun devient le bloc de
%   Simulink qui calcule la même chose. OUI = MATLIBRE_SL_PHYSIQUE(
%   'estSignal',TYPE) les reconnaît, [NE,NS] = MATLIBRE_SL_PHYSIQUE(
%   'portsSignal',TYPE,PARAMETRES) rend leurs entrées et leurs sorties.
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
        case 'estSignal'
            T = tableSignaux();
            varargout{1} = any(strcmp(varargin{1}, T(:, 1)));
        case 'portsSignal'
            [varargout{1:2}] = portsSignal(varargin{:});
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
        'opamp',                            'ampliOp',        2, 1, 0, 0, 'e', 'e'
        'idealtransformer',                 'convertisseur',  2, 2, 0, 0, 'e', 'e'
        'mutualinductor',                   'mutuelle',       2, 2, 0, 0, 'e', 'e'
        'voltagecontrolledvoltagesource',   'vcvs',           2, 2, 0, 0, 'e', 'e'
        'currentcontrolledvoltagesource',   'ccvs',           2, 2, 0, 0, 'e', 'e'
        'opencircuit',                      'libre',          1, 0, 0, 0, 'e', ''
        'translationalelectromechanicalconverter', 'convertisseur', 2, 2, 0, 0, 'e', 't'
        'translationalinerter',             'capacite',       1, 1, 0, 0, 't', 't'
        'translationalfreeend',             'libre',          1, 0, 0, 0, 't', ''
        'rotationalinerter',                'capacite',       1, 1, 0, 0, 'r', 'r'
        'rotationalfreeend',                'libre',          1, 0, 0, 0, 'r', ''
        'gearbox',                          'reducteur',      1, 1, 0, 0, 'r', 'r'
        'wheelandaxle',                     'reducteur',      1, 1, 0, 0, 'r', 't'
        'perfectinsulator',                 'libre',          1, 0, 0, 0, 'h', ''
        };
end

function t = tableTypes()
    T = table();
    t = T(:, 1);
end

% Les blocs de signaux physiques : type, entrées, sorties.
function T = tableSignaux()
    T = {
        'psgain', 1, 1; 'psadd', 2, 1; 'pssubtract', 2, 1; 'psproduct', 2, 1
        'psdivide', 2, 1; 'psabs', 1, 1; 'pssign', 1, 1; 'psceil', 1, 1
        'psfloor', 1, 1; 'psround', 1, 1; 'psfix', 1, 1; 'psmax', 2, 1
        'psmin', 2, 1; 'psconstant', 0, 1; 'psmathfunction', 1, 1
        'psintegrator', 1, 1; 'pssaturation', 1, 1; 'psdeadzone', 1, 1
        'psswitch', 3, 1; 'psconstantdelay', 1, 1; 'psterminator', 1, 0
        'pslookuptable1d', 1, 1; 'pslookuptable2d', 2, 1
        };
end

% Les ports d'un bloc de signaux physiques ; l'intégrateur gagne une entrée
% de remise et une de condition initiale quand on les lui demande.
function [ne, ns] = portsSignal(type, p)
    T = tableSignaux();
    k = find(strcmp(type, T(:, 1)), 1);
    ne = T{k, 2};
    ns = T{k, 3};
    if strcmp(type, 'psintegrator') && nargin > 1
        if isfield(p, 'ExternalReset') && ~strcmpi(char(p.ExternalReset), 'None')
            ne = ne + 1;
        end
        if isfield(p, 'InitialConditionSource') && ...
           strcmpi(char(p.InitialConditionSource), 'External')
            ne = ne + 1;
        end
    end
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
        'foundation.electrical.elements.op_amp',              'opamp'
        'foundation.electrical.elements.ideal_transformer',   'idealtransformer'
        'foundation.electrical.elements.mutual_inductor',     'mutualinductor'
        'foundation.electrical.elements.open_circuit',        'opencircuit'
        'foundation.mechanical.translational.inerter',        'translationalinerter'
        'foundation.mechanical.translational.free_end',       'translationalfreeend'
        'foundation.mechanical.rotational.inerter',           'rotationalinerter'
        'foundation.mechanical.rotational.free_end',          'rotationalfreeend'
        'foundation.mechanical.mechanisms.gear_box',          'gearbox'
        'foundation.mechanical.mechanisms.wheel_axle',        'wheelandaxle'
        'foundation.thermal.elements.perfect_insulator',      'perfectinsulator'
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
    unites = tableUnites();
    texte = strtrim(texteParametre(texte, [nom '_unit'], chemin));
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

% Les unités, chacune avec sa grandeur et son facteur vers l'unité SI.
function unites = tableUnites()
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
        'V/(rad/s)', 'E', 1; 'V/rpm', 'E', 30 / pi; 'N*m/A', 'E', 1
        'V/(m/s)', 'Et', 1; 'N/A', 'Et', 1
        's', 's', 1; 'ms', 's', 1e-3; 'us', 's', 1e-6
        'K', 'tK', 1; 'degC', 'tK', 1; 'degF', 'tK', 5 / 9; 'degR', 'tK', 5 / 9
        'W', 'P', 1; 'kW', 'P', 1e3; 'mW', 'P', 1e-3
        'm^2', 'S', 1; 'cm^2', 'S', 1e-4; 'mm^2', 'S', 1e-6
        'W/(m*K)', 'l', 1; 'W/(K*m)', 'l', 1
        'W/(m^2*K)', 'h', 1; 'W/(K*m^2)', 'h', 1
        'J/(kg*K)', 'c', 1; 'J/(K*kg)', 'c', 1; 'kJ/(kg*K)', 'c', 1e3; 'kJ/(K*kg)', 'c', 1e3
        };
end

% Un nombre écrit dans l'unité TEXTE, ramené aux unités SI : A * nombre + B.
% Une température absolue (conversion affine) se décale.
function [a, b] = versSI(texte, affine, chemin)
    texte = strtrim(texteParametre(texte, 'unite', chemin));
    a = 1;
    b = 0;
    if any(strcmp(texte, {'1', ''}))
        return
    end
    unites = tableUnites();
    k = find(strcmp(texte, unites(:, 1)), 1);
    if isempty(k)
        error('Simulink:Parameters:InvParamSetting', ...
              'L''unite ''%s'' de ''%s'' n''est pas connue.', texte, chemin);
    end
    a = unites{k, 3};
    if affine
        switch texte
            case 'degC'
                b = 273.15;
            case 'degF'
                b = 273.15 - 32 * 5 / 9;
        end
    end
end

% --- les réseaux -------------------------------------------------------------

function modele = reseaux(modele)
    modele = signauxPhysiques(modele);
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
        modele = convertisseurs(modele);
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
    % les plus grands réseaux d'abord : c'est leur erreur qui parle le mieux
    % du modèle, avant celle d'un bloc resté seul
    groupes = unique(racines);
    tailles = arrayfun(@(r) sum(racines == r), groupes);
    [~, ordre] = sort(tailles, 'descend');
    for r = groupes(ordre)
        membres = blocsPhysiques(racines == r);
        modele = remplacer(modele, membres, ports, noeud, chemin);
    end
    modele.connexions = zeros(0, 4);
    modele = convertisseurs(modele);
end

% Les blocs de signaux physiques : un signal physique n'est qu'un signal,
% en unités SI ; chacun devient le bloc de Simulink qui calcule la même
% chose, ses paramètres ramenés aux unités SI.
function modele = signauxPhysiques(modele)
    T = tableSignaux();
    nomModele = char(modele.nom);
    for k = 1:numel(modele.blocs)
        bloc = modele.blocs{k};
        if ~any(strcmp(bloc.type, T(:, 1)))
            continue
        end
        chemin = [nomModele '/' bloc.nom];
        p = struct();
        switch bloc.type
            case 'psgain'
                type = 'gain';
                p.Gain = valeurSI(bloc, 'Gain', 1, chemin);
            case {'psadd', 'pssubtract'}
                type = 'sum';
                p.Signs = '++';
                if strcmp(bloc.type, 'pssubtract')
                    p.Signs = '+-';
                end
            case {'psproduct', 'psdivide'}
                type = 'product';
                p.Inputs = '**';
                if strcmp(bloc.type, 'psdivide')
                    p.Inputs = '*/';
                end
            case 'psabs'
                type = 'abs';
            case 'pssign'
                type = 'sign';
            case {'psceil', 'psfloor', 'psround', 'psfix'}
                type = 'rounding';
                p.Operator = bloc.type(3:end);
            case {'psmax', 'psmin'}
                type = 'minmax';
                p.Function = bloc.type(3:end);
                p.Inputs = 2;
            case 'psconstant'
                type = 'constant';
                p.Value = valeurSI(bloc, 'Constant', 1, chemin);
            case 'psmathfunction'
                fonction = choix(bloc, 'Function', 'sin(u)', {'sin(u)', 'cos(u)', 'exp(u)', ...
                                 'log(u)', '10.^u', 'log10(u)', 'u.^2', 'sqrt(u)', '1./u', ...
                                 'tanh(u)', 'u.^v'}, chemin);
                switch fonction
                    case {'sin(u)', 'cos(u)', 'tanh(u)'}
                        type = 'trigonometry';
                        p.Operator = fonction(1:end - 3);
                    case 'sqrt(u)'
                        type = 'sqrt';
                        p.Operator = 'sqrt';
                    case 'u.^v'
                        type = 'matlabfunction';
                        p.Script = sprintf('function y = fcn(u)\ny = u .^ %s;\n', ...
                                           mat2str(valeurParametre(bloc, 'v', 1, chemin), 17));
                    otherwise
                        type = 'math';
                        operateurs = struct('exp', 'exp', 'log', 'log', 'dix', '10^u', ...
                                            'log10', 'log10', 'carre', 'square', ...
                                            'inverse', 'reciprocal');
                        cles = {'exp(u)', 'exp'; 'log(u)', 'log'; '10.^u', 'dix'; ...
                                'log10(u)', 'log10'; 'u.^2', 'carre'; '1./u', 'inverse'};
                        p.Operator = operateurs.(cles{strcmp(fonction, cles(:, 1)), 2});
                end
            case 'psintegrator'
                type = 'integrator';
                p.InitialCondition = valeurSI(bloc, 'InitialCondition', 0, chemin);
                p.ExternalReset = lower(choix(bloc, 'ExternalReset', 'None', ...
                                              {'None', 'Rising', 'Falling', 'Either'}, chemin));
                p.InitialConditionSource = lower(choix(bloc, 'InitialConditionSource', ...
                                                       'Internal', {'Internal', 'External'}, ...
                                                       chemin));
                borne = choix(bloc, 'LimitOutput', 'None', {'None', 'Upper', 'Lower', 'Both'}, ...
                              chemin);
                if strcmp(choix(bloc, 'LimitOutputSource', 'Internal', ...
                                {'Internal', 'External'}, chemin), 'External') && ...
                   ~strcmp(borne, 'None')
                    error('Simulink:Parameters:InvParamSetting', ...
                          ['Les bornes de ''%s'' viennent de ports (LimitOutputSource = ' ...
                           '''External'') : MatLibre ne les prend que du dialogue.'], chemin);
                end
                if ~strcmp(borne, 'None')
                    p.LimitOutput = 'on';
                    p.UpperSaturationLimit = Inf;
                    p.LowerSaturationLimit = -Inf;
                    if any(strcmp(borne, {'Upper', 'Both'}))
                        p.UpperSaturationLimit = valeurSI(bloc, 'UpperLimit', Inf, chemin);
                    end
                    if any(strcmp(borne, {'Lower', 'Both'}))
                        p.LowerSaturationLimit = valeurSI(bloc, 'LowerLimit', -Inf, chemin);
                    end
                end
            case {'pssaturation', 'psdeadzone'}
                haut = valeurSI(bloc, 'UpperLimit', 0.5, chemin);
                bas = valeurSI(bloc, 'LowerLimit', -0.5, chemin);
                if strcmp(bloc.type, 'pssaturation')
                    type = 'saturation';
                    p.UpperLimit = haut;
                    p.LowerLimit = bas;
                else
                    type = 'deadzone';
                    p.UpperValue = haut;
                    p.LowerValue = bas;
                end
                p.ZeroCross = choix(bloc, 'ZeroCross', 'on', {'on', 'off'}, chemin);
            case 'psswitch'
                % la première entrée passe quand la commande atteint le seuil
                type = 'switch';
                p.Threshold = valeurSI(bloc, 'Threshold', 0.5, chemin);
                p.Criteria = 'u2 >= Threshold';
                p.ZeroCross = choix(bloc, 'ZeroCross', 'on', {'on', 'off'}, chemin);
            case 'psconstantdelay'
                type = 'transportdelay';
                p.DelayTime = valeurSI(bloc, 'DelayTime', 1, chemin);
                p.InitialOutput = valeurSI(bloc, 'InputHistory', 0, chemin);
            case 'psterminator'
                type = 'terminator';
            case {'pslookuptable1d', 'pslookuptable2d'}
                type = 'matlabfunction';
                p.Script = scriptTable(bloc, chemin);
                p.SampleTime = -1;
        end
        modele.blocs{k} = remplace(bloc, type, p);
    end
end

% La table d'un PS Lookup Table (1D) ou (2D), vérifiée, et la fonction qui
% la lit.
function script = scriptTable(bloc, chemin)
    deux = strcmp(bloc.type, 'pslookuptable2d');
    if deux
        grilles = {tableau(bloc, 'x1', 1:3, chemin), tableau(bloc, 'x2', 1:4, chemin)};
        valeurs = tableau(bloc, 'f', reshape(1:12, 3, 4), chemin);
        attendue = [numel(grilles{1}), numel(grilles{2})];
    else
        grilles = {tableau(bloc, 'x', 1:5, chemin)};
        valeurs = tableau(bloc, 'f', 0:4, chemin);
        attendue = [1, numel(grilles{1})];
    end
    for i = 1:numel(grilles)
        g = grilles{i};
        if numel(g) < 2 || any(diff(g) <= 0)
            error('Simulink:Parameters:InvParamSetting', ...
                  ['La grille %d de ''%s'' doit compter au moins deux points, rangés en ' ...
                   'ordre strictement croissant.'], i, chemin);
        end
        grilles{i} = g(:).';
    end
    if ~deux
        valeurs = valeurs(:).';
    end
    if ~isequal(size(valeurs), attendue)
        error('Simulink:Parameters:InvParamSetting', ...
              'Les valeurs de ''%s'' sont de taille %s ; ses grilles demandent %s.', chemin, ...
              mat2str(size(valeurs)), mat2str(attendue));
    end
    lisse = strcmp(choix(bloc, 'InterpolationMethod', 'Linear', {'Linear', 'Smooth'}, ...
                         chemin), 'Smooth');
    extrapolation = choix(bloc, 'ExtrapolationMethod', 'Linear', ...
                          {'Linear', 'Nearest', 'Error'}, chemin);
    textes = cellfun(@(g) mat2str(g, 17), grilles, 'UniformOutput', false);
    if deux
        script = sprintf(['function y = fcn(u1, u2)\ny = matlibre_sl_tableps({%s, %s}, ' ...
                          '%s, {u1, u2}, %d, ''%s'', ''%s'');\n'], textes{:}, ...
                         mat2str(valeurs, 17), lisse, extrapolation, strrep(chemin, '''', ''''''));
    else
        script = sprintf(['function y = fcn(u)\ny = matlibre_sl_tableps({%s}, %s, {u}, ' ...
                          '%d, ''%s'', ''%s'');\n'], textes{1}, mat2str(valeurs, 17), lisse, ...
                         extrapolation, strrep(chemin, '''', ''''''));
    end
end

% Un tableau de nombres, dans ses unités.
function v = tableau(bloc, nom, defaut, chemin)
    v = defaut;
    if isfield(bloc.parametres, nom)
        v = bloc.parametres.(nom);
        if ischar(v) || isstring(v)
            if isfield(bloc, 'espace')
                v = matlibre_sl_masque('evaluer', char(v), bloc.espace, chemin, nom);
            else
                v = matlibre_sl_expression(char(v), chemin, nom);
            end
        end
    end
    if ~(isnumeric(v) || islogical(v)) || ~isreal(v) || any(~isfinite(double(v(:))))
        error('Simulink:Parameters:InvParamSetting', ...
              'Le parametre ''%s'' de ''%s'' doit etre un tableau de reels finis.', nom, chemin);
    end
    v = double(v);
    champ = [nom '_unit'];
    if isfield(bloc.parametres, champ)
        v = v * versSI(bloc.parametres.(champ), false, chemin);
    end
end

% Un paramètre d'un bloc de signaux physiques : tel quel s'il n'a pas
% d'unité — une expression s'évaluera avec le bloc qu'il devient —, sinon
% évalué et ramené aux unités SI.
function v = valeurSI(bloc, nom, defaut, chemin)
    v = defaut;
    if isfield(bloc.parametres, nom)
        v = bloc.parametres.(nom);
    end
    champ = [nom '_unit'];
    if isfield(bloc.parametres, champ)
        a = versSI(bloc.parametres.(champ), false, chemin);
        if a ~= 1
            v = a * valeurParametre(bloc, nom, defaut, chemin);
        end
    end
end

% Les convertisseurs : un nombre de Simulink devient un signal physique
% dans l'unité que dit le convertisseur, ramenée ici aux unités SI ; le
% Simulink-PS Converter qui filtre sans commander une source filtre lui-même.
function modele = convertisseurs(modele)
    nomModele = char(modele.nom);
    for k = 1:numel(modele.blocs)
        bloc = modele.blocs{k};
        entrant = strcmp(bloc.type, 'simulinkpsconverter');
        if ~entrant && ~strcmp(bloc.type, 'pssimulinkconverter')
            continue
        end
        chemin = [nomModele '/' bloc.nom];
        affine = strcmp(choix(bloc, 'ApplyAffineConversion', 'off', {'on', 'off'}, chemin), 'on');
        tau = 0;
        ordre = 0;
        if entrant
            [a, b] = versSI(texteDe(bloc, 'InputSignalUnit', '1', chemin), affine, chemin);
            if strcmp(reglageFiltre(bloc, chemin), 'Filter input, derivatives calculated')
                [tau, ordre] = filtreDe(bloc, chemin);
            end
        else
            % le signal physique, en unités SI, rendu dans l'unité de sortie
            [a, b] = versSI(texteDe(bloc, 'OutputSignalUnit', '1', chemin), affine, chemin);
            b = -b / a;
            a = 1 / a;
        end
        if tau > 0
            den = [tau, 1];
            if ordre == 2
                den = conv(den, den);
            end
            modele.blocs{k} = remplace(bloc, 'transferfcn', struct('Numerator', a, ...
                                                                  'Denominator', den));
        elseif a ~= 1
            modele.blocs{k} = remplace(bloc, 'gain', struct('Gain', a));
        elseif b ~= 0
            modele.blocs{k} = remplace(bloc, 'bias', struct('Bias', b));
            continue
        else
            continue
        end
        if b ~= 0
            % le décalage d'une température absolue, après le facteur
            m = numel(modele.blocs) + 1;
            modele.blocs{m} = heriter(struct('type', 'bias', 'nom', [bloc.nom '/decalage'], ...
                                             'parametres', struct('Bias', b)), bloc);
            liens = matlibre_sl_liens(modele);
            sortants = liens(:, 1) == k;
            liens(sortants, 1) = m;
            modele.liens = [liens; k, m, 1, 1];
        end
    end
end

function v = texteDe(bloc, nom, defaut, chemin)
    v = defaut;
    if isfield(bloc.parametres, nom)
        v = texteParametre(bloc.parametres.(nom), nom, chemin);
    end
end

% Un paramètre qui se donne par un texte : une ligne de caractères, ou une
% chaîne.
function t = texteParametre(v, nom, chemin)
    if isstring(v) && isscalar(v)
        v = char(v);
    end
    if ~ischar(v) || (~isempty(v) && size(v, 1) ~= 1)
        error('Simulink:Parameters:InvParamSetting', ...
              'Le parametre ''%s'' de ''%s'' doit etre un texte.', nom, chemin);
    end
    t = v;
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
    if numel(config) == numel(membres)
        error('Simscape:Network:SolverConfigurationNotConnected', ...
              ['Le bloc Solver Configuration %s n''est relie a aucun element physique : ' ...
               'reliez son port a un noeud du reseau qu''il regle.'], noms);
    end
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
                'sorties', {}, 'position', {}, 'mp', {}, 'mn', {}, 'matrice', {}, ...
                'initial2', {}, 'filtre', {}, 'ordre', {}, 'constant', {}, 'amont', {});
    for k = membres
        type = modele.blocs{k}.type;
        ligne = entreeDe(type);
        if any(strcmp(ligne{2}, {'reference', 'config'}))
            continue
        end
        e = struct('bloc', k, 'type', type, 'comportement', ligne{2}, 'p', numero(k, 1), ...
                   'n', 0, 'valeur', 0, 'r', 0, 'g', 0, 'initial', 0, 'signe', 1, ...
                   'sorties', ligne{6}, 'position', 0, 'mp', 0, 'mn', 0, 'matrice', [], ...
                   'initial2', 0, 'filtre', 0, 'ordre', 0, 'constant', false, 'amont', 0);
        switch ligne{2}
            case {'convertisseur', 'mutuelle', 'vcvs', 'ccvs'}
                % deux couples de ports : +, - à gauche ; +, - (ou R, C) à droite
                e.n = numero(k, 2);
                e.mp = numero(k, -1);
                e.mn = numero(k, -2);
            case 'ampliOp'
                % +, - à gauche, la sortie à droite
                e.n = numero(k, 2);
                e.mp = numero(k, -1);
            case 'reducteur'
                % un arbre de chaque côté, chacun rapporté à la référence
                e.mp = numero(k, -1);
            otherwise
                if ligne{4} >= 1
                    e.n = numero(k, -1);
                end
        end
        e = lireElement(modele.blocs{k}, e, chemin(k));
        if ligne{5} > 0
            e = lireCommande(modele, k, e, chemin);
            if e.amont > 0 && (e.filtre > 0 || e.constant)
                % le filtre vit dans le réseau : le convertisseur ne fait
                % plus que passer le signal
                modele.blocs{e.amont}.parametres.FilteringAndDerivatives = 'Provide signals';
            end
        end
        el(end + 1) = e; %#ok<AGROW>
    end
    comportements = {el.comportement};
    % les inconnues de branche : sources « à travers », capacités, capteurs
    % de grandeur traversante, convertisseurs, réducteurs, amplificateurs
    % opérationnels, sources de tension commandées (deux pour celle qu'un
    % courant commande : le courant mesuré, puis la sortie)
    nbBranches = double(ismember(comportements, {'sourceAcross', 'capacite', ...
        'capteurThrough', 'convertisseur', 'reducteur', 'ampliOp', 'vcvs'}));
    nbBranches(strcmp(comportements, 'ccvs')) = 2;
    premiere = nn + cumsum([0, nbBranches(1:end - 1)]) + 1;
    nb = sum(nbBranches);
    branche = @(i) premiere(i);
    capacites = find(strcmp(comportements, 'capacite'));
    inductances = find(strcmp(comportements, 'inductance'));
    mutuelles = find(strcmp(comportements, 'mutuelle'));
    sources = find(ismember(comportements, {'sourceAcross', 'sourceThrough'}));
    filtres = sources([el(sources).ordre] > 0);
    capteurs = find(ismember(comportements, {'capteurAcross', 'capteurThrough'}));
    mouvements = capteurs([el(capteurs).sorties] == 2);   % une position à intégrer
    % les états : tensions des capacités, courants des inductances, deux
    % courants par paire d'inductances couplées, sorties des filtres des
    % commandes et leurs dérivées
    colonneEtat = zeros(1, numel(el));
    colonneEtat(capacites) = 1:numel(capacites);
    colonneEtat(inductances) = numel(capacites) + (1:numel(inductances));
    suivant = numel(capacites) + numel(inductances);
    for i = mutuelles
        colonneEtat(i) = suivant + 1;
        suivant = suivant + 2;
    end
    colonneFiltre = zeros(1, numel(el));
    for i = filtres
        colonneFiltre(i) = suivant + 1;
        suivant = suivant + el(i).ordre;
    end
    nx = suivant;
    nu = numel(sources);
    % M z = N w, avec z = [grandeurs des nœuds ; grandeurs des branches] et
    % w = [états ; entrées]
    M = zeros(nn + nb);
    N = zeros(nn + nb, nx + nu);
    colonneEntree = zeros(1, numel(el));
    colonneEntree(sources) = nx + (1:nu);
    % ce que reçoit une source : son entrée, ou la sortie de son filtre
    commande = colonneEntree;
    commande(filtres) = colonneFiltre(filtres);
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
                N = injection(N, p, -e.signe, commande(i));
                N = injection(N, q, e.signe, commande(i));
            case 'inductance'
                M = conductance(M, p, q, e.g);
                N = injection(N, p, -1, colonneEtat(i));
                N = injection(N, q, 1, colonneEtat(i));
            case 'mutuelle'
                % deux courants, chacun du + au - de son enroulement
                N = injection(N, p, -1, colonneEtat(i));
                N = injection(N, q, 1, colonneEtat(i));
                N = injection(N, e.mp, -1, colonneEtat(i) + 1);
                N = injection(N, e.mn, 1, colonneEtat(i) + 1);
            case {'capteurAcross', 'libre'}
            case {'convertisseur', 'reducteur'}
                % v(+) - v(-) = K (w(R) - w(C)) ; le couple K i pousse R
                b = branche(i);
                M = incidence(M, p, q, b);
                M = colonne(M, b, e.mp, -e.valeur);
                M = colonne(M, b, e.mn, e.valeur);
                M = ligneEntree(M, e.mp, b, -e.valeur);
                M = ligneEntree(M, e.mn, b, e.valeur);
            case 'ampliOp'
                % v(+) = v(-), sans courant d'entrée ; le courant de sortie
                % vient de la référence
                b = branche(i);
                M = colonne(M, b, p, 1);
                M = colonne(M, b, q, -1);
                M = ligneEntree(M, e.mp, b, -1);
            case 'vcvs'
                % v(+2) - v(-2) = K (v(+) - v(-))
                b = branche(i);
                M = incidence(M, e.mp, e.mn, b);
                M = colonne(M, b, p, -e.valeur);
                M = colonne(M, b, q, e.valeur);
            case 'ccvs'
                % le courant mesuré va du + au - sous une tension nulle ;
                % v(+2) - v(-2) = K i
                b = branche(i);
                M = incidence(M, p, q, b);
                M = incidence(M, e.mp, e.mn, b + 1);
                M(b + 1, b) = M(b + 1, b) - e.valeur;
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
                        N(b, commande(i)) = e.signe;
                end
        end
    end
    if any(~isfinite(M(:)))
        error('Simscape:Network:SingularNetwork', ...
              ['Les equations du reseau de %s n''ont pas de solution unique : un noeud ' ...
               'flotte, sans chemin vers la reference, ou des sources et des elements ' ...
               'a etat forment une boucle.'], noms);
    end
    if ~isempty(M) && rcond(M) < 1e-13
        % des éléments à état solidaires : leurs états ne sont pas tous libres
        constantes = [el(sources).constant];
        [A, B, C, D, X0] = reseauSingulier(M, N, el, branche, colonneEtat, capacites, ...
            inductances, mutuelles, filtres, colonneFiltre, colonneEntree, capteurs, ...
            constantes, nx, nu, noms);
        modele = reecrire(modele, config, el, sources, capteurs, A, B, C, D, X0, membres, ...
                          chemin);
        return
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
    for i = mutuelles
        % [v1 ; v2] = [L1 M ; M L2] d[i1 ; i2]/dt
        k = colonneEtat(i);
        v = [ligne(el(i).p) - ligne(el(i).n); ligne(el(i).mp) - ligne(el(i).mn)];
        F(k:k + 1, :) = el(i).matrice \ v;
        X0(k:k + 1) = [el(i).initial; el(i).initial2];
    end
    F = filtrage(F, el, filtres, colonneFiltre, colonneEntree);
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

% La commande d'une source : le Simulink-PS Converter qui la donne peut la
% filtrer — le réseau reçoit alors la sortie du filtre, et ses dérivées
% quand il en a besoin — ou la dire constante par morceaux.
function e = lireCommande(modele, k, e, chemin)
    liens = matlibre_sl_liens(modele);
    l = find(liens(:, 2) == k & liens(:, 3) == 1, 1);
    if isempty(l)
        return
    end
    amont = liens(l, 1);
    bloc = modele.blocs{amont};
    if ~strcmp(bloc.type, 'simulinkpsconverter')
        return
    end
    e.amont = amont;
    switch reglageFiltre(bloc, chemin(amont))
        case 'Filter input, derivatives calculated'
            [e.filtre, e.ordre] = filtreDe(bloc, chemin(amont));
        case 'Zero derivatives (piecewise constant)'
            e.constant = true;
    end
end

function mode = reglageFiltre(bloc, chemin)
    mode = choix(bloc, 'FilteringAndDerivatives', 'Provide signals', ...
                 {'Provide signals', 'Filter input, derivatives calculated', ...
                  'Zero derivatives (piecewise constant)'}, chemin);
    fournis = choix(bloc, 'ProvidedSignals', 'Input only', {'Input only', ...
                    'Input and first derivative', 'Input and first two derivatives'}, chemin);
    if strcmp(mode, 'Provide signals') && ~strcmp(fournis, 'Input only')
        error('Simulink:Parameters:InvParamSetting', ...
              ['''%s'' fournit les derivees de son entree par des ports (ProvidedSignals ' ...
               '= ''%s'') : MatLibre ne les prend pas ; filtrez l''entree ' ...
               '(FilteringAndDerivatives = ''Filter input, derivatives calculated'').'], ...
              chemin, fournis);
    end
end

function [tau, ordre] = filtreDe(bloc, chemin)
    tau = positif(bloc, 'InputFilterTimeConstant', 0.001, 's', chemin);
    ordre = 1 + strcmp(choix(bloc, 'SimscapeFilterOrder', 'First-order filtering', ...
                             {'First-order filtering', 'Second-order filtering'}, chemin), ...
                       'Second-order filtering');
end

% Un réglage à choisir dans une liste, sans égard à la casse.
function v = choix(bloc, nom, defaut, liste, chemin)
    v = defaut;
    if isfield(bloc.parametres, nom)
        v = texteParametre(bloc.parametres.(nom), nom, chemin);
    end
    k = find(strcmpi(v, liste), 1);
    if isempty(k)
        error('Simulink:Parameters:InvParamSetting', ...
              'Le parametre ''%s'' de ''%s'' vaut ''%s'' ; il doit valoir %s.', nom, chemin, ...
              v, strjoin(cellfun(@(x) ['''' x ''''], liste, 'UniformOutput', false), ', '));
    end
    v = liste{k};
end

% Les filtres des commandes : tau f' + f = u, ou, au second ordre,
% tau^2 f'' + 2 tau f' + f = u, dont f et f' sont les états.
function F = filtrage(F, el, filtres, colonneFiltre, colonneEntree)
    for i = filtres
        k = colonneFiltre(i);
        u = colonneEntree(i);
        tau = el(i).filtre;
        if el(i).ordre == 1
            F(k, k) = F(k, k) - 1 / tau;
            F(k, u) = F(k, u) + 1 / tau;
        else
            F(k, k + 1) = F(k, k + 1) + 1;
            F(k + 1, k) = F(k + 1, k) - 1 / tau^2;
            F(k + 1, k + 1) = F(k + 1, k + 1) - 2 / tau;
            F(k + 1, u) = F(k + 1, u) + 1 / tau^2;
        end
    end
end

% --- les éléments à état solidaires ---------------------------------------------
%
% Deux inerties sur un même arbre, deux masses thermiques sur un même nœud,
% un ressort dont un bout est libre, des inductances couplées dont un
% enroulement est ouvert : les équations algébriques du réseau deviennent
% singulières, car les états de ces éléments ne sont plus indépendants. Le
% système algébro-différentiel
%     M z = Ns s + Nu u,   s' = Gz z + Gs s + Gu u,   y = Hz z + Hs s
% se ramène alors à une représentation d'état : on élimine, pas à pas, les
% contraintes que les équations algébriques imposent aux états, en ne
% gardant que les combinaisons d'états qu'elles laissent libres.

function [A, B, C, D, X0] = reseauSingulier(M, N, el, branche, colonneEtat, capacites, ...
        inductances, mutuelles, filtres, colonneFiltre, colonneEntree, capteurs, ...
        constantes, nx, nu, noms)
    nz = size(M, 1);
    mouvements = capteurs([el(capteurs).sorties] == 2);
    np = numel(mouvements);
    ns = nx + np;
    unitaire = @(j) double((1:nz) == j);
    Gz = zeros(ns, nz);
    Gs = zeros(ns, ns);
    s0 = zeros(ns, 1);
    % le poids de chaque état dans le compromis des états initiaux : sa
    % capacité, son inductance — l'inertie de deux arbres solidaires part
    % avec leur moment cinétique commun
    poids = ones(ns, 1);
    for i = capacites
        k = colonneEtat(i);
        Gz(k, branche(i)) = 1 / el(i).valeur;
        s0(k) = el(i).initial;
        poids(k) = el(i).valeur;
    end
    for i = inductances
        k = colonneEtat(i);
        Gz(k, :) = (unitaire(el(i).p) - unitaire(el(i).n)) / el(i).valeur;
        Gs(k, k) = -el(i).r / el(i).valeur;
        s0(k) = el(i).initial;
        poids(k) = el(i).valeur;
    end
    for i = mutuelles
        k = colonneEtat(i);
        Gz(k:k + 1, :) = el(i).matrice \ [unitaire(el(i).p) - unitaire(el(i).n); ...
                                          unitaire(el(i).mp) - unitaire(el(i).mn)];
        s0(k:k + 1) = [el(i).initial; el(i).initial2];
        poids(k:k + 1) = diag(el(i).matrice);
    end
    Gw = filtrage(zeros(nx, nx + nu), el, filtres, colonneFiltre, colonneEntree);
    Gs(1:nx, 1:nx) = Gs(1:nx, 1:nx) + Gw(:, 1:nx);
    Gu = [Gw(:, nx + 1:end); zeros(np, nu)];
    % les capteurs ; une position est un état de plus, l'intégrale d'une vitesse
    ny = sum([el(capteurs).sorties]);
    Hz = zeros(ny, nz);
    Hs = zeros(ny, ns);
    l = 0;
    jp = 0;
    for j = 1:numel(capteurs)
        i = capteurs(j);
        l = l + 1;
        if strcmp(el(i).comportement, 'capteurAcross')
            Hz(l, :) = unitaire(el(i).p) - unitaire(el(i).n);
            if el(i).sorties == 2
                jp = jp + 1;
                Gz(nx + jp, :) = Hz(l, :);
                s0(nx + jp) = el(i).position;
                l = l + 1;
                Hs(l, nx + jp) = 1;
            end
        else
            Hz(l, :) = unitaire(branche(i));
        end
    end
    [A, B, C, D, X0, ecart] = reduire(M, [N(:, 1:nx), zeros(nz, np)], N(:, nx + 1:end), ...
                                      Gz, Gs, Gu, Hz, Hs, s0, poids, constantes, noms);
    if ecart > 1e-6 * max(1, norm(s0))
        warning('Simscape:Network:InconsistentInitialConditions', ...
                ['Les etats initiaux des elements de %s se contredisent : des elements ' ...
                 'solidaires (deux inerties sur un meme arbre, deux masses thermiques sur ' ...
                 'un meme noeud) n''ont qu''un etat a eux deux. Il prend la moyenne des ' ...
                 'valeurs donnees, ponderee par leurs inerties, masses ou capacites.'], noms);
    end
end

function [A, B, C, D, x0, ecart] = reduire(M, Ns, Nu, Gz, Gs, Gu, Hz, Hs, s0, poids, ...
                                          constantes, noms)
    nz = size(M, 1);
    ns = size(Gs, 1);
    nu = size(Nu, 2);
    % E w' = Aw w + Bw u, y = Cw w, avec w = [z ; s]
    E = blkdiag(zeros(nz), eye(ns));
    Aw = [-M, Ns; Gz, Gs];
    Bw = [Nu; Gu];
    Cw = [Hz, Hs];
    T = eye(nz + ns);                 % w = T w' + Tu u, w' les inconnues courantes
    Tu = zeros(nz + ns, nu);
    echelle = max(1, norm(Aw, 1));
    echelleU = max(1, norm(Bw, 1));
    for tour = 1:nz + ns + 1 %#ok<FXUP>
        n = size(E, 2);
        % les directions de E : V pour ses lignes, U pour ses colonnes
        [~, S, V] = svd(E);
        [~, ~, U] = svd(E');
        sv = diag(S);
        r = sum(sv > 1e-9);
        U1 = U(:, 1:r);
        U2 = U(:, r + 1:end);
        V1 = V(:, 1:r);
        V2 = V(:, r + 1:end);
        E11 = U1' * E * V1;
        A11 = U1' * Aw * V1;
        A12 = U1' * Aw * V2;
        A21 = U2' * Aw * V1;
        A22 = U2' * Aw * V2;
        B1 = U1' * Bw;
        B2 = U2' * Bw;
        m2 = n - r;
        rho = 0;
        if m2 > 0
            [~, SA, UA] = svd(A22');   % UA : les directions des colonnes de A22
            sa = diag(SA);
            rho = sum(sa > max(1e-12 * max(sa), 1e-14 * echelle));
        end
        if rho == m2
            % les inconnues algébriques s'expriment par les états : c'est fini
            X = zeros(m2, r);
            Y = zeros(m2, nu);
            if m2 > 0
                X = -(A22 \ A21);
                Y = -(A22 \ B2);
            end
            A = E11 \ (A11 + A12 * X);
            B = E11 \ (B1 + A12 * Y);
            Tf = T * (V1 + V2 * X);
            Tuf = Tu + T * (V2 * Y);
            C = Cw * Tf;
            D = Cw * Tuf;
            Ts = Tf(nz + 1:end, :);
            x0 = zeros(r, 1);
            if r > 0
                % l'état le plus proche des valeurs données, chacune pesant
                % ce que pèse son élément
                racines = diag(sqrt(poids));
                x0 = pinv(racines * Ts) * (racines * s0);
            end
            ecart = norm(Ts * x0 - s0);
            return
        end
        % des combinaisons d'équations algébriques qui ne voient pas les
        % inconnues algébriques : des contraintes sur les états
        P = UA(:, rho + 1:end)';
        Q = UA(:, 1:rho)';
        K = P * A21;
        Kb = P * B2;
        sk = svd(K);
        rk = sum(sk > 1e-9 * max(1, norm(A21, 1)));
        if rk < size(P, 1)
            error('Simscape:Network:SingularNetwork', ...
                  ['Les equations du reseau de %s n''ont pas de solution unique : un noeud ' ...
                   'flotte, sans chemin vers la reference, ou des sources et des elements ' ...
                   'a etat forment une boucle.'], noms);
        end
        imposees = any(abs(Kb) > 1e-9 * echelleU, 1);
        if any(imposees & ~constantes)
            error('Simscape:Network:SingularNetwork', ...
                  ['Dans le reseau de %s, une source impose l''etat d''un element — une ' ...
                   'source de tension aux bornes d''un condensateur ideal, une source de ' ...
                   'vitesse sur une masse — : il faudrait deriver sa commande. Filtrez-la ' ...
                   'dans son Simulink-PS Converter (FilteringAndDerivatives), ou ajoutez ' ...
                   'une resistance ou un amortisseur en serie.'], noms);
        end
        % les états qui respectent les contraintes : a = Nk c + a0 u, u étant
        % constante par morceaux quand une contrainte la voit
        [~, ~, VK] = svd(K);
        Nk = VK(:, rk + 1:end);
        a0 = -pinv(K) * Kb;
        E = [E11 * Nk, zeros(r, m2); zeros(rho, size(Nk, 2) + m2)];
        Aw = [A11 * Nk, A12; Q * A21 * Nk, Q * A22];
        Bw = [B1 + A11 * a0; Q * B2 + Q * A21 * a0];
        Tu = Tu + T * (V1 * a0);
        T = T * [V1 * Nk, V2];
    end
    error('Simscape:Network:SingularNetwork', ...
          ['Les equations du reseau de %s n''ont pas de solution unique : un noeud ' ...
           'flotte, sans chemin vers la reference, ou des sources et des elements ' ...
           'a etat forment une boucle.'], noms);
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
        case 'idealtransformer'
            % v1 = N v2 ; le courant N i1 sort par le + du secondaire
            e.valeur = positifSansUnite(bloc, 'n', 1, chemin);
        case 'mutualinductor'
            L1 = positif(bloc, 'L1', 10, 'H', chemin);
            L2 = positif(bloc, 'L2', 0.1, 'H', chemin);
            k = valeurParametre(bloc, 'k', 0.9, chemin);
            if ~(k > 0 && k < 1)
                error('Simulink:Parameters:InvParamSetting', ...
                      ['Le coefficient de couplage ''k'' de ''%s'' vaut %s : il doit etre ' ...
                       'strictement entre 0 et 1.'], chemin, mat2str(k, 6));
            end
            mutuelle = k * sqrt(L1 * L2);
            e.matrice = [L1, mutuelle; mutuelle, L2];
            e.initial = nombre(bloc, 'i1', 0, 'A', chemin);
            e.initial2 = nombre(bloc, 'i2', 0, 'A', chemin);
        case 'voltagecontrolledvoltagesource'
            e.valeur = valeurParametre(bloc, 'K', 1, chemin);
        case 'currentcontrolledvoltagesource'
            e.valeur = nombre(bloc, 'K', 1, 'Ohm', chemin);
        case 'translationalelectromechanicalconverter'
            e.valeur = nombre(bloc, 'K', 0.1, 'V/(m/s)', chemin);
        case 'translationalinerter'
            e.valeur = positif(bloc, 'B', 1, 'kg', chemin);
            e.initial = nombre(bloc, 'v', 0, 'm/s', chemin);
        case 'rotationalinerter'
            e.valeur = positif(bloc, 'B', 1, 'kg*m^2', chemin);
            e.initial = nombre(bloc, 'w', 0, 'rad/s', chemin);
        case 'gearbox'
            % w(S) = N w(O) ; le couple de sortie vaut N fois celui d'entrée
            e.valeur = valeurParametre(bloc, 'ratio', 5, chemin);
            if e.valeur == 0
                error('Simulink:Parameters:InvParamSetting', ...
                      'Le rapport ''ratio'' de ''%s'' ne peut pas etre nul.', chemin);
            end
        case 'wheelandaxle'
            % v(P) = r w(A) or : w(A) = v(P) / (r or)
            rayon = positif(bloc, 'radius', 0.05, 'm', chemin);
            sens = 1;
            if strcmp(choix(bloc, 'orientation', 'Drives in positive direction', ...
                            {'Drives in positive direction', ...
                             'Drives in negative direction'}, chemin), ...
                      'Drives in negative direction')
                sens = -1;
            end
            e.valeur = 1 / (rayon * sens);
    end
end

function v = positifSansUnite(bloc, nom, defaut, chemin)
    v = valeurParametre(bloc, nom, defaut, chemin);
    if ~(v > 0)
        error('Simulink:Parameters:InvParamSetting', ...
              'Le parametre ''%s'' de ''%s'' vaut %s : il doit etre positif.', nom, chemin, ...
              mat2str(v, 6));
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
        if ~isempty(ligne) && ligne{5} == 0 && ligne{6} == 0 && ~strcmp(ligne{2}, 'config')
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
