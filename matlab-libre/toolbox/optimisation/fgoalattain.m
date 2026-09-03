function [x, valeurs, atteinte] = fgoalattain(fonction, x0, buts, poids, A, b, Aeq, beq, bas, haut, nonlin)
%FGOALATTAIN Atteinte d'objectifs multiples.
%   X = FGOALATTAIN(F,X0,BUTS,POIDS) cherche X et un facteur GAMMA aussi
%   petit que possible tels que
%
%      F(X) - POIDS * GAMMA <= BUTS.
%
%   Un GAMMA négatif signifie que tous les buts sont dépassés, un GAMMA
%   positif qu'on reste en deçà, proportionnellement aux poids.
%
%   [X,F,GAMMA] = FGOALATTAIN(...) rend aussi le facteur atteint.
%
%   Exemple :
%      f = @(x) [x(1)^2, (x(1)-2)^2];
%      [x, v, g] = fgoalattain(f, 0, [1 1], [1 1]);
%
%   Voir aussi FMINIMAX, FMINCON, FSEMINF, OPTIMOPTIONS.
    if nargin < 4 || isempty(poids), poids = ones(size(buts)); end
    if nargin < 5, A = []; end
    if nargin < 6, b = []; end
    if nargin < 7, Aeq = []; end
    if nargin < 8, beq = []; end
    if nargin < 9, bas = []; end
    if nargin < 10, haut = []; end
    if nargin < 11, nonlin = []; end
    buts = double(buts(:))';
    poids = double(poids(:))';
    x0 = double(x0(:))';
    n = numel(x0);
    % La variable supplémentaire est gamma : on minimise gamma sous les
    % contraintes F(x) - poids*gamma <= buts.
    depart = [x0, max((fonction(x0) - buts) ./ max(poids, eps))];
    objectif = @(v) v(end);
    contraintes = @(v) contraintesAtteinte(v, fonction, buts, poids, nonlin);
    basEtendu = [];
    hautEtendu = [];
    if ~isempty(bas), basEtendu = [bas(:)', -Inf]; end
    if ~isempty(haut), hautEtendu = [haut(:)', Inf]; end
    Aetendu = [];
    if ~isempty(A), Aetendu = [A zeros(size(A, 1), 1)]; end
    AeqEtendu = [];
    if ~isempty(Aeq), AeqEtendu = [Aeq zeros(size(Aeq, 1), 1)]; end
    v = fmincon(objectif, depart, Aetendu, b, AeqEtendu, beq, basEtendu, hautEtendu, ...
                contraintes);
    v = v(:)';
    x = v(1:n);
    atteinte = v(end);
    valeurs = fonction(x);
end

function [c, ceq] = contraintesAtteinte(v, fonction, buts, poids, nonlin)
    v = v(:)';
    x = v(1:end-1);
    gamma = v(end);
    valeurs = fonction(x);
    c = valeurs(:)' - poids * gamma - buts;
    c = c(:);
    ceq = [];
    if ~isempty(nonlin)
        [cn, ceqn] = nonlin(x);
        c = [c; cn(:)];
        ceq = ceqn(:);
    end
end
