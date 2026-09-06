function robot = importrobot(source, varargin)
%IMPORTROBOT Construit un arbre de corps rigides à partir d'un URDF.
%   ROBOT = IMPORTROBOT(CHEMIN) lit le fichier URDF et rend un
%   RIGIDBODYTREE.
%   ROBOT = IMPORTROBOT(TEXTE) accepte aussi le contenu du fichier.
%   ROBOT = IMPORTROBOT(...,'DataFormat',F) fixe le format des
%   configurations, 'struct' par défaut.
%
%   Sont lus : les liaisons — revolute, continuous, prismatic, fixed —,
%   leurs axes, leurs butées, la transformation d'origine avec ses angles
%   de roulis-tangage-lacet, et les masses, centres de masse et inerties
%   déclarés dans les balises « inertial ».
%
%   Une liaison « continuous » devient une rotoïde sans butée : c'est ce
%   que le format veut dire, et l'arbre n'a pas d'autre type pour cela.
%
%   Ce qui n'est pas lu — la géométrie visuelle, les collisions, les
%   matériaux, les transmissions — ne sert ni à la cinématique ni à la
%   dynamique, qui sont ce que l'arbre calcule.
%
%   Exemple :
%      robot = importrobot('bras.urdf');
%      showdetails(robot);
%      getTransform(robot, homeConfiguration(robot), 'outil')
%
%   Voir aussi RIGIDBODYTREE, LOADROBOT, ADDBODY.
    format = 'struct';
    for k = 1:2:numel(varargin)
        if strcmpi(varargin{k}, 'DataFormat')
            format = varargin{k+1};
        end
    end
    if isa(source, 'rigidBodyTree')
        robot = source;
        return
    end
    texte = char(source);
    if ~contains(texte, '<') && exist(texte, 'file')
        identifiant = fopen(texte, 'r');
        if identifiant < 0
            error('robotics:importrobot:Fichier', ...
                  'Impossible d''ouvrir « %s ».', texte);
        end
        texte = fread(identifiant, inf, '*char').';
        fclose(identifiant);
    end
    noeuds = matlibre_rob_xml(texte);
    racine = [];
    for k = 1:numel(noeuds)
        if strcmpi(noeuds(k).Nom, 'robot')
            racine = noeuds(k);
        end
    end
    if isempty(racine)
        error('robotics:importrobot:SansRobot', ...
              'Le document ne contient pas de balise « robot ».');
    end
    % Les corps d'abord, les liaisons ensuite : un URDF les donne dans un
    % ordre quelconque, et une liaison nomme deux corps qui doivent déjà
    % exister.
    corps = struct('nom', {}, 'masse', {}, 'centre', {}, 'inertie', {});
    liaisons = struct('nom', {}, 'type', {}, 'parent', {}, 'enfant', {}, ...
                      'origine', {}, 'axe', {}, 'butees', {});
    for k = 1:numel(racine.Enfants)
        e = racine.Enfants(k);
        switch lower(e.Nom)
            case 'link'
                corps(end+1) = lireCorps(e);        %#ok<AGROW>
            case 'joint'
                liaisons(end+1) = lireLiaison(e);   %#ok<AGROW>
        end
    end
    nomsCorps = {corps.nom};
    enfants = {liaisons.enfant};
    base = '';
    for k = 1:numel(nomsCorps)
        if ~any(strcmp(enfants, nomsCorps{k}))
            base = nomsCorps{k};
            break
        end
    end
    if isempty(base)
        error('robotics:importrobot:SansBase', ...
              'Aucun corps ne sert de base : le graphe n''est pas un arbre.');
    end
    robot = rigidBodyTree('DataFormat', format, 'BaseName', base);
    % On attache les corps dans l'ordre où leur parent devient disponible.
    poses = {base};
    restantes = true(1, numel(liaisons));
    while any(restantes)
        avance = false;
        for k = find(restantes)
            L = liaisons(k);
            if ~any(strcmp(poses, L.parent))
                continue
            end
            indice = find(strcmp(nomsCorps, L.enfant), 1);
            b = rigidBody(L.enfant);
            typeArbre = 'fixed';
            switch lower(L.type)
                case {'revolute', 'continuous'}
                    typeArbre = 'revolute';
                case 'prismatic'
                    typeArbre = 'prismatic';
            end
            jnt = rigidBodyJoint(L.nom, typeArbre);
            if ~strcmp(typeArbre, 'fixed')
                jnt.JointAxis = L.axe;
                jnt.PositionLimits = L.butees;
            end
            jnt.JointToParentTransform = L.origine;
            b.Joint = jnt;
            if ~isempty(indice)
                b.Mass = corps(indice).masse;
                b.CenterOfMass = corps(indice).centre;
                b.Inertia = corps(indice).inertie;
            end
            addBody(robot, b, L.parent);
            poses{end+1} = L.enfant;   %#ok<AGROW>
            restantes(k) = false;
            avance = true;
        end
        if ~avance
            error('robotics:importrobot:Cycle', ...
                  'Les liaisons ne forment pas un arbre depuis « %s ».', base);
        end
    end
end

function c = lireCorps(noeud)
%LIRECORPS Masse, centre de masse et inertie d'une balise « link ».
    c = struct('nom', noeud.Attributs.name, 'masse', 0, ...
               'centre', [0 0 0], 'inertie', zeros(1, 6));
    for k = 1:numel(noeud.Enfants)
        e = noeud.Enfants(k);
        if ~strcmpi(e.Nom, 'inertial')
            continue
        end
        for j = 1:numel(e.Enfants)
            f = e.Enfants(j);
            switch lower(f.Nom)
                case 'mass'
                    c.masse = str2double(f.Attributs.value);
                case 'origin'
                    if isfield(f.Attributs, 'xyz')
                        c.centre = sscanf(f.Attributs.xyz, '%f').';
                    end
                case 'inertia'
                    lire = @(nom) champ(f.Attributs, nom);
                    c.inertie = [lire('ixx'), lire('iyy'), lire('izz'), ...
                                 lire('iyz'), lire('ixz'), lire('ixy')];
            end
        end
    end
end

function L = lireLiaison(noeud)
%LIRELIAISON Parent, enfant, origine, axe et butées d'une balise « joint ».
    L = struct('nom', noeud.Attributs.name, 'type', noeud.Attributs.type, ...
               'parent', '', 'enfant', '', 'origine', eye(4), ...
               'axe', [1 0 0], 'butees', [-pi pi]);
    if strcmpi(L.type, 'continuous')
        L.butees = [-inf inf];
    end
    for k = 1:numel(noeud.Enfants)
        e = noeud.Enfants(k);
        switch lower(e.Nom)
            case 'parent'
                L.parent = e.Attributs.link;
            case 'child'
                L.enfant = e.Attributs.link;
            case 'origin'
                xyz = [0 0 0];
                rpy = [0 0 0];
                if isfield(e.Attributs, 'xyz')
                    xyz = sscanf(e.Attributs.xyz, '%f').';
                end
                if isfield(e.Attributs, 'rpy')
                    rpy = sscanf(e.Attributs.rpy, '%f').';
                end
                % L'URDF donne roulis, tangage, lacet — appliqués dans cet
                % ordre autour des axes fixes, ce qui revient à la
                % séquence ZYX lue à l'envers.
                L.origine = trvec2tform(xyz) * eul2tform(fliplr(rpy));
            case 'axis'
                L.axe = sscanf(e.Attributs.xyz, '%f').';
            case 'limit'
                bas = -pi; haut = pi;
                if isfield(e.Attributs, 'lower')
                    bas = str2double(e.Attributs.lower);
                end
                if isfield(e.Attributs, 'upper')
                    haut = str2double(e.Attributs.upper);
                end
                L.butees = [bas haut];
        end
    end
end

function v = champ(attributs, nom)
    if isfield(attributs, nom)
        v = str2double(attributs.(nom));
    else
        v = 0;
    end
end
