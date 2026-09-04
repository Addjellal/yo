function [risques, rendements, poids] = portopt(rendementsAttendus, covariance, nombrePoints, rendementsCibles, contraintes)
%PORTOPT Frontière efficiente sous contraintes linéaires.
%   [R,M,W] = PORTOPT(MU,SIGMA,N) rend N portefeuilles de la frontière :
%   leur écart type, leur rendement et leurs poids. CONTRAINTES est un
%   jeu [A b] tel que le rendent PORTCONS et ses voisines ; sans lui, les
%   poids sont positifs et somment à un.
%
%   PORTOPT(MU,SIGMA,[],CIBLES,CONTRAINTES) calcule un portefeuille pour
%   chaque rendement visé.
%
%   La frontière efficiente est l'ensemble des portefeuilles de variance
%   minimale pour chaque niveau de rendement. Elle s'obtient en résolvant
%   un programme quadratique par point : le critère est la variance, la
%   contrainte est le rendement visé.
%
%   Exemple :
%      mu = [0.10 0.15 0.12];
%      s = [0.04 0.01 0.00; 0.01 0.09 0.02; 0.00 0.02 0.06];
%      [r, m, w] = portopt(mu, s, 5)
%
%   Voir aussi FRONTCON, PORTCONS, PORTSTATS, PORTALLOC, PORTVAR.
    rendementsAttendus = double(rendementsAttendus(:));
    covariance = double(covariance);
    n = numel(rendementsAttendus);
    if nargin < 3, nombrePoints = []; end
    if nargin < 4, rendementsCibles = []; end
    if nargin < 5 || isempty(contraintes)
        contraintes = pcpval(1, n);
    end
    A = contraintes(:, 1:(end - 1));
    b = contraintes(:, end);
    if isempty(rendementsCibles)
        if isempty(nombrePoints)
            nombrePoints = 10;
        end
        % Bornes de la frontière : le portefeuille de variance minimale
        % d'un côté, celui de rendement maximal de l'autre.
        [poidsMin, bon] = matlibre_qp_actif(2 * covariance, zeros(n, 1), A, b, [], []);
        if ~bon
            error('finance:portopt:Contraintes', ...
                  'Les contraintes ne définissent aucun portefeuille admissible.');
        end
        rendementMin = rendementsAttendus.' * poidsMin;
        poidsMax = linprog(-rendementsAttendus, A, b);
        rendementMax = rendementsAttendus.' * poidsMax(:);
        if nombrePoints == 1
            rendementsCibles = rendementMax;
        else
            rendementsCibles = linspace(rendementMin, rendementMax, nombrePoints);
        end
    end
    rendementsCibles = double(rendementsCibles(:)).';
    nombre = numel(rendementsCibles);
    poids = zeros(nombre, n);
    risques = zeros(nombre, 1);
    rendements = zeros(nombre, 1);
    for k = 1:nombre
        [w, bon] = matlibre_qp_actif(2 * covariance, zeros(n, 1), A, b, ...
                                     rendementsAttendus.', rendementsCibles(k));
        if ~bon
            w = quadprog(2 * covariance, zeros(n, 1), A, b, ...
                         rendementsAttendus.', rendementsCibles(k));
        end
        poids(k, :) = w(:).';
        rendements(k) = rendementsAttendus.' * w(:);
        risques(k) = sqrt(w(:).' * covariance * w(:));
    end
end
