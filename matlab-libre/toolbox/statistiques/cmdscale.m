function [Y, valeurs] = cmdscale(D, dimension)
%CMDSCALE Positionnement multidimensionnel métrique.
%   Y = CMDSCALE(D) cherche des coordonnées dont les distances
%   euclidiennes reproduisent les dissemblances D. D est la matrice
%   carrée des distances, ou le vecteur que rend PDIST.
%
%   C'est l'analyse en coordonnées principales : on double-centre la
%   matrice des carrés des distances, on la diagonalise, et les vecteurs
%   propres mis à l'échelle de leurs valeurs propres donnent les
%   coordonnées. Quand D vient bel et bien d'un nuage euclidien, on le
%   retrouve exactement, à une isométrie près.
%
%   Y = CMDSCALE(D,P) ne garde que les P premières coordonnées.
%
%   [Y,E] = CMDSCALE(D) rend en outre les valeurs propres. Elles disent
%   combien de dimensions sont nécessaires : celles qui sont
%   négligeables — ou négatives, quand D n'est pas euclidienne — peuvent
%   être laissées.
%
%   Exemples :
%      X = [0 0; 3 0; 0 4; 3 4];
%      Y = cmdscale(pdist(X));
%      max(abs(pdist(Y) - pdist(X)))     % nul a l'arrondi pres
%
%      [Y, e] = cmdscale(pdist(randn(20, 3)));
%      e(1:5)'                            % trois valeurs, puis du bruit
%
%   Voir aussi MDSCALE, PDIST, SQUAREFORM, PCA, PROCRUSTES.
    if isvector(D)
        M = squareform(D(:)');
    else
        M = D;
    end
    n = size(M, 1);
    % Double centrage : B = -1/2 * J * D.^2 * J, avec J le centreur.
    carres = M .^ 2;
    moyenneLignes = mean(carres, 2);
    moyenneColonnes = mean(carres, 1);
    moyenneTotale = mean(carres(:));
    B = -0.5 * (carres - repmat(moyenneLignes, 1, n) - ...
                repmat(moyenneColonnes, n, 1) + moyenneTotale);
    B = (B + B') / 2;
    [V, Lambda] = eig(B);
    valeurs = real(diag(Lambda));
    [valeurs, ordre] = sort(valeurs, 'descend');
    V = real(V(:, ordre));
    positives = valeurs > max(n * eps * max([abs(valeurs); realmin]), 0);
    Y = V(:, positives) * diag(sqrt(valeurs(positives)));
    % Le signe de chaque axe est arbitraire : on le fixe pour que deux
    % appels donnent la même carte.
    for j = 1:size(Y, 2)
        [~, dominante] = max(abs(Y(:, j)));
        if Y(dominante, j) < 0
            Y(:, j) = -Y(:, j);
        end
    end
    if nargin >= 2 && ~isempty(dimension)
        if dimension > size(Y, 2)
            Y = [Y, zeros(n, dimension - size(Y, 2))];
        end
        Y = Y(:, 1:dimension);
    end
end
