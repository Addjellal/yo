function [x, drapeau, residu, iterations, residus] = ...
        gmres(A, b, redemarrage, tolerance, maxIterations, M1, M2, x0)
%GMRES Résidu minimal généralisé.
%   X = GMRES(A,B) résout A*X = B pour une matrice quelconque, carrée et
%   inversible. X = GMRES(A,B,REDEMARRAGE) redémarre l'algorithme tous les
%   REDEMARRAGE pas ; [] ne redémarre pas.
%   X = GMRES(A,B,REDEMARRAGE,TOL,MAXIT,M1,M2,X0) impose la tolérance
%   relative, le nombre de cycles, un préconditionneur et un point de
%   départ. A peut être une poignée de fonction rendant A*x.
%
%   [X,DRAPEAU,RES,K,RESIDUS] = GMRES(...) rend le drapeau — 0 si la
%   tolérance est atteinte —, le résidu relatif, le nombre d'itérations et
%   leur historique.
%
%   GMRES choisit dans l'espace de Krylov le point qui minimise la norme
%   du résidu. C'est ce qui le rend monotone : le résidu ne peut jamais
%   remonter d'une itération à l'autre, ce qu'aucune des méthodes à
%   récurrence courte ne garantit sur une matrice non symétrique.
%
%   Le prix est la mémoire : il faut garder toute la base de Krylov, donc
%   K vecteurs à la K-ième itération, et le travail croît comme K carré.
%   D'où le redémarrage, qui vide la base tous les REDEMARRAGE pas —
%   mémoire bornée, mais la monotonie n'est plus garantie d'un cycle à
%   l'autre, et l'algorithme peut stagner.
%
%   L'orthogonalisation est celle d'Arnoldi, et le petit système des
%   moindres carrés est résolu par rotations de Givens appliquées au fur
%   et à mesure : le résidu est alors connu à chaque pas sans avoir à
%   former la solution.
%
%   Exemple :
%      A = [2 1 0; 5 7 1; 0 1 3];
%      b = [11; 13; 5];
%      x = gmres(A, b, [], 1e-12, 20);
%      norm(A * x - b) / norm(b) < 1e-11
%
%   Voir aussi PCG, BICG, CGS, MINRES, MLDIVIDE.
    b = double(b(:));
    n = numel(b);
    if nargin < 3, redemarrage = []; end
    if nargin < 4 || isempty(tolerance), tolerance = 1e-6; end
    if isempty(redemarrage) || redemarrage >= n
        redemarrage = n;
        cyclesDefaut = 1;
    else
        cyclesDefaut = ceil(n / redemarrage);
    end
    if nargin < 5 || isempty(maxIterations), maxIterations = cyclesDefaut; end
    M = [];
    if nargin >= 6 && ~isempty(M1), M = M1; end
    if nargin >= 7 && ~isempty(M2)
        if isempty(M), M = M2; else, M = M * M2; end
    end
    if nargin < 8 || isempty(x0), x0 = zeros(n, 1); end
    x = double(x0(:));

    appliquer = @(v) matlibre_krylov_produit(A, v);
    if isempty(M)
        precond = @(v) v;
    elseif isa(M, 'function_handle')
        precond = M;
    else
        precond = @(v) M \ v;
    end

    normeB = norm(precond(b));
    if normeB == 0
        x = zeros(n, 1);
        drapeau = 0; residu = 0; iterations = [0 0]; residus = 0;
        return
    end
    drapeau = 1;
    residus = norm(precond(b - appliquer(x))) / normeB;
    iterations = [0 0];

    for cycle = 1:maxIterations
        r = precond(b - appliquer(x));
        beta = norm(r);
        if beta / normeB <= tolerance
            drapeau = 0;
            break
        end
        Q = zeros(n, redemarrage + 1);
        Q(:, 1) = r / beta;
        H = zeros(redemarrage + 1, redemarrage);
        cosinus = zeros(redemarrage, 1);
        sinus = zeros(redemarrage, 1);
        g = zeros(redemarrage + 1, 1);
        g(1) = beta;
        k = 0;
        for j = 1:redemarrage
            % Arnoldi : un vecteur de plus dans la base, orthogonalise
            % contre tous les precedents.
            w = precond(appliquer(Q(:, j)));
            for i = 1:j
                H(i, j) = Q(:, i)' * w;
                w = w - H(i, j) * Q(:, i);
            end
            H(j + 1, j) = norm(w);
            % La sous-diagonale avant rotation : c'est elle qui dit si
            % l'espace de Krylov est epuise. Apres la rotation elle vaut
            % zero par construction, et la tester alors arreterait tout
            % des la premiere iteration.
            sousDiagonale = H(j + 1, j);
            if sousDiagonale > 0
                Q(:, j + 1) = w / sousDiagonale;
            end
            % Les rotations deja posees s'appliquent a la colonne neuve.
            for i = 1:j - 1
                temporaire = cosinus(i) * H(i, j) + sinus(i) * H(i + 1, j);
                H(i + 1, j) = -sinus(i) * H(i, j) + cosinus(i) * H(i + 1, j);
                H(i, j) = temporaire;
            end
            denominateur = hypot(H(j, j), H(j + 1, j));
            if denominateur == 0
                cosinus(j) = 1; sinus(j) = 0;
            else
                cosinus(j) = H(j, j) / denominateur;
                sinus(j) = H(j + 1, j) / denominateur;
            end
            H(j, j) = cosinus(j) * H(j, j) + sinus(j) * H(j + 1, j);
            H(j + 1, j) = 0;
            g(j + 1) = -sinus(j) * g(j);
            g(j) = cosinus(j) * g(j);
            k = j;
            residus(end + 1) = abs(g(j + 1)) / normeB;   %#ok<AGROW>
            iterations = [cycle, j];
            if residus(end) <= tolerance || sousDiagonale == 0
                break
            end
        end
        y = H(1:k, 1:k) \ g(1:k);
        x = x + Q(:, 1:k) * y;
        if residus(end) <= tolerance
            drapeau = 0;
            break
        end
    end
    residu = residus(end);
end
