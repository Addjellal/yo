function grille = autobinning(grille, variables, varargin)
%AUTOBINNING Découpe automatique des caractéristiques d'une grille de score.
%   SC = AUTOBINNING(SC) découpe chaque caractéristique en tranches : les
%   variables numériques par quantiles, les variables de texte par
%   catégorie.
%
%   Découper n'est pas une commodité : c'est ce qui laisse une
%   caractéristique agir de façon non monotone. Un revenu très faible et
%   un revenu très élevé peuvent tous deux annoncer un risque, ce qu'un
%   coefficient unique ne saurait dire.
%
%   AUTOBINNING(SC,VARIABLES) ne traite que les variables nommées.
%   AUTOBINNING(...,'NumBins',N) fixe le nombre de tranches (cinq),
%   'MinCount',M le nombre minimal d'observations par tranche.
%
%   Exemple :
%      sc = autobinning(sc, 'revenu', 'NumBins', 4);
%
%   Voir aussi BININFO, BINDATA, FITMODEL, CREDITSCORECARD.
    nombreTranches = 5;
    minimum = 0;
    if nargin < 2 || isempty(variables)
        variables = grille.PredictorVars;
    elseif ischar(variables) || isstring(variables)
        variables = {char(variables)};
    end
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'numbins',  nombreTranches = round(varargin{k+1});
            case 'mincount', minimum = round(varargin{k+1});
            case 'algorithm' % un seul découpage est proposé
            otherwise
                error('risque:autobinning:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if minimum == 0
        minimum = max(round(numel(grille.Data.(grille.ResponseVar)) / (5 * nombreTranches)), 1);
    end
    for j = 1:numel(variables)
        nom = variables{j};
        colonne = grille.Data.(nom);
        if iscell(colonne)
            categories = unique(colonne);
            tranche = struct('nom', nom, 'type', 'categorie', ...
                             'categories', {categories});
        else
            colonne = double(colonne(:));
            valides = colonne(~isnan(colonne));
            bornes = unique(quantile(valides, linspace(0, 1, nombreTranches + 1)));
            bornes = bornes(2:end-1);
            bornes = matlibre_score_fusionner(colonne, bornes, minimum);
            tranche = struct('nom', nom, 'type', 'numerique', ...
                             'bornes', bornes);
        end
        grille = matlibre_score_poser_tranche(grille, nom, tranche);
    end
end
