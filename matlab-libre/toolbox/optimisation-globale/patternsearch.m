function [x, valeur, drapeau, sortie] = patternsearch(fonction, x0, A, b, Aeq, beq, bas, haut, nonlin, options)
%PATTERNSEARCH Recherche directe par motif généralisé.
%   X = PATTERNSEARCH(F,X0) minimise F sans jamais dériver : à chaque
%   tour, on sonde les 2N points obtenus en avançant d'un pas dans
%   chaque direction de coordonnée. Si l'un est meilleur, on s'y déplace
%   et le pas double ; sinon le pas est divisé par deux.
%
%   PATTERNSEARCH(F,X0,A,B,AEQ,BEQ,BAS,HAUT,NONLCON) tient compte des
%   contraintes : un point qui les viole est simplement refusé.
%
%   La méthode converge vers un point stationnaire sur une fonction
%   régulière, et supporte les fonctions bruitées ou non dérivables, là
%   où un gradient numérique se perdrait.
%
%   Exemple :
%      x = patternsearch(@(v) (v(1)-1)^2 + (v(2)+2)^2, [0 0]);
    if nargin < 3, A = []; end
    if nargin < 4, b = []; end
    if nargin < 5, Aeq = []; end
    if nargin < 6, beq = []; end
    if nargin < 7, bas = []; end
    if nargin < 8, haut = []; end
    if nargin < 9, nonlin = []; end
    if nargin < 10, options = struct(); end
    pas = champOptimisation(options, 'InitialMeshSize', 1);
    pasMini = champOptimisation(options, 'MeshTolerance', 1e-10);
    maxTours = champOptimisation(options, 'MaxIterations', 2000);
    x = double(x0(:))';
    n = numel(x);
    admissible = @(v) pointAdmissible(v, A, b, Aeq, beq, bas, haut, nonlin);
    if ~admissible(x)
        x = ramenerDansBornes(x, bas, haut);
    end
    valeur = fonction(x);
    tours = 0;
    evaluations = 1;
    while pas > pasMini && tours < maxTours
        tours = tours + 1;
        meilleur = valeur;
        meilleurPoint = x;
        for k = 1:n
            for signe = [1 -1]
                candidat = x;
                candidat(k) = candidat(k) + signe * pas;
                if ~admissible(candidat)
                    continue
                end
                f = fonction(candidat);
                evaluations = evaluations + 1;
                if f < meilleur
                    meilleur = f;
                    meilleurPoint = candidat;
                end
            end
        end
        if meilleur < valeur
            x = meilleurPoint;
            valeur = meilleur;
            pas = pas * 2;          % succès : on ose plus grand
        else
            pas = pas / 2;          % échec : on affine le motif
        end
    end
    drapeau = double(pas <= pasMini);
    sortie = struct('iterations', tours, 'funccount', evaluations, ...
                    'meshsize', pas, 'algorithm', 'recherche par motif');
end

function ok = pointAdmissible(x, A, b, Aeq, beq, bas, haut, nonlin)
    x = x(:);
    ok = true;
    tolerance = 1e-9;
    if ~isempty(bas) && any(x < bas(:) - tolerance), ok = false; return, end
    if ~isempty(haut) && any(x > haut(:) + tolerance), ok = false; return, end
    if ~isempty(A) && any(A * x > b(:) + tolerance), ok = false; return, end
    if ~isempty(Aeq) && any(abs(Aeq * x - beq(:)) > 1e-6), ok = false; return, end
    if ~isempty(nonlin)
        [c, ceq] = nonlin(x');
        if ~isempty(c) && any(c > tolerance), ok = false; return, end
        if ~isempty(ceq) && any(abs(ceq) > 1e-6), ok = false; return, end
    end
end

function x = ramenerDansBornes(x, bas, haut)
    if ~isempty(bas), x = max(x, bas(:)'); end
    if ~isempty(haut), x = min(x, haut(:)'); end
end
