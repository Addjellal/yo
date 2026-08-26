function [appariements, pistesLibres, detectionsLibres] = ...
        assignDetectionsToTracks(couts, coutNonAppariement, coutNonDetection)
%ASSIGNDETECTIONSTOTRACKS Appariement optimal entre pistes et détections.
%   [A,PL,DL] = ASSIGNDETECTIONSTOTRACKS(COUTS,C) apparie les lignes de
%   COUTS, les pistes, aux colonnes, les détections, de façon à minimiser
%   le coût total. C est le prix à payer pour laisser une piste ou une
%   détection sans partenaire : au-delà, mieux vaut ne pas apparier.
%
%   [A,PL,DL] = ASSIGNDETECTIONSTOTRACKS(COUTS,CP,CD) distingue le coût de
%   non-appariement d'une piste de celui d'une détection.
%
%   A porte une ligne [piste detection] par appariement retenu, PL les
%   indices des pistes restées seules, DL ceux des détections restées
%   seules.
%
%   La résolution est exacte : l'algorithme hongrois de Munkres trouve
%   l'affectation de coût minimal en temps cubique, là où l'énumération
%   serait factorielle. Le problème est plongé dans une matrice carrée où
%   chaque ligne et chaque colonne reçoit un partenaire fictif au prix du
%   non-appariement.
%
%   Exemple :
%      [a, pl, dl] = assignDetectionsToTracks([1 100; 100 2], 50);
%      a   % [1 1; 2 2]
%
%   Voir aussi BBOXOVERLAPRATIO.
    if nargin < 3 || isempty(coutNonDetection)
        coutNonDetection = coutNonAppariement;
    end
    C = double(couts);
    [nPistes, nDetections] = size(C);
    if nPistes == 0 || nDetections == 0
        appariements = zeros(0, 2);
        pistesLibres = (1:nPistes)';
        detectionsLibres = (1:nDetections)';
        return
    end
    grand = 1e9 * max(1, max(abs(C(:))));
    taille = nPistes + nDetections;
    M = grand * ones(taille);
    M(1:nPistes, 1:nDetections) = C;
    % Bloc en bas à droite : les partenaires fictifs entre eux ne coûtent
    % rien, faute de quoi ils fausseraient le total.
    M(nPistes+1:end, nDetections+1:end) = 0;
    for k = 1:nPistes
        M(k, nDetections + k) = coutNonAppariement;
    end
    for k = 1:nDetections
        M(nPistes + k, k) = coutNonDetection;
    end
    affectation = munkres(M);
    appariements = zeros(0, 2);
    pistesLibres = [];
    detectionsLibres = [];
    for piste = 1:nPistes
        colonne = affectation(piste);
        if colonne <= nDetections
            appariements(end+1, :) = [piste, colonne];      %#ok<AGROW>
        else
            pistesLibres(end+1, 1) = piste;                 %#ok<AGROW>
        end
    end
    prises = appariements;
    for detection = 1:nDetections
        if isempty(prises) || ~any(prises(:, 2) == detection)
            detectionsLibres(end+1, 1) = detection;         %#ok<AGROW>
        end
    end
    if isempty(pistesLibres), pistesLibres = zeros(0, 1); end
    if isempty(detectionsLibres), detectionsLibres = zeros(0, 1); end
end

function affectation = munkres(C)
%MUNKRES Affectation de coût minimal sur une matrice carrée.
%   Implantation classique en cinq étapes : soustraction des minima,
%   couverture des zéros par un nombre minimal de lignes, création de
%   nouveaux zéros tant que la couverture n'atteint pas la taille, puis
%   lecture de l'affectation.
    n = size(C, 1);
    C = C - repmat(min(C, [], 2), 1, n);
    C = C - repmat(min(C, [], 1), n, 1);
    marques = zeros(n);      % 1 = étoile, 2 = amorce
    lignesCouvertes = false(n, 1);
    colonnesCouvertes = false(1, n);
    % Étoiles initiales : un zéro par ligne et par colonne.
    for i = 1:n
        for j = 1:n
            if C(i, j) == 0 && ~lignesCouvertes(i) && ~colonnesCouvertes(j)
                marques(i, j) = 1;
                lignesCouvertes(i) = true;
                colonnesCouvertes(j) = true;
            end
        end
    end
    lignesCouvertes(:) = false;
    colonnesCouvertes(:) = false;
    etape = 3;
    ligneAmorce = 0;
    colonneAmorce = 0;
    while etape < 7
        switch etape
            case 3
                colonnesCouvertes = any(marques == 1, 1);
                if sum(colonnesCouvertes) >= n
                    etape = 7;
                else
                    etape = 4;
                end
            case 4
                [ligneAmorce, colonneAmorce] = chercherZeroLibre(C, lignesCouvertes, colonnesCouvertes);
                if ligneAmorce == 0
                    etape = 6;
                else
                    marques(ligneAmorce, colonneAmorce) = 2;
                    colonneEtoile = find(marques(ligneAmorce, :) == 1, 1);
                    if isempty(colonneEtoile)
                        etape = 5;
                    else
                        lignesCouvertes(ligneAmorce) = true;
                        colonnesCouvertes(colonneEtoile) = false;
                    end
                end
            case 5
                [marques] = augmenterChemin(marques, ligneAmorce, colonneAmorce);
                lignesCouvertes(:) = false;
                colonnesCouvertes(:) = false;
                marques(marques == 2) = 0;
                etape = 3;
            case 6
                valeurs = C(~lignesCouvertes, ~colonnesCouvertes);
                minimum = min(valeurs(:));
                C(lignesCouvertes, :) = C(lignesCouvertes, :) + minimum;
                C(:, ~colonnesCouvertes) = C(:, ~colonnesCouvertes) - minimum;
                etape = 4;
        end
    end
    affectation = zeros(n, 1);
    for i = 1:n
        j = find(marques(i, :) == 1, 1);
        if ~isempty(j)
            affectation(i) = j;
        end
    end
end

function [ligne, colonne] = chercherZeroLibre(C, lignesCouvertes, colonnesCouvertes)
    ligne = 0;
    colonne = 0;
    for i = 1:size(C, 1)
        if lignesCouvertes(i), continue, end
        for j = 1:size(C, 2)
            if ~colonnesCouvertes(j) && C(i, j) == 0
                ligne = i;
                colonne = j;
                return
            end
        end
    end
end

function marques = augmenterChemin(marques, ligne, colonne)
%AUGMENTERCHEMIN Alterne amorces et étoiles le long d'un chemin, puis
%   inverse leurs rôles : le nombre d'étoiles augmente d'une unité.
    chemin = [ligne, colonne];
    while true
        ligneEtoile = find(marques(:, chemin(end, 2)) == 1, 1);
        if isempty(ligneEtoile)
            break
        end
        chemin(end+1, :) = [ligneEtoile, chemin(end, 2)];        %#ok<AGROW>
        colonneAmorce = find(marques(chemin(end, 1), :) == 2, 1);
        chemin(end+1, :) = [chemin(end, 1), colonneAmorce];      %#ok<AGROW>
    end
    for k = 1:size(chemin, 1)
        if marques(chemin(k, 1), chemin(k, 2)) == 1
            marques(chemin(k, 1), chemin(k, 2)) = 0;
        else
            marques(chemin(k, 1), chemin(k, 2)) = 1;
        end
    end
end
