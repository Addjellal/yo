function pow = puissancesSousEspace(R, w, valeurs, p)
%PUISSANCESSOUSESPACE Puissance de chaque composante sinusoïdale.
%   La matrice de corrélation vaut A P A' + sigma^2 I ; sigma^2 est la
%   moyenne des plus petites valeurs propres, et P se lit par moindres
%   carrés une fois les fréquences connues.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      rng(1);
%      x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
%      [R, m] = signalMatriceCorrelation(x, 2, false);
%      pow = puissancesSousEspace(R, 2 * pi * 0.1, eig(R), 2);
%      all(isfinite(pow))
%
%   Voir aussi PMUSIC, PEIG, ROOTMUSIC.
    m = size(R, 1);
    sigma2 = mean(valeurs(p+1:end));
    A = zeros(m, numel(w));
    for j = 1:numel(w)
        A(:, j) = exp(1i * w(j) * (0:m-1)');
    end
    inverse = pinv(A);
    P = inverse * (R - sigma2 * eye(m)) * inverse';
    pow = real(diag(P));
end
