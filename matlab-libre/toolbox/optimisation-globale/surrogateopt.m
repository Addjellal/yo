function [x, valeur, drapeau, sortie] = surrogateopt(fonction, bas, haut, options)
%SURROGATEOPT Optimisation par modèle de substitution.
%   X = SURROGATEOPT(F,BAS,HAUT) minimise une fonction coûteuse en
%   construisant, à partir des points déjà évalués, une surface de
%   réponse à base radiale ; le point suivant est choisi là où le modèle
%   est bas et où l'on n'a pas encore regardé.
%
%   Utile quand chaque évaluation prend du temps : le nombre d'appels à
%   F reste petit.
%
%   Exemple :
%      x = surrogateopt(@(v) (v(1)-0.3)^2 + (v(2)+0.7)^2, [-1 -1], [1 1]);
    if nargin < 4, options = struct(); end
    bas = double(bas(:))';
    haut = double(haut(:))';
    n = numel(bas);
    budget = champOptimisation(options, 'MaxFunctionEvaluations', 100);
    depart = champOptimisation(options, 'MinSurrogatePoints', max(5, 2 * n + 1));
    % Amorçage : un plan d'expérience régulier, complété au hasard.
    points = repmat(bas, depart, 1) + ...
             rand(depart, n) .* repmat(haut - bas, depart, 1);
    points(1, :) = (bas + haut) / 2;
    valeurs = zeros(depart, 1);
    for k = 1:depart
        valeurs(k) = fonction(points(k, :));
    end
    evaluations = depart;
    while evaluations < budget
        poids = ajusterRadiales(points, valeurs);
        % Candidats : autour du meilleur point et un peu partout.
        [~, meilleurIndice] = min(valeurs);
        centre = points(meilleurIndice, :);
        rayon = (haut - bas) / 4;
        candidats = [repmat(centre, 30, 1) + (rand(30, n) - 0.5) .* repmat(rayon, 30, 1);
                     repmat(bas, 30, 1) + rand(30, n) .* repmat(haut - bas, 30, 1)];
        candidats = min(max(candidats, repmat(bas, size(candidats, 1), 1)), ...
                        repmat(haut, size(candidats, 1), 1));
        prediction = evaluerRadiales(points, poids, candidats);
        distance = distanceMinimale(candidats, points);
        % Compromis entre modèle bas et exploration : on normalise les
        % deux critères avant de les mêler.
        note = normaliser(prediction) - 0.3 * normaliser(distance);
        [~, choisi] = min(note);
        nouveau = candidats(choisi, :);
        points(end + 1, :) = nouveau;                 %#ok<AGROW>
        valeurs(end + 1, 1) = fonction(nouveau);      %#ok<AGROW>
        evaluations = evaluations + 1;
    end
    [valeur, meilleurIndice] = min(valeurs);
    x = points(meilleurIndice, :);
    drapeau = 1;
    sortie = struct('funccount', evaluations, 'algorithm', 'substitution radiale');
end

function poids = ajusterRadiales(points, valeurs)
%AJUSTERRADIALES Interpolation par fonctions de base radiales cubiques.
    M = noyauRadial(matriceDistances(points, points));
    poids = (M + 1e-8 * eye(size(M, 1))) \ valeurs;
end

function y = evaluerRadiales(points, poids, candidats)
    y = noyauRadial(matriceDistances(candidats, points)) * poids;
end

function D = matriceDistances(A, B)
%MATRICEDISTANCES Distances euclidiennes entre deux jeux de points.
%   Le développement du carré évite toute boucle : c'est la seule façon
%   de rester rapide quand les candidats se comptent par dizaines.
    normesA = sum(A .^ 2, 2);
    normesB = sum(B .^ 2, 2);
    carres = repmat(normesA, 1, size(B, 1)) + repmat(normesB', size(A, 1), 1) - 2 * (A * B');
    D = sqrt(max(carres, 0));
end

function v = noyauRadial(r)
    v = r .^ 3;
end

function d = distanceMinimale(candidats, points)
    d = min(matriceDistances(candidats, points), [], 2);
end

function y = normaliser(v)
    etendue = max(v) - min(v);
    if etendue == 0
        y = zeros(size(v));
    else
        y = (v - min(v)) / etendue;
    end
end
