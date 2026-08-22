% 01-prise-en-main.m — le langage en trente lignes.
%
%   matlibre exemples/01-prise-en-main.m

A = [1 2 3; 4 5 6; 7 8 10];
b = [6; 15; 25];
x = A \ b;
fprintf('Solution de A x = b : %s\n', mat2str(round(x', 6)));
fprintf('Determinant : %g, rang : %d\n', det(A), rank(A));
fprintf('Valeurs propres : %s\n', mat2str(round(sort(eig(A))', 4)));

% Indexation et réductions.
M = magic(4);
fprintf('Carre magique : somme des lignes = %s\n', mat2str(sum(M, 2)'));
fprintf('Diagonale : %s\n', mat2str(diag(M)'));
fprintf('Elements pairs : %d\n', sum(mod(M(:), 2) == 0));

% Cellules, structures, chaînes.
mesures = struct('nom', 'essai', 'valeurs', [1.5 2.5 3.5]);
fprintf('%s : moyenne %.2f, ecart type %.3f\n', mesures.nom, ...
        mean(mesures.valeurs), std(mesures.valeurs));

noms = {'alpha', 'beta', 'gamma'};
longueurs = cellfun(@numel, noms);
fprintf('%s\n', strjoin(noms, ', '));
fprintf('Longueurs : %s\n', mat2str(longueurs));

% Fonctions anonymes et récursion.
carre = @(v) v .^ 2;
fprintf('Carres de 1 a 5 : %s\n', mat2str(carre(1:5)));
fprintf('10! = %g\n', factorial(10));

% Contrôle de flux.
total = 0;
for k = 1:100
    if isprime(k)
        total = total + k;
    end
end
fprintf('Somme des nombres premiers jusqu''a 100 : %d\n', total);
