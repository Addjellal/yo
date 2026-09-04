function [parametres, tailleSortie, sequence] = matlibre_couche_initialiser(couche, tailleEntree, sequence)
%MATLIBRE_COUCHE_INITIALISER Poids de départ d'une couche, et sa sortie.
%   [P,T,S] = MATLIBRE_COUCHE_INITIALISER(COUCHE,TAILLEENTREE,SEQUENCE)
%   rend les paramètres appris de la couche, la taille qu'elle produit, et
%   si sa sortie est une séquence.
%
%   Les poids suivent la règle de Glorot : tirés uniformément dans un
%   intervalle inversement proportionnel à la racine du nombre d'entrées
%   et de sorties. C'est ce qui garde la variance du signal d'une couche à
%   la suivante — sans quoi un réseau profond sature ou s'éteint dès le
%   premier passage.
%
%   La taille s'entend hors observations : un nombre pour un vecteur de
%   caractéristiques, trois pour une image.
%
%   Exemple :
%      [p, t] = matlibre_couche_initialiser(fullyConnectedLayer(3), 4, false);
%      size(p.Weights)      % 3 4
%
%   Voir aussi DLNETWORK, INITIALIZE, MATLIBRE_COUCHE_APPLIQUER.
    parametres = struct();
    tailleSortie = tailleEntree;
    switch couche.type
        case {'input', 'sequenceinput'}
            tailleSortie = couche.taille(:).';
            sequence = strcmp(couche.type, 'sequenceinput');
        case 'imageinput'
            tailleSortie = couche.taille(:).';
        case 'fc'
            entrees = prod(tailleEntree);
            parametres.Weights = matlibre_glorot([couche.sorties, entrees], ...
                                                 entrees, couche.sorties);
            parametres.Bias = zeros(couche.sorties, 1);
            tailleSortie = couche.sorties;
        case 'conv2d'
            canaux = tailleEntree(3);
            noyau = couche.taille;
            parametres.Weights = matlibre_glorot([noyau(1), noyau(2), canaux, couche.filtres], ...
                                                 prod(noyau) * canaux, prod(noyau) * couche.filtres);
            parametres.Bias = zeros(couche.filtres, 1);
            bords = matlibre_dl_remplissage(couche.marge, tailleEntree(1:2), noyau, ...
                                            couche.pas, [1 1]);
            tailleSortie = [matlibre_taille_glissante(tailleEntree(1:2), noyau, couche.pas, ...
                                                      bords, [1 1]), couche.filtres];
        case 'conv1d'
            canaux = tailleEntree(2);
            parametres.Weights = matlibre_glorot([couche.taille, canaux, couche.filtres], ...
                                                 couche.taille * canaux, ...
                                                 couche.taille * couche.filtres);
            parametres.Bias = zeros(couche.filtres, 1);
            bords = matlibre_dl_remplissage(couche.marge, [tailleEntree(1), 1], ...
                                            [couche.taille, 1], [couche.pas, 1], ...
                                            [couche.dilatation, 1]);
            longueur = matlibre_taille_glissante([tailleEntree(1), 1], [couche.taille, 1], ...
                                                 [couche.pas, 1], bords, [couche.dilatation, 1]);
            tailleSortie = [longueur(1), couche.filtres];
        case 'transposedconv2d'
            canaux = tailleEntree(3);
            noyau = couche.taille;
            parametres.Weights = matlibre_glorot([noyau(1), noyau(2), couche.filtres, canaux], ...
                                                 prod(noyau) * canaux, prod(noyau) * couche.filtres);
            parametres.Bias = zeros(couche.filtres, 1);
            grande = (tailleEntree(1:2) - 1) .* couche.pas + noyau;
            rognage = matlibre_couche_rognage(couche.rognage, grande, tailleEntree(1:2), couche.pas);
            tailleSortie = [grande - rognage(1:2) - rognage(3:4), couche.filtres];
        case {'maxpool', 'avgpool'}
            bords = matlibre_dl_remplissage(champOuZero(couche, 'marge'), tailleEntree(1:2), ...
                                            couche.taille, couche.pas, [1 1]);
            tailleSortie = [matlibre_taille_glissante(tailleEntree(1:2), couche.taille, ...
                                                      couche.pas, bords, [1 1]), tailleEntree(3)];
        case {'maxpool1d', 'avgpool1d'}
            bords = matlibre_dl_remplissage(couche.marge, [tailleEntree(1), 1], ...
                                            [couche.taille, 1], [couche.pas, 1], [1 1]);
            longueur = matlibre_taille_glissante([tailleEntree(1), 1], [couche.taille, 1], ...
                                                 [couche.pas, 1], bords, [1 1]);
            tailleSortie = [longueur(1), tailleEntree(2)];
        case {'globalavgpool', 'globalmaxpool'}
            tailleSortie = tailleEntree(3);
        case 'globalavgpool1d'
            tailleSortie = tailleEntree(2);
        case 'flatten'
            tailleSortie = prod(tailleEntree);
        case {'batchnorm', 'layernorm', 'groupnorm'}
            canaux = tailleEntree(end);
            parametres.Scale = ones(canaux, 1);
            parametres.Offset = zeros(canaux, 1);
        case {'lstm', 'gru', 'bilstm'}
            entrees = tailleEntree(1);
            portes = 4;
            if strcmp(couche.type, 'gru')
                portes = 3;
            end
            unites = couche.unites;
            parametres.InputWeights = matlibre_glorot([portes * unites, entrees], ...
                                                      entrees, unites);
            parametres.RecurrentWeights = matlibre_glorot([portes * unites, unites], ...
                                                          unites, unites);
            parametres.Bias = zeros(portes * unites, 1);
            if strcmp(couche.type, 'gru')
                % La porte de réinitialisation agit après le produit
                % récurrent : ce produit a donc son propre biais.
                parametres.Bias = zeros(portes * unites + unites, 1);
            end
            if strcmp(couche.type, 'bilstm')
                parametres.InputWeightsBackward = matlibre_glorot([portes * unites, entrees], ...
                                                                  entrees, unites);
                parametres.RecurrentWeightsBackward = matlibre_glorot([portes * unites, unites], ...
                                                                      unites, unites);
                parametres.BiasBackward = zeros(portes * unites, 1);
                tailleSortie = 2 * unites;
            else
                tailleSortie = unites;
            end
            if strcmp(couche.sortieMode, 'last')
                sequence = false;
            end
        otherwise
            % Activations, abandon, agrégations de branches, couches de
            % sortie : elles ne portent aucun poids et gardent la taille.
    end
end

function v = champOuZero(couche, nom)
    if isfield(couche, nom)
        v = couche.(nom);
    else
        v = 0;
    end
end
