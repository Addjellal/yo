function [b, se, pval, dansModele, stats] = stepwise(X, y, dansModele, penter, premove)
%STEPWISE Régression pas à pas.
%   STEPWISE(X,Y) ajoute et retire des variables une à une, en suivant
%   leur p-valeur, et affiche le modèle retenu.
%   STEPWISE(X,Y,IN) part du sous-ensemble IN.
%   STEPWISE(X,Y,IN,PENTER,PREMOVE) fixe les seuils d'entrée et de sortie
%   (0,05 et 0,10 par défaut).
%
%   [B,SE,P,IN,STATS] = STEPWISE(...) rend les coefficients, leurs écarts
%   types, leurs p-valeurs, les variables retenues et les statistiques du
%   modèle, sans rien afficher.
%
%   MATLAB ouvre une fenêtre où l'on ajoute et retire les variables à la
%   main ; MatLibre mène la procédure automatique et en rend le résultat,
%   comme le fait STEPWISEFIT.
%
%   Exemple :
%      rng(1);
%      X = randn(50, 4);
%      y = X(:, 2) * 3 + randn(50, 1);
%      [b, se, p, in] = stepwise(X, y);
%      find(in)      % la deuxième variable
%
%   Voir aussi STEPWISEFIT, FITLM, REGRESS, LASSO, SEQUENTIALFS.
    if nargin < 3, dansModele = []; end
    if nargin < 4 || isempty(penter), penter = 0.05; end
    if nargin < 5 || isempty(premove), premove = 0.10; end
    arguments = {'penter', penter, 'premove', premove};
    if ~isempty(dansModele)
        arguments = [{'inmodel', logical(dansModele)}, arguments];
    end
    [b, se, pval, dansModele, stats] = stepwisefit(X, y, arguments{:});
    if nargout > 0
        return;
    end
    fprintf('\nRégression pas à pas : %d variable(s) retenue(s)\n\n', sum(dansModele));
    fprintf('%-10s %12s %12s %12s\n', 'variable', 'coefficient', 'écart type', 'p');
    for k = 1:numel(b)
        if dansModele(k)
            marque = '*';
        else
            marque = ' ';
        end
        fprintf('%s X%-8d %12.4f %12.4f %12.4f\n', marque, k, b(k), se(k), pval(k));
    end
    fprintf('\nRMSE %.4f, R2 %.4f\n\n', stats.rmse, 1 - stats.SSresid / stats.SStotal);
end
