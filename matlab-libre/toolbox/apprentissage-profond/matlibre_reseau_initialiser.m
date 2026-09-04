function reseau = matlibre_reseau_initialiser(reseau, exemples)
%MATLIBRE_RESEAU_INITIALISER Tire les poids de toutes les couches.
%   RESEAU = MATLIBRE_RESEAU_INITIALISER(RESEAU,EXEMPLES) parcourt le
%   graphe dans l'ordre du calcul, propage les tailles de couche en
%   couche, et tire les poids de chacune dès que la taille de ce qui
%   l'alimente est connue.
%
%   EXEMPLES est un tableau de cellules de données, une par couche
%   d'entrée ; il est facultatif quand les couches d'entrée déclarent leur
%   taille. Une taille qu'on ne peut pas déduire laisse le réseau non
%   initialisé plutôt que d'échouer : c'est INITIALIZE, plus tard, qui
%   finira le travail.
%
%   Exemple :
%      net = dlnetwork({featureInputLayer(3), fullyConnectedLayer(2)});
%      net.Initialized      % vrai
%
%   Voir aussi DLNETWORK, INITIALIZE.
    ordre = matlibre_reseau_ordre(reseau.Names, reseau.Connections);
    tailles = cell(1, numel(reseau.Names));
    sequences = false(1, numel(reseau.Names));
    apprises = reseau.Learnables;
    numeroEntree = 0;
    for position = ordre
        couche = reseau.Layers{position};
        nom = reseau.Names{position};
        sources = matlibre_reseau_sources(reseau, nom);
        if isempty(sources)
            numeroEntree = numeroEntree + 1;
            [taille, sequence] = matlibre_reseau_taille_entree(couche, exemples, numeroEntree);
            if isempty(taille)
                reseau.Initialized = false;
                return
            end
        else
            [taille, sequence] = matlibre_reseau_taille_amont(reseau, couche, sources, ...
                                                              tailles, sequences);
            if isempty(taille)
                reseau.Initialized = false;
                return
            end
        end
        [parametres, tailleSortie, sequence] = ...
            matlibre_couche_initialiser(couche, taille, sequence);
        champs = fieldnames(parametres);
        for k = 1:numel(champs)
            parametres.(champs{k}) = dlarray(parametres.(champs{k}));
        end
        if ~isempty(champs)
            apprises = matlibre_reseau_ecrire(apprises, nom, parametres);
        end
        tailles{position} = tailleSortie;
        sequences(position) = sequence;
    end
    reseau.Learnables = apprises;
    reseau.Initialized = true;
end

function [taille, sequence] = matlibre_reseau_taille_entree(couche, exemples, numero)
% Une couche d'entrée déclare sa taille ; à défaut, on la lit sur
% l'exemple fourni, dont la dernière dimension compte les observations.
    sequence = strcmp(couche.type, 'sequenceinput');
    if isfield(couche, 'taille') && ~isempty(couche.taille)
        taille = couche.taille(:).';
        return
    end
    taille = [];
    if numero <= numel(exemples)
        donnees = matlibre_dl_valeur(exemples{numero});
        forme = size(donnees);
        if numel(forme) <= 2
            taille = forme(1);
        else
            taille = forme(1:(end - 1));
        end
    end
end

function [taille, sequence] = matlibre_reseau_taille_amont(reseau, couche, sources, tailles, sequences)
% La taille d'entrée d'une couche vient de ses sources ; celles qui en ont
% plusieurs les combinent chacune à leur façon.
    taille = [];
    sequence = false;
    amont = cell(1, numel(sources));
    for k = 1:numel(sources)
        position = find(strcmp(reseau.Names, sources{k}), 1);
        if isempty(tailles{position})
            return
        end
        amont{k} = tailles{position};
        sequence = sequence || sequences(position);
    end
    switch couche.type
        case 'depthconcat'
            taille = amont{1};
            canal = numel(taille);
            if numel(taille) == 3
                canal = 3;
            end
            for k = 2:numel(amont)
                taille(canal) = taille(canal) + amont{k}(canal);
            end
        case 'concatenation'
            taille = amont{1};
            for k = 2:numel(amont)
                taille(couche.dimension) = taille(couche.dimension) + ...
                                           amont{k}(couche.dimension);
            end
        otherwise
            taille = amont{1};
    end
end
