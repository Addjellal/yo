function K = noyauGp(A, B, nom, longueur, signal)
%NOYAUGP Fonction de covariance d'un processus gaussien.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    carres = repmat(sum(A .^ 2, 2), 1, size(B, 1)) + ...
             repmat(sum(B .^ 2, 2).', size(A, 1), 1) - 2 * (A * B.');
    d = sqrt(max(carres, 0));
    r = d / max(longueur, eps);
    switch nom
        case 'squaredexponential'
            K = signal ^ 2 * exp(-0.5 * r .^ 2);
        case 'exponential'
            K = signal ^ 2 * exp(-r);
        case 'matern32'
            K = signal ^ 2 * (1 + sqrt(3) * r) .* exp(-sqrt(3) * r);
        case 'matern52'
            K = signal ^ 2 * (1 + sqrt(5) * r + 5 * r .^ 2 / 3) .* exp(-sqrt(5) * r);
        otherwise
            error('stats:fitrgp:Noyau', 'Noyau inconnu : %s.', nom);
    end
end
