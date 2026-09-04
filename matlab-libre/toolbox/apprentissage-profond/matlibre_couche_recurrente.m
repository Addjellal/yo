function y = matlibre_couche_recurrente(couche, x, parametres)
%MATLIBRE_COUCHE_RECURRENTE Passage avant d'une couche récurrente.
%   Y = MATLIBRE_COUCHE_RECURRENTE(COUCHE,X,PARAMETRES) parcourt la
%   séquence instant par instant en entretenant un état. X est rangé en
%   canaux-observations-temps.
%
%   Selon le type de la couche, l'état est une mémoire et une sortie
%   (mémoire longue), un seul vecteur gouverné par deux portes (portes
%   récurrentes), ou deux parcours en sens contraires mis bout à bout
%   (mémoire longue bidirectionnelle).
%
%   Le déroulement est écrit avec des opérations sur DLARRAY : la
%   rétropropagation dans le temps s'obtient donc sans qu'on l'écrive,
%   c'est la bande qui garde le fil des instants.
%
%   Exemple :
%      % appelée par le réseau, jamais directement
%
%   Voir aussi LSTMLAYER, GRULAYER, BILSTMLAYER, DLNETWORK.
    instants = size(x, 3);
    observations = size(x, 2);
    unites = couche.unites;
    switch couche.type
        case 'lstm'
            sorties = derouler(@etapeMemoireLongue, x, parametres.InputWeights, ...
                               parametres.RecurrentWeights, parametres.Bias, ...
                               unites, observations, instants, false);
        case 'gru'
            sorties = derouler(@etapePortes, x, parametres.InputWeights, ...
                               parametres.RecurrentWeights, parametres.Bias, ...
                               unites, observations, instants, false);
        case 'bilstm'
            avant = derouler(@etapeMemoireLongue, x, parametres.InputWeights, ...
                             parametres.RecurrentWeights, parametres.Bias, ...
                             unites, observations, instants, false);
            arriere = derouler(@etapeMemoireLongue, x, parametres.InputWeightsBackward, ...
                               parametres.RecurrentWeightsBackward, ...
                               parametres.BiasBackward, unites, observations, ...
                               instants, true);
            sorties = cell(1, instants);
            for t = 1:instants
                sorties{t} = cat(1, avant{t}, arriere{t});
            end
        otherwise
            error('nnet:recurrente:Type', 'Type inconnu : %s.', couche.type);
    end
    if strcmp(couche.sortieMode, 'last')
        y = sorties{end};
        return
    end
    for t = 1:instants
        sorties{t} = reshape(sorties{t}, size(sorties{t}, 1), observations, 1);
    end
    y = cat(3, sorties{:});
end

function sorties = derouler(etape, x, W, R, b, unites, observations, instants, arriere)
% Le parcours du temps, dans un sens ou dans l'autre. L'état de départ est
% nul : c'est la convention de MATLAB, et elle vaut ce que vaut n'importe
% quel départ dès que la séquence est un peu longue.
    h = dlarray(zeros(unites, observations));
    c = dlarray(zeros(unites, observations));
    sorties = cell(1, instants);
    if arriere
        ordre = instants:-1:1;
    else
        ordre = 1:instants;
    end
    for t = ordre
        xt = reshape(x(:, :, t), size(x, 1), observations);
        [h, c] = etape(xt, h, c, W, R, b, unites);
        sorties{t} = h;
    end
end

function [h, c] = etapeMemoireLongue(xt, h, c, W, R, b, unites)
% Trois portes : ce qu'on oublie, ce qu'on écrit, ce qu'on montre. La
% mémoire traverse l'instant par une addition, et c'est par là que le
% gradient remonte le temps sans s'éteindre.
    z = W * xt + R * h + b;
    entree = sigmoid(z(1:unites, :));
    oubli = sigmoid(z((unites + 1):(2 * unites), :));
    candidat = tanh(z((2 * unites + 1):(3 * unites), :));
    sortie = sigmoid(z((3 * unites + 1):(4 * unites), :));
    c = oubli .* c + entree .* candidat;
    h = sortie .* tanh(c);
end

function [h, c] = etapePortes(xt, h, c, W, R, b, unites)
% Deux portes seulement : l'une décide de ce qu'on oublie du passé,
% l'autre de la part de neuf qu'on écrit. La réinitialisation agit après
% le produit récurrent, comme dans MATLAB, ce qui donne à ce produit son
% propre biais.
    partieEntree = W * xt + b(1:(3 * unites));
    partieRecurrente = R * h;
    reinitialisation = sigmoid(partieEntree(1:unites, :) + ...
                               partieRecurrente(1:unites, :));
    mise = sigmoid(partieEntree((unites + 1):(2 * unites), :) + ...
                   partieRecurrente((unites + 1):(2 * unites), :));
    biaisRecurrent = b((3 * unites + 1):(4 * unites));
    candidat = tanh(partieEntree((2 * unites + 1):(3 * unites), :) + ...
                    reinitialisation .* (partieRecurrente((2 * unites + 1):(3 * unites), :) + ...
                                         biaisRecurrent));
    h = (1 - mise) .* candidat + mise .* h;
end
