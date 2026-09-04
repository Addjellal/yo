function [y, etat] = matlibre_couche_appliquer(couche, entrees, parametres, etat, apprentissage)
%MATLIBRE_COUCHE_APPLIQUER Passage avant d'une couche.
%   [Y,ETAT] = MATLIBRE_COUCHE_APPLIQUER(COUCHE,ENTREES,PARAMETRES,ETAT,
%   APPRENTISSAGE) applique la couche aux entrées — un tableau de cellules,
%   car une couche d'addition ou de concaténation en a plusieurs — et rend
%   sa sortie ainsi que son état mis à jour.
%
%   APPRENTISSAGE distingue les couches qui ne se comportent pas de même
%   aux deux régimes : l'abandon n'agit qu'à l'apprentissage, et la
%   normalisation par lot emploie alors les statistiques du lot plutôt que
%   celles accumulées.
%
%   Tout est écrit avec des opérations sur DLARRAY : la dérivée de la
%   couche s'obtient donc sans qu'on l'écrive.
%
%   Exemple :
%      y = matlibre_couche_appliquer(reluLayer(), {dlarray([-1 2])}, ...
%                                    struct(), struct(), true);
%      extractdata(y)      % 0 2
%
%   Voir aussi DLNETWORK, FORWARD, PREDICT.
    x = entrees{1};
    y = x;
    switch couche.type
        case {'input', 'imageinput', 'sequenceinput'}
            % Les couches d'entrée ne transforment rien.
        case 'fc'
            y = fullyconnect(x, parametres.Weights, parametres.Bias);
        case 'conv2d'
            y = dlconv(x, parametres.Weights, parametres.Bias, ...
                       'Stride', couche.pas, 'Padding', couche.marge, ...
                       'DataFormat', 'SSCB');
        case 'conv1d'
            y = dlconv(x, parametres.Weights, parametres.Bias, ...
                       'Stride', couche.pas, 'Padding', couche.marge, ...
                       'DilationFactor', couche.dilatation, 'DataFormat', 'SCB');
        case 'transposedconv2d'
            y = matlibre_dl_convolution_transposee(x, parametres.Weights, ...
                                                   parametres.Bias, couche.pas, ...
                                                   couche.rognage);
        case 'relu'
            y = relu(x);
        case 'leakyrelu'
            y = leakyrelu(x, couche.pente);
        case 'clippedrelu'
            y = min(max(x, 0), couche.plafond);
        case 'elu'
            % La branche négative est exponentielle : continue en zéro, et
            % de dérivée non nulle, contrairement au redresseur.
            y = max(x, 0) + couche.alpha * (exp(min(x, 0)) - 1);
        case 'gelu'
            y = 0.5 * x .* (1 + erf(x / sqrt(2)));
        case 'swish'
            y = x .* sigmoid(x);
        case 'softplus'
            y = log(1 + exp(x));
        case 'tanh'
            y = tanh(x);
        case 'sigmoid'
            y = sigmoid(x);
        case 'softmax'
            y = softmax(x);
        case 'batchnorm'
            [y, etat] = matlibre_couche_batchnorm(couche, x, parametres, etat, apprentissage);
        case 'layernorm'
            y = layernorm(x, parametres.Offset, parametres.Scale, ...
                          'Epsilon', couche.epsilon, ...
                          'DataFormat', matlibre_dl_format_entree(x));
        case 'groupnorm'
            y = groupnorm(x, parametres.Offset, parametres.Scale, couche.groupes, ...
                          'Epsilon', couche.epsilon, ...
                          'DataFormat', matlibre_dl_format_entree(x));
        case 'crosschannelnorm'
            y = matlibre_couche_canaux(x, couche);
        case 'dropout'
            y = matlibre_couche_abandon(x, couche, apprentissage);
        case 'maxpool'
            y = maxpool(x, couche.taille, 'Stride', couche.pas, ...
                        'Padding', champOuZero(couche, 'marge'), 'DataFormat', 'SSCB');
        case 'avgpool'
            y = avgpool(x, couche.taille, 'Stride', couche.pas, ...
                        'Padding', champOuZero(couche, 'marge'), 'DataFormat', 'SSCB');
        case 'maxpool1d'
            y = maxpool(x, couche.taille, 'Stride', couche.pas, ...
                        'Padding', couche.marge, 'DataFormat', 'SCB');
        case 'avgpool1d'
            y = avgpool(x, couche.taille, 'Stride', couche.pas, ...
                        'Padding', couche.marge, 'DataFormat', 'SCB');
        case 'globalavgpool'
            y = reshape(mean(mean(x, 1), 2), size(x, 3), size(x, 4));
        case 'globalmaxpool'
            y = reshape(max(max(x, [], 1), [], 2), size(x, 3), size(x, 4));
        case 'globalavgpool1d'
            y = reshape(mean(x, 1), size(x, 2), size(x, 3));
        case 'flatten'
            y = reshape(x, [], size(x, ndims(x)));
        case 'addition'
            y = entrees{1};
            for k = 2:numel(entrees)
                y = y + entrees{k};
            end
        case 'multiplication'
            y = entrees{1};
            for k = 2:numel(entrees)
                y = y .* entrees{k};
            end
        case 'concatenation'
            y = cat(couche.dimension, entrees{:});
        case 'depthconcat'
            dimension = 1;
            if ndims(matlibre_dl_valeur(entrees{1})) >= 4
                dimension = 3;
            end
            y = cat(dimension, entrees{:});
        case {'lstm', 'gru', 'bilstm'}
            y = matlibre_couche_recurrente(couche, x, parametres);
        case {'classification', 'regression'}
            % Les couches de sortie ne font que déclarer le coût.
        otherwise
            error('nnet:couche:Type', 'Type de couche inconnu : %s.', couche.type);
    end
end

function v = champOuZero(couche, nom)
    if isfield(couche, nom)
        v = couche.(nom);
    else
        v = 0;
    end
end

function [y, etat] = matlibre_couche_batchnorm(couche, x, parametres, etat, apprentissage)
% À l'apprentissage, les statistiques sont celles du lot, et les moyennes
% glissantes se mettent à jour ; en prédiction, ce sont ces moyennes qu'on
% emploie, pour que la sortie ne dépende pas des voisins du lot.
    format = matlibre_dl_format_entree(x);
    if apprentissage || ~isfield(etat, 'TrainedMean') || isempty(etat.TrainedMean)
        [y, moyenne, variance] = batchnorm(x, parametres.Offset, parametres.Scale, ...
                                           'Epsilon', couche.epsilon, 'DataFormat', format);
        if ~isfield(etat, 'TrainedMean') || isempty(etat.TrainedMean)
            etat.TrainedMean = moyenne;
            etat.TrainedVariance = variance;
        else
            etat.TrainedMean = 0.9 * etat.TrainedMean + 0.1 * moyenne;
            etat.TrainedVariance = 0.9 * etat.TrainedVariance + 0.1 * variance;
        end
    else
        y = batchnorm(x, parametres.Offset, parametres.Scale, ...
                      etat.TrainedMean, etat.TrainedVariance, ...
                      'Epsilon', couche.epsilon, 'DataFormat', format);
    end
end

function y = matlibre_couche_abandon(x, couche, apprentissage)
% L'abandon éteint une part des unités et amplifie les autres pour garder
% l'espérance : le réseau ne peut plus miser sur une unité en particulier.
    if ~apprentissage || couche.probabilite <= 0
        y = x;
        return
    end
    masque = double(rand(size(matlibre_dl_valeur(x))) >= couche.probabilite) / ...
             (1 - couche.probabilite);
    y = x .* masque;
end

function y = matlibre_couche_canaux(x, couche)
% Chaque activation est divisée par une fonction de ses voisines dans les
% canaux : les canaux se font concurrence à chaque position.
    canaux = size(x, 3);
    demi = floor(couche.fenetre / 2);
    carres = x .^ 2;
    somme = 0 * carres;
    for d = -demi:demi
        indices = (1:canaux) + d;
        valides = indices >= 1 & indices <= canaux;
        ajout = 0 * carres;
        ajout(:, :, find(valides), :) = carres(:, :, indices(valides), :);
        somme = somme + ajout;
    end
    y = x ./ (couche.K + couche.alpha * somme) .^ couche.beta;
end
