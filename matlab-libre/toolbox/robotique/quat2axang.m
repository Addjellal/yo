function axang = quat2axang(q)
%QUAT2AXANG Quaternion vers axe et angle.
%   AXANG = QUAT2AXANG([W X Y Z]) rend [X Y Z THETA].
%
%   L'angle est deux fois l'arc cosinus de la partie réelle ; l'axe est
%   la partie imaginaire, normalisée. Un quaternion de partie imaginaire
%   nulle est l'identité : son axe est indéterminé, on rend z.
%
%   Exemple :
%      quat2axang(axang2quat([1 0 0 0.4]))    % [1 0 0 0.4]
%
%   Voir aussi AXANG2QUAT, QUAT2ROTM, QUAT2EUL.
    [m, ~] = matlibre_rob_lignes(q, 4, 'Q');
    n = size(m, 1);
    axang = zeros(n, 4);
    for k = 1:n
        v = m(k, :) / norm(m(k, :));
        if v(1) < 0
            % q et -q décrivent la même rotation : on choisit celle dont
            % l'angle tombe dans [0, pi].
            v = -v;
        end
        imaginaire = v(2:4);
        longueur = norm(imaginaire);
        if longueur < 1e-12
            axang(k, :) = [0 0 1 0];
        else
            axang(k, :) = [imaginaire / longueur, 2 * atan2(longueur, v(1))];
        end
    end
end
