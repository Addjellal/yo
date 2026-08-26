function D = directivity(theta, diagramme)
%DIRECTIVITY Directivité estimée à partir d'un diagramme en puissance.
    U = diagramme .^ 2;
    integrale = trapz(theta, U .* sin(theta)) * 2 * pi;
    D = 4 * pi * max(U) / integrale;
end
