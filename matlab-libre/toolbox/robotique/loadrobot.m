function [robot, donnees] = loadrobot(nom, varargin)
%LOADROBOT Charge un modèle de robot du catalogue.
%   ROBOT = LOADROBOT(NOM) rend un RIGIDBODYTREE monté d'après les
%   paramètres de Denavit-Hartenberg publiés pour ce robot.
%   [ROBOT,DONNEES] = LOADROBOT(...) rend aussi une structure décrivant
%   la source des paramètres et la configuration de repos.
%   LOADROBOT(...,'DataFormat',F,'Gravity',G) règle l'arbre.
%
%   Modèles disponibles :
%      'universalUR3', 'universalUR5', 'universalUR10'
%                          - les trois bras à six axes d'Universal Robots
%      'puma560'           - le Unimation PUMA 560, six axes
%      'stanfordArm'       - le bras de Stanford, cinq rotoïdes et une
%                            prismatique
%      'scara'             - un SCARA à quatre axes
%      'planarArm2R', 'planarArm3R'
%                          - les bras plans du cours
%
%   LOADROBOT('list') rend la liste des noms.
%
%   Les longueurs viennent des tables publiées par les constructeurs ou
%   des manuels de robotique. Les masses sont celles annoncées quand elles
%   le sont ; les inerties, faute de chiffres publics, sont celles d'une
%   barre homogène de la longueur du segment. La cinématique est donc
%   exacte, la dynamique seulement plausible — ce qui suffit à éprouver un
%   algorithme, non à régler un robot réel.
%
%   Exemple :
%      robot = loadrobot('universalUR5', 'DataFormat', 'row');
%      showdetails(robot);
%      T = getTransform(robot, homeConfiguration(robot), 'outil');
%
%   Voir aussi IMPORTROBOT, RIGIDBODYTREE, INVERSEKINEMATICS.
    catalogue = {'universalUR3', 'universalUR5', 'universalUR10', 'puma560', ...
                 'stanfordArm', 'scara', 'planarArm2R', 'planarArm3R'};
    if nargin == 0 || strcmpi(nom, 'list')
        robot = catalogue;
        donnees = struct('Source', 'catalogue', 'Modeles', {catalogue});
        return
    end
    format = 'struct';
    pesanteur = [0 0 0];
    for k = 1:2:numel(varargin)
        switch validatestring(varargin{k}, {'DataFormat', 'Gravity'}, 'loadrobot')
            case 'DataFormat'
                format = varargin{k+1};
            case 'Gravity'
                pesanteur = double(varargin{k+1}(:)).';
        end
    end
    nom = char(nom);
    position = find(strcmpi(catalogue, nom), 1);
    if isempty(position)
        error('robotics:loadrobot:Inconnu', ...
              'Modele inconnu : « %s ». LOADROBOT(''list'') donne la liste.', nom);
    end
    nom = catalogue{position};
    % Chaque modèle se décrit par ses paramètres de Denavit-Hartenberg
    % standard, une ligne [a alpha d theta] par axe, et par les masses et
    % les types de liaison correspondants.
    types = {};
    switch nom
        case 'universalUR3'
            dh = [0, pi/2, 0.1519, 0; -0.24365, 0, 0, 0; -0.21325, 0, 0, 0; ...
                  0, pi/2, 0.11235, 0; 0, -pi/2, 0.08535, 0; 0, 0, 0.0819, 0];
            masses = [2.0 3.42 1.26 0.8 0.8 0.35];
            source = 'table de parametres publiee par Universal Robots';
        case 'universalUR5'
            dh = [0, pi/2, 0.089159, 0; -0.425, 0, 0, 0; -0.39225, 0, 0, 0; ...
                  0, pi/2, 0.10915, 0; 0, -pi/2, 0.09465, 0; 0, 0, 0.0823, 0];
            masses = [3.7 8.393 2.275 1.219 1.219 0.1879];
            source = 'table de parametres publiee par Universal Robots';
        case 'universalUR10'
            dh = [0, pi/2, 0.1273, 0; -0.612, 0, 0, 0; -0.5723, 0, 0, 0; ...
                  0, pi/2, 0.163941, 0; 0, -pi/2, 0.1157, 0; 0, 0, 0.0922, 0];
            masses = [7.1 12.7 4.27 2.0 2.0 0.365];
            source = 'table de parametres publiee par Universal Robots';
        case 'puma560'
            dh = [0, pi/2, 0, 0; 0.4318, 0, 0, 0; 0.0203, -pi/2, 0.15005, 0; ...
                  0, pi/2, 0.4318, 0; 0, -pi/2, 0, 0; 0, 0, 0, 0];
            masses = [0 17.4 4.8 0.82 0.34 0.09];
            source = 'parametres du PUMA 560 des manuels de robotique';
        case 'stanfordArm'
            dh = [0, -pi/2, 0.412, 0; 0, pi/2, 0.154, 0; 0, 0, 0, 0; ...
                  0, -pi/2, 0, 0; 0, pi/2, 0, 0; 0, 0, 0.263, 0];
            types = {'revolute', 'revolute', 'prismatic', ...
                     'revolute', 'revolute', 'revolute'};
            masses = [9.29 5.01 4.25 1.08 0.63 0.51];
            source = 'parametres du bras de Stanford des manuels de robotique';
        case 'scara'
            dh = [0.325, 0, 0.2, 0; 0.275, pi, 0, 0; 0, 0, 0, 0; 0, 0, 0, 0];
            types = {'revolute', 'revolute', 'prismatic', 'revolute'};
            masses = [3.0 2.0 1.0 0.3];
            source = 'geometrie type d''un SCARA a quatre axes';
        case 'planarArm2R'
            dh = [1, 0, 0, 0; 1, 0, 0, 0];
            masses = [1 1];
            source = 'bras plan a deux segments du cours';
        case 'planarArm3R'
            dh = [1, 0, 0, 0; 0.7, 0, 0, 0; 0.4, 0, 0, 0];
            masses = [1 0.7 0.4];
            source = 'bras plan a trois segments du cours';
    end
    n = size(dh, 1);
    if isempty(types)
        types = repmat({'revolute'}, 1, n);
    end
    robot = rigidBodyTree('DataFormat', format);
    robot.Gravity = pesanteur;
    parent = robot.BaseName;
    for k = 1:n
        nomCorps = sprintf('corps%d', k);
        b = rigidBody(nomCorps);
        jnt = rigidBodyJoint(sprintf('j%d', k), types{k});
        setFixedTransform(jnt, dh(k, :), 'dh');
        if strcmp(types{k}, 'prismatic')
            jnt.PositionLimits = [0 0.5];
        else
            jnt.PositionLimits = [-pi pi];
        end
        b.Joint = jnt;
        b.Mass = masses(k);
        % Faute d'inerties publiées, on prend celles d'une barre homogène
        % de la longueur du segment : le centre de masse au milieu, et le
        % moment m L^2 / 12 autour des deux axes transverses.
        longueur = max(abs(dh(k, 1)), abs(dh(k, 3)));
        b.CenterOfMass = [-dh(k, 1) / 2, 0, -dh(k, 3) / 2];
        transverse = masses(k) * longueur ^ 2 / 12;
        b.Inertia = [transverse, transverse, transverse / 10, 0, 0, 0];
        addBody(robot, b, parent);
        parent = nomCorps;
    end
    % Un corps terminal sans masse marque l'effecteur : c'est là qu'on
    % lit la pose et qu'on résout la cinématique inverse.
    outil = rigidBody('outil');
    outil.Mass = 0;
    outil.Inertia = zeros(1, 6);
    addBody(robot, outil, parent);
    donnees = struct('Name', nom, 'Source', source, ...
                     'DH', dh, 'JointTypes', {types}, ...
                     'HomeConfiguration', homeConfiguration(robot));
end
