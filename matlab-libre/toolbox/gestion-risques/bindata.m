function sortie = bindata(grille, donnees, varargin)
%BINDATA Remplace les caractéristiques par leur tranche ou son poids.
%   D = BINDATA(SC) rend les données d'origine, chaque caractéristique
%   étant remplacée par le numéro de sa tranche. BINDATA(SC,DONNEES)
%   traite d'autres données que celles de la grille.
%
%   BINDATA(...,'OutputType','WOEModelInput') remplace plutôt par le
%   poids de la preuve : c'est ce que FITMODEL donne à la régression.
%
%   Exemple :
%      d = bindata(sc, [], 'OutputType', 'WOEModelInput');
%
%   Voir aussi BININFO, AUTOBINNING, FITMODEL.
    typeSortie = 'binnumber';
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'outputtype', typeSortie = lower(char(varargin{k+1}));
            otherwise
                error('risque:bindata:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if nargin < 2 || isempty(donnees)
        colonnes = grille.Data;
    else
        colonnes = matlibre_score_colonnes(donnees);
    end
    sortie = struct();
    if ~isempty(grille.IDVar) && isfield(colonnes, grille.IDVar)
        sortie.(grille.IDVar) = colonnes.(grille.IDVar);
    end
    for j = 1:numel(grille.PredictorVars)
        nom = grille.PredictorVars{j};
        if ~isfield(colonnes, nom)
            continue
        end
        indices = matlibre_score_indices(grille, nom, colonnes.(nom));
        switch typeSortie
            case {'woemodelinput', 'woe'}
                sortie.(nom) = matlibre_score_poids(grille, nom, indices);
            otherwise
                sortie.(nom) = indices;
        end
    end
    if isfield(colonnes, grille.ResponseVar)
        sortie.(grille.ResponseVar) = colonnes.(grille.ResponseVar);
    end
end
