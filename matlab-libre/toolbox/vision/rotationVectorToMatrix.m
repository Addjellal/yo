function R = rotationVectorToMatrix(vecteur)
%ROTATIONVECTORTOMATRIX Formule de Rodrigues.
%   R = ROTATIONVECTORTOMATRIX(V) rend la matrice de rotation dont l'axe
%   est la direction de V et l'angle sa norme :
%
%      R = I + sin(theta) K + (1 - cos(theta)) K^2
%
%   où K est la matrice antisymétrique associée à l'axe unitaire. Trois
%   nombres suffisent donc à décrire une rotation, là où la matrice en
%   compte neuf liés par six contraintes.
%
%   Exemple :
%      R = rotationVectorToMatrix([0 0 pi/2]);
%      round(R * [1; 0; 0])   % [0; 1; 0]
%
%   Voir aussi ROTATIONMATRIXTOVECTOR.
    v = double(vecteur(:));
    theta = norm(v);
    if theta < eps
        R = eye(3);
        return
    end
    axe = v / theta;
    K = [    0,      -axe(3),  axe(2);
          axe(3),       0,    -axe(1);
         -axe(2),   axe(1),      0   ];
    R = eye(3) + sin(theta) * K + (1 - cos(theta)) * (K * K);
end
