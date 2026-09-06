classdef rigidBodyJoint < handle
%RIGIDBODYJOINT Liaison entre deux corps rigides.
%   JNT = RIGIDBODYJOINT(NOM) crée une liaison fixe.
%   JNT = RIGIDBODYJOINT(NOM,TYPE) où TYPE vaut 'fixed', 'revolute' ou
%   'prismatic'.
%
%   Propriétés :
%      Name                     - le nom de la liaison
%      Type                     - 'fixed', 'revolute' ou 'prismatic'
%      JointAxis                - l'axe de rotation ou de translation
%      HomePosition             - la position de repos
%      PositionLimits           - [minimum maximum]
%      JointToParentTransform   - du repère de liaison au corps parent
%      ChildToJointTransform    - du corps enfant au repère de liaison
%
%   La pose du corps enfant dans le repère du parent vaut
%
%      T = JointToParentTransform * Tliaison(q) * ChildToJointTransform
%
%   où Tliaison(q) est la rotation d'angle q — ou la translation de q —
%   autour de JointAxis. Les deux transformations fixes encadrent donc le
%   seul degré de liberté : l'une place la liaison sur le parent, l'autre
%   place l'enfant sur la liaison.
%
%   SETFIXEDTRANSFORM remplit ces deux transformations à partir des
%   paramètres de Denavit-Hartenberg, standard ou modifiés, ce qui évite
%   de les écrire à la main.
%
%   Exemple :
%      jnt = rigidBodyJoint('j1', 'revolute');
%      jnt.JointAxis = [0 0 1];
%      setFixedTransform(jnt, [0.5 0 0 0], 'dh');
%
%   Voir aussi RIGIDBODY, RIGIDBODYTREE, SETFIXEDTRANSFORM.
    properties
        Name = ''
        JointAxis = [0 0 1]
        HomePosition = 0
        PositionLimits = [-pi pi]
        JointToParentTransform = eye(4)
        ChildToJointTransform = eye(4)
    end
    properties (SetAccess = private)
        Type = 'fixed'
    end
    methods
        function obj = rigidBodyJoint(nom, type)
            if nargin < 1
                nom = 'joint';
            end
            if nargin < 2
                type = 'fixed';
            end
            type = validatestring(type, {'fixed', 'revolute', 'prismatic'}, ...
                                  'rigidBodyJoint', 'TYPE');
            obj.Name = char(nom);
            obj.Type = type;
            switch type
                case 'fixed'
                    obj.PositionLimits = [0 0];
                case 'revolute'
                    obj.PositionLimits = [-pi pi];
                case 'prismatic'
                    obj.PositionLimits = [-0.5 0.5];
            end
        end

        function n = matlibre_ddl(obj)
        %MATLIBRE_DDL Nombre de degrés de liberté : un, sauf si fixe.
            n = double(~strcmp(obj.Type, 'fixed'));
        end

        function T = matlibre_transformation(obj, q)
        %MATLIBRE_TRANSFORMATION Pose de l'enfant dans le repère du parent.
            if nargin < 2 || isempty(q)
                q = obj.HomePosition;
            end
            a = obj.JointAxis(:).';
            switch obj.Type
                case 'revolute'
                    Tq = axang2tform([a / max(norm(a), eps), q]);
                case 'prismatic'
                    Tq = trvec2tform(q * a / max(norm(a), eps));
                otherwise
                    Tq = eye(4);
            end
            T = obj.JointToParentTransform * Tq * obj.ChildToJointTransform;
        end

        function setFixedTransform(obj, entree, convention)
        %SETFIXEDTRANSFORM Fixe les transformations qui encadrent la liaison.
        %   SETFIXEDTRANSFORM(JNT,T) pose ChildToJointTransform à T.
        %
        %   SETFIXEDTRANSFORM(JNT,[A ALPHA D THETA],'dh') emploie les
        %   paramètres de Denavit-Hartenberg standard, où la matrice de
        %   passage vaut Rz(THETA) Tz(D) Tx(A) Rx(ALPHA). Pour une liaison
        %   rotoïde THETA est ignoré — c'est la variable — et pour une
        %   liaison prismatique c'est D.
        %
        %   SETFIXEDTRANSFORM(JNT,[A ALPHA D THETA],'mdh') emploie la
        %   convention modifiée, où la matrice vaut
        %   Rx(ALPHA) Tx(A) Rz(THETA) Tz(D).
        %
        %   Exemple :
        %      jnt = rigidBodyJoint('j', 'revolute');
        %      setFixedTransform(jnt, [0.3 -pi/2 0 0], 'dh');
            if nargin < 3
                convention = 'matrice';
            end
            if strcmpi(convention, 'matrice') || isequal(size(entree), [4 4])
                if ~isequal(size(entree), [4 4])
                    error('robotics:rigidBodyJoint:Transformation', ...
                          'La transformation doit etre une matrice 4x4.');
                end
                obj.ChildToJointTransform = double(entree);
                return
            end
            p = double(entree(:)).';
            if numel(p) ~= 4
                error('robotics:rigidBodyJoint:Parametres', ...
                      'Les parametres de Denavit-Hartenberg sont quatre : [A ALPHA D THETA].');
            end
            a = p(1); alpha = p(2); d = p(3); theta = p(4);
            Tz = @(v) trvec2tform([0 0 v]);
            Tx = @(v) trvec2tform([v 0 0]);
            Rz = @(v) rotm2tform(matlibre_rob_axe(3, v));
            Rx = @(v) rotm2tform(matlibre_rob_axe(1, v));
            switch lower(convention)
                case 'dh'
                    % Rz(theta) Tz(d) Tx(a) Rx(alpha), la variable étant
                    % theta pour une rotoïde et d pour une prismatique.
                    switch obj.Type
                        case 'revolute'
                            obj.JointToParentTransform = eye(4);
                            obj.ChildToJointTransform = Tz(d) * Tx(a) * Rx(alpha);
                        case 'prismatic'
                            obj.JointToParentTransform = Rz(theta);
                            obj.ChildToJointTransform = Tx(a) * Rx(alpha);
                        otherwise
                            obj.JointToParentTransform = eye(4);
                            obj.ChildToJointTransform = Rz(theta) * Tz(d) * Tx(a) * Rx(alpha);
                    end
                case 'mdh'
                    % Rx(alpha) Tx(a) Rz(theta) Tz(d) : les deux
                    % transformations fixes se rangent naturellement de
                    % part et d'autre de la variable.
                    switch obj.Type
                        case 'revolute'
                            obj.JointToParentTransform = Rx(alpha) * Tx(a);
                            obj.ChildToJointTransform = Tz(d);
                        case 'prismatic'
                            obj.JointToParentTransform = Rx(alpha) * Tx(a) * Rz(theta);
                            obj.ChildToJointTransform = eye(4);
                        otherwise
                            obj.JointToParentTransform = Rx(alpha) * Tx(a);
                            obj.ChildToJointTransform = Rz(theta) * Tz(d);
                    end
                otherwise
                    error('robotics:rigidBodyJoint:Convention', ...
                          'Convention inconnue : %s. Employez ''dh'' ou ''mdh''.', ...
                          char(convention));
            end
        end

        function autre = copy(obj)
        %COPY Copie indépendante de la liaison.
            autre = rigidBodyJoint(obj.Name, obj.Type);
            autre.JointAxis = obj.JointAxis;
            autre.HomePosition = obj.HomePosition;
            autre.PositionLimits = obj.PositionLimits;
            autre.JointToParentTransform = obj.JointToParentTransform;
            autre.ChildToJointTransform = obj.ChildToJointTransform;
        end
    end
end
