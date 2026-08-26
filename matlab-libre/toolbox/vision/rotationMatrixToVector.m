function v = rotationMatrixToVector(R)
%ROTATIONMATRIXTOVECTOR Axe et angle d'une matrice de rotation.
%   V = ROTATIONMATRIXTOVECTOR(R) rend le vecteur dont la direction est
%   l'axe de rotation et la norme l'angle. C'est la réciproque de
%   ROTATIONVECTORTOMATRIX.
%
%   L'angle se lit sur la trace, acos((trace(R) - 1) / 2), et l'axe sur la
%   partie antisymétrique. Les deux cas dégénérés sont traités à part :
%   l'angle nul, où l'axe est indéterminé, et l'angle pi, où la partie
%   antisymétrique s'annule et où l'axe se lit sur la diagonale de R + I.
%
%   Exemple :
%      rotationMatrixToVector(rotationVectorToMatrix([0.1 0.2 0.3]))
%      % [0.1 0.2 0.3]
%
%   Voir aussi ROTATIONVECTORTOMATRIX.
    R = double(R);
    cosinus = (trace(R) - 1) / 2;
    cosinus = min(max(cosinus, -1), 1);
    theta = acos(cosinus);
    if theta < 1e-12
        v = zeros(1, 3);
        return
    end
    if abs(theta - pi) < 1e-8
        % Angle plat : R + I vaut 2 a a', dont la plus grande colonne
        % donne l'axe au signe près.
        M = (R + eye(3)) / 2;
        [~, colonne] = max(diag(M));
        axe = M(:, colonne) / sqrt(max(M(colonne, colonne), eps));
        axe = axe / norm(axe);
        v = (theta * axe)';
        return
    end
    axe = [R(3, 2) - R(2, 3); R(1, 3) - R(3, 1); R(2, 1) - R(1, 2)] / (2 * sin(theta));
    v = (theta * axe)';
end
