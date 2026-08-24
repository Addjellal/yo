function [fis, erreurs] = anfis(donnees, fisInitial, epoques, pasInitial)
%ANFIS Apprentissage d'un système de Sugeno par méthode hybride.
%   FIS = ANFIS(DONNEES) apprend un système à partir d'une matrice dont
%   les premières colonnes sont les entrées et la dernière la sortie.
%   FIS = ANFIS(DONNEES,FIS0) part d'un système donné, construit par
%   GENFIS1 ou GENFIS2.
%   FIS = ANFIS(DONNEES,FIS0,N) fixe le nombre d'époques, dix par défaut.
%   [FIS,ERREURS] = ANFIS(...) rend l'erreur quadratique moyenne à chaque
%   époque.
%
%   L'apprentissage est celui de Jang : à chaque époque, les paramètres
%   de conclusion sont trouvés exactement par moindres carrés — la sortie
%   en dépend linéairement —, puis les paramètres de prémisse sont
%   corrigés par descente de gradient. Le pas s'adapte : il croît de dix
%   pour cent quand l'erreur baisse, et se réduit de moitié sinon.
%
%   C'est cette séparation qui fait la force de la méthode : la moitié
%   linéaire du problème est résolue d'un coup au lieu d'être approchée.
%
%   Exemple :
%      x = (0:0.05:10)';
%      donnees = [x, sin(x)];
%      [fis, e] = anfis(donnees, genfis1(donnees, 7), 20);
%      e(end) < e(1)   % vrai
%
%   Voir aussi GENFIS1, GENFIS2, EVALFIS, FCM.
    donnees = double(donnees);
    nEntrees = size(donnees, 2) - 1;
    X = donnees(:, 1:nEntrees);
    Y = donnees(:, end);
    if nargin < 2 || isempty(fisInitial)
        fisInitial = genfis1(donnees, 2);
    end
    if nargin < 3 || isempty(epoques), epoques = 10; end
    if nargin < 4 || isempty(pasInitial), pasInitial = 0.01; end
    fis = fisInitial;
    if ~strcmp(fis.type, 'sugeno')
        error('fuzzy:anfis:BadType', 'ANFIS ne travaille que sur un système de Sugeno.');
    end
    pas = pasInitial;
    erreurs = zeros(epoques, 1);
    fis = ajusterConclusions(fis, X, Y);
    erreurCourante = erreurQuadratique(fis, X, Y);
    for epoque = 1:epoques
        parametres = lireParametresPremisse(fis);
        gradient = zeros(size(parametres));
        pasDerivee = 1e-6;
        for k = 1:numel(parametres)
            perturbes = parametres;
            perturbes(k) = perturbes(k) + pasDerivee;
            essai = ecrireParametresPremisse(fis, perturbes);
            essai = ajusterConclusions(essai, X, Y);
            gradient(k) = (erreurQuadratique(essai, X, Y) - erreurCourante) / pasDerivee;
        end
        norme = norm(gradient);
        if norme > 0
            candidatParametres = parametres - pas * gradient / norme;
            candidat = ecrireParametresPremisse(fis, candidatParametres);
            candidat = ajusterConclusions(candidat, X, Y);
            erreurCandidate = erreurQuadratique(candidat, X, Y);
            if erreurCandidate < erreurCourante
                fis = candidat;
                erreurCourante = erreurCandidate;
                pas = pas * 1.1;
            else
                pas = pas / 2;
            end
        end
        erreurs(epoque) = erreurCourante;
        if pas < 1e-12
            erreurs = erreurs(1:epoque);
            break
        end
    end
end

function fis = ajusterConclusions(fis, X, Y)
%AJUSTERCONCLUSIONS Moindres carrés sur les paramètres de conclusion.
%   La sortie vaut somme_r wbar_r (a_r . x + b_r) : elle est linéaire en
%   les a et les b, si bien qu'une seule résolution suffit.
    nEntrees = numel(fis.entrees);
    nRegles = size(fis.regles, 1);
    lineaire = strcmpi(fis.sorties{1}.mf{1}.type, 'linear');
    if lineaire
        parRegle = nEntrees + 1;
    else
        parRegle = 1;
    end
    poids = forcesNormalisees(fis, X);
    n = size(X, 1);
    A = zeros(n, nRegles * parRegle);
    if lineaire
        etendu = [X, ones(n, 1)];
        for r = 1:nRegles
            colonnes = (r - 1) * parRegle + (1:parRegle);
            A(:, colonnes) = etendu .* repmat(poids(:, r), 1, parRegle);
        end
    else
        A = poids;
    end
    % Régularisation minuscule : deux règles presque confondues rendent le
    % système singulier, et la solution de norme minimale est la bonne.
    theta = (A' * A + 1e-10 * eye(size(A, 2))) \ (A' * Y);
    for r = 1:nRegles
        indiceMf = abs(fis.regles(r, nEntrees + 1));
        colonnes = (r - 1) * parRegle + (1:parRegle);
        fis.sorties{1}.mf{indiceMf}.parametres = theta(colonnes)';
    end
end

function poids = forcesNormalisees(fis, X)
%FORCESNORMALISEES Forces d'activation de chaque règle, pour toutes les
%   lignes d'un coup. Les appartenances sont évaluées une fois par
%   fonction, pas une fois par point et par règle : c'est ce qui rend
%   l'apprentissage praticable.
    nEntrees = numel(fis.entrees);
    nRegles = size(fis.regles, 1);
    n = size(X, 1);
    appartenances = cell(1, nEntrees);
    for k = 1:nEntrees
        variable = fis.entrees{k};
        table = zeros(n, numel(variable.mf));
        for j = 1:numel(variable.mf)
            mf = variable.mf{j};
            table(:, j) = reshape(evalmf(X(:, k), mf.type, mf.parametres), n, 1);
        end
        appartenances{k} = table;
    end
    poids = ones(n, nRegles);
    for r = 1:nRegles
        for k = 1:nEntrees
            indiceMf = fis.regles(r, k);
            if indiceMf == 0, continue, end
            colonne = appartenances{k}(:, abs(indiceMf));
            if indiceMf < 0, colonne = 1 - colonne; end
            poids(:, r) = poids(:, r) .* colonne;
        end
    end
    total = sum(poids, 2);
    nuls = total <= 0;
    total(nuls) = nRegles;
    poids(nuls, :) = 1;
    poids = poids ./ repmat(total, 1, nRegles);
end

function y = predire(fis, X)
%PREDIRE Sortie du système de Sugeno, vectorisée.
    nEntrees = numel(fis.entrees);
    nRegles = size(fis.regles, 1);
    poids = forcesNormalisees(fis, X);
    n = size(X, 1);
    y = zeros(n, 1);
    lineaire = strcmpi(fis.sorties{1}.mf{1}.type, 'linear');
    for r = 1:nRegles
        indiceMf = abs(fis.regles(r, nEntrees + 1));
        p = fis.sorties{1}.mf{indiceMf}.parametres(:)';
        if lineaire
            conclusion = X * p(1:nEntrees)' + p(end);
        else
            conclusion = repmat(p(1), n, 1);
        end
        y = y + poids(:, r) .* conclusion;
    end
end

function e = erreurQuadratique(fis, X, Y)
    e = sqrt(mean((predire(fis, X) - Y) .^ 2));
end

function parametres = lireParametresPremisse(fis)
    parametres = [];
    for k = 1:numel(fis.entrees)
        for j = 1:numel(fis.entrees{k}.mf)
            parametres = [parametres, fis.entrees{k}.mf{j}.parametres(:)'];   %#ok<AGROW>
        end
    end
end

function fis = ecrireParametresPremisse(fis, parametres)
    position = 1;
    for k = 1:numel(fis.entrees)
        for j = 1:numel(fis.entrees{k}.mf)
            n = numel(fis.entrees{k}.mf{j}.parametres);
            fis.entrees{k}.mf{j}.parametres = parametres(position:position + n - 1);
            position = position + n;
        end
    end
end
