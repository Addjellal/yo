function varargout = classify(reseau, X, varargin)
%CLASSIFY Classe de plus forte probabilité pour chaque observation.
%   Deux fonctions de MATLAB portent ce nom : l'analyse discriminante de
%   Statistics and Machine Learning Toolbox, et le classement par un
%   réseau de Deep Learning Toolbox. CLASSIFY les distingue à son premier
%   argument, une matrice d'observations ou un réseau.
%
%   Analyse discriminante
%   CLASS = CLASSIFY(SAMPLE,TRAINING,GROUP) range chaque ligne de SAMPLE
%   dans l'un des groupes de TRAINING, dont GROUP donne le groupe de
%   chaque ligne. Chaque groupe est supposé gaussien, avec une
%   covariance commune estimée sur tous les groupes ; CLASS a le type
%   de GROUP.
%   CLASSIFY(...,TYPE) choisit la covariance : 'linear' (défaut),
%   'diaglinear', 'quadratic' (une par groupe), 'diagquadratic',
%   'mahalanobis' (distance à chaque groupe, sans probabilités).
%   CLASSIFY(...,TYPE,PRIOR) fixe les a priori : un vecteur, une
%   structure aux champs prob et group, ou 'empirical' (proportionnels
%   aux effectifs). Ils valent 1/G par défaut.
%   [CLASS,ERR,POSTERIOR,LOGP,COEFF] = CLASSIFY(...) rend aussi l'erreur
%   apparente sur TRAINING (pondérée par les a priori), les probabilités
%   a posteriori, le logarithme de la densité de chaque observation, et
%   les frontières entre groupes : COEFF(I,J) porte const, linear et
%   quadratic, et l'observation x va du côté de I quand
%   const + x*linear + sum((x*quadratic).*x) > 0.
%   MathWorks recommande désormais FITCDISCR, qui fait le même calcul.
%
%   Exemple (iris de Fisher, 1936) :
%      load fisheriris
%      c = classify(meas, meas, species);
%      sum(~strcmp(c, species))      % 3 fleurs mal classées sur 150
%
%   Réseau de neurones
%   C = CLASSIFY(RESEAU,X) rend, pour chaque observation de X, l'indice de
%   la classe de plus fort score. C est une colonne, une entrée par
%   observation.
%
%   [C,SCORES] = CLASSIFY(RESEAU,X) rend en plus les scores complets, une
%   colonne par observation. Il faut les regarder : l'indice seul ne
%   distingue pas une réponse à 0,99 d'une réponse à 0,34 contre 0,33 et
%   0,33, alors que la première est une décision et la seconde un tirage
%   au sort. Un seuil sur le score maximal permet de refuser de conclure.
%
%   RESEAU est un réseau appris par TRAINNETWORK.
%
%   Exemple :
%      X = [randn(2, 30), randn(2, 30) + 3];
%      Y = [repmat([1; 0], 1, 30), repmat([0; 1], 1, 30)];
%      couches = {fullyConnectedLayer(4), reluLayer(), ...
%                 fullyConnectedLayer(2), softmaxLayer()};
%      reseau = trainNetwork(X, Y, couches, trainingOptions('sgdm'));
%      [c, s] = classify(reseau, X);
%
%   Voir aussi FITCDISCR, PREDICTRESEAU, SOFTMAXLAYER, CONFUSIONCHART.
    if isnumeric(reseau) || islogical(reseau)
        if nargin < 3
            error('stats:classify:TooFewInputs', ...
                  'CLASSIFY(SAMPLE,TRAINING,GROUP) attend au moins trois arguments.');
        end
        [varargout{1:max(nargout, 1)}] = matlibre_classify(reseau, X, varargin{:});
        return
    end
    if ~isempty(varargin)
        error('MATLAB:TooManyInputs', ...
              'CLASSIFY(RESEAU,X) attend deux arguments.');
    end
    scores = predict(reseau, X);
    [~, classes] = max(scores, [], 1);
    varargout{1} = classes(:);
    if nargout > 1
        varargout{2} = scores;
    end
end
