function [X, R] = corrmtx(x, m, methode)
%CORRMTX Matrice de données pour l'estimation de la corrélation.
%   X = CORRMTX(V,M,METHODE) rend une matrice rectangulaire dont X'*X est
%   une estimation de la matrice d'autocorrélation d'ordre M+1. METHODE
%   vaut 'autocorrelation' (par défaut), 'prewindowed', 'postwindowed',
%   'covariance' ou 'modified'.
%
%   [X,R] = CORRMTX(...) rend aussi X'*X.
%
%   Exemple :
%      [X, R] = corrmtx(randn(100,1), 4, 'modified');
    if nargin < 3 || isempty(methode), methode = 'autocorrelation'; end
    x = double(x(:));
    n = numel(x);
    colonnes = m + 1;
    switch lower(char(methode))
        case 'autocorrelation'
            % Signal complété de zéros des deux côtés.
            etendu = [zeros(m, 1); x; zeros(m, 1)];
            lignes = n + m;
            X = zeros(lignes, colonnes);
            for i = 1:lignes
                X(i, :) = etendu(i + m:-1:i).';
            end
        case 'prewindowed'
            etendu = [zeros(m, 1); x];
            lignes = n;
            X = zeros(lignes, colonnes);
            for i = 1:lignes
                X(i, :) = etendu(i + m:-1:i).';
            end
        case 'postwindowed'
            etendu = [x; zeros(m, 1)];
            lignes = n;
            X = zeros(lignes, colonnes);
            for i = 1:lignes
                X(i, :) = etendu(i + m:-1:i).';
            end
        case 'covariance'
            lignes = n - m;
            X = zeros(lignes, colonnes);
            for i = 1:lignes
                X(i, :) = x(i + m:-1:i).';
            end
        case 'modified'
            lignes = n - m;
            X = zeros(2 * lignes, colonnes);
            for i = 1:lignes
                X(i, :) = x(i + m:-1:i).';
                X(lignes + i, :) = conj(x(i:i + m)).';
            end
        otherwise
            error('signal:corrmtx:UnknownMethod', 'Méthode inconnue : %s.', char(methode));
    end
    % Normalisation : X'*X doit estimer l'autocorrélation, donc diviser
    % par le nombre de produits accumulés. Les méthodes fenêtrées
    % rapportent à la longueur du signal, les autres au nombre de lignes.
    if any(strcmpi(char(methode), {'autocorrelation', 'prewindowed', 'postwindowed'}))
        X = X / sqrt(n);
    else
        X = X / sqrt(size(X, 1));
    end
    if nargout > 1
        R = X' * X;
    end
end
