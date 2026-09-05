function axang = rotm2axang(R)
%ROTM2AXANG Matrice de rotation vers axe et angle.
%   AXANG = ROTM2AXANG(R) rend [X Y Z THETA]. Un tableau 3x3xN rend une
%   matrice N sur 4.
%
%   L'angle se lit sur la trace : celle d'une rotation vaut
%   1 + 2 cos(theta), quelle que soit la direction de l'axe. L'axe, lui,
%   est le vecteur propre associé à la valeur propre un — la seule
%   direction que la rotation ne déplace pas.
%
%   Deux cas demandent un traitement à part. À l'angle nul, l'axe est
%   indéterminé : on rend l'axe z par convention. À pi, la partie
%   antisymétrique s'annule et l'axe se lit sur la diagonale de R + I.
%
%   Exemple :
%      rotm2axang(axang2rotm([0 0 1 pi / 3]))    % [0 0 1 pi/3]
%
%   Voir aussi AXANG2ROTM, ROTM2QUAT, ROTM2EUL.
    R = double(R);
    n = size(R, 3);
    axang = zeros(n, 4);
    for k = 1:n
        M = R(:, :, k);
        cosinus = min(max((trace(M) - 1) / 2, -1), 1);
        theta = acos(cosinus);
        if theta < 1e-10
            axang(k, :) = [0 0 1 0];
        elseif abs(theta - pi) < 1e-6
            % À pi, R est symétrique : l'axe se lit sur la diagonale de
            % R + I, dont la colonne de plus grande norme est la plus
            % sûre numériquement.
            S = (M + eye(3)) / 2;
            [~, colonne] = max(diag(S));
            axe = S(:, colonne) / sqrt(max(S(colonne, colonne), eps));
            axe = axe / norm(axe);
            axang(k, :) = [axe(:).', pi];
        else
            axe = [M(3, 2) - M(2, 3); M(1, 3) - M(3, 1); M(2, 1) - M(1, 2)] ...
                  / (2 * sin(theta));
            axang(k, :) = [axe(:).', theta];
        end
    end
end
