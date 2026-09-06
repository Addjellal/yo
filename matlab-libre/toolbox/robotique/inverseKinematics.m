classdef inverseKinematics < handle
%INVERSEKINEMATICS Cinématique inverse d'un arbre de corps rigides.
%   IK = INVERSEKINEMATICS('RigidBodyTree',ROBOT) construit le solveur.
%   [CONFIG,INFO] = IK(CORPS,POSE,POIDS,DEPART) cherche la configuration
%   qui amène CORPS sur la POSE demandée — une matrice homogène 4x4 — en
%   partant de DEPART.
%
%   POIDS compte six nombres : les trois premiers pèsent l'erreur
%   d'orientation, les trois derniers l'erreur de position. Les mettre à
%   zéro revient à ne pas contraindre la composante correspondante — c'est
%   ainsi qu'on demande une position sans imposer l'orientation.
%
%   Propriétés :
%      RigidBodyTree     - l'arbre sur lequel on résout
%      SolverParameters  - les réglages : MaxIterations, MaxTime,
%                          SolutionTolerance, AllowRandomRestart
%
%   INFO rend Iterations, NumRandomRestarts, PoseErrorNorm, ExitFlag et
%   Status — 'success' ou 'best available'.
%
%   La résolution se fait par moindres carrés amortis : à chaque pas on
%   linéarise par la jacobienne géométrique et on résout
%
%      (J' W J + lambda I) dq = J' W e
%
%   L'amortissement lambda monte quand le pas échoue et descend quand il
%   réussit. C'est ce qui rend la méthode sûre au voisinage des
%   singularités, où la jacobienne seule n'est plus inversible.
%
%   Quand la descente s'arrête sur un minimum local, le solveur repart
%   d'une configuration tirée au hasard : c'est la seule parade contre les
%   minima locaux, et le nombre de reprises figure dans INFO.
%
%   Exemple :
%      ik = inverseKinematics('RigidBodyTree', robot);
%      cible = trvec2tform([0.5 0.3 0]);
%      [config, info] = ik('effecteur', cible, [0 0 0 1 1 1], ...
%                          homeConfiguration(robot));
%
%   Voir aussi GENERALIZEDINVERSEKINEMATICS, RIGIDBODYTREE, GETTRANSFORM.
    properties
        RigidBodyTree = []
        SolverParameters = struct('MaxIterations', 1500, 'MaxTime', 10, ...
                                  'SolutionTolerance', 1e-6, ...
                                  'AllowRandomRestart', true, ...
                                  'GradientTolerance', 1e-12, ...
                                  'StepTolerance', 1e-14)
    end
    methods
        function obj = inverseKinematics(varargin)
            for k = 1:2:numel(varargin)
                nom = validatestring(varargin{k}, ...
                        {'RigidBodyTree', 'SolverParameters'}, 'inverseKinematics');
                if strcmp(nom, 'RigidBodyTree')
                    obj.RigidBodyTree = varargin{k+1};
                else
                    obj.SolverParameters = varargin{k+1};
                end
            end
        end

        function varargout = subsref(obj, s)
            if strcmp(s(1).type, '()')
                [config, info] = resoudre(obj, s(1).subs{:});
                if nargout > 1
                    varargout = {config, info};
                else
                    varargout = {config};
                end
                return
            end
            [varargout{1:nargout}] = builtin('subsref', obj, s);
        end

        function [config, info] = resoudre(obj, nomCorps, pose, poids, depart)
        %RESOUDRE Cherche la configuration demandée.
            robot = obj.RigidBodyTree;
            if isempty(robot)
                error('robotics:inverseKinematics:SansArbre', ...
                      'Le solveur demande un RigidBodyTree.');
            end
            n = matlibre_nddl(robot);
            if nargin < 4 || isempty(poids)
                poids = ones(1, 6);
            end
            if nargin < 5 || isempty(depart)
                depart = homeConfiguration(robot);
            end
            noms = matlibre_nomsLiaisons(robot);
            q = matlibre_deshabiller(robot, depart);
            W = diag(double(poids(:)));
            bornes = matlibre_bornes(obj, robot);
            reglages = obj.SolverParameters;
            lambda = 1e-4;
            meilleure = q;
            meilleurEcart = inf;
            reprises = 0;
            iterations = 0;
            while true
                for pas = 1:reglages.MaxIterations
                    iterations = iterations + 1;
                    e = matlibre_ecart(obj, robot, q, noms, nomCorps, pose);
                    ecart = sqrt(e.' * W * e);
                    if ecart < meilleurEcart
                        meilleurEcart = ecart;
                        meilleure = q;
                    end
                    if ecart < reglages.SolutionTolerance
                        break
                    end
                    J = geometricJacobian(robot, matlibre_habiller(robot, q, noms), nomCorps);
                    A = J.' * W * J + lambda * eye(n);
                    dq = (A \ (J.' * W * e)).';
                    qNouveau = min(max(q + dq, bornes(1, :)), bornes(2, :));
                    eNouveau = matlibre_ecart(obj, robot, qNouveau, noms, nomCorps, pose);
                    if sqrt(eNouveau.' * W * eNouveau) < ecart
                        q = qNouveau;
                        lambda = max(lambda / 3, 1e-12);
                    else
                        lambda = lambda * 4;
                        if lambda > 1e8
                            break
                        end
                    end
                end
                if meilleurEcart < reglages.SolutionTolerance || ...
                        ~reglages.AllowRandomRestart || reprises >= 10
                    break
                end
                reprises = reprises + 1;
                q = matlibre_deshabiller(robot, randomConfiguration(robot));
                lambda = 1e-4;
            end
            config = matlibre_habiller(robot, meilleure, noms);
            reussi = meilleurEcart < reglages.SolutionTolerance;
            info = struct('Iterations', iterations, ...
                          'NumRandomRestarts', reprises, ...
                          'PoseErrorNorm', meilleurEcart, ...
                          'ExitFlag', double(reussi), ...
                          'Status', 'best available');
            if reussi
                info.Status = 'success';
            end
        end
    end
    methods (Access = private)
        function e = matlibre_ecart(~, robot, q, noms, nomCorps, pose)
        %MATLIBRE_ECART Erreur de pose : trois d'orientation, trois de position.
            T = getTransform(robot, matlibre_habiller(robot, q, noms), nomCorps);
            Rerr = pose(1:3, 1:3) * T(1:3, 1:3).';
            aa = rotm2axang(Rerr);
            e = [aa(1:3).' * aa(4); pose(1:3, 4) - T(1:3, 4)];
        end

        function bornes = matlibre_bornes(~, robot)
        %MATLIBRE_BORNES Butées de chaque liaison mobile, en deux lignes.
            bas = [];
            haut = [];
            for k = 1:robot.NumBodies
                j = robot.Bodies{k}.Joint;
                if matlibre_ddl(j) > 0
                    bas(end + 1) = j.PositionLimits(1);    %#ok<AGROW>
                    haut(end + 1) = j.PositionLimits(2);   %#ok<AGROW>
                end
            end
            bornes = [bas; haut];
        end
    end
end
