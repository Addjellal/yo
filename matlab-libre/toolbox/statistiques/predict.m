function [etiquettes, scores] = predict(modele, X)
%PREDICT Prédiction d'un modèle ajusté.
%   Y = PREDICT(M,X) applique à X le modèle M, quel qu'il soit : arbre,
%   k plus proches voisins, bayésien naïf, analyse discriminante, machine
%   à vecteurs de support, modèle linéaire, code correcteur, processus
%   gaussien.
%
%   [Y,SCORES] = PREDICT(M,X) rend en outre les scores : une colonne par
%   classe pour un classifieur, la variance de prédiction pour un
%   processus gaussien.
%
%   MatLibre décrit ses modèles par des structures portant un champ
%   « type » ; PREDICT s'y fie pour choisir la règle. MATLAB, lui,
%   emploie des objets à méthode.
%
%   Exemple :
%      m = fitcnb(X, y);
%      etiquettes = predict(m, Xnouveau);
%
%   Un réseau de neurones passe par le même nom : PREDICT le reconnaît à
%   ses couches et le confie à PREDICTRESEAU.
%
%   Voir aussi FITCTREE, FITCKNN, FITCNB, FITCDISCR, FITCSVM, FITCECOC,
%   FITRGP, PREDICTRESEAU.
    if isstruct(modele) && isfield(modele, 'couches')
        % Un réseau de neurones : PREDICT est le nom commun, comme dans
        % MATLAB, et c'est le réseau qui décide de la suite.
        etiquettes = predictReseau(modele, X);
        return;
    end
    if ~isstruct(modele) || ~isfield(modele, 'type')
        error('stats:predict:Modele', ...
              'PREDICT attend un modèle ajusté par une fonction fitc… ou fitr…, ou un réseau.');
    end
    X = double(X);
    scores = [];
    switch modele.type
        case 'arbre'
            etiquettes = predicttree(modele, X);
        case 'arbre-regression'
            etiquettes = predictArbreRegression(modele, X);
        case 'knn'
            etiquettes = predictknn(modele, X);
        case 'bayes-naif'
            [etiquettes, scores] = predictBayesNaif(modele, X);
        case 'discriminant'
            [etiquettes, scores] = predictDiscriminant(modele, X);
        case 'svm'
            [etiquettes, scores] = predictSvm(modele, X);
        case 'svm-regression'
            etiquettes = predictSvm(modele, X);
        case 'lineaire'
            [etiquettes, scores] = predictLineaire(modele, X);
        case 'ecoc'
            [etiquettes, scores] = predictEcoc(modele, X);
        case 'gp'
            [etiquettes, scores] = predictGp(modele, X);
        case 'melange-gaussien'
            [etiquettes, scores] = clusterMelange(modele, X);
        otherwise
            error('stats:predict:Type', 'Modèle inconnu : %s.', modele.type);
    end
end
