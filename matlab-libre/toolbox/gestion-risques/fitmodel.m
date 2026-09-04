function [grille, modele] = fitmodel(grille, varargin)
%FITMODEL Ajuste la régression logistique d'une grille de score.
%   [SC,M] = FITMODEL(SC) régresse la réponse sur les poids de la preuve
%   des caractéristiques découpées, et range les coefficients dans la
%   grille.
%
%   La régression porte sur les poids de la preuve, non sur les valeurs
%   brutes : chaque caractéristique entre donc dans le modèle par un seul
%   coefficient, quel que soit le nombre de ses tranches, et ce
%   coefficient devrait valoir un si le découpage a bien fait son
%   travail. S'en écarter beaucoup signale un découpage à revoir.
%
%   FITMODEL(...,'PredictorVars',V) limite les caractéristiques,
%   'VariableSelection','stepwise' les choisit une à une par leur apport.
%
%   Exemple :
%      [sc, m] = fitmodel(sc);
%      m.Coefficients
%
%   Voir aussi AUTOBINNING, BININFO, DISPLAYPOINTS, SCORE, PROBDEFAULT.
    selection = 'none';
    variables = grille.PredictorVars;
    afficher = true;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'predictorvars'
                valeur = varargin{k+1};
                if ischar(valeur) || isstring(valeur)
                    variables = {char(valeur)};
                else
                    variables = valeur(:).';
                end
            case 'variableselection', selection = lower(char(varargin{k+1}));
            case 'display',           afficher = ~strcmpi(char(varargin{k+1}), 'off');
            otherwise
                error('risque:fitmodel:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    [bons, ~, ~] = matlibre_score_reponse(grille);
    if strcmp(selection, 'stepwise')
        variables = matlibre_score_selection(grille, variables, bons);
    end
    X = zeros(numel(bons), numel(variables));
    for j = 1:numel(variables)
        nom = variables{j};
        indices = matlibre_score_indices(grille, nom, grille.Data.(nom));
        X(:, j) = matlibre_score_poids(grille, nom, indices);
    end
    ajuste = fitglm(X, bons, 'Distribution', 'binomial');
    grille.ModelVars = variables;
    grille.ModelCoefficients = ajuste.Coefficients(:);
    grille.Fitted = ajuste.Fitted(:);
    modele = ajuste;
    if afficher
        fprintf('\n  Grille de score : %d caractéristiques retenues\n', numel(variables));
        fprintf('  %-20s %12s\n', '(constante)', ' ');
        fprintf('  %-20s %12.6f\n', '(Intercept)', grille.ModelCoefficients(1));
        for j = 1:numel(variables)
            fprintf('  %-20s %12.6f\n', variables{j}, grille.ModelCoefficients(j + 1));
        end
        fprintf('\n');
    end
end
