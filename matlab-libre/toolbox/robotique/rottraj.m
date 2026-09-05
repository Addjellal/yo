function [R, omega, alpha] = rottraj(r0, rF, intervalle, echantillons)
%ROTTRAJ Interpolation entre deux rotations.
%   [R,OMEGA,ALPHA] = ROTTRAJ(R0,RF,INTERVALLE,ECHANTILLONS) interpole
%   entre deux orientations, données en quaternions [W X Y Z] ou en
%   matrices 3x3. Le résultat est du même type que l'entrée.
%
%   L'interpolation est sphérique : elle suit le plus court chemin sur la
%   sphère des rotations, à vitesse angulaire constante. Interpoler
%   linéairement les coefficients d'une matrice de rotation ne donnerait
%   pas une rotation ; interpoler les angles d'Euler donnerait un chemin
%   qui dépend de la convention choisie. Ni l'un ni l'autre n'est le plus
%   court.
%
%   Exemple :
%      q0 = eul2quat([0 0 0]);
%      q1 = eul2quat([pi / 2 0 0]);
%      [r, w] = rottraj(q0, q1, [0 1], linspace(0, 1, 20));
%      w(:, 1)                         % vitesse angulaire, constante
%
%   Voir aussi TRANSFORMTRAJ, QUAT2ROTM, SLERP.
    enMatrice = size(r0, 1) == 3 && size(r0, 2) == 3;
    if enMatrice
        q0 = rotm2quat(r0);
        qF = rotm2quat(rF);
    else
        q0 = double(r0(:)).';
        qF = double(rF(:)).';
    end
    intervalle = double(intervalle(:)).';
    echantillons = double(echantillons(:)).';
    fraction = (echantillons - intervalle(1)) / (intervalle(2) - intervalle(1));
    q0 = q0 / norm(q0);
    qF = qF / norm(qF);
    % q et -q décrivent la même rotation : on choisit le signe qui rend
    % le chemin le plus court, sans quoi l'interpolation ferait le grand
    % tour.
    if dot(q0, qF) < 0
        qF = -qF;
    end
    cosinus = min(max(dot(q0, qF), -1), 1);
    theta = acos(cosinus);
    n = numel(fraction);
    quaternions = zeros(n, 4);
    for k = 1:n
        u = fraction(k);
        if theta < 1e-8
            quaternions(k, :) = q0;
        else
            quaternions(k, :) = (sin((1 - u) * theta) * q0 + sin(u * theta) * qF) ...
                                / sin(theta);
        end
        quaternions(k, :) = quaternions(k, :) / norm(quaternions(k, :));
    end
    if enMatrice
        R = zeros(3, 3, n);
        for k = 1:n
            R(:, :, k) = quat2rotm(quaternions(k, :));
        end
    else
        R = quaternions.';
    end
    if nargout > 1
        % La vitesse angulaire est constante : l'angle total divisé par
        % la durée, porté par l'axe de la rotation relative.
        relatif = quatmultiply(qF, quatconj(q0));
        axang = quat2axang(relatif);
        duree = intervalle(2) - intervalle(1);
        omega = repmat(axang(1:3).' * axang(4) / duree, 1, n);
    end
    if nargout > 2
        alpha = zeros(3, n);
    end
end
