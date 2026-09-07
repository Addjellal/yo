function [x, drapeau, residu, iterations, residus] = ...
        matlibre_krylov(methode, A, b, tolerance, maxIterations, M, x0)
%MATLIBRE_KRYLOV Rouage commun des méthodes de Krylov.
%   Il tient ce que PCG, BICG, CGS et MINRES ont en commun : la lecture
%   des arguments, le produit par A donné en matrice ou en poignée, le
%   préconditionneur, le critère d'arrêt et l'historique des résidus.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Toutes ces méthodes cherchent la solution dans l'espace de Krylov
%   engendré par b, A*b, A^2*b… Elles n'en diffèrent que par la façon d'y
%   choisir un point : minimiser l'erreur en norme A pour le gradient
%   conjugué, le résidu en norme 2 pour MINRES, imposer une orthogonalité
%   croisée pour BICG.
%
%   Exemple :
%      x = matlibre_krylov('pcg', [4 1; 1 3], [1; 2], 1e-10, 20, [], []);
%      norm([4 1; 1 3] * x - [1; 2]) < 1e-9
%
%   Voir aussi PCG, BICG, CGS, MINRES, GMRES.
    if nargin < 4 || isempty(tolerance), tolerance = 1e-6; end
    b = double(b(:));
    n = numel(b);
    if nargin < 5 || isempty(maxIterations), maxIterations = min(n, 20); end
    if nargin < 6, M = []; end
    if nargin < 7 || isempty(x0), x0 = zeros(n, 1); end
    x = double(x0(:));

    appliquer = @(v) matlibre_krylov_produit(A, v);
    if isempty(M)
        precond = @(v) v;
    elseif isa(M, 'function_handle')
        precond = M;
    else
        precond = @(v) M \ v;
    end

    normeB = norm(b);
    if normeB == 0
        x = zeros(n, 1);
        drapeau = 0; residu = 0; iterations = 0; residus = 0;
        return
    end

    r = b - appliquer(x);
    residus = norm(r) / normeB;
    drapeau = 1;
    iterations = 0;

    switch methode
        case 'pcg'
            z = precond(r);
            p = z;
            rho = r' * z;
            for k = 1:maxIterations
                q = appliquer(p);
                denominateur = p' * q;
                if denominateur == 0, break, end
                alpha = rho / denominateur;
                x = x + alpha * p;
                r = r - alpha * q;
                residus(end + 1) = norm(r) / normeB;   %#ok<AGROW>
                iterations = k;
                if residus(end) <= tolerance
                    drapeau = 0;
                    break
                end
                z = precond(r);
                rhoNeuf = r' * z;
                p = z + (rhoNeuf / rho) * p;
                rho = rhoNeuf;
            end
        case 'minres'
            % MINRES sur une matrice symetrique : le gradient conjugue
            % applique aux equations normales du residu, ce qui n'exige
            % plus la definie positivite.
            p = precond(r);
            s = appliquer(p);
            for k = 1:maxIterations
                denominateur = s' * s;
                if denominateur == 0, break, end
                alpha = (r' * s) / denominateur;
                x = x + alpha * p;
                r = r - alpha * s;
                residus(end + 1) = norm(r) / normeB;   %#ok<AGROW>
                iterations = k;
                if residus(end) <= tolerance
                    drapeau = 0;
                    break
                end
                z = precond(r);
                w = appliquer(z);
                beta = -(w' * s) / denominateur;
                p = z + beta * p;
                s = w + beta * s;
            end
        case {'bicg', 'cgs'}
            % Le residu fantome : BICG poursuit en parallele le systeme
            % transpose, et c'est l'orthogonalite croisee des deux suites
            % qui remplace celle du gradient conjugue.
            rChapeau = r;
            rho = 1; alpha = 1; omega = 1;
            v = zeros(n, 1); p = zeros(n, 1);
            for k = 1:maxIterations
                rhoNeuf = rChapeau' * r;
                if rhoNeuf == 0, break, end
                if k == 1
                    p = r;
                else
                    beta = (rhoNeuf / rho) * (alpha / omega);
                    p = r + beta * (p - omega * v);
                end
                pChapeau = precond(p);
                v = appliquer(pChapeau);
                denominateur = rChapeau' * v;
                if denominateur == 0, break, end
                alpha = rhoNeuf / denominateur;
                s = r - alpha * v;
                if norm(s) / normeB <= tolerance
                    x = x + alpha * pChapeau;
                    residus(end + 1) = norm(s) / normeB;   %#ok<AGROW>
                    iterations = k;
                    drapeau = 0;
                    break
                end
                sChapeau = precond(s);
                t = appliquer(sChapeau);
                denominateur = t' * t;
                if denominateur == 0, break, end
                omega = (t' * s) / denominateur;
                x = x + alpha * pChapeau + omega * sChapeau;
                r = s - omega * t;
                residus(end + 1) = norm(r) / normeB;   %#ok<AGROW>
                iterations = k;
                if residus(end) <= tolerance
                    drapeau = 0;
                    break
                end
                if omega == 0, break, end
                rho = rhoNeuf;
            end
        otherwise
            error('MATLAB:krylov:UnknownMethod', 'Méthode inconnue : %s.', methode);
    end
    residu = residus(end);
end
