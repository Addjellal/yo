function [sorties, etat] = matlibre_reseau_avant(reseau, entrees, apprentissage)
%MATLIBRE_RESEAU_AVANT Passage avant d'un réseau, couche par couche.
%   [S,ETAT] = MATLIBRE_RESEAU_AVANT(RESEAU,ENTREES,APPRENTISSAGE)
%   parcourt le graphe dans l'ordre du calcul, applique chaque couche aux
%   sorties de celles qui l'alimentent, et rend les sorties du réseau
%   ainsi que l'état mis à jour.
%
%   ENTREES est un tableau de cellules, une donnée par couche d'entrée.
%
%   Toutes les opérations passent par DLARRAY : le passage est donc
%   dérivable de bout en bout, y compris à travers les branches et les
%   couches récurrentes.
%
%   Exemple :
%      s = matlibre_reseau_avant(net, {dlarray(randn(3, 5), 'CB')}, false);
%
%   Voir aussi DLNETWORK, FORWARD, PREDICT.
    if ~reseau.Initialized
        reseau = matlibre_reseau_initialiser(reseau, entrees);
        if ~reseau.Initialized
            error('nnet:dlnetwork:NonInitialise', ...
                  'Le réseau n''est pas initialisé ; appelez INITIALIZE.');
        end
    end
    ordre = matlibre_reseau_ordre(reseau.Names, reseau.Connections);
    valeurs = cell(1, numel(reseau.Names));
    etat = reseau.State;
    numeroEntree = 0;
    for position = ordre
        couche = reseau.Layers{position};
        nom = reseau.Names{position};
        sources = matlibre_reseau_sources(reseau, nom);
        if isempty(sources)
            numeroEntree = numeroEntree + 1;
            if numeroEntree > numel(entrees)
                error('nnet:dlnetwork:Entrees', ...
                      'Le réseau attend %d entrées.', numel(reseau.InputNames));
            end
            arrivee = {matlibre_dl_entree(entrees{numeroEntree})};
        else
            arrivee = cell(1, numel(sources));
            for k = 1:numel(sources)
                arrivee{k} = valeurs{strcmp(reseau.Names, sources{k})};
            end
        end
        parametres = matlibre_reseau_lire(reseau.Learnables, nom);
        etatCouche = matlibre_reseau_lire(etat, nom);
        [valeurs{position}, etatCouche] = ...
            matlibre_couche_appliquer(couche, arrivee, parametres, etatCouche, apprentissage);
        if ~isempty(fieldnames(etatCouche))
            etat = matlibre_reseau_ecrire(etat, nom, etatCouche);
        end
    end
    sorties = cell(1, numel(reseau.OutputNames));
    for k = 1:numel(reseau.OutputNames)
        sorties{k} = valeurs{strcmp(reseau.Names, reseau.OutputNames{k})};
    end
end
