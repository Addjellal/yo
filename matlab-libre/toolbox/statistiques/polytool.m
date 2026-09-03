function [beta, bornes, modele] = polytool(x, y, n, alpha, varargin)
%POLYTOOL Ajustement polynomial et bande de confiance.
%   POLYTOOL(X,Y,N) ajuste un polynôme de degré N et trace la courbe
%   avec sa bande de confiance.
%   POLYTOOL(X,Y,N,ALPHA) fixe le niveau, 0,05 par défaut.
%
%   [BETA,BORNES] = POLYTOOL(...) rend les coefficients et leur
%   intervalle de confiance, sans rien tracer.
%
%   MATLAB ouvre une fenêtre où l'on déplace le point d'évaluation à la
%   souris ; MatLibre n'a pas d'outil interactif dans ses figures, et
%   trace la courbe et sa bande d'un coup. C'est la même information,
%   sans le curseur.
%
%   Exemple :
%      x = (1:20)';
%      y = 3 + 2 * x - 0.1 * x .^ 2 + randn(20, 1);
%      [beta, bornes] = polytool(x, y, 2);
%
%   Voir aussi POLYFIT, POLYVAL, POLYCONF, FITLM, REGRESS.
    if nargin < 3 || isempty(n)
        n = 1;
    end
    if nargin < 4 || isempty(alpha)
        alpha = 0.05;
    end
    x = double(x(:));
    y = double(y(:));
    [beta, S] = polyfit(x, y, n);
    beta = beta(:);
    % L'intervalle de confiance des coefficients vient de la matrice R
    % de la factorisation, celle que polyfit garde.
    ddl = max(numel(x) - (n + 1), 1);
    covariance = (S.normr ^ 2 / ddl) * inv(S.R.' * S.R);   %#ok<MINV>
    erreurs = sqrt(max(diag(covariance), 0));
    marge = tinv(1 - alpha / 2, ddl) * erreurs;
    bornes = [beta - marge, beta + marge];
    modele = struct('beta', beta, 'R', S.R, 'df', ddl, 'normr', S.normr, ...
                    'degre', n, 'alpha', alpha);
    if nargout > 0
        return;
    end
    grille = linspace(min(x), max(x), 200).';
    [ajuste, ecart] = polyval(beta, grille, S);
    plot(x, y, 'o');
    hold('on');
    plot(grille, ajuste, '-');
    plot(grille, ajuste + ecart, '--');
    plot(grille, ajuste - ecart, '--');
    hold('off');
    xlabel('x');
    ylabel('y');
    title(sprintf('Ajustement polynomial de degré %d', n));
end
