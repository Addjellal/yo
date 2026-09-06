classdef rigidBodyTree < handle
%RIGIDBODYTREE Arbre de corps rigides articulés.
%   ROBOT = RIGIDBODYTREE() crée un arbre réduit à sa base.
%   ROBOT = RIGIDBODYTREE('DataFormat',F,'MaxNumBodies',N) fixe le format
%   des configurations — 'struct', 'row' ou 'column'.
%
%   L'arbre décrit un robot : une base, des corps, et pour chaque corps la
%   liaison qui le rattache à son parent. De cette seule description on
%   tire toute la cinématique — GETTRANSFORM, GEOMETRICJACOBIAN — et toute
%   la dynamique — MASSMATRIX, INVERSEDYNAMICS, FORWARDDYNAMICS.
%
%   Propriétés :
%      NumBodies     - le nombre de corps, base non comprise
%      Bodies        - les corps, dans l'ordre où ils ont été ajoutés
%      BodyNames     - leurs noms
%      BaseName      - le nom de la base, 'base' par défaut
%      Gravity       - le vecteur de pesanteur, nul par défaut
%      DataFormat    - la forme des configurations
%
%   Une configuration se donne sous trois formes, selon DataFormat : un
%   tableau de structures à deux champs — JointName et JointPosition —,
%   un vecteur ligne, ou un vecteur colonne. Le format par défaut est le
%   tableau de structures, qui nomme ce qu'il porte ; les deux autres sont
%   plus commodes dès qu'on calcule.
%
%   Exemple :
%      robot = rigidBodyTree('DataFormat', 'row');
%      corps = rigidBody('bras1');
%      corps.Joint = rigidBodyJoint('j1', 'revolute');
%      setFixedTransform(corps.Joint, [1 0 0 0], 'dh');
%      addBody(robot, corps, 'base');
%      getTransform(robot, 0, 'bras1')
%
%   Voir aussi RIGIDBODY, RIGIDBODYJOINT, ADDBODY, GETTRANSFORM,
%   GEOMETRICJACOBIAN, INVERSEKINEMATICS, IMPORTROBOT, LOADROBOT.
    properties
        BaseName = 'base'
        Gravity = [0 0 0]
        DataFormat = 'struct'
    end
    properties (SetAccess = private)
        Bodies = {}
        BodyNames = {}
    end
    methods
        function obj = rigidBodyTree(varargin)
            for k = 1:2:numel(varargin)
                nom = validatestring(varargin{k}, ...
                        {'DataFormat', 'MaxNumBodies', 'BaseName', 'Gravity'}, ...
                        'rigidBodyTree');
                switch nom
                    case 'DataFormat'
                        obj.DataFormat = validatestring(varargin{k+1}, ...
                                {'struct', 'row', 'column'}, 'rigidBodyTree', 'DataFormat');
                    case 'BaseName'
                        obj.BaseName = char(varargin{k+1});
                    case 'Gravity'
                        obj.Gravity = double(varargin{k+1}(:)).';
                    case 'MaxNumBodies'
                        % Sans effet ici : l'arbre grandit à la demande.
                end
            end
        end

        function n = get.NumBodies(obj)
            n = numel(obj.Bodies);
        end

        %% Construction de l'arbre
        function addBody(obj, corps, nomParent)
        %ADDBODY Attache un corps à l'arbre.
            if nargin < 3
                nomParent = obj.BaseName;
            end
            nomParent = char(nomParent);
            if ~ischar(corps.Name) || isempty(corps.Name)
                error('robotics:rigidBodyTree:NomVide', 'Le corps doit porter un nom.');
            end
            if any(strcmp(obj.BodyNames, corps.Name)) || strcmp(corps.Name, obj.BaseName)
                error('robotics:rigidBodyTree:NomPris', ...
                      'Un corps porte deja le nom « %s ».', corps.Name);
            end
            if ~strcmp(nomParent, obj.BaseName) && ~any(strcmp(obj.BodyNames, nomParent))
                error('robotics:rigidBodyTree:ParentInconnu', ...
                      'Aucun corps ni base ne se nomme « %s ».', nomParent);
            end
            matlibre_poserParent(corps, nomParent);
            if ~strcmp(nomParent, obj.BaseName)
                matlibre_ajouterEnfant(obj.Bodies{obj.matlibre_indice(nomParent)}, corps.Name);
            end
            obj.Bodies{end + 1} = corps;
            obj.BodyNames{end + 1} = corps.Name;
        end

        function corps = removeBody(obj, nom)
        %REMOVEBODY Détache un corps et toute sa descendance.
            nom = char(nom);
            indice = obj.matlibre_indice(nom);
            aOter = obj.matlibre_descendance(indice);
            corps = obj.Bodies{indice};
            parent = corps.Parent;
            if ~strcmp(parent, obj.BaseName)
                matlibre_oterEnfant(obj.Bodies{obj.matlibre_indice(parent)}, nom);
            end
            garder = true(1, numel(obj.Bodies));
            garder(aOter) = false;
            obj.Bodies = obj.Bodies(garder);
            obj.BodyNames = obj.BodyNames(garder);
        end

        function replaceBody(obj, nom, corps)
        %REPLACEBODY Remplace un corps sans toucher à la structure.
            indice = obj.matlibre_indice(char(nom));
            ancien = obj.Bodies{indice};
            corps.Name = ancien.Name;
            matlibre_poserParent(corps, ancien.Parent);
            for k = 1:numel(ancien.Children)
                matlibre_ajouterEnfant(corps, ancien.Children{k});
            end
            obj.Bodies{indice} = corps;
        end

        function corps = getBody(obj, nom)
        %GETBODY Rend le corps qui porte ce nom.
            corps = obj.Bodies{obj.matlibre_indice(char(nom))};
        end

        function showdetails(obj)
        %SHOWDETAILS Affiche la structure de l'arbre.
            fprintf('--------------------\n');
            fprintf('Robot : (%d corps)\n\n', numel(obj.Bodies));
            fprintf('%4s %12s %14s %10s %14s\n', ...
                    'Idx', 'Corps', 'Liaison', 'Type', 'Parent');
            fprintf('%4s %12s %14s %10s %14s\n', ...
                    '---', '-----', '-------', '----', '------');
            for k = 1:numel(obj.Bodies)
                b = obj.Bodies{k};
                fprintf('%4d %12s %14s %10s %14s\n', ...
                        k, b.Name, b.Joint.Name, b.Joint.Type, b.Parent);
            end
            fprintf('--------------------\n');
        end

        %% Configurations
        function config = homeConfiguration(obj)
        %HOMECONFIGURATION La configuration de repos de chaque liaison.
            valeurs = zeros(1, 0);
            noms = {};
            for k = 1:numel(obj.Bodies)
                j = obj.Bodies{k}.Joint;
                if matlibre_ddl(j) > 0
                    valeurs(end + 1) = j.HomePosition;   %#ok<AGROW>
                    noms{end + 1} = j.Name;              %#ok<AGROW>
                end
            end
            config = obj.matlibre_habiller(valeurs, noms);
        end

        function config = randomConfiguration(obj)
        %RANDOMCONFIGURATION Une configuration tirée dans les butées.
            valeurs = zeros(1, 0);
            noms = {};
            for k = 1:numel(obj.Bodies)
                j = obj.Bodies{k}.Joint;
                if matlibre_ddl(j) > 0
                    bornes = j.PositionLimits;
                    valeurs(end + 1) = bornes(1) + rand * (bornes(2) - bornes(1)); %#ok<AGROW>
                    noms{end + 1} = j.Name;              %#ok<AGROW>
                end
            end
            config = obj.matlibre_habiller(valeurs, noms);
        end

        function n = matlibre_nddl(obj)
        %MATLIBRE_NDDL Nombre de degrés de liberté de vitesse.
            n = 0;
            for k = 1:numel(obj.Bodies)
                n = n + matlibre_ddl(obj.Bodies{k}.Joint);
            end
        end

        function q = matlibre_deshabiller(obj, config)
        %MATLIBRE_DESHABILLER Configuration ramenée à un vecteur ligne.
            if isempty(config)
                q = zeros(1, obj.matlibre_nddl());
                return
            end
            if isstruct(config)
                noms = obj.matlibre_nomsLiaisons();
                q = zeros(1, numel(noms));
                for k = 1:numel(config)
                    position = find(strcmp(noms, config(k).JointName), 1);
                    if ~isempty(position)
                        q(position) = config(k).JointPosition;
                    end
                end
                return
            end
            q = double(config(:)).';
            if numel(q) ~= obj.matlibre_nddl()
                error('robotics:rigidBodyTree:Configuration', ...
                      'La configuration compte %d valeurs, il en faut %d.', ...
                      numel(q), obj.matlibre_nddl());
            end
        end

        function noms = matlibre_nomsLiaisons(obj)
        %MATLIBRE_NOMSLIAISONS Noms des liaisons mobiles, dans l'ordre.
            noms = {};
            for k = 1:numel(obj.Bodies)
                if matlibre_ddl(obj.Bodies{k}.Joint) > 0
                    noms{end + 1} = obj.Bodies{k}.Joint.Name;   %#ok<AGROW>
                end
            end
        end

        function config = matlibre_habiller(obj, valeurs, noms)
        %MATLIBRE_HABILLER Vecteur ramené au format demandé.
            switch obj.DataFormat
                case 'row'
                    config = valeurs(:).';
                case 'column'
                    config = valeurs(:);
                otherwise
                    if isempty(valeurs)
                        config = struct('JointName', {}, 'JointPosition', {});
                        return
                    end
                    for k = numel(valeurs):-1:1
                        config(k) = struct('JointName', noms{k}, ...
                                           'JointPosition', valeurs(k));
                    end
            end
        end

        %% Cinématique
        function T = getTransform(obj, config, cible, source)
        %GETTRANSFORM Pose d'un corps dans le repère d'un autre.
            q = obj.matlibre_deshabiller(config);
            poses = obj.matlibre_poses(q);
            T = obj.matlibre_pose(poses, char(cible));
            if nargin >= 4
                T = obj.matlibre_pose(poses, char(source)) \ T;
            end
        end

        function J = geometricJacobian(obj, config, nomCorps)
        %GEOMETRICJACOBIAN Jacobienne géométrique d'un corps.
            q = obj.matlibre_deshabiller(config);
            poses = obj.matlibre_poses(q);
            [axes, origines] = obj.matlibre_axes(poses);
            n = obj.matlibre_nddl();
            J = zeros(6, n);
            indice = obj.matlibre_indice(char(nomCorps));
            Tfin = poses{indice + 1};
            pFin = Tfin(1:3, 4);
            chemin = obj.matlibre_chaine(indice);
            for k = chemin
                colonne = obj.matlibre_colonne(k);
                if colonne == 0
                    continue
                end
                a = axes{k};
                p = origines{k};
                if strcmp(obj.Bodies{k}.Joint.Type, 'revolute')
                    J(1:3, colonne) = a;
                    J(4:6, colonne) = cross(a, pFin - p);
                else
                    J(4:6, colonne) = a;
                end
            end
        end

        function [c, Jc] = centerOfMass(obj, config)
        %CENTEROFMASS Centre de masse de l'ensemble, dans le repère de base.
            if nargin < 2
                config = obj.homeConfiguration();
            end
            q = obj.matlibre_deshabiller(config);
            poses = obj.matlibre_poses(q);
            masse = 0;
            somme = zeros(3, 1);
            for k = 1:numel(obj.Bodies)
                b = obj.Bodies{k};
                T = poses{k + 1};
                centre = T(1:3, 1:3) * b.CenterOfMass(:) + T(1:3, 4);
                somme = somme + b.Mass * centre;
                masse = masse + b.Mass;
            end
            if masse <= 0
                c = zeros(1, 3);
            else
                c = (somme / masse).';
            end
            if nargout > 1
                % La jacobienne du centre de masse, par différences
                % centrées : c'est la définition, et elle évite d'écrire
                % une seconde fois la cinématique.
                n = obj.matlibre_nddl();
                Jc = zeros(3, n);
                h = 1e-7;
                for k = 1:n
                    dq = zeros(1, n);
                    dq(k) = h;
                    cPlus = obj.centerOfMass(obj.matlibre_habiller(q + dq, obj.matlibre_nomsLiaisons()));
                    cMoins = obj.centerOfMass(obj.matlibre_habiller(q - dq, obj.matlibre_nomsLiaisons()));
                    Jc(:, k) = (cPlus(:) - cMoins(:)) / (2 * h);
                end
            end
        end

        %% Dynamique
        function tau = inverseDynamics(obj, config, qPoint, qPointPoint, fext)
        %INVERSEDYNAMICS Couples articulaires d'un mouvement donné.
            n = obj.matlibre_nddl();
            if nargin < 2 || isempty(config), config = obj.homeConfiguration(); end
            if nargin < 3 || isempty(qPoint), qPoint = zeros(1, n); end
            if nargin < 4 || isempty(qPointPoint), qPointPoint = zeros(1, n); end
            if nargin < 5 || isempty(fext), fext = zeros(6, numel(obj.Bodies)); end
            q = obj.matlibre_deshabiller(config);
            tau = obj.matlibre_newtonEuler(q, double(qPoint(:)).', ...
                                           double(qPointPoint(:)).', fext);
            tau = obj.matlibre_commeConfig(tau);
        end

        function M = massMatrix(obj, config)
        %MASSMATRIX Matrice d'inertie articulaire.
            n = obj.matlibre_nddl();
            if nargin < 2 || isempty(config), config = obj.homeConfiguration(); end
            q = obj.matlibre_deshabiller(config);
            % La colonne j vaut le couple d'une accélération unité sur la
            % seule liaison j, sans vitesse ni pesanteur : c'est la
            % définition de la matrice d'inertie.
            pesanteur = obj.Gravity;
            obj.Gravity = [0 0 0];
            M = zeros(n, n);
            for j = 1:n
                e = zeros(1, n);
                e(j) = 1;
                M(:, j) = obj.matlibre_newtonEuler(q, zeros(1, n), e, ...
                                                   zeros(6, numel(obj.Bodies)));
            end
            obj.Gravity = pesanteur;
            M = (M + M.') / 2;
        end

        function tau = velocityProduct(obj, config, qPoint)
        %VELOCITYPRODUCT Couples de Coriolis et centrifuges.
            n = obj.matlibre_nddl();
            if nargin < 3 || isempty(qPoint), qPoint = zeros(1, n); end
            q = obj.matlibre_deshabiller(config);
            pesanteur = obj.Gravity;
            obj.Gravity = [0 0 0];
            tau = obj.matlibre_newtonEuler(q, double(qPoint(:)).', zeros(1, n), ...
                                           zeros(6, numel(obj.Bodies)));
            obj.Gravity = pesanteur;
            tau = obj.matlibre_commeConfig(tau);
        end

        function tau = gravityTorque(obj, config)
        %GRAVITYTORQUE Couples nécessaires pour tenir contre la pesanteur.
            n = obj.matlibre_nddl();
            if nargin < 2 || isempty(config), config = obj.homeConfiguration(); end
            q = obj.matlibre_deshabiller(config);
            tau = obj.matlibre_newtonEuler(q, zeros(1, n), zeros(1, n), ...
                                           zeros(6, numel(obj.Bodies)));
            tau = obj.matlibre_commeConfig(tau);
        end

        function qPointPoint = forwardDynamics(obj, config, qPoint, tau, fext)
        %FORWARDDYNAMICS Accélérations articulaires sous des couples donnés.
            n = obj.matlibre_nddl();
            if nargin < 2 || isempty(config), config = obj.homeConfiguration(); end
            if nargin < 3 || isempty(qPoint), qPoint = zeros(1, n); end
            if nargin < 4 || isempty(tau), tau = zeros(1, n); end
            if nargin < 5 || isempty(fext), fext = zeros(6, numel(obj.Bodies)); end
            q = obj.matlibre_deshabiller(config);
            % M qddot = tau - biais, où le biais rassemble Coriolis,
            % pesanteur et forces extérieures : c'est ce qu'inverseDynamics
            % rend à accélération nulle.
            biais = obj.matlibre_newtonEuler(q, double(qPoint(:)).', zeros(1, n), fext);
            M = obj.massMatrix(config);
            qPointPoint = obj.matlibre_commeConfig((M \ (double(tau(:)) - biais(:))).');
        end

        function fext = externalForce(obj, nomCorps, torseur, config)
        %EXTERNALFORCE Matrice des efforts extérieurs, une colonne par corps.
            fext = zeros(6, numel(obj.Bodies));
            indice = obj.matlibre_indice(char(nomCorps));
            w = double(torseur(:));
            if numel(w) ~= 6
                error('robotics:rigidBodyTree:Torseur', ...
                      'Un torseur compte six composantes : [couple ; force].');
            end
            if nargin >= 4 && ~isempty(config)
                % Donné dans le repère du corps : on le ramène à celui de
                % la base, où le calcul de dynamique se fait.
                T = obj.getTransform(config, char(nomCorps));
                R = T(1:3, 1:3);
                w = [R * w(1:3); R * w(4:6)];
            end
            fext(:, indice) = w;
        end

        function autre = copy(obj)
        %COPY Copie indépendante de l'arbre.
            autre = rigidBodyTree('DataFormat', obj.DataFormat, ...
                                  'BaseName', obj.BaseName);
            autre.Gravity = obj.Gravity;
            for k = 1:numel(obj.Bodies)
                addBody(autre, copy(obj.Bodies{k}), obj.Bodies{k}.Parent);
            end
        end
    end

    properties (Dependent)
        NumBodies
    end

    methods (Access = private)
        function indice = matlibre_indice(obj, nom)
            indice = find(strcmp(obj.BodyNames, nom), 1);
            if isempty(indice)
                error('robotics:rigidBodyTree:CorpsInconnu', ...
                      'Aucun corps ne se nomme « %s ».', nom);
            end
        end

        function colonne = matlibre_colonne(obj, indice)
        %MATLIBRE_COLONNE Rang du corps parmi les liaisons mobiles.
            colonne = 0;
            compte = 0;
            for k = 1:numel(obj.Bodies)
                if matlibre_ddl(obj.Bodies{k}.Joint) > 0
                    compte = compte + 1;
                    if k == indice
                        colonne = compte;
                        return
                    end
                elseif k == indice
                    return
                end
            end
        end

        function liste = matlibre_chaine(obj, indice)
        %MATLIBRE_CHAINE Corps de la base jusqu'à celui-ci, dans l'ordre.
            liste = [];
            courant = indice;
            while courant > 0
                liste = [courant, liste];   %#ok<AGROW>
                parent = obj.Bodies{courant}.Parent;
                if strcmp(parent, obj.BaseName)
                    break
                end
                courant = find(strcmp(obj.BodyNames, parent), 1);
                if isempty(courant)
                    break
                end
            end
        end

        function liste = matlibre_descendance(obj, indice)
        %MATLIBRE_DESCENDANCE Le corps et tous ceux qu'il porte.
            liste = indice;
            k = 1;
            while k <= numel(liste)
                enfants = obj.Bodies{liste(k)}.Children;
                for j = 1:numel(enfants)
                    position = find(strcmp(obj.BodyNames, enfants{j}), 1);
                    if ~isempty(position) && ~any(liste == position)
                        liste(end + 1) = position;   %#ok<AGROW>
                    end
                end
                k = k + 1;
            end
        end

        function poses = matlibre_poses(obj, q)
        %MATLIBRE_POSES Pose de chaque corps dans le repère de base.
        %   poses{1} est la base, poses{k+1} le corps k.
            n = numel(obj.Bodies);
            poses = cell(1, n + 1);
            poses{1} = eye(4);
            colonne = 0;
            for k = 1:n
                b = obj.Bodies{k};
                if matlibre_ddl(b.Joint) > 0
                    colonne = colonne + 1;
                    valeur = q(colonne);
                else
                    valeur = 0;
                end
                if strcmp(b.Parent, obj.BaseName)
                    Tparent = poses{1};
                else
                    Tparent = poses{find(strcmp(obj.BodyNames, b.Parent), 1) + 1};
                end
                poses{k + 1} = Tparent * matlibre_transformation(b.Joint, valeur);
            end
        end

        function T = matlibre_pose(obj, poses, nom)
            if strcmp(nom, obj.BaseName)
                T = poses{1};
            else
                T = poses{obj.matlibre_indice(nom) + 1};
            end
        end

        function [axes, origines] = matlibre_axes(obj, poses)
        %MATLIBRE_AXES Axe et origine de chaque liaison, en repère de base.
        %   L'axe d'une liaison ne passe pas par l'origine du corps
        %   qu'elle porte, mais par celle du repère de liaison — que
        %   JointToParentTransform place sur le parent. Confondre les deux
        %   fausse la jacobienne dès que la liaison est décalée.
            n = numel(obj.Bodies);
            axes = cell(1, n);
            origines = cell(1, n);
            for k = 1:n
                b = obj.Bodies{k};
                if strcmp(b.Parent, obj.BaseName)
                    Tparent = poses{1};
                else
                    Tparent = poses{find(strcmp(obj.BodyNames, b.Parent), 1) + 1};
                end
                Tliaison = Tparent * b.Joint.JointToParentTransform;
                a = b.Joint.JointAxis(:);
                axes{k} = Tliaison(1:3, 1:3) * (a / max(norm(a), eps));
                origines{k} = Tliaison(1:3, 4);
            end
        end

        function config = matlibre_commeConfig(obj, valeurs)
        %MATLIBRE_COMMECONFIG Vecteur rendu dans l'orientation du format.
            switch obj.DataFormat
                case 'column'
                    config = valeurs(:);
                otherwise
                    config = valeurs(:).';
            end
        end

        function tau = matlibre_newtonEuler(obj, q, qPoint, qPointPoint, fext)
        %MATLIBRE_NEWTONEULER Algorithme de Newton-Euler récursif.
        %   Descente : vitesses et accélérations, de la base aux feuilles.
        %   Remontée : efforts, des feuilles à la base. Tout est exprimé
        %   dans le repère de base, ce qui évite un changement de repère à
        %   chaque étape au prix de quelques produits vectoriels de plus.
        %
        %   La pesanteur entre comme une accélération de la base en sens
        %   contraire : le procédé est classique, et il évite d'ajouter un
        %   terme de poids à chaque corps.
        %
        %   Les moments se prennent à l'origine de la liaison, non à celle
        %   du corps : c'est là que passe l'axe, et donc là que le couple
        %   articulaire se lit par simple projection.
            n = numel(obj.Bodies);
            poses = obj.matlibre_poses(q);
            [axes, origines] = obj.matlibre_axes(poses);
            omega = cell(1, n + 1);
            alpha = cell(1, n + 1);
            acc = cell(1, n + 1);
            omega{1} = zeros(3, 1);
            alpha{1} = zeros(3, 1);
            acc{1} = -obj.Gravity(:);
            F = cell(1, n);
            N = cell(1, n);
            centres = cell(1, n);
            colonne = 0;
            for k = 1:n
                b = obj.Bodies{k};
                if strcmp(b.Parent, obj.BaseName)
                    ip = 1;
                else
                    ip = find(strcmp(obj.BodyNames, b.Parent), 1) + 1;
                end
                p = poses{k + 1}(1:3, 4);
                pp = poses{ip}(1:3, 4);
                pj = origines{k};
                r1 = pj - pp;            % du parent a la liaison
                r2 = p - pj;             % de la liaison au corps
                wp = omega{ip};
                ap = alpha{ip};
                w = wp;
                al = ap;
                supplement = zeros(3, 1);
                if matlibre_ddl(b.Joint) > 0
                    colonne = colonne + 1;
                    z = axes{k};
                    dq = qPoint(colonne);
                    ddq = qPointPoint(colonne);
                    if strcmp(b.Joint.Type, 'revolute')
                        w = wp + z * dq;
                        al = ap + z * ddq + cross(wp, z * dq);
                    else
                        supplement = z * ddq + 2 * cross(wp, z * dq);
                    end
                end
                a = acc{ip} + cross(ap, r1) + cross(wp, cross(wp, r1)) ...
                    + cross(al, r2) + cross(w, cross(w, r2)) + supplement;
                omega{k + 1} = w;
                alpha{k + 1} = al;
                acc{k + 1} = a;
                R = poses{k + 1}(1:3, 1:3);
                d = R * b.CenterOfMass(:);
                centres{k} = d;
                accCentre = a + cross(al, d) + cross(w, cross(w, d));
                Ibase = R * matlibre_inertie(b) * R.';
                F{k} = b.Mass * accCentre;
                N{k} = Ibase * al + cross(w, Ibase * w);
            end
            % Remontée : chaque corps porte ce que ses enfants lui
            % transmettent, plus son propre effort d'inertie, moins ce
            % qu'un effort extérieur lui apporte.
            f = cell(1, n);
            nMoment = cell(1, n);
            for k = n:-1:1
                b = obj.Bodies{k};
                p = poses{k + 1}(1:3, 4);
                pj = origines{k};
                fExt = fext(4:6, k);
                nExt = fext(1:3, k);
                fk = F{k} - fExt;
                nk = N{k} + cross(p + centres{k} - pj, F{k}) ...
                     - nExt - cross(p - pj, fExt);
                for j = 1:numel(b.Children)
                    ic = find(strcmp(obj.BodyNames, b.Children{j}), 1);
                    if isempty(ic)
                        continue
                    end
                    fk = fk + f{ic};
                    nk = nk + nMoment{ic} + cross(origines{ic} - pj, f{ic});
                end
                f{k} = fk;
                nMoment{k} = nk;
            end
            tau = zeros(obj.matlibre_nddl(), 1);
            colonne = 0;
            for k = 1:n
                b = obj.Bodies{k};
                if matlibre_ddl(b.Joint) == 0
                    continue
                end
                colonne = colonne + 1;
                z = axes{k};
                if strcmp(b.Joint.Type, 'revolute')
                    tau(colonne) = z.' * nMoment{k};
                else
                    tau(colonne) = z.' * f{k};
                end
            end
        end
    end
end
