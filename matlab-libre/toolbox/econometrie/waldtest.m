function [rejet, pValeur, statistique, valeurCritique] = waldtest(ecarts, jacobien, covariance, alpha)
%WALDTEST Test de Wald sur des restrictions paramétriques.
%   H = WALDTEST(R,JAC,COV) teste les restrictions r(theta) = 0. R est le
%   vecteur des restrictions évaluées à l'estimation libre, JAC leur
%   jacobienne par rapport aux paramètres, COV la matrice de covariance
%   des paramètres estimés. H vaut un quand les restrictions sont
%   rejetées.
%
%   Le test ne demande que le modèle libre : il mesure de combien
%   d'écarts-types les restrictions sont violées. La forme quadratique
%   R'*inv(JAC*COV*JAC')*R suit un khi-deux à autant de degrés de liberté
%   qu'il y a de restrictions.
%
%   Pour des restrictions linéaires A*theta = c, prendre
%   R = A*theta - c et JAC = A.
%
%   H = WALDTEST(...,ALPHA) règle le seuil (0,05 par défaut).
%   [H,P,STAT,CRIT] = WALDTEST(...) rend la valeur p, la statistique et
%   la valeur critique.
%
%   R, JAC et COV peuvent être des tableaux de cellules : le test est
%   alors mené pour chaque triplet.
%
%   Exemple :
%      % Le second coefficient d'une régression est-il nul ?
%      m = ols(y, X);
%      A = [0 1 0];
%      waldtest(A * m.beta, A, m.sigma2 * inv(X' * X))
%
%   Voir aussi LRATIOTEST, OLS, GCTEST.
    if nargin < 3
        error('econ:waldtest:Arguments', ...
              'Il faut les restrictions, leur jacobienne et la covariance.');
    end
    if nargin < 4 || isempty(alpha)
        alpha = 0.05;
    end
    if ~iscell(ecarts),     ecarts = {ecarts};         end
    if ~iscell(jacobien),   jacobien = {jacobien};     end
    if ~iscell(covariance), covariance = {covariance}; end
    nombre = max([numel(ecarts), numel(jacobien), numel(covariance)]);
    ecarts = matlibre_etendre_cellules(ecarts, nombre, 'restrictions');
    jacobien = matlibre_etendre_cellules(jacobien, nombre, 'jacobiennes');
    covariance = matlibre_etendre_cellules(covariance, nombre, 'covariances');
    statistique = zeros(1, nombre);
    ddl = zeros(1, nombre);
    for k = 1:nombre
        r = double(ecarts{k});
        r = r(:);
        J = double(jacobien{k});
        C = double(covariance{k});
        if size(J, 1) ~= numel(r)
            error('econ:waldtest:Jacobien', ...
                  ['La jacobienne doit avoir autant de lignes que ' ...
                   'de restrictions.']);
        end
        if size(J, 2) ~= size(C, 1) || size(C, 1) ~= size(C, 2)
            error('econ:waldtest:Covariance', ...
                  ['La covariance doit être carrée, de la taille du ' ...
                   'nombre de paramètres.']);
        end
        milieu = J * C * J.';
        statistique(k) = r.' * (milieu \ r);
        ddl(k) = numel(r);
    end
    pValeur = 1 - chi2cdf(statistique, ddl);
    valeurCritique = chi2inv(1 - alpha, ddl);
    rejet = pValeur < alpha;
    if nombre == 1
        statistique = statistique(1);
        pValeur = pValeur(1);
        valeurCritique = valeurCritique(1);
        rejet = rejet(1);
    end
end
