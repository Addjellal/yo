function [meilleur, valeur] = particleswarm(fonction, nVariables, bas, haut, nParticules, iterations)
%PARTICLESWARM Optimisation par essaim particulaire.
%   [X,VALEUR] = PARTICLESWARM(F,NVARIABLES,BAS,HAUT,NPARTICULES,ITERATIONS)
%   fait évoluer un essaim de points, chacun attiré à la fois par son
%   meilleur souvenir et par le meilleur de l'essaim.
%
%   Le compromis entre exploration et exploitation tient dans ces deux
%   attractions : la première maintient la diversité, la seconde
%   concentre l'essaim. Un essaim trop attiré par son meilleur converge
%   vite et mal.
%
%   La méthode ne demande ni dérivée ni continuité, ce qui la rend
%   applicable là où les méthodes de descente ne s'appliquent pas — au
%   prix d'un nombre d'évaluations bien plus grand.
%
%   Exemple :
%      f = @(x) sum(x.^2 - 10 * cos(2*pi*x) + 10);   % Rastrigin
%      [x, v] = particleswarm(f, 5, -5*ones(1,5), 5*ones(1,5), 40, 200);
%
%   Voir aussi GA, SIMULANNEALBND, MULTISTART.
    if nargin < 5, nParticules = 30; end
    if nargin < 6, iterations = 100; end
    bas = bas(:).';
    haut = haut(:).';
    x = repmat(bas, nParticules, 1) + rand(nParticules, nVariables) .* ...
        repmat(haut - bas, nParticules, 1);
    v = zeros(nParticules, nVariables);
    meilleursLocaux = x;
    scoresLocaux = zeros(nParticules, 1);
    for k = 1:nParticules
        scoresLocaux(k) = fonction(x(k, :));
    end
    [valeur, k] = min(scoresLocaux);
    meilleur = x(k, :);
    inertie = 0.7;
    c1 = 1.5;
    c2 = 1.5;
    for t = 1:iterations
        for k = 1:nParticules
            r1 = rand(1, nVariables);
            r2 = rand(1, nVariables);
            v(k, :) = inertie * v(k, :) + c1 * r1 .* (meilleursLocaux(k, :) - x(k, :)) ...
                      + c2 * r2 .* (meilleur - x(k, :));
            x(k, :) = min(max(x(k, :) + v(k, :), bas), haut);
            score = fonction(x(k, :));
            if score < scoresLocaux(k)
                scoresLocaux(k) = score;
                meilleursLocaux(k, :) = x(k, :);
            end
            if score < valeur
                valeur = score;
                meilleur = x(k, :);
            end
        end
    end
end
