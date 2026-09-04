function [matrice, totauxEchantillon, totauxIdentifiant] = transprob(donnees, varargin)
%TRANSPROB Matrice de transition de notation estimée sur des migrations.
%   [P,T] = TRANSPROB(D) rend la matrice des probabilités de passer d'une
%   notation à une autre sur un an. D est une matrice à trois colonnes :
%   identifiant, date, notation, une ligne par observation.
%
%   TRANSPROB(...,'algorithm','cohort') compte les notations au début et
%   à la fin de chaque période, sans regarder ce qui s'est passé entre
%   les deux. C'est la méthode simple, et le défaut.
%
%   TRANSPROB(...,'algorithm','duration') estime d'abord la matrice des
%   intensités : combien de passages de i vers j, rapportés au temps
%   passé en i. La matrice de transition en est l'exponentielle. Cette
%   méthode voit les allers-retours qu'une photographie annuelle manque,
%   et donne des probabilités non nulles là où aucune transition directe
%   n'a été observée.
%
%   'snapsPerYear' fixe le nombre de photographies par an (1),
%   'transInterval' la durée visée en années (1), 'labels' les
%   étiquettes des notations.
%
%   Exemple :
%      d = [1 datenum('01-Jan-2020') 1; 1 datenum('01-Jan-2021') 2; ...
%           2 datenum('01-Jan-2020') 2; 2 datenum('01-Jan-2021') 2];
%      transprob(d)
%
%   Voir aussi TRANSPROBBYTOTALS, TRANSPROBTOTHRESHOLDS, CREDITTRANSITION.
    algorithme = 'cohort';
    photosParAn = 1;
    intervalle = 1;
    etiquettes = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'algorithm',     algorithme = lower(char(varargin{k+1}));
            case 'snapsperyear',  photosParAn = round(varargin{k+1});
            case 'transinterval', intervalle = varargin{k+1};
            case 'labels',        etiquettes = varargin{k+1};
            otherwise
                error('risque:transprob:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    donnees = double(donnees);
    if size(donnees, 2) < 3
        error('risque:transprob:Donnees', ...
              'Il faut trois colonnes : identifiant, date, notation.');
    end
    identifiants = donnees(:, 1);
    dates = donnees(:, 2);
    notations = round(donnees(:, 3));
    niveaux = max(notations);
    if ~isempty(etiquettes)
        niveaux = numel(etiquettes);
    end
    uniques = unique(identifiants);
    switch algorithme
        case 'cohort'
            comptes = zeros(niveaux);
            debut = min(dates);
            fin = max(dates);
            pas = 365.25 / photosParAn;
            instants = debut:pas:fin;
            for e = 1:numel(uniques)
                garde = identifiants == uniques(e);
                [datesEntite, ordre] = sort(dates(garde));
                notationsEntite = notations(garde);
                notationsEntite = notationsEntite(ordre);
                vues = matlibre_notation_a(instants, datesEntite, notationsEntite);
                for t = 1:(numel(vues) - 1)
                    if ~isnan(vues(t)) && ~isnan(vues(t + 1))
                        comptes(vues(t), vues(t + 1)) = ...
                            comptes(vues(t), vues(t + 1)) + 1;
                    end
                end
            end
            totauxEchantillon = struct('totalsMat', comptes, ...
                                       'algorithm', 'cohort', ...
                                       'numLevels', niveaux);
            matrice = matlibre_normaliser_lignes(comptes);
        case 'duration'
            transitions = zeros(niveaux);
            tempsPasse = zeros(niveaux, 1);
            for e = 1:numel(uniques)
                garde = identifiants == uniques(e);
                [datesEntite, ordre] = sort(dates(garde));
                notationsEntite = notations(garde);
                notationsEntite = notationsEntite(ordre);
                for t = 1:(numel(datesEntite) - 1)
                    depart = notationsEntite(t);
                    arrivee = notationsEntite(t + 1);
                    tempsPasse(depart) = tempsPasse(depart) + ...
                        (datesEntite(t + 1) - datesEntite(t)) / 365.25;
                    if arrivee ~= depart
                        transitions(depart, arrivee) = transitions(depart, arrivee) + 1;
                    end
                end
            end
            totauxEchantillon = struct('totalsMat', transitions, ...
                                       'algorithm', 'duration', ...
                                       'numLevels', niveaux, ...
                                       'timeSpent', tempsPasse);
            matrice = matlibre_generateur_vers_transition(transitions, tempsPasse, ...
                                                          intervalle);
        otherwise
            error('risque:transprob:Algorithme', ...
                  'L''algorithme vaut ''cohort'' ou ''duration''.');
    end
    if nargout > 2
        totauxIdentifiant = repmat(totauxEchantillon, numel(uniques), 1);
    end
end
