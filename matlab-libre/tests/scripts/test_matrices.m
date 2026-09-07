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

%% ------------------------------------------------------------- blkdiag
% Les blocs se posent sur la diagonale, le reste est nul. Ils n'ont pas a
% etre carres ni de meme taille, et un bloc vide n'ajoute rien.
assert(isequal(blkdiag([1 2; 3 4], 5), [1 2 0; 3 4 0; 0 0 5]));
assert(isequal(blkdiag(1, 2, 3), diag([1 2 3])));
assert(isequal(size(blkdiag([1 2 3], [4; 5])), [3 4]));
assert(isequal(blkdiag([], [1 2]), [1 2]));
assert(isempty(blkdiag([], [])));
assert(isequal(blkdiag(eye(2)), eye(2)));

%% -------------------------------------------------------------- setxor
% La difference symetrique : ce qui est dans l'un ou dans l'autre, jamais
% dans les deux. Les positions rendues designent la source de chaque
% valeur.
assert(isequal(setxor([1 2 3 4], [3 4 5]), [1 2 5]));
[cx, iax, ibx] = setxor([5 1 3], [3 9]);
assert(isequal(cx, [1 5 9]));
assert(isequal(sort(iax(:))', [1 2]));
assert(isequal(ibx, 2));
assert(isequal(setxor([1 2 3 4], [3 4 5], 'stable'), [1 2 5]));
sx = setxor({'a','b'}, {'b','c'});
assert(numel(sx) == 2 && strcmp(sx{1}, 'a') && strcmp(sx{2}, 'c'));
% Deux ensembles egaux ne laissent rien.
assert(isempty(setxor([1 2], [2 1])));

%% ------------------------------------------------------------- repelem
% Chaque element est repete sur place, ce qui n'est pas repmat : repmat
% recopie le tableau entier, repelem etale chaque valeur.
assert(isequal(repelem([1 2 3], 2), [1 1 2 2 3 3]));
assert(isequal(repelem([1 2 3], [1 2 3]), [1 2 2 3 3 3]));
assert(isequal(repelem([1 2; 3 4], 2, 3), ...
               [1 1 1 2 2 2; 1 1 1 2 2 2; 3 3 3 4 4 4; 3 3 3 4 4 4]));
assert(isequal(size(repelem(zeros(2, 3), [1 2], [2 0 1])), [3 3]));
assert(isequal(repelem([1; 2], 3), [1; 1; 1; 2; 2; 2]));
r = repelem({'a', 'b'}, 2);
assert(numel(r) == 4 && strcmp(r{2}, 'a'));

%% ------------------------------------------------------------ shiftdim
a4 = ones(1, 1, 3, 2);
[b4, n4] = shiftdim(a4);
assert(isequal(size(b4), [3 2]) && n4 == 2);
assert(isequal(size(shiftdim(ones(2, 3), 1)), [3 2]));
assert(isequal(size(shiftdim(ones(2, 3), -2)), [1 1 2 3]));
assert(shiftdim(5) == 5);
c3 = reshape(1:12, [2 3 2]);
d3 = shiftdim(c3, 1);
assert(isequal(size(d3), [3 2 2]));
assert(isequal(d3(:, :, 1), [1 7; 3 9; 5 11]));

%% ------------------------------------------------------------ issorted
assert(issorted([1 2 2 5]));
assert(~issorted([1 2 2 5], 'strictascend'));
assert(issorted([5 3 1], 'descend'));
assert(issorted([5 3 1], 'monotonic'));
assert(issorted({'a', 'b'}));
assert(issortedrows([1 2; 1 3; 2 0]));
assert(~issortedrows([1 2; 1 3; 2 0], -1));

%% --------------------------------------------------------------- convn
% La convolution a N dimensions. En deux dimensions elle doit rendre
% exactement ce que rend conv2, sans quoi l'une des deux est fausse.
assert(isequal(convn([1 2 3], [1 1]), [1 3 5 3]));
assert(isequal(convn(magic(3), ones(2), 'same'), conv2(magic(3), ones(2), 'same')));
v3 = convn(ones(3, 3, 3), ones(2, 2, 2), 'valid');
assert(isequal(size(v3), [2 2 2]) && all(v3(:) == 8));
assert(isequal(size(convn(ones(3, 3, 3), ones(2, 2, 2))), [4 4 4]));
f3 = convn(reshape(1:8, 2, 2, 2), ones(1, 1, 2));
assert(isequal(size(f3), [2 2 3]));
assert(isequal(f3(:, :, 2), [6 10; 8 12]));

%% ----------------------------------------------------------- pagemtimes
ap = reshape(1:8, 2, 2, 2);
cp = pagemtimes(ap, ap);
assert(isequal(cp(:, :, 1), ap(:, :, 1) * ap(:, :, 1)));
assert(isequal(cp(:, :, 2), ap(:, :, 2) * ap(:, :, 2)));
bp = pagemtimes(ap, 'transpose', ap, 'none');
assert(isequal(bp(:, :, 2), ap(:, :, 2)' * ap(:, :, 2)));
% Une seule page sert a toutes les autres.
dp = pagemtimes(ap, [1; 1]);
assert(isequal(size(dp), [2 1 2]) && isequal(dp(:, :, 2)', [12 14]));
assert(isequal(pagetranspose(ap), permute(ap, [2 1 3])));

%% ------------------------------------------------------------ swapbytes
assert(swapbytes(uint16(1)) == 256);
assert(swapbytes(uint32(1)) == 16777216);
% Deux inversions rendent la valeur de depart, quelle que soit la classe.
assert(isequal(swapbytes(swapbytes(int16([-2 300]))), int16([-2 300])));
assert(isequal(swapbytes(swapbytes(double(pi))), double(pi)));
assert(isequal(swapbytes(uint8([1 2])), uint8([1 2])));

%% ----------------------------------------------------------- discretize
assert(isequal(discretize([1 2 3 4 5], [1 3 5]), [1 1 2 2 2]));
assert(all(isnan(discretize([0 6], [1 3 5]))));
[bd, ed] = discretize([1 2 3 4], 2);
assert(isequal(bd, [1 1 2 2]) && isequal(ed, [1 2.5 4]));
assert(isequal(discretize([1 3 5], [1 3 5], 'IncludedEdge', 'right'), [1 1 2]));
nd = discretize([1 2 3 4 5], [1 3 5], {'bas', 'haut'});
assert(strcmp(nd{1}, 'bas') && strcmp(nd{5}, 'haut'));

%% -------------------------------- estimations de norme et de conditionnement
% NORMEST monte vers la norme spectrale par la methode de la puissance :
% l'estimation est une borne inferieure, atteinte a la tolerance pres.
A = magic(5);
assert(abs(normest(A) - norm(A)) / norm(A) < 1e-6);
assert(normest(A) <= norm(A) * (1 + 1e-9), 'jamais au-dessus');
assert(abs(normest(eye(4)) - 1) < 1e-12);
assert(normest(zeros(3)) == 0, 'la matrice nulle a une norme nulle');

% NORMEST1 cherche le sommet du cube unite ou la norme 1 est atteinte, et
% rend le temoin de son estimation.
assert(abs(normest1(magic(5)) - norm(magic(5), 1)) < 1e-10);
[estimation, v, w] = normest1(magic(4));
assert(abs(norm(w, 1) - estimation * norm(v, 1)) < 1e-10, ...
       'le temoin verifie l''estimation');
assert(estimation <= norm(magic(4), 1) * (1 + 1e-9), 'borne inferieure');

% COND(A,P) n'est pas COND(A) : pour la matrice de Hilbert d'ordre six,
% 1,5e7 en norme 2 et 2,9e7 en norme 1. Ignorer P rendait une valeur
% fausse en silence.
H = hilb(6);
assert(abs(cond(H, 1) - norm(H, 1) * norm(inv(H), 1)) / cond(H, 1) < 1e-10);
assert(abs(cond(H, inf) - norm(H, inf) * norm(inv(H), inf)) / cond(H, inf) < 1e-10);
assert(abs(cond(H, 2) - cond(H)) < 1e-6 * cond(H));
assert(cond(H, 1) > 1.5 * cond(H, 2), 'les deux normes ne disent pas la meme chose');
assert(abs(cond(eye(3), 1) - 1) < 1e-12);

% CONDEST estime la norme 1 de l'inverse sans former l'inverse : chaque
% produit devient une resolution. C'est une borne inferieure.
assert(abs(condest(eye(3)) - 1) < 1e-12);
assert(condest(H) <= cond(H, 1) * (1 + 1e-9));
assert(condest(H) > 1e6, 'la matrice de Hilbert est infame');
assert(abs(condest([2 0; 0 1]) - 2) < 1e-12);

%% -------------------------------------------- methodes de Krylov
% Les quatre convergent a la precision machine sur un systeme bien pose.
A = [4 1 0; 1 3 1; 0 1 2];
b = [1; 2; 3];
for f = {@pcg, @bicg, @cgs, @minres}
    [x, drapeau, ~, iterations] = f{1}(A, b, 1e-12, 50);
    assert(drapeau == 0, 'la tolerance doit etre atteinte');
    assert(norm(A * x - b) / norm(b) < 1e-11);
    assert(iterations <= 3, 'au plus N iterations en arithmetique exacte');
end
% La matrice n'est jamais demandee, seulement son action sur un vecteur.
x = pcg(@(v) A * v, b, 1e-12, 50);
assert(norm(A * x - b) < 1e-11);
% BICG et CGS ne demandent pas la definie positivite.
B = [2 1; 5 7];
c = [11; 13];
assert(norm(B * bicg(B, c, 1e-12, 50) - c) < 1e-10);

% GMRES minimise le residu a chaque pas : il ne peut que decroitre. C'est
% ce qu'aucune methode a recurrence courte ne garantit sur une matrice non
% symetrique.
C = [2 1 0; 5 7 1; 0 1 3];
d = [11; 13; 5];
[x, drapeau, ~, compteur] = gmres(C, d, [], 1e-12, 20);
assert(drapeau == 0 && norm(C * x - d) / norm(d) < 1e-11);
assert(compteur(2) <= 3, 'exact en N pas');
rng(1);
G = randn(20) + 20 * eye(20);
g = randn(20, 1);
[x, drapeau, ~, ~, historique] = gmres(G, g, [], 1e-12, 30);
assert(drapeau == 0 && norm(G * x - g) / norm(g) < 1e-10);
assert(all(diff(historique) <= 1e-14), 'le residu de GMRES est monotone');
% Le redemarrage borne la memoire et converge encore ici.
assert(norm(C * gmres(C, d, 2, 1e-12, 40) - d) / norm(d) < 1e-10);

%% ------------------------------------- moindre norme, pages, tenseurs
% LSQMINNORM rend, parmi les solutions equivalentes, celle de plus petite
% norme ; l'antislash en rend une autre, a coefficients epars.
M = [1 1; 1 1];
v = [2; 2];
x = lsqminnorm(M, v);
assert(norm(M * x - v) < 1e-12, 'c''est bien une solution des moindres carres');
assert(norm(x) <= norm(M \ v) + 1e-12, 'et de norme minimale');
% Sur une matrice de rang plein, les deux coincident.
D = [1 2; 3 4];
assert(norm(lsqminnorm(D, [5; 6]) - D \ [5; 6]) < 1e-10);

% Les operations par page ne melangent pas les pages.
P = cat(3, [2 0; 0 4], [1 1; 0 1]);
Q = pageinv(P);
assert(max(max(max(abs(pagemtimes(P, Q) - cat(3, eye(2), eye(2)))))) < 1e-12);
R = cat(3, [2; 4], [3; 1]);
X = pagemldivide(P, R);
assert(max(max(max(abs(pagemtimes(P, X) - R)))) < 1e-12);

% TENSORPROD contracte les indices qu'on lui dit : contracter la deuxieme
% dimension de A avec la premiere de B redonne le produit matriciel.
assert(max(max(abs(tensorprod(D, [5 6; 7 8], 2, 1) - D * [5 6; 7 8]))) < 1e-12);
assert(abs(tensorprod([1 2 3], [4 5 6], 2, 2) - 32) < 1e-12);
assert(isequal(size(tensorprod(ones(2, 3), ones(4, 5))), [2 3 4 5]));
assert(abs(tensorprod(D, D, 'all') - sum(sum(D .* D))) < 1e-12);

% MAXK, MINK, EIGS et SVDS : le sommet, sans trier plus qu'il ne faut.
assert(isequal(maxk([3 1 4 1 5], 2), [5 4]));
[dessus, rangs] = maxk([3 1 4 1 5], 2);
assert(isequal(rangs, [5 3]));
assert(isequal(mink([3 1 4 1 5], 2), [1 1]));
assert(isequal(mink([3 1 4], 3), sort([3 1 4])), 'tout prendre, c''est trier');
assert(isequal(maxk([1 2; 3 4], 1), [3 4]), 'par colonne');

E = diag([1 2 3 10]);
assert(isequal(eigs(E, 2)', [10 3]));
assert(isequal(eigs(E, 2, 'smallestabs')', [1 2]));
[vecteurs, valeurs] = eigs(E, 1);
assert(norm(E * vecteurs - vecteurs * valeurs) < 1e-12);

F = magic(4);
valeursSing = svd(F);
assert(max(abs(svds(F, 2) - valeursSing(1:2))) < 1e-10);
[Us, Ss, Vs] = svds(F, 1);
assert(abs(norm(F - Us * Ss * Vs') - valeursSing(2)) < 1e-9, ...
       'Eckart-Young : l''erreur de rang un est la valeur singuliere suivante');

% PAGESVD decompose chaque page separement : aucune page n'influence une
% autre, et la reconstruction se verifie page par page.
P3 = cat(3, diag([3 1]), diag([2 5]));
valeurs = pagesvd(P3);
assert(isequal(valeurs(:, :, 1)', [3 1]));
assert(isequal(valeurs(:, :, 2)', [5 2]), 'les valeurs sortent decroissantes');
[Up, Sp, Vp] = pagesvd(P3);
assert(max(max(max(abs(pagemtimes(pagemtimes(Up, Sp), pagetranspose(Vp)) - P3)))) < 1e-12);

%% ------------------------- factorisations incompletes et renumerotations
% « Incomplete » designe ce qu'on abandonne : le remplissage. L et L' ne
% valent plus A, mais le motif ne s'etend pas, et c'est ce qu'on achete.
n = 30;
T = full(spdiags([-ones(n, 1), 2 * ones(n, 1), -ones(n, 1)], -1:1, n, n));
Li = ichol(T);
assert(istril(Li), 'la factorisation rend une triangulaire inferieure');
assert(nnz(Li) <= nnz(tril(T)), 'et ne remplit rien de neuf');
% Sur une tridiagonale, il n'y a rien a remplir : la factorisation
% incomplete est alors exacte, et le preconditionneur parfait.
assert(norm(T - Li * Li') < 1e-10);
bb = ones(n, 1);
[~, ~, ~, sansPrecond] = pcg(T, bb, 1e-10, 200);
[~, ~, ~, avecPrecond] = pcg(T, bb, 1e-10, 200, Li * Li');
assert(avecPrecond <= sansPrecond, 'le preconditionneur ne peut pas nuire');
assert(avecPrecond == 1, 'et ici il resout d''un coup');
% La diagonale decalee sauve une matrice que la factorisation refuse.
assert(istril(ichol(T, struct('diagcomp', 0.1))));

m = 20;
Q = full(spdiags([-ones(m, 1), 4 * ones(m, 1), -ones(m, 1)], -1:1, m, m));
[Lq, Uq] = ilu(Q);
assert(istril(Lq) && istriu(Uq));
assert(max(abs(diag(Lq) - 1)) < 1e-12, 'la diagonale de L vaut un');
assert(norm(Q - Lq * Uq) < 1e-10, 'sans remplissage a faire, c''est exact');
% Un pivot nul arrete la factorisation sans permutation : le dire vaut
% mieux que rendre des infinis.
leve = false;
try
    ilu([0 1; 1 0]);
catch
    leve = true;
end
assert(leve);

% SYMRCM range les coefficients pres de la diagonale.
C = [1 0 1 0; 0 1 0 1; 1 0 1 0; 0 1 0 1];
pr = symrcm(C);
assert(isequal(sort(pr), 1:4), 'c''est une permutation');
assert(matlibre_largeur_bande(C(pr, pr)) <= matlibre_largeur_bande(C));
% Sur une matrice deja bandee, il ne peut pas faire pire.
B5 = full(spdiags(ones(5, 3), -1:1, 5, 5));
p5 = symrcm(B5);
assert(matlibre_largeur_bande(B5(p5, p5)) <= 1);

% SYMAMD et COLAMD reduisent le remplissage, non la bande : ce sont deux
% objectifs differents. Le noeud le plus lie n'est pas elimine en premier.
D4 = [1 1 1 1; 1 1 0 0; 1 0 1 0; 1 0 0 1];
pa = symamd(D4);
assert(isequal(sort(pa), 1:4));
assert(find(pa == 1) > 1, 'le noeud de degre trois attend son tour');
E4 = [1 1 1; 1 0 0; 1 0 0; 0 1 0];
pc = colamd(E4);
assert(isequal(sort(pc), 1:3), 'une permutation des colonnes');
assert(isequal(sort(symamd(eye(4))), 1:4), 'une diagonale se permute aussi');

disp('matrices : toutes les verifications passent');
