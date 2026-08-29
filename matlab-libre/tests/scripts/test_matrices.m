% test_matrices.m — construction, indexation et réductions.
disp('--- matrices ---');

A = [1 2 3; 4 5 6];
assert(isequal(size(A), [2 3]));
assert(numel(A) == 6);
assert(ndims(A) == 2);
assert(A(2, 3) == 6);
assert(A(end, end) == 6);
assert(isequal(A(:, 2), [2; 5]));
assert(isequal(A(1, :), [1 2 3]));
assert(isequal(A(:).', [1 4 2 5 3 6]));

% Concaténation.
assert(isequal([A; [7 8 9]], [1 2 3; 4 5 6; 7 8 9]));
assert(isequal([[1;2], [3;4]], [1 3; 2 4]));
assert(isempty([[], []]));

% reshape, permute, transposition.
B = reshape(1:6, 2, 3);
assert(isequal(B, [1 3 5; 2 4 6]));
assert(isequal(B.', [1 2; 3 4; 5 6]));
assert(isequal(reshape(B, 3, 2), [1 4; 2 5; 3 6]));
assert(isequal(fliplr([1 2 3]), [3 2 1]));
assert(isequal(flipud([1; 2]), [2; 1]));

% Construction.
assert(isequal(size(zeros(2, 3)), [2 3]));
assert(all(all(ones(2) == 1)));
assert(isequal(eye(2), [1 0; 0 1]));
assert(numel(linspace(0, 1, 11)) == 11);
assert(abs(linspace(0, 1, 11)(6) - 0.5) < 1e-12);
assert(isequal(repmat([1 2], 2, 2), [1 2 1 2; 1 2 1 2]));

% Indexation logique et affectation.
v = 1:6;
v(v > 4) = 0;
assert(isequal(v, [1 2 3 4 0 0]));
w = 1:5;
w([1 3]) = [];
assert(isequal(w, [2 4 5]));

% Croissance.
c = [];
for k = 1:4
    c(end+1) = k * k;
end
assert(isequal(c, [1 4 9 16]));

% Réductions.
M = [1 2; 3 4];
assert(isequal(sum(M), [4 6]));
assert(isequal(sum(M, 2), [3; 7]));
assert(sum(M(:)) == 10);
assert(isequal(prod(M), [3 8]));
assert(isequal(cumsum([1 2 3]), [1 3 6]));
assert(isequal(max(M), [3 4]));
[valeur, indice] = max([3 9 4]);
assert(valeur == 9 && indice == 2);
assert(isequal(sort([3 1 2]), [1 2 3]));
[trie, ordre] = sort([3 1 2]);
assert(isequal(ordre, [2 3 1]));
assert(isequal(find([0 1 0 1]), [2 4]));
assert(any([0 0 1]));
assert(~all([1 0 1]));
assert(isequal(unique([3 1 3 2]), [1 2 3]));
assert(isequal(diff([1 4 9]), [3 5]));
assert(isequal(cross([1 0 0], [0 1 0]), [0 0 1]));
assert(dot([1 2], [3 4]) == 11);

% Expansion implicite.
assert(isequal([1; 2] + [10 20], [11 21; 12 22]));

% Diagonales et triangles.
assert(isequal(diag([1 2]), [1 0; 0 2]));
assert(isequal(diag([1 2; 3 4]), [1; 4]));
assert(isequal(triu([1 2; 3 4]), [1 2; 0 4]));
assert(isequal(tril([1 2; 3 4]), [1 0; 3 4]));

% Tableaux à trois dimensions.
T = zeros(2, 2, 2);
T(:, :, 2) = [1 2; 3 4];
assert(ndims(T) == 3);
assert(T(2, 2, 2) == 4);
assert(size(T, 3) == 2);

% MATLAB ne conserve jamais de dimension singleton en queue au-dela de la
% deuxieme : un tableau demande en 2x2x1x1 est une matrice 2x2.
assert(isequal(size(zeros(2, 2, 1, 1)), [2 2]));
assert(isequal(size(ones([2 2 1 1])), [2 2]));
assert(isequal(size(false(2, 2, 1, 1)), [2 2]));
assert(isequal(size(rand(2, 3, 1)), [2 3]));
assert(isequal(size(cell(2, 2, 1, 1)), [2 2]));
assert(isequal(size(reshape(1:4, 2, 2, 1, 1)), [2 2]));
assert(ndims(zeros(2, 2, 1, 1)) == 2);
% Les singletons interieurs et de tete restent.
assert(isequal(size(ones(1, 1, 3)), [1 1 3]));
assert(isequal(size(zeros(2, 1, 3)), [2 1 3]));
assert(isequal(size(zeros(2, 1, 1)), [2 1]));
% Une dimension nulle n'est pas un singleton.
assert(isequal(size(zeros(0, 3)), [0 3]));

%% ------------------------------------------- nombres complexes
% Ecrire un complexe dans un tableau reel rend le tableau complexe, y
% compris quand l'ecriture fait grandir le tableau.
p = zeros(0, 1);
p(end+1, 1) = 1 + 2i;
p(end+1, 1) = 3 + 4i;
assert(isequal(p, [1+2i; 3+4i]));
t = [];
t(3) = 2 + 3i;
assert(isequal(t, [0 0 2+3i]));
q = zeros(2, 1);
q(1) = 1 + 2i;
assert(q(1) == 1+2i && q(2) == 0);
r = [1 2 3];
r(2) = 5i;
assert(isequal(r, [1 5i 3]));

% complex() force le stockage complexe : contrairement a une somme, la
% partie imaginaire nulle n'est pas abandonnee.
assert(~isreal(complex(0, 0)));
assert(~isreal(complex(3)));
assert(~isreal(complex(zeros(2, 2))));
assert(isreal(1 + 0i));                 % une somme, elle, se reduit
assert(complex(3, 0) == 3);
assert(isequal(class(complex(single(1), single(2))), 'single'));
assert(isequal(size(complex(zeros(2, 3))), [2 3]));

% z^n a exposant entier reel passe par carres successifs, comme MATLAB :
% le resultat est exact quand il peut l'etre.
assert((1+2i)^2 == -3+4i);
assert((1+1i)^4 == -4);
assert((2+0i)^3 == 8);
assert(abs((1+2i)^-2 - 1/(-3+4i)) < 1e-16);
assert(abs((1+1i)^0.5 - exp(0.5*log(1+1i))) < 1e-15);
assert((1+2i)^0 == 1);

% conv, deconv et filter travaillent sur les complexes.
assert(isequal(conv([1 1i], [1 -1i]), [1 0 1]));
assert(max(abs(conv([1 0.5-0.866i], [1 0.5+0.866i]) - [1 1 1.0000 - 0i])) < 1e-3);
assert(isequal(conv([1+2i 3], [2 1]), [2+4i 7+2i 3]));
assert(max(abs(deconv([1 0 1], [1 1i]) - [1 -1i])) < 1e-14);
assert(isequal(filter([1 1i], 1, [1 0 0]), [1 1i 0]));

% Le produit de complexes ne se decompose pas en parties.
assert(prod([1+1i, 1-1i]) == 2);
assert(isequal(cumprod([1+1i, 1-1i]), [1+1i, 2]));
assert(sum([1+1i, 1-1i]) == 2);
assert(isequal(cumsum([1+1i, 1-1i]), [1+1i, 2]));

% roots et eig convergent sur des racines complexes : les racines
% n-iemes de l'unite sont toutes de module 1.
for n = [2 3 5 8 12 14]
    racines = roots([1 zeros(1, n-1) -1]);
    assert(numel(racines) == n);
    assert(max(abs(abs(racines) - 1)) < 1e-10);
    % Leur produit vaut (-1)^(n+1), leur somme est nulle pour n > 1.
    assert(abs(sum(racines)) < 1e-9);
end
% Matrice de permutation cyclique : valeurs propres sur le cercle unite.
for n = [3 5 7]
    P = zeros(n);
    for k = 1:n
        P(k, mod(k, n) + 1) = 1;
    end
    assert(max(abs(abs(eig(P)) - 1)) < 1e-10);
end
% Trace et determinant se lisent sur les valeurs propres.
randn('seed', 5);
for n = [4 8 16]
    A = randn(n);
    e = eig(A);
    assert(abs(sum(e) - trace(A)) < 1e-12 * n);
    assert(abs(abs(prod(e)) - abs(det(A))) < 1e-8 * max(1, abs(det(A))));
end

% pinv, rank, cond, norm et svd acceptent les matrices complexes.
Ac = [1 1; 1i -1i; -1 -1];
assert(max(max(abs(pinv(Ac) * Ac - eye(2)))) < 1e-14);
assert(rank(Ac) == 2);
Vc = exp(1i * (0:7)' * [-1.885 -1.257 1.257 1.885]);
assert(rank(Vc) == 4);
assert(cond(Vc) < 2);
assert(max(max(abs(pinv(Vc) * Vc - eye(4)))) < 1e-12);
[Uc, Sc, Wc] = svd(Ac, 0);
assert(max(max(abs(Uc * Sc * Wc' - Ac))) < 1e-14);
assert(max(max(abs(Uc' * Uc - eye(2)))) < 1e-14);
assert(max(abs(svd(Ac) - [2; sqrt(2)])) < 1e-14);
randn('seed', 7);
Cc = randn(4) + 1i * randn(4);
assert(abs(norm(Cc) - max(svd(Cc))) < 1e-12);

%% ------------------------------------------- ensembles et leurs indices
% MATLAB rend jusqu'a trois sorties : « C = A(IA) » et « C = B(IB) ».
a = [5 1 3];  b = [3 5];
[c, ia, ib] = intersect(a, b);
assert(isequal(c, [3 5]));
assert(isequal(a(ia), c));
assert(isequal(b(ib), c));

[u, iau, ibu] = union([1 2], [2 3]);
assert(isequal(u, [1 2 3]));
sourceA = [1 2];  sourceB = [2 3];
assert(isequal(sourceA(iau), [1 2]));   % ce qui vient de A
assert(isequal(sourceB(ibu), 3));       % et ce qui vient de B

% setdiff n'a que deux sorties : ses elements ne sont dans aucune
% position de B.
[d, iad] = setdiff([1 2 3 4], [2 4]);
assert(isequal(d, [1 3]));
assert(isequal(iad, [1 3]));

% Sur des cellules aussi.
[cc, icc] = intersect({'a','b'}, {'b','c'});
assert(numel(cc) == 1 && strcmp(cc{1}, 'b'));
assert(icc == 2);

%% ------------------------------------------------ « axis » de MATLAB
% axis rend les bornes, les impose, egalise les echelles et masque les
% axes — les mots-cles de la documentation.
figure
plot([0 1], [0 2]);
axis([0 1 -1 1]);
assert(isequal(axis, [0 1 -1 1]));
axis auto
plot(1:10);
axis tight
bornesTight = axis;
assert(bornesTight(1) == 1 && bornesTight(2) == 10);
axis equal
axis square
axis off
axis on
close all

disp('matrices : toutes les verifications passent');
