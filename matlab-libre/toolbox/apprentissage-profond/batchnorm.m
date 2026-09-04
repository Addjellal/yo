function [y, moyenneRendue, varianceRendue] = batchnorm(x, decalage, echelle, varargin)
%BATCHNORM Normalisation par lot.
%   Y = BATCHNORM(X,DECALAGE,ECHELLE) centre et réduit X canal par canal,
%   sur toutes les observations du lot et toutes les positions spatiales,
%   puis applique l'échelle et le décalage appris — un par canal.
%
%   [Y,MU,SIGMA2] = BATCHNORM(...) rend aussi la moyenne et la variance
%   du lot, à conserver pour la prédiction.
%
%   Y = BATCHNORM(X,DECALAGE,ECHELLE,MU,SIGMA2) emploie les statistiques
%   données au lieu de celles du lot : c'est ce qu'il faut faire en
%   prédiction, où le résultat ne doit pas dépendre des autres exemples
%   présentés en même temps.
%
%   [Y,MU,SIGMA2] = BATCHNORM(X,DECALAGE,ECHELLE,MU0,SIGMA20,...) met à
%   jour les moyennes glissantes à partir de celles données.
%
%   Options et valeurs par défaut :
%     'Epsilon'         1e-5, ajouté à la variance avant la racine
%     'MeanDecay'       0.1, le poids du lot dans la moyenne glissante
%     'VarianceDecay'   0.1
%     'DataFormat'      le format, quand X n'en porte pas
%
%   La normalisation par lot recentre l'entrée de chaque couche, ce qui
%   permet des pas d'apprentissage plus grands sans divergence.
%
%   Exemple :
%      x = dlarray(randn(4, 4, 3, 16), 'SSCB');
%      y = batchnorm(x, zeros(3, 1), ones(3, 1));
%
%   Voir aussi LAYERNORM, GROUPNORM, BATCHNORMALIZATIONLAYER, DLARRAY.
    epsilon = 1e-5;
    inertieMoyenne = 0.1;
    inertieVariance = 0.1;
    format = '';
    moyenneConnue = [];
    varianceConnue = [];
    debut = 1;
    if numel(varargin) >= 2 && ~ischar(varargin{1})
        moyenneConnue = varargin{1};
        varianceConnue = varargin{2};
        debut = 3;
    end
    for k = debut:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'epsilon',       epsilon = double(varargin{k + 1});
            case 'meandecay',     inertieMoyenne = double(varargin{k + 1});
            case 'variancedecay', inertieVariance = double(varargin{k + 1});
            case 'dataformat',    format = upper(char(varargin{k + 1}));
            otherwise
                error('nnet:batchnorm:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    [canal, ~, nombre] = matlibre_dl_axe_canal(x, format);
    dimensions = setdiff(1:nombre, canal);
    forme = ones(1, nombre);
    forme(canal) = numel(matlibre_dl_valeur(echelle));
    echelle = reshape(echelle, forme);
    decalage = reshape(decalage, forme);
    if isempty(moyenneConnue) || nargout > 1
        [~, moyenneLot, varianceLot] = ...
            matlibre_dl_normaliser(x, dimensions, decalage, echelle, epsilon);
    end
    if isempty(moyenneConnue)
        y = echelle .* (x - moyenneLot) ./ sqrt(varianceLot + epsilon) + decalage;
        moyenneRendue = reshape(moyenneLot, [], 1);
        varianceRendue = reshape(varianceLot, [], 1);
        return
    end
    % Statistiques imposées : la sortie ne dépend plus des autres exemples
    % du lot, ce qui est la condition d'une prédiction reproductible.
    moyenneFixe = reshape(moyenneConnue, forme);
    varianceFixe = reshape(varianceConnue, forme);
    y = echelle .* (x - moyenneFixe) ./ sqrt(varianceFixe + epsilon) + decalage;
    if nargout > 1
        moyenneRendue = (1 - inertieMoyenne) * reshape(moyenneConnue, [], 1) + ...
                        inertieMoyenne * reshape(matlibre_dl_valeur(moyenneLot), [], 1);
        varianceRendue = (1 - inertieVariance) * reshape(varianceConnue, [], 1) + ...
                         inertieVariance * reshape(matlibre_dl_valeur(varianceLot), [], 1);
    end
end
