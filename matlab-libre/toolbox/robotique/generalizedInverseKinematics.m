classdef generalizedInverseKinematics < handle
%GENERALIZEDINVERSEKINEMATICS Cinématique inverse sous contraintes.
%   GIK = GENERALIZEDINVERSEKINEMATICS('RigidBodyTree',ROBOT, ...
%         'ConstraintInputs',{'position','joint'}) construit le solveur.
%   [CONFIG,INFO] = GIK(DEPART,C1,C2,...) cherche la configuration qui
%   satisfait au mieux toutes les contraintes.
%
%   ConstraintInputs annonce les types attendus, dans l'ordre :
%   'pose', 'position', 'orientation', 'cartesian', 'joint', 'aiming',
%   'distance'.
%
%   Là où INVERSEKINEMATICS ne connaît qu'une pose à atteindre, celui-ci
%   accepte plusieurs contraintes de natures différentes et cherche le
%   compromis. C'est ce qu'il faut dès qu'un robot est redondant : une
%   position à tenir, une orientation approximative, et des butées à
%   respecter font trois exigences que rien n'oblige à être compatibles.
%
%   Chaque contrainte rend un résidu nul quand elle est satisfaite ; le
%   solveur minimise la somme de leurs carrés par moindres carrés amortis,
%   la jacobienne étant obtenue par différences finies — les contraintes
%   n'ayant pas toutes de dérivée analytique simple.
%
%   INFO rend Iterations, NumRandomRestarts, ExitFlag, Status et
%   ConstraintViolations, une structure par contrainte.
%
%   Exemple :
%      gik = generalizedInverseKinematics('RigidBodyTree', robot, ...
%                'ConstraintInputs', {'position', 'joint'});
%      cible = constraintPositionTarget('effecteur');
%      cible.TargetPosition = [0.4 0.2 0];
%      [config, info] = gik(homeConfiguration(robot), cible, ...
%                           constraintJointBounds(robot));
%
%   Voir aussi INVERSEKINEMATICS, CONSTRAINTPOSETARGET, CONSTRAINTJOINTBOUNDS.
    properties
        RigidBodyTree = []
        ConstraintInputs = {}
        SolverParameters = struct('MaxIterations', 1500, 'MaxTime', 10, ...
                                  'SolutionTolerance', 1e-6, ...
                                  'AllowRandomRestart', true)
    end
    methods
        function obj = generalizedInverseKinematics(varargin)
            for k = 1:2:numel(varargin)
                nom = validatestring(varargin{k}, ...
                        {'RigidBodyTree', 'ConstraintInputs', 'SolverParameters'}, ...
                        'generalizedInverseKinematics');
                obj.(nom) = varargin{k+1};
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

        function [config, info] = resoudre(obj, depart, varargin)
        %RESOUDRE Cherche la configuration qui satisfait les contraintes.
            robot = obj.RigidBodyTree;
            if isempty(robot)
                error('robotics:generalizedInverseKinematics:SansArbre', ...
                      'Le solveur demande un RigidBodyTree.');
            end
            contraintes = varargin;
            noms = matlibre_nomsLiaisons(robot);
            n = matlibre_nddl(robot);
            q = matlibre_deshabiller(robot, depart);
            reglages = obj.SolverParameters;
            residu = @(v) matlibre_pile(obj, robot, v, noms, contraintes);
            lambda = 1e-3;
            meilleur = q;
            meilleureNorme = norm(residu(q));
            reprises = 0;
            iterations = 0;
            while true
                for pas = 1:reglages.MaxIterations
                    iterations = iterations + 1;
                    r = residu(q);
                    norme = norm(r);
                    if norme < meilleureNorme
                        meilleureNorme = norme;
                        meilleur = q;
                    end
                    if norme < reglages.SolutionTolerance
                        break
                    end
                    J = zeros(numel(r), n);
                    h = 1e-7;
                    for k = 1:n
                        dq = zeros(1, n);
                        dq(k) = h;
                        J(:, k) = (residu(q + dq) - residu(q - dq)) / (2 * h);
                    end
                    if all(abs(J(:)) < 1e-12)
                        break
                    end
                    dq = ((J.' * J + lambda * eye(n)) \ (J.' * r)).';
                    if norm(residu(q - dq)) < norme
                        q = q - dq;
                        lambda = max(lambda / 3, 1e-12);
                    else
                        lambda = lambda * 4;
                        if lambda > 1e8
                            break
                        end
                    end
                end
                if meilleureNorme < reglages.SolutionTolerance || ...
                        ~reglages.AllowRandomRestart || reprises >= 10
                    break
                end
                reprises = reprises + 1;
                q = matlibre_deshabiller(robot, randomConfiguration(robot));
                lambda = 1e-3;
            end
            config = matlibre_habiller(robot, meilleur, noms);
            violations = struct('Type', {}, 'Violation', {});
            for k = 1:numel(contraintes)
                violations(k).Type = class(contraintes{k});
                violations(k).Violation = norm(matlibre_residu(contraintes{k}, robot, config));
            end
            reussi = meilleureNorme < reglages.SolutionTolerance;
            info = struct('Iterations', iterations, ...
                          'NumRandomRestarts', reprises, ...
                          'ExitFlag', double(reussi), ...
                          'Status', 'best available', ...
                          'ConstraintViolations', violations);
            if reussi
                info.Status = 'success';
            end
        end
    end
    methods (Access = private)
        function r = matlibre_pile(~, robot, q, noms, contraintes)
        %MATLIBRE_PILE Résidus de toutes les contraintes, mis bout à bout.
            config = matlibre_habiller(robot, q, noms);
            r = [];
            for k = 1:numel(contraintes)
                r = [r; matlibre_residu(contraintes{k}, robot, config)];   %#ok<AGROW>
            end
            if isempty(r)
                r = 0;
            end
        end
    end
end
