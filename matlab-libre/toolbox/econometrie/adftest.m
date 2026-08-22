function [rejette, statistique] = adftest(y, retards)
%ADFTEST Test de Dickey-Fuller augmenté (modèle sans tendance).
%   [H,T] = ADFTEST(Y) rend H=1 si la racine unitaire est rejetée au seuil
%   de 5 %, en comparant la statistique aux valeurs critiques usuelles.
    if nargin < 2
        retards = 1;
    end
    y = y(:);
    dy = diff(y);
    n = numel(dy);
    X = y(1:end-1);
    for k = 1:retards
        X = [X, [zeros(k, 1); dy(1:end-k)]];
    end
    X = [X, ones(size(X, 1), 1)];
    b = X \ dy;
    residus = dy - X * b;
    ddl = numel(dy) - size(X, 2);
    sigma2 = sum(residus .^ 2) / max(ddl, 1);
    covariance = sigma2 * inv(X.' * X);
    statistique = b(1) / sqrt(covariance(1, 1));
    % Valeur critique de MacKinnon à 5 % pour un modèle avec constante.
    rejette = double(statistique < -2.86);
end
