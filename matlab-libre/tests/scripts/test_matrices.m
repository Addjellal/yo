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

disp('matrices : toutes les verifications passent');
