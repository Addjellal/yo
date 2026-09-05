function [T, vitesse, acceleration] = transformtraj(T0, TF, intervalle, echantillons)
%TRANSFORMTRAJ Interpolation entre deux transformations homogènes.
%   [T,V,A] = TRANSFORMTRAJ(T0,TF,INTERVALLE,ECHANTILLONS) interpole
%   entre deux matrices 4x4 et rend un tableau 4x4xN.
%
%   La rotation est interpolée sphériquement, la translation
%   linéairement : ce sont deux quantités de natures différentes, et les
%   traiter ensemble — en interpolant les seize coefficients — ne
%   donnerait même pas des matrices de transformation valides.
%
%   V rend les six composantes de la vitesse : les trois de la vitesse
%   angulaire d'abord, les trois de la vitesse linéaire ensuite.
%
%   Exemple :
%      T0 = trvec2tform([0 0 0]);
%      TF = trvec2tform([1 2 3]) * eul2tform([pi / 2 0 0]);
%      T = transformtraj(T0, TF, [0 1], linspace(0, 1, 10));
%      tform2trvec(T(:, :, end))       % [1 2 3]
%
%   Voir aussi ROTTRAJ, TFORM2TRVEC, TRVEC2TFORM.
    T0 = double(T0);
    TF = double(TF);
    intervalle = double(intervalle(:)).';
    echantillons = double(echantillons(:)).';
    n = numel(echantillons);
    fraction = (echantillons - intervalle(1)) / (intervalle(2) - intervalle(1));
    rotations = rottraj(tform2rotm(T0), tform2rotm(TF), intervalle, echantillons);
    p0 = tform2trvec(T0);
    pF = tform2trvec(TF);
    T = zeros(4, 4, n);
    for k = 1:n
        T(:, :, k) = eye(4);
        T(1:3, 1:3, k) = rotations(:, :, k);
        T(1:3, 4, k) = p0(:) + fraction(k) * (pF(:) - p0(:));
    end
    if nargout > 1
        duree = intervalle(2) - intervalle(1);
        [~, angulaire] = rottraj(tform2rotm(T0), tform2rotm(TF), intervalle, ...
                                 echantillons);
        lineaire = repmat((pF(:) - p0(:)) / duree, 1, n);
        vitesse = [angulaire; lineaire];
    end
    if nargout > 2
        acceleration = zeros(6, n);
    end
end
