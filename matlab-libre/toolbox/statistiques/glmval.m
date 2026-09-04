function predictions = glmval(coefficients, X, lien, varargin)
%GLMVAL Prédiction d'un modèle linéaire généralisé.
%   Y = GLMVAL(B,X,LIEN) applique les coefficients aux prédicteurs et
%   inverse le lien : c'est la prédiction sur l'échelle de la réponse, non
%   sur celle du prédicteur linéaire.
%
%   GLMVAL(...,'constant','off') suppose qu'il n'y a pas d'ordonnée à
%   l'origine dans B.
%
%   Exemple :
%      b = glmfit(X, y, 'binomial');
%      p = glmval(b, X, 'logit');       % probabilites entre zero et un
%
%   Voir aussi GLMFIT, FITGLM.
    avecConstante = true;
    k = 1;
    while k + 1 <= numel(varargin)
        if strcmpi(char(varargin{k}), 'constant')
            avecConstante = ~strcmpi(char(varargin{k+1}), 'off');
        end
        k = k + 2;
    end
    X = double(X);
    if isvector(X) && size(X, 1) == 1
        X = X(:);
    end
    coefficients = double(coefficients(:));
    if avecConstante
        lineaire = coefficients(1) + X * coefficients(2:end);
    else
        lineaire = X * coefficients;
    end
    predictions = matlibre_lien_inverse(lineaire, char(lien));
end
