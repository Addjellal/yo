classdef rigidBody < handle
%RIGIDBODY Corps rigide d'un arbre articulé.
%   BODY = RIGIDBODY(NOM) crée un corps portant une liaison fixe du même
%   nom. On lui donne ensuite sa liaison, sa masse et son inertie, puis on
%   l'attache à un arbre par ADDBODY.
%
%   Propriétés :
%      Name          - le nom du corps
%      Joint         - la liaison qui le relie à son parent
%      Mass          - sa masse, en kilogrammes
%      CenterOfMass  - son centre de masse, dans son propre repère
%      Inertia       - [Ixx Iyy Izz Iyz Ixz Ixy] au centre de masse
%      Parent        - le nom de son parent, une fois attaché
%      Children      - les noms de ses enfants
%
%   L'inertie se donne au centre de masse et dans le repère du corps : ce
%   sont les six coefficients distincts de la matrice symétrique, dans
%   l'ordre des trois termes diagonaux puis des trois produits.
%
%   Exemple :
%      corps = rigidBody('bras');
%      corps.Joint = rigidBodyJoint('j1', 'revolute');
%      corps.Mass = 2;
%      corps.CenterOfMass = [0.25 0 0];
%      corps.Inertia = [0.01 0.05 0.05 0 0 0];
%
%   Voir aussi RIGIDBODYJOINT, RIGIDBODYTREE, ADDBODY.
    properties
        Name = ''
        Joint = []
        Mass = 1
        CenterOfMass = [0 0 0]
        Inertia = [1 1 1 0 0 0]
    end
    properties (SetAccess = private)
        Parent = ''
        Children = {}
    end
    methods
        function obj = rigidBody(nom)
            if nargin < 1
                nom = 'body';
            end
            obj.Name = char(nom);
            obj.Joint = rigidBodyJoint(obj.Name, 'fixed');
        end

        function M = matlibre_inertie(obj)
        %MATLIBRE_INERTIE Matrice d'inertie 3x3, au centre de masse.
            I = double(obj.Inertia(:)).';
            M = [I(1), I(6), I(5); I(6), I(2), I(4); I(5), I(4), I(3)];
        end

        function matlibre_poserParent(obj, nom)
        %MATLIBRE_POSERPARENT Enregistre le nom du parent.
            obj.Parent = char(nom);
        end

        function matlibre_ajouterEnfant(obj, nom)
        %MATLIBRE_AJOUTERENFANT Enregistre un enfant de plus.
            if ~any(strcmp(obj.Children, nom))
                obj.Children{end + 1} = char(nom);
            end
        end

        function matlibre_oterEnfant(obj, nom)
        %MATLIBRE_OTERENFANT Retire un enfant de la liste.
            obj.Children = obj.Children(~strcmp(obj.Children, nom));
        end

        function autre = copy(obj)
        %COPY Copie indépendante du corps, liaison comprise.
            autre = rigidBody(obj.Name);
            autre.Joint = copy(obj.Joint);
            autre.Mass = obj.Mass;
            autre.CenterOfMass = obj.CenterOfMass;
            autre.Inertia = obj.Inertia;
        end
    end
end
