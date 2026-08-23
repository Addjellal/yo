function pow = puissancesSousEspace(R, w, valeurs, p)
%PUISSANCESSOUSESPACE Puissance de chaque composante sinusoïdale.
%   La matrice de corrélation vaut A P A' + sigma^2 I ; sigma^2 est la
%   moyenne des plus petites valeurs propres, et P se lit par moindres
%   carrés une fois les fréquences connues.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
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
