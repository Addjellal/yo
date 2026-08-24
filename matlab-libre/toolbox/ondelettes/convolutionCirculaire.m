function y = convolutionCirculaire(x, h)
%CONVOLUTIONCIRCULAIRE Corrélation périodique, longueur conservée.
%   Le signal est prolongé périodiquement : la sortie a exactement la
%   longueur de l'entrée, ce qu'exige la transformée stationnaire.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    x = x(:)';
    h = h(:)';
    n = numel(x);
    m = numel(h);
    y = zeros(1, n);
    for k = 1:n
        somme = 0;
        for j = 1:m
            indice = mod(k - 1 + j - 1, n) + 1;
            somme = somme + h(j) * x(indice);
        end
        y(k) = somme;
    end
end
