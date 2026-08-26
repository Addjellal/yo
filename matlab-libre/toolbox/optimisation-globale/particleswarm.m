function [meilleur, valeur] = particleswarm(fonction, nVariables, bas, haut, nParticules, iterations)
%PARTICLESWARM Optimisation par essaim particulaire.
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
